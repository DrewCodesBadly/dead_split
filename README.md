# dead-split
 Livesplit if it was bad (and cross platform).  
 Built using [godot 4.4](https://godotengine.org/), the [godot-rust bindings](https://godot-rust.github.io/), and [livesplit-core](https://crates.io/crates/livesplit-core) because I have completely lost it.  
 Features:
 - Basically all the normal stuff livesplit does
 - Working global hotkeys (on my system anyway, check if the [global-hotkeys crate](https://crates.io/crates/global-hotkey) works on your system)
 - Importing .lss files from livesplit
 - Subsplits, working the same as in livesplit (WIP)
 - Customizable layout using godot's resource system - see Themes for more info (You can even write a shader for your timer background!!!!!)
 - Full autosplitter support (WIP by which I mean literally does not exist)
 
**WIP: NO RELEASE BUILDS YET**  
*this project is primarily for my own use and has been only tested on my system (fedora cinnamon spin). it probably doesn't work on other platforms, but hey, you can try building it and see what happens.*

## Usage
 The app will open as a borderless window similar to livesplit. Clicking and dragging will move the window.
 Right-clicking on the window will open a settings popup which you can use to edit the timer and hotkeys used to control it.

## Themes
 Themes can be loaded in settings by selecting a .zip file to open. Creating themes requires a bit more effort (maybe at some point a settings ui could be added for this).  
 To create a theme:
 1. Download at least the dead_split_gd folder from this repository, you probably want to clone the whole thing and build the rust code as well so you can test out the timer in the editor, though.
 2. Install the godot editor v4.4 beta4
 3. Open the project inside dead_split_gd
 4. Edit the resources located inside the DefaultTheming folder to your liking
 5. You can ruin the main scene to test out the timer. Once you're finished, open theme_dumper.tscn (in the ThemeDumper folder)
 6. Run the scene and select a location to save the .zip file in, and a .zip containing the new theme will be placed there. It can be loaded as normal from there.

## Building
 1. Install cargo, godot 4.4 (whatever the latest beta is, this will be kept up to date), and install any needed export templates in the godot editor.
 2. Run `cargo build` and `cargo build --release` in the dead_split_rs folder, then move the generated library files into somewhere inside the dead_split_gd folder and update dead_split_rs.gdextension appropriately.
 3. Finally, export the project in the godot editor as usual.
