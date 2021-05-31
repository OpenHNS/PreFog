#include <amxmodx>
#include <reapi>

new max_players;

new g_iDDNum[MAX_PLAYERS + 1];
new g_iPreDuckFog[MAX_PLAYERS + 1];
new Float:g_flDuckGainSpeed[MAX_PLAYERS + 1];
new Float:g_flPreDuckSpeed[MAX_PLAYERS + 1];

new g_iBhopNum[MAX_PLAYERS + 1];
new g_iPreBhopFog[MAX_PLAYERS + 1];
new Float:g_flBhopGainSpeed[MAX_PLAYERS + 1];
new Float:g_flPreBhopSpeed[MAX_PLAYERS + 1];
new bool:g_iPerfectBhops[MAX_PLAYERS + 1];

new bool:g_bLadderJump[MAX_PLAYERS + 1];
new Float:g_flPreLadderSpeed[MAX_PLAYERS + 1];

new g_iMoveType[MAX_PLAYERS + 1];
new g_iObject;
new bool:g_bFirstFallGround[MAX_PLAYERS + 1];
new bool:g_bOnOffPre[MAX_PLAYERS + 1];
new bool:g_bJumped[MAX_PLAYERS + 1];
new bool:g_bReset[MAX_PLAYERS + 1];
new bool:g_bAir[MAX_PLAYERS + 1];
new bool:g_bNoJump[MAX_PLAYERS + 1];
new bool:g_bUserDuck[MAX_PLAYERS + 1];
new Float:g_flFallTime[MAX_PLAYERS + 1];
new Float:g_flSpeed[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("PreFog", "1.1", "WessTorn"); // Спасибо, FAME, Destroman, Borjomi

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
			g_bJumped[id] = false;
			g_bAir[id] = false;
			g_bUserDuck[id] = false;
			g_bNoJump[id] = false;
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
			
			if (iGroundFrames[id] <= 5 && button & IN_JUMP && ~oldbuttons & IN_JUMP) {
				g_iPerfectBhops[id] = false;
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
					g_iPerfectBhops[id] = true;
			}

			if (iGroundFrames[id] <= 5 && button & IN_DUCK && (~oldbuttons & IN_DUCK || (button & IN_DUCK && oldbuttons & IN_DUCK && ~iPrevButtons[id] & IN_DUCK))) {
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

		if (g_bNoJump[id]) {
			g_bNoJump[id] = false;
		}

		if (flags & FL_ONGROUND) {
			g_bNoJump[id] = true;
		}

		if ((g_iMoveType[id] == MOVETYPE_FLY) && (button & IN_FORWARD || button & IN_BACK || button & IN_LEFT || button & IN_RIGHT)) {
			g_bLadderJump[id] = true;
		}

		if ((g_iMoveType[id] == MOVETYPE_FLY) && button & IN_JUMP) {
			g_bLadderJump[id] = false;
			g_bAir[id] = false;
			g_bNoJump[id] = true;
		}

		if (g_iMoveType[id] != MOVETYPE_FLY && g_bLadderJump[id] == true) {
			g_bNoJump[id] = true;
			g_bLadderJump[id] = false;

			static i;
			g_bAir[id] = true;
			g_bJumped[id] = true;
			g_flPreBhopSpeed[id] = 0.0;
			g_flPreDuckSpeed[id] = 0.0;
			for (i = 1; i <= max_players; i++) {
				if ((i == id || is_spec_user[i])) {
					if (g_bOnOffPre[i]) {
						g_flPreLadderSpeed[id] = g_flSpeed[id]
						set_hudmessage(140, 140, 140, -1.0, 0.665, 0, 0.0, 1.0, 0.01, 0.0);
						ShowSyncHudMsg(i, g_iObject, "%d", floatround(g_flSpeed[id]));
					}
				}
			}
		}

		if (button & IN_DUCK && !(oldbuttons & IN_DUCK) && flags & FL_ONGROUND) {
			if (g_flSpeed[id] > 110) {
				g_iDDNum[id]++;
			} else {
				g_iDDNum[id] = 0;
			}
		}

		if (button & IN_JUMP && !(oldbuttons & IN_JUMP) && flags & FL_ONGROUND) {
			g_iBhopNum[id]++;
			g_bNoJump[id] = false;

			g_iDDNum[id] = 0;
			get_entvar(id, var_velocity, velocity);
			static i;
			g_bAir[id] = true;
			g_bJumped[id] = true;

			for (i = 1; i <= max_players; i++) {
				if ((i == id || is_spec_user[i])) {
					if (g_bOnOffPre[i]) {
						if (g_iBhopNum[id] > 0) {
							g_flPreDuckSpeed[id] = g_flSpeed[id]
							if (floatround(g_flPreLadderSpeed[id]) > 20) {
								g_flBhopGainSpeed[id] = g_flPreLadderSpeed[id];
								g_flPreLadderSpeed[id] = 0.0;
							} else if (floatround(g_flPreBhopSpeed[id]) > 100) {
								g_flBhopGainSpeed[id] = g_flPreBhopSpeed[id];
								g_flPreBhopSpeed[id] = 0.0;
							}

							if (g_iPerfectBhops[id] == true) {
								if (g_flBhopGainSpeed[id] > g_flSpeed[id]) {
									set_hudmessage(0, 250, 60, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
									ShowSyncHudMsg(i, g_iObject, "FOG %d^n%d", g_iPreBhopFog[id], floatround(g_flSpeed[id]));
								} else if (g_flBhopGainSpeed[id] == 0.0 || g_flBhopGainSpeed[id] == g_flSpeed[id]) {
									set_hudmessage(0, 250, 60, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
									ShowSyncHudMsg(i, g_iObject, "FOG %d^n%d", g_iPreBhopFog[id], floatround(g_flSpeed[id]));
								} else if (g_flBhopGainSpeed[id] < g_flSpeed[id]) {
									set_hudmessage(0, 250, 60, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
									ShowSyncHudMsg(i, g_iObject, "FOG %d^n%d(+%d)", g_iPreBhopFog[id], floatround(g_flSpeed[id]), floatround(g_flSpeed[id] - g_flBhopGainSpeed[id]));
								}
							} else {
								if (g_flBhopGainSpeed[id] > g_flSpeed[id]) {
									set_hudmessage(200, 10, 50, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
									ShowSyncHudMsg(i, g_iObject, "FOG %d^n%d", g_iPreBhopFog[id], floatround(g_flSpeed[id]));
								} else if (g_flBhopGainSpeed[id] == 0.0 || g_flBhopGainSpeed[id] == g_flSpeed[id]) {
									set_hudmessage(200, 10, 50, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
									ShowSyncHudMsg(i, g_iObject, "FOG %d^n%d", g_iPreBhopFog[id], floatround(g_flSpeed[id]));
								} else if (g_flBhopGainSpeed[id] < g_flSpeed[id]) {
									set_hudmessage(200, 10, 50, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
									ShowSyncHudMsg(i, g_iObject, "FOG %d^n%d(+%d)", g_iPreBhopFog[id], floatround(g_flSpeed[id]), floatround(g_flSpeed[id] - g_flBhopGainSpeed[id]));
								}
							}
						}
					}
				}
			}

			g_flBhopGainSpeed[id] = g_flSpeed[id];
		} else if (flags & FL_ONGROUND && g_bAir[id]) {
			g_bReset[id] = true;
		}

		if (button & IN_DUCK && !(oldbuttons & IN_DUCK) && flags & FL_ONGROUND && !g_bUserDuck[id]) {
			for (new i = 1; i <= max_players; i++) {
				if ((i == id || is_spec_user[i])) {
					if (g_bOnOffPre[i]) {
						if (g_iDDNum[id] > 0) {
							g_flPreBhopSpeed[id] = g_flSpeed[id]
							if (floatround(g_flPreLadderSpeed[id]) > 20) {
								g_flBhopGainSpeed[id] = g_flPreLadderSpeed[id];
								g_flPreLadderSpeed[id] = 0.0;
							} else if (floatround(g_flPreDuckSpeed[id]) > 100) {
								g_flDuckGainSpeed[id] = g_flPreDuckSpeed[id];
								g_flPreDuckSpeed[id] = 0.0;
							}
							if (g_flDuckGainSpeed[id] > g_flSpeed[id]) {
								set_hudmessage(200, 10, 50, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
								ShowSyncHudMsg(i, g_iObject, "FOG %d^n%d(-%d)", g_iPreDuckFog[id], floatround(g_flSpeed[id]), floatround(g_flDuckGainSpeed[id] - g_flSpeed[id]));
							} else if (g_flDuckGainSpeed[id] == 0.0 || g_flDuckGainSpeed[id] == g_flSpeed[id]) {
								set_hudmessage(170, 170, 170, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
								ShowSyncHudMsg(i, g_iObject, "FOG %d^n%d", g_iPreDuckFog[id], floatround(g_flSpeed[id]));
							} else if (g_flDuckGainSpeed[id] < g_flSpeed[id]) {
								set_hudmessage(0, 250, 60, -1.0, 0.65, 0, 0.0, 1.0, 0.1, 0.0, 2);
								ShowSyncHudMsg(i, g_iObject, "FOG %d^n%d(+%d)", g_iPreDuckFog[id], floatround(g_flSpeed[id]), floatround(g_flSpeed[id] - g_flDuckGainSpeed[id]));
							}
						}
					}
				}
			}
			g_flDuckGainSpeed[id] = g_flSpeed[id];
			g_bUserDuck[id] = true;
		} else if (!g_bAir[id] && oldbuttons & IN_DUCK && flags & FL_ONGROUND) {
			if (!is_user_duck(id)) {
				g_bUserDuck[id] = false;
			}
		}

		if (flags & FL_ONGROUND && g_bFirstFallGround[id] == true && get_gametime() - g_flFallTime[id] > 0.5) {
			g_iDDNum[id] = 0;
			g_iBhopNum[id] = 0;
			g_bFirstFallGround[id] = false;
			g_iPerfectBhops[id] = false;
			g_flDuckGainSpeed[id] = 0.0;
			g_flPreBhopSpeed[id] = 0.0;
			g_flPreDuckSpeed[id] = 0.0;
			g_flBhopGainSpeed[id] = 0.0;
			g_flPreLadderSpeed[id] = 0.0;
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
	g_iPerfectBhops[id] = false;
	g_iDDNum[id] = 0;
	g_flBhopGainSpeed[id] = 0.0;
	g_flDuckGainSpeed[id] = 0.0;
	g_flPreBhopSpeed[id] = 0.0;
	g_flPreDuckSpeed[id] = 0.0;
	g_flPreLadderSpeed[id] = 0.0;
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
