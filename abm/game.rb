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