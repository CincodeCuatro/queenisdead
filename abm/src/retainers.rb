require_relative 'pieces'
require_relative 'actions'


######################
### Retainer Cards ###
######################

### Retainer card base class

class Retainer < Card
  attr_accessor :master
  attr_reader :bluff

  # Init
  def initialize(deck)
    super()
    @deck = deck # The retainer-deck this card belongs to 
    @master = nil # The character this retainer is attached to
    @bluff = nil # An instance of another retainer card that this one is bluffing (if any)
  end
  
  # Return this card to the retainer deck, remove it from its master, and reset it
  def reshuffle
    @deck.tuck(self)
    initialize(@deck)
  end

  # The class of this retainer card (if face up)
  # or the class of the card it is bluffing as (if bluffing)
  def appears_as
    return @bluff.class if !@bluff.nil?
    self.class
  end

  # Returns whether this retainer is attached to a character adjacent to this target
  def is_adjacent_to_character?(target)
    b = @deck.board
    ml, tl = @master.location, target.location
    return b.court.adjacent?(@master, b.master) if ml == b.court && tl == b.court
    b.buildings.adjacent?(ml, tl) if ml.is_a?(Building) && tl.is_a?(Building)
    return false
  end

  # Checks to make sure the target is an adjacent character
  # If not, raises and exception
  def assert_adjacent!(target)
    raise "#{target} is not adjacent to: #{@master}" unless is_adjacent_to_character(target)
  end

  # Attached this retainer to an in-play character
  # If bluff_as is supplied, play the card face down and bluff as that class
  def attach(character, bluff_as=nil)
    @master = character
    set_location(@master.retainer)
    @master.retainer.set(self)
    @bluff = bluff_as.new if !bluff_as.nil?
  end

  def detach
    @master&.retainer.remove(self)
    set_location(nil)
    initialize(deck)
  end

  # An effect the player that owns this card may play on their turn
  # The effect is either the perk of this card (if face up)
  # or the perk of the card this one is bluffing as (if bluffing)
  # Specific perk methods may have a target parameter, which is the character it acts upon
  def perk
  end

  # A one time use effect that the player that owns this card may play on their turn
  # The effect of a retainer is always the action of the actual card (even if bluffing)
  # Using the action of a retainer reveales it (if bluffing)
  # Specific action methods may have a target parameter, which is the character it acts upon
  # If an action is used against a character with a bluffed retainer, that retainer is revealed before the effect is applied
  def action
  end

  # If this retainer is bluffing and is revealed and the card does not match its bluff
  # Then the player that owns it loses 2 prestige and may incure an additional effect
  # (if specified by the specific retainer card, this effect is the one of the bluffed card)
  def bluff_fail
    @master.take({ prestige: 2 })
  end

  # If bluffing reveal this card, and if the card does not match its bluff run bluff_fail
  def reveal
    @bluff.bluff_fail if !bluff.nil?
    bluff = nil
  end

end



### Retainers

# The Barber keeps your character well manicured in court earning +2 prestige when called on. Beware his treacherous blade. 
class Barber < Retainer
  def perk
    @master.player.give({ prestige: 2 })
  end

  def bluff_fail
    super()
    @master.kill
    return_to_deck
  end
end

# The Bard can sing your priases in court earning +2 prestige. He may also insult adjacent characters which lose 2 prestige.
class Bard < Retainer
  def perk(target)
    if target == @master
      @master.player.give({ prestige: 2 })
    else
      assert_adjacent!(target)
      target.player.take({ prestige: 2 })
    end
  end

  def bluff_fail
    super()
    @master.punish
    return_to_deck
  end

end

# The Barrister negates upkeep cost for a character on Campaign or imprisoned. If caught in a lie he will be punished accordingly. 
class Barrister < Retainer
  def bluff_fail
    super()
    if @master.imprisoned?
      @master.kill
    elsif @master.campaigning?
      @master.punish
    end
    return_to_deck
  end
end

# The Bodyguard protects a character from direct attack, namely from the Rogue
class BodyGuard < Retainer
end

# The Courtesan may perform a saucy puppet show gaining +1 gold for all adjacent characters. Beware, infidelity will cost you prestige
class Courtesan < Retainer
  def perk
    @master.adjacent.each { |c| c.player.take({ gold: 1 }) }
    @master.player.give({ gold: @master.adjacent.length })
  end

  def bluff_fail
    super()
    @master.take({ prestige: 2 })
  end
end

# The Cupbearer may gain +1 food by gathering tablescraps. His purpose is to uncover poison, but beware his spoiled food.
class Cupbearer < Retainer
  def perk
    @master.player.give({ food: 1 })
  end

  def bluff_fail
    super()
    @master.take({ food: 5 })
  end
end

# TODO: Implement
# The Eunuch may gain +2 prestige in court.
# Special - reveal any adjacent retainer card in play and resolve the negative effect on that character. 
# Special - Visit the tavern and turn this card in to start a Plot
class Eunuch < Retainer
end

# The Huntmaster gains +3 food for his master on a successful hunt. Beware the hunting accident.
class Huntmaster < Retainer
  def perk
    @master.player.give({ food: 3 })
  end

  def bluff_fail
    super()
    @master.kill
    return_to_deck
  end
end

# The Jester may gain +1 gold for entertaining guests.
# Special - Swap the adjacent target retainer with an a new random retainer from the deck
class Jester < Retainer
  def perk
    @master.player.give({ gold: 1 })
  end

  def action(target)
    assert_adjacent!(target)
    target.master = @deck.draw
    return_to_deck
  end
end

# The Monk earns +1 food and +1 prestige for his services in court. Beware of his heresey. 
class Monk < Retainer
  def perk
    @master.player.give({ food: 1, prestige: 1 })
  end

  def bluff_fail
    super()
    @master.punish
    return_to_deck
  end
end

# The Physician gains +2 prestige in court for his services. 
# Special - pay 10 gold and target an adjacent family character to poison. Sending them home. 
# Countered by Cupbearer
class Physician < Retainer
  def perk
    @master.player.give({ prestige: 2 })
  end

  def action(target)
    assert_adjacent!(target)
    cost = 10
    if @master.player.gold >= cost
      @master.player.take({ gold: cost })
      unless target.retainer.is_a?(Cupbearer)
        target.move(nil)
        return_to_deck
      end
    else
      raise "Player doesn't have enough gold for this action"
    end
  end
end

# The Rogue - Pay 25 gold and target any character in play. 
# Countered by the Bodyguard
class Rogue < Retainer
  def action(target)
    cost = 25
    if @master.player.gold >= cost
      @master.player.take({ gold: cost })
      unless target.retainer.is_a?(BodyGuard)
        target.kill
        return_to_deck
      end
    else
      raise "Player doesn't have enough gold for this action"
    end
  end 
end