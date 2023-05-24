require_relative 'game'
require_relative 'actions'
require_relative 'not_terrible_strats'



strats = load_strats("strats-run0.json")
g = Game.new(4, Array.new(4) { strats.sample })
g.play!
g.print_log



def find_best_strategies(strategies, top_n)
  wins = strategies.map { |s| [s, 0] }.to_h
  strategies.each_with_index do |s, i|
    100.times do
      g = Game.new(4, [s] + Array.new(3) { (strategies-[s]).sample } )
      win_reason, winner = g.play!
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

=begin
game_ends = Hash.new(0)
100.times {
  strats = Array.new(4) { Not_terrible_strats.sample }
  g = Game.new(4, strats)
  ge, _ = g.play!
  game_ends[ge] += 1
}
puts game_ends
=end

=begin
t = Time.now.to_i

tier_3 = Array.new(50) { Priorities.new }
tier_2 = find_best_strategies(tier_3, 10)
#tier_1 = find_best_strategies(tier_2.map(&:first), 100)

tier_2.each { |s, n| puts "Strategy: #{s.show} won #{n} times" }
save_strats("strats-run0.json", tier_2.map(&:first))


puts Time.now.to_i - t
=end