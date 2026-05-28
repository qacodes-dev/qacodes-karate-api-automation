@ignore
Feature: Delete Test Booking (Reusable)
# Called by other features for post-scenario cleanup.
# Expects: bookingId (int), authToken (string)

  Background:
    * url baseUrl

  Scenario: Delete a booking by id with cookie auth
    Given path '/booking/' + bookingId
    And cookie token = authToken
    When method DELETE
    # Restful Booker quirk: DELETE returns 201 Created, not 200/204
    Then status 201
