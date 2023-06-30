public Plugin myinfo = 
{
    name = "raspyverse basic commands handler plugin",
    author = "raspy",
    description = "",
    version = "1.0.0",
    url = "https://jackavery.ca/tf2"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_discord", Command_Discord);
    RegConsoleCmd("sm_donate", Command_Donate);
}

// there is almost certainly a better way to handle this, but i'm lazy
public Action Command_Discord(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }
    ReplyToCommand(client, "%s", "https://discord.gg/V5Z29SXtsY");
    return Plugin_Handled;
}

public Action Command_Donate(int client, int args)
{
    if (!client)
    {
        return Plugin_Handled;
    }
    ReplyToCommand(client, "%s", "https://ko-fi.com/raspy");
    return Plugin_Handled;
}
