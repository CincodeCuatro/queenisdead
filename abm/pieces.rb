require_relative 'piece_containers'
require_relative 'utils'


# An item on the board (a building card, a character, a worker, or a retainer card) that has a location and can be moved
class Piece

  # Print smaller info for debug (remove for final project)
  def inspect = "#{self.class.to_s.upcase}-#{self.object_id}"

  attr_reader :location

  def initialize
    @location = nil
  end

  def set_location(location)
    @location = location
  end

  def clear_location
    @location = nil
  end

end

# A Character card
# An instance will be owned by a player
class Character < Piece
  attr_reader :player, :gender, :retainer, :name
  

  # Init
  def initialize(player, gender=nil)
    super()
    @player = player
    @gender = gender || %w(male female).sample
    @name = gen_name(@gender)
    @retainer = Slot.new("Character_#{object_id}_retainer")
    @moveLock = false
    return self
  end

  #handles movement for character around the board
  def move(location, pos=nil, auto_heir_promote=true)
    old_location = @location
    @location&.remove(self) 
    if location.nil?
      set_location(nil)
      lock
      return
    end
    raise "Character cannot move because they are locked" if @moveLock
    b = @player.game.board
    if location.is_a?(Building)
      location.manager.set(self)
      set_location(location)
    else
      case location
        when :crypt; b.crypt.add(self); set_location(b.crypt)
        when :dungeon; b.dungeon.add(self); set_location(b.dungeon)
        when :campaign; b.campaign.add(self); set_location(b.campaign)
        when :court; b.court.set(self, pos); set_location(b.court)
        #when :building; bld = b.buildings.get(pos); bld&.manager.set(self); set_location(bld) 
        when :crown; b.crown.set(self); set_location(b.crown); @player.game.board.new_crown
        when :priest; b.priest.set(self); set_location(b.priest)
        when :commander; b.commander.set(self); set_location(b.commander)  
        when :spymaster; b.spymaster.set(self); set_location(b.spymaster)
        when :treasurer; b.treasurer.set(self); set_location(b.treasurer)
        when :heir; b.heir.set(self); set_location(b.heir)
        else raise "Unknown location: #{location}"
      end
    end
    if auto_heir_promote && old_location == b.crown && !b.heir.empty?
      heir = b.heir.contents
      heir.lockless_move(:crown)
      @player.game.add_to_log("Heir, #{heir.name}, has been crowned")
    end
    lock
  end

  def lockless_move(location, pos=nil)
    lock_status = locked?
    unlock
    move(location, pos)
    lock if lock_status
  end


  def where_am_i?
    return :hand if @location.nil?
    return :building if @location.is_a?(Building)
    b = @player.game.board
    return {
      b.crypt => :crypt,
      b.dungeon => :dungeon,
      b.campaign => :campaign,
      b.court => :court,
      b.crown => :crown,
      b.priest => :priest,
      b.commander => :commander,
      b.spymaster => :spymaster,
      b.treasurer => :treasurer,
      b.heir => :heir
    }[@location]
  end

  def kill(auto_heir_promote=true)
    unlock
    @retainer.contents&.reshuffle
    move(:crypt, nil, auto_heir_promote)
  end

  #Handles punishment for a character based on sentencing severity on the board
  def punish
    case @player.game.board.sentencing
      # TODO: in case of fine sentencing should gold go to the priest?
      when :fine; @player.take({ gold: 10 }); @player.game.board.priest.contents&.player&.give({ gold: 10 })
      when :prison;
        d = @player.game.board.dungeon.contents
        dl = d.length
        d.push(*[nil, nil]) if dl == 0
        d.push(nil) if dl == 1
        lockless_move(:dungeon)
      when :death; kill
    end
  end


  ## Move Lock

  def locked? = @moveLock

  def lock = @moveLock = true

  def unlock = @moveLock = false

end


# A Worker piece, will be owned by a Player
# May be placed on a building card (in play)
class Worker < Piece
  attr_reader :player

  # Init
  def initialize(player)
    super()
    @player = player
  end

  # Places this worker on the specified building
  # If target is nil, returns this worker to the player's hand
  def move(building)
    @location&.workers&.remove(self)
    if building.nil?
      set_location(nil)
    else
      building.workers.add(self)
      set_location(building)
    end
  end

  def where_am_i?
    return :hand if @location.nil?
    @location.name
  end

end


### Parent class for cards
class Card < Piece
end
