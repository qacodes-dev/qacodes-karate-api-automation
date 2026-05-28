function fn() {
  var env = karate.env || 'local';

  var baseUrl = 'https://restful-booker.herokuapp.com';
  if (env === 'staging') {
    baseUrl = karate.properties['qa.baseUrl'] || 'https://restful-booker.herokuapp.com';
  }

  var username = karate.properties['qa.username'] || 'admin';
  var password = karate.properties['qa.password'] || 'password123';

  karate.configure('connectTimeout', 30000);
  karate.configure('readTimeout', 30000);

  // Global retry defaults for `retry until` steps in features.
  // Restful Booker is a shared public API that occasionally returns transient
  // 418/429/5xx during cold starts or under load — retry up to 3× with 5 s backoff.
  karate.configure('retry', { count: 3, interval: 5000 });

  // Cold-start gate: poll /ping (expects 201) before scenarios run.
  // Bounded, tolerant: logs a warning and proceeds if the API never returns 201,
  // so a single network blip doesn't hard-fail the whole suite.
  var maxAttempts = 5;
  var pingOk = false;
  for (var i = 0; i < maxAttempts; i++) {
    try {
      var conn = new java.net.URL(baseUrl + '/ping').openConnection();
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

  return {
    env: env,
    baseUrl: baseUrl,
    username: username,
    password: password
  };
}
