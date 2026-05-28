@ignore
Feature: Create Test Booking (Reusable)
# Called by other features to set up independent test data.
# Returns: bookingId (int), booking (object)
# `retry until responseStatus == 200` handles transient 418/429/5xx throttling
# from the shared public API.

  Background:
    * url baseUrl

  Scenario: Create a booking and expose its id and fields
    Given path '/booking'
    And request
      """
      {
        "firstname": "Test",
        "lastname":  "User",
        "totalprice": 150,
        "depositpaid": true,
        "bookingdates": {
          "checkin":  "2025-01-01",
          "checkout": "2025-01-07"
        },
        "additionalneeds": "Breakfast"
      }
      """
    And retry until responseStatus == 200
    When method POST
    Then status 200
    * def bookingId = response.bookingid
    * def booking   = response.booking
