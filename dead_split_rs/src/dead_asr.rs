use std::{
    fs,
    path::PathBuf,
    sync::{Arc, RwLockReadGuard, RwLockWriteGuard},
    thread::{self},
    time::{Duration, Instant},
};

use godot::builtin::{Dictionary, Variant};
use livesplit_auto_splitting::{
    settings::{Map, Value},
    AutoSplitter, Config, CreationError, Runtime, TimerState,
};
use livesplit_core::{SharedTimer, TimeSpan, TimerPhase};

pub struct DeadASR {
    timer: SharedTimer,
    runtime: Runtime,
    autosplitter: Arc<Option<AutoSplitter<TimerWrapper>>>, // ohhh my god this type is awful why rust
    path: Option<PathBuf>,
}

fn start(optional_autosplitter: Arc<Option<AutoSplitter<TimerWrapper>>>) {
    if let Some(a) = &*optional_autosplitter {
        let mut tick = Instant::now();
        let tick_rate = Duration::from_secs_f64(1.0 / 120.0);
        loop {
            match a.lock().update() {
                Ok(_) => {
                    tick += tick_rate;
                    let now = Instant::now();
                    if let Some(t) = tick.checked_duration_since(now) {
                        thread::sleep(t);
                    } else {
                        tick = now;
                    }
                }
                Err(_) => break,
            }
        }
    }
}

impl DeadASR {
    pub fn new(t: SharedTimer) -> Self {
        Self {
            timer: t,
            runtime: Runtime::new(Config::default()).expect("failed to create autosplit runtime"),
            autosplitter: Arc::from(None),
            path: None,
        }
    }

    pub fn set_autosplitter_path(&mut self, path: PathBuf) {
        self.path = Some(path);
    }

    pub fn load_autosplitter(&mut self, settings: Option<Map>) -> Result<(), CreationError> {
        if let Some(p) = &self.path {
            let module = self.runtime.compile(
                fs::read(p)
                    .map_err(|e| CreationError::ModuleLoading { source: e.into() })?
                    .as_slice(),
            )?;
            self.autosplitter = Arc::from(Some(module.instantiate(
                TimerWrapper(self.timer.clone()),
                settings,
                None,
            )?));

            thread::Builder::new()
                .name("Autosplitter Thread".into())
                .spawn({
                    let auto = self.autosplitter.clone();
                    move || start(auto)
                })
                .unwrap();

            return Ok(());
        }
        Err(CreationError::MissingMemory) // not accurate but this was easiest to return and you won't see these anyway
    }

    pub fn unload_autosplitter(&mut self) {
        if let Some(a) = &*self.autosplitter {
            a.interrupt_handle().interrupt();
            self.autosplitter = Arc::from(None);
        }
    }

    pub fn get_settings_dict(&self) -> Dictionary {
        let mut dict = Dictionary::new();

        if let Some(a) = &*self.autosplitter {
            // why is it set up as widgets just put the kv pairs in the bag bro
            for (k, v) in a.settings_map().iter() {
                match v {
                    Value::Bool(b) => dict.set(k, *b),

                    // Other value types are currently unsupported
                    _ => {}
                }
            }
        }

        dict
    }

    // To avoid having to update settings every tick we just recompile the autosplitter so it calls the entry point again.
    // This is a hacky workaround but the library doesn't easily expose a way to call a function to update settings.
    pub fn set_settings(&mut self, dict: Dictionary) -> Result<(), CreationError> {
        if self.path.is_some() {
            let mut new_settings = Map::new();
            for (k, v) in dict.iter_shared() {
                new_settings.insert(Arc::from(k.to::<String>()), Value::Bool(v.booleanize()));
            }

            return self.load_autosplitter(Some(new_settings));
        }
        Err(CreationError::MissingMemory) // not accurate but this was easiest to return and you won't see these anyway
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

    fn skip_split(&mut self) {
        let _ = self.write().skip_split();
    }

    fn undo_split(&mut self) {
        let _ = self.write().undo_split();
    }

    fn log_auto_splitter(&mut self, message: std::fmt::Arguments<'_>) {
        godot::global::print(&[Variant::from(message.as_str().unwrap_or(""))]);
    }

    fn log_runtime(
        &mut self,
        message: std::fmt::Arguments<'_>,
        _log_level: livesplit_auto_splitting::LogLevel,
    ) {
        godot::global::print(&[Variant::from(message.as_str().unwrap_or(""))]);
    }
}
