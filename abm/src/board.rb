require_relative 'containers'
require_relative 'decks'
require_relative 'coffer'

#############
### Board ###
#############

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
    upkeep_base = { gold: 1, food: 1 }
    upkeep_base.transform_values { |v| v * constructed_buildings.length } 
  end

  # Check if office action has already been used this round
  def office_action_available?(action) = @officeActionLocks[action].nil?


  ### Bookkeeping ###

  # Takes care of various trackers and other minutia between rounds
  def bookkeeping!
    campaign_challenges!
    distribute_resources!
    if end_of_year?
      advance_year!
      advance_crisis!
      unlock_buildings!
      collect_upkeep!
    end
    unlock_characters!
    advance_season!
    unlock_office_actions!
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

  # Unlock all buildings (so they can be taken over again in the next year)
  def unlock_buildings! = constructed_buildings.each(&:unlock)

  # Unlock all characters (so they can be moved again in the next turn)
  def unlock_characters! = @game.players.each { |player| player.characters.each(&:unlock) }

  # Unlock office actions (so they can be used again in the next round)
  def unlock_office_actions! = @officeActionLocks = {}

  def campaign_challenges!
    @campaign.contents.each do |c|
      if c.player.coffer.food >= 1
        c.player.take({food: 1})
        roll = (1..6).to_a.sample
        case roll
        when 1
          c.kill
          @game.log("#{c.name} (Player #{c.player.id}) has died on campaign")
        when (2..5)
          c.player.give({ gold: (roll + 1) })
        when 6
          c.player.give({ gold: 10, prestige: 2 })
        end
      else
        c.kill
        @game.log("#{c.name} (Player #{c.player.id}) has died on starved to death on campaign")
      end
    end
  end

  # Go through each built-building and give players with workers there their payout
  def distribute_resources! = constructed_buildings.map(&:output)

  def collect_upkeep!
    upkeep_amount = realm_upkeep
    @game.log("Time to collect the realm's upkeep! #{upkeep_amount[:gold]} gold & #{upkeep_amount[:food]} food needed...")
    
    treasury_gold_contribution = [@coffer.gold, upkeep_amount[:gold]].min
    @coffer.take({gold: treasury_gold_contribution})
    upkeep_amount[:gold] -= treasury_gold_contribution
    treasury_food_contribution = [@coffer.food, upkeep_amount[:food]].min
    @coffer.take({food: treasury_food_contribution})
    upkeep_amount[:food] -= treasury_food_contribution
    @game.log("#{treasury_gold_contribution} gold & #{treasury_food_contribution} food has been paid out of the royal treasury. #{upkeep_amount[:gold]} gold & #{upkeep_amount[:food]} food still needed...")

    per_player_amount = upkeep_amount.transform_values { |v| v / @game.players.length }
    @game.players.each { |player|
      from_player = player.request_upkeep(per_player_amount)
      from_player.each {|k, v| upkeep_amount[k] -= v }
    }
    @game.log("Upkeep balance: ", upkeep_amount)
    if upkeep_amount.values.sum > 0
      @game.log("Players didn't contribute enough upkeep")
      activate_crisis
    else
      @game.log("Players have contributed enough upkeep. The realm is safe (for now...)")
    end
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

  # Move the building queue forward
  def advance_build_queue! = @buildQueue.add(@buildingsDeck.draw)

end






