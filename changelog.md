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
* (3.9.15) Add command names to cloud and saved lists

v3.10.0

* Add "Drive On Water" feature
* Add sorted cloud list
* Added cloud rating system
* (3.10.4) Updated translations lib to 1.4.0

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
* (1.10.9) Fix cloud bug

v1.11.0

* Added translations support
* Added chinese (traditional) translation (Thanks Zero)

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
* (1.2.27) Updated translations lib to 1.4.0

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

V1.25.0

* Switched to new format 2 for jackz_animator (breaks old recordings)

V1.26.0

* Improved default names for some entities
* (Manual only) Automatically restart script on update

# jackz animator (v1)

V1.1.0

* Made positions relative for builder
* Fixed recording not ending
* Fixed recording list not clearing previous entries
* Changed filename format for new recordings