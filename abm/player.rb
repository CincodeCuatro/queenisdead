require_relative 'pieces'
require_relative 'coffer'
require_relative 'actions'


class Player

  # Print smaller info for debug (remove for final project)
  def inspect = "#{self.class.to_s.upcase}-#{self.object_id}"
    
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
    a = pa.sample
    a&.run(@game)
  end
  

  ### Actions ###

  # TODO: Break-up other office abilities (like commander)

  # All possible actions
  # N.B. in the case that a player has both the crown and another office this method returns each of that office's actions twice
  def actions
    possible_actions = base_actions
    possible_actions.concat(priest_actions) if has_office?(:priest)
    possible_actions.concat(treasurer_actions) if has_office?(:treasurer)
    possible_actions.concat(commander_actions) if has_office?(:commander)
    possible_actions.concat(spymaster_actions) if has_office?(:spymaster)
    possible_actions.concat(crown_actions) if has_office?(:crown)
    return possible_actions.flatten
  end

  # Base actions all players can do
  def base_actions
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
      move_to_office_actions
    ]
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
    priest_sentencing_actions + priest_tithe_actions
  end

  def priest_sentencing_actions
    return [] if !@board.office_action_available?(:priest_sentencing)
    ([:fine, :prison, :death] - [@board.sentencing]).map { |s|
      Action.new(self,
        "The Priest changed the sentencing to #{s.to_s.upcase}",
        ->{ @board.set_sentencing(s); @board.lock_office_action(:priest_sentencing) }
      )
    }
  end

  def priest_tithe_actions
    return [] if !@board.office_action_available?(:priest_tithe)
    [Action.new(self,
      "The Priest has collected a tithe",
      ->{ other_players.each { |player|
        if player.worked_buildings.all? { |b| !b.is_a?(Church) }
          player.take({gold: 2})
          give({gold: 2})
        end
        @board.lock_office_action(:priest_tithe)
      }}
    )]
  end

  # Treasurer abilities. Tax & audit
  def treasurer_actions
     treasurer_tax_actions + treasurer_audit_actions
  end

  # Treasurer can tax all players
  def treasurer_tax_actions
    return [] if !@board.office_action_available?(:treasurer_tax)
    [Action.new(self,
      "The Treasurer has collected taxes from all players",
      ->{ other_players.each do |player|
          if player.coffer.gold >= 2
            player.take({gold: 2})
            @board.coffer.give({gold: 2})
          else
            player.take({prestige: 2})
          end
        end
        @board.lock_office_action(:treasurer_tax) 
      }
    )]
  end

  # Treasurer can audit a specific player
  def treasurer_audit_actions
    return [] if !@board.office_action_available?(:treasurer_audit)
    other_players.map { |player|
      audit_strength = ((1..6).to_a.sample) + 2
      Action.new(self,
        "The Treasurer has audited player #{player.id} and taken #{audit_strength} gold",
        ->{ player.take({gold: audit_strength}); @board.coffer.give({gold: audit_strength}); @board.lock_office_action(:treasurer_audit) }
      )
    }
  end

  # Commander abilities (punish & vacate)
  def commander_actions(from_crown=false)
    commander_punish_actions(from_crown) + commander_vacate_actions
  end

  # Punish a character with equal or less prestige (if challenge successful)
  # TODO: King can punish without challenge
  def commander_punish_actions(from_crown=false)
    return [] if !@board.office_action_available?(:commander_punish)
    other_players
    .filter { |player| player.coffer.prestige <= @coffer.prestige }
    .map(&:characters)
    .flatten
    .filter { |c| ![:hand, :crown, :dungeon, :crypt].include?(c.where_am_i?)  }
    .map { |c|
      if from_crown
        Action.new(self,
          "The Commander has punished Player #{c.player.id}",
          ->{ c.punish; @board.lock_office_action(:commander_punish) }
        )
      else
        ChallengeAction.new(self,
          "The Commander has punished Player #{c.player.id}",
          ->{ c.punish; @board.lock_office_action(:commander_punish) },
          "Player #{c.name} managed to escape the long arm of the law",
          ->{ @board.lock_office_action(:commander_punish) }
        )
      end
    }
  end

  # Vacate a building and move all the commander's workers in the barracks there
  def commander_vacate_actions
    return [] if !@board.office_action_available?(:commander_vacate)
    @board.constructed_buildings
      .filter { |b| !b.is_a?(Barracks) && !b.workers.contents.any? { |w| w.player == self } }
      .map { |b|
        Action.new(self,
          "The Commander has seized a #{b.name} and moved any of his workers in the barracks there",
          -> {
            b.vacate
            @workers.filter { |w| w.location.is_a?(Barracks) }.each { |w| w.move(b) if !b.workers.full? }
            @board.lock_office_action(:commander_vacate)
          }
        )
      }
  end

  # Spymaster abilities. Blackmail, Peek at top card (not impelmented)
  def spymaster_actions
    spymaster_blackmail_actions
  end

  # Blackmail players who have workers present in the tavern 
  def spymaster_blackmail_actions
    return [] if !@board.office_action_available?(:spymaster_blackmail)
    players_in_the_tavern = other_players.filter { |player| player.worked_buildings.any? { |b| b.is_a?(Tavern)} }
    [Action.new(self,
      "The Spymaster has collected evidence to blackmail visitors in the Tavern",
      ->{ players_in_the_tavern.map {|player| player.take({prestige: 2}) }; @board.lock_office_action(:spymaster_blackmail) }
    )]
  end

  # Crown actions. Pardon, name heir, and all sub-office actions
  def crown_actions
    crown_pardon_actions + crown_heir_actions + crown_delegate_actions
  end

  # Free a character from the dungeon
  def crown_pardon_actions
    return [] if !@board.office_action_available?(:crown_pardon)
    @board.dungeon.contents.compact.map { |c|
      Action.new(self, "The Crown has pardoned #{c.name}", ->{ c.move(nil); @board.lock_office_action(:crown_pardon) })
    }
  end

  # Name an heir
  def crown_heir_actions
    return [] if !@board.office_action_available?(:crown_heir)
    @board.court.get_all.map { |c|
      Action.new(self,
        "The Crown has named #{c.name} as their successor",
        ->{ @board.heir.contents&.move(nil); c.move(:heir); @board.lock_office_action(:crown_heir) }
      )
    }
  end

  # Actions of any other non-empty office
  def crown_delegate_actions
    delegate_actions = []
    delegate_actions.concat(priest_actions) if !@board.priest.empty?
    delegate_actions.concat(treasurer_actions) if !@board.treasurer.empty?
    delegate_actions.concat(commander_actions(true)) if !@board.commander.empty?
    delegate_actions.concat(spymaster_actions) if !@board.spymaster.empty?
    delegate_actions.map(&:from_crown)
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
? peek at any deck (Crisis, law, retainer)
? peak at retainer in play/on board(reveal)
x Take presitige from everyone with a worker in the tavern (blackmail)

# Crown
x build at half cost (passive)
x name heir (oath cards?)
x use any ability of subordinate (TODO: can refuse sacrificing oath card/prestige)
x pardon prisoner (target)

# Heir?
x Heir gets promoted to crown if crown leaves/gets-killed

# Retainers
- Purchase retainer (if worker/manager in Tavern)
- Place a retainer on a character
- Use retainer action



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