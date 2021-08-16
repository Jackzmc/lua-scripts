# vehicle options (v1.8)

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
Saved vehicles are stored in `%appdata%\Stand\Vehicles`. Format is not compatible with any other menu, but its similar to Paragon's.

# actions (v1.5)

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