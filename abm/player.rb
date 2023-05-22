require_relative 'pieces'
require_relative 'coffer'
require_relative 'actions'


class Player
    
  attr_reader :game, :id, :workers, :characters, :retainers, :coffer

  def initialize(game, id)
    @game = game
    @board = game.board
    @id = id
    @workers = Array.new(4) { Worker.new(self) }
    @characters = Array.new(6) { Character.new(self) }
    @retainers = []
    @coffer = Coffer.new({ gold: 20, food: 6, prestige: 6 })
  end

  ### Info Methods & Calculated Properties ###

  # Check if this player has a character in the provided office
  def has_office?(office) = @characters.map(&:where_am_i?).include?(office)

  # Check if this player has any characters who are not dead or in the dungeon
  def no_usable_characters? = @characters.all? { |c| [:dungeon, :crypt].include?(c.where_am_i?) }

  # Returns a list of this player's unassigned workers
  def free_workers = @workers.filter { |w| w.location.nil? }

  # Get a list of buildings worked by this player
  def worked_buildings = @board.constructed_buildings.filter { |b| b.workers.contents&.any? { |w| w.player == self }}

  # Returns a list of this player's unassigned characters
  def free_characters = @characters.filter { |c| c.location.nil? }

  # Returns a list of all the other players in this game (excluding itself)
  def other_players = @game.players - [self]

  # Render player status
  def show = "P#{@id} #{@coffer.show}"


  ### Character Piece Management Helper Methods ###

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
  def give(resources) = @coffer.give(resources)

  # Take resources from player
  def take(resources) = @coffer.take(resources)


  ### Game Logic ###

  # Make player take their turn
  def take_turn!
    pa = actions
    pa.sample&.run(@game)
  end
  

  ### Actions ###

  # TODO: Break-up other office abilities (like commander)

  # All possible actions
  def actions
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
      treasurer_actions,
      commander_actions,
      spymaster_actions
    ].flatten
  end

  # Build a building from the build queue
  def build_actions
    pos = @board.buildings.first_free_pos
    return [] if pos.nil?
    bs = @board.get_build_queue
    bs.map! { |b, c| [b, c/2] } if has_office?(:crown)
    bs.filter! { |b, c| c <= @coffer.gold }
    bs.map { |b, c| Action.new(self, "Built #{b.name}", ->{ b.build(pos); take({gold: c}) }) }
  end

  # Assign a free worker to a building with capacity for it
  def place_worker_actions
    return [] if free_workers.empty?
    bs = @board.constructed_buildings.filter { |b| !b.workers.full? }
    bs.map { |b| Action.new(self, "Moved worker to #{b.name}", ->{ place_worker(b) }) }
  end

  # Move a worker from its current building to another one with capacity
  def reallocate_worker_actions
    return [] if free_workers.length < @workers.length
    bs = @board.constructed_buildings.filter { |b| !b.workers.full? }
    worked_buildings.map { |b|
      bs.filter { |b2| b != b2 }.map { |b2|
        Action.new(self, "Moved worker from #{b.name} to #{b2.name}", ->{ reallocate_worker(b, b2) })
      }
    }.flatten
  end

  # Assign a free character to a manager-less building
  def place_manager_actions
    return [] if free_characters.empty?
    bs = @board.constructed_buildings.filter { |b| b.manager.empty? }
    bs.map { |b| Action.new(self, "Moved #{free_characters.first.name} to #{b.name}", ->{ place_manager(b) }) }
  end

  # Move a character from a building to another manager-less building
  def reallocate_manager_actions
    @board.constructed_buildings.filter { |b| b.manager.contents == self}.map { |b|
      @board.constructed_buildings.map { |b2| b.manager.empty? }.map { |b2|
        Action.new(self, "Moved manager from #{b} to #{b2}", ->{ reallocate_manager(b, b2) })
      }
    }.flatten
  end

  # Attempt to vacate a building and install a free character there
  def takeover_actions
    return [] if free_characters.empty?
    @board.constructed_buildings.filter { |b| !b.manager.empty? && b.manager.contents != self && !b.locked? }.map { |b|
      ChallengeAction.new(self,
        "#{free_characters.first.name} took over #{b.name} and expelled all workers", ->{ b.vacate; free_characters.first.move(b); b.lock },
        "#{free_characters.first.name} died trying to take over #{b.name}", ->{ free_characters.first.kill; b.lock }
      )
    }
  end

  # Move a free character into the court
  def court_actions
    return [] if free_characters.empty? || @coffer.prestige <= 2 || @board.court.full?
    [Action.new(self,
      "Moved #{free_characters.first.name} into court",
      ->{ free_characters.first.move(:court, @board.court.first_free_pos); @coffer.take({prestige: 2}) }
    )]
  end

  # Send a free character on campaign
  def campaign_actions
    return [] if free_characters.empty? || @board.campaign.full?
    [Action.new(self, "Sent #{free_characters.first.name} on campaign", ->{ free_characters.first.move(:campaign) })]
  end

  # Recall an assigned character back to the player's hand
  def recall_character_actions
    @characters.filter { |c| ![:hand, :crypt, :dungeon].include?(c.where_am_i?) }.map { |c|
      Action.new(self, "Recalled #{c.name} from #{c.where_am_i?.to_s}", ->{ c.move(nil) })
    }
  end

  # Move a character in the court into a free office position
  def move_to_office_actions
    characters_in_court = @characters.filter { |c| c.where_am_i? == :court }
    return [] if characters_in_court.empty?
    offices = [:priest, :treasurer, :commander, :spymaster]
    offices.filter! { |office| @board.office_available?(office) && @board.get_office(office).empty? }
    offices.map { |office|
      Action.new(self, "Moved #{characters_in_court.first.name} into office: #{office.to_s.capitalize}", ->{ characters_in_court.first.move(office) })
    }
  end

  # Priest abilities. Collect tithes & change sentencing
  def priest_actions
    return [] if !has_office?(:priest)
    ([:fine, :prison, :death] - [@board.sentencing]).map { |s|
      Action.new(self,
        "The Priest changed the sentencing to #{s.to_s.upcase}",
        ->{ @board.set_sentencing(s) }
      )
    } + [Action.new(self,
      "The Priest has collected a tithe",
      ->{ other_players.each { |player|
        if player.worked_buildings.all? { |b| !b.is_a?(Church) }
          player.take({gold: 2})
          give({gold: 2})
        end
      }}
    )]
  end

  # Treasurer abilities. Tax all players & audit specific player
  def treasurer_actions
    return [] if !has_office?(:treasurer)
    other_players.map { |player|
      audit_strength = ((1..6).to_a.sample) + 2
      Action.new(self,
        "The Treasurer has audited player #{player.id} and taken #{audit_strength} gold",
        ->{ player.take({gold: audit_strength}); @board.coffer.give({gold: audit_strength}) }
      )
    } + [
      Action.new(self,
        "The Treasurer has collected taxes from all players",
        ->{
          other_players.each do |player|
            if player.coffer.gold >= 2
              player.take({gold: 2})
              @board.coffer.give({gold: 2})
            else
              player.take({prestige: 2})
            end
          end
         }
      )
    ]
  end

  # Commander abilities (punish & vacate)
  def commander_actions
    return [] if !has_office?(:commander)
    commander_punish_actions + commander_vacate_actions
  end

  # Punish a character with equal or less prestige (if challenge successful)
  # TODO: King can punish without challenge
  def commander_punish_actions
    other_players
    .filter { |player| player.coffer.prestige <= @coffer.prestige }
    .map(&:characters)
    .flatten
    .filter { |c| ![:hand, :crown, :dungeon, :crypt].include?(c.where_am_i?)  }
    .map { |c|
      ChallengeAction.new(self,
        "The Commander has punished Player #{c.player.id}",
        ->{ c.punish },
        "Player #{c.name} managed to escape the long arm of the law",
        ->{}
      )
    }
  end

  # Vacate a building and move all the commander's workers in the barracks there
  def commander_vacate_actions
    @board.constructed_buildings
      .filter { |b| !b.is_a?(Barracks) && !b.workers.contents.any? { |w| w.player == self } }
      .map { |b|
        Action.new(self,
          "The Commander has seized a #{b.name} and moved any of his workers in the barracks there",
          -> { b.vacate;  @workers.filter { |w| w.location.is_a?(Barracks) }.each { |w| w.move(b) } }
        )
      }
  end


end

  # Spymaster abilities. Blackmail, Peek at top card (not impelmented)
  def spymaster_actions
    return [] if !has_office?(:spymaster)
    spymaster_blackmail_actions
  end

  #Blackmail players who have workers present in the tavern 
  def spymaster_blackmail_actions
    other_players
    .filter { |player| player.worked_buildings.all? { |b| b.is_a?(Tavern)} }
    .flatten
    .map { |player|
      Action.new(self,
        "The Spymaster has collected evidence to blackmail visitors in the Tavern", -> { player.take({prestige: 2})} #not sure if it takes prestige from each player
      )
    }

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

# Priest
x Tithe (collect money from all players that don't have a worker in the church)
x Set sentencing
    
# Treasurer
x Collect base tax (constant amount) from all players. If a player can't pay they get punished (or lose prestige?)
x Collect random (1, 6) amount from a specific player

# Commander
x Target character for arreest (challenge if not ordered by King)
x Vacate target building, sends all workers back to respective player hand. Moves workers from barracks into target buildng

# Spymaster
- peek at any deck (Crisis, law, retainer)
- peak at retainer in play/on board(reveal)

# Crown
x build at half cost (passive)
- name heir        
- use any ability of subordinate (can refuse sacrificing oath card/prestige)
- pardon prisoner (target)

# Retainers
- Purchase retainer (if worker/manager in Tavern)
- Place a retainer on a character
- Use retainer action

# Heir?
???


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