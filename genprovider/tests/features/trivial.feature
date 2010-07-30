Feature: Ability to parse a mof and create a template
  In Order to verify the basic functionality
  As a developer
  I want to generate a simple Ruby provider
  Then I should be able to read it
  And I should be able to get it compiled
  Scenario: Run genprovider
    Given nothing
    When I run genprovider with no arguments
    Then I should see a short usage explanation
  Scenario: Generate a simple provider
    Given I have a mof file called "trivial.mof"
    When I pass "trivial.mof" to genprovider redirecting its output to "output.rb"
    Then I should see an "output.rb" file
  Scenario: Ensure correct output format
    Given I have a mof file called "trivial.mof"
    When I pass "trivial.mof" to genprovider
    Then comment lines should not exceed "75" characters
    And it should be accepted by "ruby"  