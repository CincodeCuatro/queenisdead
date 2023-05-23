require_relative 'game'
require_relative 'actions'

=begin
g = Game.new
g.play!
g.print_log
=end

t = Time.now.to_i

def find_best_strategies(strategies, top_n)
  wins = strategies.map { |s| [s, 0] }.to_h
  strategies.each_with_index do |s, i|
    100.times do
      g = Game.new(4, [s] + Array.new(3) { (strategies-[s]).sample } )
      winner = g.play!
      wins[s] += 1 if winner == 0
    end
    puts "Strategy #{i+1} of #{strategies.length} done."
  end
  return wins
    .to_a
    .sort_by { |s, n| n }
    .reverse
    .take(top_n)
end

tier_3 = Array.new(10000) { Priorities.new }
tier_2 = find_best_strategies(tier_3, 1000)
tier_1 = find_best_strategies(tier_2.map(&:first), 100)

tier_1.each { |s, n| puts "Strategy: #{s.effects.inspect} won #{n} times" }

puts Time.now.to_i - t