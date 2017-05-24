
# monkey-patch deprecated breaking change from 5x
class LogStash::Event
  alias :[]  :get if method_defined?(:get)
  alias :[]= :set if method_defined?(:set)
end
