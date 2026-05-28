@regression
Feature: Create Booking

  Background:
    * url baseUrl

  @smoke
  Scenario: POST /booking returns 200 with bookingid and echoed fields
    Given path '/booking'
    And request read('classpath:data/valid-booking.json')
    And retry until responseStatus == 200
    When method POST
    Then status 200
    And match response.bookingid == '#number'
    And match response.booking.firstname    == '#string'
    And match response.booking.lastname     == '#string'
    And match response.booking.totalprice   == '#number'
    And match response.booking.depositpaid  == '#boolean'
    And match response.booking.bookingdates.checkin  == '#string'
    And match response.booking.bookingdates.checkout == '#string'

  Scenario: Created booking echoes the exact request values
    * def payload = read('classpath:data/valid-booking.json')
    Given path '/booking'
    And request payload
    And retry until responseStatus == 200
    When method POST
    Then status 200
    And match response.booking.firstname   == payload.firstname
    And match response.booking.lastname    == payload.lastname
    And match response.booking.depositpaid == payload.depositpaid

  @datadriven
  Scenario Outline: Create booking with data-driven CSV examples
    Given path '/booking'
    And request
      """
      {
        "firstname":     "<firstname>",
        "lastname":      "<lastname>",
        "totalprice":    <totalprice>,
        "depositpaid":   <depositpaid>,
        "bookingdates":  {
          "checkin":  "<checkin>",
          "checkout": "<checkout>"
        },
        "additionalneeds": "<additionalneeds>"
      }
      """
    And retry until responseStatus == 200
    When method POST
    Then status 200
    And match response.bookingid   == '#number'
    And match response.booking.firstname == '<firstname>'
    And match response.booking.lastname  == '<lastname>'

    Examples:
      | read('classpath:data/booking-examples.csv') |
