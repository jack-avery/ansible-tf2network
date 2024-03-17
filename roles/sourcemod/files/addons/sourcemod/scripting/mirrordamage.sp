#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <mirrordamage>

#pragma semicolon 1

public Plugin:myinfo =
{
   name = "Mirror Damage",
   author = "Forth",
   description = "Turns damage dealt or taken by marked players into self-damage",
   version = "1.2"
}

new Handle:g_CvarPublicMirror = INVALID_HANDLE;
new Handle:g_CvarFriendlyFire = INVALID_HANDLE;

new bool:g_bLateLoad = false;
new bool:g_FriendlyFire = false;

new bool:g_Mirror[MAXPLAYERS+1];
new bool:g_MirrorTaken[MAXPLAYERS+1];
new bool:g_Locked[MAXPLAYERS+1];

new mirrorme_flags = ADMFLAG_SLAY;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
   g_bLateLoad = late;

   CreateNative("MirrorDamage_Status", Native_Status);
   CreateNative("MirrorDamage_Enable", Native_Enable);
   RegPluginLibrary("mirrordamage");

   return APLRes_Success;
}

public OnPluginStart()
{
   LoadTranslations("common.phrases");

   RegAdminCmd("sm_mirror", Command_Mirror, ADMFLAG_SLAY,
      "sm_mirror <#userid|name> <0|1>");
   RegAdminCmd("sm_mirrortaken", Command_Mirror, ADMFLAG_SLAY,
      "sm_mirrortaken <#userid|name> <0|1>");
   RegAdminCmd("sm_listmirrors", Command_ListMirrors, ADMFLAG_SLAY, "sm_listmirrors");
   RegConsoleCmd("sm_mirrorme", Command_MirrorMe, "sm_mirrorme");

   g_CvarPublicMirror = CreateConVar("sm_mirror_public", "1.0",
      "Whether regular players can run sm_mirrorme", _, true, 0.0, true, 1.0);

   g_CvarFriendlyFire = FindConVar("mp_friendlyfire");

   GetCommandOverride("sm_mirrorme", Override_Command, mirrorme_flags);

   AutoExecConfig(true, "plugin.mirrordamage");

   ResetOverride();
   HookConVarChange(g_CvarPublicMirror, OnPublicMirrorChanged);

   if (g_CvarFriendlyFire != INVALID_HANDLE) {
      g_FriendlyFire = GetConVarBool(g_CvarFriendlyFire);
      HookConVarChange(g_CvarFriendlyFire, OnFriendlyFireChanged);
   }

   if (g_bLateLoad) {
      for (new i = 1; i <= MaxClients; i++)
         if (IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
   }
}

public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
   g_Mirror[client]      = false;
   g_MirrorTaken[client] = false;
   g_Locked[client]      = false;
}

public OnRebuildAdminCache(AdminCachePart:part)
{
   if (part == AdminCache_Overrides) {
      GetCommandOverride("sm_mirrorme", Override_Command, mirrorme_flags);
      ResetOverride();
   }
}

public OnPublicMirrorChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
   ResetOverride();
}

ResetOverride()
{
   switch (GetConVarInt(g_CvarPublicMirror)) {
      case 0:
      {
         AddCommandOverride("sm_mirrorme", Override_Command, mirrorme_flags);
      }
      case 1:
      {
         UnsetCommandOverride("sm_mirrorme", Override_Command);
      }
   }
}

public OnFriendlyFireChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
  g_FriendlyFire = GetConVarBool(convar);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage,
   &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
   if (attacker < 1 || attacker > MaxClients)
      return Plugin_Continue;

   if (client != attacker && (g_Mirror[attacker] || g_MirrorTaken[client])) {
      if (damagecustom == TF_CUSTOM_BACKSTAB)
         damage = GetClientHealth(attacker) * 6.0;
      else if (damagecustom == TF_CUSTOM_BOOTS_STOMP)
         return Plugin_Handled;
      else if (!g_FriendlyFire && GetClientTeam(client) == GetClientTeam(attacker))
        return Plugin_Continue;

      SDKHooks_TakeDamage(attacker, client, attacker, damage, damagetype, weapon, damageForce, damagePosition);
      return Plugin_Handled;
   }

   return Plugin_Continue;
}

public Action:Command_MirrorMe(client, args)
{
   if (g_Locked[client])
      ReplyToCommand(client, "[SM] Damage mirroring has been locked by an administrator");
   else {
      g_Mirror[client] = !g_Mirror[client];
      ReplyToCommand(client, "[SM] Damage mirroring %s", g_Mirror[client] ? "enabled" : "disabled");
   }

   return Plugin_Handled;
}

public Action:Command_Mirror(client, args)
{
   decl String:cmd[16];
   GetCmdArg(0, cmd, sizeof(cmd));

   new bool:mirrortaken = (strcmp("sm_mirror", cmd) == 0) ? false : true;

   if (args < 2) {
      ReplyToCommand(client, "[SM] Usage: %s <#userid|name> <0|1>", cmd);
      return Plugin_Handled;
   }

   new String:arg[64];
   GetCmdArg(1, arg, sizeof(arg));

   decl String:target_name[MAX_TARGET_LENGTH];
   decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

   if ((target_count = ProcessTargetString(
      arg,
      client,
      target_list,
      MAXPLAYERS,
      COMMAND_FILTER_CONNECTED,
      target_name,
      sizeof(target_name),
      tn_is_ml)) <= 0)
   {
      ReplyToTargetError(client, target_count);
      return Plugin_Handled;
   }

   new String:arg2[16];
   GetCmdArg(2, arg2, sizeof(arg2));

   new bool:enable = bool:StringToInt(arg2);

   new String:action[] = "disabled";
   if (enable)
      action = "enabled";

   new String:type[] = "dealt";
   if (mirrortaken)
      type = "taken";

   ShowActivity2(client, "[SM] ", "%s damage %s mirroring for %s",
      enable ? "Enabled" : "Disabled", type, target_name);

   for (new i = 0; i < target_count; i++) {
      if (mirrortaken)
         g_MirrorTaken[ target_list[i] ] = enable;
      else {
         g_Mirror[ target_list[i] ] = enable;
         g_Locked[ target_list[i] ] = enable;
      }

      LogAction(client, target_list[i], "\"%L\" %s damage %s mirror for \"%L\"",
         client, action, type, target_list[i]);
   }

   return Plugin_Handled;
}

public Action:Command_ListMirrors(client, args)
{
   for (new i = 1; i <= MaxClients; i++) {
      if (!IsClientInGame(i) || IsClientReplay(i))
         continue;
      else if (!g_Mirror[i] && !g_MirrorTaken[i])
         continue;

      ReplyToCommand(client, "Mirror: %3s, Mirror Taken: %3s, Locked: %3s | %N",
         g_Mirror[i]      ? "Yes" : " No",
         g_MirrorTaken[i] ? "Yes" : " No",
         g_Locked[i]      ? "Yes" : " No", i);
   }
   return Plugin_Handled;
}

public Native_Status(Handle:hPlugin, numParams)
{
   new client = GetNativeCell(1);
   if (client < 1 || client > MaxClients) {
      return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
   }

   if (!IsClientConnected(client)) {
      return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
   }

   new MirrorType:mType = GetNativeCell(2);
   switch (mType)
   {
      case MirrorDealt:
      {
         return g_Mirror[client];
      }
      case MirrorTaken:
      {
         return g_MirrorTaken[client];
      }
      case MirrorLocked:
      {
         return g_Locked[client];
      }
   }

   return ThrowNativeError(SP_ERROR_NATIVE,
      "Mirror type %d is invalid", mType);
}

public Native_Enable(Handle:hPlugin, numParams)
{
   new client = GetNativeCell(1);
   if (client < 1 || client > MaxClients) {
      return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d", client);
   }

   if (!IsClientConnected(client)) {
      return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
   }

   new MirrorType:mType = GetNativeCell(2);
   new bool:enable = GetNativeCell(3);

   switch (mType)
   {
      case MirrorDealt:
      {
         g_Mirror[client] = enable;
      }
      case MirrorTaken:
      {
         g_MirrorTaken[client] = enable;
      }
      case MirrorLocked:
      {
         g_Locked[client] = enable;
      }
      default:
      {
         return ThrowNativeError(SP_ERROR_NATIVE,
            "Mirror type %d is invalid", mType);
      }
   }

   return true;
}
