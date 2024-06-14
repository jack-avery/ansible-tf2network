use std::collections::HashMap;

use serde::Deserialize;
use serenity::all::ChannelId;

#[derive(Debug, Clone, Deserialize)]
pub struct ServerConfig {
    /// Server hostname
    pub hostname: String,
    /// Unique internal name for the server
    pub internal_name: String,
    /// Server IP and Port
    pub ip: String,
    /// Server RCon password
    pub rcon_pass: String,
    /// Discord relay channel for the bot
    pub relay_channel: Option<u64>,
    /// Whether the server is STV enabled
    pub stv_enabled: bool
}

#[derive(Debug, Clone, Deserialize)]
pub struct Manifest {
    pub hosts: Vec<ServerConfig>
}

pub fn load() -> Manifest {
    println!("loading manifest");

    let cfg_bytes = std::fs::read("manifest.yml")
        .expect("missing manifest.yml");
    let cfg_str = std::str::from_utf8(&cfg_bytes)
        .expect("failed to utf8decode config");

    serde_yaml::from_str(cfg_str).expect("failed to parse cfg")
}

pub fn channel_key_value(manifest: &Manifest) -> HashMap<ChannelId, ServerConfig> {
    println!("generating id-channel map");

    let mut map: HashMap<ChannelId, ServerConfig> = HashMap::new();
    for host in &manifest.hosts {
        if let Some(channel) = host.relay_channel {
            map.insert(ChannelId::new(channel), host.clone());
        }
    }

    dbg!(&map);
    map
}
