require_relative 'containers'
require_relative 'pieces'
require_relative 'actions'


######################
### Building Cards ###
######################

### Building cards base class
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
    @deck.board.advance_build_queue!
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

  def place_worker_effects(player)
    return Effects.new({prestige: 1}) if player.worked_buildings.any? { |b| b.is_a?(Church) }
    Effects.new({risk: -0.5, prestige: 1})
  end

  def remove_worker_effects(player)
    return Effects.new({prestige: -1}) if player.characters.count { |c| c.location.is_a?(Church) } > 1
    Effects.new({risk: 1, prestige: -1})
  end

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
    return if @deck.board.season == :winter || @deck.board.activeCrisis.is_a?(Blight)
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