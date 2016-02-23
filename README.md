# Fix Message Logstash Filter

A LogStash filter plugin for FIX Message parsing

Given a FIX log file that looks like this:

```
2015-08-26 23:08:38,096 FIX.4.2:AIX->CQG: 8=FIX.4.29=18435=F34=249=CQG50=DefaultSenderSubID52=20150826-23:08:38.09456=AIX1=DefaultAccount11=clordid_of_cancel41=15101256954=155=ITER60=20250407-13:14:15167=FUT200=20151210=147
2015-08-31 17:48:20,890 FIXT.1.1:AIX->CQG: 8=FIXT.1.19=14035=W34=249=AIX52=20150831-17:48:20.89056=CQG22=9948=.AQUA-W262=golden_path_test268=1269=3270=640754272=20150831273=17:48:20.88210=070
2015-08-31 20:48:26,536 FIXT.1.1:AIX->CQG: 8=FIXT.1.19=18935=W34=549=AIX52=20150831-20:48:26.53556=CQG22=9948=ITRZ21262=req_A268=2269=0270=0.01005271=10272=20150831273=20:48:26.514269=1270=0.0101271=2272=20150831273=20:48:26.51410=123
```

The FIX Message filter plugin can read the FIX log as an input and turn it into something like this:

![alt tag](http://i.imgur.com/l8OKWvN.png)

## Development Environment

### Vagrant
```
vagrant up
```

### Manual Setup (OSX)
+ `rvm install jruby`
+ `rvm use jruby`
+ `bundle install`
+ `brew install logstash`

Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version, update the **version number** in `logstash-filter-fix_message_filter.gemspec`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Running Tests

```
# We're exporting JRUBY_OPTS to the JVM for faster boot
$ ./bin/rspec rspec
```

## Installation

1. Add the filter to your installation of LogStash

```ruby
# /opt/logstash/Gemfile
#...
gem "logstash-output-kafka"
gem "logstash-input-http_poller"
gem "logstash-filter-fix_message_filter"
```

2. Install the filter plugin

```
$ /opt/logstash/bin/plugin install
```

3. Start logstash installation with a LogStash configuration file.

```
$ /opt/logstash/bin/logstash -f /PATH/TO/logstash.conf
```

## Plugin Configuration

A sample FIX 5.0 would look something like the below. For FIX < 5.0, simply omit the `session_dictionary_path` and supply a `data_dictionary_path`.

```
input {
  file {
    path => "/PATH/TO/YOUR/FIX-MESSAGE.log"
    start_position => "beginning"
  }
}
filter {
  grok {
    match => ["message","%{TIMESTAMP_ISO8601:timestamp} %{GREEDYDATA:fix_string}: %{GREEDYDATA:fix_message}"]
  }
  fix_message_filter {
    message => fix_message
    session_dictionary_path => "/PATH/TO/FIX/5.0/SESSION/DICTIONARY/FIX.xml"
    data_dictionary_path => "/PATH/TO/FIX/5.0/DATA/DICTIONARY/FIX.xml"
  }
}
output {
  stdout { codec => rubydebug }
}

```

Notice, we're using the Grok filter to create a `fix_message` variable from a theoretical FIX Message log file. Then, we're passing that variable to our filter. You can see this emulated behavior in our specs.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/fix_logstash_plugin/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
