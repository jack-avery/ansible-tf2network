#include <sourcemod>
#include <discord>
#include <SteamWorks>

#define PLUGIN_VERSION "1.0"

#define MSG_CHAT "{\"avatar_url\": \"{AVATAR}\", \"username\": \"{NAME} [{STEAMID}]\", \"content\": \"{MESSAGE}\"}"
#define MSG_DISCONNECT "{\"content\": \":outbox_tray: **{NAME}** `[{STEAMID}]` disconnected\"}"
#define MSG_CONNECT "{\"content\": \":inbox_tray: **{NAME}** `[{STEAMID}]` connected\"}"
#define MSG_MAPCHANGE "{\"content\": \":map: The server has changed maps to **{MAP}**\"}"

ConVar g_cWebhook;
ConVar g_cAPIKey;

char g_sAvatarURL[MAXPLAYERS+1][128];

public Plugin myinfo = 
{
    name = "Discord: relay",
    author = ".#Zipcore, Dragonisser, raspy",
    description = "Extremely primitive relay submodule for Discord Plugin",
    version = PLUGIN_VERSION,
    url = ""
}

public void OnPluginStart()
{
    CreateConVar("discord_relay_version", PLUGIN_VERSION, "Discord Relay version", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cWebhook = CreateConVar("discord_relay_webhook", "relay", "Config key from configs/discord.cfg.");
    g_cAPIKey = CreateConVar("discord_relay_apikey", "", "Steam API Key (https://steamcommunity.com/dev/apikey).", FCVAR_PROTECTED);

    RegConsoleCmd("say", ChatHook);
    RegConsoleCmd("say_team", ChatHook);
}

public void OnMapStart()
{
    char map[PLATFORM_MAX_PATH];
    GetCurrentMap(map, sizeof(map));
    Discord_EscapeString(map, sizeof(map))
    
    char sMSG[2048] = MSG_MAPCHANGE;
    ReplaceString(sMSG, sizeof(sMSG), "{MAP}", map);

    SendMessage(sMSG);
}

public void OnClientAuthorized(int client, const char[] auth)
{
    if (StrEqual(auth, "BOT"))
    {
        return;
    }

    char sName[32];
    GetClientName(client, sName, sizeof(sName));
    Discord_EscapeString(sName, sizeof(sName));

    char sMSG[2048] = MSG_CONNECT;
    ReplaceString(sMSG, sizeof(sMSG), "{NAME}", sName);
    ReplaceString(sMSG, sizeof(sMSG), "{STEAMID}", auth);

    SendMessage(sMSG);

    char apiKey[64];
    g_cAPIKey.GetString(apiKey, sizeof(apiKey));

    if(StrEqual(apiKey, ""))
	{
		return;
	}

    g_sAvatarURL[client][0] = '\0';
    char szSteamID64[32];
    if(!GetClientAuthId(client, AuthId_SteamID64, szSteamID64, sizeof(szSteamID64)))
    {
        return;
    }
    static char sRequest[256];
    FormatEx(sRequest, sizeof(sRequest), "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s&format=vdf", apiKey, szSteamID64);
    Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, sRequest);
    if(!hRequest || !SteamWorks_SetHTTPRequestContextValue(hRequest, client) || !SteamWorks_SetHTTPCallbacks(hRequest, OnTransferCompleted) || !SteamWorks_SendHTTPRequest(hRequest))
    {
        delete hRequest;
    }
}

public void OnClientDisconnect(int client)
{
    char sAuth[32];
    GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));

    if (StrEqual(sAuth, "BOT"))
    {
        return;
    }
    
    char sName[32];
    GetClientName(client, sName, sizeof(sName));
    Discord_EscapeString(sName, sizeof(sName));

    char sMSG[2048] = MSG_DISCONNECT;
    ReplaceString(sMSG, sizeof(sMSG), "{NAME}", sName);
    ReplaceString(sMSG, sizeof(sMSG), "{STEAMID}", sAuth);

    SendMessage(sMSG);
}

public void OnTransferCompleted(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
    if (bFailure || !bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
    {
        LogError("SteamAPI HTTP Response failed: %d", eStatusCode);
        delete hRequest;
        return;
    }

    int iBodyLength;
    SteamWorks_GetHTTPResponseBodySize(hRequest, iBodyLength);

    char[] sData = new char[iBodyLength];
    SteamWorks_GetHTTPResponseBodyData(hRequest, sData, iBodyLength);

    delete hRequest;
    
    APIWebResponse(sData, client);
}

public void APIWebResponse(const char[] sData, int client)
{
    KeyValues kvResponse = new KeyValues("SteamAPIResponse");

    if (!kvResponse.ImportFromString(sData, "SteamAPIResponse"))
    {
        LogError("kvResponse.ImportFromString(\"SteamAPIResponse\") in APIWebResponse failed. Try updating your steamworks extension.");

        delete kvResponse;
        return;
    }

    if (!kvResponse.JumpToKey("players"))
    {
        LogError("kvResponse.JumpToKey(\"players\") in APIWebResponse failed. Try updating your steamworks extension.");

        delete kvResponse;
        return;
    }

    if (!kvResponse.GotoFirstSubKey())
    {
        LogError("kvResponse.GotoFirstSubKey() in APIWebResponse failed. Try updating your steamworks extension.");

        delete kvResponse;
        return;
    }

    kvResponse.GetString("avatarfull", g_sAvatarURL[client], sizeof(g_sAvatarURL[]));
    delete kvResponse;
}

public Action ChatHook(int client, int args)
{
    char sAuth[32];
    GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));
    
    char sName[32];
    GetClientName(client, sName, sizeof(sName));
    Discord_EscapeString(sName, sizeof(sName));

    char sChat[512]
    GetCmdArgString(sChat, sizeof(sChat));
    StripQuotes(sChat);
    Discord_EscapeString(sChat, sizeof(sChat));

    char sMSG[2048] = MSG_CHAT;
    ReplaceString(sMSG, sizeof(sMSG), "{NAME}", sName);
    ReplaceString(sMSG, sizeof(sMSG), "{STEAMID}", sAuth);
    ReplaceString(sMSG, sizeof(sMSG), "{MESSAGE}", sChat);
    ReplaceString(sMSG, sizeof(sMSG), "{AVATAR}", g_sAvatarURL[client]);

    SendMessage(sMSG);

    return Plugin_Continue;
}

SendMessage(char[] sMessage)
{
    char sWebhook[32];
    g_cWebhook.GetString(sWebhook, sizeof(sWebhook));
    Discord_SendMessage(sWebhook, sMessage);
}