use crate::{error::RelayBotError, state};

use serenity::{all::Color, builder::{CreateCommand, CreateEmbed}};

pub fn register() -> CreateCommand {
    CreateCommand::new("servers")
        .description("Get servers")
}

pub async fn run() -> Result<CreateEmbed, RelayBotError> {
    let servers = state::get_all().await;

    Ok(CreateEmbed::new()
        .description(
            servers.into_iter()
                .map(|(internal_name, info)| {
                    format!("### {}\n (`{}`, `{}`) \n{}/{} players on {}",
                        info.hostname,
                        internal_name,
                        info.ip,
                        info.players,
                        info.maxplayers,
                        info.map)
                })
                .collect::<Vec<String>>()
                .join("\n\n---\n"))
        .color(Color::BLURPLE))
}
