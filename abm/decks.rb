
###########################
### Abstract Deck Class ###
###########################

class Deck
    attr_reader :board

    def initialize(board)
      @board = board
      @cards = []
    end

    # Add N new instances of the provided card-class to this deck
    def add_cards(card, n) = @cards.concat(Array.new(n) { card.new(self) })

    # Take N cards off the top of the deck
    def draw(n=1) = @cards.pop(n)
    
    # Look at the top N cards
    def peek(n=1) = @cards.last(n)

    # Return the provided card(s) at the back of the deck
    def tuck(c) = @cards.unshift(*c)
end


######################
### Buildings Deck ###
######################

class BuildingsDeck < Deck
  def initialize(board)
    super(board)
    add_cards(Apothecary, 2)
    add_cards(Bank, 1)
    add_cards(Barracks, 1)
    add_cards(Church, 2)
    add_cards(Crypt, 1)
    add_cards(Dungeon, 1)
    add_cards(Farm, 5)
    add_cards(GuildHall, 2)
    add_cards(Market, 1)
    add_cards(MercenaryCamp, 1)
    add_cards(Mine, 1)
    add_cards(Tavern, 1)
    @cards.shuffle!
  end
end



######################
### Retainers Deck ###
######################

class RetainersDeck < Deck
  def initialize(board)
    super(board)
    add_cards(Barber, 2)
    add_cards(Bard, 2)
    add_cards(Barrister, 2)
    add_cards(Bodyguard, 2)
    add_cards(Courtesan, 1)
    add_cards(Cupbearer, 2)
    add_cards(Eunuch, 1)
    add_cards(Huntmaster, 1)
    add_cards(Jester, 1)
    add_cards(Monk, 2)
    add_cards(Physician, 1)
    add_cards(Rogue, 1)
    @cards.shuffle!
  end
end