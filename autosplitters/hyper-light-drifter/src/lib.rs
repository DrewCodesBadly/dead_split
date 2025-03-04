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

#![no_std]
extern crate alloc;

#[global_allocator]
static ALLOC: dlmalloc::GlobalDlmalloc = dlmalloc::GlobalDlmalloc;

use asr::{
    future::{next_tick, retry},
    settings::Gui,
    timer::{pause_game_time, resume_game_time, split, start},
    Error, Process,
};
use bytemuck::CheckedBitPattern;

asr::async_main!(stable);
asr::panic_handler!();

#[derive(Gui)]
struct Settings {
    #[default = true]
    ng_start: bool,

    #[default = true]
    alt_end: bool,

    #[default = false]
    horde_finish: bool,

    #[default = false]
    horde_start: bool,

    #[default = false]
    room_transitions: bool,

    #[default = true]
    intro: bool,

    #[default = false]
    mre: bool,

    #[default = true]
    modules: bool,

    #[default = true]
    warps: bool,
}

// DeepPointer isn't working and idk what I'm doing wrong
// So i'm writing my own solution
#[derive(Default)]
struct PointerPath<T: CheckedBitPattern> {
    path: &'static [u64],
    bits_32: bool,
    pub value: Option<T>,
}

impl<T: CheckedBitPattern> PointerPath<T> {
    // Returns a tuple of (old value, new value)
    pub fn update(&mut self, process: &Process) -> (Option<T>, Option<T>) {
        let output = (
            self.value,
            if self.bits_32 {
                self.read_32(process)
            } else {
                self.read_64(process)
            }
            .ok(),
        );
        self.value = output.1;
        output
    }

    fn read_32(&self, process: &Process) -> Result<T, Error> {
        let mut iter = self.path.iter();

        let mut val: u32 = *iter.next().unwrap() as u32;

        for offset in iter {
            val = process.read(val)?;
            val += *offset as u32;
        }

        let result_val: T = process.read(val)?;

        Ok(result_val)
    }

    fn read_64(&self, process: &Process) -> Result<T, Error> {
        let mut iter = self.path.iter();

        let mut val: u64 = *iter.next().unwrap();

        for offset in iter {
            val = process.read(val)?;
            val += offset;
        }

        let result_val: T = process.read(val)?;

        Ok(result_val)
    }
}

async fn main() {
    let mut settings = Settings::register();

    // Pointer paths to useful values, as taken from the HLD asl autosplitter
    let mut room_id_ptr = PointerPath::<u32> {
        path: &[0x259B1F10],
        bits_32: true,
        ..Default::default()
    };
    let mut is_loading_ptr = PointerPath::<f64> {
        path: &[0x259A7E24, 0x0, 0x0, 0x10, 0x0, 0xC, 0x28, 0x370],
        bits_32: true,
        ..Default::default()
    };
    let mut game_state_ptr = PointerPath::<u32> {
        path: &[0x259A7E0C, 0xAC, 0xC, 0xC],
        bits_32: true,
        ..Default::default()
    };
    let mut module_toggle_ptr = PointerPath::<u32> {
        path: &[0x259B2648, 0xA5C, 0x18, 0x24],
        bits_32: true,
        ..Default::default()
    };
    let mut horde_end_ptr = PointerPath::<u32> {
        path: &[0x259B2648, 0xA60, 0x18, 0x24],
        bits_32: true,
        ..Default::default()
    };
    let mut is_paused_ptr = PointerPath::<u32> {
        path: &[0x259AF150, 0x0, 0x144, 0x3C, 0xD8],
        bits_32: true,
        ..Default::default()
    };

    let mut mre_triggered = false;

    loop {
        let process = retry(|| {
            ["wine-preloader", "HyperLightDrifter.exe"]
                .into_iter()
                .find_map(Process::attach)
        })
        .await;
        process
            .until_closes(async {
                loop {
                    settings.update(); // do we really need to call this every tick? settings shouldn't change mid-run

                    let game_state = game_state_ptr.update(&process);
                    let is_loading = is_loading_ptr.update(&process);
                    let room_id = room_id_ptr.update(&process);
                    let module_toggle = module_toggle_ptr.update(&process);
                    let horde_end = horde_end_ptr.update(&process);
                    let is_paused = is_paused_ptr.update(&process);

                    // Load removal
                    if is_loading.1 == Some(1.0) {
                        pause_game_time();
                    } else {
                        resume_game_time();
                    }

                    // NG Start
                    if settings.ng_start && game_state.0 == Some(0) && game_state.1 == Some(5) {
                        start();
                        mre_triggered = false // moderately jank
                    }

                    // Horde mode start
                    if settings.horde_start
                        && room_id.1 >= Some(73)
                        && room_id.0 <= Some(77)
                        && room_id.0 != room_id.1
                    {
                        start();
                        mre_triggered = false
                    }

                    // Horde mode end
                    if settings.horde_finish
                        && horde_end.1 == Some(1)
                        && horde_end.0 == Some(0)
                        && is_paused.1 == Some(0)
                        && room_id.1 >= Some(73)
                        && room_id.1 <= Some(77)
                    {
                        split();
                    }

                    // Modules
                    if settings.modules
                        && module_toggle.0 != module_toggle.1 // assume no error nonsense
                        && module_toggle.1 == Some(1)
                    {
                        split();
                    }

                    // Any splits on room transitions
                    if let (Some(old), Some(new)) = room_id {
                        // && operator causes a very wacky rust error here.
                        if old != new {
                            if settings.room_transitions {
                                split();
                            }

                            // Warps
                            if settings.warps {
                                // Town
                                if room_id.1 == Some(61)
                                    && (room_id.0 < Some(60) || room_id.0 > Some(80))
                                {
                                    split();
                                }
                                // East
                                else if room_id.1 == Some(175)
                                    && (room_id.0 < Some(172) || room_id.0 > Some(200))
                                {
                                    split();
                                }
                                // North
                                else if room_id.1 == Some(94)
                                    && (room_id.0 < Some(93) || room_id.0 > Some(124))
                                {
                                    split();
                                }
                                // West
                                else if room_id.1 == Some(219)
                                    && (room_id.0 < Some(218) || room_id.0 > Some(253))
                                {
                                    split();
                                }
                                // South
                                else if room_id.1 == Some(130)
                                    && (room_id.0 < Some(128) || room_id.0 > Some(165))
                                {
                                    split();
                                }
                            }

                            // Alt end
                            if settings.alt_end && room_id.1 == Some(8) && room_id.0 == Some(262) {
                                split();
                            }

                            // MRE
                            if settings.mre && !mre_triggered && room_id.1 == Some(53) {
                                split();
                                mre_triggered = true;
                            }

                            // Intro
                            if settings.intro && room_id.1 == Some(51) && room_id.0 == Some(50) {
                                split();
                            }
                        }
                    }

                    next_tick().await;
                }
            })
            .await;
    }
}
