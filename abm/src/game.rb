require_relative 'board'
require_relative 'player'
require_relative 'log'
require_relative 'utils'

#######################
### Main Game Logic ###
#######################

class Game

  # Print smaller info for debug (remove for final project)
  def inspect = "#{self.class.to_s.upcase}-#{self.object_id}"

  attr_reader :board, :players

  def initialize(player_num=4, priorities=[])
    @board = Board.new(self)
    @players = Array.new(player_num) { |i| Player.new(self, i, priorities[i]) }
    @log = EventLog.new
    @players.sample.characters.first.move(:crown)
    log("Player #{@board.crown.contents.player.id} (#{@board.crown.contents.name}) is crowned")
  end


  ### Info Methods & Calculated Properties ###

  # Checks if the game is over, if so returns the reason
  def game_end?
    return :fiveYears if @board.year >= 5 
    return :crownWin if (@board.firstCrown && (@board.crownTicker >= 9)) || (@board.firstCrown == false && @board.crownTicker >= 6)
    return :crisisEnd if !@board.activeCrisis.nil? && @board.pastCrises.length >= 2
    return :familyExtinguished if @players.map(&:no_usable_characters?).any?
    return false
  end


  ### Game Helper Methods ###

  # Logging helper
  def log(val, state=nil)
    if val.is_a?(String)
      state ? @log.d(val, state) : @log.g(val)
    elsif val.is_a?(Action)
      @log.p(val.desc, val.player.id)
    end
  end

  # Print out the log of all the events that happened this game
  def print_log(debug=false) = @log.pp(debug)

  # Add some info to the log at the start of every year
  def log_new_year
    log("Start of year #{@board.year}")
  end

   # Add some info to the log at the start of every season
   def log_new_season
    log("Start of #{@board.season.upcase}")
    log("Player Resources: ", @players.map(&:show).join(' '))
  end

  # Used as coin flip for failable actions
  # TODO: Implement actual challenges with banner-men
  def challenge = [true, false].sample


  ### Game Logic ###

  # Simulate a full game
  def play!
    rounds = 0
    game_end_reason = nil
    loop do
      raise "Reached max rounds limit" if rounds > 100
      game_end_reason = game_end?
      break if game_end_reason
      play_round!
      rounds += 1
    end

    case game_end_reason
    when :fiveYears
      winner = @board.crown.contents&.player&.id
      log("Game ended: 5 years have passed #{winner ? "(Player #{winner} won)" : '' }")
      return [game_end_reason, winner]
    when :crownWin
      winner = @board.crown.contents.player.id
      crown = @board.crown.contents.name
      log("Game ended: Player #{winner} (#{crown}) successfully held the throne for #{@board.firstCrown ? 3 : 2} years")
      return [game_end_reason, winner]
    when :crisisEnd
      log("Game ended: realm in crisis")
      return [game_end_reason, nil]
    when :familyExtinguished
      crown = @board.crown.contents
      loser = @players.filter(&:no_usable_characters?).first.id
      log("Game ended: Player #{loser}'s dynasty is dead #{crown ? "(Player #{crown.player.id} won with (#{crown.name}) on the throne)" : '' }")
      return [game_end_reason, crown ? crown.player.id : nil]
    end
  end

  # Play a single round
  def play_round!
    log_new_year if @board.beginning_of_year?
    log_new_season
    if !@board.crown.empty?
      crown_player = @board.crown.contents.player
      crown_player.take_turn!
      (@players - [crown_player]).each(&:take_turn!)
    else
      @players.each { |player| player.take_turn! }
    end
    @board.bookkeeping!
  end

end