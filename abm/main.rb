require_relative 'game'



=begin
g = Game.new
g.play!
g.print_log
=end

t = Time.now.to_i
10000.times{ g = Game.new; g.play! }
puts Time.now.to_i - t

=begin
t = Tavern.new(nil)
puts t.is_a?(Building)
=end