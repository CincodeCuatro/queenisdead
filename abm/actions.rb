require_relative 'utils'

class Action

  attr_accessor :effects

  def initialize(player, desc, action, effects)
    @player = player
    @description = desc
    @action = action
    @effects = effects.is_a?(Hash) ? Effects.new(effects) : effects
  end

  def run(game)
    @action.call
    game.add_to_log(desc)
  end

  def desc
    color_text("Player #{@player.id}: #{@description}", @player.id)
  end

  def from_crown
    @description = "As ordered by the crown: " + @description
    return self
  end

end


# TODO: This class is redundant (check treasurer audit action; pre determined outcomes)

class ChallengeAction

  attr_accessor :effects

  def initialize(success, failure)
    @success = success
    @failure = failure
    @effects = success.effects + { risk: 3 }
  end

  def run(game) = game.challenge ? @success.run(game) : @failure.run(game)

end


class Effects

  attr_accessor :effects
  
  def initialize(effects)
    @effects = { gold: 0, food: 0, prestige: 0, reputation: 0, power: 0, risk: 0, karma: 0 }.merge(effects)
  end

  def +(x) = Effects.new(@effects.merge(x.is_a?(Effects) ? x.effects : x) { |_, a, b| a + b })

  def *(x) = Effects.new(@effects.merge(x.is_a?(Effects) ? x.effects : x) { |_, a, b| a * b })

  def inverse = Effects.new(@effects.transform_values { |v| v * -1 })

  def scale(n) = Effects.new(@effects.transform_values { |v| n * v })

end


=begin
### GOALS ###
- Gold
- Food
- Prestige
- Power
- Risk
- Karma
=end