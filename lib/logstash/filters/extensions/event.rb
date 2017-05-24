
# monkey-patch deprecated breaking change from 5x
class LogStash::Event
  def [](key)
    respond_to?(:get) ? get(key) : super(key)
  end

  def []=(key, val)
    respond_to?(:set) ? set(key, val) : super(key, val)
  end
end
