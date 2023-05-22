require_relative 'game'




g = Game.new
g.play!
g.print_log


=begin
t = Time.now.to_i
1000.times{ g = Game.new; g.play! }
puts Time.now.to_i - t
=end