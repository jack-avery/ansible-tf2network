/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod VoteAlltalk
 * Creates a map vote when the required number of players have requested one.
 * Updated with NativeVotes support
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <sourcemod>

// Despite being labeled as TF2-only, this plugin does work on other games.
// It's just identical to rockthevote.smx there
#undef REQUIRE_EXTENSIONS
#include <tf2>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.0.0"

public Plugin myinfo =
{
	name = "Vote Alltalk",
	author = "AlliedModders LLC and Powerlord, raspy",
	description = "Provides Alltalk Toggle Voting",
	version = VERSION,
	url = ""
};

ConVar g_Cvar_Needed;
ConVar g_Cvar_Alltalk;

int g_Voters = 0;				// Total voters connected. Doesn't include fake clients.
int g_Votes = 0;				// Total number of "say alltalk" votes
int g_VotesNeeded = 0;			// Necessary votes before alltalk toggles. (voters * percent_needed)
bool g_Voted[MAXPLAYERS+1] = {false, ...};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("votealltalk.phrases");
	
	g_Cvar_Needed = CreateConVar("sm_votealltalk_needed", "0.60", "Percentage of players needed to toggle alltalk (Def 60%)", 0, true, 0.05, true, 1.0);
	g_Cvar_Alltalk = FindConVar("sv_alltalk");
	
	RegConsoleCmd("sm_votealltalk", Command_VoteAlltalk);
	RegConsoleCmd("sm_valltalk", Command_VoteAlltalk);
	RegConsoleCmd("sm_alltalk", Command_VoteAlltalk);

	AutoExecConfig(true, "votealltalk");
}

public void OnMapStart()
{
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	
	/* Handle late load */
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}

public void OnClientConnected(int client)
{
	if(IsFakeClient(client))
		return;
	
	g_Voted[client] = false;

	g_Voters++;
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	return;
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
	{
		g_Votes--;
	}
	
	g_Voters--;
	
	g_VotesNeeded = RoundToFloor(float(g_Voters) * g_Cvar_Needed.FloatValue);
	
	if (g_Votes && 
		g_Voters && 
		g_Votes >= g_VotesNeeded ) 
	{
		ToggleAlltalk();
	}	
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if (!client)
	{
		return;
	}
	
	if (strcmp(sArgs, "alltalk", false) == 0 || strcmp(sArgs, "votealltalk", false) == 0)
	{
		ReplySource old = SetCmdReplySource(SM_REPLY_TO_CHAT);
		
		VoteAlltalk(client);
		
		SetCmdReplySource(old);
	}
}

public Action Command_VoteAlltalk(int client, int args)
{
	VoteAlltalk(client);
	
	return Plugin_Handled;
}

void VoteAlltalk(int client)
{
	if (g_Voted[client])
	{
		ReplyToCommand(client, "[SM] %t", "Already Voted", g_Votes, g_VotesNeeded);
		return;
	}	
	
	char name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));
	
	g_Votes++;
	g_Voted[client] = true;
	
	PrintToChatAll("[SM] %t", "Alltalk Requested", name, g_Votes, g_VotesNeeded);

	if (g_Votes >= g_VotesNeeded)
	{
		ToggleAlltalk();
	}
}

void ToggleAlltalk()
{
	bool old = GetConVarBool(g_Cvar_Alltalk);
	SetConVarBool(g_Cvar_Alltalk, !old);
	ResetVoteAlltalk();
}

void ResetVoteAlltalk()
{
	g_Votes = 0;
			
	for (int i=1; i<=MAXPLAYERS; i++)
	{
		g_Voted[i] = false;
	}
}
