require_relative 'containers'
require_relative 'pieces'
require_relative 'actions'


####################
### Crisis Cards ###
####################

### Crisis card base class
class Crisis < Card
  def initialize(deck) = @deck = deck
end

# Regecide - the king dies of mysterious causes
class Regecide < Crisis
  def activate
    crown = @deck.board.crown.contents
    return if crown.nil?
    @deck.board.game.log("A regicide has taken place, the crown (#{crown.name}) is dead!")
    crown.kill
  end
end

# Blight - no farms work this year
class Blight < Crisis
  def activate
    @deck.board.game.log("A blight has befallen the land, farms produce no food this year!")
  end
end

# Plague - all players without worker in apothecary loses random family character
class Plague < Crisis
  def activate
    @deck.board.game.log("A plague has swept the countryside, two characters from each family have fallen!")
    @deck.board.game.players.each do |player|
      if !player.worked_buildings.any? { |b| b.is_a?(Apothecary) }
        player
          .characters
          .filter { |c| ![:dungeon, :crypt].include?(c.where_am_i?) }
          .take(2)
          .map(&:kill)
      end
    end
  end
end

# Powder Plot - all characters in court have been exploded
class Powderplot < Crisis
  def activate
    @deck.board.game.log("A powderplot has taken place, all members of the court have been vaporized!")
    @deck.board.court.contents.map(&:contents).compact.map(&:kill)
    [:crown, :priest, :commander, :treasurer, :spymaster].each { |office| @deck.board.get_office(office).contents&.kill }
  end
end




