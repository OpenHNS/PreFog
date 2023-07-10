#include <amxmodx>
#include <reapi>
#include <fakemeta>

new g_iHudObject;
new bool:g_bOnOffPre[MAX_PLAYERS + 1];

enum FOG_TYPE {
	FOG_VERYBAD = 0,
	FOG_PERFECT,
	FOG_GOOD,
	FOG_BAD
}

new g_szFogType[FOG_TYPE][] = {
	"[VB]",
	"[P]",
	"[G]",
	"[B]"
};

new FOG_TYPE:g_eFogType[MAX_PLAYERS + 1];

new g_bInDuck[MAX_PLAYERS + 1];

new bool:g_isSpec[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("PreFog", "2.1.0", "WessTorn"); // Спасибо: FAME, Destroman, Borjomi, Denzer, Albertio

	register_clcmd("say /showpre", "cmdShowPre")
	register_clcmd("say /pre", "cmdShowPre")

	RegisterHookChain(RG_PM_Move, "rgPM_Move");

	g_iHudObject = CreateHudSyncObj();
}

public client_connect(id) {
	g_bOnOffPre[id] = true;
}

public cmdShowPre(id) {
	g_bOnOffPre[id] = g_bOnOffPre[id] ? false : true;

	if (!g_bOnOffPre[id])
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Fog/Prestrafe: ^3OFF^1");
	else
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Fog/Prestrafe: ^3ON^1");
}

public rgPM_Move(id) {
	if (!g_bOnOffPre[id])
		return HC_CONTINUE;

	if (!is_user_alive(id)) {
		if(get_member(id, m_iObserverLastMode) == OBS_ROAMING)
			return HC_CONTINUE;

		g_isSpec[id] = true;
		return HC_CONTINUE;
	} else {
		g_isSpec[id] = false;
	}

	static iFog;

	new bool:isLadder = bool:(get_pmove(pm_movetype) == MOVETYPE_FLY);
	new bool:isGround = !bool:(get_pmove(pm_onground) == -1);
	static bool:isOldGround, bool:isOldLadder, bool:isSlide;
	isGround = isGround || isLadder;

	new Float:flVelocity[3]; get_pmove(pm_velocity, flVelocity);
	new Float:flSpeed = vector_hor_length(flVelocity);
	static Float:flOldSpeed, Float:flPreSpeed;

	new iOldButtons = get_pmove(pm_oldbuttons);
	static iPrevButtons; 

	new Float:flMaxSpeed = get_maxspeed(id);

	g_bInDuck[id] = bool:(get_pmove(pm_flags) & FL_DUCKING);
	static isSgs;

	if (isGround) {
		iFog++;

		if (iFog == 1) {
			isSgs = bool:(g_bInDuck[id]);
		}

		if (!isOldGround) {
			flPreSpeed = flSpeed;
		}
	} else {
		if (isUserSurfing(id)) {
			iFog = 0;
			isSlide = true;
		} else {
			if (isSlide) {
				for (new i = 1; i <= MaxClients; i++) {
					if (i == id || g_isSpec[i]) {
						set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.01, 0.0);
						ShowSyncHudMsg(i, g_iHudObject, "[Slide]^n%.2f", flSpeed);
					}
				}
				isSlide = false;
			}
		}

		if (isOldGround) {
			new bool:isDuck = !g_bInDuck[id] && !(iOldButtons & IN_JUMP) && iPrevButtons & IN_DUCK;
			new bool:isJump = !isDuck && iOldButtons & IN_JUMP && !(iPrevButtons & IN_JUMP);

			if (isOldLadder) {
				for (new i = 1; i <= MaxClients; i++) {
					if (i == id || g_isSpec[i]) {
						set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.01, 0.0);
						ShowSyncHudMsg(i, g_iHudObject, "[Ladder]^n%.2f", flSpeed);
					}
				}
			} else {
				if (iFog > 10) {
					if (isDuck) {
						for (new i = 1; i <= MaxClients; i++) {
							if (i == id || g_isSpec[i]) {
								set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.1, 0.0, 2);
								ShowSyncHudMsg(i, g_iHudObject, "[Duck]^n%.2f", flSpeed);
							}
						}
					} 
					if (isJump) {
						for (new i = 1; i <= MaxClients; i++) {
							if (i == id || g_isSpec[i]) {
								set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.1, 0.0, 2);
								ShowSyncHudMsg(i, g_iHudObject, "[Jump]^n%.2f", flSpeed);
							}
						}
					}
				} else {
					g_eFogType[id] = FOG_VERYBAD;
					
					if (isJump) {
						if (flSpeed < flMaxSpeed && iFog == 1)
							g_eFogType[id] = FOG_PERFECT;

						if (!g_eFogType[id]) {
							switch(iFog) {
								case 1..2: g_eFogType[id] = FOG_GOOD;
								case 3: g_eFogType[id] = FOG_BAD;
								default: g_eFogType[id] = FOG_VERYBAD;
							}
						}
					} else if (isDuck) {
						if (isSgs) {
							switch(iFog) {
								case 3: g_eFogType[id] = FOG_PERFECT;
								case 4: g_eFogType[id] = FOG_GOOD;
								case 5: g_eFogType[id] = FOG_BAD;
								default: g_eFogType[id] = FOG_VERYBAD;
							}
						} else {
							switch(iFog) {
								case 2: g_eFogType[id] = FOG_PERFECT;
								case 3: g_eFogType[id] = FOG_GOOD;
								case 4: g_eFogType[id] = FOG_BAD;
								default: g_eFogType[id] = FOG_VERYBAD;
							}
						}
					}
					
					for (new i = 1; i <= MaxClients; i++) {
						if (i == id || g_isSpec[i]) {
							if (g_eFogType[id] == FOG_PERFECT) {
								set_hudmessage(0, 250, 60, -1.0, 0.64, 0, 0.0, 1.0, 0.1, 0.0, 2);
								ShowSyncHudMsg(i, g_iHudObject, "%d %s^n%.2f^n%.2f", iFog, g_szFogType[g_eFogType[id]], flPreSpeed, flOldSpeed);
							} else {
								set_hudmessage(250, 250, 250, -1.0, 0.64, 0, 0.0, 1.0, 0.1, 0.0, 2);
								ShowSyncHudMsg(i, g_iHudObject, "%d %s^n%.2f^n%.2f", iFog, g_szFogType[g_eFogType[id]],flPreSpeed, flOldSpeed);
							}
						}
					}
				}
			}
		}

		isSgs = false
		iFog = 0;
	}

	isOldGround = isGround;
	isOldLadder = isLadder;
	iPrevButtons = iOldButtons;
	flOldSpeed = flSpeed;

	return HC_CONTINUE;
}

stock Float:vector_hor_length(Float:flVel[3]) {
	new Float:flNorma = floatpower(flVel[0], 2.0) + floatpower(flVel[1], 2.0);
	if (flNorma > 0.0)
		return floatsqroot(flNorma);
		
	return 0.0;
}

stock Float:get_maxspeed(id) {
	new Float:flMaxSpeed;
	flMaxSpeed = get_entvar(id, var_maxspeed);
	
	return flMaxSpeed * 1.2;
}

stock bool:isUserSurfing(id) {
	static Float:origin[3], Float:dest[3];
	get_entvar(id, var_origin, origin);
	
	dest[0] = origin[0];
	dest[1] = origin[1];
	dest[2] = origin[2] - 1.0;

	static Float:flFraction;

	engfunc(EngFunc_TraceHull, origin, dest, 0, 
		g_bInDuck[id] ? HULL_HEAD : HULL_HUMAN, id, 0);

	get_tr2(0, TR_flFraction, flFraction);

	if (flFraction >= 1.0) return false;
	
	get_tr2(0, TR_vecPlaneNormal, dest);

	return dest[2] <= 0.7;
} 