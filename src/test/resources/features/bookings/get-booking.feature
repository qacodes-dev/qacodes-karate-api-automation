@regression
Feature: Get Booking

  Background:
    * url baseUrl
    * def createResult = call read('classpath:features/reusable/create-test-booking.feature')
    * def bookingId    = createResult.bookingId

  @smoke
  Scenario: GET /booking/{id} returns 200 with flat booking shape (no wrapper)
    Given path '/booking/' + bookingId
    When method GET
    Then status 200
    # GET response is FLAT — no "booking" wrapper, no "bookingid" field
    And match response.firstname   == '#string'
    And match response.lastname    == '#string'
    And match response.totalprice  == '#number'
    And match response.depositpaid == '#boolean'
    And match response.bookingdates.checkin  == '#string'
    And match response.bookingdates.checkout == '#string'

  @schema
  Scenario: GET /booking/{id} matches booking schema
    Given path '/booking/' + bookingId
    When method GET
    Then status 200
    And match response == read('classpath:schemas/booking-schema.json')

  Scenario: GET /booking/{id} values match those set at creation
    * def created = createResult.booking
    Given path '/booking/' + bookingId
    When method GET
    Then status 200
    And match response.firstname   == created.firstname
    And match response.lastname    == created.lastname
    And match response.depositpaid == created.depositpaid
