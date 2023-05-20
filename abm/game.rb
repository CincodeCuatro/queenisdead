require_relative 'board'
require_relative 'player'


#####################
### Win Coditions ###
#####################

=begin

If the first monarch is able to hold the throne within their dynasty for 3 consecutive years, they win.

If the crown is held by the same Dynasty for 6 consecutive seasons they win.

If Crisis falls upon the realm 3 times everyone loses and the game is over.

If every member of a single family Dynasty is imprisoned or killed, the current monarch has won.

Else, the one who holds the throne at the end of the 5th year wins.

=end


=begin MOCKUP GAME INTERFACE

GAME:
    
    
CHARACTER:
    move(location, pos=nil)
    place_retainer(retainer)
    remove_retainer
    kill

WORKER:
    move(location)

RETAINER:
    reshuffle
    move(location)

BUILDING:
    reshuffle
    build(pos)
    destroy
    place_character(character)
    place_worker(worker)
    remove_character(character)
    remove_worker(worker)

CRYPT:
    place_character(character)
    remove_character(character)

CAMPAIGN:
    place_character(character)
    remove_character(character)

COURT:
    place_character(character, pos)
    remove_character(character)

DUNGEON:
    place_character(character)
    remove_character(character)

BUILDING_PLOTS:
    place_building(building)
    remove_building(building)



=end

class Game

  attr_reader :board, :players

  def initialize(player_num=4)
    @board = Board.new
    @players = Array.new(player_num) { Player.new(self) }
    @crownTicker = 0
    @crownWinThreshold = 9
    @firstCrown = true
    @moveLog = []
    @players.sample.characters.first.move(:crown)
  end

  def play_round
    @board.buildings.map { |slot| slot.contents&.output }
    @board.crown.contents.play_turn
    @players.each { |player| player.play_turn if player != @board.crown.contents }
    # TODO: collect upkeep if season is winter
    @board.next_season
    @crownTicker += 1
  end

  def game_end?
    return :fiveYears if @board.year >= 5
    return :crownWin if @crownTicker >= @crownWinThreshold
    return :crisisEnd if !@board.activeCrisis.nil? && @board.pastCrises.length >= 2
    return :familyExtinguished if !@players.map(&:has_free_character?).all?
    return false
  end

  def new_crown
    @crownTicker = 0
    @crownWinThreshold = @firstCrown ? 9 : 6
    @firstCrown = false
  end

  def add_to_log(move_desc)
    @moveLog << move_desc
  end

  def challenge
    [true, false].sample
  end

end