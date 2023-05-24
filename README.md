# queenisdead
Agent based Model for testing board game


[x] Tithe/Blackmail check if actions are even sensible

[x] Color Log Output by Player

[ ] Implement campaign challenge each round

[ ] Cost prestige to appoint to office

[ ] Challenge Crown
  [ ] Action (challenge)

[ ] Crisis
  [ ] Cards
  [ ] Crisis Actions

[ ] Realm Upkeep

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
