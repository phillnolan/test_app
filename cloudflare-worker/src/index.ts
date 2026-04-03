import { createRemoteJWKSet, jwtVerify } from "jose";

export interface Env {
  DB: D1Database;
  CACHE: KVNamespace;
  FILES: R2Bucket;
  APP_ENV: string;
  FIREBASE_PROJECT_ID: string;
}

type ApiResponse =
  | { ok: true; data?: unknown }
  | { ok: false; error: string };

type AuthContext = {
  uid: string;
  email?: string;
  name?: string;
};

const googleJwks = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return withCors(new Response(null, { status: 204 }));
    }

    if (url.pathname === "/health") {
      return json({ ok: true, data: { status: "healthy", env: env.APP_ENV } });
    }

    const auth = await verifyFirebaseToken(request, env);
    if (!auth.ok) {
      return json({ ok: false, error: auth.error }, { status: 401 });
    }

    await upsertUserProfile(env, auth.data);

    if (url.pathname === "/notes" && request.method === "GET") {
      return getNotes(env, auth.data.uid);
    }

    if (url.pathname === "/notes" && request.method === "POST") {
      return upsertNote(request, env, auth.data.uid);
    }

    if (url.pathname === "/tasks" && request.method === "POST") {
      return upsertTask(request, env, auth.data.uid);
    }

    if (url.pathname === "/sync-cache" && request.method === "POST") {
      return saveSyncCache(request, env, auth.data.uid);
    }

    if (url.pathname === "/sync-cache" && request.method === "GET") {
      return getSyncCache(url, env, auth.data.uid);
    }

    if (url.pathname === "/account-data" && request.method === "DELETE") {
      return deleteAccountData(env, auth.data.uid);
    }

    if (url.pathname === "/attachments/upload" && request.method === "POST") {
      return uploadAttachment(request, env, auth.data.uid);
    }

    if (url.pathname === "/attachments/download" && request.method === "GET") {
      return downloadAttachment(url, env, auth.data.uid);
    }

    return json({ ok: false, error: "Not found." }, { status: 404 });
  },
};

async function verifyFirebaseToken(
  request: Request,
  env: Env,
): Promise<{ ok: true; data: AuthContext } | { ok: false; error: string }> {
  const header = request.headers.get("authorization");
  if (!header?.startsWith("Bearer ")) {
    return { ok: false, error: "Missing Bearer token." };
  }

  const token = header.slice("Bearer ".length).trim();
  if (!token) {
    return { ok: false, error: "Empty Bearer token." };
  }

  try {
    const { payload } = await jwtVerify(token, googleJwks, {
      issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
      audience: env.FIREBASE_PROJECT_ID,
    });

    const uid = payload.sub?.toString();
    if (!uid) {
      return { ok: false, error: "Firebase token is missing sub." };
    }

    return {
      ok: true,
      data: {
        uid,
        email: payload.email?.toString(),
        name: payload.name?.toString(),
      },
    };
  } catch {
    return { ok: false, error: "Invalid Firebase token." };
  }
}

async function getNotes(env: Env, firebaseUid: string): Promise<Response> {
  const result = await env.DB.prepare(
    `SELECT id, event_id, event_type, content, created_at, updated_at
     FROM notes WHERE firebase_uid = ? ORDER BY updated_at DESC`,
  )
    .bind(firebaseUid)
    .all();

  return json({ ok: true, data: result.results satisfies unknown[] });
}

async function upsertUserProfile(env: Env, auth: AuthContext): Promise<void> {
  const now = new Date().toISOString();
  await env.DB.prepare(
    `INSERT INTO users (firebase_uid, email, display_name, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?)
     ON CONFLICT(firebase_uid) DO UPDATE SET
       email = excluded.email,
       display_name = excluded.display_name,
       updated_at = excluded.updated_at`,
  )
    .bind(auth.uid, auth.email ?? null, auth.name ?? null, now, now)
    .run();
}

async function upsertNote(
  request: Request,
  env: Env,
  firebaseUid: string,
): Promise<Response> {
  const body = (await request.json()) as {
    id: string;
    eventId: string;
    eventType: string;
    content?: string;
  };

  if (!body.id || !body.eventId || !body.eventType) {
    return json({ ok: false, error: "Missing note payload." }, { status: 400 });
  }

  const now = new Date().toISOString();
  await env.DB.prepare(
    `INSERT INTO notes (id, firebase_uid, event_id, event_type, content, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(id) DO UPDATE SET
       content = excluded.content,
       updated_at = excluded.updated_at`,
  )
    .bind(
      body.id,
      firebaseUid,
      body.eventId,
      body.eventType,
      body.content ?? null,
      now,
      now,
    )
    .run();

  return json({ ok: true, data: { id: body.id } });
}

async function upsertTask(
  request: Request,
  env: Env,
  firebaseUid: string,
): Promise<Response> {
  const body = (await request.json()) as {
    id: string;
    title: string;
    note?: string;
    startAt: string;
    endAt: string;
    isDone?: boolean;
  };

  if (!body.id || !body.title || !body.startAt || !body.endAt) {
    return json({ ok: false, error: "Missing task payload." }, { status: 400 });
  }

  const now = new Date().toISOString();
  await env.DB.prepare(
    `INSERT INTO personal_tasks
      (id, firebase_uid, title, note, start_at, end_at, is_done, created_at, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT(id) DO UPDATE SET
       title = excluded.title,
       note = excluded.note,
       start_at = excluded.start_at,
       end_at = excluded.end_at,
       is_done = excluded.is_done,
       updated_at = excluded.updated_at`,
  )
    .bind(
      body.id,
      firebaseUid,
      body.title,
      body.note ?? null,
      body.startAt,
      body.endAt,
      body.isDone ? 1 : 0,
      now,
      now,
    )
    .run();

  return json({ ok: true, data: { id: body.id } });
}

async function saveSyncCache(
  request: Request,
  env: Env,
  firebaseUid: string,
): Promise<Response> {
  const body = (await request.json()) as {
    snapshotKey: string;
    payload: unknown;
    ttlSeconds?: number;
  };

  if (!body.snapshotKey) {
    return json({ ok: false, error: "Missing snapshotKey." }, { status: 400 });
  }

  const cacheKey = buildCacheKey(firebaseUid, body.snapshotKey);
  await env.CACHE.put(cacheKey, JSON.stringify(body.payload), {
    expirationTtl: body.ttlSeconds ?? 60 * 60 * 6,
  });

  const now = new Date().toISOString();
  await env.DB.prepare(
    `INSERT OR REPLACE INTO sync_snapshots
      (id, firebase_uid, snapshot_key, payload_json, synced_at, expires_at)
     VALUES (?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      crypto.randomUUID(),
      firebaseUid,
      body.snapshotKey,
      JSON.stringify(body.payload),
      now,
      null,
    )
    .run();

  return json({ ok: true });
}

async function getSyncCache(
  url: URL,
  env: Env,
  firebaseUid: string,
): Promise<Response> {
  const snapshotKey = url.searchParams.get("key");
  if (!snapshotKey) {
    return json({ ok: false, error: "Missing key param." }, { status: 400 });
  }

  const cacheKey = buildCacheKey(firebaseUid, snapshotKey);
  const value = await env.CACHE.get(cacheKey);
  if (!value) {
    return json({ ok: true, data: null });
  }

  return json({ ok: true, data: JSON.parse(value) });
}

async function uploadAttachment(
  request: Request,
  env: Env,
  firebaseUid: string,
): Promise<Response> {
  const fileName = request.headers.get("x-file-name");
  const eventId = request.headers.get("x-event-id");
  const contentType = request.headers.get("content-type");
  if (!fileName || !eventId) {
    return json(
      { ok: false, error: "Missing x-file-name or x-event-id header." },
      { status: 400 },
    );
  }

  const objectKey = `${firebaseUid}/${eventId}/${crypto.randomUUID()}-${fileName}`;
  const bytes = await request.arrayBuffer();
  await env.FILES.put(objectKey, bytes, {
    httpMetadata: {
      contentType: contentType ?? "application/octet-stream",
    },
  });

  await env.DB.prepare(
    `INSERT INTO attachments
      (id, firebase_uid, event_id, file_name, object_key, content_type, size_bytes, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
  )
    .bind(
      crypto.randomUUID(),
      firebaseUid,
      eventId,
      fileName,
      objectKey,
      contentType ?? null,
      bytes.byteLength,
      new Date().toISOString(),
    )
    .run();

  return json({
    ok: true,
    data: {
      objectKey,
      fileName,
    },
  });
}

async function deleteAccountData(
  env: Env,
  firebaseUid: string,
): Promise<Response> {
  await env.CACHE.delete(buildCacheKey(firebaseUid, "dashboard"));

  const attachmentRows = await env.DB.prepare(
    `SELECT object_key
     FROM attachments
     WHERE firebase_uid = ?`,
  )
    .bind(firebaseUid)
    .all<{ object_key: string }>();

  for (const row of attachmentRows.results) {
    if (row.object_key) {
      await env.FILES.delete(row.object_key);
    }
  }

  await env.DB.batch([
    env.DB.prepare(`DELETE FROM attachments WHERE firebase_uid = ?`).bind(
      firebaseUid,
    ),
    env.DB.prepare(`DELETE FROM notes WHERE firebase_uid = ?`).bind(firebaseUid),
    env.DB.prepare(`DELETE FROM personal_tasks WHERE firebase_uid = ?`).bind(
      firebaseUid,
    ),
    env.DB.prepare(`DELETE FROM sync_snapshots WHERE firebase_uid = ?`).bind(
      firebaseUid,
    ),
  ]);

  return json({ ok: true });
}

async function downloadAttachment(
  url: URL,
  env: Env,
  firebaseUid: string,
): Promise<Response> {
  const objectKey = url.searchParams.get("key");
  if (!objectKey) {
    return json({ ok: false, error: "Missing key param." }, { status: 400 });
  }

  const attachment = await env.DB.prepare(
    `SELECT file_name, object_key, content_type
     FROM attachments
     WHERE firebase_uid = ? AND object_key = ?
     LIMIT 1`,
  )
    .bind(firebaseUid, objectKey)
    .first<{ file_name: string; object_key: string; content_type: string | null }>();

  if (!attachment) {
    return json({ ok: false, error: "Attachment not found." }, { status: 404 });
  }

  const object = await env.FILES.get(attachment.object_key);
  if (!object) {
    return json({ ok: false, error: "File content not found." }, { status: 404 });
  }

  const headers = new Headers();
  headers.set(
    "content-type",
    attachment.content_type ?? "application/octet-stream",
  );
  headers.set(
    "content-disposition",
    `inline; filename="${attachment.file_name.replace(/"/g, "")}"`,
  );

  return withCors(new Response(object.body, { status: 200, headers }));
}

function buildCacheKey(firebaseUid: string, snapshotKey: string): string {
  return `snapshot:${firebaseUid}:${snapshotKey}`;
}

function json(body: ApiResponse, init?: ResponseInit): Response {
  return withCors(
    new Response(JSON.stringify(body), {
      ...init,
      headers: {
        "content-type": "application/json; charset=utf-8",
        ...(init?.headers ?? {}),
      },
    }),
  );
}

function withCors(response: Response): Response {
  response.headers.set("access-control-allow-origin", "*");
  response.headers.set("access-control-allow-methods", "GET,POST,DELETE,OPTIONS");
  response.headers.set(
    "access-control-allow-headers",
    "content-type,authorization,x-file-name,x-event-id",
  );
  return response;
}
