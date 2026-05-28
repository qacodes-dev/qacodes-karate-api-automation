@regression
Feature: Delete Booking

  Background:
    * url baseUrl
    * def authResult = callonce read('classpath:features/auth/create-token.feature')
    * def authToken  = authResult.authToken
    * def createResult = call read('classpath:features/reusable/create-test-booking.feature')
    * def bookingId    = createResult.bookingId

  @smoke
  Scenario: DELETE /booking/{id} with cookie auth returns 201 Created
    Given path '/booking/' + bookingId
    And cookie token = authToken
    When method DELETE
    # Restful Booker quirk: DELETE returns 201 Created, not 200 or 204
    Then status 201

  Scenario: GET the deleted booking returns 404
    # First delete the booking created in Background
    Given path '/booking/' + bookingId
    And cookie token = authToken
    When method DELETE
    Then status 201
    # Now confirm it is gone
    Given path '/booking/' + bookingId
    When method GET
    Then status 404
