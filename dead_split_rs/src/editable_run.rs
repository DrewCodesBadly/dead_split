use std::str::FromStr;

use godot::prelude::*;
use livesplit_core::{Run, Segment, TimeSpan};

// Godot class wrapper for a run so it can be edited through godot code, then put back into the timer.
#[derive(GodotClass)]
#[class(no_init)]
pub struct EditableRun {
    run: Run,
}

// NOT godot api functions, used within rust to interact with the object
impl EditableRun {
    pub fn from_run(run: &Run) -> Gd<Self> {
        Gd::from_object(Self { run: run.clone() })
    }

    pub fn get_run(&self) -> Run {
        return self.run.clone();
    }
}

// Godot api functions to edit the run
#[godot_api]
impl EditableRun {
    #[func]
    fn add_segment(&mut self, name: String) {
        self.run.push_segment(Segment::new(name));
    }

    #[func]
    fn set_game_name(&mut self, name: String) {
        self.run.set_game_name(name);
    }

    #[func]
    fn get_game_name(&self) -> String {
        self.run.game_name().to_owned()
    }

    #[func]
    fn get_category_name(&self) -> String {
        self.run.category_name().to_owned()
    }

    #[func]
    fn set_category_name(&mut self, name: String) {
        self.run.set_category_name(name);
    }

    #[func]
    fn set_attempt_count(&mut self, c: i32) {
        self.run.set_attempt_count(c.try_into().unwrap_or_default());
    }

    #[func]
    fn get_attempt_count(&self) -> i32 {
        self.run.attempt_count() as i32
    }

    #[func]
    fn set_offset(&mut self, offset: f64) {
        self.run.set_offset(TimeSpan::from_seconds(offset));
    }

    #[func]
    fn get_offset(&self) -> f64 {
        self.run.offset().total_seconds()
    }

    #[func]
    fn generate_comparisons(&mut self) {
        self.run.regenerate_comparisons();
    }

    // no idea why you would want this
    #[func]
    fn clear_times(&mut self) {
        self.run.clear_times();
    }

    #[func]
    fn get_auto_splitter_settings(&self) {
        self.run.auto_splitter_settings();
    }

    #[func]
    fn set_auto_splitter_settings(&mut self, settings: String) {
        *self.run.auto_splitter_settings_mut() = settings
    }

    #[func]
    fn get_custom_comparisons(&self) -> Array<GString> {
        Array::from_iter(
            self.run
                .custom_comparisons()
                .iter()
                .map(|s| GString::from_str(s).expect("literally how does this fail")),
        )
    }

    #[func]
    fn get_comparisons(&self) -> Array<GString> {
        Array::from_iter(
            self.run
                .comparisons()
                .map(|s| GString::from_str(s).expect("literally how does this fail")),
        )
    }

    #[func]
    fn add_custom_comparison(&mut self, comp: String) {
        self.run.custom_comparisons_mut().push(comp);
    }

    #[func]
    fn remove_custom_comparison(&mut self, idx: i32) {
        self.run.custom_comparisons_mut().remove(idx as usize);
    }

    #[func]
    fn fix_split(&mut self) {
        self.run.fix_splits(); // literally what does this do????
    }

    // Segments
    #[func]
    fn get_segment_count(&self) -> i32 {
        self.run.len() as i32
    }

    #[func]
    fn get_segment_name(&self, idx: i32) -> String {
        self.run.segment(idx as usize).name().to_owned()
    }

    #[func]
    fn set_segment_name(&mut self, idx: i32, name: String) {
        self.run.segment_mut(idx as usize).set_name(name);
    }

    #[func]
    fn get_segment_comparison(&self, idx: i32, comparing_to: String, rta: bool) -> f64 {
        let comp = self.run.segment(idx as usize).comparison(&comparing_to);
        if rta {
            comp.real_time.unwrap_or_default().total_seconds()
        } else {
            comp.game_time.unwrap_or_default().total_seconds()
        }
    }

    #[func]
    fn set_segment_comparison(&mut self, idx: i32, comparing_to: String, rta: bool, time: f64) {
        let comp = self
            .run
            .segment_mut(idx as usize)
            .comparison_mut(&comparing_to);
        if rta {
            comp.real_time = Some(TimeSpan::from_seconds(time));
        } else {
            comp.game_time = Some(TimeSpan::from_seconds(time));
        }
    }

    #[func]
    fn get_segment_best(&self, idx: i32, rta: bool) -> f64 {
        let best_time = self.run.segment(idx as usize).best_segment_time();
        if rta {
            best_time.real_time.unwrap_or_default().total_seconds()
        } else {
            best_time.game_time.unwrap_or_default().total_seconds()
        }
    }

    #[func]
    fn set_segment_best(&mut self, idx: i32, rta: bool, time: f64) {
        let best = self.run.segment_mut(idx as usize).best_segment_time_mut();
        if rta {
            best.real_time = Some(TimeSpan::from_seconds(time));
        } else {
            best.game_time = Some(TimeSpan::from_seconds(time));
        }
    }

    #[func]
    fn remove_segment(&mut self, idx: i32) {
        self.run.segments_mut().remove(idx as usize);
    }

    #[func]
    fn move_up_segment(&mut self, idx: i32) {
        let segments = self.run.segments_mut();
        let idx_u = idx as usize;
        if idx_u > 0 {
            segments.swap(idx_u, idx_u - 1);
        }
    }

    #[func]
    fn move_down_segment(&mut self, idx: i32) {
        let segments = self.run.segments_mut();
        let idx_u = idx as usize;
        if idx_u < segments.len() - 1 {
            segments.swap(idx_u, idx_u + 1);
        }
    }
}
