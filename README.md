# ADND Collision Viewer

This is the source for the collision viewer N3rdsWithGame hacked together for the [OOT64 All Dungeons No Doors TAS](https://www.youtube.com/watch?v=vtWr7wiS-Hw) ([collision viewer segments](https://www.youtube.com/watch?v=PNXj_QmwNDc)). Tested on Bizhawk 1.13.x with Jabo and GlideN64 video plugins, but **in theory** it should *just work*™ with later versions.

These 3 lua files have been floating around in people's DM's for better part of 2 and a half years, but at the request of RoseWater N3rdsWithGame has made them publicly available.

Big thanks to N3rdsWithGame for releasing these files, making this continuation work possible.

## Intent

The intent behind these scripts were to make a collision viewer that would be use able for a TAS settings. As such this was designed to have minimal impact on the emulation as possible, only write to RAM what was needed in the form of a display list, and generate it all in LUA instead of C/MIPS to preserve the CPU cyclecount and not fiddle with calls to srand (which periodically use the cpu cycle count as part of the seed).

Every bk2 movie tried would sync wrt the script running or not, however it cannot be guaranteed that running the script will not result in a desync.

## How to use
* Download the repo (git clone or click the green "clone or download" button and download it as a zip), or just download the 3 lua files. 
* Make sure they are all in the same folder.
* In bizhawk, go to Tools->Lua Console
* open `collision.lua`

## Contributing

If you are interested in contributing, here are some features that would be beneficial to this project:

* Support other versions of Ocarina of Time (mostly done)
* Support Majora's Mask as a game
* Port to pj64d using the javascript scripting API
