module LogStashManager
  extend self
  SERVICE = 'LogStash'

  def start_logstash
    logstash = ServiceManager.services.find { |s| s.name ==  SERVICE }
    logstash.start unless logstash.running?
  end
end

World(LogStashManager)
