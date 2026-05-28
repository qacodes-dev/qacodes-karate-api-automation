Feature: Create Auth Token

  Background:
    * url baseUrl

  Scenario: POST /auth returns a valid token
    Given path '/auth'
    And request { username: '#(username)', password: '#(password)' }
    # retry until a 200 is observed — handles transient 418/429/5xx from the shared public API
    And retry until responseStatus == 200
    When method POST
    Then status 200
    And match response.token == '#string'
    * def authToken = response.token
