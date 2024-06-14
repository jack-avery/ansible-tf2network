use std::env;

use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    /// A list of user IDs with access to the `rcon` slash command.
    rcon_users_ids: Vec<u64>
}

impl Config {
    pub fn rcon_users_ids(&self) -> Vec<u64> {
        self.rcon_users_ids.clone()
    }
}

pub fn load() -> Config {
    println!("loading config");

    let rcon_users_raw: String = env::var("RCON_USERS").expect("RCON_USERS not set?");
    let rcon_users_ids: Vec<u64> = rcon_users_raw.split(':')
        .map(|s| s.parse().expect("could not parse RCON_USERS envvar"))
        .collect();

    Config {
        rcon_users_ids
    }
}