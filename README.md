# dead-split
 Livesplit if it was bad (and cross platform).  
 Built using [godot 4.4](https://godotengine.org/), the [godot-rust bindings](https://godot-rust.github.io/), and [livesplit-core](https://crates.io/crates/livesplit-core) because I have completely lost it.  
 Features:
 - Basically all the normal stuff livesplit does
 - Working global hotkeys (on my system anyway, check if the [global-hotkeys crate](https://crates.io/crates/global-hotkey) works on your system)
 - Importing .lss files from livesplit
 - Customizable layout using godot's theming and StyleBox systems (WIP by which I mean literally does not exist)
 - Full autosplitter support (WIP by which I mean literally does not exist)
 
**WIP: NO RELEASE BUILDS YET**  
*this project is primarily for my own use and has been only tested on my system (fedora cinnamon spin). it probably doesn't work on other platforms, but hey, you can try building it and see what happens.*

## Usage
 The app will open as a borderless window similar to livesplit. Clicking and dragging will move the window.
 Right-clicking on the window will open a settings popup which you can use to edit the timer and hotkeys used to control it.

## Building
 1. Install cargo, godot 4.4 (whatever the latest beta is, this will be kept up to date), and install any needed export templates in the godot editor.
 2. Run `cargo build` and `cargo build --release` in the dead_split_rs folder, then move the generated library files into somewhere inside the dead_split_gd folder and update dead_split_rs.gdextension appropriately.
 3. Finally, export the project in the godot editor as usual.
