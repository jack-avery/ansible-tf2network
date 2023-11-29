# ansible-tf2network discord->server relay bot
# this is pretty haphazardly thrown together, rewrite eventually

import asyncio
import discord
import logging
import re
import sys
import yaml

from rcon.source import Client

DISCORD_MENTION_RE = re.compile(r"<@\d+>")
DISCORD_CHANNEL_RE = re.compile(r"<#\d+>")
DISCORD_EMOTE_RE = re.compile(r"(<a?(:[a-zA-Z0-9_]+:)\d+>)")

SERVER_PLAYERS_RE = re.compile(r"players : (\d+) humans, (\d+) bots \((\d+)")

with open("config.yml", "r") as f:
    CONFIG: dict = yaml.safe_load(f.read())
cfg = lambda k: CONFIG.get(k, None)

log_handlers = []
formatter = logging.Formatter(
    "%(asctime)s | %(module)s [%(levelname)s] %(message)s",
)
stdout_handler = logging.StreamHandler(sys.stdout)
stdout_handler.setLevel(logging.DEBUG)
stdout_handler.setFormatter(formatter)
log_handlers.append(stdout_handler)
logging.basicConfig(handlers=log_handlers, level=logging.DEBUG)


def rcon(cmd: str) -> str:
    try:
        with Client(cfg("rcon_addr"), cfg("port"), passwd=cfg("rcon_pass")) as client:
            response = client.run(cmd)
        return response
    except:
        return None


class DiscordBot(discord.Client):
    def __init__(self):
        # I don't know which to use, so we just do this.
        discord.Client.__init__(self, intents=discord.Intents().all())
        self.tree = discord.app_commands.CommandTree(self)
        self.SETUP = False

    async def on_ready(self) -> None:
        if not self.SETUP:
            # find relay channel
            if cfg("relay_channel"):
                self.RELAY_CHANNEL = self.get_channel(cfg("relay_channel"))

            # begin polling status
            if cfg("status_channel"):
                self.STATUS_CHANNEL = self.get_channel(cfg("status_channel"))
                asyncio.ensure_future(self.poll_status())

            # get guild from channel; add commands
            self.tree.copy_global_to(
                guild=discord.Object(id=self.RELAY_CHANNEL.guild.id)
            )
            await self.tree.sync()

            logging.info("Ready!")
            self.SETUP = True

    async def poll_status(self, frequency: int = 30) -> None:
        while True:
            await self.update_status_channel()
            await asyncio.sleep(frequency)

    async def update_status_channel(self) -> None:
        """
        Poll server player info.
        """
        status = rcon("status")

        info = SERVER_PLAYERS_RE.findall(status)[0]
        count_players = int(info[0])
        count_bots = int(info[1])
        maxplayers = int(info[2])

        if count_bots > 0:
            maxplayers -= count_bots

        server_str = f'({count_players}/{maxplayers}) {cfg("hostname")}'
        if len(server_str) > 100:  # voice channel max name length is 100 characters
            server_str = server_str[:99]

        await self.STATUS_CHANNEL.edit(name=server_str)

    async def on_message(self, message: discord.Message) -> None:
        if message.author == self.user or message.author.bot:
            return

        if not cfg("relay_channel"):
            return

        if not message.channel.id == cfg("relay_channel"):
            return

        msg = message.content

        # replace mentions with raw text
        if DISCORD_MENTION_RE.search(msg):
            for m, c in zip(DISCORD_MENTION_RE.findall(msg), message.mentions):
                msg = msg.replace(m, f"@{c.display_name}")

        # replace channel mentions with raw text
        if DISCORD_CHANNEL_RE.search(msg):
            for m, c in zip(DISCORD_CHANNEL_RE.findall(msg), message.channel_mentions):
                msg = msg.replace(m, f"#{c.name}")

        # replace emotes with raw text
        if DISCORD_EMOTE_RE.search(msg):
            for m, e in DISCORD_EMOTE_RE.findall(msg):
                msg = msg.replace(m, e)

        reply_note = ""
        if message.reference:
            reply = await self.RELAY_CHANNEL.fetch_message(message.reference.message_id)
            reply_note = f" (replying to {reply.author.display_name})"

        # sanitize
        for i in ['"', '"']:
            msg = msg.replace(i, "'")

        msg = msg.replace("\\", "")

        for i in ["\n", "\r", "\t", "\f"]:
            msg = msg.replace(i, " ")

        msg = msg.replace(";", "")

        msg = f"{message.author.display_name}{reply_note}: {msg}"

        # max tf2 message length is 127;
        # " [...] (attachment)" (19) on max length 127-19=98
        if len(msg) > 94:
            msg = msg[:87] + " [...]"

        if len(message.attachments) != 0:
            msg = msg + " (attachment)"

        rcon(f"discord_relay_say {msg}")


client = DiscordBot()


@client.tree.command(
    name="rcon", description="Run a command on the server through rcon"
)
async def _rcon(interaction: discord.Interaction, command: str) -> None:
    if interaction.user.id not in cfg("rcon_users"):
        embed = discord.embeds.Embed(
            color=discord.Color.red(),
            description="You do not have access to that command.",
        )
        await interaction.response.send_message(embed=embed, ephemeral=True)
        return

    response = rcon(command)
    if len(response) == 0:
        response = "*Command does not have a response*"

    embed = discord.embeds.Embed(
        color=discord.Color.og_blurple(), title="Command", description=response
    )
    await interaction.response.send_message(embed=embed, ephemeral=True)


client.run(cfg("token"))
