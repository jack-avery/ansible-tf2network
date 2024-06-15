mod commands;
mod config;
mod error;
mod manifest;
mod state;

use std::{env, collections::HashMap};

use config::Config;
use error::RelayBotError;
use manifest::{Manifest, ServerConfig};

use lazy_static::lazy_static;
use regex::Regex;
use serenity::all::{
    async_trait, ChannelId, Color, Command, CreateEmbed, CreateInteractionResponse, CreateInteractionResponseMessage, Interaction, Message, Ready
};
use serenity::prelude::*;
use sourcon::client::Client as RconClient;

lazy_static! {
    static ref CONFIG: Config = config::load();
    static ref MANIFEST: Manifest = manifest::load();
    static ref RELAY_CHANNELS: HashMap<ChannelId, ServerConfig> = manifest::channel_key_value(&MANIFEST);

    static ref RE_DISCORD_MENTION: Regex = Regex::new(r"<@d\+>").expect("failed to compile RE_DISCORD_MENTION");
    static ref RE_DISCORD_CHANNEL: Regex = Regex::new(r"<#\d+>").expect("failed to compile RE_DISCORD_CHANNEL");
    static ref RE_DISCORD_EMOTE: Regex = Regex::new(r"(<a?(:[a-zA-Z0-9_]+:)\d+>)").expect("failed to compile RE_DISCORD_EMOTE");
}

struct Handler;

#[async_trait]
impl EventHandler for Handler {
    async fn interaction_create(&self, context: Context, interaction: Interaction) {
        if let Interaction::Command(command) = interaction {
            let content: Result<CreateEmbed, RelayBotError> = match command.data.name.as_str() {
                "servers" => commands::servers::run().await,
                "rcon" => commands::rcon::run(&CONFIG, &command.user, &command.data.options()).await,
                _ => unreachable!()
            };
            
            let response: CreateEmbed = match content {
                Ok(r) => r,
                Err(err) => {
                    CreateEmbed::new()
                        .description(err.to_string())
                        .color(Color::RED)
                }
            };

            let data: CreateInteractionResponseMessage = CreateInteractionResponseMessage::new().embed(response);
            let builder: CreateInteractionResponse = CreateInteractionResponse::Message(data);
            if let Err(why) = command.create_response(&context.http, builder).await {
                println!("Cannot respond to slash command: {why}");
            }
        }
    }

    async fn ready(&self, context: Context, ready: Ready) {
        println!("logged in as {}", ready.user.name);

        if let Err(why) = Command::create_global_command(&context.http, commands::rcon::register()).await {
            eprintln!("failed to register rcon command: {why:?}");
        };
        if let Err(why) = Command::create_global_command(&context.http, commands::servers::register()).await {
            eprintln!("failed to register servers command: {why:?}");
        };
    }

    async fn message(&self, _: Context, message: Message) {
        if message.author.bot { return };
        let Some(server) = &RELAY_CHANNELS.get(&message.channel_id) else { return };

        let mut msg: String = message.clone().content;

        // format mentions & emotes
        for (re, u) in itertools::zip_eq(RE_DISCORD_MENTION.find_iter(&message.content), &message.mentions) {
            msg = msg.replace(re.as_str(), &u.name);
        }
        for (re, c) in itertools::zip_eq(RE_DISCORD_CHANNEL.find_iter(&message.content), &message.mention_channels) {
            msg = msg.replace(re.as_str(), format!("#{}", &c.name).as_str());
        }
        for (re, e) in itertools::zip_eq(RE_DISCORD_EMOTE.find_iter(&message.content), RE_DISCORD_EMOTE.captures(&message.content)) {
            msg = msg.replace(re.as_str(), format!(":{}:", &e[0]).as_str());
        }

        // add attachment note
        if !message.attachments.is_empty() {
            msg = format!("(attachment) {}", msg);
        }

        // sanitize out stuff that could otherwise be harmful
        msg = msg.replace('"', "\'")
            .replace('\\', "/")
            .replace(['\n', '\r', '\t', ';'], "");

        // conjoin the message
        msg = format!("{}: {}", message.author.name, msg);

        // tf2 message max length is 127
        // formatting and such leaves only 99 of which for the message
        // cull and ellipsis
        let message: String = if msg.len() > 99 {
            format!("{} [...]", &msg[0..=92])
        } else {
            msg
        };

        if let Err(why) = rcon(&server.ip, &server.rcon_pass, format!("discord_relay_say {}", message).as_str()).await {
            eprintln!("relay error: {why:?}")
        }
    }
}

async fn rcon(ip: &str, pass: &str, command: &str) -> Result<String, RelayBotError> {
    let mut client = RconClient::connect(ip, pass).await?;
    let response = client.command(command).await?;
    Ok(response.body().to_owned())
}

#[tokio::main]
async fn main() {
    state::init(&MANIFEST).await;

    let token: String = env::var("DISCORD_TOKEN").expect("DISCORD_TOKEN not set? cannot start!");
    let intents: GatewayIntents = GatewayIntents::MESSAGE_CONTENT
        | GatewayIntents::GUILD_MESSAGES;

    let mut client: Client =
        Client::builder(&token, intents).event_handler(Handler).await.expect("failed to create client");

    if let Err(why) = client.start().await {
        eprintln!("client error: {why:?}");
    }
}