require_relative 'pieces'
require_relative 'coffer'


class Player
    
  def initialize(game)
    @game = game
    @workers = Array.new(4) { Worker.new(self) }
    @characters = Array.new(6) { Character.new(self) }
    @retainers = []
    @coffer = Coffer.new({ gold: 6, food: 6, prestige: 6 })
    # @bannermenDeck = (1..13).to_a
  end


  def play_turn

  end

  # Check if this player has a character in the provided office
  def has_office?(office)
    @characters.map { |c| c.where_am_i? }.include?(office)
  end

  # Returns a list of this player's unassigned workers
  def free_workers
    @workers.filter { |w| w.location.nil? }
  end

  # Assign a free worker to the provided building
  def place_worker(building)
    raise "No free workers" if free_workers.empty?
    free_workers.first.move(building)
  end

  # Move a worker from building b1 to building b2
  def reallocate_worker(b1, b2)
    ws = b1.workers.contents.filter { |w| w.player == self }
    raise "No workers in building #{b1}" if ws.empty?
    raise "Building #{b2} is full" if b2.workers.full?
    ws.first.move(b2)
  end

  # Returns a list of this player's unassigned characters
  def free_characters
    @characters.filter { |c| c.location.nil? }
  end

  # Assign a free character as manager of the provided building
  def place_manager(building)
    raise "No free characters" if free_characters.empty?
    raise "Building already has a manager" if !building.manager.empty?
    free_characters.first.move(building)
  end

  # Move a manager from building b1 to building b2
  def reallocate_manager(b1, b2)
    raise "No manager owned by this player in building #{b1}" if b1.manager.contents&.player != self
    raise "Building #{b2} already has a manager" if !b2.manager.empty?
    b1.manager.contents.move(b2)
  end

  

  ## Actions

  # All possible actions
  def possible_actions
  end

  # Build a building from the build queue
  def build_actions
    pos = @game.buildings.first_free_pos
    return [] if pos.nil?
    bs = @game.board.get_build_queue
    bs.map! { |b, c| [b, c/2] } if has_office?(:crown)
    bs.filter! { |b, c| c <= @coffer.gold }
    bs.map { |b, _| TurnAction.new("Built #{b.name}", ->{ b.build(pos) }) }
  end

  # Assign a free worker to a building with capacity for it
  def place_worker_actions
    return [] if free_workers.empty?
    bs = @game.board.constructed_buildings.filter { |b| !b.workers.full? }
    bs.map { |b| TurnAction.new("Moved worker to #{b.name}"), ->{ place_worker(b) } }
  end

  # Move a worker from its current building to another one with capacity
  def reallocate_worker_actions
    return [] if free_workers.length < @workers.length
    bs = @game.board.constructed_buildings.filter { |b| !b.workers.full? }
    @board.worked_buildings(self).map { |b|
      bs.filter { |b2| b != b2 }.map { |b2|
        TurnAction.new("Moved worker from #{b.name} to #{b2.name}", ->{ reallocate_worker(b, b2) })
      }
    }.flatten
  end

  # Assign a free character to a manager-less building
  def place_manager_actions
    return [] if free_characters.empty?
    bs = @game.board.constructed_buildings.filter { |b| b.manager.empty? }
    bs.map { |b| TurnAction.new("Moved character to #{b.name}"), ->{ place_manager(b) } }
  end

  # Move a character from a building to another manager-less building
  def reallocate_manager_actions
    @game.board.contructed_buildings.filter { |b| b.manager.contents == self}.map { |b|
      @game.board.constructed_buildings.map { |b2| b.manager.empty? }.map { |b2|
        TurnAction.new("Moved manager from #{b} to #{b2}", ->{ reallocate_manager(b, b2) })
      }
    }.flatten
  end

  # Attempt to vacate a building and install a free character there
  def takeover_actions
    return [] if free_characters.empty?
    @game.board.constructed_buildings.map { |b|
      ChallengeAction.new(
        "Took over #{b.name} and expelled all workers", ->{ b.vacate; free_characters.first.move(b) },
        "Died trying to take over #{b.name}", ->{ free_characters.first.kill }
      )
    }
  end

  # Move a free character into the court
  def court_actions
    return [] if free_characters.empty?
    return [] if @coffer.prestige >= 2
    [TurnAction.new("Moved character into court", ->{ free_characters.first.move(:court); @coffer.take({prestige: 2}) })]
  end

  # Send a free character on campaign
  def campaign_actions
    return [] if free_characters.empty?
    [TurnAction.new("Sent character on campaign", ->{ free_characters.first.move(:campaign) })]
  end

  # Recall an assigned character back to the player's hand
  def recall_character_actions
    @characters.filter { |c| ![:hand, :crypt, :dungeon].include?(c.where_am_i?) }.map { |c|
      TurnAction("Recalled character from #{c.where_am_i?.to_s}", ->{ c.move(nil)  })
    }
  end

end

class TurnAction
  def initialize(desc, action)
    @description = desc
    @action = action
  end

  def run(player, game)
    game.add_to_log([player, @description])
    action.call
  end
end

class ChallengeAction
  def initialize(succ_desc, succ_action, fail_desc, fail_action)
    @success_description = succ_desc
    @success_action = succ_action
    @failure_description = fail_desc
    @failure_action = fail_action
  end

  def run(player, game)
    if game.challenge
      game.add_to_log([player, @success_description])
      success_action.call
    else
      game.add_to_log([player, @failure_description])
      failure_action.call
    end
  end
end

=begin

Possible moves:

x Build a building from the build queue

x Place worker on a building with free spaces
x Reallocate worker

x Place character on an unmanaged building
x Reallocate manager
x Take-over building
x Place character in the court
x Place character on campaign
- Place character in office
x Recall character

- Purchase retainer (if worker/manager in Tavern)
- Place a retainer on a character
- Use retainer action


if Priest:
    - Tithe (collect money from all players based on how many workers they have (that aren't in a church))
    - Set sentencing
    
if Treasurer:
    - Collect base tax (constant amount) from all players
    - Collect random (1, 6) amount from a specific player

if Commander:
    - Target character for arreest (challenge if not ordered by King)
    - Vacate target building, sends all workers back to respective player hand. Moves workers from barracks into target buildng

if Spymaster 
        -peek at any deck (Crisis, law, retainer)
        -peak at retainer in play/on board(reveal)

if Crown
        -name heir
        -build at half cost
        -use any ability of subordinate (can refuse sacrificing oath card/prestige)
        -pardon prisoner (target)


=end