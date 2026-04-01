CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  firebase_uid TEXT NOT NULL UNIQUE,
  email TEXT,
  display_name TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notes (
  id TEXT PRIMARY KEY,
  firebase_uid TEXT NOT NULL,
  event_id TEXT NOT NULL,
  event_type TEXT NOT NULL,
  content TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS attachments (
  id TEXT PRIMARY KEY,
  firebase_uid TEXT NOT NULL,
  event_id TEXT NOT NULL,
  file_name TEXT NOT NULL,
  object_key TEXT NOT NULL,
  content_type TEXT,
  size_bytes INTEGER,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS personal_tasks (
  id TEXT PRIMARY KEY,
  firebase_uid TEXT NOT NULL,
  title TEXT NOT NULL,
  note TEXT,
  start_at TEXT NOT NULL,
  end_at TEXT NOT NULL,
  is_done INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_snapshots (
  id TEXT PRIMARY KEY,
  firebase_uid TEXT NOT NULL,
  snapshot_key TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  synced_at TEXT NOT NULL,
  expires_at TEXT
);
