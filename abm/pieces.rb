
# An item on the board (a building card, a character, a worker, or a retainer card) that has a location and can be moved
class Piece

  attr_reader :location

  def initialize
    @location = nil
  end

  def set_location(location)
    @location = location
  end

end

# A Character card
# An instance will be owned by a player
class Character < Piece
  attr_reader :player, :gender, :retainer

  # Init
  def initialize(player, gender=nil)
    super
    @player = player
    @gender = gender || [:male, :female].sample
    @retainer = Slot.new("Character_#{object_id}_retainer")
    return self
  end

  #handles movement for character around the board
  def move(location, pos=nil)
    @location&.remove(self)
    b = @player.game.board
    case location
      when :crypt; b.crypt.add(self); set_location(b.crypt)
      when :dungeon; b.dungeon.add(self); set_location(b.dungeon)
      when :campaign; b.campaign.add(self); set_location(b.campaign)
      when :court; b.court.set(self, pos); set_location(b.court)
      when :building; bld = b.buildings.get(pos); bld&.manager.set(self); set_location(bld) 
      when :crown; b.crown.set(self); set_location(b.crown)
      when :priest; b.priest.set(self); set_location(b.priest)
      when :commander; b.commander.set(self); set_location(b.commander)  
      when :spymaster; b.spymaster.set(self); set_location(b.spymaster)
      when :treasurer; b.treasurer.set(self); set_location(b.treasurer)
      when :heir; b.heir.set(self); set_location(b.heir)
      when nil; set_location(nil)
      else raise "Unknown location: #{location}"
    end
  end

  def kill
    @retainer.contents&.reshuffle
    move(:crypt)
  end

  #Handles punishment for a character based on sentencing severity on the board
  def punish
    case @player.game.board.sentencing
      when :fine; @player.take({ gold: 10 }); @player.game.board.priest.contents&.give({ gold: 10 })
      when :prison;
        d = @player.game.board.dungeon.contents
        dl = d.length
        d.push(*[nil, nil]) if dl == 0
        d.push(nil) if dl == 1
        move(:dungeon)
      when :death; kill
    end
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
  def move(building)
    @location&.workers.remove(self)
    if building.nil?
      set_location(nil)
    else
      building.workers.add(self)
      set_location(building.workers)
    end
  end
end