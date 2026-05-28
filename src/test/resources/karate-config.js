function fn() {
  var env = karate.env || 'mock';   // default: built-in mock (no external dependency, CI-safe)
  var config = { env: env };

  if (env === 'mock') {
    // Boot the mock once per JVM (callSingle caches the result across parallel threads).
    var port = karate.callSingle('classpath:mock/mock-start.feature').port;
    config.baseUrl = 'http://localhost:' + port;
    config.username = 'admin';
    config.password = 'password123';
  } else {
    // Real Restful Booker — opt-in: mvn test -Dkarate.env=real
    // Note: the live API may return 418 from CI/cloud IPs or throttle after repeated runs.
    config.baseUrl = karate.properties['qa.baseUrl'] || 'https://restful-booker.herokuapp.com';
    config.username = karate.properties['qa.username'] || 'admin';
    config.password = karate.properties['qa.password'] || 'password123';

    // Cold-start gate: poll /ping (expects 201) before scenarios run.
    var maxAttempts = 5;
    var pingOk = false;
    for (var i = 0; i < maxAttempts; i++) {
      try {
        var conn = new java.net.URL(config.baseUrl + '/ping').openConnection();
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        conn.setRequestMethod('GET');
        var status = conn.getResponseCode();
        conn.disconnect();
        if (status === 201) {
          karate.log('[karate-config] API ready (ping attempt ' + (i + 1) + ' → 201)');
          pingOk = true;
          break;
        }
        karate.log('[karate-config] Ping attempt ' + (i + 1) + ' returned ' + status + ', retrying in 3s...');
      } catch (e) {
        karate.log('[karate-config] Ping attempt ' + (i + 1) + ' error: ' + e + ', retrying in 3s...');
      }
      if (i < maxAttempts - 1) java.lang.Thread.sleep(3000);
    }
    if (!pingOk) {
      karate.log('[karate-config] WARNING: /ping never returned 201 — proceeding anyway, scenarios will use retry logic');
    }
  }

  karate.configure('connectTimeout', 15000);
  karate.configure('readTimeout', 15000);
  // retry until lines in features: instant against mock, still useful for real-API mode
  karate.configure('retry', { count: 3, interval: 1000 });

  return config;
}
