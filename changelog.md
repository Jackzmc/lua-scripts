# jackz vehicles (v3)
  
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

v3.8.0

* Fix nearby vehicle list not updating live
* Sort nearby vehicle list by distance to player
* Add a refresh interval for vehicle list

v3.9.0

* Allow turning off refresh interval for nearby vehicles
* Supposedly fix jackzvehiclelib improperly doing extras
* (3.9.1) Updated jackzvehiclelib
* (3.9.2) Fix extras (Thanks hexarobi)
* (3.9.3) Actually fix extras
* (3.9.5) Fix vehicle colors being wrong, save wheel types, fix livery spawning
* (3.9.6) Auto migrate older vehicles
* (3.9.7) Fix meta error typo
* (3.9.8) jackzvehiclelib: Fix bug with license plates
* (3.9.9) Update natives
* (3.9.10) Renamed commands to reduce conflicts
* (3.9.12) Fix version issues
* (3.9.14) Fix detach cargobob

# actions (v1)

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

v1.10.0

* Added "Special Animations" with support of some curated animations that include props
* Changed Action Targets to a list
* Move a lot of data (scenarios, etc) to separate file
* (1.10.3) Don't kick players out of vehicle on stop
* (1.10.4) Fix some special actions erroring
* (1.10.6) Fix cloud favorites > browse failing
* (1.10.7) Allow moving during special animations
* (1.10.8) Auto download animations.txt

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
* (1.2.21) Fix some deprecated and weird time based bugs
* (1.2.22) Actually fix it (fixes messages not clearing)
* (1.2.23) Fix preprocessor bug

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

V1.17.0

* Allowed changing to a dev release channel
* Added backend support for ped animations
* Added blip icons to vehicles with ability to change (base vehicle -> settings -> blip icon)
* Fix some bugs with invalid exceptions
* Fix 'Remove All Entities' clearing base vehicle
* Added Clone > Mirror for every axis
* General bug fixes and improvements
* Added some info boxes for builder entities
* Added info boxes for cloud / saved vehicles
* Added ability to favorite peds, objects, vehicles
* Updated to latest jackzvehiclelib
* (1.17.1) Fix extras (Thanks hexarobi)
* (1.17.1) Change some blip icons
* (1.17.3) Add warning to delete all
* (1.17.3) Fix cloning issues
* (1.17.4) Fix some bugs
* (1.17.4) Actually fix extrasa
* (1.17.5) Fix highlightedHandle not being reset on new base
* (1.17.6) Autocreate save directory if not exist
* (1.17.7) Fix some previews being inside base vehicle

V1.18.0

* Add ability to change attachment position of entities
* Add ability to attach entities to other entities
* Add vehicle name to pre-existing add overlay
* Use hard entity pinning
* Add setting to disable 'add to vehicle' overlay
* Minor fixes / improvements, especially to descriptions
* Add warning to deleting an entity
* Automatically make a copy of last autosave on save failure
* Allow having peds and objects to be a build's base entity
* Allow offline browsing of vehicles (use local resource file)
* Fix even more inconsisenties with vehicle saving
* (1.18.1) Fix save_recents error with null vehicle name
* (1.18.2) Fix errors when entity disappears, and setting a new base
* (1.18.3) Fix meta error typo
* (1.18.4) Fix Attach to: Missing base vehicle
* (1.18.4) Only show overlays when builder menus are open

V1.19.0

* Auto smart distance for build previews and spawning
* Added a "Create New Structure" menu
* Cleaned up ui slightly

V1.20.0

* Allow adding other builds to your build
* UI Improvements
* Bug fixes
* Fix non-vehicle bases not spawning

V1.21.0

* Allow to set a build's spawn location (Builder > Build > Spawn Location)
* Add some checks to increase stability
* Ensure nested builds entities don't collide with other build entities
* Fix builds not spawning objects
* Added option to turn off an entity's collision
* Fix non-base entities not being transparent
* jackzvehiclelib: Allow turning on siren sounds separate from lights (Thanks hexarobi)
* Bug fixes and improvements hopefully
* Updated natives to latest version`
* (1.21.2) Add Script Meta > Upload logs for support purposes
* (1.21.2) Add Settings > Debug Mode for support purposes
* (1.21.2) jackzvehiclelib: Fix bug with license plates
* (1.21.2) Fix cloud overlays erroring
* (1.21.3) Fix overlay on builds erroring


V1.22.0

* Added "Create Manual Base" to spawn a manual model name
* Update updaters, internal changes
* (1.22.1) Fixed visibility not being networked (Ty hexarobi)
* (1.22.1) Fixed collision not turning off (Ty hexarobi)
* (1.22.2) Add check for corrupted favorites.json file

V1.23.0

* Added spawning particle effects to a build
* Add an 'Open Folder' option in saved builds
* Fix some bugs
* Add shortcut to clear build on main menu
* Minor cleanup on some descriptions
* Add command to spawn builds
* (1.23.1) Fix error on older builds