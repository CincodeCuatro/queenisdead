
# An item on the board (a building card, a character, a worker, or a retainer card) that has a location and can be moved
class Piece

  attr_reader :location

  def initialize
    @location = nil
  end

end

# A Character card
# An instance will be owned by a player
class Character < Piece
  attr_reader :player, :gender, :retainer

  # Init
  def initialize(player, gender)
    super
    @player = player
    @gender = gender
    @retainer = nil
    return self
  end

  # If target is a Building, Crypt, Campain, Dungeon, or Court: places the card on that location
  # If target is nil, returns this character card to the player's hand
  # Always calls .remove_character(self) on the current @location (if it's not nil)
  # In case the move is to the court, a position argument may be supplied
  def move(target, pos=nil)
    @location&.remove_character(self)
    if target.nil?
      @location = nil
    else
      if ![Building, Crypt, Campaign, Dungeon, Court].map { |p| target.is_a?(p) }.any?
        raise "#{target} is not a place for a character"
      end
      pos ? target.place_character(self, pos) : target.place_character(self)
      @location = target
    end
    return self
  end

  # Place a retainer card on this character card
  def place_retainer(retainer)
    remove_retainer if !@retainer.nil?
    @retainer = retainer
    return self
  end

  # Removes the retainer card on this character card
  def remove_retainer
    @retainer = nil
    return self
  end

  # TODO: Implement
  def kill
    @retainer&.reshuffle
    move(player.game.board.crypt)
    return self
  end
end

# A Worker piece, will be owned by a Player
# May be placed on a building card (in play)
class Worker < Piece
  attr_reader :player

  # Init
  def initialize(player)
    super
    @player = player
  end

  # Places this worker on the specified building
  # If target is nil, returns this worker to the player's hand
  # Always calls .remove_worker(self) on the current @location (if it's not nil)
  def move(building)
    @location&.remove_worker(self)
    if building.nil?
      @location = nil
    else
      raise "#{building} is not a building" if !building.is_a?(Building)
      building.place_worker(self)
      @location = building
    end
    return self
  end
end