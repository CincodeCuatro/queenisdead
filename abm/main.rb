require_relative 'game'


t = Tavern.new(nil)
puts t.is_a?(Building)

g = Game.new
g.play!
g.print_log

#p 10000.times.collect { g.play! }.include?(:fiveYears)

=begin
t = Tavern.new(nil)
puts t.is_a?(Building)
=end