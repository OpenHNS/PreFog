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

enum PRE_COLOR {
	CLR_WHITE = 0,
	CLR_GREEN,
	CLR_VIOLET,
	CLR_BLUE,
	CLR_RED,
	CLR_YELLOW
};

new PRE_COLOR:g_eSpeedColorDef[MAX_PLAYERS + 1];
new PRE_COLOR:g_eSpeedColorPerf[MAX_PLAYERS + 1];

enum SPEED_TYPE {
	ST_DEF = 0,
	ST_QUAKE,
	ST_NUM
}

new SPEED_TYPE:g_eSpeedType[MAX_PLAYERS + 1];

new bool:g_isPre[MAX_PLAYERS + 1];

new bool:g_bInDuck[MAX_PLAYERS + 1];

new bool:g_isSpec[MAX_PLAYERS + 1];

enum PRE_CVAR {
	Float:c_iPreHudX,
	Float:c_iPreHudY,
	c_iPreHud,
}

new g_pCvar[PRE_CVAR];

public plugin_init() {
	register_plugin("PreFog", "3.2.0", "WessTorn"); // Спасибо: FAME, Destroman, Borjomi, Denzer, Albertio

	bind_pcvar_float(register_cvar("pre_x", "-1.0"),		g_pCvar[c_iPreHudX]);
	bind_pcvar_float(register_cvar("pre_y", "0.55"),		g_pCvar[c_iPreHudY]);
	bind_pcvar_num(register_cvar("pre_hud", "1"),			g_pCvar[c_iPreHud]);

	register_clcmd("say /speedmenu", "cmdPreSpeedMenu");
	register_clcmd("say /speed", "cmdPreSpeedMenu");
	register_clcmd("say /premenu", "cmdPreSpeedMenu");
	register_clcmd("say /pre", "cmdPreSpeedMenu");
	register_clcmd("say /showpre", "cmdShowPre");
	register_clcmd("say /showspeed", "cmdShowSpeed");

	RegisterHookChain(RG_PM_Move, "rgPM_Move");

	g_iHudObject = CreateHudSyncObj();
}

public client_connect(id) {
	g_bOnOffPre[id] = true;
	g_bOnOffSpeed[id] = true;
	arrayset(g_eHudPre[id], 0, HUD_PRE);
	g_eSpeedColorDef[id] = CLR_WHITE;
	g_eSpeedColorPerf[id] = CLR_GREEN;
	g_eSpeedType[id] = ST_DEF;
}

public rgPM_Move(id) {
	if (!g_bOnOffPre[id] && !g_bOnOffSpeed[id])
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
	new Float:flSpeedDef = vector_length(flVelocity);
	static Float:flOldSpeed, Float:flPreSpeed;

	new iOldButtons = get_pmove(pm_oldbuttons);
	static iPrevButtons; 

	new Float:flMaxSpeed = get_maxspeed(id);

	g_bInDuck[id] = bool:(get_pmove(pm_flags) & FL_DUCKING);
	static bool:isSgs;

	show_prespeed(id, flSpeed, flSpeedDef);

	if (isGround) {
		iFog++;

		if (iFog == 1) {
			isSgs = g_bInDuck[id];
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

stock show_prespeed(id, Float:flSpeed, Float:flSpeedDef = 0.0) {
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

	new iColors[3];

	static Float:val;
	val = convertToRange(floatmin(flSpeed, 285.0), 40.0, 285.0); // в квар

	FormatRGBHud(id, val, iColors);

	for (new i = 1; i <= MaxClients; i++) {
		if (i == id || g_isSpec[i]) {
			set_hudmessage(iColors[0], iColors[1], iColors[2], g_pCvar[c_iPreHudX], g_pCvar[c_iPreHudY], 0, 1.0, 0.15, 0.0, 0.0, g_pCvar[c_iPreHud]);

			new szSpeed[32];
			if (g_bOnOffSpeed[id]) {
				switch (g_eSpeedType[id]) {
					case ST_DEF: 	formatex(szSpeed, charsmax(szSpeed), "%.0f u/s", flSpeed);
					case ST_QUAKE: 	formatex(szSpeed, charsmax(szSpeed), "%.0f units/seconds^n%.0f velocity", flSpeedDef, flSpeed);
					case ST_NUM: 	formatex(szSpeed, charsmax(szSpeed), "%.0f", flSpeed);
				}
			}

			if (g_bOnOffPre[id] && isPre) {
				switch (g_eHudPre[id][HUD_TYPE]) {
					case HUD_FOG: {
						ShowSyncHudMsg(id, g_iHudObject, "%s^n^n%d %s^n%.2f^n%.2f", g_bOnOffSpeed[id] ? szSpeed : "", g_eHudPre[id][HUD_FOG], g_szFogType[g_eHudPre[id][HUD_FOGTYPE]], g_eHudPre[id][HUD_PREST], g_eHudPre[id][HUD_POST]);
					}
					default: {
						ShowSyncHudMsg(id, g_iHudObject, "%s^n^n%s^n%.2f", g_bOnOffSpeed[id] ? szSpeed : "", g_szPreType[g_eHudPre[id][HUD_TYPE]], g_eHudPre[id][HUD_POST]);
					}
				}
			} else { 
				ShowSyncHudMsg(id, g_iHudObject, "%s", g_bOnOffSpeed[id] ? szSpeed : "");
			}
		}
	}

	flHudTime = g_flGameTime;
}

public cmdPreSpeedMenu(id) {
	if (!is_user_connected(id))
		return;

	new hMenu = menu_create("\rPreFog menu:", "SpeedMenuCode");

	if (g_bOnOffSpeed[id]) {
		menu_additem(hMenu, "Speed - \yon", "1");
	} else {
		menu_additem(hMenu, "Speed - \doff", "1");
	}

	if (g_bOnOffPre[id]) {
		menu_additem(hMenu, "Prefog - \yon", "2");
	} else {
		menu_additem(hMenu, "Prefog - \doff", "2");
	}
	
	switch (g_eSpeedType[id]) {
		case ST_DEF: 	menu_additem(hMenu, "Speed type - \ydefault", "3");
		case ST_QUAKE: 	menu_additem(hMenu, "Speed type - \yquake", "3");
		case ST_NUM: 	menu_additem(hMenu, "Speed type - \ynumber", "3");
	}

	switch (g_eSpeedColorPerf[id]) {
		case CLR_WHITE: 	menu_additem(hMenu, "Hud perfect color - \ywhite", "4");
		case CLR_GREEN:		menu_additem(hMenu, "Hud perfect color - \ygreen", "4");
		case CLR_VIOLET:	menu_additem(hMenu, "Hud perfect color - \yviolet", "4");
		case CLR_BLUE:		menu_additem(hMenu, "Hud perfect color - \yblue", "4");
		case CLR_RED:		menu_additem(hMenu, "Hud perfect color - \yred", "4");
		case CLR_YELLOW:	menu_additem(hMenu, "Hud perfect color - \yyellow", "4");
	}

	switch (g_eSpeedColorDef[id]) {
		case CLR_WHITE:		menu_additem(hMenu, "Hud default color - \ywhite", "5");
		case CLR_GREEN:		menu_additem(hMenu, "Hud default color - \ygreen", "5");
		case CLR_VIOLET:	menu_additem(hMenu, "Hud default color - \yviolet", "5");
		case CLR_BLUE:		menu_additem(hMenu, "Hud default color - \yblue", "5");
		case CLR_RED:		menu_additem(hMenu, "Hud default color - \yred", "5");
		case CLR_YELLOW:	menu_additem(hMenu, "Hud default color - \yyellow", "5");
	}

	menu_display(id, hMenu, 0);
}

public SpeedMenuCode(id, hMenu, item) {
	if (item == MENU_EXIT) {
		return PLUGIN_HANDLED;
	}


	menu_destroy(hMenu);

	switch (item) {
		case 0: {
			cmdShowSpeed(id);
			cmdPreSpeedMenu(id);
		}
		case 1: {
			cmdShowPre(id);
			cmdPreSpeedMenu(id);
		}
		case 2: {
			switch (g_eSpeedType[id]) {
				case ST_DEF:	g_eSpeedType[id] = ST_QUAKE;
				case ST_QUAKE:	g_eSpeedType[id] = ST_NUM;
				case ST_NUM:	g_eSpeedType[id] = ST_DEF;
			}

			cmdPreSpeedMenu(id);
		}
		case 3: {
			switch (g_eSpeedColorPerf[id]) {
				case CLR_WHITE:		g_eSpeedColorPerf[id] = CLR_GREEN;
				case CLR_GREEN:		g_eSpeedColorPerf[id] = CLR_VIOLET;
				case CLR_VIOLET:	g_eSpeedColorPerf[id] = CLR_BLUE;
				case CLR_BLUE:		g_eSpeedColorPerf[id] = CLR_RED;
				case CLR_RED:		g_eSpeedColorPerf[id] = CLR_YELLOW;
				case CLR_YELLOW:	g_eSpeedColorPerf[id] = CLR_WHITE;
			}

			cmdPreSpeedMenu(id);
		}
		case 4: {
			switch (g_eSpeedColorDef[id]) {
				case CLR_WHITE:		g_eSpeedColorDef[id] = CLR_GREEN;
				case CLR_GREEN:		g_eSpeedColorDef[id] = CLR_VIOLET;
				case CLR_VIOLET:	g_eSpeedColorDef[id] = CLR_BLUE;
				case CLR_BLUE:		g_eSpeedColorDef[id] = CLR_RED;
				case CLR_RED:		g_eSpeedColorDef[id] = CLR_YELLOW;
				case CLR_YELLOW:	g_eSpeedColorDef[id] = CLR_WHITE;
			}

			cmdPreSpeedMenu(id);
		}
	}
	return PLUGIN_HANDLED;
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

FormatRGBHud(id, const Float:val, colors[3]) {
	new iColorPerf[3], iColorDef[3];

	switch (g_eSpeedColorPerf[id]) {
		case CLR_WHITE: {
			iColorPerf = {255, 255, 255};
		}
		case CLR_GREEN: {
			iColorPerf = {0, 250, 0};
		}
		case CLR_VIOLET: {
			iColorPerf = {250, 0, 250};
		}
		case CLR_BLUE: {
			iColorPerf = {0, 150, 250};
		}
		case CLR_RED: {
			iColorPerf = {250, 0, 0};
		}
		case CLR_YELLOW: {
			iColorPerf = {250, 250, 0};
		}
	}

	switch (g_eSpeedColorDef[id]) {
		case CLR_WHITE: {
			iColorDef = g_eHudPre[id][HUD_FOGTYPE] == FOG_PERFECT ? iColorPerf : {255, 255, 255};
		}
		case CLR_GREEN: {
			iColorDef = g_eHudPre[id][HUD_FOGTYPE] == FOG_PERFECT ? iColorPerf : {0, 250, 0};
		}
		case CLR_VIOLET: {
			iColorDef = g_eHudPre[id][HUD_FOGTYPE] == FOG_PERFECT ? iColorPerf : {250, 0, 250};
		}
		case CLR_BLUE: {
			iColorDef = g_eHudPre[id][HUD_FOGTYPE] == FOG_PERFECT ? iColorPerf : {0, 150, 250};
		}
		case CLR_RED: {
			iColorDef = g_eHudPre[id][HUD_FOGTYPE] == FOG_PERFECT ? iColorPerf : {250, 0, 0};
		}
		case CLR_YELLOW: {
			iColorDef = g_eHudPre[id][HUD_FOGTYPE] == FOG_PERFECT ? iColorPerf : {250, 250, 0};
		}
	}

	colors[0] = floatround(float(iColorPerf[0] - iColorDef[0]) * val + iColorDef[0]);
	colors[1] = floatround(float(iColorPerf[1] - iColorDef[1]) * val + iColorDef[1]);
	colors[2] = floatround(float(iColorPerf[2] - iColorDef[2]) * val + iColorDef[2]);
}

stock Float: convertToRange(Float:value, Float:FromMin, Float:FromMax, Float:ToMin = 0.0, Float:ToMax = 1.0) {
	return floatclamp((value-FromMin) / (FromMax-FromMin) * (ToMax-ToMin + ToMin), ToMin, ToMax);
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