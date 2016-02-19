require 'service_manager'

# color guide
#0  Reset all attributes
#1  Bright
#2  Dim
#4  Underscore
#5  Blink
#7  Reverse
#8  Hidden

# Foreground Colours
#30 Black
#31 Red
#32 Green
#33 Yellow
#34 Blue
#35 Magenta
#36 Cyan
#37 White

# Background Colours
#40 Black
#41 Red
#42 Green
#43 Yellow
#44 Blue
#45 Magenta
#46 Cyan
#47 White

module ServiceManager
  SERVICES_PATH = "./features/support/services.rb"
end

ServiceManager.define_service 'LogStash' do |s|
  s.host = "localhost"
  s.port = 8001
  s.cwd = Dir.pwd
  s.start_cmd = "./bin/smart_logstash -f #{File.expand_path('../', __FILE__)}/logstash.conf"
  s.color = 33
  s.timeout = 60
end
