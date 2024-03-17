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

SERVER_PLAYERS_RE = re.compile(r"players : (\d+) humans, \d+ bots \((\d+)")

with open("config.yml", "r") as f:
    CONFIG: dict = yaml.safe_load(f.read())
cfg = lambda k: CONFIG.get(k, None)

with open("manifest.yml", "r") as f:
    MANIFEST: dict[str, dict] = yaml.safe_load(f.read())

log_handlers = []
formatter = logging.Formatter(
    "%(asctime)s | %(module)s [%(levelname)s] %(message)s",
)
stdout_handler = logging.StreamHandler(sys.stdout)
stdout_handler.setLevel(logging.DEBUG)
stdout_handler.setFormatter(formatter)
log_handlers.append(stdout_handler)
logging.basicConfig(handlers=log_handlers, level=logging.DEBUG)


class DiscordBot(discord.Client):
    def __init__(self):
        # I don't know which to use, so we just do this.
        discord.Client.__init__(self, intents=discord.Intents().all())
        self.tree = discord.app_commands.CommandTree(self)

    async def on_ready(self) -> None:
        # find channels
        self.RELAY_CHANNELS: dict[str, discord.TextChannel] = {}
        # self.STATUS_CHANNELS: dict[str, discord.VoiceChannel] = {}
        for instance in MANIFEST:
            if "relay_channel" in MANIFEST[instance]:
                self.RELAY_CHANNELS[instance] = self.get_channel(
                    MANIFEST[instance]["relay_channel"]
                )

            # if "status_channel" in MANIFEST[instance]:
            #     self.STATUS_CHANNELS[instance] = self.get_channel(
            #         MANIFEST[instance]["status_channel"]
            #     )

        self.RELAY_LOOKUP: dict[discord.TextChannel, str] = {
            v.id: k for k, v in self.RELAY_CHANNELS.items()
        }

        # asyncio.ensure_future(self.poll_status())

        # get guild from channel; add commands
        for channel in self.RELAY_CHANNELS.values():
            self.tree.copy_global_to(guild=discord.Object(id=channel.guild.id))
        await self.tree.sync()

        logging.info("Ready!")

    async def rcon(self, instance: str, cmd: str) -> str | None:
        """Return the response of the given command.
        If the command times out, errors, or returns `None`.
        """
        rcon_client = Client(
            MANIFEST[instance]["ip"],
            MANIFEST[instance]["port"],
            passwd=MANIFEST[instance]["rcon_pass"],
        )
        try:
            rcon_client.connect(True)
            async with asyncio.timeout(5):
                response = rcon_client.run(cmd)
                rcon_client.close()
                return response
        except:
            rcon_client.close()
            return None

    # async def poll_status(self, frequency: int = 60) -> None:
    #     while True:
    #         await self.update_status_channels()
    #         await asyncio.sleep(frequency)

    # async def update_status_channels(self) -> None:
    #     """
    #     Poll server player info.
    #     """
    #     for instance in MANIFEST:
    #         if (
    #             "status_channel" not in MANIFEST[instance]
    #             or not MANIFEST[instance]["status_channel"]
    #         ):
    #             continue
    #         channel: discord.VoiceChannel = self.STATUS_CHANNELS[instance]

    #         status = await self.rcon(instance, "status")
    #         if not status:
    #             server_str = f'(??/??) {MANIFEST[instance]["hostname"]}'
    #             await channel.edit(name=server_str)
    #             continue

    #         info = SERVER_PLAYERS_RE.findall(status)[0]
    #         count_players = int(info[0])
    #         maxplayers = int(info[1])

    #         if MANIFEST[instance]["stv_enabled"]:
    #             maxplayers -= 1

    #         server_str = (
    #             f'({count_players}/{maxplayers}) {MANIFEST[instance]["hostname"]}'
    #         )
    #         # voice channel max name length is 100 characters; just truncate
    #         if len(server_str) > 100:
    #             server_str = server_str[:99]

    #         await channel.edit(name=server_str)

    async def on_message(self, message: discord.Message) -> None:
        if message.author == self.user or message.author.bot:
            return

        if not message.channel.id in self.RELAY_LOOKUP:
            return

        instance = self.RELAY_LOOKUP[message.channel.id]
        msg = message.content

        logging.info(
            f"Relaying message from {instance} channel to server: "
            + f"{message.author.global_name} said {msg}"
        )

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
            reply = await message.channel.fetch_message(message.reference.message_id)
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

        await self.rcon(instance, f"discord_relay_say {msg}")


client = DiscordBot()


@client.tree.command(
    name="instances", description="Get a list of instances for use with /rcon"
)
async def _instances(interaction: discord.Interaction) -> None:
    description = "- " + "\n- ".join([k for k in MANIFEST.keys()])
    embed = discord.embeds.Embed(
        color=discord.Color.og_blurple(),
        title="Instances listing",
        description=description,
    )
    await interaction.response.send_message(embed=embed, ephemeral=True)
    return


@client.tree.command(
    name="rcon", description="Run a command on the server through rcon"
)
async def _rcon(interaction: discord.Interaction, instance: str, command: str) -> None:
    if interaction.user.id not in cfg("rcon_users"):
        embed = discord.embeds.Embed(
            color=discord.Color.red(),
            description="You do not have access to that command.",
        )
        await interaction.response.send_message(embed=embed, ephemeral=True)
        return

    if instance not in MANIFEST:
        embed = discord.embeds.Embed(
            color=discord.Color.og_blurple(),
            title="Command",
            description=f"Instance `{instance}` does not exist.",
        )
        await interaction.response.send_message(embed=embed, ephemeral=True)
        return

    response = await client.rcon(instance, command)
    if len(response) == 0:
        response = "*Command does not have a response*"

    embed = discord.embeds.Embed(
        color=discord.Color.og_blurple(), title="Command", description=response
    )
    await interaction.response.send_message(embed=embed, ephemeral=True)


client.run(cfg("token"))
