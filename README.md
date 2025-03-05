# dead-split
 Livesplit if it was bad (and cross platform).  
 Built using [godot 4.4](https://godotengine.org/), the [godot-rust bindings](https://godot-rust.github.io/), and [livesplit-core](https://crates.io/crates/livesplit-core) because I have completely lost it.  
 Features:
 - Basically all the normal stuff livesplit does
 - Working global hotkeys (on my system anyway, check if the [global-hotkeys crate](https://crates.io/crates/global-hotkey) works on your system)
 - Importing .lss files from livesplit
 - Subsplits, working the same as in livesplit
 - Customizable layout using godot's resource system - see Themes for more info (You can even write a shader for your timer background!!!!!)
 - Full autosplitter support using GDScript
 
**WIP: NO RELEASE BUILDS YET**  
*this project is primarily for my own use and has been only tested on my system (fedora cinnamon spin). it probably doesn't work on other platforms, but hey, you can try it and see what happens.*

## Usage
 The app will open as a borderless window similar to livesplit. Clicking and dragging will move the window.  
 Right-clicking on the window will open a settings popup which you can use to edit the timer and hotkeys used to control it.

## Autosplitters
Autosplitters are written in Godot's GDScript, and the script file can be loaded in the settings menu either using quick load or in the autosplitters menu. Float, integer, and boolean autosplitter settings are supported and can be edited in the autosplitters menu. Some autosplitters are provided directly with the timer and can be loaded from the quick load menu, but you can also specify other GDScript files to load and run.  
For information about building autosplitters, see "Writing Autosplitters" at the bottom of this file.  
Autosplitters for the following games are shipped with the application by default:
- Hyper Light Drifter

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

## Writing Autosplitters
Autosplitters are written as GDScript files, and should extend the class "Autosplitter". You can write these however you want but it may be easier in the Godot editor or in a clone of this repository. The default autosplitters in the project can be found in res://Autosplitters. The Hyper Light Drifter autosplitter is thoroughly commented and should be a good example.  
The Autosplitter class has a ``process_name`` property which you must set. Then, the autosplitter will automatically attempt to attach to any process containing that name. There is also a ``settings`` variable which is a dictionary that should contain mappings of Strings to any Variant type. However, only float, int, and bool will actually show up in the settings editor.
The Autosplitter class has 3 methods you are expected to override.
1. ``setup() -> void`` This method is called when the autosplitter is loaded. This is intended to be used to set the ``process_name`` and ``settings`` variables but you could also do anything else.
2. ``read_settings() -> void`` This method is called after the timer loads any changes to the settings the user made. You might not need this method, but it can be useful if you want to do something with the settings on startup or to store settings somewhere else to avoid checking from the settings dictionary multiple times every tick.
3. ``process_update() -> void`` **This is where the autosplitter logic runs.** This method is called 120 times per second, but only if the timer has attached to a valid process.  
Autosplitter contains an enum for different data types that can be read from memory. These are:
- TYPE_I32 - 32-bit integer
- TYPE_I64 - 64-bit integer
- TYPE_U32 - unsigned 32-bit integer
- TYPE_U64 - unsigned 64-bit integer
- TYPE_F32 - 32-bit floating point number
- TYPE_F64 - 64-bit floating point number
The Autosplitter class provides the following methods:
- ``start_split() -> void`` - Starts or splits the timer.
- ``skip_split() -> void`` - Skips the next split.
- ``undo_split() -> void`` - Undoes the last split.
- ``reset() -> void`` - Resets the timer.
- ``pause_game_time() -> void`` - Pauses game time. This does not count as the timer itself being paused, just game time.
- ``resume_game_time() -> void`` - Resumes game time.
- ``func read_pointer_path(offsets: PackedInt64Array, pointer_size_32: bool, data_type: int)`` - Attempts to read memory from the currently attached process at the pointer path specific in ``offsets``. ``pointer_size_32`` specifies whether 32 or 64 bit pointers should be used. ``data_type`` is expected to be from the type enum, and specifies what type of data to read and return. Returns null if the path couldn't be read, otherwise returns a data type corresponding to the ``data_type`` parameter.
Additionally, the PointerPath class is provided for use in autosplitters. This should be constructed with ``PointerPath.new(p_path: Array[int], last_val, p_type: int, pointer_size_32: bool)``. ``p_path`` should be the pointer path as a list of offsets, and ``last_val`` should be any default value of the same data type that the pointer should read, specified by the ``data_type`` parameter. This works similarly to ``read_pointer_path`` in Autosplitter. Once constructed, the PointerPath be updated using the ``update() -> void`` method every tick, which will attempt to read data from memory. If it succeeds, the ``current`` property will be set to the data that was read, and the ``last`` property will be set to the previous contents of ``current``. Otherwise, no change will be made. This allows you to compare the value from the last tick with that of the current tick easily using something like ``path.last == 0 && path.current == 1``, and guarantees that there will never be a null value so comparisons can be made safely.
