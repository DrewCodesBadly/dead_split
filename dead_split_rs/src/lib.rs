use std::collections::HashMap;

use global_hotkey::{hotkey::HotKey, GlobalHotKeyEvent, GlobalHotKeyManager, HotKeyState};
use godot::prelude::*;
use livesplit_core::{Run, Segment, Timer};

mod editable_run;
mod timer;

struct DeadSplitRust;

#[gdextension]
unsafe impl ExtensionLibrary for DeadSplitRust {}

#[derive(GodotClass)]
#[class(base = Node)]
pub struct DeadSplitTimer {
    timer: Timer,
    #[var]
    pub current_time: f64,
    #[var]
    pub current_game_time: f64,
    #[var]
    pub current_split_index: i32,
    #[var]
    pub timer_phase: u8,
    hotkey_mgr: GlobalHotKeyManager,
    hotkey_binds: HashMap<u32, i32>,
    hotkeys: HashMap<i32, HotKey>,

    base: Base<Node>,
}

#[godot_api]
impl INode for DeadSplitTimer {
    fn init(base: godot::obj::Base<Self::Base>) -> Self {
        Self {
            timer: Timer::new(get_default_run()).expect("default run has 1 segment"),
            current_time: 0.0,
            current_game_time: 0.0,
            current_split_index: -1,
            timer_phase: 0,
            hotkey_mgr: GlobalHotKeyManager::new().expect("couldn't create hotkey manager"),
            hotkey_binds: HashMap::new(),
            hotkeys: HashMap::new(),
            base,
        }
    }

    fn process(&mut self, _delta: f64) {
        // Updates displayed properties from a snapshot every frame
        let snapshot = self.timer.snapshot();
        let t = snapshot.current_time();
        self.current_time = t.real_time.unwrap_or_default().total_seconds();
        self.current_game_time = t.game_time.unwrap_or_default().total_seconds();
        self.current_split_index = match snapshot.current_split_index() {
            Some(i) => i as i32,
            None => -1,
        };
        self.timer_phase = snapshot.current_phase() as u8;

        // Check for hotkey presses
        if let Ok(e) = GlobalHotKeyEvent::receiver().try_recv() {
            if e.state() == HotKeyState::Pressed {
                if let Some(c) = self.hotkey_binds.get(&e.id()).to_owned() {
                    let idx = *c;
                    self.base_mut()
                        .clone()
                        .upcast::<Object>()
                        .emit_signal("hotkey_pressed", &[Variant::from(idx)]);
                    // self.hotkey_pressed(idx);
                }
            }
        }
    }
}

fn get_default_run() -> Run {
    let mut run = Run::new();
    run.push_segment(Segment::new("Time"));
    run.set_game_name("Game");
    run.set_category_name("Any%");
    run
}
