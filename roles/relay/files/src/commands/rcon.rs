use crate::{config::Config, error::RelayBotError, state};

use sourcon::client::Client;

use serenity::all::{Color, CreateEmbed, ResolvedOption, ResolvedValue, User};
use serenity::builder::{CreateCommand, CreateCommandOption};
use serenity::model::application::CommandOptionType;

pub fn register() -> CreateCommand {
    CreateCommand::new("rcon")
        .description("Run a command on a server")
        .add_option(
            CreateCommandOption::new(CommandOptionType::String, "server", "Internal name for the server")
            .required(true)
        )
        .add_option(
            CreateCommandOption::new(CommandOptionType::String, "command", "Command to run")
            .required(true)
        )
}

pub async fn run(
    config: &Config,
    invoking_user: &User,
    options: &[ResolvedOption<'_>]
) -> Result<CreateEmbed, RelayBotError> {
    // handle perms
    if !config.rcon_users_ids().contains(&invoking_user.id.into()) {
        return Err(RelayBotError::UserNoAccess());
    }

    // get args
    let Some(ResolvedOption {
        value: ResolvedValue::String(server), ..
    }) = options.get(0) else {
        return Err(RelayBotError::MissingParameter("server".to_string()));
    };
    let Some(ResolvedOption {
        value: ResolvedValue::String(command), ..
    }) = options.get(1) else {
        return Err(RelayBotError::MissingParameter("command".to_string()));
    };

    // verify server exists
    let Some(host) = state::get(server).await else {
        return Err(RelayBotError::ServerNonExist(server.to_string()));
    };

    // issue command
    println!("@{} invoking command on {}: {}", invoking_user.name, server, command);
    let mut client = Client::connect(&host.ip, &host.rcon_pass).await?;
    let response = client.command(command).await?;
    let response = match response.body().len() {
        0 => "*Command has no response.*",
        _ => response.body()
    };

    Ok(CreateEmbed::new()
        .description(response)
        .color(Color::BLURPLE))
}