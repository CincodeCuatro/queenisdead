require_relative 'piece_containers'
require_relative 'decks'
require_relative 'coffer'


class Board

  # Print smaller info for debug (remove for final project)
  def inspect = "#{self.class.to_s.upcase}-#{self.object_id}"

  attr_reader(*[
    :game,
    :season, :activeCrisis, :pastCrises, :sentencing, :year, :firstCrown, :crownTicker,
    :buildingsDeck, :retainersDeck, :lawsDeck, :crisesDeck,
    :buildings, :court, :campaign, :crypt, :dungeon,
    :crown, :priest, :commander, :spymaster, :treasurer, :heir,
    :currentLaws, :coffer, :buildQueue, :officeActionLocks
  ])

  def initialize(game)
    # Game
    @game = game

    # Trackers
    @season = :summer
    @activeCrisis = nil
    @pastCrises = []
    @sentencing = :fine
    @year = 0
    @crownTicker = 0
    @firstCrown = nil 

    # Decks
    @buildingsDeck = BuildingsDeck.new(self)
    @retainersDeck = RetainersDeck.new(self)
    @crisisDeck = CrisisDeck.new(self)
    # @lawsDeck = LawsDeck.new # TODO: 

    # Spaces
    @buildings = Ring.new(:buildings, 15)
    @court = Ring.new(:court, 13)
    @campaign = Box.new(:campaign, 6, -> _x, _xs { raise "No space left in Campaign" })
    @dungeon = Box.new(:dungeon, 3, -> x, xs { xs.shift&.kill; xs << x })
    @crypt = Bag.new(:crypt)

    # Offices
    @crown = Slot.new(:crown)
    @priest = Slot.new(:priest)
    @commander = Slot.new(:commander)
    @spymaster = Slot.new(:spymaster)
    @treasurer = Slot.new(:treasurer)
    @heir = Slot.new(:heir)

    # Misc
    @currentLaws = []
    @coffer = Coffer.new
    @buildQueue = Box.new(:building_queue, 3, -> c, bq { @buildingsDeck.tuck(bq.shift); bq << c })
    3.times { advance_build_queue! }
    @officeActionLocks = {}
  end

  ### Info Methods & Calculated Properties ###

  # Checks if office has been unlocked and is available for occupation. Most unlock by constructing a specific building
  def office_available?(office)
    case office
    when :crown; true
    when :priest; @buildings.has_a?(Church)
    when :commander; @buildings.has_a?(Barracks)
    when :spymaster; @buildings.has_a?(Tavern)
    when :treasurer; @buildings.has_a?(Bank)
    when :heir; true
    else raise "Unknown office: #{office}"
    end
  end

  # Gets the slot associated with an office from an office name
  def get_office(office)
    case office
    when :crown; return @crown
    when :priest; return @priest
    when :commander; return @commander
    when :spymaster; return @spymaster
    when :treasurer; return @treasurer
    when :heir; return @heir
    else raise "Unknown office: #{office}"
    end
  end

  # Check if we're at the beginning of a year
  def beginning_of_year? = @season == :summer

  # Check if we've reached the end of the year
  def end_of_year? = @season == :winter

  # Build queue on the board draws three cards, adds additional cost to each position, cards at the end is reshuffled into the deck
  def get_build_queue = @buildQueue.contents.zip(1..3).map { |b, i| [b, b.cost + i] }

  # Returns the list of buildings that are actually built
  def constructed_buildings = @buildings.contents.map(&:contents).compact

  # Returns all buildings of the given type that are built
  def get_buildings_of_type(type) = constructed_buildings.filter { |b| b.is_a?(type) }

  # Returns the list of buildings that have no manager
  def managerless_buildings = constructed_buildings.filter { |b| b.manager.empty? }

  # Realm upkeep increases with each building constructed, must be paid in full to avert crisis at the end of a year (3rd season)
  def realm_upkeep
    upkeep_base = { gold: 2, food: 2 }
    upkeep_base.transform_values { |v| v * constructed_buildings.length } 
  end

  # Check if office action has already been used this round
  def office_action_available?(action) = @officeActionLocks[action].nil?


  ### Bookkeeping ###

  # Takes care of various trackers and other minutia between rounds
  def bookkeeping!
    if end_of_year?
      advance_year!
      advance_crisis!
      unlock_buildings!
      collect_upkeep!
    end
    advance_season!
    unlock_office_actions!
    distribute_resources!
    @crownTicker += 1 if @crown.contents
  end

  # Incremement the year counter
  def advance_year! = @year += 1

  # Seasons advance after every player has taken their turn, after three seasons a year has passed. 
  def advance_season!
    seasons = [:summer, :harvest, :winter]
    @season = seasons[(seasons.index(@season) + 1) % seasons.length]    
  end

  # Clear active crisis at end of year
  def advance_crisis!
    if !@activeCrisis.nil?
      @pastCrises << @activeCrisis
      @activeCrisis = nil
    end
  end

  # Move the building queue forward
  def advance_build_queue! = @buildQueue.add(@buildingsDeck.draw)

  # Unlock all buildings (so they can be taken over again in the next year)
  def unlock_buildings! = constructed_buildings.each(&:unlock)

  # Unlock office actions (so they can be used again in the next round)
  def unlock_office_actions! = constructed_buildings.each(&:unlock)

  # Go through each built-building and give players with workers there their payout
  def distribute_resources! = constructed_buildings.map(&:output)

  def collect_upkeep!
    upkeep_amount = realm_upkeep
    per_player_amount = upkeep_amount.transform_values { |v| v / @game.players.length }
    @game.players.each { |player|
      from_player = player.request_upkeep(per_player_amount)
      upkeep_amount.merge! { |_, v1, v2| v1 - v2 }
    }
    activate_crisis if upkeep_amount.values.sum > 0
  end


  ### Board State Helper Methods ###
  
  # Draws crisis card and sets to active
  def activate_crisis
    @activeCrisis = @crisisDeck.draw
    @activeCrisis.activate
  end

  # Priest position may set sentencing as an action. Fine is 10 gold paid to priest, prison sends character to dungeon, and death kills character. Dungeon overflow also results in death
  def set_sentencing(severity)
    raise "Unknown severity: #{severity}" if ![:fine, :prison, :death].include?(severity)
    @sentencing = severity
  end

  # Called when a new player ascends the throne
  def new_crown
    @crownTicker = 0
    @firstCrown = @firstCrown.nil? ? true : false
  end

  # Lock office action so it can't be performed more than once a round
  def lock_office_action(action) = @officeActionLocks[action] = true

end






