# jackz vehicles (v1.16.6)

V1.2

* Fixed bugs, added 'Set License Plate'

V1.3

* Fix teleport far not returning self to vehicle
* (Untested) Support spectating other players. Should work with Teleport Vehicle

V1.4

* Added door controls
* Rearranged menu options
  
V1.5

* Added painting car
* Added spawning any vehicle infront of a player
* Removed teleport far distance (normal teleport now works smarter)
* Made getting control of players that are too far auto spectate.
* 1.5.1: Changed hard 3s auto-spectate to soft 3s wait
* 1.5.2: Fixed auto-spectating activating when already spectating
* 1.5.2: Fixed auto-spectating not properly waiting

V1.6

* Added new Customization submenu:
  * Xenon Headlights Paint Type
  * Neon Lights (individual toggles and color)
  * Moved paint options to this menu
* Added Door Locking to doors submenu
* Added Landing Gear State (Retracted or Open) to doors submenu as well

V1.7

* Upgraded the 'Customization' menu (renamed to 'Los Santos Customs') and added:
  * Vehicle Mods - Contains the all 31 upgrades (wheel design, engine, transmission, etc.)
  * Upgrade
  * Performance Upgrade

V1.8

* Added saving of any vehicle to a json file
* Clone any player's vehicle
* Spawn any saved vehicles
* (1.8.1) Added option to apply to pre-existing vehicle
* (1.8.3) Allow restoring vehicle mods to stock (-1)
* (1.8.3) Fixed spawning saved vehicle erroring
Saved vehicles are stored in `%appdata%\Stand\Vehicles`. Format is not compatible with any other menu, but its similar to Paragon's.

V1.9

* Fixed following mods from not saving correctly: Xenon Headlights, Turbo, and Tire Smoke.
  * A new saved vehicle will need to be created, was not stored properly
* Added saving engine state
* Added some vehicle info to spawn saved vehicle list (vehicle manufacturer, name, and type, and format version)

V1.10

* Added Movement > Tow Options >
  * Tow (Wander) - Spawns a random tow truck infront, that will drive randomly
  * Tow (Waypoint) - Spawns a random tow truck, heading to your waypoint
  * Detatch Tow
* Added Flip Vehicle 180
* Added Hijack Vehicle - Makes a random npc hijack their vehicle and stops the vehicle instantly.
* Added under lua scripts:
  * Tow All Nearby Vehicles
  * Clear All Nearby Tows

V1.11

* Renamed Movement > Tow Options to Movement > Attachments
* Added Cargobob (Cargobob to Mt. Chiliad, Ocean, Waypoint)
* Added Trailer (Drive around, Take to Waypoint)
* Added Free Vehicle (Teleports vehicle upwards to escape trailers or cages)

V1.12

* Added Clean Vehicle
* Improved Hijacking Success
* Added Delete Vehicle
* Improved Cargo All Nearby Vehicles (Makes them have no collision at beginning)
* Fix spawn saved vehicles being named "Spawn"
* Switch Tow trucks to "Avoid Traffic" driving style

V1.13

* Added preview vehicle for spawning saved vehicles
* (1.13.1) Added more checks for saved vehicles for invalid or missing entries
* (1.13.1) Delete spawn preview on spawn

V1.14

* Added Clear All Nearby Vehicles
* Added Hijack All Nearby Vehicles
* Removed Activate on Last Vehicle (Automatic now)
* Added 'Honk' and 'honkall' commands
* Re-organized nearby actions to submenu ("Nearby Vehicles")
* Added "Cargobob to Them"
* Added "Towtruck to Them"

V1.15.0

* Replaced x To Them with "X to Player"
* Added "Hijack & Drive To Player" option
* Fixed tow to player actually not working
* Remove cargobobs automatically when told to detach
* Improved 'Upgrade'
* (1.15.1) Fixed cargobob to player just following itself
* (1.15.2) Fix tow to player hijacking vehicle instead
* (1.15.3) Fix tow all nearby towing farthest instead
* (1.15.4) Automatically flip vehicle upright for more efficient cargobobing

V1.16.0

* Added "Titan" attachments: (circles around destination)
  * Fly to Mt. Chiliad
  * Fly to Waypoint
  * Fly to Player
* Added "All Vehicles" menu:
  * Nearby Only (on by default, off will auto spectate all far vehicles one by one)
  * Clean Vehicle
  * Repair Vehicle
  * Toggle Godmode
  * Set License Plate
* Added "Use Magnet" to cargobob attachments
* Added Nearby Vehicles -> "Cargobob Nearby Cars (Magnet)"
* (1.16.1) Lots of bug fixes & improvements
* (1.16.1) Also merged vehicle_autodrive into script
* (1.16.4) Fix color not applying to some stock vehicles
* (1.16.5) Possible fix for apply spawning new vehicles instead
* (1.16.6) Remove old named version (vehicle_options.lua)

# actions (v1.7.1)

v1.1

* Fixed lua failure when search result returned < 20
* Added an option to immediately stop anim/scenario when switching to new one
v1.2

* Added a favorites system
* (1.2.1) Fixed favorites causing errors
* (1.2.2) Added alias support (must be manually written to file)

v1.3

* Added a recents menu
* Made animations list alphabetically (requires new animations.lua lib file)
* Added playing animations and scenarios on other peds (See 'Action Targets' menu item)

v1.4

* Nested organization - Still not _perfect_ but at this point, it's good enough.
* Removed search - Due to new alphabetical system & lua stupidity had to be removed
* Fixed favorites not being removed
* Note: Requires new animations.lua library! 

v1.5

* Re-added category search

v1.6

* Added [Ambient Speech] menu for npcs and self:
* Plays certain phrases with certain methods (shouted, megaphone, etc)
* Able to play on self, choose a voice under Self Model Voice (spawns an invisible attached ped)
* (1.7.0) Allow you to set the interval that voice lines are repeated
  * Best: Duration 0 for constant repeat at 500ms with kiflom or insult :)