#if defined _tf2paj_included_
  #endinput
#endif
#define _tf2paj_included_

/**
 * @brief Called when pyro is blowing air
 *
 * @param iClient			Client index
 * @return					Plugin_Handled to block the air jump
 */
forward Action:TF2_OnPyroAirBlast( iClient );

public SharedPlugin:__pl_tf2paj =
{
	name = "tf2pyroairjump",
	file = "tf2pyroairjump.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

public __pl_tf2paj_SetNTVOptional()
{
}
