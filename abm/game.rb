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
    @log = []
    @players.sample.characters.first.move(:crown)
    add_to_log("Player #{@board.crown.contents.player.id} is king")
  end


  ### Info Methods & Calculated Properties ###

  # Checks if the game is over, if so returns the reason
  def game_end?
    return :fiveYears if @board.year >= 5
    return :crownWin if (@board.firstCrown && @board.crownTicker >= 9) || @board.crownTicker >= 6
    return :crisisEnd if !@board.activeCrisis.nil? && @board.pastCrises.length >= 2
    return :familyExtinguished if @players.map(&:no_usable_characters?).any?
    return false
  end


  ### Game Helper Methods ###

  # Add a game event to the log
  def add_to_log(item) = @log << item

  # Print out the log of all the events that happened this game
  def print_log = @log.each { |e| puts(e.is_a?(Action) ? e.desc : e) }

  # Add some info to the log at the start of every year
  def log_new_year
    add_to_log("Start of year #{@board.year}")
    add_to_log(@players.map(&:show).join("\t"))
  end

  # Used as coin flip for failable actions
  # TODO: Implement actual challenges with banner-men
  def challenge = [true, false].sample



  ### Game Logic ###

  # Simulate a full game
  def play!
    game_end_reason = nil
    loop do
      game_end_reason = game_end?
      break if game_end_reason
      play_round!
    end

    case game_end_reason
    when :fiveYears
      add_to_log("Game ended: 5 years have passed") # TODO: Last crown should win
    when :crownWin
      winner = @board.crown.contents.player.id
      add_to_log("Game ended: Player #{winner} successfully held the throne for #{@board.firstCrown ? 3 : 2} years")
    when :crisisEnd
      add_to_log("Game ended: realm in crisis")
    when :familyExtinguished
      loser = @players.filter(&:no_usable_characters?).first
      add_to_log("Game ended: Player #{loser}'s dynasty is dead")
    end
  end

  # Play a single round
  def play_round!
    log_new_year if @board.beginning_of_year?

    if !@board.crown.empty?
      @board.crown.contents.player.take_turn!
      @players.each { |player| player.take_turn! if player != @board.crown.contents }
    else
      @players.each { |player| player.take_turn! }
    end

    @board.bookkeeping!
  end

end