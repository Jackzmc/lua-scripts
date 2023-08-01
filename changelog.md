# jackz vehicles (v3)

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
* (3.10.1) Made chauffer ped not flee
* (3.10.2) Update to 'Upload Logs' to use new provider
* (3.10.3) Fix Cloud Vehicles > Browse By Users not working
* (3.10.4) Updated translations lib to 1.4.0
* (3.10.6) Updated translations lib to 1.4.2
* (3.10.7) Add discord link

# actions (v1)

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
* (1.10.13) Remove encoding issue from resource file
* (1.10.14) Make actions_data file optional
* (1.10.15) Fix playing animations erroring
* (1.10.16) Update error message to clarify
* (1.10.17) Fix variable scope issue
* (1.10.18) Fix add to favorites functionality missing
* (1.10.19) Update to 'Upload Logs' to use new provider

v1.11.0

* Added translations support
* Added chinese (traditional) translation (Thanks Zero)
* (1.11.1) Add log to translate lib
* (1.11.3) Fix translation issues (sorry about that, please report bugs to me!)
* (1.11.4) Updated chinese translation
* (1.11.5) Fix typo for cloud browse
* (1.11.6) Fix is_anim_in_recent bug
* (1.11.7) Add discord link
* (1.11.8) Fix error (thanks hexarobi)

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
* (1.2.24) Update to 'Upload Logs' to use new provider
* (1.2.27) Updated translations lib to 1.4.0
* (1.2.29) Updated translations lib to 1.4.2
* (1.2.30) Add discord link

V1.3.0

* Added channel subscriptions (get messages from multiple channels)
* Clarified wording on some menus, broken/missing translations
* Show active channel in Send Message
* Added "discord" channel that sends messages to new official discord
* (1.3.1) Fix SEND_ERR translation

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
* (1.1.8) Update to 'Upload Logs' to use new provider
* (1.1.9) Add discord link

# jackz vehicle builder (v1)

V1.24.0

* Internal change for vehicle search
* Add sorting option (type and direction) for cloud lists
* Organize builder entities by type
* Add cloning non-networked entities
* Add shortcuts to adding jackz_vehicles
* Add abiity to attach entities directly to the world
* Added ability to set animations on entities (see jackz_animator)
* Fix some bugs
* (1.24.1) Fix bug
* (1.24.2) Fix download process
* (1.24.3) Check for invalid builds on spawn
* (1.24.4) Changed cloud spawning logic
* (1.24.5) Fix wrong toast
* (1.24.6) Fix uncaught error
* (1.24.7) Fix more merge errors
* (1.24.8) Add missing particles search
* (1.24.9) Fix another error -_-
* (1.24.10) Fix another git issue (cloud sorts lists)
* (1.24.11) Fix search error
* (1.24.12) Fix cloud sorts > spawn not working

V1.25.0

* Switched to new format 2 for jackz_animator (breaks old recordings)
* (1.25.2) Load animator if builder is from repo
* (1.25.4) Fix cloning failing
* (1.25.5) Update to 'Upload Logs' to use new provider
* (1.25.6) Fix assigning base changing rotation of base entity
* (1.25.6) Stop using read_vector3 -> v3
* (1.25.7) Fix toasting non-errors
* (1.25.8) Fix 'Open Folder' permission error
* (1.25.9) Fix small error on toast
* (1.25.10) Add discord link
* (1.25.11) Use built in json
* (1.25.12) Fix saved builds not appearing (Sorry this took so long)
* (1.25.13) Fix Clone Entity error

V1.26.0

* Add Utilities > Delete Current Vehicle
* Minor wording improvements
* Add some more error checks
* Improved entity count accuracy

# jackz animator (v1)

V1.1.0

* Made positions relative for builder
* Fixed recording not ending
* Fixed recording list not clearing previous entries
* Changed filename format for new recordings
* (1.1.1) Update to 'Upload Logs' to use new provider
* (1.1.2) Add discord link
