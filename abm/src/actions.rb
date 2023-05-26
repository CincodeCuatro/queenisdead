require_relative 'utils'
require_relative 'effects'

###############
### Actions ###
###############

## Potential action a player may take on their turn
class Action

  attr_accessor :player, :effects

  def initialize(player, desc, action, effects)
    @player = player # the player doing the action
    @description = desc # a description of the action performed (past tense)
    @action = action # a closure representing the action
    @effects = effects.is_a?(Hash) ? Effects.new(effects) : effects
  end

  def desc = @description

  # Run the action and log it
  def run(game)
    @action.call
    game.log(self)
  end

  # Used for crown delegate actions
  def from_crown
    @description = "As ordered by the crown: " + @description
    return self
  end

end


# Specialized action class for branching actions which involve a challenge (non-deterministic)
class ChallengeAction

  attr_accessor :effects, :desc

  def initialize(success, failure)
    @success = success # Action instance representing challenge success
    @failure = failure # Action instance representing challenge failure
    @effects = success.effects + { risk: 3 } # Challenge actions have an added risk
    @desc = "( #{success.desc} | #{failure.desc} )"
  end

  def run(game) = game.challenge ? @success.run(game) : @failure.run(game)

end