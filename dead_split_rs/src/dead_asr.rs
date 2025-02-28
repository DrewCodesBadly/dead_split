use std::{
    fs,
    path::PathBuf,
    sync::{RwLockReadGuard, RwLockWriteGuard},
};

use godot::builtin::{Dictionary, Variant, VariantType};
use livesplit_auto_splitting::{SettingValue, SettingsStore, TimerState};
use livesplit_core::{SharedTimer, TimeSpan, TimerPhase};

type OptionalRuntime = Option<livesplit_auto_splitting::Runtime<TimerWrapper>>;

pub struct DeadASR {
    timer: SharedTimer,
    autosplitter: Option<PathBuf>,
    runtime: OptionalRuntime,
}

fn new_runtime(
    t: TimerWrapper,
    path: PathBuf,
    settings: SettingsStore,
) -> Result<livesplit_auto_splitting::Runtime<TimerWrapper>, ()> {
    let file = fs::read(path).map_err(|_| ())?;
    Ok(livesplit_auto_splitting::Runtime::new(file.as_slice(), t, settings).map_err(|_| ())?)
}

impl DeadASR {
    pub fn new(t: SharedTimer) -> Self {
        Self {
            timer: t,
            autosplitter: None,
            runtime: None,
        }
    }

    pub fn load_autosplitter(&mut self, path: PathBuf) -> Result<(), ()> {
        self.runtime = Some(new_runtime(
            TimerWrapper(self.timer.clone()),
            path,
            SettingsStore::new(),
        )?);
        Ok(())
    }

    // Kills the autosplitter and removes the runtime
    pub fn unload(&mut self) {
        if let Some(r) = &self.runtime {
            r.interrupt_handle().interrupt();
            self.runtime = None
        }
    }

    pub fn get_settings_dict(&self) -> Dictionary {
        let mut dict = Dictionary::new();

        if let Some(r) = &self.runtime {
            // Add ALL settings, not just modified ones
            for setting in r.user_settings() {
                dict.set(
                    setting.key.as_ref(),
                    match setting.default_value {
                        SettingValue::Bool(b) => b,

                        // Should be unreachable unless more type support is added
                        _ => false,
                    },
                );
            }

            // Apply any changes
            for (k, v) in r.settings_store().iter() {
                dict.set(
                    k,
                    match v {
                        SettingValue::Bool(b) => *b,

                        _ => false,
                    },
                );
            }
        }

        dict // returns empty dict if no runtime
    }

    pub fn set_settings(&mut self, settings: Dictionary) -> Result<(), ()> {
        // For some reason it seems the whole runtime needs to be reconstructed for this
        if let Some(p) = &self.autosplitter {
            let mut settings_store = SettingsStore::new();

            // Add dict settings to map
            for (k, v) in settings.iter_shared() {
                if let Ok(s) = k.try_to::<String>() {
                    settings_store.set(
                        s.into(),
                        match v.get_type() {
                            VariantType::BOOL => SettingValue::Bool(v.to()),

                            // No support for other data types so this should never happen
                            // But in case it does we still get bool values
                            _ => SettingValue::Bool(v.booleanize()),
                        },
                    );
                }
            }

            self.runtime = Some(new_runtime(
                TimerWrapper(self.timer.clone()),
                p.clone(),
                settings_store,
            )?);

            return Ok(());
        }

        Err(())
    }
}

struct TimerWrapper(SharedTimer);

// I can't implement Timer on SharedTimer so I need a wrapper struct
impl TimerWrapper {
    pub fn read(&self) -> RwLockReadGuard<livesplit_core::Timer> {
        self.0.read().unwrap()
    }

    pub fn write(&mut self) -> RwLockWriteGuard<livesplit_core::Timer> {
        self.0.write().unwrap()
    }
}

impl livesplit_auto_splitting::Timer for TimerWrapper {
    fn state(&self) -> TimerState {
        match self.read().current_phase() {
            TimerPhase::Ended => TimerState::Ended,
            TimerPhase::NotRunning => TimerState::NotRunning,
            TimerPhase::Paused => TimerState::Paused,
            TimerPhase::Running => TimerState::Running,
        }
    }

    fn start(&mut self) {
        let _ = self.write().start();
    }

    fn split(&mut self) {
        let _ = self.write().split();
    }

    fn reset(&mut self) {
        let _ = self.write().reset(true);
    }

    fn set_game_time(&mut self, time: livesplit_auto_splitting::time::Duration) {
        let _ = self
            .write()
            .set_game_time(TimeSpan::from_seconds(time.as_seconds_f64()));
    }

    fn pause_game_time(&mut self) {
        let _ = self.write().pause_game_time();
    }

    fn resume_game_time(&mut self) {
        let _ = self.write().resume_game_time();
    }

    fn set_variable(&mut self, key: &str, value: &str) {
        let _ = self.write().set_custom_variable(key, value);
    }

    fn log(&mut self, message: std::fmt::Arguments<'_>) {
        godot::global::print(&[Variant::from(message.as_str().unwrap_or(""))]);
    }
}
