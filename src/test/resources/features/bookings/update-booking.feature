@regression
Feature: Update Booking

  Background:
    * url baseUrl
    * def authResult = callonce read('classpath:features/auth/create-token.feature')
    * def authToken  = authResult.authToken

  Scenario: Full update (PUT) with cookie auth returns 200 and reflects changes
    * def createResult = call read('classpath:features/reusable/create-test-booking.feature')
    * def bookingId    = createResult.bookingId
    Given path '/booking/' + bookingId
    And cookie token = authToken
    And request
      """
      {
        "firstname":    "Updated",
        "lastname":     "Person",
        "totalprice":   999,
        "depositpaid":  false,
        "bookingdates": {
          "checkin":  "2025-06-01",
          "checkout": "2025-06-10"
        },
        "additionalneeds": "Lunch"
      }
      """
    When method PUT
    Then status 200
    And match response.firstname  == 'Updated'
    And match response.lastname   == 'Person'
    And match response.totalprice == 999
    And match response.depositpaid == false
    # Cleanup
    * call read('classpath:features/reusable/delete-test-booking.feature') { bookingId: #(bookingId), authToken: '#(authToken)' }

  Scenario: Partial update (PATCH) with cookie auth returns 200 and reflects changes
    * def createResult = call read('classpath:features/reusable/create-test-booking.feature')
    * def bookingId    = createResult.bookingId
    Given path '/booking/' + bookingId
    And cookie token = authToken
    And request { firstname: 'Patched', lastname: 'Name' }
    When method PATCH
    Then status 200
    And match response.firstname == 'Patched'
    And match response.lastname  == 'Name'
    # Cleanup
    * call read('classpath:features/reusable/delete-test-booking.feature') { bookingId: #(bookingId), authToken: '#(authToken)' }
