#include <amxmodx>
#include <reapi>

new max_players;

new g_iPreDuckFog[MAX_PLAYERS + 1];
new bool:g_bPerfectDucks[MAX_PLAYERS + 1];

new g_iPreBhopFog[MAX_PLAYERS + 1];
new bool:g_bPerfectBhops[MAX_PLAYERS + 1];

new bool:g_bLadderJump[MAX_PLAYERS + 1];

new g_iMoveType[MAX_PLAYERS + 1];
new g_iObject;
new bool:g_bPlrSgs[MAX_PLAYERS + 1];
new bool:g_bFirstFallGround[MAX_PLAYERS + 1];
new bool:g_bOnOffPre[MAX_PLAYERS + 1];
new bool:g_bReset[MAX_PLAYERS + 1];
new bool:g_bAir[MAX_PLAYERS + 1];
new bool:g_bUserDuck[MAX_PLAYERS + 1];
new Float:g_flFallTime[MAX_PLAYERS + 1];
new Float:g_flSpeed[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("PreFog", "1.4", "WessTorn"); // Спасибо: FAME, Destroman, Borjomi, Denzer

	register_clcmd("say /showpre", "cmdShowPre")
	register_clcmd("say /pre", "cmdShowPre")

	RegisterHookChain(RG_CBasePlayer_PreThink, "rgPlayerPreThink", false);

	max_players = get_maxplayers();
	g_iObject = CreateHudSyncObj();
}

public cmdShowPre(id) {
	g_bOnOffPre[id] = g_bOnOffPre[id] ? false : true

	set_hudmessage(0, 100, 255, -1.0, 0.74, 2, 0.1, 2.5, 0.01, 0.01, 3);

	if (!g_bOnOffPre[id]) {
		ShowSyncHudMsg(id, g_iObject, "SHOWPRE: OFF");
	} else {
		ShowSyncHudMsg(id, g_iObject, "SHOWPRE: ON");
	}
}

public rgPlayerPreThink(id) {
	if (is_user_alive(id) && is_user_connected(id)) {
		if (g_bReset[id] == true) {
			g_bReset[id] = false;
			g_bAir[id] = false;
			g_bUserDuck[id] = false;
			g_bLadderJump[id] = false;
		}

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

		static iGroundFrames[MAX_PLAYERS + 1], iOldGroundFrames[MAX_PLAYERS + 1], iPrevButtons[MAX_PLAYERS + 1], Float:flSpeed, Float:flMaxPreStrafe, Pmaxspeed, Float:flOldSpeed[MAX_PLAYERS + 1];
		flSpeed = vector_length(velocity);
		Pmaxspeed = get_entvar(id, var_maxspeed);
		flMaxPreStrafe = Pmaxspeed * 1.2;

		if (flags & FL_ONGROUND) {
			iGroundFrames[id]++;

			if (button & IN_JUMP && ~oldbuttons & IN_JUMP)
				iOldGroundFrames[id] = iGroundFrames[id];

			if (button & IN_DUCK && ~oldbuttons & IN_DUCK)
				iOldGroundFrames[id] = iGroundFrames[id];

			if (iGroundFrames[id] == 1) {
				if (flags & FL_DUCKING)
					g_bPlrSgs[id] = true;
				else
					g_bPlrSgs[id] = false;
			}
			
			if (iGroundFrames[id] <= 5 && button & IN_JUMP && ~oldbuttons & IN_JUMP) {
				g_bPerfectBhops[id] = false;
				switch (iGroundFrames[id]) {
					case 1: {
						g_iPreBhopFog[id] = 1;
					}
					case 2: {
						g_iPreBhopFog[id] = 2;
					}
					case 3: {
						g_iPreBhopFog[id] = 3;
					}
					case 4: {
						g_iPreBhopFog[id] = 4;
					}
					case 5: {
						g_iPreBhopFog[id] = 5;
					}
				}

				if (flSpeed < flMaxPreStrafe && (iGroundFrames[id] == 1 || iGroundFrames[id] >= 2 && flOldSpeed[id] > flMaxPreStrafe))
					g_bPerfectBhops[id] = true;
			}

			if (iGroundFrames[id] <= 5 && button & IN_DUCK && (~oldbuttons & IN_DUCK || (button & IN_DUCK && oldbuttons & IN_DUCK && ~iPrevButtons[id] & IN_DUCK))) {
				g_bPerfectDucks[id] = false;
				switch (iGroundFrames[id]) {
					case 1: {
						g_iPreDuckFog[id] = 1;
					}
					case 2: {
						g_iPreDuckFog[id] = 2;
					}
					case 3: {
						g_iPreDuckFog[id] = 3;
					}
					case 4: {
						g_iPreDuckFog[id] = 4;
					}
					case 5: {
						g_iPreDuckFog[id] = 5;
					}
				}

				if (flSpeed < flMaxPreStrafe) {
					if (g_bPlrSgs[id] == true && iGroundFrames[id] == 2)
						g_bPerfectDucks[id] = true;
					else if (g_bPlrSgs[id] == false && iGroundFrames[id] == 1)
						g_bPerfectDucks[id] = true;
					else
						g_bPerfectDucks[id] = false;
				}
			}

		} else {
			if (iGroundFrames[id])
				iGroundFrames[id] = 0;
		}

		flOldSpeed[id] = flSpeed;

		new is_spec_user[MAX_PLAYERS + 1];
		for (new i = 1; i <= max_players; i++) {
			is_spec_user[i] = is_user_spectating_player(i, id);
		}

		if ((g_iMoveType[id] == MOVETYPE_FLY) && (button & IN_FORWARD || button & IN_BACK || button & IN_LEFT || button & IN_RIGHT)) {
			g_bLadderJump[id] = true;
		}

		if ((g_iMoveType[id] == MOVETYPE_FLY) && button & IN_JUMP) {
			g_bLadderJump[id] = false;
			g_bAir[id] = false;
		}

		if (g_iMoveType[id] != MOVETYPE_FLY && g_bLadderJump[id] == true) {
			g_bLadderJump[id] = false;

			static i;
			g_bAir[id] = true;
			for (i = 1; i <= max_players; i++) {
				if ((i == id || is_spec_user[i])) {
					if (g_bOnOffPre[i]) {
						set_hudmessage(250, 250, 250, -1.0, 0.65, 0, 0.0, 1.0, 0.01, 0.0);
						ShowSyncHudMsg(i, g_iObject, "[Ladder]^n%.2f", g_flSpeed[id]);
					}
				}
			}
		}

		if (button & IN_JUMP && !(oldbuttons & IN_JUMP) && flags & FL_ONGROUND) {
			get_entvar(id, var_velocity, velocity);
			static i;
			g_bAir[id] = true;

			for (i = 1; i <= max_players; i++) {
				if ((i == id || is_spec_user[i])) {
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
		} else if (flags & FL_ONGROUND && g_bAir[id]) {
			g_bReset[id] = true;
		}

		if (button & IN_DUCK && !(oldbuttons & IN_DUCK) && flags & FL_ONGROUND && !g_bUserDuck[id]) {
			for (new i = 1; i <= max_players; i++) {
				if ((i == id || is_spec_user[i])) {
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
			g_bUserDuck[id] = true;
		} else if (!g_bAir[id] && oldbuttons & IN_DUCK && flags & FL_ONGROUND) {
			if (!is_user_duck(id)) {
				g_bUserDuck[id] = false;
			}
		}

		if (flags & FL_ONGROUND && g_bFirstFallGround[id] == true && get_gametime() - g_flFallTime[id] > 0.5) {
			g_bFirstFallGround[id] = false;
			g_bPerfectBhops[id] = false;
			g_bPerfectDucks[id] = false;
			g_bPlrSgs[id] = false;
			g_iPreBhopFog[id] = 0;
			g_iPreDuckFog[id] = 0;
		}

		if (flags & FL_ONGROUND && g_bFirstFallGround[id] == false) {
			g_flFallTime[id] = get_gametime();
			g_bFirstFallGround[id] = true;
		} else if (!(flags & FL_ONGROUND) && g_bFirstFallGround[id] == true) {
			g_bFirstFallGround[id] = false;
		}
	}
}

bool:is_user_duck(id) {
	if (!is_entity(id))
		return false

	new Float:abs_min[3], Float:abs_max[3]

	get_entvar(id, var_absmin, abs_min)
	get_entvar(id, var_absmax, abs_max)

	abs_min[2] += 64.0

	if (abs_min[2] < abs_max[2])
		return false

	return true
}

public client_connect(id) {
	g_bOnOffPre[id] = true;
	g_bPerfectBhops[id] = false;
	g_bPerfectDucks[id] = false;
	g_bPlrSgs[id] = false;
	g_iPreBhopFog[id] = 0;
	g_iPreDuckFog[id] = 0;
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
