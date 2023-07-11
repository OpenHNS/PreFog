#include <amxmodx>
#include <reapi>
#include <fakemeta>

new g_iHudObject;
new bool:g_bOnOffPre[MAX_PLAYERS + 1];
new bool:g_bOnOffSpeed[MAX_PLAYERS + 1];

enum PRE_TYPE {
	PRE_FOG = 0,
	PRE_JUMP,
	PRE_DUCK,
	PRE_LADDER,
	PRE_SLIDE
};

new g_szPreType[PRE_TYPE][] = {
	"",
	"[Jump]",
	"[Duck]",
	"[Ladder]",
	"[Slide]"
};

enum FOG_TYPE {
	FOG_VERYBAD = 0,
	FOG_PERFECT,
	FOG_GOOD,
	FOG_BAD
};

new g_szFogType[FOG_TYPE][] = {
	"[VB]",
	"[P]",
	"[G]",
	"[B]"
};

enum _:HUD_PRE {
	HUD_FOG,
	FOG_TYPE:HUD_FOGTYPE,
	Float:HUD_PREST,
	Float:HUD_POST,
	PRE_TYPE:HUD_TYPE
};

new g_eHudPre[MAX_PLAYERS + 1][HUD_PRE];

new bool:g_isPre[MAX_PLAYERS + 1];

new g_bInDuck[MAX_PLAYERS + 1];

new bool:g_isSpec[MAX_PLAYERS + 1];

enum PRE_CVAR {
	c_iPreHudDefPerfR,
	c_iPreHudDefPerfG,
	c_iPreHudDefPerfB,
	c_iPreHudDefR,
	c_iPreHudDefG,
	c_iPreHudDefB,
	Float:c_iPreHudX,
	Float:c_iPreHudY,
	c_iPreHud,
}

new g_pCvar[PRE_CVAR];

public plugin_init() {
	register_plugin("PreFog", "3.1.0", "WessTorn"); // Спасибо: FAME, Destroman, Borjomi, Denzer, Albertio

	bind_pcvar_num(register_cvar("pre_def_pref_R", "0"),	g_pCvar[c_iPreHudDefPerfR]);
	bind_pcvar_num(register_cvar("pre_def_pref_G", "250"),	g_pCvar[c_iPreHudDefPerfG]);
	bind_pcvar_num(register_cvar("pre_def_pref_B", "60"),	g_pCvar[c_iPreHudDefPerfB]);
	bind_pcvar_num(register_cvar("pre_def_R", "250"),		g_pCvar[c_iPreHudDefR]);
	bind_pcvar_num(register_cvar("pre_def_G", "250"),		g_pCvar[c_iPreHudDefG]);
	bind_pcvar_num(register_cvar("pre_def_B", "250"),		g_pCvar[c_iPreHudDefB]);
	bind_pcvar_float(register_cvar("pre_x", "-1.0"),		g_pCvar[c_iPreHudX]);
	bind_pcvar_float(register_cvar("pre_y", "0.55"),		g_pCvar[c_iPreHudY]);
	bind_pcvar_num(register_cvar("pre_hud", "1"),			g_pCvar[c_iPreHud]);

	register_clcmd("say /showpre", "cmdShowPre");
	register_clcmd("say /pre", "cmdShowPre");
	register_clcmd("say /showspeed", "cmdShowSpeed");
	register_clcmd("say /speed", "cmdShowSpeed");

	RegisterHookChain(RG_PM_Move, "rgPM_Move");

	g_iHudObject = CreateHudSyncObj();
}

public client_connect(id) {
	g_bOnOffPre[id] = true;
	g_bOnOffSpeed[id] = true;
	arrayset(g_eHudPre[id], 0, HUD_PRE);
}

public cmdShowPre(id) {
	g_bOnOffPre[id] = g_bOnOffPre[id] ? false : true;

	if (!g_bOnOffPre[id])
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Fog/Prestrafe: ^3OFF^1");
	else
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Fog/Prestrafe: ^3ON^1");
}

public cmdShowSpeed(id) {
	g_bOnOffSpeed[id] = g_bOnOffSpeed[id] ? false : true;

	if (!g_bOnOffSpeed[id])
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Speed: ^3OFF^1");
	else
		client_print_color(id, print_team_blue, "[^3PreFog^1] Show Speed: ^3ON^1");
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

	if (g_bOnOffSpeed[id] || g_bOnOffPre[id])
		show_prespeed(id, flSpeed);

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
				format_prest(id, PRE_SLIDE, flOldSpeed);
				isSlide = false;
			}
		}

		if (isOldGround) {
			new bool:isDuck = !g_bInDuck[id] && !(iOldButtons & IN_JUMP) && iPrevButtons & IN_DUCK;
			new bool:isJump = !isDuck && iOldButtons & IN_JUMP && !(iPrevButtons & IN_JUMP);

			if (isOldLadder) {
				format_prest(id, PRE_LADDER, flOldSpeed);
			} else {
				if (iFog > 10) {
					if (isDuck) {
						format_prest(id, PRE_DUCK, flOldSpeed);
					} 
					if (isJump) {
						format_prest(id, PRE_JUMP, flOldSpeed);
					}
				} else {
					new FOG_TYPE:iFogType;
					
					if (isJump) {
						if (flSpeed < flMaxSpeed && iFog == 1)
							iFogType = FOG_PERFECT;

						if (!iFogType) {
							switch(iFog) {
								case 1..2: iFogType = FOG_GOOD;
								case 3: iFogType = FOG_BAD;
								default: iFogType = FOG_VERYBAD;
							}
						}
					} else if (isDuck) {
						if (isSgs) {
							switch(iFog) {
								case 3: iFogType = FOG_PERFECT;
								case 4: iFogType = FOG_GOOD;
								case 5: iFogType = FOG_BAD;
								default: iFogType = FOG_VERYBAD;
							}
						} else {
							switch(iFog) {
								case 2: iFogType = FOG_PERFECT;
								case 3: iFogType = FOG_GOOD;
								case 4: iFogType = FOG_BAD;
								default: iFogType = FOG_VERYBAD;
							}
						}
					}
					
					format_prest(id, PRE_FOG, flOldSpeed, flPreSpeed, iFog, iFogType);
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

stock format_prest(id, PRE_TYPE:iPreType, Float:flPost, Float:flPre = 0.0, iFog = 0, FOG_TYPE:iType = FOG_VERYBAD) {
	g_isPre[id] = true;
	g_eHudPre[id][HUD_TYPE] = iPreType;
	g_eHudPre[id][HUD_POST] = flPost;
	g_eHudPre[id][HUD_PREST] = flPre;
	g_eHudPre[id][HUD_FOG] = iFog;
	g_eHudPre[id][HUD_FOGTYPE] = iType;
}

public show_prespeed(id, Float:flSpeed) {
	new Float:g_flGameTime = get_gametime();
	static Float:flHudTime
	
	if(flHudTime + 0.05 > g_flGameTime)
		return;

	static bool:isPre;
	static Float:flPreTime;

	if (!isPre) {
		isPre = g_isPre[id];
		if (isPre) {
			flPreTime = g_flGameTime + 1.0;
			g_isPre[id] = false;
		}
	} else {
		if (g_isPre[id]) {
			flPreTime = g_flGameTime + 1.0;
			g_isPre[id] = false;
		}
	}

	if(flPreTime < g_flGameTime) {
		isPre = false;
		arrayset(g_eHudPre[id], 0, HUD_PRE);
	}

	for (new i = 1; i <= MaxClients; i++) {
		if (i == id || g_isSpec[i]) {
			if (g_eHudPre[id][HUD_FOGTYPE] == FOG_PERFECT)
				set_hudmessage(g_pCvar[c_iPreHudDefPerfR], g_pCvar[c_iPreHudDefPerfG], g_pCvar[c_iPreHudDefPerfB], g_pCvar[c_iPreHudX], g_pCvar[c_iPreHudY], 0, 1.0, 0.15, 0.0, 0.0, g_pCvar[c_iPreHud]);
			else
				set_hudmessage(g_pCvar[c_iPreHudDefR], g_pCvar[c_iPreHudDefG], g_pCvar[c_iPreHudDefB], g_pCvar[c_iPreHudX], g_pCvar[c_iPreHudY], 0, 1.0, 0.15, 0.0, 0.0, g_pCvar[c_iPreHud]);


			new szSpeed[8];
			if (g_bOnOffSpeed[id])
				formatex(szSpeed, charsmax(szSpeed), "%.0f u/s", flSpeed)

			if (g_bOnOffPre[id] && isPre) {
				switch (g_eHudPre[id][HUD_TYPE]) {
					case HUD_FOG: {
						ShowSyncHudMsg(id, g_iHudObject, "%s^n^n%d %s^n%.2f^n%.2f", g_bOnOffSpeed[id] ? szSpeed : "", g_eHudPre[id][HUD_FOG], g_szFogType[g_eHudPre[id][HUD_FOGTYPE]], g_eHudPre[id][HUD_PREST], g_eHudPre[id][HUD_POST]);
					}
					default: {
						ShowSyncHudMsg(id, g_iHudObject, "%s^n^n%s^n%.2f", g_bOnOffSpeed[id] ? szSpeed : "", g_szPreType[g_eHudPre[id][HUD_TYPE]], g_eHudPre[HUD_POST]);
					}
				}
			} else { 
				ShowSyncHudMsg(id, g_iHudObject, "%s", g_bOnOffSpeed[id] ? szSpeed : "");
			}
		}
	}

	flHudTime = g_flGameTime;
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