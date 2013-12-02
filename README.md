## Overview
**HMS Notifier** manages programs, recipients and their subscriptions to
each program.  A _program_ is a series of messages that should be delivered
to a recipient over a period of time.  For example, a nine-month program
could be developed that delivers informational or supportive messages on
a weekly basis throughout an expectant monther's pregnancy.  The notifier
manages subscriptions that feed into the
[HMS Hub](https://github.com/dhedlund/hms-hub).

This software was developed to support objectives outlined in the CCPF
program.


### About the CCPF Program
The VillageReach CCPF program, CHIPATALA CHA PA
FONI, means "Health Center by Phone" in the Malawian language of Chichewa.
The program is focused on maternal & child health improvement, through
increased access to basic health information, and prompting towards earlier
interaction with the health system.  The program has two components:  a
toll-free hotline for pregnancy & infant health advice and referrals,  and a
health-tip messaging system, which pushes SMS and voice messages out to
rural clients who have been enrolled in the tips system.  The program
enjoyed a successful pilot over 2 years, from 2011-2013, handling hundreds
of callers per week,  and is now in the process of expanding its reach.

The software used by the hotline workers to record caller interaction is
[mnch-hotline](https://github.com/BaobabHealthTrust/mnch-hotline), developed
by the Malawian health-software company
[Baobab Health Trust](http://baobabhealth.org/). The software to handle the
tips-message distribution, [HMS-Hub](https://github.com/dhedlund/hms-hub),
and [HMS-Notifier](https://github.com/dhedlund/hms-notifier), were developed
by [VillageReach](http://villagereach.org/).  All components are in active
production use in Malawi.

### Messaging System
The tips-messaging system is designed to operate
robustly in a environment with intermittent connectivity, and multiple
remote messaging sources.  The Hub software is intended to be on a
relatively better-connected server.  It centralizes handling of all the
message-delivery gateways (SMS, IVR, email, etc) and serves as a capable
store-and-forward.  Each authorized instance of the Notifier software
connects to the Hub periodically to issue a new set of message requests, and
receive data on message-attempt results.  Both apps expect an unreliable
Hub-Notifier connection, and to a lesser extent, an unreliable connection
between the Hub and its messaging gateways.  The Hub also handles its own
retries of failed messages, for when the gateway does not.

In production practice, in Malawi, the Hub is in a telco server room, on the
telco's network connection.  The currently single Notifier instance on the
hotline server, located in a rural district hospital, where the hotline
workers have local oversight in the pilot program.  The Notifier connects
via a USB dongle, over a private APN on the telco's 2G network.  The
software handles regular downtime between those servers, and the Hub handles
SMS and voice messages that often take multiple retries to reach customer
phones, which are often out of range or powered down.


## Getting Started
It is assumed that you have ruby version 1.9.3, are using bundler and have the necessary mysql headers to compile the `mysql2`
gem.

```plain
git clone git://github.com/dhedlund/hms-notifier.git hms-notifier
cd hms-notifier
bundle install
bundle exec rake db:create db:schema:load db:seed
bundle exec rails s -blocalhost
```


## Running Tests
```plain
bundle exec rake test # all tests
bundle exec rake test:units # unit tests
bundle exec rake test:functionals # functional/controller tests
TEST=test/unit/notification_test.rb bundle exec rake test # single test file
```
