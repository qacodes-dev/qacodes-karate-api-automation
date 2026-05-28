# Karate API Automation — Restful Booker

A portfolio-quality API automation framework demonstrating Karate's feature-first approach, reusable calls, data-driven testing, schema validation, and parallel execution — all against the public [Restful Booker](https://restful-booker.herokuapp.com) API.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Test DSL | [Karate 1.4.1](https://github.com/karatelabs/karate) |
| Runner | JUnit 5 via `karate-junit5` |
| Build | Maven 3 |
| Java | 17 |
| Reports | Karate built-in HTML (`target/karate-reports/`) |
| CI | GitHub Actions (Temurin 17) |

---

## API Under Test

**Base URL:** `https://restful-booker.herokuapp.com`

Key behaviors worth knowing before reading the tests:

| Endpoint | Status | Note |
|---|---|---|
| `GET /ping` | **201** Created | Not 200 — assert 201 |
| `POST /auth` | 200 | Returns `{"token":"..."}` in JSON body |
| `POST /booking` | 200 | No auth required; response wraps fields under `booking` key |
| `GET /booking/{id}` | 200 | Flat response — no `booking` wrapper |
| `PUT /booking/{id}` | 200 | Requires **cookie** `token=<value>`, not Bearer header |
| `PATCH /booking/{id}` | 200 | Same cookie auth requirement |
| `DELETE /booking/{id}` | **201** Created | Not 200/204 — assert 201 |

### Cookie auth — not Bearer

Writes (PUT, PATCH, DELETE) authenticate via a **cookie**, not an `Authorization` header:

```gherkin
# CORRECT — cookie auth
And cookie token = authToken

# WRONG — server returns 403
And header Authorization = 'Bearer ' + authToken
```

### Heroku quirks

- **Auto-reset**: The API resets its database every 10 minutes. During the reset window all write operations return `418 I'm a Teapot`. Wait a moment and retry.
- **Cold start**: Free-tier Heroku dynos sleep when idle. The first request after a sleep may take 10–20 s; the 30-second timeout in `karate-config.js` handles this.

---

## Scenarios Covered

| Feature | Scenarios | Tags |
|---|---|---|
| `auth/create-token` | Token auth via POST /auth | |
| `bookings/create-booking` | Create booking, echo values, 4× CSV data-driven rows | `@smoke` `@regression` `@datadriven` |
| `bookings/get-booking` | Happy-path GET, values match create, schema validation | `@smoke` `@regression` `@schema` |
| `bookings/update-booking` | Full PUT + partial PATCH (cookie auth) | `@regression` |
| `bookings/delete-booking` | DELETE returns 201, GET after delete returns 404 | `@smoke` `@regression` |
| `bookings/z-booking-negative` | Auth failures, non-existing IDs, invalid payload | `@negative` `@regression` |
| Reusable | `create-test-booking`, `delete-test-booking` | `@ignore` |

**Total: 20 scenarios**

---

## Feature File Structure

```
src/test/resources/
├── karate-config.js              # env, baseUrl, credentials, timeouts
├── logback-test.xml              # quiet logging
├── features/
│   ├── auth/
│   │   └── create-token.feature  # returns authToken
│   ├── bookings/
│   │   ├── create-booking.feature
│   │   ├── get-booking.feature
│   │   ├── update-booking.feature
│   │   ├── delete-booking.feature
│   │   └── z-booking-negative.feature   # z- prefix → runs last (see Known Limitations)
│   └── reusable/
│       ├── create-test-booking.feature  # @ignore — called by other features
│       └── delete-test-booking.feature  # @ignore — cleanup helper
├── data/
│   ├── valid-booking.json
│   ├── invalid-booking.json
│   └── booking-examples.csv      # 4 rows for Scenario Outline
└── schemas/
    ├── booking-schema.json        # Karate fuzzy-match schema for GET /booking/{id}
    └── error-schema.json
```

### How auth works

```gherkin
# In Background (once per feature via callonce):
* def authResult = callonce read('classpath:features/auth/create-token.feature')
* def authToken  = authResult.authToken

# In scenarios that need writes:
And cookie token = authToken   # ← cookie, not Bearer
```

---

## How to Run

### Run all tests (parallel, 2 threads)

```bash
mvn clean test
```

Reports are written to `target/karate-reports/`.

### Run by tag

```bash
# Smoke tests only
mvn clean test -Dkarate.options='--tags @smoke'

# Exclude negative tests
mvn clean test -Dkarate.options='--tags ~@negative'
```

### Run a single feature from IDE

Open `KarateTestRunner.java` → right-click → **Run**. The `testAll()` and `testSmoke()` methods map to the two common modes.

### Run by tag (parallel runner from command line)

Add the tag to the `Runner` call in `ParallelTestRunner`, or use the system property variant:

```bash
mvn clean test -Dkarate.options='--tags @regression'
```

---

## How to View Reports

After `mvn clean test`, open:

```
target/karate-reports/karate-summary.html
```

Each feature also has its own HTML report in `target/karate-reports/`.

---

## Test Data Strategy

| File | Purpose |
|---|---|
| `data/valid-booking.json` | Baseline valid booking payload for create tests |
| `data/invalid-booking.json` | Intentionally incomplete — tests server's 500 response |
| `data/booking-examples.csv` | 4 rows of booking data for `Scenario Outline` |
| Reusable features | `create-test-booking.feature` generates isolated test data per scenario; `delete-test-booking.feature` cleans up |

Schema files (`schemas/`) use Karate's fuzzy-match markers (`#string`, `#number`, `#boolean`, `##string` for optional) so they can be used directly in `match response ==` assertions.

---

## CI/CD

The GitHub Actions workflow (`.github/workflows/karate-tests.yml`) runs on every push and pull request to `main`:

1. Check out code
2. Set up Java 17 (Temurin)
3. Cache `~/.m2`
4. `mvn -B clean test`
5. Upload `target/karate-reports/` and `target/surefire-reports/` as artifacts (always, even on failure)

Credentials default to `admin` / `password123` (the public demo creds). In a real project, store them in GitHub Secrets and pass as `-Dqa.username` / `-Dqa.password`.

---

## Known Limitations

### Restful Booker is a shared public API

- **Auto-reset every 10 minutes**: During the reset, POST/PUT/PATCH/DELETE return `418 I'm a Teapot`. If a local run fails with 418, wait a minute and retry.
- **No data isolation**: Other users share the same bookings. Tests create their own bookings and clean up where possible, but the `/booking` list may contain bookings from other users.
- **Deliberate bugs**: Some invalid payloads return `500` instead of `400`; DELETE returns `201` not `204`. Tests assert the _actual_ behavior and include `# quirk:` comments.

### Why `z-booking-negative.feature` is prefixed with `z-`

The scenario that POSTs an invalid booking (expecting `500`) causes the Restful Booker server to enter a temporary rate-limit state where subsequent POST /booking requests in the same Heroku connection return `418`. Prefixing the file with `z-` ensures it sorts _after_ all other booking features, so the invalid POST runs last and cannot poison earlier tests.

### Local rate limiting after many runs

Running the full suite many times in quick succession can exhaust the Heroku API's per-session request quota (which resets with the 10-minute auto-reset). GitHub Actions runs from a fresh IP on each workflow trigger and is not affected.

---

## What I Learned

- **Karate is readability-first**: chaining `Given/When/Then` steps in feature files is far more readable than equivalent Java code, and `callonce`/`call` for reusable features keeps setup DRY.
- **Cookie auth vs Bearer**: The Restful Booker silently rejects `Authorization: Bearer` with 403; only the `token` cookie works. Always read the API docs before assuming conventional auth patterns.
- **Real APIs have real quirks**: `DELETE → 201`, `GET /ping → 201`, `POST with bad body → 500` — testing against an actual hosted API forces you to assert real behaviour, not idealised behaviour.
- **Execution order matters**: The `z-` prefix convention is a lightweight way to control feature ordering in Karate's parallel runner without requiring custom runner code.
- **`callonce` vs `call`**: `callonce` runs once per JVM (perfect for auth tokens), `call` runs per scenario (correct for test-data setup that must be fresh each time).

---

## Next Improvements

- Add a WireMock or Testcontainers-based local mock so the suite runs without internet and without API rate limits.
- Add `@afterScenario` hooks for automatic cleanup of created bookings.
- Parametrise the thread count via a Maven property (`-Dkarate.threads=4`) rather than a hard-coded literal.
- Add negative schema tests for error responses once the API returns consistent error JSON.
- Integrate Karate's HTML report into a CI/CD dashboard (e.g., Allure or GitHub Pages artifact).
