# jackz vehicles (v3)

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
* (3.6.1) Reflect Stand API Change
* (3.6.2) Remove auto updated dupe files
* (3.6.5) Update cloud code to new database system
* (3.6.5) Improved cloud browse & search code as well
* (3.6.6) Fix cloud vehicle browsing failing to load some users
* (3.6.7) Update jackzvehiclelib
* (3.6.8) Bug fix
  
v3.7.0

* Support subfolders in vehicle list
* Rename "Current Vehicle Multiplers" to "Current Vehicle Settings"
* Add Always Keep Upright to above list
* (3.7.2) Possibly fix cloud user's vehicles list being empty
* (3.7.3) Sorry, parser acted up again, fixed termination issue
* (3.7.5) Added korean translations (Thanks IceDoomfist)
* (3.7.6) Updated translations lib
* (3.7.7) Minor fixes
* (3.7.8) Possible fix for rare vehicle saving failure
* (3.7.9) Fix bug with vehicle lib
* (3.7.10) Update jackzvehiclelib
* (3.7.11) Fix some lua bugs, updated translations
* (3.7.12) Update LSC for new wheel types (Thanks hexarobi)

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
* (1.9.3) Don't load translations as too lazy to set that up
* (1.9.4) Remove auto updated dupe files
* (1.9.6) "Fix" race error on cloud fetch
* (1.9.7) Update cloud url
* (1.9.8) Fix outdated code prompting lang meta menu

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
* (1.2.6) Remove auto updated dupe files
* (1.2.11) Use updated lang
* (1.2.16) Added korean translations (Thanks IceDoomfist)
* (1.2.17) Updated translations lib
* (1.2.18) Switched chat server to fix script not working

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
* (1.1.3) Remove auto updated dupe files
* (1.1.6) Fix errors
* (1.1.7) Updated translations

# jackz vehicle builder (v1)

V1.1.0

* Added swapping base vehicle
* Auto populate name when editing saved
* (1.1.1) Reflect Stand API Change

V1.2.0

* Added previews for saved custom vehicles

V1.3.0

* Add ability to mark objects and base vehicle as invisible
* Made previews non-networked, less buggy hopefully
* (1.3.1) Hopefully fix some loading issues
* (1.3.2) Fix vehicle savedata not being loaded
* (1.3.3) Actually make previews non networked
* (1.3.4) Fix previews spawning incorrectly
* (1.3.4) Remove auto updated dupe files

V1.4.0

* Added spawning in vehicles (Manual Input for now)
* Minor bug fixes

V1.5.0

* Added in browse, search, and curated vehicle spawning
* Added entity position slider sensitivity slider

V1.6.0

* Add recents menu for both spawner menus
* (1.6.1) Fix error when spawning curated
* (1.6.1) Fix prop browse list being empty
* (1.6.4) Fix prop spawn error

V1.7.0

* Add 'Spawn Vehicles -> Clone Current Vehicle'

V1.8.0

* Add built in XML converter
* Fixed objects in old formats (or converted) being invisible
* Minor fixes and improvements

V1.9.0

* Add free edit (View Entities -> Free Edit option for info)
* Fix inconsistencies with entity offset menu
* Some other fixes
* (1.9.3) Add warning when vehicle does not save
* (1.9.3) Whoops: Fixed saving custom vehicles
* (1.9.5) Sorry this took a while: Fix saved vehicle spawn failure
* (1.9.5) Removed teleport into vehicle option for individual vehicle
* (1.9.5) Add 'Spawn In Vehicle' for spawner
* (1.9.6) Fix possible delete error
* (1.9.7) Updated translations lib
* (1.9.8) Possible fix for rare vehicle saving failure
* (1.9.10) Fix bug
* (1.9.11) Fix bug with vehicle lib

V1.10.0

* Attached vehicles now default to godmode
* Add option to disable godmode for attached vehicles
* Fix preview not being removed on spawn
* Make Free Edit disabled by default
* (1.10.1) Update jackzvehiclelib
* (1.10.2) Updated translations

V1.11.0

* Added basic backend support for peds ('peds' json array)