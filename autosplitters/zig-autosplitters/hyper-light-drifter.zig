// For some reason (on proton hotfix 2017 hld) when you quit to menu/reload the autosplitter detaches from the process
// But it seems like it instantly reattaches so at worst you lose 1 tick?
// Doesn't seem consequential. No idea why it's like this.
// However, this doesn't happen with proton 9.0-4 so just use that

// USE 2017 PATCH AND PROTON 9.0-4

// Pointer paths used in HLD's asl autosplitter
// state("HyperLightDrifter", "7/21/2017") {
// 	/* optimal steam patch */
// 	uint room : 0x255B1F10;
// 	double isLoading : 0x255A7E24, 0x0, 0x0, 0x10, 0x0, 0xC, 0x28, 0x370;
// 	uint moduleCount : 0x255B2648, 0xA5C, 0x18, 0x24;
// 	uint gameState : 0x255A7E0C, 0xAC, 0xC, 0xC;
// 	uint hordeEnd : 0x255B2648, 0xA60, 0x18, 0x24;
// 	uint isPaused : 0x255AF150, 0x0, 0x144, 0x3C, 0xD8;
// }
// When running with proton, it appears there is a set offset from the original pointer on windows
// Not exactly surprising, was kind of hoping this would happen
// This is 0x00400000 in my case. idk how it works across devices

// This could be handled using the runtime_get_os method in autosplit-util, but that's a pain

// Extra comments thrown in since this is the first autosplitter I've written
// You can use this as an example (hopefully)

// This script contains useful structs and the external functions declared in Rust
const AutosplitUtil = @import("util/autosplit-util.zig");
const std = @import("std");

// This is a struct containing all the compared values so we can compare current values with old values

// This struct contains the settings.
const Settings = struct {
    ng_start: bool,
    alt_end: bool,
    horde_finish: bool,
    horde_start: bool,
    room_transitions: bool,
    intro: bool,
    mre: bool,
    modules: bool,
    warps: bool,
};

var settings = Settings{
    .ng_start = true,
    .alt_end = false,
    .horde_finish = false,
    .horde_start = false,
    .room_transitions = true,
    .intro = true,
    .mre = false,
    .modules = true,
    .warps = false,
};

// This is the entry point. You should register some settings here.
// You could also do any other initial startup things, like making decision based on platform/arch.
// Then read back out of the settings map which will contain user changes.
// The autosplitter is reloaded when settings are changed so this function will be called again.
export fn _start() void {
    // Setting a process name will make AutosplitUtil's update function
    // automatically find the process and call process_update for you.
    AutosplitUtil.process_name = "HyperLightDrifter.exe";

    // Make sure to set the pointer to process_update so that way AutosplitUtil knows what to call
    AutosplitUtil.process_update_fn = &process_update;

    // This registers name - boolean setting pairs.
    AutosplitUtil.register_settings(
        &[_][]const u8{ "ng_start", "alt_end", "horde_finish", "horde_start", "room_transitions", "intro", "mre", "modules", "warps" },
        &[_]bool{ true, false, false, false, true, true, false, true, true },
    );

    // Sadly to get everything into a struct you have to read each value manually. Improve later?
    settings.ng_start = AutosplitUtil.read_setting("ng_start");
    settings.alt_end = AutosplitUtil.read_setting("alt_end");
    settings.horde_finish = AutosplitUtil.read_setting("horde_finish");
    settings.horde_start = AutosplitUtil.read_setting("horde_start");
    settings.room_transitions = AutosplitUtil.read_setting("room_transitions");
    settings.intro = AutosplitUtil.read_setting("intro");
    settings.mre = AutosplitUtil.read_setting("mre");
    settings.modules = AutosplitUtil.read_setting("modules");
    settings.warps = AutosplitUtil.read_setting("warps");
}

// Here we declare lists of offsets - these are the pointer paths to useful values
const room_ptr = AutosplitUtil.Address{ .n = 0x259B1F10 };
const is_loading_ptr = [_]u32{ 0x259A7E24, 0x0, 0x0, 0x10, 0x0, 0xC, 0x28, 0x370 };
const module_toggle_ptr = [_]u32{ 0x259B2648, 0xA5C, 0x18, 0x24 };
const game_state_ptr = [_]u32{ 0x259A7E0C, 0xAC, 0xC, 0xC };
const horde_end_ptr = [_]u32{ 0x259B2648, 0xA60, 0x18, 0x24 };
const is_paused_ptr = [_]u32{ 0x259AF150, 0x0, 0x144, 0x3C, 0xD8 };

// These are structs containing game state information (The values at each pointer path)
// Old is the state from last tick, current is the current tick
const State = struct {
    room: u32,
    is_loading: f64,
    module_toggle: u32,
    game_state: u32,
    horde_end: u32,
    is_paused: u32,
};
var current = State{
    .room = 0,
    .is_loading = 0.0,
    .module_toggle = 0,
    .game_state = 0,
    .horde_end = 0,
    .is_paused = 0,
};
var last = State{
    .room = 0,
    .is_loading = 0.0,
    .module_toggle = 0,
    .game_state = 0,
    .horde_end = 0,
    .is_paused = 0,
};

// Declare any extra variables here
var mre_triggered = false;

// This function is repeatedly called as long as there is a process attached
pub fn process_update(process: AutosplitUtil.Process) void {

    // Update the last state
    last = current;

    // Get new values at all pointers
    current.room = process.read(u32, room_ptr) orelse current.room;
    current.is_loading = process.read_path(f64, u32, &is_loading_ptr) orelse current.is_loading;
    current.module_toggle = process.read_path(u32, u32, &module_toggle_ptr) orelse current.module_toggle;
    current.game_state = process.read_path(u32, u32, &game_state_ptr) orelse current.game_state;
    current.horde_end = process.read_path(u32, u32, &horde_end_ptr) orelse current.horde_end;
    current.is_paused = process.read_path(u32, u32, &is_paused_ptr) orelse current.is_paused;

    // Autosplitter code goes here
    AutosplitUtil.timer_resume_game_time();

    // Load removal
    if (current.is_loading == 1.0) {
        AutosplitUtil.timer_pause_game_time();
    } else if (current.is_loading != last.is_loading) {
        AutosplitUtil.timer_resume_game_time();
    }

    // NG start
    if (settings.ng_start and last.game_state == 0 and current.game_state == 5) {
        AutosplitUtil.timer_start();
        mre_triggered = false;
    }

    // Horde start
    if (settings.horde_start and current.room >= 73 and current.room <= 77 and last.room != current.room) {
        AutosplitUtil.timer_start();
        mre_triggered = false;
    }

    // Horde end
    if (settings.horde_finish and last.horde_end == 0 and current.horde_end == 1 and current.is_paused == 0 and current.room >= 73 and current.room <= 77) {
        AutosplitUtil.timer_split();
    }

    // Modules
    if (settings.modules and last.module_toggle != current.module_toggle and current.module_toggle == 1) {
        AutosplitUtil.timer_split();
    }

    // All room transition related splits
    if (last.room != current.room) {
        if (settings.room_transitions) {
            AutosplitUtil.timer_split();
        }

        // Warps
        else if (settings.warps) {
            // Town
            if (current.room == 61 and (last.room < 60 or last.room > 80)) {
                AutosplitUtil.timer_split();
            }
            // East
            else if (current.room == 175 and (last.room < 172 or last.room > 200)) {
                AutosplitUtil.timer_split();
            }
            // West
            else if (current.room == 219 and (last.room < 218 or last.room > 253)) {
                AutosplitUtil.timer_split();
            }
            // North
            else if (current.room == 94 and (last.room < 172 or last.room > 200)) {
                AutosplitUtil.timer_split();
            }
            // South
            else if (current.room == 130 and last.room < 128 or last.room > 165) {
                AutosplitUtil.timer_split();
            }
        }

        // Alt end
        else if (settings.alt_end and current.room == 8 and last.room == 262) {
            AutosplitUtil.timer_split();
        }

        // MRE
        else if (settings.mre and !mre_triggered and current.room == 53) {
            AutosplitUtil.timer_split();
            mre_triggered = true;
        }

        // Intro
        else if (settings.intro and current.room == 51 and last.room == 50) {
            AutosplitUtil.timer_split();
        }
    }
}
