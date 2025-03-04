use std::{
    fs::{self, File},
    io::BufWriter,
    path::{Path, PathBuf},
    str::FromStr,
};

use crate::editable_run::EditableRun;
use godot::prelude::*;
use livesplit_core::{
    analysis::total_playtime::TotalPlaytime,
    run::{
        parser::composite,
        saver::livesplit::{self, IoWrite},
    },
};

use super::*;

// impl block for basic livesplit-core interface exposed to godot
#[godot_api]
impl DeadSplitTimer {
    // Timer control
    #[func]
    fn new_run(&self) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.replace_run(get_default_run(), true);
    }

    #[func]
    fn start_split(&self) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.split_or_start();
    }

    #[func]
    fn reset(&self) {
        let mut binding = timer_write(&self.timer);
        let current_split_index = binding.current_split_index().unwrap_or_default();
        let _ = binding.reset(true);
        let mut run = binding.run().clone();
        run.update_segment_history(current_split_index);
        run.fix_splits();
        let _ = binding.replace_run(run, true); // WHY WOULD YOU MAKE THIS A RESULT ISTG
    }

    #[func]
    fn pause(&self) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.pause();
    }

    #[func]
    fn resume(&self) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.resume();
    }

    #[func]
    fn toggle_pause(&self) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.toggle_pause();
    }

    #[func]
    fn undo_all_pauses(&self) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.undo_all_pauses();
    }

    #[func]
    fn skip_split(&self) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.skip_split();
    }

    #[func]
    fn undo_split(&self) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.undo_split();
    }

    #[func]
    fn toggle_timing_method(&self) {
        let mut binding = timer_write(&self.timer);
        binding.toggle_timing_method();
    }

    #[func]
    fn try_save_run(&self, file_path: String) -> bool {
        let binding = timer_read(&self.timer);
        let writer = match File::create(file_path) {
            Ok(f) => BufWriter::new(f),
            Err(_) => return false,
        };

        match livesplit::save_run(binding.run(), IoWrite(writer)) {
            Ok(_) => true,
            Err(_) => false,
        }
    }

    #[func]
    fn try_load_run(&self, file_path: String) -> bool {
        let mut binding = timer_write(&self.timer);
        let path = Path::new(&file_path);
        let file = match fs::read(path) {
            Ok(f) => f,
            Err(_) => return false,
        };

        let _ = binding.replace_run(
            match composite::parse(&file, Some(path)) {
                Ok(p) => p.run,
                Err(_) => return false,
            },
            true,
        );
        true
    }

    #[func]
    fn init_game_time(&self) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.initialize_game_time();
    }

    #[func]
    fn regenerate_comparisons(&self) {
        let mut binding = timer_write(&self.timer);
        let mut new_run = binding.run().clone();
        new_run.regenerate_comparisons();
        let _ = binding.set_run(new_run);
    }

    // Get timer data
    #[func]
    fn get_segment_count(&self) -> i32 {
        let binding = timer_read(&self.timer);
        binding.run().len() as i32
    }

    #[func]
    fn get_segment_name(&self, idx: i32) -> String {
        let binding = timer_read(&self.timer);
        binding.run().segment(idx as usize).name().to_owned()
    }

    #[func]
    fn get_segment_comparison(&self, idx: i32, comparing_to: String, rta: bool) -> f64 {
        let binding = timer_read(&self.timer);
        let comp = binding
            .run()
            .segment(idx as usize)
            .comparison(&comparing_to);
        if rta {
            comp.real_time.unwrap_or_default().total_seconds()
        } else {
            comp.game_time.unwrap_or_default().total_seconds()
        }
    }

    #[func]
    fn get_segment_time(&self, idx: i32, rta: bool) -> f64 {
        let binding = timer_read(&self.timer);
        let split_time = binding.run().segment(idx as usize).split_time();
        if rta {
            split_time.real_time.unwrap_or_default().total_seconds()
        } else {
            split_time.game_time.unwrap_or_default().total_seconds()
        }
    }

    #[func]
    fn get_pb_segment_time(&self, idx: i32, rta: bool) -> f64 {
        let binding = timer_read(&self.timer);
        let split_time = binding
            .run()
            .segment(idx as usize)
            .personal_best_split_time();
        if rta {
            split_time.real_time.unwrap_or_default().total_seconds()
        } else {
            split_time.game_time.unwrap_or_default().total_seconds()
        }
    }

    #[func]
    fn get_segment_best(&self, idx: i32, rta: bool) -> f64 {
        let binding = timer_read(&self.timer);
        let best_time = binding.run().segment(idx as usize).best_segment_time();
        if rta {
            best_time.real_time.unwrap_or_default().total_seconds()
        } else {
            best_time.game_time.unwrap_or_default().total_seconds()
        }
    }

    #[func]
    fn get_total_playtime(&self) -> f64 {
        let binding = timer_read(&self.timer);
        binding.run().total_playtime().total_seconds()
    }

    #[func]
    fn get_game_name(&self) -> String {
        let binding = timer_read(&self.timer);
        binding.run().game_name().to_owned()
    }

    #[func]
    fn get_category_name(&self) -> String {
        let binding = timer_read(&self.timer);
        binding.run().category_name().to_owned()
    }

    #[func]
    fn get_attempt_count(&self) -> i32 {
        let binding = timer_read(&self.timer);
        binding.run().attempt_count() as i32
    }

    #[func]
    fn get_finished_run_count(&self) -> i32 {
        let binding = timer_read(&self.timer);
        let mut count: i32 = 0;
        for attempt in binding.run().attempt_history() {
            if let Some(_) = attempt.time().real_time {
                count += 1;
            }
        }
        count
    }

    // run interfacing
    #[func]
    fn update_run(&mut self, editable_run: Gd<EditableRun>) {
        let mut binding = timer_write(&self.timer);
        let _ = binding.replace_run(editable_run.bind().get_run(), true);
    }

    #[func]
    fn get_editable_run(&self) -> Gd<EditableRun> {
        let binding = timer_read(&self.timer);
        EditableRun::from_run(binding.run())
    }

    #[func]
    fn get_comparisons(&self) -> Array<GString> {
        let binding = timer_read(&self.timer);
        Array::from_iter(binding.run().comparisons().map(|s| GString::from(s)))
    }

    // hotkeys
    #[func]
    fn add_hotkey(&mut self, key_string: String, hotkey_id: i32) -> bool {
        let key = match HotKey::from_str(&key_string) {
            Ok(k) => k,
            Err(_) => return false,
        };
        if self.hotkey_mgr.register(key).is_err() {
            false;
        }
        self.hotkey_binds.insert(key.id(), hotkey_id);
        self.hotkeys.insert(hotkey_id, key);

        true
    }

    #[func]
    fn remove_hotkey(&mut self, hotkey_id: i32) -> bool {
        let key = match self.hotkeys.get(&hotkey_id) {
            Some(k) => k,
            None => return false,
        };
        if self.hotkey_mgr.unregister(*key).is_err() {
            return false;
        }
        self.hotkey_binds.remove_entry(&key.id);

        true
    }

    #[func]
    fn get_hotkey_string(&self, hotkey_id: i32) -> String {
        self.hotkeys
            .get(&hotkey_id)
            .map(|h| h.into_string())
            .unwrap_or(String::from("None"))
    }

    #[func]
    fn get_hotkeys_dict(&self) -> Dictionary {
        let mut dict = Dictionary::new();

        for (k, v) in &self.hotkeys {
            dict.set(*k, v.into_string());
        }

        dict
    }

    #[signal]
    pub fn hotkey_pressed(&mut self, hotkey_id: i32) {}

    // Interact with autosplitter runtime
    #[func]
    pub fn load_autosplitter(&mut self, script_path: String) -> bool {
        let path = match PathBuf::from_str(&script_path) {
            Ok(p) => p,
            Err(_) => return false,
        };
        self.runtime.set_autosplitter_path(path);
        match self.runtime.load_autosplitter(None) {
            Ok(_) => true,
            Err(_) => false,
        }
    }

    #[func]
    pub fn unload_autosplitter(&mut self) {
        self.runtime.unload_autosplitter(); // not worried about this result
    }

    #[func]
    pub fn get_auto_splitter_settings(&self) -> Dictionary {
        self.runtime.get_settings_dict()
    }

    #[func]
    pub fn set_auto_splitter_settings(&mut self, settings: Dictionary) {
        let _ = self.runtime.set_settings(settings);
    }
}
