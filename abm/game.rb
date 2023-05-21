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
    @players = Array.new(player_num) { |i| Player.new(self, i) }
    @crownTicker = 0
    @crownWinThreshold = 9
    @firstCrown = true
    @log = []
    @players.sample.characters.first.move(:crown)
  end

  def inspect = "GAME"

  def play!
    game_end_reason = nil
    loop do
      game_end_reason = game_end?
      break if game_end_reason
      play_round
    end
    case game_end_reason
    when :fiveYears
      add_to_log("Game ended: 5 years have passed with no clear winner")
    when :crownWin
      winner = @board.crown.contents.player.playerID
      add_to_log("Game ended: Player #{winner} successfully held the throne for #{@firstCrown ? 3 : 2} years")
    when :crisisEnd
      add_to_log("Game ended: realm in crisis")
    when :familyExtinguished
      loser = @players.filter(&:no_usable_characters?).first
      add_to_log("Game ended: Player #{loser}'s dynasty is dead")
    end
  end

  def play_round
    add_to_log("Start of year #{@board.year}") if @board.season == :summer
    @board.constructed_buildings.map(&:output)
    if !@board.crown.empty?
      @board.crown.contents.player.play_turn
      @players.each { |player| player.play_turn if player != @board.crown.contents }
    else
      @players.each { |player| player.play_turn }
    end
    # TODO: collect upkeep if season is winter
    @board.next_season
    @crownTicker += 1 if !@board.crown.empty?
  end

  def game_end?
    return :fiveYears if @board.year >= 5
    return :crownWin if @crownTicker >= @crownWinThreshold
    return :crisisEnd if !@board.activeCrisis.nil? && @board.pastCrises.length >= 2
    return :familyExtinguished if @players.map(&:no_usable_characters?).any?
    return false
  end

  def new_crown
    @crownTicker = 0
    @crownWinThreshold = @firstCrown ? 9 : 6
    @firstCrown = false
  end

  def add_to_log(item)
    @log << item
  end

  def print_log
    @log.each do |item|
      puts(item.is_a?(TurnAction) ? item.desc : item)
    end
  end

  def challenge
    [true, false].sample
  end

end