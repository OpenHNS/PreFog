#include <amxmodx>
#include <reapi>

new g_iPreDuckFog[MAX_PLAYERS + 1];
new bool:g_bPerfectDucks[MAX_PLAYERS + 1];

new g_iPreBhopFog[MAX_PLAYERS + 1];
new bool:g_bPerfectBhops[MAX_PLAYERS + 1];

new bool:g_bLadderJump[MAX_PLAYERS + 1];

new g_iMoveType[MAX_PLAYERS + 1];
new g_iObject;
new bool:g_bPlrSgs[MAX_PLAYERS + 1];
new bool:g_bOnOffPre[MAX_PLAYERS + 1];
new Float:g_flSpeed[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("PreFog", "1.5", "WessTorn"); // Спасибо: FAME, Destroman, Borjomi, Denzer

	register_clcmd("say /showpre", "cmdShowPre")
	register_clcmd("say /pre", "cmdShowPre")

	RegisterHookChain(RG_CBasePlayer_PreThink, "rgPlayerPreThink", false);

	g_iObject = CreateHudSyncObj();
}

public cmdShowPre(id) {
	g_bOnOffPre[id] = g_bOnOffPre[id] ? false : true;

	if (!g_bOnOffPre[id])
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Fog/Prestrafe: ^3OFF^1");
	else
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Fog/Prestrafe: ^3ON^1");
}

public rgPlayerPreThink(id) {
	if (is_user_alive(id) && is_user_connected(id)) {
		static button, oldbuttons, flags;
		button = get_entvar(id, var_button);
		flags = get_entvar(id, var_flags);
		oldbuttons = get_entvar(id, var_oldbuttons);

		new Float:velocity[3];
		get_entvar(id, var_velocity, velocity);
		g_iMoveType[id] = get_entvar(id, var_movetype);

		if (flags & FL_ONGROUND && flags & FL_INWATER)
			velocity[2] = 0.0;
		if (velocity[2] != 0)
			velocity[2] -= velocity[2];

		g_flSpeed[id] = vector_length(velocity);

		static iGroundFrames[MAX_PLAYERS + 1], Float:flSpeed, Float:flMaxPreStrafe, Pmaxspeed, Float:flOldSpeed[MAX_PLAYERS + 1];
		flSpeed = vector_length(velocity);
		Pmaxspeed = get_entvar(id, var_maxspeed);
		flMaxPreStrafe = Pmaxspeed * 1.2;

		if (flags & FL_ONGROUND) {
			iGroundFrames[id]++;

			if (iGroundFrames[id] == 1) {
				g_bPlrSgs[id] = (flags & FL_DUCKING) ? true : false;
			}

			if (iGroundFrames[id] <= 5) {
				if (button & IN_JUMP && ~oldbuttons & IN_JUMP) {
					g_bPerfectBhops[id] = false;
					g_iPreBhopFog[id] = iGroundFrames[id];

					if (flSpeed < flMaxPreStrafe && (iGroundFrames[id] == 1 || iGroundFrames[id] >= 2 && flOldSpeed[id] > flMaxPreStrafe))
						g_bPerfectBhops[id] = true;
				} else if (button & IN_DUCK && ~oldbuttons & IN_DUCK) {
					g_bPerfectDucks[id] = false;
					g_iPreDuckFog[id] = iGroundFrames[id];

					if (flSpeed < flMaxPreStrafe) {
						if (g_bPlrSgs[id] == true && iGroundFrames[id] == 2)
							g_bPerfectDucks[id] = true;
						else if (g_bPlrSgs[id] == false && iGroundFrames[id] == 1)
							g_bPerfectDucks[id] = true;
						else
							g_bPerfectDucks[id] = false;
					}
				}
			}
		} else {
			if (iGroundFrames[id])
				iGroundFrames[id] = 0;
		}

		flOldSpeed[id] = flSpeed;

		new is_spec_user[MAX_PLAYERS + 1];
		for (new i = 1; i <= MaxClients; i++) {
			is_spec_user[i] = is_user_spectating_player(i, id);
		}

		if ((g_iMoveType[id] == MOVETYPE_FLY) && (button & IN_FORWARD || button & IN_BACK || button & IN_LEFT || button & IN_RIGHT)) {
			g_bLadderJump[id] = true;
		}

		if ((g_iMoveType[id] == MOVETYPE_FLY) && button & IN_JUMP) {
			g_bLadderJump[id] = false;
		}

		if (g_iMoveType[id] != MOVETYPE_FLY && g_bLadderJump[id] == true) {
			g_bLadderJump[id] = false;

			static i;
			for (i = 1; i <= MaxClients; i++) {
				if (i == id || is_spec_user[i]) {
					if (g_bOnOffPre[i]) {
						set_hudmessage(250, 250, 250, -1.0, 0.65, 0, 0.0, 1.0, 0.01, 0.0);
						ShowSyncHudMsg(i, g_iObject, "[Ladder]^n%.2f", g_flSpeed[id]);
					}
				}
			}
		}

		if (button & IN_JUMP && !(oldbuttons & IN_JUMP) && flags & FL_ONGROUND) {
			static i;
			for (i = 1; i <= MaxClients; i++) {
				if (i == id || is_spec_user[i]) {
					if (g_bOnOffPre[i]) {
						if (g_bPerfectBhops[id] == true) {
							set_hudmessage(0, 250, 60, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
							ShowSyncHudMsg(i, g_iObject, "%d [P]^n%.2f", g_iPreBhopFog[id], g_flSpeed[id]);
						} else {
							set_hudmessage(250, 250, 250, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
							if (g_iPreBhopFog[id] == 2)
								ShowSyncHudMsg(i, g_iObject, "%d [G]^n%.2f", g_iPreBhopFog[id], g_flSpeed[id]);
							else if (g_iPreBhopFog[id] == 3)
								ShowSyncHudMsg(i, g_iObject, "%d [B]^n%.2f", g_iPreBhopFog[id], g_flSpeed[id]);
							else if (g_iPreBhopFog[id] == 0)
								ShowSyncHudMsg(i, g_iObject, "[Jump]^n%.2f", g_flSpeed[id]);
							else
								ShowSyncHudMsg(i, g_iObject, "%d [VB]^n%.2f", g_iPreBhopFog[id], g_flSpeed[id]);
						}
					}
				}
			}
		} else if (button & IN_DUCK && ~oldbuttons & IN_DUCK && flags & FL_ONGROUND) {
			static i;
			for (i = 1; i <= MaxClients; i++) {
				if (i == id || is_spec_user[i]) {
					if (g_bOnOffPre[i]) {
						if (g_bPerfectDucks[id] == true) {
							set_hudmessage(0, 250, 60, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
							ShowSyncHudMsg(i, g_iObject, "%d [P]^n%.2f", g_iPreDuckFog[id], g_flSpeed[id]);

						} else {
							set_hudmessage(250, 250, 250, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
							if (g_iPreDuckFog[id] == 2 || g_iPreDuckFog[id] == 1)
								ShowSyncHudMsg(i, g_iObject, "%d [G]^n%.2f", g_iPreDuckFog[id], g_flSpeed[id]);
							else if (g_iPreDuckFog[id] == 3)
								ShowSyncHudMsg(i, g_iObject, "%d [B]^n%.2f", g_iPreDuckFog[id], g_flSpeed[id]);
							else if (g_iPreDuckFog[id] == 0)
								ShowSyncHudMsg(i, g_iObject, "[Duck]^n%.2f", g_flSpeed[id]);
							else
								ShowSyncHudMsg(i, g_iObject, "%d [VB]^n%.2f", g_iPreDuckFog[id], g_flSpeed[id]);
						}
					}
				}
			}
		}
	}
}

public client_connect(id) {
	g_bOnOffPre[id] = true;
}

stock is_user_spectating_player(spectator, player) {
	if(!is_user_connected(spectator) || !is_user_connected(player))
		return 0;

	if(is_user_alive(spectator) || !is_user_alive(player))
		return 0;

	static specmode;
	specmode = get_entvar(spectator, var_iuser1);

	if(specmode == 3)
		return 0;
	   
	if(get_entvar(spectator, var_iuser2) == player)
		return 1;
	   
	return 0;
}
