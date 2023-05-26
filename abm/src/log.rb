require_relative 'utils'


#################
### Event Log ###
#################

### Log of game events
class EventLog
  def initialize = @log = []
  def g(m) = @log << GameEvent.new(m)
  def p(m, i) = @log << PlayerEvent.new(m, i)
  def d(m, s) = @log << DebugEvent.new(m, s)
  def pp(d=false) = @log.each do |e|
    case e
    when GameEvent; puts "========> #{e.msg}"
    when PlayerEvent; puts "Player #{e.pid}: #{color_text(e.msg, e.pid)}"
    when DebugEvent; puts "********> #{e.msg} #{e.state || ''}" if d
    else raise "Logging Error - Unknown event class: #{e.class}"
    end
  end
end

### Events
GameEvent = Struct.new :msg
PlayerEvent = Struct.new :msg, :pid
DebugEvent = Struct.new :msg, :state