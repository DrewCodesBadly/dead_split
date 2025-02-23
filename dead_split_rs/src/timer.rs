use std::{
    fs::{self, File},
    io::BufWriter,
    path::Path,
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

mod autosplitters;

// impl block for basic livesplit-core interface exposed to godot
#[godot_api]
impl DeadSplitTimer {
    // Timer control
    #[func]
    fn new_run(&mut self) {
        let _ = self.timer.replace_run(get_default_run(), true);
    }

    #[func]
    fn start_split(&mut self) {
        self.timer.split_or_start();
    }

    #[func]
    fn reset(&mut self) {
        let current_split_index = self.timer.current_split_index().unwrap_or_default();
        self.timer.reset(true);
        let mut run = self.timer.run().clone();
        run.update_segment_history(current_split_index);
        run.fix_splits();
        let _ = self.timer.replace_run(run, true); // WHY WOULD YOU MAKE THIS A RESULT ISTG
    }

    #[func]
    fn pause(&mut self) {
        self.timer.pause();
    }

    #[func]
    fn resume(&mut self) {
        self.timer.resume();
    }

    #[func]
    fn toggle_pause(&mut self) {
        self.timer.toggle_pause();
    }

    #[func]
    fn undo_all_pauses(&mut self) {
        self.timer.undo_all_pauses();
    }

    #[func]
    fn skip_split(&mut self) {
        self.timer.skip_split();
    }

    #[func]
    fn undo_split(&mut self) {
        self.timer.undo_split();
    }

    #[func]
    fn toggle_timing_method(&mut self) {
        self.timer.toggle_timing_method();
    }

    #[func]
    fn try_save_run(&self, file_path: String) -> bool {
        let writer = match File::create(file_path) {
            Ok(f) => BufWriter::new(f),
            Err(_) => return false,
        };

        match livesplit::save_run(self.timer.run(), IoWrite(writer)) {
            Ok(_) => true,
            Err(_) => false,
        }
    }

    #[func]
    fn try_load_run(&mut self, file_path: String) -> bool {
        let path = Path::new(&file_path);
        let file = match fs::read(path) {
            Ok(f) => f,
            Err(_) => return false,
        };

        let _ = self.timer.replace_run(
            match composite::parse(&file, Some(path)) {
                Ok(p) => p.run,
                Err(_) => return false,
            },
            true,
        );
        true
    }

    #[func]
    fn init_game_time(&mut self) {
        self.timer.initialize_game_time();
    }

    #[func]
    fn regenerate_comparisons(&mut self) {
        let mut new_run = self.timer.run().clone();
        new_run.regenerate_comparisons();
        let _ = self.timer.set_run(new_run);
    }

    // Get timer data
    #[func]
    fn get_segment_count(&self) -> i32 {
        self.timer.run().len() as i32
    }

    #[func]
    fn get_segment_name(&self, idx: i32) -> String {
        self.timer.run().segment(idx as usize).name().to_owned()
    }

    #[func]
    fn get_segment_comparison(&self, idx: i32, comparing_to: String, rta: bool) -> f64 {
        let comp = self
            .timer
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
        let split_time = self.timer.run().segment(idx as usize).split_time();
        if rta {
            split_time.real_time.unwrap_or_default().total_seconds()
        } else {
            split_time.game_time.unwrap_or_default().total_seconds()
        }
    }

    #[func]
    fn get_pb_segment_time(&self, idx: i32, rta: bool) -> f64 {
        let split_time = self
            .timer
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
        let best_time = self.timer.run().segment(idx as usize).best_segment_time();
        if rta {
            best_time.real_time.unwrap_or_default().total_seconds()
        } else {
            best_time.game_time.unwrap_or_default().total_seconds()
        }
    }

    #[func]
    fn get_total_playtime(&self) -> f64 {
        self.timer.run().total_playtime().total_seconds()
    }

    #[func]
    fn get_game_name(&self) -> String {
        self.timer.run().game_name().to_owned()
    }

    #[func]
    fn get_category_name(&self) -> String {
        self.timer.run().category_name().to_owned()
    }

    #[func]
    fn get_attempt_count(&self) -> i32 {
        self.timer.run().attempt_count() as i32
    }

    #[func]
    fn get_finished_run_count(&self) -> i32 {
        let mut count: i32 = 0;
        for attempt in self.timer.run().attempt_history() {
            if let Some(_) = attempt.time().real_time {
                count += 1;
            }
        }
        count
    }

    // run interfacing
    #[func]
    fn update_run(&mut self, editable_run: Gd<EditableRun>) {
        let _ = self.timer.replace_run(editable_run.bind().get_run(), true);
    }

    #[func]
    fn get_editable_run(&self) -> Gd<EditableRun> {
        EditableRun::from_run(self.timer.run())
    }

    #[func]
    fn get_comparisons(&self) -> Array<GString> {
        Array::from_iter(self.timer.run().comparisons().map(|s| GString::from(s)))
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

    #[signal]
    pub fn hotkey_pressed(&mut self, hotkey_id: i32) {}
}
