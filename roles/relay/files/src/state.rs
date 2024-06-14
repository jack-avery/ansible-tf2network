use std::collections::HashMap;
use std::env;
use std::time::Duration;

use rsourcequery::info::{query, ServerInfo};

use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::Mutex;

use crate::manifest::Manifest;

#[derive(Debug, Clone)]
pub struct HostInfo {
    /// Server IP address and Port
    pub ip: String,
    /// Server RCon password
    pub rcon_pass: String,
    /// Server hostname
    pub hostname: String,
    /// The map the server is on
    pub map: String,
    /// Active player count
    pub players: u8,
    /// Server capacity
    pub maxplayers: u8,
}

impl HostInfo {
    pub fn new(ip: &str, rcon_pass: &str, hostname: &str) -> Self {
        HostInfo {
            ip: ip.to_owned(),
            rcon_pass: rcon_pass.to_owned(),
            hostname: hostname.to_owned(),
            map: "".to_owned(),
            players: 0,
            maxplayers: 24,
        }
    }
}

lazy_static! {
    // cached host info
    static ref HOST_INFO: Arc<Mutex<HashMap<String, HostInfo>>> = Arc::new(Mutex::new(HashMap::new()));
}

pub async fn init(manifest: &Manifest) {
    // parse STATE_REFRESH_RATE envvar
    let refresh_rate: u64 = env::var("STATE_REFRESH_RATE")
        .unwrap_or(5.to_string())
        .parse()
        .expect("could not parse STATE_REFRESH_RATE");
    let refresh_rate: Duration = Duration::from_secs(refresh_rate);

    // populate hashmap
    let mut server_info = HOST_INFO.lock().await;
    for host in manifest.hosts.iter() {
        server_info.insert(
            host.internal_name.clone(),
            HostInfo::new(&host.ip, &host.rcon_pass, &host.hostname)
        );
    }
    std::mem::drop(server_info); // manually unlock

    tokio::task::spawn(async move {
        loop {
            let mut new_server_info: HashMap<String, HostInfo> = HOST_INFO.lock().await.clone();
            let old_server_info: HashMap<String, HostInfo> = HOST_INFO.lock().await.clone();

            for (name, host) in old_server_info {
                match query_host(&host).await {
                    Ok(new_info) => {
                        new_server_info.insert(name, new_info);
                    },
                    Err(why) => eprintln!("failed to refresh {}: {why:?}", name),
                }
            }

            let mut server_info = HOST_INFO.lock().await;
            *server_info = new_server_info;
            std::mem::drop(server_info); // manually unlock

            tokio::time::sleep(refresh_rate).await;
        }
    });
}

async fn query_host<'a>(
    host: &HostInfo,
) -> Result<HostInfo, Box<dyn std::error::Error + 'a>> {
    let info: ServerInfo = query(&host.ip).await?;

    Ok(HostInfo {
        ip: host.ip.to_owned(),
        rcon_pass: host.rcon_pass.to_owned(),
        hostname: info.hostname,
        map: info.map,
        players: info.players,
        maxplayers: info.maxplayers,
    })
}

/// Get a clone of the current state as `HashMap<String, HostInfo>`
pub async fn get_all() -> HashMap<String, HostInfo> {
    HOST_INFO.lock().await.clone()
}

/// Get the corresponding [`HostInfo`] for the internal name `host`.
pub async fn get(host: &str) -> Option<HostInfo> {
    let info = HOST_INFO.lock().await.clone();

    info.get(host).cloned()
}