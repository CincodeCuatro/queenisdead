require_relative 'game'
require_relative 'effects'

############
### Main ###
############

def sim(player_num, strats_pool=nil, debug=false)
  strats = Array.new(player_num) { strats_pool ? strats_pool.sample : Priorities.new }
  game = Game.new(player_num, strats)
  outcome = game.play!
  game.print_log(debug)
  return outcome
end

def arena(strats_pool, top_n, game_num)
  strats_pool
    .map { |s| [s, calc_performance(s, game_num, strats_pool)] }
    .sort_by { |s, n| n }
    .reverse
    .take(top_n)
end

def calc_performance(strat, game_num=100, strats_pool=nil)
  strats_pool ||= Array.new(game_num) { Priorities.new }
  strats_pool -= [strat]
  wins = 0
  game_num.times do
    other_strats = Array.new(player_num-1) { strats_pool.sample }
    game = Game.new(4, [s] + other_strats)
    _, winner = game.play!
    wins += 1 if winner == 0
  end
  return game_num.to_f / wins
end

def game_ends(strats_pool=nil, game_num=100)
  strats_pool ||= Array.new(game_num) { Priorities.new }
  game_ends = Hash.new(0)
  game_num.times {
    strats = Array.new(4) { strats_pool.sample }
    game = Game.new(4, strats)
    end_type, _ = game.play!
    game_ends[end_type] += 1
  }
  return game_ends
end

