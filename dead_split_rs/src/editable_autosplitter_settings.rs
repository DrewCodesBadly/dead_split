use godot::prelude::*;
use livesplit_core::{auto_splitting::settings::Map, auto_splitting::settings::Value};

// Very similar to EditableRun
// Godot class wrapper for a settings map so it can be edited through godot code, then put back into the runtime.
#[derive(GodotClass)]
#[class(no_init)]
pub struct EditableAutosplitterSettings {
    settings_map: Map,
}

// NOT godot api functions, used within rust to interact with the object
impl EditableAutosplitterSettings {
    pub fn from_map(map: &Map) -> Gd<Self> {
        Gd::from_object(Self {
            settings_map: map.clone(),
        })
    }

    pub fn get_map(&self) -> &Map {
        return &self.settings_map;
    }
}

#[godot_api]
impl EditableAutosplitterSettings {
    #[func]
    pub fn get_settings(&self) -> Dictionary {
        let mut dict = Dictionary::new();

        for (k, v) in self.settings_map.iter() {
            match v {
                Value::Bool(b) => dict.set(k, *b),
                Value::I64(i) => dict.set(k, *i),
                Value::F64(f) => dict.set(k, *f),

                // unsupported
                _ => {}
            }
        }

        dict
    }

    #[func]
    pub fn set_settings_from_dict(&mut self, dict: Dictionary) {
        for (k, v) in dict.iter_shared() {
            if k.get_type() == VariantType::STRING {
                match v.get_type() {
                    VariantType::BOOL => self
                        .settings_map
                        .insert(k.to::<String>().into(), Value::Bool(v.to())),
                    VariantType::INT => self
                        .settings_map
                        .insert(k.to::<String>().into(), Value::I64(v.to())),
                    VariantType::FLOAT => self
                        .settings_map
                        .insert(k.to::<String>().into(), Value::F64(v.to())),

                    _ => {} // unsupported
                }
            }
        }
    }
}
