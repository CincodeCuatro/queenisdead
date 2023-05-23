require_relative 'piece_containers'
require_relative 'pieces'
require_relative 'actions'


#############################
### Abstract Card Classes ###
#############################

### Parent class for cards
class Card < Piece
end

### Building cards
class Building < Card
  attr_reader :cost, :workers, :worker_capacity, :office_unlock, :manager
  
  # Init
  def initialize(deck)
    super()
    @deck = deck # The building-deck this card belongs to
    @workers = Box.new("#{self.class}_#{self.object_id}_workers", @worker_capacity, -> _x, _xs { raise "Cannot add any more workers here #{self}" }) # List of players that have workers on this building (players can appear multiple times)
    @manager = Slot.new("#{self.class}_#{self.object_id}_manager")
    @lock = false
  end

  def name
    self.class.to_s.downcase
  end

  # Apply building effects to relevant players
  def output
  end

  def build(pos)
    bs = @deck.board.buildings
    raise "Already a building in position #{pos}" if !bs.get(pos).nil?
    @deck.board.buildQueue.remove(self)
    bs.set(self, pos)
    set_location(bs)
  end

  # Called when this building is destroyed and put back into the deck
  # If the building has a manager, they get killed
  # Move all workers back to their player's hand
  # The exception is if office_unlock is not nil, in this case the building is permanent
  def destroy
    if @office_unlock.nil?
      @manager.contents&.kill
      @workers.contents.map { |w| w.move(nil) }
      @deck.tuck(self)
      initialize(@deck)
    end
  end

  # Returns list of players with pieces/characters in a building
  def involved_players
    ip = @workers.contents.map(&:player)
    ip << @manager.contents.player if !@manager.empty?
    ip.uniq
  end

  # Returns the number of workers the given player has working in this buildings
  def player_worker_num(player)
    @workers.contents.filter { |x| x.player == player }.length
  end

  # Forces manager and workers off this building (and back to their owner's hand)
  def vacate
    @manager.contents&.move(nil)
    @workers.contents.map { |w| w.move(nil) }
  end

  # Remove attached character or worker
  def remove(x)
    @manager.remove(x)
    @workers.remove(x)
  end

  ## Take-Over Lock

  def locked? = @lock

  def lock = @lock = true

  def unlock = @lock = false


  ## Effects

  def build_effects = Effects.new({})

  def place_worker_effects(player) = Effects.new({})

  def remove_worker_effects(player) = Effects.new({})

  def place_manager_effects(player) = Effects.new({})

  def remove_manager_effects(player) = Effects.new({})

end


### Retainer cards
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


### Crisis cards
# TODO: Implement
class Crisis < Card

end


### Law cards
# TODO: Implement
class Law < Card
=begin
name: "Triple Taxation"
description: "Lord Treasurer now collects +6 on inspections and +4 gold and +6 food from each player"
effect: "Lord Treasurer collects +6 on inspection, and +4 gold and +6 food from each player as Tax"  
=end
end



######################
### Building Cards ###
######################

# Visit the Apothecary before a Plague Crisis to save family characters in play
class Apothecary < Building
  def initialize(deck)
    @cost = 6
    @worker_capacity = 3
    super(deck)
  end

  def build_effects = Effects.new({})

  def place_worker_effects(player)
    return Effects.new({}) if player_worker_num(player) >= 1
    Effects.new({ risk: -2 })
  end

  def remove_worker_effects(player)
    return Effects.new({risk: -2}) if player_worker_num(player) == 1
    Effects.new({})
  end

  def place_manager_effects(player) = Effects.new({ general: -8 })

  def remove_manager_effects(player) = Effects.new({})
end

# Unlocks Lord Treasurer position when constructed, generates +2 gold when occupied
class Bank < Building
  def initialize(deck)
    @cost = 8
    @worker_capacity = 1
    @office_unlock = :treasurer
    super(deck)
  end

  def output
    @workers.contents.each do |w|
      bounty = { gold: 2 }
      if w.player == @manager.contents&.player
        bounty.transform_values! { |v| v * 2 }
      end
      w.player.give(bounty)
    end
  end

  def build_effects = Effects.new({gold: 5, power: 2})

  def place_worker_effects(player)
    (@manager.contents&.player == player) ? Effects.new({gold: 4}) : Effects.new({gold: 2})
  end

  def remove_worker_effects(player)
    (@manager.contents&.player == player) ? Effects.new({gold: -4}) : Effects.new({gold: -2})
  end

  def place_manager_effects(player)
    player_worker_num(player) == 1 ? Effects.new({gold: 4}) : Effects.new({gold: 2})
  end

  def remove_manager_effects(player)
    player_worker_num(player) == 1 ? Effects.new({gold: -4}) : Effects.new({gold: -2})
  end

end

# Unlocks Commander position when constructed. Special action: When Commander uses action to vacate a building, they may place workers currently in the Barracks in the new building
class Barracks < Building
  def initialize(deck)
    @cost = 6 
    @worker_capacity = 4
    @office_unlock = :commander
    super(deck)
  end

  def build_effects = Effects.new({power: 3})

  def place_worker_effects(player)
    player.has_office?(:commander) ? Effects.new({power: 1}) : Effects.new({general: -2})
  end

  def remove_worker_effects(player)
    player.has_office?(:commander) ? Effects.new({power: -1}) : Effects.new({})
  end

  def place_manager_effects(player) =  Effects.new({general: -8})

  def remove_manager_effects(player) = Effects.new({})

end

# Unlocks High Priest position when constructed. For every 2 workers owned by the same player generate +1 prestige
class Church < Building
  def initialize(deck)
    @cost = 6
    @worker_capacity = 4
    @office_unlock = :priest
    super(deck)
  end

  def output
    player_worker_counts = @workers.contents.map(&:player).group_by(&:itself).map { |k, v| [k, v.length] }.to_h 
    player_worker_counts.each do |player, count|
      bounty = { prestige: 1 }
      if player == @manager.contents&.player
        bounty.transform_values! { |v| v * 2 }
      end
      player.give(bounty) if count >= 2
    end
  end

  def build_effects = Effects.new({power: 2, prestige: 1})

  def place_worker_effects(player) = Effects.new({risk: -1, prestige: 1})

  def remove_worker_effects(player) = Effects.new({risk: 1, prestige: -1})

  def place_manager_effects(player)
    player_worker_num(player) >= 1 ? Effects.new({prestige: 3}) : Effects.new({prestige: 0.5})
  end

  def remove_manager_effects(player)
    player_worker_num(player) >= 1 ? Effects.new({prestige: -3}) : Effects.new({})
  end

end

# Fallow during winter season. Summer Generates +1 food per occupied space and +3 if the same player owns both spaces. During Harvest season generates +2 food per space, and +6 if one player owns both spaces.
class Farm < Building
  def initialize(deck)
    @cost = 4
    @worker_capacity = 2
    super(deck)
  end

  def output
    return if @deck.board.season == :winter
    player_worker_counts = @workers.contents.map(&:player).group_by(&:itself).map { |k, v| [k, v.length] }.to_h 
    player_worker_counts.each do |player, count|
      bounty = { food: ((count < 2) ? 1 : 3) }
      if player == @manager.contents&.player
        bounty.transform_values! { |v| v * 2 }
      end
      player.give(bounty)
    end
  end

  def build_effects = Effects.new({food: 4})

  def place_worker_effects(player)
    player_worker_num(player) == 1 ? Effects.new({food: 3}) : Effects.new({food: 1}) 
  end

  def remove_worker_effects(player)
    player_worker_num(player) == 2 ? Effects.new({food: -3}) : Effects.new({food: -1})
  end

  def place_manager_effects(player)
    return Effects.new({food: 6}) if player_worker_num(player) == 2
    return Effects.new({food: 2}) if player_worker_num(player) == 1
    Effects.new({food: 0.5})
  end

  def remove_manager_effects(player)
    return Effects.new({food: -6}) if player_worker_num(player) == 2
    return Effects.new({food: -2}) if player_worker_num(player) == 1
    Effects.new({})
  end

end

# Generates +1 prestige for occupying player
class GuildHall < Building
  def initialize(deck)
    @cost = 6
    @worker_capacity = 1
    super(deck)
  end

  def output
    @workers.contents.each do |w|
      bounty = { prestige: 1 }
      if w.player == @manager.contents&.player
        bounty.transform_values! { |v| v * 2 }
      end
      w.player.give(bounty)
    end
  end

  def build_effects = Effects.new({prestige: 1})

  def place_worker_effects(player) = Effects.new({prestige: 1})

  def remove_worker_effects(player) = Effects.new({prestige: -1})

  def place_manager_effects(player) = player_worker_num(player) == 1 ? Effects.new({prestige: 2}) : Effects.new({prestige: 0.5}) 

  def remove_manager_effects(player) = player_worker_num(player) == 1 ? Effects.new({prestige: -2}) : Effects.new({})

end

# Generates +1 gold for each worker, occupying players may exchange food at a base cost of 1 gold per 2 food, and vice versa. 
# Special - if Lord Treasurer has a representative in the market, generate +1 gold for every transaction made by other players. 
class Market < Building
  def initialize(deck)
    @cost = 6
    @worker_capacity = 3
    super(deck)
  end

  def output
    @workers.contents.each do |w|
      bounty = { gold: 1 }
      if w.player == @manager.contents&.player
        bounty.transform_values! { |v| v * 2 }
      end
      w.player.give(bounty)
    end
  end

  def build_effects = Effects.new({gold: 4})

  def place_worker_effects(player) = Effects.new({gold: 1})

  def remove_worker_effects(player) = Effects.new({gold: -1})

  def place_manager_effects(player) = player_worker_num(player) >= 1 ? Effects.new({gold: 2}) : Effects.new({gold: 0.5}) 

  def remove_manager_effects(player) = player_worker_num(player) >= 1 ? Effects.new({gold: -2}) : Effects.new({})

end

# Occupying this building at the end of the year will allow the player to regain a previously used Bannermen card. 
class MercenaryCamp < Building
  def initialize(deck)
    @cost = 6
    @worker_capacity = 1
    super(deck)
  end

  def build_effects = Effects.new({general: -8})

  def place_worker_effects(player) = Effects.new({general: -8})

  def remove_worker_effects(player) = Effects.new({})

  def place_manager_effects(player) = Effects.new({general: -8})

  def remove_manager_effects(player) = Effects.new({})

end

# Generates +1 gold per occupied space. If the same player occupies both generate +4 gold and +1 prestige
class Mine < Building
  def initialize(deck)
    @cost = 10
    @worker_capacity = 2
    super(deck)
  end

  def output
    player_worker_counts = @workers.contents.map(&:player).group_by(&:itself).map { |k, v| [k, v.length] }.to_h 
    player_worker_counts.each do |player, count|
      bounty = { gold: ((count < 2) ? 1 : 4), prestige: ((count < 2) ? 0 : 1) }
      if player == @manager.contents&.player
        bounty.transform_values! { |v| v * 2 }
      end
      player.give(bounty)
    end
  end

  def build_effects = Effects.new({gold: 6})

  def place_worker_effects(player)
    player_worker_num(player) == 1 ? Effects.new({gold: 4}) : Effects.new({gold: 1}) 
  end

  def remove_worker_effects(player)
    player_worker_num(player) == 2 ? Effects.new({gold: -4}) : Effects.new({gold: -1})
  end

  def place_manager_effects(player)
    return Effects.new({gold: 8, prestige: 4}) if player_worker_num(player) == 2
    return Effects.new({gold: 2}) if player_worker_num(player) == 1
    Effects.new({gold: 0.5})
  end

  def remove_manager_effects(player)
    return Effects.new({gold: -8, prestige: -4}) if player_worker_num(player) == 2
    return Effects.new({gold: -2}) if player_worker_num(player) == 1
    Effects.new({})
  end

end

# Unlocks Spymaster position. 
# Visiting the tavern with a worker or family character allows purchase of retainer for 3 gold.
# Special - Dice game, minimum 2 gold bet, roll a dice, 5 or higher to double the bet. May also challenge other players in tavern. 
class Tavern < Building
  def initialize(deck)
    @cost = 4 
    @worker_capacity = 3
    @office_unlock = :spymaster
    super(deck)
  end

  def build_effects = Effects.new({power: 3})

  def place_worker_effects(player) = Effects.new({power: 1, risk: 1})

  def remove_worker_effects(player) = Effects.new({power: -1, risk: -1})

  def place_manager_effects(player) = Effects.new({power: 1, risk: 1, general: -1})

  def remove_manager_effects(player) = Effects.new({power: -1, risk: -1, general: 1})

end



######################
### Retainer Cards ###
######################

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