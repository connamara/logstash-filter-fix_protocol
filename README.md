# FIX Protocol Logstash Filter [![Build Status](https://travis-ci.org/connamara/logstash-filter-fix_protocol.svg?branch=master)](https://travis-ci.org/connamara/logstash-filter-fix_protocol)

A LogStash filter plugin for FIX Message parsing

Given a FIX log file that looks like this:

```
2015-08-26 23:08:38,096 FIX.4.2:DUMMY_INC->ANOTHER_INC: 8=FIX.4.29=18435=F34=249=ANOTHER_INC50=DefaultSenderSubID52=20150826-23:08:38.09456=DUMMY_INC1=DefaultAccount11=clordid_of_cancel41=15101256954=155=ITER60=20250407-13:14:15167=FUT200=20151210=147
2015-08-31 17:48:20,890 FIXT.1.1:DUMMY_INC->ANOTHER_INC: 8=FIXT.1.19=14035=W34=249=DUMMY_INC52=20150831-17:48:20.89056=ANOTHER_INC22=9948=.AQUA-W262=golden_path_test268=1269=3270=640754272=20150831273=17:48:20.88210=070
2015-08-31 20:48:26,536 FIXT.1.1:DUMMY_INC->ANOTHER_INC: 8=FIXT.1.19=18935=W34=549=DUMMY_INC52=20150831-20:48:26.53556=ANOTHER_INC22=9948=ITRZ21262=req_A268=2269=0270=0.01005271=10272=20150831273=20:48:26.514269=1270=0.0101271=2272=20150831273=20:48:26.51410=123
```

The FIX Message filter plugin can read the FIX log as an input and turn it into something like this:

![alt tag](http://i.imgur.com/gkeStss.png)

## Installation
```
$ /opt/logstash/bin/plugin install logstash-filter-fix_protocol
```

## Plugin Configuration

| Setting                 | Input type      | Required | Default Value      |
| ----------------------- | ----------------| ---------| ------------------ |
| fix_message             | string/variable | Yes      | "message"          |
| data_dictionary_path    | string          | Yes      | "/PATH/TO/YOUR/DD" |
| session_dictionary_path | string          | No       | nil                |

**fix_message**
+ value type is a string
+ required

Should be the actual fix message passed to the filter. You might need to use a separate filter, like grok, to parse a log and set a fix string variable.

**data_dictionary_path**
+ value type is a string
+ required

Should be the absolute path to your data dictionary xml file.

**session_dictionary_path**
+ value type is a string
+ Not required

Should be the absolute path to your session dictionary xml file for FIX versions > 5.0. Note, if you do not set this but are using FIX 5.0, the filter will still work, but admin messages won't be correctly parsed - you'll lose data. The filter ignores key-value pairs that it doesn't parse correctly.

**Sample Config File**

*Note: For FIX < 5.0, simply omit the `session_dictionary_path`.*

```
input {
  file {
    path => "/PATH/TO/YOUR/FIX-MESSAGE.log"
    start_position => "beginning"
  }
}
filter {
  grok {
    match => ["message","%{TIMESTAMP_ISO8601:timestamp} %{GREEDYDATA:fix_session}: %{GREEDYDATA:fix_string}"]
  }
  fix_protocol {
    fix_message => fix_string
    session_dictionary_path => "/PATH/TO/FIX/5.0/SESSION/DICTIONARY/FIX.xml"
    data_dictionary_path => "/PATH/TO/FIX/5.0/DATA/DICTIONARY/FIX.xml"
  }
}
output {
  stdout { codec => rubydebug }
}

```
**Sample Config File For Multiple FIX Versions**
```
input {
  file {
    path => "/path/to/fix.log"
    start_position => "beginning"
  }
}
filter {
  grok {
    match => ["message","%{TIMESTAMP_ISO8601:timestamp} %{GREEDYDATA:fix_session}: %{GREEDYDATA:fix_string}"]
  }
  if [message] =~ "=FIX.4.2" {
    fix_protocol {
      fix_message => fix_string
      data_dictionary_path => "/path/to/datadict/FIX42.xml"
    }

  if [message] =~ "=FIX.4.4" {
    fix_protocol {
      fix_message => fix_string
      data_dictionary_path => "/path/to/datadict/FIX44.xml"
    }
  }
  if [message] =~ "=FIX.5.0" {
    fix_protocol {
      fix_message => fix_string
      data_dictionary_path => "/path/to/datadict/FIX50.xml"
    }
  }

  }
}
output {
  stdout { codec => rubydebug }
}


```

Notice, we're using the Grok filter to create a `fix_message` variable from a theoretical FIX Message log file. Then, we're passing that variable to our filter. You can see this emulated behavior in our specs.

## Development Environment

To get set up quickly, we recommend using Vagrant with the Ansible provisioning available in this source repository.

### Setup with Vagrant

* Install [Ansible](http://www.ansible.com/)
* Install [VirtualBox](https://www.virtualbox.org)
* Install [Vagrant](http://www.vagrantup.com/)

Then,

```
vagrant up
```

### Manual Setup (OSX)
+ `rvm install jruby`
+ `rvm use jruby`
+ `bundle install`
+ `brew install logstash`

Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version, update the **version number** in `logstash-filter-fix_protocol.gemspec`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

*Note: If you get an error message about metadata, you'll need to update to ruby gems > 2.0. Run `gem update --system`*

### Running Tests

```
$ ./bin/rspec rspec
```

### Logstash 2x vs 5x

Remove any installed versions of logstash and install your desired version.

After you've completed the 'Manual change' or 'Ansible provisioning change' below, follow instructions for 'Development Logstash Installation'

#### Manual change:

Change the version number in `lib/logstash/filters/version.rb` 

```ruby
module Logstash
  VERSION = '2.x'
end
```

#### Ansible provisioning change:

Change the version number in `provision/group_vars/all.yml`

```yml
logstash_version: 5.x # -> 2.x
```

Run vagrant provision:

```
vagrant provision
```

### Development Logstash Installation

1. Add the filter to your installation of LogStash

    ```ruby
    # /opt/logstash/Gemfile
    #...
    gem "logstash-output-kafka"
    gem "logstash-input-http_poller"
    gem "logstash-filter-fix_protocol", :path => "/PATH/TO/YOUR/FORK"
    ```

2. Install the filter plugin

    ```
    $ /opt/logstash/bin/plugin install --no-verify
    ```

3. Start logstash installation with a LogStash configuration file.

    ```
    $ /opt/logstash/bin/logstash -f /PATH/TO/logstash.conf
    ```

## Contributing

Contributions are welcome!  Please see the [Contribution Guidelines](CONTRIBUTING.md) for details.

![Connamara Systems](http://www.connamara.com/wp-content/uploads/2016/01/connamara_logo_dark.png)

FIX Message Logstash Filter is maintained and funded by [Connamara Systems, llc](http://connamara.com).

The names and logos for Connamara Systems are trademarks of Connamara Systems, llc.

## Licensing

FIX Message Logstash Filter is Copyright © 2016 Connamara Systems, llc.

This software is available under the Apache license and a commercial license.  Please see the [LICENSE](LICENSE.txt) file for the terms specified by the Apache license.  The commercial license offers more flexible licensing terms compared to the Apache license, and includes support services.  [Contact us](mailto:info@connamara.com) for more information on the Connamara commercial license, what it enables, and how you can start commercial development with it.

This product includes software developed by quickfixengine.org ([http://www.quickfixengine.org/](http://www.quickfixengine.org/)). Please see the [QuickFIX Software LICENSE](QUICKFIX_LICENSE.txt) for the terms specified by the QuickFIX Software License.
