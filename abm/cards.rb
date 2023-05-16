
#############################
### Abstract Card Classes ###
#############################

### Parent class for cards
class Card < Piece
end

### Building cards
class Building < Card
  attr_reader :cost, :workers, :worker_num, :office_unlock, :manager
  
  # Init
  def initialize(deck)
    @deck = deck # The building-deck this card belongs to 
    @cost = 0 # Cost of this building
    @workers = [] # List of players that have workers on this building (players can appear multiple times)
    @worker_num = 0 # Maximum number of workers
    @office_unlock = nil # Which office (if any) this building unlocks
    @manager = nil # The character that is managing this building (if any)
  end

  # Reset and reshuffle this card back into the deck
  def reshuffle
    @deck.tuck(self)
    initialize(@deck)
  end

  # Apply building effects to relevant players
  def output
  end

  ## TODO: Implement
  def build(pos)

  end

  # Called when this building is destroyed and put back into the deck
  # If the building has a manager, they get killed
  # Move all workers back to their player's hand
  # The exception is if office_unlock is not nil, in this case the building is permanent
  def destroy
    if @office_unlock.nil?
      @manager&.kill
      @workers.each { |w| w.move(nil) }
      reshuffle
    end
  end

  # Make the provided character this building's manager (if there isn't already a manager)
  def place_character(character)
    raise "Building already has a manager #{@manager}" if !@manager.nil?
    @manager = character
  end

  # Remove the current manager
  def remove_character(_character)
    raise "Building has no manager" if @manager.nil?
    @manager = nil
  end

  # Add the provided worker to this card's worker pool (if there's capacity for it)
  def place_worker(worker)
    raise "Building already at max worker capacity" if @workers.length >= @worker_num
    @workers << worker
  end

  # Remove the provided worker from this card's worker pool
  def remove_worker(worker)
    raise "Worker not positioned here" if !@workers.delete(worker)
  end

end


### Retainer cards
class Retainer < Card
  attr_accessor :master
  attr_reader :bluff

  # Init
  def initialize(deck)
    @deck = deck # The retainer-deck this card belongs to 
    @master = nil # The character this retainer is attached to
    @bluff = nil # An instance of another retainer card that this one is bluffing (if any)
  end
  
  # Return this card to the retainer deck, remove it from its master, and reset it
  def reshuffle
    @master&.remove_retainer
    @deck.tuck(self)
    initialize(@deck)
  end

  # The class of this retainer card (if face up)
  # or the class of the card it is bluffing as (if bluffing)
  def appears_as
    @bluff.class if !@bluff.nil?
    self.class
  end

  # Checks to make sure the target is an adjacent character
  # If not, raises and exception
  def assert_adjacent!(target)
    raise "#{target} is not adjacent to: #{@master}" unless @master.adjacent_to?(target)
  end

  # Attached this retainer to an in-play character
  # If bluff_as is supplied, play the card face down and bluff as that class
  def play(character, bluff_as=nil)
    @master = character
    master.retainer = self
    @bluff = bluff_as.new if !bluff_as.nil?
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


### Crisis cards
# TODO: Implement
class Crisis < Card

end


### Law cards
# TODO: Implement
class Law < Card

end



######################
### Building Cards ###
######################

#Visit the Apothecary before a Plague Crisis to save family characters in play
class Apothecary < Building
  def initialize
    super
    @cost = 6
    @worker_num = 3
  end
end

#Unlocks Lord Treasurer position when constructed, generates +2 gold when occupied
class Bank < Building
  def initialize
    super
    @cost = 8
    @worker_num = 1
    @office_unlock = :treasurer
  end

  def output
    workers.each do |player|
      bounty = { gold: 2 }
      if !@manager.nil? && player == @manager.player
        bounty.transform_values! { |v| v * 2 }
      end
      player.give bounty
    end
  end
end

#Unlocks Commander position when constructed. Special action: When Commander uses action to vacate a building, they may place workers currently in the Barracks in the new building
class Barracks < Building
  def initialize
    super
    @cost = 6 
    @worker_num = 4
    @office_unlock = :commander
  end
end

#Unlocks High Priest position when constructed. For every 2 workers owned by the same player generate +1 prestige
class Church < Building
  def initialize
    super
    @cost = 6
    @worker_num = 4
    @office_unlock = :priest
  end

  def output
    player_worker_counts = workers.group_by(&:itself).map { |k, v| [k, v.length] }.to_h 
    player_worder_counts.each do |player, count|
      bounty = { prestige: 1 }
      if !@manager.nil? && player == @manager.player
        bounty.transform_values! { |v| v * 2 }
      end
      player.give bounty if count >= 2
    end
  end
end

#Fallow during winter season. Summer Generates +1 food per occupied space and +3 if the same player owns both spaces. During Harvest season generates +2 food per space, and +6 if one player owns both spaces.
class Farm < Building
  def initialize
    super
    @cost = 4
    @worker_num = 2
  end

  def output
    player_worker_counts = workers.group_by(&:itself).map { |k, v| [k, v.length] }.to_h 
    player_worder_counts.each do |player, count|
      bounty = { food: ((count < 2) ? 1 : 3) }
      if !@manager.nil? && player == @manager.player
        bounty.transform_values! { |v| v * 2 }
      end
      player.give bounty
    end
  end
end

#Generates +1 prestige for occupying player
class GuildHall < Building
  def initialize
    super
    @cost = 6
    @worker_num = 1
  end

  def output
    workers.each do |player|
      bounty = { prestige: 1 }
      if !@manager.nil? && player == @manager.player
        bounty.transform_values! { |v| v * 2 }
      end
      player.give bounty
    end
  end
end

#Generates +1 gold for each worker, occupying players may exchange food at a base cost of 1 gold per 2 food, and vice versa. 
#Special - if Lord Treasurer has a representative in the market, generate +1 gold for every transaction made by other players. 
class Market < Building
  def initialize
    super
    @cost = 6
    @worker_num = 3
  end

  def output
    workers.each do |player|
      bounty = { gold: 1 }
      if !@manager.nil? && player == @manager.player
        bounty.transform_values! { |v| v * 2 }
      end
      player.give bounty
    end
  end
end

#Occupying this building at the end of the year will allow the player to regain a previously used Bannermen card. 
class MercenaryCamp < Building
  def initialize
    super
    @cost = 6
    @worker_num = 1
  end
end

#Generates +1 gold per occupied space. If the same player occupies both generate +4 gold and +1 prestige
class Mine < Building
  def initialize
    super
    @cost = 10
    @worker_num = 2
  end

  def output
    player_worker_counts = workers.group_by(&:itself).map { |k, v| [k, v.length] }.to_h 
    player_worder_counts.each do |player, count|
      bounty = { gold: ((count < 2) ? 1 : 4), prestige: ((count < 2) ? 0 : 1) }
      if !@manager.nil? && player == @manager.player
        bounty.transform_values! { |v| v * 2 }
      end
      player.give bounty
    end
  end
end

#Unlocks Spymaster position. 
#Visiting the tavern with a worker or family character allows purchase of retainer for 3 gold.
#Special - Dice game, minimum 2 gold bet, roll a dice, 5 or higher to double the bet. May also challenge other players in tavern. 
class Tavern < Building
  def initialize
    super
    @cost = 4 
    @worker_num = 3
    @office_unlock = :spymaster
  end
end



######################
### Retainer Cards ###
######################

#The Barber keeps your character well manicured in court earning +2 prestige when called on. Beware his treacherous blade. 
class Barber < Retainer
  def perk
    @master.player.give({ prestige: 2 })
  end

  def bluff_fail
    super
    @master.kill
    return_to_deck
  end
end

#The Bard can sing your priases in court earning +2 prestige. He may also insult adjacent characters which lose 2 prestige.
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
    super
    @master.punish
    return_to_deck
  end

end

#The Barrister negates upkeep cost for a character on Campaign or imprisoned. If caught in a lie he will be punished accordingly. 
class Barrister < Retainer
  def bluff_fail
    super
    if @master.imprisoned?
      @master.kill
    elsif @master.campaigning?
      @master.punish
    end
    return_to_deck
  end
end

#The Bodyguard protects a character from direct attack, namely from the Rogue
class BodyGuard < Retainer
end

#The Courtesan may perform a saucy puppet show gaining +1 gold for all adjacent characters. Beware, infidelity will cost you prestige
class Courtesan < Retainer
  def perk
    @master.adjacent.each { |c| c.player.take({ gold: 1 }) }
    @master.player.give({ gold: @master.adjacent.length })
  end

  def bluff_fail
    super
    @master.take({ prestige: 2 })
  end
end

#The Cupbearer may gain +1 food by gathering tablescraps. His purpose is to uncover poison, but beware his spoiled food.
class Cupbearer < Retainer
  def perk
    @master.player.give({ food: 1 })
  end

  def bluff_fail
    super
    @master.take({ food: 5 })
  end
end

# TODO: Implement
#The Eunuch may gain +2 prestige in court.
#Special - reveal any adjacent retainer card in play and resolve the negative effect on that character. 
#Special - Visit the tavern and turn this card in to start a Plot
class Eunuch < Retainer
end

#The Huntmaster gains +3 food for his master on a successful hunt. Beware the hunting accident.
class Huntmaster < Retainer
  def perk
    @master.player.give({ food: 3 })
  end

  def bluff_fail
    super
    @master.kill
    return_to_deck
  end
end

#The Jester may gain +1 gold for entertaining guests.
#Special - Swap the adjacent target retainer with an a new random retainer from the deck
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

#The Monk earns +1 food and +1 prestige for his services in court. Beware of his heresey. 
class Monk < Retainer
  def perk
    @master.player.give({ food: 1, prestige: 1 })
  end

  def bluff_fail
    super
    @master.punish
    return_to_deck
  end
end

#The Physician gains +2 prestige in court for his services. 
#Special - pay 10 gold and target an adjacent family character to poison. Sending them home. 
#Countered by Cupbearer
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
        target.return_to_hand
        return_to_deck
      end
    else
      raise "Player doesn't have enough gold for this action"
    end
  end
end

#The Rogue - Pay 25 gold and target any character in play. 
#Countered by the Bodyguard
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