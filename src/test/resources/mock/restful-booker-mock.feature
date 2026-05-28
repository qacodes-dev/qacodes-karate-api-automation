Feature: Restful Booker Mock Server
# Stateful in-memory mock reproducing Restful Booker's API quirks:
#   ping→201, DELETE→201, invalid POST→500, auth failure→200 {reason:...}
#   writes require Cookie token (Bearer→403), DELETE nonexistent+auth→405
#   POST create response is nested under 'booking'; GET response is flat

Background:
  * def bookings = {}
  * def nextId = { value: 1 }
  * def VALID_TOKEN = 'karate-mock-token'
  * def doCreate =
    """
    function(body) {
      var id = nextId.value;
      nextId.value = nextId.value + 1;
      bookings[id + ''] = body;
      return { bookingid: id, booking: body };
    }
    """
  * def doUpdate =
    """
    function(id, body) {
      bookings[id] = body;
      return body;
    }
    """
  * def doPatch =
    """
    function(id, patch) {
      var existing = bookings[id] || {};
      var merged = {};
      var k;
      for (k in existing) { merged[k] = existing[k]; }
      for (k in patch) { merged[k] = patch[k]; }
      bookings[id] = merged;
      return merged;
    }
    """
  * def doDelete =
    """
    function(id) {
      delete bookings[id];
      return '';
    }
    """

# ── health ───────────────────────────────────────────────────────────────────

Scenario: pathMatches('/ping')
  * def responseStatus = 201

# ── auth ──────────────────────────────────────────────────────────────────────

Scenario: pathMatches('/auth') && methodIs('post')
  * def creds = request
  * def isValid = creds.username == 'admin' && creds.password == 'password123'
  * def tokenObj = { token: '#(VALID_TOKEN)' }
  * def failObj  = { reason: 'Bad credentials' }
  * def responseStatus = 200
  * def response = isValid ? tokenObj : failObj

# ── list bookings ─────────────────────────────────────────────────────────────

Scenario: pathMatches('/booking') && methodIs('get')
  * def idList = []
  * def addFn = function(k) { idList.push({ bookingid: parseInt(k) }) }
  * eval Object.keys(bookings).forEach(addFn)
  * def responseStatus = 200
  * def response = idList

# ── create booking ────────────────────────────────────────────────────────────

Scenario: pathMatches('/booking') && methodIs('post')
  * def body = request
  * def ok = body.firstname && body.lastname && body.totalprice != null && body.depositpaid != null && body.bookingdates
  * def responseStatus = ok ? 200 : 500
  * def response = ok ? doCreate(body) : 'Internal Server Error'

# ── get booking ───────────────────────────────────────────────────────────────

Scenario: pathMatches('/booking/{id}') && methodIs('get')
  * def id = pathParams.id
  * def booking = bookings[id]
  * def responseStatus = booking ? 200 : 404
  * def response = booking ? booking : 'Not Found'

# ── full update (PUT) ─────────────────────────────────────────────────────────

Scenario: pathMatches('/booking/{id}') && methodIs('put')
  * def cookieHeader = requestHeaders['cookie']
  * def authed = cookieHeader != null && cookieHeader[0] != null && (cookieHeader[0] + '').indexOf('token=' + VALID_TOKEN) >= 0
  * def id = pathParams.id
  * def responseStatus = authed ? 200 : 403
  * def response = authed ? doUpdate(id, request) : 'Forbidden'

# ── partial update (PATCH) ────────────────────────────────────────────────────

Scenario: pathMatches('/booking/{id}') && methodIs('patch')
  * def cookieHeader = requestHeaders['cookie']
  * def authed = cookieHeader != null && cookieHeader[0] != null && (cookieHeader[0] + '').indexOf('token=' + VALID_TOKEN) >= 0
  * def id = pathParams.id
  * def responseStatus = authed ? 200 : 403
  * def response = authed ? doPatch(id, request) : 'Forbidden'

# ── delete booking ────────────────────────────────────────────────────────────

Scenario: pathMatches('/booking/{id}') && methodIs('delete')
  * def cookieHeader = requestHeaders['cookie']
  * def authed = cookieHeader != null && cookieHeader[0] != null && (cookieHeader[0] + '').indexOf('token=' + VALID_TOKEN) >= 0
  * def id = pathParams.id
  * def booking = bookings[id]
  * def responseStatus = authed ? (booking ? 201 : 405) : 403
  * def response = (authed && booking) ? doDelete(id) : ''
