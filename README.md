1.1	– The Game

In The Queen is Dead, each player takes on the role of a family Dynasty vying for the Crown.

The game begins by choosing a new monarch through diplomacy or force. Once chosen the game begins starting with the player who took the Crown. The game is played in rounds, each round represents a season. There are three seasons. A player may take up to three actions per season. At the end of the third season marks the passing of one year and a second phase takes place where players contribute resources to the overall Realm Upkeep which is determined by the number of buildings constructed.

If the quota is not met, a Crisis card is drawn and resolved. If three crises occur, the game ends and everyone loses. If all six family members from a single player are killed or imprisoned, the game ends and current Crown wins. Otherwise, in order to win, the first to take the throne must reign for three consecutive years. Else a player must take and hold the throne within their family for six consecutive seasons. Finally, on the fifth year, whoever holds the Crown is declared the winner and the game ends. 

The game board is divided into two zones. First, the Capitol where buildings are constructed and workers can be placed to generate resources (food and gold). Second, the Royal Court, which is further subdivided into the High Court and the Low Court. 

Each player has 4 workers at their disposal for placement on buildings in the Capitol. However their most important resource are the core family members which may enter Court, go on Campaign, or manage buildings for extra resources. 

There are 5 important offices in the Royal Court, each with unique abilities that can be used as one action on a player’s turn. The offices are the Crown, the Commander, the High Priest, the Spymaster, and the Lord Treasurer.

High Priest
Collect Tithe, all players with no workers in a church will pay a tithe of 1 gold to the priest.
Set sentencing: choose between fine (paid to priest), prison, or execution. Sentencing handles family characters who are punished.

Commander
Arrest a character
Seize and Vacate a building using his own workers in the barracks. 

Lord Treasurer
Collect Tax from all players – collects tax at base rate of 2 gold 2 food
Audit a target player – rolls a die and takes the result + 2 gold

Spymaster
Blackmail all players with pieces in the tavern
Peak at top cards of any deck
Peak at retainer cards

Crown
Delegate – use the ability of any subordinate office as if crown performed themselves, blocking this action from use by the subordinate if applicable.  
Construct buildings at half cost
Pardon prisoner
Name Heir 

[x] Tithe/Blackmail check if actions are even sensible

[x] Color Log Output by Player

[x] Implement campaign challenge each round

[x] Cost prestige to appoint to office

[x] Challenge Crown
  [x] Action (challenge)

[x] Crisis
  [x] Cards
  [x] Crisis Actions

[x] Realm Upkeep

[x] Reputation System

[~] Heuristic System
  [x] Player Priorities
  [x] Player Effect-Score calculation
  [x] Player sort by effect-score
  [x] Player does 3 actions per turn
  [~] Buildings Effects (build, place_worker, remove_worker, place_manager, remove_manager)
    [x] Apothecary
    [x] Bank
    [x] Barracks
    [x] Church
    [~] Farm (TODO: move during winter?)
    [x] Guild Hall
    [x] Market
    [~] Mercenary Camp
    [x] Mines
    [~] Tavern
  [~] Effects
    [x] Build Building Effects (defer to building & scale cost if crown)
    [x] Place Worker Effects (defer to building)
    [x] Reallocate Worker Effects (target effects + -current_location effects)
    [x] Place Manager Effects (defer to building)
    [x] Reallocate Manager Effects (target effects + -current_location effects)
    [x] Takeover Effects (defer to building + high risk + medium power + karma)
    [x] Court Effects (hardcoded power + low risk)
    [x] Campaign Effects (hardcoded prestige + gold + high risk)
    [x] Recall Character (-current_location effects + -risk)
    [~] Appoint to Office (TODO: hardcoded -prestige)
      [x] Priest (hardcoded high power + gold + low risk)
      [x] Treasurer (hardcoded medium power + gold + low risk)
      [x] Commander (hardcoded high power + medium risk)
      [x] Spymaster (hardcoded medium power + low risk)
      [x] Crown (hardcoded high power + high gold + high risk)
    [x] Priest Actions
      [x] Sentencing (hardcoded (for each type) risk + (power?)
      [x] Tithe (hardcoded gold) [add in karma]
    [x] Treasurer Actions
      [x] Tax (power) [add in karma]
      [x] Audit (power)
    [x] Commander Actions
      [x] Punish (hardcoded high risk)
      [x] Vacate (hardcode ddefer to building + high power)
    [x] Spymaster Actions
      [x] Blackmail (hardcoded medium power)
    [x] Crown
      [x] Pardon (hardcoded medium power)
      [x] Name Heir ()
      [x] Sub-Actions (delegate)

[ ] Retainers

[ ] Bannermen
  [ ] Mercenary Camp

[ ] Oath cards

[ ] Laws
