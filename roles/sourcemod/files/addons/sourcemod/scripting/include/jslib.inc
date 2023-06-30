#if defined _jslib_included_
  #endinput
#endif
#define _jslib_included_

#include <tf2_stocks>
// --------------

#define EMPTY_VECTOR view_as<float>({0,0,0})

enum {
	TEAM_UNASSIGNED = 0,
	TEAM_SPECTATOR,
	TEAM_RED,
	TEAM_BLUE
}

enum {
	INTEL_PICKEDUP = 1,
	INTEL_CAPTURED,
	INTEL_DEFENDED,
	INTEL_DROPPED,
	INTEL_RETURNED
}

#define HIDEHUD_WEAPONSELECTION   (1<<0)
#define HIDEHUD_FLASHLIGHT        (1<<1)
#define HIDEHUD_ALL               (1<<2)
#define HIDEHUD_HEALTH            (1<<3)
#define HIDEHUD_PLAYERDEAD        (1<<4)
#define HIDEHUD_NEEDSUIT          (1<<5)
#define HIDEHUD_MISCSTATUS        (1<<6)
#define HIDEHUD_CHAT              (1<<7)
#define HIDEHUD_CROSSHAIR         (1<<8)
#define HIDEHUD_VEHICLE_CROSSHAIR (1<<9)
#define HIDEHUD_INVEHICLE         (1<<10)
#define HIDEHUD_BONUS_PROGRESS    (1<<11)


/**
 * Checks if a 3D vector equals {0.0, 0.0, 0.0}.
 * 
 * @param vector       The 3D vector to check against
 * @return             True if empty, else false
 */
stock bool IsEmptyVector(float vector[3]) {
	return !vector[0] && !vector[1] && !vector[2];
}

/**
 * Return absolute value of an integer
 * 
 * @param value        The value to check against
 * @return             Absolute value
 */
stock int Abs(int value) {
    int mask = value >> 31;
    return (value + mask) ^ mask;
}

/**
 * Return absolute value of a floating point value
 * 
 * @param value        The value to check against
 * @return             Absolute value
 */
stock float AbsF(float value) {
   return view_as<float>(view_as<int>(value) & ~cellmin);
}

/**
 * Clamp an int value to inclusive range [min, max].
 * Assumes that min is less than max.
 * 
 * @param value        The value to check against
 * @param min          Minimum boundary
 * @param max          Maximum boundary
 * @return             Value if within bounds, else boundary extrema
 */
stock int Clamp(int value, int min, int max) {
	if (value > max) {
		return max;
	}
	
	if (value < min) {
		return min;
	}

	return value;
}

/**
 * Clamp a float value to inclusive range [min, max].
 * Assumes that min is less than max.
 * 
 * @param value        The value to check against
 * @param min          Minimum boundary
 * @param max          Maximum boundary
 * @return             Value if within bounds, else boundary extrema
 */
stock float ClampF(float value, float min, float max) {
	if (value > max) {
		return max;
	}
	
	if (value < min) {
		return min;
	}

	return value;
}

/**
 * Converts a hex string to an integer value
 * 
 * @param hex          The hex string to convert
 * @return             Integer result of the hex conversion
 */
stock int HexToInt(const char[] hex) {
	return StringToInt(hex, 16);
}

/**
 * Formats an int value to 6 character hex
 * 
 * @param value        The value to format
 * @param hex          Buffer to store result
 * @param size         Buffer size
 */
stock void IntToHex6(int value, char[] hex, int size) {
	FormatEx(hex, size, "%06X", value);
}

/**
 * Formats an int value to 8 character hex
 * 
 * @param value        The value to format
 * @param hex          Buffer to store result
 * @param size         Buffer size
 */
stock void IntToHex8(int value, char[] hex, int size) {
	FormatEx(hex, size, "%08X", value);
}

/**
 * Converts hex sequence to RGB
 * 
 * @param hex          Hex string to convert
 * @param rgb          Result of conversion
 */
stock void HexToRGB(const char[] hex, int rgb[3]) {
	IntToRGB(HexToInt(hex), rgb);
}

/**
 * Converts hex sequence ro RGBA
 * 
 * @param hex          Hex string to convert
 * @param rgba         Result of conversion
 */
stock void HexToRGBA(const char[] hex, int rgba[4]) {
	IntToRGBA(HexToInt(hex), rgba);
}

/**
 * Converts RGB to 6 character hex sequence
 * 
 * @param rgb          The RGB int values to convert
 * @param hex          Buffer to store result
 * @param size         Buffer size
 */
stock void RGBToHex(const int rgb[3], char[] hex, int size) {
	IntToHex6(RGBToInt(rgb), hex, size);
}

/**
 * Converts RGBA to 8 character hex sequence
 * 
 * @param rgba         The RGBA int values to convert
 * @param hex          Buffer to store result
 * @param size         Buffer size
 */
stock void RGBAToHex(const int rgba[4], char[] hex, int size) {
	IntToHex8(RGBAToInt(rgba), hex, size);
}

/**
 * Converts int value to RGB values
 * 
 * @param value        The int value to convert
 * @param rgb          Buffer to store result
 */
stock void IntToRGB(int value, int rgb[3]) {
	rgb[0] = ((value >> 16) & 0xFF);
	rgb[1] = ((value >>  8) & 0xFF);
	rgb[2] = ((value      ) & 0xFF);
}

/**
 * Converts int value to RGBA values
 * 
 * @param value         The int value to convert
 * @param rgba          Buffer to store results
 */
stock void IntToRGBA(int value, int rgba[4]) {
	rgba[0] = ((value >> 24) & 0xFF);
	rgba[1] = ((value >> 16) & 0xFF);
	rgba[2] = ((value >>  8) & 0xFF);
	rgba[3] = ((value      ) & 0xFF);
}

/**
 * Converts RGB values to int value
 * 
 * @param rgb           The RGB values to convert
 * @return              Result of conversion from RGB to int
 */
stock int RGBToInt(const int rgb[3]) {
	return ((rgb[0] & 0xFF) << 16) |
	       ((rgb[1] & 0xFF) <<  8) |
	       ((rgb[2] & 0xFF)      );
}

/**
 * Converts RGBA values to int value
 * 
 * @param rgba          The RGBA values to convert
 * @return              Result of conversion from RGBA to int
 */
stock int RGBAToInt(const int rgba[4]) {
	return ((rgba[0] & 0xFF) << 24) |
	       ((rgba[1] & 0xFF) << 16) |
	       ((rgba[2] & 0xFF) <<  8) |
	       ((rgba[3] & 0xFF)      );
}

/**
 * Searches for a client by name.
 * Differs from FindTarget in that it doesn't call ReplyToTargetError().
 * 
 * @param client       Client index of player searching for target
 * @param target       The search string of the target's name
 * @param nobots       Set to true to exclude bots
 * @param immunity     Set to false to ignore immunity
 * @return             Target index if found, else -1
 */
stock int FindTargetEx(int client, const char[] target, bool nobots = false, bool immunity = true) {
	int flags = COMMAND_FILTER_NO_MULTI;

	if (nobots) {
		flags |= COMMAND_FILTER_NO_BOTS;
	}

	if (!immunity) {
		flags |= COMMAND_FILTER_NO_IMMUNITY;
	}

	char target_name[MAX_TARGET_LENGTH];
	int target_list[1];
	bool tn_is_ml;

	if ((ProcessTargetString(target, client, target_list, 1, flags, target_name, sizeof(target_name), tn_is_ml)) > 0) {
		return target_list[0];
	}

	return -1;
}

/**
 * Allows for changing the ammo count for the specific client and weapon
 * 
 * @param client         Client index
 * @param weapon         Weapon entity
 * @param ammo           New ammo count
 */
stock void SetPrimaryAmmo(int client, int weapon, int ammo) {
	int ammoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammoType != -1) {
		SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, ammoType);
	}
}

/**
 * Retrieves the string name of a class based on TFClassType
 * 
 * @param class     The class to retrieve name of
 * @param buffer    Destination string buffer
 * @param size      Length of destination buffer, including null terminator
 */
stock void GetClassName(TFClassType class, char[] buffer, int size) {
	switch(class) {
		case TFClass_Scout:    strcopy(buffer, size, "Scout");
		case TFClass_Sniper:   strcopy(buffer, size, "Sniper");
		case TFClass_Soldier:  strcopy(buffer, size, "Soldier");
		case TFClass_DemoMan:  strcopy(buffer, size, "Demoman");
		case TFClass_Medic:    strcopy(buffer, size, "Medic");
		case TFClass_Heavy:    strcopy(buffer, size, "Heavy");
		case TFClass_Pyro:     strcopy(buffer, size, "Pyro");
		case TFClass_Spy:      strcopy(buffer, size, "Spy");
		case TFClass_Engineer: strcopy(buffer, size, "Engineer");
	}
}

/**
 * Checks a client index for validity
 * 
 * @note To be only used within a native
 * 
 * @param client        Client index
 * @param inGame        Set to false to not test if client is in game
 * 
 * @error Throws if 1) client index out of bounds. 2) client is not connected 3) inGame param true
 *        and client is not in game.
 */
stock void CheckNativeClient(int client, bool inGame = true) {
	if (client < 1 || client > MaxClients) {
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}

	if (!IsClientConnected(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not connected", client);
	}

	if (inGame && !IsClientInGame(client)) {
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not in game", client);
	}
}
