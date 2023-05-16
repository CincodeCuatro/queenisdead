#######################
### Season Tracker  ###
#######################

#######################
### UpKeep Tracking ###
#######################

######################
### Crisis Tracker ###
######################

############
### Laws ###
############

###########################
### Sentencing Severity ###
###########################




class Board

  attr_reader
    :season, :crisisTracker, :sentencing, :year,
    :buildingsDeck, :retainersDeck, :lawsDeck, :crisesDeck,
    :buildings, :court, :campaign, :crypt, :dungeon,
    :crown, :priest, :commander, :spymaster, :treasurer, :heir,
    :currentLaws, :treasury

  def initialize
    #Trackers
    @season = :summer
    @crisisTracker = []
    @sentencing = :fine
    @year = 0

    # Decks
    @buildingsDeck = BuildingsDeck.new
    @retainersDeck = RetainersDeck.new
    # @lawsDeck = LawsDeck.new # TODO: 
    # @crisesDeck = CrisesDeck # TODO: 

    # Spaces
    @buildings = Spaces.new(15)
    @court = Spaces.new(13)
    @campaign = []
    @dungeon = []
    @crypt = []

    # Offices
    @crown = nil
    @priest = nil
    @commander = nil
    @spymaster = nil
    @treasurer = nil
    @heir = nil

    # Misc
    @currentLaws = []
    @treasury = Coffer.new
  end

  def next_season
    @year += 1 if @season == :winter 
    seasons = [:summer, :harvest, :winter]
    seasons[(seasons.index(@season)+1) % seasons.length]    
  end

  def add_crisis(crisis)
    @crisisTracker << crisis
  end

  def realm_upkeep
    UPKEEP_MULTIPLIER = { gold: 2, food: 2 }
    UPKEEP_MULTIPLIER.transform_values { |v| v * @buildings.length } 
  end

  def set_sentencing(severity)
    raise "Unknown severity: #{severity}" if ![:fine, :prison, :death].include?(severity)
    @sentencing = severity
  end

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

  def set_office(office_name, player)
    raise "Office: #{office_name} not available!" if not office_available(office_name)
    case office_name
    when :crown; @crown = player
    when :priest; @priest = player
    when :commander; @commander = player
    when :spymaster; @spymaster = player
    when :treasurer; @treasurer = player
    when :heir; @heir = player
    else raise "Unknown office: #{office_name}"
    end
  end

end





# Interface for objects which can have things placed on them
module BoardLocation
  # Place item on this board location (with optional position)
  def place(item, pos=nil) = raise "Not implemented"

  # Remove item from this board position
  def unplace()

end



# Container for board-items with not adjacency or capacity
class Crypt

  attr_reader :name

  def initialize(name)
    @name = name
    @contents = []
  end

  def can_move_to?
    true
  end

  def add(a)
    raise "Wrong board item type" if !a.is_a?(Character)
    @contents << a
  end

  def remove(a)
    @contents.delete(a)
  end

  def has?(a)
    @contents.include?(a)
  end

end


class Campaign < Crypt

  def initialize(name, capacity)
    super(name)
    @capacity = capacity
  end

  def can_move_to?
    @contents.length < @capacity
  end

end


class Dungeon < Crypt

  def initialize(name, capacity)
    super(name)
    @capacity = capacity
  end

  def add(a)
    @contents.shift.kill if @contents.length >= @capacity
    super(a)
  end

end


# Container for characters, with sub areas
class Court

  def initialize(name, @capacity)
    super(name)
    @capacity = capacity
    @spaces = Array.new(@capacity, nil)
  end

  def at(pos)
    @spaces[pos % @spaces.length]
  end

  def can_move_to?(pos)
    at(pos).nil?
  end

  def pos_of(a)
    @spaces.index(a)
  end

  def adjacent?(a, b)
    positions = [pos_of(a), pos_of(b)].sort
    return nil if positions.include?(nil)
    return true if positions == [0, @size-1]
    return (positions[1] - positions[0]) == 1
  end

  def has_a?(type)
    @spaces.map { |space| space.is_a?(type) }.any?
  end

  def add(a, pos)
    raise "Wrong board item type" if !a.is_a?(Character)
    @spaces[pos] = a
  end

  def remove(a)
    pos = pos_of(a)
    raise "No item #{a} in Court" if pos.nil?
    @spaces[pos] = nil
  end

end








class Coffer
  def initialize(amounts={})
    @gold = amounts[:gold] || 0
    @food = amounts[:food] || 0
    @prestige = amounts[:prestige] || 0
  end

  def give(amounts)
    @gold += amounts[:gold] || 0
    @food += amounts[:food] || 0
    @prestige += amounts[:prestige] || 0
  end

  def take(amounts)
    give(amounts.transform_values { |x| -1 * x })
  end
end