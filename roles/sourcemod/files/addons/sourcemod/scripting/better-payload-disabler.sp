/*
	Better Payload Disabler
	by muddy
	
	I got temp banned from a UGC payload server for standing on the cart. I don't know
	what method they use, but if it's hacky enough that it lags the server, they obviously
	need some additional help.
	
	Consider this my application for plugin developer.
	
	-- CHANGELOG --
	1.0 - Initial release
*/

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required;
#pragma semicolon 1;

#define VERSION "1.0"

public Plugin myinfo =  {
	name = "Better Payload Disabler",
	author = "muddy",
	description = "Disables payload carts for PLR in a non-hacky way",
	version = VERSION,
	url = ""
}

public void OnPluginStart() {
	//hook cart being pushed - this would affect any tracktrain but hightower only has the carts
	HookEntityOutput("func_tracktrain", "OnStart", onCartPush);
}

void onCartPush(const char[] output, int caller, int activator, float delay) {
	//stop the cart as soon as it starts
	AcceptEntityInput(caller, "Stop", activator, caller);
}