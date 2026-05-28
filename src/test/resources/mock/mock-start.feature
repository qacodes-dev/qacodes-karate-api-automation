@ignore
Feature: Boot Restful Booker mock server
# Called exactly once per JVM via karate.callSingle() from karate-config.js.
# Exports: port (int)

  Scenario: start mock
    * def server = karate.start('classpath:mock/restful-booker-mock.feature')
    * def port = server.port
