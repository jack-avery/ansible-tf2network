#if defined __antiflood
#endinput
#endif
#define __antiflood

/**
 * Check whether a user is actively blocked from chatting by antiflood.
 * 
 * @param client the client to check
 * @return whether the client is flood blocked
 */
native bool antiflood_blocked(int client);