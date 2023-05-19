
class Board

  attr_reader
    :season, :activeCrisis, :pastCrises, :sentencing, :year,
    :buildingsDeck, :retainersDeck, :lawsDeck, :crisesDeck,
    :buildings, :court, :campaign, :crypt, :dungeon,
    :crown, :priest, :commander, :spymaster, :treasurer, :heir,
    :currentLaws, :treasury, :buildingQueue

  def initialize
    #Trackers
    @season = :summer
    @activeCrisis = nil
    @pastCrises = []
    @sentencing = :fine
    @year = 0

    # Decks
    @buildingsDeck = BuildingsDeck.new(self)
    @retainersDeck = RetainersDeck.new(self)
    # @lawsDeck = LawsDeck.new # TODO: 
    # @crisesDeck = CrisesDeck # TODO: 

    # Spaces
    @buildings = Ring.new(:buildings, 15)
    @court = Ring.new(:court, 15)
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
    @treasury = Coffer.new
    @buildingQueue = Box.new(:building_queue, 3, -> c, bq { @buildingsDeck.tuck(bq.shift); bq << c })
  end

  #Seasons advance after every player has taken their turn, after three seasons a year has passed. 
  def next_season
    @dungeon.contents.shift&.move(nil)
    if @season == :winter
      @year += 1
      if !@activeCrisis.nil?
        @pastCrises << @activeCrisis
        @activeCrisis = nil
      end
    end
    seasons = [:summer, :harvest, :winter]
    seasons[(seasons.index(@season) + 1) % seasons.length]    
  end

  #draws crisis card and sets to active
  def activate_crisis
    @activeCrisis = @crisesDeck.draw
  end
  
  #realm upkeep increases with each building constructed, must be paid in full to avert crisis at the end of a year (3rd season)
  def realm_upkeep
    UPKEEP_MULTIPLIER = { gold: 2, food: 2 }
    UPKEEP_MULTIPLIER.transform_values { |v| v * @buildings.length } 
  end

  #Priest position may set sentencing as an action. Fine is 10 gold paid to priest, prison sends character to dungeon, and death kills character. Dungeon overflow also results in death
  def set_sentencing(severity)
    raise "Unknown severity: #{severity}" if ![:fine, :prison, :death].include?(severity)
    @sentencing = severity
  end

  #Checks if office has been unlocked and is available for occupation. Most unlock by constructing a specific building
  def office_available?(office_name)
    case office_name
    when :crown; true
    when :priest; @buildings.has_a?(Church)
    when :commander; @buildings.has_a?(Barracks)
    when :spymaster; @buildings.has_a?(Tavern)
    when :treasurer; @buildings.has_a?(Bank)
    when :heir; true
    else raise "Unknown office: #{office_name}"
    end
  end

  #Build queue on the board draws three cards, adds additional cost to each position, cards at the end is reshuffled into the deck
  def get_build_queue
    @buildQueue.contents.zip(1..3)..map { |b, i| [b, b.cost + i] }
  end

  def advance_build_queue
    @buildingQueue.add(@buildingsDeck.draw)
  end

end






