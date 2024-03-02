# Lua scripts

This is the source code for my lua scripts.

**NOTE: These scripts are __not intended to be run as is__, but be served & processed via my website.** 
What you see here is the dev versions I run that do not have autoupdates and are not intended for end users. You will not get help using the raw source.
The base scripts (non pre-processed) do not include auto-updates, version changelogs, the Script Meta menu, or automatic downloading of missing files.

Feel free to submit issues or pull requests or ask about them on the guilded. 

Use https://jackz.me/stand/get-lua.php?script=SCRIPT_NAME_HEREsource=manual&branch=master to download the preprocessed file. Extenstion is optional. 
Use 'source=repo' to have a version that does not have any automatic updating logic.

Exmaple: https://jackz.me/stand/get-lua.php?script=jackz_vehicle_builder&source=manual&branch=master

### get-lua.php Parameters

* `script=` Script name, supports relative paths like `lib/` and `resources/`
* `source=` The source (REPO, MANUAL, DEV) that dictactes what preprocessor comments run
* `branch=` The git branch to pull from, default is `release`
* `template_branch=` The branch to pull templates from, default is &branch

### Preprocessor
The preprocessor is shit. It does not work well with else statements and commonly breaks down

Directive is `--#P:DEBUG_ONLY` and then `--#P:END` replacing DEBUG_ with MANUAL_ or REPO_.

Recommend to just use `SCRIPT_SOURCE` which is filled with the capitalized source parameter from above



## Branches

release - The public version that all end users download from

master - The main branch where development and breaking changes occur
