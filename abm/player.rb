require_relative 'pieces'
require_relative 'coffer'


class Player
    
  attr_reader :game, :playerID, :workers, :characters, :retainers, :coffer

  def initialize(game, playerID)
    @game = game
    @playerID = playerID
    @workers = Array.new(4) { Worker.new(self) }
    @characters = Array.new(6) { Character.new(self) }
    @retainers = []
    @coffer = Coffer.new({ gold: 20, food: 6, prestige: 6 })
  end


  def play_turn
    pa = possible_actions
    # puts "POSSIBLE ACTIONS FOR PLAYER #{@playerID}: " + pa.to_s
    pa.sample&.run(@game)
  end

  # Check if this player has a character in the provided office
  def has_office?(office)
    @characters.map(&:where_am_i?).include?(office)
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

  def other_players
    @game.players - [self]
  end

  def no_usable_characters?
    @characters.map { |c| [:dungeon, :crypt].include?(c.where_am_i?) }.all?
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

  # Give resources to player
  def give(resources)
    @coffer.give(resources)
  end

  # Take resources from player
  def take(resources)
    @coffer.take(resources)
  end

  def show
    "P#{@playerID} #{@coffer.show}"
  end

  

  ## Actions

  # All possible actions
  def possible_actions
    # @game.add_to_log [playerID, treasurer_actions, has_office?(:treasurer)].inspect
    [
      build_actions,
      place_worker_actions,
      reallocate_worker_actions,
      place_manager_actions,
      reallocate_manager_actions,
      takeover_actions,
      court_actions,
      campaign_actions,
      recall_character_actions,
      move_to_office_actions,
      priest_actions,
      treasurer_actions
    ].flatten
  end

  # Build a building from the build queue
  def build_actions
    pos = @game.board.buildings.first_free_pos
    return [] if pos.nil?
    bs = @game.board.get_build_queue
    bs.map! { |b, c| [b, c/2] } if has_office?(:crown)
    bs.filter! { |b, c| c <= @coffer.gold }
    bs.map { |b, c| TurnAction.new(self, "Built #{b.name}", ->{ b.build(pos); take({gold: c}) }) }
  end

  # Assign a free worker to a building with capacity for it
  def place_worker_actions
    return [] if free_workers.empty?
    bs = @game.board.constructed_buildings.filter { |b| !b.workers.full? }
    bs.map { |b| TurnAction.new(self, "Moved worker to #{b.name}", ->{ place_worker(b) }) }
  end

  # Move a worker from its current building to another one with capacity
  def reallocate_worker_actions
    return [] if free_workers.length < @workers.length
    bs = @game.board.constructed_buildings.filter { |b| !b.workers.full? }
    @game.board.worked_buildings(self).map { |b|
      bs.filter { |b2| b != b2 }.map { |b2|
        TurnAction.new(self, "Moved worker from #{b.name} to #{b2.name}", ->{ reallocate_worker(b, b2) })
      }
    }.flatten
  end

  # Assign a free character to a manager-less building
  def place_manager_actions
    return [] if free_characters.empty?
    bs = @game.board.constructed_buildings.filter { |b| b.manager.empty? }
    bs.map { |b| TurnAction.new(self, "Moved character to #{b.name}", ->{ place_manager(b) }) }
  end

  # Move a character from a building to another manager-less building
  def reallocate_manager_actions
    @game.board.constructed_buildings.filter { |b| b.manager.contents == self}.map { |b|
      @game.board.constructed_buildings.map { |b2| b.manager.empty? }.map { |b2|
        TurnAction.new(self, "Moved manager from #{b} to #{b2}", ->{ reallocate_manager(b, b2) })
      }
    }.flatten
  end

  # Attempt to vacate a building and install a free character there
  def takeover_actions
    return [] if free_characters.empty?
    @game.board.constructed_buildings.filter { |b| !b.manager.empty? && b.manager.contents != self && !b.locked? }.map { |b|
      ChallengeAction.new(self,
        "Took over #{b.name} and expelled all workers", ->{ b.vacate; free_characters.first.move(b); b.lock },
        "Died trying to take over #{b.name}", ->{ free_characters.first.kill; b.lock }
      )
    }
  end

  # Move a free character into the court
  def court_actions
    return [] if free_characters.empty?
    return [] if @coffer.prestige <= 2
    return [] if @game.board.court.full?
    [TurnAction.new(self,
      "Moved character into court",
      ->{ free_characters.first.move(:court, @game.board.court.first_free_pos); @coffer.take({prestige: 2}) }
    )]
  end

  # Send a free character on campaign
  def campaign_actions
    return [] if free_characters.empty?
    return [] if @game.board.campaign.full?
    [TurnAction.new(self, "Sent character on campaign", ->{ free_characters.first.move(:campaign) })]
  end

  # Recall an assigned character back to the player's hand
  def recall_character_actions
    @characters.filter { |c| ![:hand, :crypt, :dungeon].include?(c.where_am_i?) }.map { |c|
      TurnAction.new(self, "Recalled character from #{c.where_am_i?.to_s}", ->{ c.move(nil) })
    }
  end

  # Move a character in the court into a free office position
  def move_to_office_actions
    characters_in_court = @characters.filter { |c| c.where_am_i? == :court }
    return [] if characters_in_court.empty?
    offices = [:priest, :treasurer, :commander, :spymaster]
    offices.filter! { |office| @game.board.office_available?(office) && @game.board.get_office(office).empty? }
    offices.map { |office|
      TurnAction.new(self, "Moved character into office: #{office.to_s.capitalize}", ->{ characters_in_court.first.move(office) })
    }
  end

  # Priest abilities. Collect tithes & change sentencing
  def priest_actions
    return [] if !has_office?(:priest)
    ([:fine, :prison, :death] - [@game.board.sentencing]).map { |s|
      TurnAction.new(self,
        "The Priest changed the sentencing to #{s.to_s.upcase}",
        ->{ @game.board.set_sentencing(s) }
      )
    } + [TurnAction.new(self,
      "The Priest has collected a tithe",
      ->{ @game.players.each { |player|
        next if player == self 
        if !player.workers.any? { |w| w.location.is_a?(Church) }
          player.take({gold: 2})
          give({gold: 2})
        end
      }}
    )]
  end

  def treasurer_actions
    return [] if !has_office?(:treasurer)
    other_players.map { |player|
      audit_strength = ((1..6).to_a.sample) + 2
      TurnAction.new(self,
        "The Treasurer has audited player #{player.playerID} and taken #{audit_strength} gold",
        ->{ player.take({gold: audit_strength}); @game.board.coffer.give({gold: audit_strength}) }
      )
    } + [
      TurnAction.new(self,
        "The Treasurer has collected taxes from all players",
        ->{
          other_players.each do |player|
            if player.coffer.gold >= 2
              player.take({gold: 2})
              @game.board.coffer.give({gold: 2})
            else
              player.take({prestige: 2})
            end
          end
         }
      )
    ]
  end

end



class TurnAction

  def initialize(player, desc, action)
    @player = player
    @description = desc
    @action = action
  end

  def run(game)
    @action.call
    game.add_to_log(self)
  end

  def desc
    "Player #{@player.playerID}: #{@description}"
  end

end



class ChallengeAction

  def initialize(player, succ_desc, succ_action, fail_desc, fail_action)
    @success = TurnAction.new(player, succ_desc, succ_action)
    @failure = TurnAction.new(player, fail_desc, fail_action)
  end

  def run(game)
    if game.challenge
      @success.run(game)
    else
      @failure.run(game)
    end
  end

end

=begin

Possible moves:

# Buildings
x Build a building from the build queue

# Workers
x Place worker on a building with free spaces
x Reallocate worker

# Characters
x Place character on an unmanaged building
x Reallocate manager
x Take-over building
x Place character in the court
x Place character on campaign
x Place character in office
x Recall character

# Retainers
- Purchase retainer (if worker/manager in Tavern)
- Place a retainer on a character
- Use retainer action

# Priest
- Tithe (collect money from all players that don't have a worker in the church)
- Set sentencing
    
# Treasurer
- Collect base tax (constant amount) from all players. If a player can't pay they get punished (or lose prestige?)
- Collect random (1, 6) amount from a specific player

# Commander
- Target character for arreest (challenge if not ordered by King)
- Vacate target building, sends all workers back to respective player hand. Moves workers from barracks into target buildng

# Spymaster
-peek at any deck (Crisis, law, retainer)
-peak at retainer in play/on board(reveal)

# Crown
x build at half cost (passive)
- name heir        
- use any ability of subordinate (can refuse sacrificing oath card/prestige)
- pardon prisoner (target)





### GOALS ###
- Gold
- Food
- Prestige
- Reputation
- Power

- Risk (negative)
- Cost

Build a farm
{ cost: -2, food: 3, risk: -1 }


{ cost: 2, risk: 0.5 }





=end