# jackz vehicles (v3)

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
* (1.16.7) Add "Upgrade Performance" and "Upgrade" to All Vehicles

V2.1.0

* Added a CLOUD VEHICLES system! Download, spawn, and upload custom vehicles between each other.
* 2.0.0 skipped because I accidently released 2.0.0 early with no changes
* (2.1.1) Fixed some users not generating cloud id
* (2.1.2) Fix vehicle folder not being created
* (2.1.3) Fix cloudID not being set on first-generation
* (2.1.4) Fix preview vehicle not vanishing when backing out of menu
* (2.1.5) Fix lauhttp lib not installing correctly
* (2.1.6) Fixed libs not downloading correctly. Again.
* (2.1.7) Fix error when hovering over 'upload' if lib was downloaded
* (2.1.8) Remove auto downloading luahttp due to corruption
* (2.1.9) Fixed 'hijack & drive to player'
* (2.1.9) Fix set license plate clearing on personal vehicles
* (2.1.10) Improved auto-spectating for all players

v2.2.0

* Added Autodrive > Chauffeur - A ped that will drive for you with full control
* Fix some search results being invalid

v2.3.0

* Added Spinning Cars
* Made uploaded vehicle account be unspoofed socialclub name
* (2.3.1) Improved loading of luahttp
* (2.3.2) Fix spawning saved vehicles not clearing preview
* (2.3.3) Made chauffeurs not flee when gunshots occur
* (2.3.3) Automatically warp player into passenger seat instead of hijacking
* (2.3.4) Used built in menu async_http instead of luahttp for uploading

v2.4.0

* Made nearby vehicles -> explode random. That's all. It's fun.
* (2.4.1) Add minor ui updates to cloud vehicles (show vehicle count & vehicle info on vehicle name)

v3.0.0

* Added complete translation support. All text elements (within reason) are pulled from a translations file.
* This took me like 5 hours
* (3.0.1) Fixed spawning errroing
* (3.0.2) Refactored a LOT of code
* (3.0.2) Automatically update translations library to latest

v3.1.0

* Added "Drive Vehicle" to player list
* (3.1.1) Added a 'Language' selector
* (3.1.2) Fixed not auto updating translation lib

v3.2.0

* Added saving/restoring vehicle extras
* Added modifying vehicle extras under LSC list
* Added in lua root "Current Vehicle Multiplers"
  * Lights Multipler
  * Acceleration
  * Traction
* Re-arranged some root menu items
* Moved spinning cars to nearby vehicles
* (3.2.1) Fixed changing extras not changing vehicle
* (3.2.1) Moved Set License Plate into Los Santos Customs
* (3.2.1) Fix spawnvehicle conflicting with official stand saving
* (3.2.1) Fixed extras not spawning on saved
* (3.2.2) Add text to loading indicators for cloud section
* (3.2.3) Add option to enable multipliers
  
v3.3.0

* Added autodrive
* Added LSC > Random Upgrade
* Added Root > Spawn In Vehicle
* Added Nearby Vehicles > List
  * Added Nearby Vehicles > List > Seats
* (3.3.1) Added all script spawned cars to list
* Added Smart Autodrive
* (3.3.2) Upgraded apis to new stand apis

v3.4.0

* Fixed Hijack all erroring
* Added Teleport Vehicle to Waypoint
* Fix bugs probably
* (3.4.1) Fix small bugs

v3.5.0

* Added Attachments > Tow & Drive
* Added Attachments > Spawn Cargobob & Fly

v3.6.0

* Use custom jackzvehiclelib file
* Fix some inconsistencies when saving vehicle colors
* Use latest natives

# actions (v1)

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

v 1.7.0

* Allow you to set the interval that voice lines are repeated
  * Best: Duration 0 for constant repeat at 500ms with kiflom or insult :)
* (1.7.6) Fixed 'controllable' not activating on first load
* (1.7.7) Improved loading time slightly
* (1.7.8) Upgraded apis to new stand apis

v1.8

* Fix failing to load issue
* Add cloud favorites system - Browse favorites from other users.
  * Uploading coming soon
* (1.8.1) Fix sub item count being 0
* (1.8.2) Catch ratelimit errors
* (1.8.3) Load animation data only on demand
* (1.8.3) Improve search algorithm
* (1.8.4) Reduce amount of menus created even further in browse

v1.9.0

* Added upload support, upload from recents or favorites
* Fix small bugs with browsing, smoother now
* Minor re-organizing of animation menus
* (1.9.1) Fix outdated stand api usage, thanks aaronlink127 for catching
* (1.9.2) Use updated natives

# jackz chat (v1)

V1.1.0

* Add setting to change how long a message is shown
* Set a cap to 20 messages to be shown at once
* (1.1.1) Minor changes
* (1.1.2) Add clarification
* (1.1.3) Pull channel list from server
* (1.1.4) Small UI changes

V1.2.0

* Added translation support
* (1.2.1) Added a 'Language' selector
* (1.2.2) Fixed not auto updating translation lib
* (1.2.3) Updated translations lib target version
* (1.2.4) Upgraded apis to new stand apis
* (1.2.5) Use updated natives

# train control (v1)

V1.1.0

* Added a toggle for global speed control
* Continously set speed for global train speed
* Fix delete last spawned train not working
* Fix deleting vehicle in spawned list not deleting
* Properly spawn in metro train
* Added loading indicator when models are first being loaded
* (1.1.1) Upgraded apis to new stand apis
* (1.1.2) Use updated natives

# jackz_vehicle_builder (v1)

V1.1.0

* Added swapping base vehicle
* Auto populate name when editing saved
