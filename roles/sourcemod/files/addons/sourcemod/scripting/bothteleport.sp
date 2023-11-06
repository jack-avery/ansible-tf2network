#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "kgbproject"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
//#include <sdkhooks>

public Plugin myinfo = 
{
	name = "[TF2]Bidirectional Teleports",
	author = PLUGIN_AUTHOR,
	description = "Toggles engineer teleports moving players in both sides",
	version = PLUGIN_VERSION,
	url = "sourcemod.net"
};
public OnPluginStart()
{
CreateConVar("bidirectional_teleports_version", PLUGIN_VERSION, "Bidirectional Teleports Version", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
    HookEvent("post_inventory_application", Event_PlayerSpawn, EventHookMode_Post);
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
        int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    new Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
    if(IsValidEntity(Weapon))
    {
    	   if (TF2_GetPlayerClass(client) == TFClassType:TFClass_Engineer)
        {
            TF2Attrib_SetByDefIndex(client, 276, 1.0);    //bidirectional teleport
        }
    }
}  