require_relative 'game'

=begin
g = Game.new
g.play!
g.print_log
=end

t = Time.now.to_i
1000.times{ g = Game.new; g.play!; g.print_log }
puts Time.now.to_i - t