

class Action

  def initialize(player, desc, action)
    @player = player
    @description = desc
    @action = action
  end

  def run(game)
    @action.call
    game.add_to_log(self)
  end

  def desc
    "Player #{@player.id}: #{@description}"
  end

  def from_crown
    @description = "As ordered by the crown: " + @description
    return self
  end

end


# TODO: This class is redundant (check treasurer audit action; pre determined outcomes)

class ChallengeAction

  def initialize(player, succ_desc, succ_action, fail_desc, fail_action)
    @success = Action.new(player, succ_desc, succ_action)
    @failure = Action.new(player, fail_desc, fail_action)
  end

  def run(game)
    if game.challenge
      @success.run(game)
    else
      @failure.run(game)
    end
  end

end