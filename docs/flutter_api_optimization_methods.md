# Optimizing Flutter Workflows That Call Many APIs

## Overview

Flutter applications sometimes need to perform workflows that depend on many API calls. If those calls are handled poorly, users may experience long loading times, frozen screens, duplicated requests, excessive battery usage, or unstable behavior on weak networks.

The goal is not only to make each API call faster. A well-optimized Flutter app should also:

- Reduce the number of API calls when possible.
- Run independent API calls concurrently.
- Avoid blocking the UI thread.
- Display useful content as early as possible.
- Cache reusable data.
- Retry failed requests safely.
- Cancel requests that are no longer needed.
- Move non-critical work to the background.
- Improve the backend contract when the mobile app is too dependent on many small APIs.

This document summarizes practical methods for optimizing Flutter workflows that require many API calls.

---

## 1. Run Independent API Calls in Parallel

A common mistake is awaiting API calls one by one, even when they do not depend on each other.

### Inefficient Sequential Approach

```dart
final user = await api.getUser();
final orders = await api.getOrders();
final notifications = await api.getNotifications();
```

In this approach, the total loading time is approximately the sum of all API durations.

### Optimized Parallel Approach

```dart
final results = await Future.wait([
  api.getUser(),
  api.getOrders(),
  api.getNotifications(),
]);

final user = results[0];
final orders = results[1];
final notifications = results[2];
```

`Future.wait` is useful when multiple API calls can be started at the same time.

### When to Use

Use parallel execution when:

- API calls are independent.
- One response is not required to build another request.
- The backend can handle concurrent requests.
- The device network conditions are acceptable.

---

## 2. Limit Concurrency Instead of Sending Too Many Requests at Once

Running API calls in parallel is useful, but sending too many requests at once can overload the client, backend, or network connection.

For example, avoid firing 50 or 100 requests simultaneously unless the backend is designed for it.

### Concurrency-Limited Execution

```dart
Future<List<T>> runWithLimit<T>(
  List<Future<T> Function()> tasks, {
  int limit = 6,
}) async {
  final results = <T>[];
  var index = 0;

  Future<void> worker() async {
    while (index < tasks.length) {
      final current = index++;
      results.add(await tasks[current]());
    }
  }

  await Future.wait(
    List.generate(limit, (_) => worker()),
  );

  return results;
}
```

### Recommended Use Cases

Use concurrency limits when:

- Loading details for many list items.
- Fetching paginated resources.
- Uploading or downloading multiple files.
- Calling APIs that may be rate-limited.
- Running batch-like operations from the client.

A reasonable starting point is usually between 4 and 8 concurrent requests, depending on the backend and network conditions.

---

## 3. Separate Critical and Non-Critical APIs

Not every API is required before rendering the first useful screen.

### Example

Critical APIs:

- User profile
- Main feed
- Required app configuration

Non-critical APIs:

- Recommendations
- Analytics
- Badge counts
- Secondary banners
- Recently viewed items

### Recommended Flow

```dart
final criticalData = await Future.wait([
  api.getProfile(),
  api.getFeed(),
]);

emit(HomeLoaded(criticalData));

unawaited(api.getRecommendations());
unawaited(api.sendAnalytics());
unawaited(api.getBadgeCount());
```

This improves perceived performance because the user can interact with the main content while secondary data loads in the background.

---

## 4. Use Caching Aggressively

Caching is one of the most effective ways to reduce waiting time and network usage.

### Types of Cache

| Cache Type | Purpose |
|---|---|
| Memory cache | Fast access during the current app session |
| Disk cache | Persisted data after app restart |
| HTTP cache | Reuse responses based on HTTP caching headers |
| Database cache | Structured offline data using SQLite, Drift, Isar, Hive, etc. |

### Dio Cache Example

```dart
final dio = Dio();

final cacheOptions = CacheOptions(
  store: MemCacheStore(),
  policy: CachePolicy.request,
  maxStale: const Duration(hours: 1),
);

dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
```

### What to Cache

Good candidates for caching:

- App configuration
- User profile
- Category lists
- Product metadata
- Static content
- Home screen data
- Feature flags
- Lookup tables

Avoid caching highly sensitive or rapidly changing data unless you have a clear invalidation strategy.

---

## 5. Apply Stale-While-Revalidate

Stale-while-revalidate is a pattern where the app displays cached data immediately, then refreshes the data in the background.

### Flow

1. Read data from local cache.
2. Show cached data immediately if available.
3. Fetch fresh data from the API in the background.
4. Update cache and UI when fresh data arrives.

### Example

```dart
Future<HomeData> getHomeData() async {
  final cached = await localStore.getHomeData();

  if (cached != null) {
    unawaited(_refreshHomeData());
    return cached;
  }

  return _refreshHomeData();
}

Future<HomeData> _refreshHomeData() async {
  final fresh = await api.getHomeData();
  await localStore.saveHomeData(fresh);
  return fresh;
}
```

### Benefits

- Faster perceived loading.
- Better offline experience.
- Less blocking on slow networks.
- Smoother user experience.

---

## 6. Use Pagination and Lazy Loading

Avoid loading large datasets all at once. Instead, load only the data needed for the current screen.

### Example

```dart
Future<List<Product>> getProducts({
  required int page,
  int limit = 20,
}) {
  return api.getProducts(page: page, limit: limit);
}
```

### ListView Pagination Example

```dart
ListView.builder(
  itemCount: items.length + 1,
  itemBuilder: (context, index) {
    if (index == items.length) {
      controller.loadNextPage();
      return const CircularProgressIndicator();
    }

    return ProductTile(product: items[index]);
  },
);
```

### Prefer Cursor-Based Pagination

For large datasets, cursor-based pagination is often better than offset-based pagination.

Example:

```http
GET /products?cursor=eyJpZCI6MTAwMX0=&limit=20
```

Cursor-based pagination is usually more stable when records are frequently inserted or deleted.

---

## 7. Move Heavy JSON Parsing to an Isolate

API calls themselves are asynchronous, but large JSON parsing can still block the main isolate and cause UI jank.

### Example with `Isolate.run`

```dart
final response = await dio.get('/large-data');

final data = await Isolate.run(() {
  return parseLargeJson(response.data);
});
```

### Example with `compute`

```dart
final data = await compute(parseLargeJson, response.data);
```

### Use Isolates For

- Large JSON parsing
- Mapping thousands of objects
- Encryption or decryption
- Compression or decompression
- Image processing
- Heavy file processing

Avoid using isolates for small responses because the overhead may be greater than the benefit.

---

## 8. Add Smart Retry with Exponential Backoff

Network requests may fail due to unstable connections, temporary server issues, or rate limits. Retrying can help, but retries must be controlled.

### Bad Retry Strategy

Do not retry many times immediately without delay.

### Better Retry Strategy

Use exponential backoff:

```text
Attempt 1: immediate
Attempt 2: wait 500 ms
Attempt 3: wait 1 second
Attempt 4: wait 2 seconds
Attempt 5: wait 4 seconds
```

Add random jitter when possible to avoid many clients retrying at the same time.

### Example

```dart
Future<T> retry<T>(Future<T> Function() task) async {
  var delay = const Duration(milliseconds: 500);

  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      return await task();
    } catch (e) {
      if (attempt == 3) rethrow;

      await Future.delayed(delay);
      delay *= 2;
    }
  }

  throw StateError('Unreachable');
}
```

### Retry Only Suitable Errors

Usually retry:

- Timeout
- Connection failure
- HTTP 429
- HTTP 500
- HTTP 502
- HTTP 503
- HTTP 504

Usually do not retry:

- HTTP 400
- HTTP 401
- HTTP 403
- HTTP 404

---

## 9. Cancel Requests That Are No Longer Needed

Requests should be canceled when the result is no longer useful.

### Common Scenarios

- User leaves the screen.
- User changes search keyword.
- User changes filters.
- A newer refresh request replaces an older one.
- A tab or page is disposed.

### Dio CancelToken Example

```dart
CancelToken? _cancelToken;

Future<void> search(String keyword) async {
  _cancelToken?.cancel();

  _cancelToken = CancelToken();

  final response = await dio.get(
    '/search',
    queryParameters: {'q': keyword},
    cancelToken: _cancelToken,
  );

  // Handle response
}
```

Canceling unnecessary requests reduces wasted bandwidth and prevents outdated responses from overwriting newer UI state.

---

## 10. Debounce and Throttle User-Triggered Requests

Search boxes, filters, and scroll listeners can trigger too many API calls.

### Debounce Example

Debounce waits until the user stops typing.

```dart
Timer? _debounce;

void onSearchChanged(String value) {
  _debounce?.cancel();

  _debounce = Timer(const Duration(milliseconds: 400), () {
    search(value);
  });
}
```

### Throttle Example

Throttle limits how often an action can run.

Use throttle for:

- Infinite scrolling
- Pull-to-refresh protection
- Button spam prevention
- Real-time filtering
- Repeated API-triggering gestures

---

## 11. Use Backend Aggregation, BFF, Batch APIs, or GraphQL

If the Flutter app must call many APIs to render one screen, the backend contract may be the real bottleneck.

### Problematic Pattern

```text
GET /user
GET /orders
GET /notifications
GET /wallet
GET /banners
GET /settings
GET /recommendations
```

### Better Pattern

```text
GET /mobile/home
```

Example response:

```json
{
  "user": {},
  "orders": [],
  "notifications": [],
  "wallet": {},
  "banners": [],
  "settings": {},
  "recommendations": []
}
```

### Options

| Approach | Description |
|---|---|
| BFF | Backend for Frontend, designed specifically for mobile needs |
| Batch endpoint | Client sends multiple request definitions in one call |
| GraphQL | Client requests only the fields it needs |
| Aggregate endpoint | Backend combines multiple services into one mobile-friendly response |

### Benefits

- Fewer network round trips.
- Less client-side orchestration.
- Easier caching.
- Better mobile-specific API contracts.
- Lower perceived latency.

---

## 12. Optimize Payload Size

Large payloads increase download time, parsing time, memory usage, and battery usage.

### Backend-Side Optimizations

- Return only fields needed by the screen.
- Use compression such as gzip or Brotli.
- Support ETag and `If-None-Match`.
- Support `Last-Modified` and `If-Modified-Since`.
- Avoid deeply nested unnecessary data.
- Use compact DTOs for mobile.
- Avoid returning large arrays without pagination.

### Client-Side Considerations

- Do not request data before it is needed.
- Avoid storing duplicate large objects in memory.
- Parse only what is required.
- Use streaming for large files when possible.

---

## 13. Use Background Sync for Long-Running Work

Some workflows should not block the user interface.

### Good Candidates

- Data synchronization
- Upload queues
- Prefetching
- Log or analytics upload
- Cache refresh
- Offline mutation sync

In Flutter, background execution can be implemented using packages such as `workmanager`, but platform limitations must be considered.

### Important Notes

- Android background work is generally more flexible.
- iOS background execution is more restricted.
- Background jobs are not guaranteed to run immediately.
- Do not depend on background jobs for urgent user-facing tasks.

---

## 14. Use Offline-First and Mutation Queues

For user actions, the app can often update local state immediately and sync later.

### Example Flow

```text
User submits action
↓
Save action locally with status = pending
↓
Update UI immediately
↓
Sync with server in background
↓
Mark as synced or failed
```

### Use Cases

- Likes
- Comments
- Form submissions
- Draft updates
- Cart changes
- Profile edits
- Field work apps
- Chat-like workflows

### Benefits

- Faster UI response.
- Better weak-network support.
- Reduced dependency on immediate server response.
- More resilient user experience.

---

## 15. Prevent Duplicate Requests

Duplicate requests often happen when:

- `build()` triggers API calls.
- Multiple widgets request the same data independently.
- The user taps a button repeatedly.
- Refresh and initial loading run at the same time.
- Providers are recreated unexpectedly.

### Recommendations

- Never call APIs directly inside `build()`.
- Use repositories or data providers.
- Share the same request among listeners.
- Disable buttons during submission.
- Deduplicate identical in-flight requests.
- Cache results at the repository layer.

### Simple In-Flight Deduplication Example

```dart
Future<User>? _userRequest;

Future<User> getUser() {
  _userRequest ??= api.getUser().whenComplete(() {
    _userRequest = null;
  });

  return _userRequest!;
}
```

---

## 16. Avoid Unnecessary UI Rebuilds

Even if APIs are optimized, the UI can still feel slow if large parts of the widget tree rebuild after every response.

### Recommendations

- Split state by feature or screen section.
- Avoid one large global loading state.
- Use selectors when available.
- Keep expensive computations out of `build()`.
- Use `const` widgets where possible.
- Render partial data as soon as it is available.

### Example State Split

Instead of one large state:

```text
HomeState
```

Use separated state:

```text
ProfileState
FeedState
BannerState
NotificationState
RecommendationState
```

This allows each UI section to update independently.

---

## 17. Use Progressive Rendering

A screen does not need to wait for all data before showing something useful.

### Example

```text
Step 1: Show cached layout or skeleton
Step 2: Load profile and main feed
Step 3: Render main content
Step 4: Load secondary sections
Step 5: Refresh stale data silently
```

### UI Patterns

- Skeleton loading
- Shimmer placeholders
- Partial rendering
- Section-level loading indicators
- Optimistic UI updates
- Cached-first rendering

Progressive rendering improves perceived performance even when total network time remains the same.

---

## 18. Measure Before and After Optimization

Optimization should be based on measurements.

### Measure

- API latency
- DNS/connect/TLS time
- Server response time
- Payload size
- JSON parsing time
- Local database read/write time
- UI frame time
- Number of duplicated requests
- Time to first meaningful content

### Dio Timing Interceptor Example

```dart
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      options.extra['startTime'] = DateTime.now();
      handler.next(options);
    },
    onResponse: (response, handler) {
      final start = response.requestOptions.extra['startTime'] as DateTime;
      final duration = DateTime.now().difference(start);

      debugPrint(
        '${response.requestOptions.path}: '
        '${duration.inMilliseconds}ms',
      );

      handler.next(response);
    },
    onError: (error, handler) {
      final start = error.requestOptions.extra['startTime'] as DateTime?;
      if (start != null) {
        final duration = DateTime.now().difference(start);
        debugPrint(
          '${error.requestOptions.path} failed after '
          '${duration.inMilliseconds}ms',
        );
      }

      handler.next(error);
    },
  ),
);
```

---

## Recommended Architecture

A clean architecture for API-heavy Flutter screens may look like this:

```text
UI
 ↓
Controller / Bloc / Notifier
 ↓
Repository
 ↓
Local Cache + Remote API
 ↓
Dio / HTTP Client + Interceptors
```

### Repository Responsibilities

The repository should decide:

- Whether cached data can be used.
- Whether remote data is required.
- Whether stale data should be refreshed.
- Whether requests should be retried.
- Whether duplicate requests should be deduplicated.
- Whether the response should be saved locally.
- Whether the task should run in the background.

### Example Repository

```dart
class HomeRepository {
  HomeRepository(this.api, this.cache);

  final HomeApi api;
  final HomeCache cache;

  Future<HomeData> getHome() async {
    final cached = await cache.getHome();

    if (cached != null && !cached.isExpired) {
      unawaited(refreshHome());
      return cached.data;
    }

    return refreshHome();
  }

  Future<HomeData> refreshHome() async {
    final results = await Future.wait([
      api.getProfile(),
      api.getFeed(),
      api.getBanners(),
    ]);

    final data = HomeData(
      profile: results[0] as Profile,
      feed: results[1] as List<Post>,
      banners: results[2] as List<BannerItem>,
    );

    await cache.saveHome(data);
    return data;
  }
}
```

---

## Practical Optimization Priority

| Priority | Optimization | Impact |
|---|---|---|
| 1 | Measure API and parsing time | Identifies the real bottleneck |
| 2 | Run independent APIs in parallel | Reduces blocking time |
| 3 | Add caching | Reduces repeated network calls |
| 4 | Use stale-while-revalidate | Improves perceived performance |
| 5 | Add pagination and lazy loading | Reduces payload size |
| 6 | Move heavy parsing to isolates | Prevents UI jank |
| 7 | Add retry, timeout, and cancellation | Improves network resilience |
| 8 | Deduplicate requests | Prevents wasted traffic |
| 9 | Use backend aggregation or BFF | Reduces round trips |
| 10 | Add background sync | Avoids blocking the user |

---

## Final Checklist

Before shipping an API-heavy Flutter feature, verify the following:

- [ ] Independent APIs are executed in parallel.
- [ ] Concurrency is limited for large request batches.
- [ ] Critical and non-critical APIs are separated.
- [ ] Cached data is used when possible.
- [ ] Stale-while-revalidate is implemented for reusable data.
- [ ] Large lists use pagination or lazy loading.
- [ ] Heavy JSON parsing is moved to an isolate.
- [ ] Retry uses exponential backoff.
- [ ] Requests are canceled when no longer needed.
- [ ] User input APIs are debounced or throttled.
- [ ] Duplicate requests are prevented.
- [ ] UI rebuilds are scoped to the smallest necessary section.
- [ ] Long-running tasks are moved to background sync when appropriate.
- [ ] Backend aggregation is considered for API-heavy screens.
- [ ] API latency and parsing time are measured before and after optimization.

---

## Conclusion

Optimizing Flutter workflows that call many APIs requires a combination of client-side and backend-side techniques. The most effective improvements usually come from:

1. Running independent APIs concurrently.
2. Caching reusable data.
3. Rendering cached or partial data early.
4. Reducing payload size.
5. Paginating large datasets.
6. Moving heavy parsing away from the UI isolate.
7. Canceling, retrying, and deduplicating requests carefully.
8. Improving the backend API contract with aggregation, BFF, batch endpoints, or GraphQL.

A fast Flutter app is not only one that receives API responses quickly. It is one that shows useful content early, avoids unnecessary work, and remains responsive even when the network is slow.
