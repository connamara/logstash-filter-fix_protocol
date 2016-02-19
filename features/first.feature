@logstash @beta
Feature:  The LogStash Filter can parse a FIX message log file

Background:
  Given fix message log "fix-input.log"

Scenario: Hey DJ, parse dat shit!
  Given the logstash filter parses the log

  Then I should see the following fix messages:
  | INSTITUTION   | SIDE   | COUNTERPARTY  | AMOUNT     | RATE  | REPAYMENT DATE | AMOUNT OWED (DUE) | STATUS |
  | Institution 1 | Borrow | CCP           | $1,000,000 | 0.110 | 2014/12/29     | ($1,000,006.11)   | Busted |
  | Institution 3 | Lend   | CCP           | $1,000,000 | 0.110 | 2014/12/29     | $1,000,006.11     | Busted |


