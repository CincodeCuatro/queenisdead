
# A container for a single game-piece
# (For example: the Spymaster court position)
class Slot
  attr_reader :name, :contents
  
  def initialize(name)
    @name = name
    @contents = nil
  end

  def set(piece)
    raise "Slot #{self} is not empty" if !@contents.nil?
    @contents = piece
    return self
  end

  def remove(piece)
    if @contents == piece
      piece.clear_location
      @contents = nil
    end
  end

  def clear = @contents = nil

  def empty? = @contents.nil?
end

# A container for any number of pieces which are never retrieved
# (Currently only used for the Crypt)
class Bag
  attr_reader :name, :contents

  def initialize(name)
    @name = name
    @contents = []
  end

  def add(piece) = @contents << piece
end

# A container for a limited number of game pieces
# Runs a specified callback in case the limit is reached
# (Used for the Dungeon & Campaign)
class Box
  attr_reader :name, :contents

  def initialize(name, capacity, on_overflow)
    @name = name
    @capacity = capacity
    @on_overflow = on_overflow
    @contents = []
  end

  def full? = @contents.length >= @capacity

  def add(piece) = full? ? @on_overflow.call(piece, @contents) : @contents << piece

  def get(n) = @contents[n % @capacity]

  def remove(piece)
    piece.clear_location
    @contents.delete(piece)
  end

end

# A container which contains a fixed number of slots
# Rings loop around, so that the last and first slots are adjacent
# (Used for the Court & Building Plots)
class Ring
  attr_reader :name, :contents

  def initialize(name, capacity)
    @name = name
    @capacity = capacity
    @contents = Array.new(capacity) { |i| Slot.new([name, i]) }
  end

  def set(piece, n) = @contents[n % @capacity].set(piece)

  def remove(x)
    if x.is_a?(Numeric)
      @contents.get(x)&.clear_location
      @contents[x % @capacity].clear
    else
      @contents.map { |slot| slot.remove(x) }
    end
  end

  #gets contents of a slot at position n
  def get(n) = @contents[n % @capacity].contents

  def get_all = @contents.map(&:contents).compact

  def index(piece)
    @contents.each_with_index { |i, x| return i if x.contents == piece }
    return nil
  end

  def has_a?(type) = @contents.map { |slot| slot.contents&.is_a?(type) }.any?

  def full? = @contents.map { |s| !s.empty? }.all?

  #Checks adjacency between two positions, mainly used by characters to use abilities of their Retainers
  def adjacent?(a, b)
    ai, bi = index(a), index(b)
    return !ai.nil? && !bi.nil? && (ai - bi).abs == 1
  end

  def first_free_pos
    @contents.each_with_index { |s, i| return i if s.empty? }
    return nil
  end
end