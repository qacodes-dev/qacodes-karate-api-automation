# Karate API Automation — Restful Booker

A portfolio-quality API automation framework demonstrating Karate's feature-first approach, reusable calls, data-driven testing, schema validation, parallel execution, and **built-in mock server** — all modelled on the [Restful Booker](https://restful-booker.herokuapp.com) API.

---

## How the suite runs

**By default the suite runs against a built-in Karate mock server** — no external dependency, no network, no throttling. The mock faithfully reproduces Restful Booker's API including its quirks (cookie auth, `DELETE → 201`, `ping → 201`, create-vs-get shape, invalid POST → 500). This makes runs:

- **Deterministic** — identical results every time
- **CI-stable** — no 418 / rate-limit / Heroku cold-start failures
- **Fast** — the full 20-scenario suite completes in under 3 seconds
- **Parallel-safe** — the mock is booted once per JVM via `callSingle`

The real Restful Booker API is still supported as an opt-in mode:

```bash
# Default — uses built-in mock (CI-safe, no internet needed)
mvn clean test

# Opt-in — hits the live Restful Booker on Heroku
mvn clean test -Dkarate.env=real
```

> **Note:** The live API may return 418 from CI/cloud IPs or throttle after repeated runs — which is exactly why the mock is the default.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Test DSL | [Karate 1.4.1](https://github.com/karatelabs/karate) |
| Mock server | Karate built-in (`karate.start`) — no WireMock or external deps |
| Runner | JUnit 5 via `karate-junit5` |
| Build | Maven 3 |
| Java | 17 |
| Reports | Karate built-in HTML (`target/karate-reports/`) |
| CI | GitHub Actions (Temurin 17) |

---

## API Under Test (and mock)

**Mock base URL:** `http://localhost:<random-port>` (booted automatically)  
**Real base URL:** `https://restful-booker.herokuapp.com` (opt-in with `-Dkarate.env=real`)

Restful Booker quirks reproduced faithfully by the mock:

| Endpoint | Status | Quirk |
|---|---|---|
| `GET /ping` | **201** | Not 200 |
| `POST /auth` (bad creds) | **200** | Returns `{"reason":"Bad credentials"}`, not 4xx |
| `POST /booking` | 200 | Response wraps fields under `booking` key |
| `GET /booking/{id}` | 200 | Flat response — no `booking` wrapper |
| `PUT /booking/{id}` | 200 | Cookie `token` required — Bearer → 403 |
| `PATCH /booking/{id}` | 200 | Same cookie auth |
| `DELETE /booking/{id}` | **201** | Not 200/204 |
| `DELETE /booking/{nonexistent}` + valid auth | **405** | Not 404 |
| `POST /booking` with missing fields | **500** | Not 400/422 |

### Cookie auth — not Bearer

```gherkin
# CORRECT — cookie auth
And cookie token = authToken

# WRONG — server (and mock) returns 403
And header Authorization = 'Bearer ' + authToken
```

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

## Project Structure

```
src/test/resources/
├── karate-config.js              # env switch: mock (default) vs real
├── logback-test.xml
├── mock/
│   ├── restful-booker-mock.feature  # stateful in-memory mock server
│   └── mock-start.feature           # boots mock via callSingle (once per JVM)
├── features/
│   ├── auth/
│   │   └── create-token.feature
│   ├── bookings/
│   │   ├── create-booking.feature
│   │   ├── get-booking.feature
│   │   ├── update-booking.feature
│   │   ├── delete-booking.feature
│   │   └── z-booking-negative.feature
│   └── reusable/
│       ├── create-test-booking.feature  # @ignore — test-data setup
│       └── delete-test-booking.feature  # @ignore — cleanup
├── data/
│   ├── valid-booking.json
│   ├── invalid-booking.json
│   └── booking-examples.csv             # 4 rows for Scenario Outline
└── schemas/
    ├── booking-schema.json
    └── error-schema.json
```

### How the mock boots

`karate-config.js` calls `karate.callSingle('classpath:mock/mock-start.feature')` when `env == 'mock'`. `callSingle` caches the result across parallel threads, so the mock server starts exactly once per JVM regardless of thread count. The port is random (`port: 0`) and stored in `config.baseUrl`.

### How auth works

```gherkin
# Once per feature via callonce:
* def authResult = callonce read('classpath:features/auth/create-token.feature')
* def authToken  = authResult.authToken

# On write scenarios:
And cookie token = authToken
```

---

## How to Run

### Run all tests (mock, parallel, 2 threads)

```bash
mvn clean test
```

### Run against the live Restful Booker (opt-in, once)

```bash
mvn clean test -Dkarate.env=real
```

> May return 418 from cloud IPs or throttle after repeated runs.

### Run by tag

```bash
mvn clean test -Dkarate.options='--tags @smoke'
mvn clean test -Dkarate.options='--tags ~@negative'
```

### Run a single feature from IDE

Open `KarateTestRunner.java` → right-click → **Run**.

---

## How to View Reports

```
target/karate-reports/karate-summary.html
```

---

## Test Data Strategy

| File | Purpose |
|---|---|
| `data/valid-booking.json` | Baseline valid payload for create tests |
| `data/invalid-booking.json` | Intentionally incomplete — tests the 500 response |
| `data/booking-examples.csv` | 4 rows for `Scenario Outline` |
| Reusable features | `create-test-booking` generates isolated test data; `delete-test-booking` cleans up |

---

## CI/CD

The GitHub Actions workflow (`.github/workflows/karate-tests.yml`) runs on every push/PR to `main`:

1. Checkout → Java 17 (Temurin) → Maven cache
2. `mvn -B clean test` — uses the built-in mock by default, no internet needed
3. Upload `target/karate-reports/` and `target/surefire-reports/` as artifacts

---

## What This Demonstrates

- **Karate mock server** — `karate.start()` boots a stateful HTTP mock from a `.feature` file; `callSingle` ensures it starts once for parallel-safe execution
- **Karate readability** — `Given/When/Then` in feature files is far more readable than equivalent Java; `callonce`/`call` keeps setup DRY
- **Cookie auth vs Bearer** — the API (and mock) silently reject `Authorization: Bearer` with 403; only the `token` cookie works
- **Real quirks, real assertions** — `DELETE → 201`, `ping → 201`, `POST bad body → 500` — the mock preserves the same behaviour so tests stay realistic
- **Parallel execution** — 2-thread parallel runner via `Runner.path(...).parallel(2)` with thread-safe shared mock state
- **`callonce` vs `call`** — `callonce` for auth tokens (once per JVM), `call` for test-data setup (fresh per scenario)
