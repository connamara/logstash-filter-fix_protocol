module LogStashManager
  extend self

  def start_logstash
    logstash = ServiceManager.services.find { |s| s.name == 'LogStash' }
    return if logstash.running?
    ServiceManager.start { |s| s.name == 'LogStash' }
  end
end

World(LogStashManager)
