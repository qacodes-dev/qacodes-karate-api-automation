@regression @negative
Feature: Booking Negative Cases
# NOTE: The `z-` prefix is a fragile ordering hack — Karate does not guarantee
# alphabetical execution. The proper mechanism for ordering / isolation is tags
# + `callonce` for shared setup, which is what this suite uses elsewhere.
# The `z-` prefix is retained only as a soft hint that the invalid-POST scenario
# (which can briefly poison the shared Restful Booker connection) should run late.
# Exclude this feature in CI if needed with: --tags ~@negative

  Background:
    * url baseUrl
    # callonce — auth token is created exactly once for the whole feature, not per scenario
    * def authResult = callonce read('classpath:features/auth/create-token.feature')
    * def authToken  = authResult.authToken

  Scenario: PUT /booking/{id} without any auth token returns 403
    # Auth check happens before existence check, so id=1 works without creating a booking
    Given path '/booking/1'
    And request
      """
      {
        "firstname":    "Unauthorized",
        "lastname":     "User",
        "totalprice":   100,
        "depositpaid":  false,
        "bookingdates": { "checkin": "2025-01-01", "checkout": "2025-01-02" },
        "additionalneeds": ""
      }
      """
    When method PUT
    Then status 403

  Scenario: PUT /booking/{id} with Authorization Bearer header (wrong auth method) returns 403
    # The API requires a COOKIE named "token", not an Authorization: Bearer header.
    # Sending Bearer is silently rejected with 403 — never use Bearer for this API.
    Given path '/booking/1'
    And header Authorization = 'Bearer ' + authToken
    And request
      """
      {
        "firstname":    "Bearer",
        "lastname":     "Attempt",
        "totalprice":   100,
        "depositpaid":  false,
        "bookingdates": { "checkin": "2025-01-01", "checkout": "2025-01-02" },
        "additionalneeds": ""
      }
      """
    When method PUT
    # Restful Booker quirk: Bearer auth is silently rejected — cookie is mandatory
    Then status 403

  Scenario: GET /booking/{id} for a non-existing id returns 404
    Given path '/booking/999999'
    When method GET
    Then status 404

  Scenario: DELETE /booking/{id} for a non-existing id without auth returns 403
    # Auth check fires before the existence check
    Given path '/booking/999999'
    When method DELETE
    Then status 403

  Scenario: DELETE /booking/{id} for a non-existing id with auth returns 405
    # Restful Booker quirk: non-existing id + valid auth returns 405 Method Not Allowed
    Given path '/booking/999999'
    And cookie token = authToken
    When method DELETE
    Then status 405

  @invalid-payload
  Scenario: POST /booking with missing required fields returns 500
    # Single representative invalid-payload case — kept minimal to reduce the volume of
    # bad POSTs that can transiently throttle subsequent requests on the shared API.
    # Restful Booker quirk: invalid/incomplete payloads return 500 (not 400/422).
    # Tagged @invalid-payload so it can be excluded in CI if needed:
    #   --tags ~@invalid-payload
    Given path '/booking'
    And request read('classpath:data/invalid-booking.json')
    When method POST
    Then status 500
