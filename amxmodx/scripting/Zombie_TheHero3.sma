#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "Zombie: The Hero"
#define VERSION "3.0"
#define AUTHOR "Dias"

#define LANG_OFFICIAL LANG_PLAYER
// #define _DEBUG

// Configs
new const SETTING_FILE[] = "zombie_thehero2/config.ini"
new const MAP_FILE[] = "zombie_thehero2/maplist.ini"
new const CVAR_FILE[] = "zombie_thehero2/zth_server.cfg"
new const LANG_FILE[] = "zombie_thehero2.txt"

#define KNIFE_IMPULSE 25622
#define DEF_COUNTDOWN 20
#define MAX_ZOMBIECLASS 20

#define MAIN_HUD_X -1.0
#define MAIN_HUD_Y 0.30
#define MAIN_HUD_Y_BOTTOM 0.70

// Speed Problem
new g_UsingCustomSpeed[33]
new Float:g_PlayerMaxSpeed[33]

// TASK
enum 
{
	TASK_CHOOSECLASS = 52001,
	TASK_NVGCHANGE
}

#define MAX_SYNCHUD 6

new g_gamemode, g_evo_need_infect[2]
// Game Vars
new iGameCurStatus:g_gamestatus, g_MaxPlayers,
g_Forwards[FWD_MAX], g_WinText[PlayerTeams][64], g_countdown_count,
g_zombieclass_i, g_fwResult, g_classchoose_time, Float:g_Delay_ComeSound, g_SyncHud[MAX_SYNCHUD],
g_firstzombie, g_firsthuman

new g_zombie[33], g_hero[33], g_hero_locked[33], g_sex[33], g_StartHealth[33], g_StartArmor[33],
g_zombie_class[33], g_zombie_type[33], g_level[33], g_RespawnTime[33], g_unlocked_class[33][MAX_ZOMBIECLASS],
g_can_choose_class[33], g_restore_health[33], g_iMaxLevel[33], Float:g_iEvolution[33]

new zombie_level2_health, zombie_level2_armor, zombie_level3_health, zombie_level3_armor, zombie_minhealth, zombie_minarmor,
grenade_default_power, human_health, human_armor,
g_respawn_time, g_respawn_icon[64], g_respawn_iconid, Float:g_health_reduce_percent, Float:g_flinfect_multi[33]

new Float:g_roundstart_time;
// Array
new Array:human_model_male, Array:human_model_female, Array:hero_model_male, Array:hero_model_female,
Array:sound_infect_male, Array:sound_infect_female
new Array:sound_game_start, sound_game_count[64], Array:sound_win_human, Array:sound_win_zombie,
Array:sound_zombie_coming, Array:sound_zombie_comeback, sound_ambience[64], sound_human_levelup[64],
sound_remain_time[64]

new Array:zombie_name, Array:zombie_desc, Array:zombie_sex, Array:zombie_lockcost, Array:zombie_model_host, Array:zombie_model_origin,
Array:zombie_gravity, Array:zombie_speed_host, Array:zombie_speed_origin, Array:zombie_knockback, Array:zombie_dmgmulti,
Array:zombie_painshock, Array:zombie_sound_death1, Array:zombie_sound_death2, Array:zombie_sound_hurt1,
Array:zombie_sound_hurt2, Array:zombie_clawsmodel_host, Array:zombie_clawsmodel_origin, Array:zombie_claw_distance1, Array:zombie_claw_distance2
	
new Array:zombie_sound_heal, Array:zombie_sound_evolution, Array:sound_zombie_attack,
Array:sound_zombie_hitwall, Array:sound_zombie_swing
	
// - Weather & Sky & NVG
new g_mapname[32]
new g_rain, g_snow, g_fog, g_fog_density[10], g_fog_color[12]
new g_sky[32], g_light[2]
new g_NvgColor[PlayerTeams][3], g_NvgAlpha, g_nvg[33], g_HasNvg[33]
new const sound_nvg[2][] = {"items/nvg_off.wav", "items/nvg_on.wav"}

new const HealerSpr[] = "sprites/zombie_thehero/zombihealer.spr" // temp

// Block Round Event
new g_BlockedObj_Forward
new g_BlockedObj[12][] =
{
        "func_bomb_target",
        "info_bomb_target",
        "info_vip_start",
        "func_vip_safetyzone",
        "func_escapezone",
        "hostage_entity",
        "monster_scientist",
        "func_hostage_rescue",
        "info_hostage_rescue",
        "item_longjump",
        "func_vehicle",
        "func_buyzone"
}

// Restore Health Problem
new Restore_Health_Time, Restore_Amount_Host, Restore_Amount_Origin
new g_MsgScreenFade

new g_Msg_SayText

#define MAX_RETRY 33

// ======================== PLUGINS FORWARDS ======================
// ================================================================
public plugin_init()
{
	if(g_zombieclass_i == -1)
	{
		set_fail_state("[ZB3] Error: No Class Loaded")
		return
	}
	
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Register Lang
	register_dictionary(LANG_FILE)
	
	// Game Events
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("CurWeapon", "Event_CheckWeapon", "be", "1=1")
	register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_will_restart_in")
	
	// Messages
	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon")
	register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse")
	register_message(get_user_msgid("Health"), "Message_Health")
	register_message(get_user_msgid("Battery"), "Message_Battery")
	
	// Forward
	unregister_forward(FM_Spawn, g_BlockedObj_Forward)
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_ClientKill, "fw_Block" );
	register_forward(FM_ClientDisconnect, "fw_disconnect" );

	// ReAPI Hooks
	RegisterHookChain(RG_RoundEnd, "Fw_RG_RoundEnd");
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "Fw_RG_CSGameRules_OnRoundFreezeEnd");
	RegisterHookChain(RG_CSGameRules_SendDeathMessage, "Fw_RG_CSGameRules_SendDeathMessage");
	RegisterHookChain(RG_CSGameRules_PlayerSpawn, "Fw_RG_CSGameRules_PlayerSpawn_Post", 1);
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Fw_RG_CBasePlayer_TakeDamage");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "Fw_RG_CBasePlayer_TakeDamage_Post", 1);
	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "Fw_RG_CBasePlayer_ResetMaxSpeed");
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "Fw_RG_CBasePlayer_AddPlayerItem");
	RegisterHookChain(RG_CBasePlayer_TakeDamageImpulse, "Fw_RG_CBasePlayer_TakeDamageImpulse");
	RegisterHookChain(RG_CBasePlayer_Pain, "Fw_RG_CBasePlayer_Pain");
	RegisterHookChain(RG_CBasePlayer_DeathSound, "Fw_RG_CBasePlayer_DeathSound");
	RegisterHookChain(RG_CBasePlayer_PreThink, "Fw_RG_CBasePlayer_PreThink");
	RegisterHookChain(RG_CBasePlayer_GetIntoGame, "Fw_RG_CBasePlayer_GetIntoGame");

	g_MaxPlayers = get_maxplayers()
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	g_Msg_SayText = get_user_msgid("SayText")
	
	formatex(g_WinText[TEAM_HUMAN], 63, "%L", LANG_OFFICIAL, "WIN_HUMAN")
	formatex(g_WinText[TEAM_ZOMBIE], 63, "%L", LANG_OFFICIAL, "WIN_ZOMBIE")
	formatex(g_WinText[TEAM_ALL], 63, "#Round_Draw")
	formatex(g_WinText[TEAM_START], 63, "#Game_Commencing")	
	
	g_Forwards[FWD_USER_INFECT] = CreateMultiForward("zb3_user_infected", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FWD_USER_CHANGE_CLASS] = CreateMultiForward("zb3_user_change_class", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FWD_USER_SPAWN] = CreateMultiForward("zb3_user_spawned", ET_IGNORE, FP_CELL)
	g_Forwards[FWD_USER_DEAD] = CreateMultiForward("zb3_user_dead", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FWD_GAME_START] = CreateMultiForward("zb3_game_start", ET_IGNORE, FP_CELL)
	g_Forwards[FWD_GAME_END] = CreateMultiForward("zb3_game_end", ET_IGNORE, FP_CELL)
	g_Forwards[FWD_USER_EVOLUTION] = CreateMultiForward("zb3_zombie_evolution", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FWD_USER_HERO] = CreateMultiForward("zb3_user_become_hero", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FWD_TIME_CHANGE] = CreateMultiForward("zb3_time_change", ET_IGNORE)
	g_Forwards[FWD_SKILL_HUD] = CreateMultiForward("zb3_skill_show", ET_IGNORE, FP_CELL)
	
	g_SyncHud[SYNCHUD_NOTICE] = CreateHudSyncObj(SYNCHUD_NOTICE)
	g_SyncHud[SYNCHUD_HUMANZOMBIE_ITEM] = CreateHudSyncObj(SYNCHUD_HUMANZOMBIE_ITEM)
	g_SyncHud[SYNCHUD_ZBHM_SKILL1] = CreateHudSyncObj(SYNCHUD_ZBHM_SKILL1)
	g_SyncHud[SYNCHUD_ZBHM_SKILL2] = CreateHudSyncObj(SYNCHUD_ZBHM_SKILL2)
	g_SyncHud[SYNCHUD_ZBHM_SKILL3] = CreateHudSyncObj(SYNCHUD_ZBHM_SKILL3)
	g_SyncHud[SYCHUDD_EFFECTKILLER] = CreateHudSyncObj(SYCHUDD_EFFECTKILLER)

	// Set Sky
	if(g_sky[0])
		set_cvar_string("sv_skyname", g_sky)

	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)

#if defined _DEBUG
	register_clcmd("zb3_infect", "cmd_infect")
	register_clcmd("zb3_hero", "cmd_hero")
	register_clcmd("zb3_free", "cmd_free")
#endif

	register_clcmd("nightvision", "cmd_nightvision")
	register_clcmd("drop", "cmd_drop")
	
	set_member_game(m_GameDesc, GAMENAME);

	set_task(1.0, "Time_Change", _, _, _, "b")
}

#if defined _DEBUG
public cmd_infect(id)
{
	if(!is_user_connected(id))
		return
	if(!g_gamestart)
		return
		
	static arg[64], target, zombie_type
	
	read_argv(1, arg, sizeof(arg))
	target = get_user_index(arg)
	
	read_argv(2, arg, sizeof(arg))
	zombie_type = str_to_num(arg)
	
	if(is_user_alive(target))
	{
		set_user_zombie(target, -1, 0, zombie_type, 0)
	} else {
		client_print(id, print_console, "[ZB3] Player %i not valid !!!", target)
	}
}

public cmd_hero(id)
{
	if(!is_user_connected(id))
		return
	if(!g_gamestart)
		return
		
	static arg[64], target, zombie_type
	
	read_argv(1, arg, sizeof(arg))
	target = get_user_index(arg)
	
	read_argv(2, arg, sizeof(arg))
	zombie_type = str_to_num(arg)
	
	if(is_user_alive(target))
	{
		set_user_hero(target, zombie_type == 0 ? SEX_MALE : SEX_FEMALE)
	} else {
		client_print(id, print_console, "[ZB3] Player %i not valid !!!", target)
	}
}

public cmd_free(id)
{
	g_free_gun = !g_free_gun
	client_print(id, print_console, "[ZB3 MAIN] Free = %i", g_free_gun)
}
#endif

public plugin_precache()
{
	// Register Forward
	g_BlockedObj_Forward = register_forward(FM_Spawn, "fw_BlockedObj_Spawn")
	
	// Create Array
	zombie_name = ArrayCreate(64, 1)
	zombie_desc = ArrayCreate(64, 1)
	zombie_sex = ArrayCreate(1, 1)
	zombie_lockcost = ArrayCreate(64, 1)
	zombie_model_host = ArrayCreate(64, 1)
	zombie_model_origin = ArrayCreate(64, 1)
	zombie_gravity = ArrayCreate(1, 1)
	zombie_speed_host = ArrayCreate(1, 1)
	zombie_speed_origin = ArrayCreate(1, 1)
	zombie_knockback = ArrayCreate(1, 1)
	zombie_dmgmulti = ArrayCreate(1, 1)
	zombie_painshock = ArrayCreate(1, 1)
	zombie_sound_death1 = ArrayCreate(64, 1)
	zombie_sound_death2 = ArrayCreate(64, 1)
	zombie_sound_hurt1 = ArrayCreate(64, 1)
	zombie_sound_hurt2 = ArrayCreate(64, 1)
	zombie_clawsmodel_host = ArrayCreate(64, 1)
	zombie_clawsmodel_origin = ArrayCreate(64, 1)
	zombie_claw_distance1 = ArrayCreate(1, 1)
	zombie_claw_distance2 = ArrayCreate(1, 1)	
	
	zombie_sound_heal = ArrayCreate(64, 1)
	zombie_sound_evolution = ArrayCreate(64, 1)	
	sound_zombie_coming = ArrayCreate(64, 1)
	sound_zombie_attack = ArrayCreate(64, 1)
	sound_zombie_hitwall = ArrayCreate(64, 1)
	sound_zombie_swing = ArrayCreate(64, 1)
	
	human_model_male = ArrayCreate(64, 1)
	human_model_female = ArrayCreate(64, 1)
	hero_model_male = ArrayCreate(64, 1)
	hero_model_female = ArrayCreate(64, 1)
	sound_infect_male = ArrayCreate(64, 1)
	sound_infect_female = ArrayCreate(64, 1)
	
	sound_game_start = ArrayCreate(64, 1)
	sound_zombie_coming = ArrayCreate(64, 1)
	sound_zombie_comeback = ArrayCreate(64, 1)
	sound_win_human = ArrayCreate(64, 1)
	sound_win_zombie = ArrayCreate(64, 1)
	
	// Load Configs File
	load_config_file()

	new szBuffer[128], buffer[128], i
	
	// Precache Human Models
	for (i = 0; i < ArraySize(human_model_male); i++)
	{
		ArrayGetString(human_model_male, i, buffer, charsmax(buffer))
		format(szBuffer, sizeof(szBuffer), "models/player/%s/%s.mdl", buffer, buffer)
		
		engfunc(EngFunc_PrecacheModel, szBuffer)
	}	
	for (i = 0; i < ArraySize(human_model_female); i++)
	{
		ArrayGetString(human_model_female, i, buffer, charsmax(buffer))
		format(szBuffer, sizeof(szBuffer), "models/player/%s/%s.mdl", buffer, buffer)
		
		engfunc(EngFunc_PrecacheModel, szBuffer)
	}		
	for (i = 0; i < ArraySize(hero_model_male); i++)
	{
		ArrayGetString(hero_model_male, i, buffer, charsmax(buffer))
		format(szBuffer, sizeof(szBuffer), "models/player/%s/%s.mdl", buffer, buffer)
		
		engfunc(EngFunc_PrecacheModel, szBuffer)
	}	
	for (i = 0; i < ArraySize(hero_model_female); i++)
	{
		ArrayGetString(hero_model_female, i, buffer, charsmax(buffer))
		format(szBuffer, sizeof(szBuffer), "models/player/%s/%s.mdl", buffer, buffer)
		
		engfunc(EngFunc_PrecacheModel, szBuffer)
	}		
	for(i = 0; i < ArraySize(sound_infect_male); i++)
	{
		ArrayGetString(sound_infect_male, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for(i = 0; i < ArraySize(sound_infect_female); i++)
	{
		ArrayGetString(sound_infect_female, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	
	// Precache Sounds
	for (i = 0; i < ArraySize(sound_game_start); i++)
	{
		ArrayGetString(sound_game_start, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}	
	for (i = 0; i < ArraySize(sound_zombie_coming); i++)
	{
		ArrayGetString(sound_zombie_coming, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}		
	for (i = 0; i < ArraySize(sound_zombie_comeback); i++)
	{
		ArrayGetString(sound_zombie_comeback, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}	
	
	for (new i = 1; i <= 10; i++)
	{
		new sound_count[64]
		format(sound_count, sizeof sound_count - 1, sound_game_count, i)
		engfunc(EngFunc_PrecacheSound, sound_count)
	}	
	for (i = 0; i < ArraySize(sound_win_zombie); i++)
	{
		ArrayGetString(sound_win_zombie, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_win_human); i++)
	{
		ArrayGetString(sound_win_human, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}	
	
	for (i = 0; i < ArraySize(sound_zombie_attack); i++)
	{
		ArrayGetString(sound_zombie_attack, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_zombie_hitwall); i++)
	{
		ArrayGetString(sound_zombie_hitwall, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}		
	for (i = 0; i < ArraySize(sound_zombie_swing); i++)
	{
		ArrayGetString(sound_zombie_swing, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}		
	
	// Precache Ambience
	format(buffer, charsmax(buffer), "sound/%s", sound_ambience)
	engfunc(EngFunc_PrecacheGeneric, buffer)
	
	// Precache Human Level-Up
	engfunc(EngFunc_PrecacheSound, sound_human_levelup)
	
	// Weather Handle
	if(g_fog)
	{
		new ent;
		if(!rg_find_ent_by_class(-1, "env_fog", true))
			ent = rg_create_entity("env_fog", true);
		else
			ent = rg_find_ent_by_class(-1, "env_fog", true)

		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", g_fog_density, "env_fog")
			fm_set_kvd(ent, "rendercolor", g_fog_color, "env_fog")
		}
	}

	if(g_rain)
	{
		if(!rg_find_ent_by_class(-1, "env_rain", true))
			rg_create_entity("env_rain", true);
	}

	if(g_snow)
	{
		if(!rg_find_ent_by_class(-1, "env_snow", true))
			rg_create_entity("env_snow", true);
	}
	
	g_respawn_iconid = precache_model(g_respawn_icon)
	precache_model(HealerSpr)
	
	// YaPB detection
	register_cvar("zp_delay", "20", FCVAR_PROTECTED)	
}

public plugin_natives()
{
	// Native
	register_native("zb3_get_mode", "native_get_mode", 1)
	register_native("zb3_load_setting_string", "native_load_setting_string", 1)

	register_native("zb3_infect", "native_infect", 1)
	
	register_native("zb3_get_user_zombie", "native_get_user_zombie", 1)
	register_native("zb3_get_user_zombie_type", "native_get_user_zombie_type", 1)
	register_native("zb3_get_user_zombie_class", "native_get_user_zombie_class", 1)
	
	register_native("zb3_set_user_respawn_time", "native_set_respawn_time", 1)
	register_native("zb3_reset_user_respawn_time", "native_reset_respawn_time", 1)
	
	register_native("zb3_get_user_hero", "native_get_user_hero", 1)
	register_native("zb3_set_lock_hero", "native_set_lock_hero", 1)
	
	register_native("zb3_set_user_sex", "native_set_user_sex", 1)
	register_native("zb3_get_user_sex", "native_get_user_sex", 1)
	
	register_native("zb3_set_user_speed", "native_set_user_speed", 1)
	register_native("zb3_reset_user_speed", "native_reset_user_speed", 1)
	
	register_native("zb3_set_user_nvg", "native_set_nvg", 1)
	register_native("zb3_get_user_nvg", "native_get_nvg", 1)
	
	register_native("zb3_set_user_health", "native_set_user_health", 1)
	register_native("zb3_set_user_light", "native_set_light", 1)
	register_native("zb3_set_user_rendering", "native_set_rendering", 1)
	
	register_native("zb3_get_synchud_id", "native_get_synchud_id", 1)
	register_native("zb3_show_dhud", "native_show_dhud", 1)
	
	register_native("zb3_set_user_level", "native_set_level", 1)
	register_native("zb3_get_user_level", "native_get_level", 1)
	
	register_native("zb3_get_user_starthealth", "native_get_starthealth", 1)
	register_native("zb3_set_user_starthealth", "native_set_starthealth", 1)
	
	register_native("zb3_get_user_startarmor", "native_get_startarmor", 1)
	register_native("zb3_set_user_startarmor", "native_set_startarmor", 1)	
	register_native("zb3_get_user_gravity", "native_get_user_gravity", 1) 
	register_native("zb3_set_user_gravity", "native_set_user_gravity", 1) 
	register_native("zb3_reset_user_gravity", "native_reset_user_gravity", 1) 

	register_native("zb3_get_user_maxhealth", "native_get_maxhealth", 1) 
	register_native("zb3_get_user_maxarmor", "native_get_maxarmor", 1) 

	register_native("zb3_set_user_maxlevel", "native_set_maxlevel", 1)
	register_native("zb3_get_user_maxlevel", "native_get_maxlevel", 1)
	register_native("zb3_reset_user_maxlevel", "native_reset_maxlevel", 1)	
	
	register_native("zb3_set_user_infect_mod", "native_set_infect_multiplier", 1)
	register_native("zb3_reset_user_infect_mod", "native_reset_infect_multiplier", 1)

	register_native("zb3_register_zombie_class", "native_register_zombie_class", 1)
	register_native("zb3_set_zombie_class_data", "native_set_zombie_class_data", 1)
}

public plugin_cfg()
{
	new cfgdir[32]
	get_configsdir(cfgdir, charsmax(cfgdir))
	
	server_cmd("exec %s/%s", cfgdir, CVAR_FILE)
	server_exec()
	
	// Load New Round
	Event_NewRound()
}

public fw_BlockedObj_Spawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED
	
	static Ent_Classname[64]
	pev(ent, pev_classname, Ent_Classname, sizeof(Ent_Classname))
	
	for(new i = 0; i < sizeof g_BlockedObj; i++)
	{
		if (equal(Ent_Classname, g_BlockedObj[i]))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

// ========================== AMXX NATIVES ========================
// ================================================================
public native_get_mode()
{
	return g_gamemode
}
public native_load_setting_string( bool:IsArray, const filename[], const setting_section[], setting_key[], return_string[], string_size, Array:array_handle)
{
	param_convert(2)
	param_convert(3)
	param_convert(4)
	param_convert(5)

	amx_load_setting_string( IsArray, filename, setting_section, setting_key, return_string, string_size, array_handle)
}

public native_infect(id, attacker, origin_zombie, respawn)
{
	if(!is_user_alive(id))
		return
	if(!is_user_connected(attacker))
		attacker = -1

	static weapon; weapon = 0;

	if(is_user_alive(id))
		weapon = get_user_weapon(attacker)
		
	set_user_zombie(id, attacker, weapon, origin_zombie, respawn)
}

public native_get_user_zombie(id)
{
	if(!is_user_connected(id))
		return 0
		
	return g_zombie[id]
}

public native_get_user_zombie_type(id)
{
	if(!is_user_connected(id))
		return 0

	return g_zombie_type[id]
}

public native_get_user_zombie_class(id)
{
	if(!is_user_connected(id))
		return 0
		
	return g_zombie_class[id]
}

public native_set_respawn_time(id, Time)
{
	if(!is_user_connected(id))
		return
		
	g_RespawnTime[id] = Time
}
	
public native_reset_respawn_time(id)
{
	if(!is_user_connected(id))
		return
		
	g_RespawnTime[id] = g_respawn_time
}
	
public native_get_user_hero(id)
{
	if(!is_user_connected(id))
		return 0
		
	return g_hero[id]	
}

public native_set_lock_hero(id, lock)
{
	if(!is_user_connected(id))
		return 0
		
	g_hero_locked[id] = lock
	return 1
}

public native_get_user_sex(id)
{
	return g_zombie[id] ? ArrayGetCell(zombie_sex, g_zombie_class[id]) : g_sex[id]
}

public native_set_user_sex(id, sex)
{
	if(!is_user_connected(id))
		return
		
	g_sex[id] = sex
}

public native_set_user_speed(id, Speed)
{
	if(!is_user_alive(id))
		return
	
	fm_set_user_speed(id, float(Speed))
}

public native_reset_user_speed(id)
{
	if(!is_user_alive(id))
		return	
		
	fm_reset_user_speed(id)
}

public native_set_nvg(id, on, auto_on, give, remove)
{
	if(!is_user_connected(id))
		return
		
	if(give) g_HasNvg[id] = 1
	if(remove) g_HasNvg[id] = 0
	
	set_user_nightvision(id, on, 0, 0)
}

public native_get_nvg(id)
{
	if(!is_user_connected(id))
		return 0
		
	return g_nvg[id]
}

public native_set_user_health(id, Health)
{
	if(!is_user_connected(id))
		return
		
	fm_set_user_health(id, Health)
}

public native_set_light(id, const light[])
{
	if(!is_user_connected(id))
		return
		
	param_convert(2)
	set_player_light(id, light)
}

public native_set_rendering(id, fx, r, g, b, render, amount)
{
	if(!is_user_connected(id))
		return	
		
	fm_set_rendering(id, fx, r, g, b, render, amount)
}

public native_get_synchud_id(hudtype)
{
	return g_SyncHud[hudtype]
}

public native_show_dhud(id, R, G, B, Float:X, Float:Y, Float:TimeLive, const Text[])
{
	if(!is_user_connected(id))
		return
		
	param_convert(8)
		
	set_dhudmessage(R, G, B, X, Y, 0, TimeLive, TimeLive)
	show_dhudmessage(id, Text)	
}

public native_get_level(id)
{
	if(!is_user_connected(id))
		return 0
		
	return g_level[id]
}

public native_set_level(id, level)
{
	if(!is_user_connected(id))
		return
		
	g_level[id] = level
}

public native_set_starthealth(id, Health)
{
	if(!is_user_connected(id))
		return
		
	g_StartHealth[id] = Health
}

public native_get_starthealth(id)
{
	if(!is_user_connected(id))
		return 0
		
	return g_StartHealth[id]
}

public native_set_startarmor(id, Health)
{
	if(!is_user_connected(id))
		return
		
	g_StartArmor[id] = Health
}

public native_get_startarmor(id)
{
	if(!is_user_connected(id))
		return 0
		
	return g_StartArmor[id]
}

public native_get_user_gravity(id)
{
	if(!is_user_connected(id))
		return 0
		
	if(g_zombie[id]) return ArrayGetCell(zombie_gravity, g_zombie_class[id])
	else return pev(id, pev_gravity )
}
public native_set_user_gravity(id, Float:fGravity)
{
	if(!is_user_connected(id))
		return 
	
	set_pev(id, pev_gravity, fGravity )
}
public native_reset_user_gravity(id)
{
	if(!is_user_connected(id))
		return 

	if(g_zombie[id]) set_pev(id, pev_gravity, ArrayGetCell(zombie_gravity, g_zombie_class[id]) ) 
	else set_pev(id, pev_gravity, 1.0 )
}

public native_get_maxhealth(id)
{
	if(!is_user_connected(id))
		return 0

	static zombie_maxhealth
	zombie_maxhealth = g_level[id] > 2 ? zombie_level3_health : zombie_level2_health
	
	return g_zombie[id] ? zombie_maxhealth : human_health;
}

public native_get_maxarmor(id)
{
	if(!is_user_connected(id))
		return 0
	static zombie_maxarmor
	zombie_maxarmor = g_level[id] > 2 ? zombie_level3_armor  : zombie_level2_armor
	return g_zombie[id] ? zombie_maxarmor : human_armor;
}

public native_set_infect_multiplier(id, Float:multi)
{
	if(!is_user_connected(id))
		return
		
	g_flinfect_multi[id] = multi
}
	
public native_reset_infect_multiplier(id)
{
	if(!is_user_connected(id))
		return
		
	g_flinfect_multi[id] = 0.5
}

public native_get_maxlevel(id)
{
	if(!is_user_connected(id))
		return 0
		
	return g_iMaxLevel[id]
}

public native_set_maxlevel(id, maxlevel)
{
	if(!is_user_connected(id))
		return
		
	g_iMaxLevel[id] = maxlevel
}

public native_reset_maxlevel(id)
{
	if(!is_user_connected(id))
		return 
		
	g_iMaxLevel[id] = 10;
}

public native_register_zombie_class(const Name[], const Desc[], Sex, LockCost, Float:Gravity, 
Float:SpeedHost, Float:SpeedOrigin, Float:KnockBack, Float:DmgMulti, Float:PainShock, Float:ClawsDistance1, Float:ClawsDistance2)
{
	param_convert(1)
	param_convert(2)
	
	ArrayPushString(zombie_name, Name)
	ArrayPushString(zombie_desc, Desc)
	ArrayPushCell(zombie_sex, Sex)
	ArrayPushCell(zombie_lockcost, LockCost)
	
	ArrayPushCell(zombie_gravity, Gravity)
	ArrayPushCell(zombie_speed_host, SpeedHost)
	ArrayPushCell(zombie_speed_origin, SpeedOrigin)
	ArrayPushCell(zombie_knockback, KnockBack)
	ArrayPushCell(zombie_painshock, PainShock)
	ArrayPushCell(zombie_dmgmulti, DmgMulti)

	ArrayPushCell(zombie_claw_distance1, ClawsDistance1)
	ArrayPushCell(zombie_claw_distance2, ClawsDistance2)

	g_zombieclass_i++
	return g_zombieclass_i - 1
}

public native_set_zombie_class_data(const ModelHost[], const ModelOrigin[], const ClawsModel_Host[], const ClawsModel_Origin[],
const DeathSound1[], const DeathSound2[], const HurtSound1[], const HurtSound2[], const HealSound[], const EvolSound[])
{
	param_convert(1)
	param_convert(2)
	param_convert(3)
	param_convert(4)
	param_convert(5)
	param_convert(6)
	param_convert(7)
	param_convert(8)
	param_convert(9)
	param_convert(10)
	
	static Buffer[128]
	
	ArrayPushString(zombie_model_host, ModelHost)
	formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", ModelHost, ModelHost)
	engfunc(EngFunc_PrecacheModel, Buffer)
	
	ArrayPushString(zombie_model_origin, ModelOrigin)
	formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", ModelOrigin, ModelOrigin)
	engfunc(EngFunc_PrecacheModel, Buffer)	
	
	ArrayPushString(zombie_clawsmodel_host, ClawsModel_Host)
	formatex(Buffer, sizeof(Buffer), "models/zombie_thehero/%s", ClawsModel_Host)
	engfunc(EngFunc_PrecacheModel, Buffer)	
	
	ArrayPushString(zombie_clawsmodel_origin, ClawsModel_Origin)	
	formatex(Buffer, sizeof(Buffer), "models/zombie_thehero/%s", ClawsModel_Origin)
	engfunc(EngFunc_PrecacheModel, Buffer)	
		
	ArrayPushString(zombie_sound_death1, DeathSound1)
	engfunc(EngFunc_PrecacheSound, DeathSound1)
	
	ArrayPushString(zombie_sound_death2, DeathSound2)
	engfunc(EngFunc_PrecacheSound, DeathSound2)
	
	ArrayPushString(zombie_sound_hurt1, HurtSound1)
	engfunc(EngFunc_PrecacheSound, HurtSound1)
	
	ArrayPushString(zombie_sound_hurt2, HurtSound2)	
	engfunc(EngFunc_PrecacheSound, HurtSound2)
	
	ArrayPushString(zombie_sound_heal, HealSound)
	engfunc(EngFunc_PrecacheSound, HealSound)
	
	ArrayPushString(zombie_sound_evolution, EvolSound)
	engfunc(EngFunc_PrecacheSound, EvolSound)
}

// ========================= AMXX FORWARDS ========================
// ================================================================
public Fw_RG_CBasePlayer_GetIntoGame(id)
{
	if(!is_user_connected(id))
		return
		
	reset_player(id, 1, 0)
	gameplay_check()
}

public fw_disconnect(id)
{
	remove_game_task_player(id)
	gameplay_check()
}

// ========================= GAME EVENTS ==========================
// ================================================================
public Event_NewRound()
{
	if(GetTotalPlayer(TEAM_ALL, 0) < 2)
	{
		g_gamestatus = STATUS_WAITING
		return
	}	

	g_firstzombie = g_firsthuman = 0
	g_gamestatus = STATUS_FREEZE

	remove_game_task()
	
	ExecuteForward(g_Forwards[FWD_GAME_START], g_fwResult, GAMESTART_NEWROUND)
}

public Fw_RG_CSGameRules_OnRoundFreezeEnd()
{
	if(g_gamestatus != STATUS_FREEZE)
		return
		
	static GameSound[128]
	ArrayGetString(sound_game_start, get_random_array(sound_game_start), GameSound, sizeof(GameSound))
	PlaySound(0, GameSound)
	
	g_roundstart_time = get_gametime()
	g_gamestatus = STATUS_COUNTDOWN
	
	ExecuteForward(g_Forwards[FWD_GAME_START], g_fwResult, GAMESTART_COUNTING)
}

// public Event_RoundEnd()
public Fw_RG_RoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
{
	if((event != ROUND_GAME_RESTART && event != ROUND_END_DRAW && event != ROUND_GAME_OVER))
	{
		SetHookChainReturn(ATYPE_BOOL, false)
		return HC_SUPERCEDE;
	}
	
	static iZombie
	g_gamestatus = STATUS_ENDROUND
	
	// Update Score
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue

		iZombie = g_zombie[i]

		UpdateFrags(i, -1, iZombie ? 1 : 2, -1, 1)
	}

	SetHookChainReturn(ATYPE_BOOL, true)
	return HC_CONTINUE;
}

public Event_GameRestart()
{
	g_gamestatus = STATUS_ENDROUND
}

public Event_CheckWeapon(id)
{
	if (!is_user_alive(id)) 
		return
	if(!g_zombie[id])
		return
	
	static current_weapon; current_weapon = get_user_weapon(id)
	static ViewModel[64], Buffer[128]

	ArrayGetString(g_zombie_type[id] == ZOMBIE_HOST ? zombie_clawsmodel_host : zombie_clawsmodel_origin, g_zombie_class[id], ViewModel, sizeof(ViewModel))
	formatex(Buffer, sizeof(Buffer), "models/zombie_thehero/%s", ViewModel)

	switch(current_weapon)
	{
		case CSW_HEGRENADE,CSW_FLASHBANG,CSW_SMOKEGRENADE: return
		case CSW_KNIFE: { set_pev(id, pev_viewmodel2, Buffer); set_pev(id, pev_weaponmodel2, "") ;}
		default: { fm_reset_user_weapon(id); return; }
	}
}

public Fw_RG_CSGameRules_SendDeathMessage(const attacker, const victim, const assister, const inflictor, const killerWeaponName[], const DeathMessageFlags:iDeathMessageFlags, const KillRarity:iRarityOfKill)
{
	static headshot;
	headshot = iRarityOfKill == KILLRARITY_HEADSHOT
	set_user_nightvision(victim, 0, 1, 1)

	if(!is_user_alive(victim) && g_gamemode == MODE_HERO)
	{
		if(g_zombie[victim]) // Zombie Death
		{
			UpdateFrags(attacker, victim, headshot ? 3 : 0, headshot ? 3 : 0, headshot ? 1 : 1)

			if(headshot) client_print(victim, print_center, "%L", LANG_OFFICIAL, "ZOMBIE_NORESPAWN")
			else set_member(victim, m_flRespawnPending, get_gametime() + float(g_RespawnTime[victim]) + 1.0);

			if(is_user_connected(attacker) && !g_zombie[attacker]) 
				UpdateLevelTeamHuman()
		}
	}
	
	ExecuteForward(g_Forwards[FWD_USER_DEAD], g_fwResult, victim, attacker, headshot)
	gameplay_check()
}

public Message_StatusIcon(msg_id, msg_dest, msg_entity)
{
	static szMsg[8];
	get_msg_arg_string(2, szMsg ,7)
	
	if(equal(szMsg, "buyzone") && get_msg_arg_int(1))
	{
		set_pdata_int(msg_entity, 235, get_pdata_int(msg_entity, 235) & ~(1<<0))
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public Message_ClCorpse()
{
	if(get_member(get_msg_arg_int(12), m_flRespawnPending)) return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public Message_Health(msg_id, msg_dest, id)
{
	if(!is_user_alive(id))
		return
	// Get player's health
	static health
	health = get_user_health(id)
	
	//// Don't bother
	if(health < 1) 
		return
	
	static Float:NewHealth, RealHealth, Health
	
	NewHealth = float(health) * (g_zombie[id] ? 0.01 : 0.1)
	RealHealth = floatround(NewHealth)
	Health = clamp(RealHealth, 1, 255)

	set_msg_arg_int(1, get_msg_argtype(1), Health)
}

public Message_Battery(msg_id, msg_dest, id)
{
	if(!is_user_alive(id) || !g_zombie[id])
		return
	// Get player's armor
	static armor
	armor = rg_get_user_armor(id)
	
	//// Don't bother
	if(armor < 1) 
		return
	
	static Float:NewArmor, RealArmor, ArmorP
	
	NewArmor = float(armor) * 0.1
	RealArmor = floatround(NewArmor)
	ArmorP = clamp(RealArmor, 1, 999)

	set_msg_arg_int(1, get_msg_argtype(1), ArmorP)
}
public cmd_nightvision(id)
{
	if (!is_user_alive(id) || !g_HasNvg[id]) return PLUGIN_HANDLED;

	if (!g_nvg[id])
	{
		set_user_nightvision(id, 1, 0, 0)
	}
	else
	{
		set_user_nightvision(id, 0, 0, 0)
	}
	
	return PLUGIN_HANDLED;
}

public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(g_hero[id] || g_zombie[id] && g_zombie_type[id] == ZOMBIE_HOST && g_gamemode == MODE_MUTATION)
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public Time_Change() 
{
	ExecuteForward(g_Forwards[FWD_TIME_CHANGE], g_fwResult)

	static i, alive, zombie, Float:gametime, Float:respawntime;
	gametime = get_gametime()

	switch(g_gamestatus)
	{
		case STATUS_COUNTDOWN: handle_countdown(gametime)
		case STATUS_PLAY:  handle_round_timeout(gametime)
	}
	
	if(g_gamemode <= MODE_ORIGINAL)
		return

	for(i = 1; i <= g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		
		alive = is_user_alive(i)
		zombie = g_zombie[i]
		respawntime = get_member(i, m_flRespawnPending)

		if(zombie && (g_zombie_type[i] == ZOMBIE_ORIGIN && g_gamemode == MODE_MUTATION) || g_gamemode == MODE_HERO)
			ExecuteForward(g_Forwards[FWD_SKILL_HUD], g_fwResult, i)
		
		if(alive && g_gamemode == MODE_HERO )
			show_evolution_hud(i, zombie)

		if(!alive && respawntime)
			handle_respawn_countdown(i, gametime, respawntime)
	}

}
// ===================== HAM & FM FORWARDS ========================
// ================================================================
public Fw_RG_CSGameRules_PlayerSpawn_Post(id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		return

	if(g_zombie[id] && g_gamestatus >= STATUS_PLAY)
	{
		set_user_zombie(id, -1, 0, g_zombie_type[id] == ZOMBIE_ORIGIN ? 1 : 0, 1)
		do_random_spawn(id, MAX_RETRY / 2)
		
		ExecuteForward(g_Forwards[FWD_USER_SPAWN], g_fwResult, id)

		return
	}

	if(get_member(id, m_iTeam) == TEAM_TERRORIST)
		set_team(id, TEAM_HUMAN)
	
	// Reset this Player
	reset_player(id, 0, 0)
	
	// Set Spawn
	do_random_spawn(id, MAX_RETRY)
	
	// Set Human
	// set_team(id, TEAM_HUMAN)
	set_human_model(id)
	fm_set_rendering(id)
	
	fm_set_user_health(id, human_health)
	fm_cs_set_user_armor(id, human_armor, ARMOR_KEVLAR)
	
	fm_reset_user_speed(id)
	set_user_nightvision(id, 0, 1, 1)
	
	fm_reset_user_weapon(id)
	StopSound(id)
	ExecuteForward(g_Forwards[FWD_USER_SPAWN], g_fwResult, id)

	return
}
public Fw_RG_CBasePlayer_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(g_gamestatus != STATUS_PLAY)
	{
		SetHookChainReturn(ATYPE_INTEGER, false)
		return HC_SUPERCEDE;
	}

	SetHookChainReturn(ATYPE_INTEGER, true)
	return HC_CONTINUE;
}

public Fw_RG_CBasePlayer_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(attacker))
	{
		SetHookChainReturn(ATYPE_INTEGER, true)
		return HC_CONTINUE;
	}
	if(fm_cs_get_user_team(attacker) == fm_cs_get_user_team(victim) || g_gamestatus != STATUS_PLAY)
	{
		SetHookChainReturn(ATYPE_INTEGER, false)
		return HC_SUPERCEDE;
	}

	if(g_zombie[attacker] && !g_zombie[victim])
	{
		static ent;
		ent = inflictor;
		rg_find_ent_by_owner(ent, "weapon_knife", attacker);

		if(get_entvar(ent, var_impulse) == KNIFE_IMPULSE)
		{
			set_user_zombie(victim, attacker, ent, false, false)
			SetHookChainReturn(ATYPE_INTEGER, false)
			return HC_SUPERCEDE;
		}

		SetHookChainReturn(ATYPE_INTEGER, true)
		return HC_CONTINUE;
	}

	static Float:zb_class_dmgmulti; zb_class_dmgmulti = ArrayGetCell(zombie_dmgmulti, g_zombie_class[victim])

	if (zb_class_dmgmulti > 0.0)
		damage *= zb_class_dmgmulti
	if (damagebits & DMG_GRENADE)
		damage *= grenade_default_power
	if (damagebits & DMG_BULLET && g_gamemode == MODE_HERO)
		damage *= 1.0 + (g_level[attacker] * 0.1)

	// SetHamParamFloat(4, damage)
	SetHookChainArg(4, ATYPE_FLOAT, damage);

	fm_cs_set_user_money(attacker, fm_cs_get_user_money(attacker) + floatround(damage) / 8, true)
	fm_cs_set_user_money(victim, fm_cs_get_user_money(victim) + floatround(damage) / 16, true)

	switch(g_gamemode)
	{
		case MODE_MUTATION: if(g_restore_health[victim]) g_restore_health[victim] = 0
		case MODE_HERO:
		{
			if(g_restore_health[victim]) g_restore_health[victim] = 0
			switch(g_zombie_type[attacker])
			{
				case ZOMBIE_HOST: handle_evolution(victim, damage * 0.001) 
				case ZOMBIE_ORIGIN: handle_evolution(victim, damage * 0.0005)
			}
		}
	}

	SetHookChainReturn(ATYPE_INTEGER, true)
	return HC_CONTINUE;
}

public Fw_RG_CBasePlayer_TakeDamageImpulse(const this, attacker, Float:flKnockbackForce, Float:flVelModifier)
{
	static Float:classzb_knockback; classzb_knockback = ArrayGetCell(zombie_knockback, g_zombie_class[this])
	static Float:zb_class_painshock; zb_class_painshock = ArrayGetCell(zombie_painshock, g_zombie_class[this])

	SetHookChainArg(3, ATYPE_FLOAT, flKnockbackForce * classzb_knockback);
	SetHookChainArg(4, ATYPE_FLOAT, flVelModifier * zb_class_painshock);
}

public Fw_RG_CBasePlayer_ResetMaxSpeed(id)
{
	if( g_zombie[id] || g_hero[id] )
		return HC_SUPERCEDE;
	
	return HC_CONTINUE;
}

public Fw_RG_CBasePlayer_AddPlayerItem(const this, const pItem)
{
	if(g_zombie[this])
	{
		new iWpnId = rg_get_iteminfo(pItem, ItemInfo_iId)
		if ( iWpnId == CSW_KNIFE || iWpnId == CSW_FLASHBANG || iWpnId == CSW_HEGRENADE || iWpnId == CSW_SMOKEGRENADE )
		{
			SetHookChainReturn(ATYPE_INTEGER, true);
			return HC_CONTINUE;
		}

		SetHookChainReturn(ATYPE_INTEGER, false);
		return HC_SUPERCEDE;
	}

	SetHookChainReturn(ATYPE_INTEGER, true);
	return HC_CONTINUE;
}

public set_team(id, {PlayerTeams,_}:team)
{
	if(!is_user_connected(id))
		return
	
	switch(team)
	{
		case TEAM_HUMAN: if(fm_cs_get_user_team(id) != TEAM_CT) fm_cs_set_user_team(id, TEAM_CT)
		case TEAM_ZOMBIE: if(fm_cs_get_user_team(id) != TEAM_TERRORIST) fm_cs_set_user_team(id, TEAM_TERRORIST)
	}
}

public fw_Touch(ent, id)
{
	if(!pev_valid(ent))
		return FMRES_IGNORED
	if (!is_user_alive(id))
		return FMRES_IGNORED
	
	if(g_zombie[id] || g_hero[id])
	{
		static ClassName[32]
		pev(ent, pev_classname, ClassName, sizeof(ClassName))	
		
		if (equal(ClassName, "weaponbox") || equal(ClassName, "armoury_entity") || equal(ClassName, "weapon_shield"))
			return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (!is_user_alive(id) || !g_zombie[id])
		return FMRES_IGNORED
	if (strncmp(sample,"weapons/knife_", true) != 0)
		return FMRES_IGNORED;
	
	static sound[64], attack_type;
	attack_type = 0;

	// Zombie Attack
	switch(sample[17])
	{
		case 'w': attack_type = 1
		case '1'..'4': attack_type = 2
		case 'b': attack_type = 2
		case 's': attack_type = 3
		default: attack_type = 0
	}

	if (attack_type)
	{
		switch(attack_type)
		{
			case 1: ArrayGetString(sound_zombie_hitwall, get_random_array(sound_zombie_hitwall), sound, charsmax(sound))
			case 2: ArrayGetString(sound_zombie_attack, get_random_array(sound_zombie_attack), sound, charsmax(sound))
			default: ArrayGetString(sound_zombie_swing, get_random_array(sound_zombie_swing), sound, charsmax(sound))
		}
		emit_sound(id, channel, sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public Fw_RG_CBasePlayer_Pain(id)
{
	if (!g_zombie[id])
		return HC_CONTINUE;

	static sound[64]
	ArrayGetString(random_num(1, 2) == 1 ? zombie_sound_hurt1 : zombie_sound_hurt2, g_zombie_class[id], sound, charsmax(sound))

	EmitSound(id, CHAN_BODY, sound)
	return HC_SUPERCEDE;
}

public Fw_RG_CBasePlayer_DeathSound(id, lastHitGroup, bool:hasArmour)
{
	if (!g_zombie[id])
		return HC_CONTINUE;

	static sound[64]
	ArrayGetString(random_num(1, 2) == 1 ? zombie_sound_death1 : zombie_sound_death2, g_zombie_class[id], sound, charsmax(sound))

	EmitSound(id, CHAN_BODY, sound)
	return HC_SUPERCEDE;
}

public Fw_RG_CBasePlayer_PreThink(id)
{
	if(g_UsingCustomSpeed[id] && pev(id, pev_maxspeed) != g_PlayerMaxSpeed[id])
		set_pev(id, pev_maxspeed, g_PlayerMaxSpeed[id])
	if(g_zombie[id]) zombie_restore_health(id)
}

public fw_Block(id)
{
	return FMRES_SUPERCEDE;
}
// ======================== MAIN PUBLIC ===========================
// ================================================================	
public show_evolution_hud(id, is_zombie)
{
	if(is_user_bot(id))
		return;

	static Float:f , i, DamagePercent, level_color[3], PowerUp[32], PowerDown[32], FullText[88]

	DamagePercent = 0
	PowerUp[0] = PowerDown[0] = FullText[0] = '^0'

	for(i = 0; i < sizeof(level_color); i++)
		level_color[i] = get_color_level(id, i)
	
	// Show Hud
	set_dhudmessage(level_color[0], level_color[1], level_color[2], MAIN_HUD_X, 0.83, 0, 1.5, 1.5)

	switch(is_zombie)
	{
	case true:
	{
		DamagePercent = g_level[id]
		
		for(f = 0.0; f < g_iEvolution[id]; f += 1.0)
			formatex(PowerUp, sizeof(PowerUp), "%s|", PowerUp)
		for(f = 10.0; f > g_iEvolution[id]; f -= 1.0)
			formatex(PowerDown, sizeof(PowerDown), "%s_", PowerDown)

		formatex(FullText, sizeof(FullText), "%L", LANG_PLAYER, "ZOMBIE_EVOL_HUD", DamagePercent, PowerUp, PowerDown)
	}
	case false:
	{
		DamagePercent = 100 + (g_level[id] * 10)

		for(i = 0; i < g_level[id]; i++)
			formatex(PowerUp, sizeof(PowerUp), "%s|", PowerUp)
		for(i = g_iMaxLevel[id]; i > g_level[id]; i--)
			formatex(PowerDown, sizeof(PowerDown), "%s_", PowerDown)

		formatex(FullText, sizeof(FullText), "%L", LANG_PLAYER, "HUMAN_EVOL_HUD", DamagePercent, PowerUp, PowerDown)
	}
	}
	
	ShowSyncHudMsg(id, g_SyncHud[SYNCHUD_ZBHM_SKILL3], FullText)
}

public UpdateLevelZombie(id)
{
	if(!is_user_connected(id))
		return
	if(g_level[id] > 2 || g_level[id] < 1)
		return
	
	g_StartHealth[id] = g_level[id] == 1 ? zombie_level2_health :  zombie_level3_health
	g_StartArmor[id] = g_level[id] == 1 ? zombie_level2_armor :  zombie_level3_armor

	g_iEvolution[id] = g_level[id] < 3 ? 0.0 : 10.0
	g_level[id]++ //= g_level[id] == 1 ? 2 : 3

	g_zombie_type[id] = ZOMBIE_ORIGIN
	
	// Update Health & Armor
	fm_set_user_health(id, g_StartHealth[id])
	fm_cs_set_user_armor(id, g_StartArmor[id], ARMOR_KEVLAR)
	
	// Update Speed
	new Float:speed = ArrayGetCell(zombie_speed_origin, g_zombie_class[id])
	fm_set_user_speed(id, speed)
	
	// Update Player Model
	new model[64]
	ArrayGetString(zombie_model_origin, g_zombie_class[id], model, charsmax(model))
	
	set_model(id, model)
	
	// Play Evolution Sound
	new sound[64]
	ArrayGetString(zombie_sound_evolution, g_zombie_class[id], sound, charsmax(sound))
	EmitSound(id, CHAN_AUTO, sound)
	
	// Reset Claws
	Event_CheckWeapon(id)
	set_weapon_anim(id, 3)
	
	// Show Hud
	new szText[128]
	format(szText, charsmax(szText), "%L", LANG_PLAYER, g_level[id] > 2 ? "NOTICE_ZOMBIE_LEVELUP3" : "NOTICE_ZOMBIE_LEVELUP2")

	set_dhudmessage(0, 160, 0, MAIN_HUD_X, MAIN_HUD_Y_BOTTOM , 2, 1.0, 3.0, 0.005 , 0.1)
	show_dhudmessage(id, szText)
	
	if(g_gamemode == MODE_MUTATION)
		SendScenarioMsg(id, g_evo_need_infect[g_zombie_type[id]] - floatround(g_iEvolution[id]))

	// Exec Forward
	ExecuteForward(g_Forwards[FWD_USER_EVOLUTION], g_fwResult, id, g_level[id])
}

public UpdateLevelTeamHuman()
{
	if(g_gamestatus != STATUS_PLAY)
		return
		
	for (new id = 1; id <= g_MaxPlayers; id++)
		delay_UpdateLevelHuman(id)
}

public delay_UpdateLevelHuman(id)
{
	if (g_level[id] >= g_iMaxLevel[id] || !is_user_alive(id) || g_zombie[id])
		return

	g_level[id]++
	
	new szText[64]
	new Color[3]
	Color[0] = get_color_level(id, 0)
	Color[1] = get_color_level(id, 1)
	Color[2] = get_color_level(id, 2)		
	
	fm_set_rendering(id, kRenderFxGlowShell, get_color_level(id, 0), get_color_level(id, 1), get_color_level(id, 2), kRenderNormal, 0)
	
	PlaySound(id, sound_human_levelup)
	format(szText, charsmax(szText), "%L", LANG_PLAYER, "NOTICE_HUMAN_LEVELUP", g_level[id])

	set_dhudmessage(200, 200, 0, MAIN_HUD_X, MAIN_HUD_Y, 0, 3.0, 3.0)
	show_dhudmessage(id, szText)
}

public zombie_restore_health(id)
{
	if(!is_user_alive(id)) 
		return
	if (!g_zombie[id]) 
		return
	
	static Float:velocity[3]
	pev(id, pev_velocity, velocity)
	
	switch( velocity[0] == 0 && velocity[1] == 0 && velocity[2] == 0 )
	{
		case true: if (!g_restore_health[id]) g_restore_health[id] = get_systime()
		case false: g_restore_health[id] = 0
	}

	if(!g_restore_health[id])
		return
	
	new rh_time = get_systime() - g_restore_health[id]
	if (rh_time == Restore_Health_Time + 1 && get_user_health(id) < g_StartHealth[id])
	{
		// get health add
		new health_add
		if (g_level[id] > 1) health_add = Restore_Amount_Origin
		else health_add = Restore_Amount_Host

		// get health new
		new health_new = get_user_health(id)+health_add
		health_new = min(health_new, g_StartHealth[id])
			
		// set health
		set_pev(id, pev_health, float(health_new))
		g_restore_health[id] += 1
			
		// play sound heal
		new sound_heal[64]
		ArrayGetString(zombie_sound_heal, g_zombie_class[id], sound_heal, charsmax(sound_heal))
		EmitSound(id, CHAN_VOICE, sound_heal)
		zb3_set_head_attachment(id, HealerSpr, 1.0, 1.0, 0.5, 19)
	}
}
		
public bool:Dead_Effect(id, countdown)
{		
	if(countdown != g_RespawnTime[id] + 1)
		return false;

	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(g_respawn_iconid)
	write_byte(10)
	write_byte(20)
	write_byte(14)
	message_end()

	return true;
}

public gameplay_check()
{
	switch(g_gamestatus)
	{
		case STATUS_WAITING:
		{
			if(GetTotalPlayer(TEAM_START, 0) >= 2)
			{
				g_gamestatus = STATUS_PLAY;
				TerminateRound(TEAM_START);
				return;
			}
		}
		case STATUS_PLAY:
		{
			if(GetTotalPlayer(TEAM_HUMAN, 1) <= 0)
				TerminateRound(TEAM_ZOMBIE)
			else if(GetTotalPlayer(TEAM_ZOMBIE, 1) <= 0)
				if(!GetRespawningCount()) TerminateRound(TEAM_HUMAN)
		}
		default:
		{
			if(GetTotalPlayer(TEAM_ALL, 0) < 2)
			{
				g_gamestatus = STATUS_WAITING;
				return;
			}
		}
	}
}

public set_zombie_nvg(id, auto_on)
{
	if(!is_user_connected(id))
		return
		
	g_HasNvg[id] = 1
	if(auto_on)
		set_user_nightvision(id, 1, 1, 0)
}

public set_user_nightvision(id, on, nosound, ignored_hadnvg)
{
	if (!is_user_connected(id)) 
		return PLUGIN_HANDLED
	if(!ignored_hadnvg)
	{
		if(!g_HasNvg[id])
			return PLUGIN_HANDLED
	}

	g_nvg[id] = on
	
	if(!nosound)
		PlaySound(id, sound_nvg[on >= 1 ? 1 : 0])
	set_user_nvision(id)
	
	return 0
}

public set_user_nvision(id)
{	
	if (!is_user_connected(id)) 
		return

	new alpha
	if(g_nvg[id]) alpha = g_NvgAlpha
	else alpha = 0
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte(g_NvgColor[g_zombie[id] ? TEAM_ZOMBIE : TEAM_HUMAN][0]) // r
	write_byte(g_NvgColor[g_zombie[id] ? TEAM_ZOMBIE : TEAM_HUMAN][1]) // g
	write_byte(g_NvgColor[g_zombie[id] ? TEAM_ZOMBIE : TEAM_HUMAN][2]) // b
	write_byte(alpha) // alpha
	message_end()
	
	if(!g_zombie[id])
	{
		if(g_nvg[id])
		{
			set_task(0.5, "change_human_nvgcolor", id+TASK_NVGCHANGE)
		} else {
			remove_task(id+TASK_NVGCHANGE)
		}
	}

	/*
	LightStyle outside a-z (i.e 0) set fullbright for single player.
	exactly what CSO Zombie NVG do but quite buggy in 1.6,
	since embedded map light entity is not disabled.
	alternatively use LightStyle "z" for safer and closer to style "0".
	*/

	set_player_light(id, g_nvg[id] ? "z" : g_light)
}

public change_human_nvgcolor(id)
{
	id -= TASK_NVGCHANGE
	
	if (!is_user_alive(id)) 
		return
	if(!g_nvg[id] || g_zombie[id])
	{
		remove_task(id+TASK_NVGCHANGE)
		return
	}
	
	new alpha
	if(g_nvg[id]) alpha = random_num(g_NvgAlpha - 10, g_NvgAlpha + 10)
	else alpha = 0
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte(g_NvgColor[g_zombie[id] ? TEAM_ZOMBIE : TEAM_HUMAN][0]) // r
	write_byte(g_NvgColor[g_zombie[id] ? TEAM_ZOMBIE : TEAM_HUMAN][1]) // g
	write_byte(g_NvgColor[g_zombie[id] ? TEAM_ZOMBIE : TEAM_HUMAN][2]) // b
	write_byte(alpha) // alpha
	message_end()	
	
	set_task(random_float(0.5, 1.0), "change_human_nvgcolor", id+TASK_NVGCHANGE)
}

public set_player_light(id, const LightStyle[])
{
	if(!is_user_connected(id))
		return
	
	if(id != 0)
		message_begin(MSG_ONE, SVC_LIGHTSTYLE, .player = id)
	else
		message_begin(MSG_BROADCAST, SVC_LIGHTSTYLE)

	write_byte(0)
	write_string(LightStyle)
	message_end()
}

public remove_game_task()
{	
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		remove_task(i+TASK_CHOOSECLASS)
		remove_task(i+TASK_NVGCHANGE)
	}
}

public remove_game_task_player(id)
{
	remove_task(id+TASK_CHOOSECLASS)
	remove_task(id+TASK_NVGCHANGE)
}

public start_game_now()
{
	// Set Game Start
	g_gamestatus = STATUS_PLAY

	get_random_zombie()
	if(g_gamemode == MODE_HERO) get_random_hero()

	set_task(3.0, "play_ambience_sound")
	ExecuteForward(g_Forwards[FWD_GAME_START], g_fwResult, GAMESTART_ZOMBIEAPPEAR)	
}

public play_ambience_sound()
{
	PlaySound(0, sound_ambience)	
}

public get_random_zombie()
{
	// Pick a Random Zombie & Hero
	static Required_Zombie, Total_Player

	Total_Player = GetTotalPlayer(TEAM_HUMAN, 1)
	Required_Zombie = floatround(float(Total_Player + 1) / 8, floatround_ceil)

	// used for consistent first zombie health
	g_firstzombie = Required_Zombie
	g_firsthuman  = Total_Player - Required_Zombie
	
	// Get and Set Zombie
	while(GetTotalPlayer(TEAM_ZOMBIE, 1) < Required_Zombie)
		set_user_zombie(GetRandomAlive(), -1, 0, 1, 0)
}
public get_random_hero()
{
	static i, id, Total_Player, Required_Hero, szName[32], szHeroNames[64], FullText[64];
	szName[0] = szHeroNames[0] = FullText[0] = '^0';

	Total_Player = GetTotalPlayer(TEAM_HUMAN, 1)
	Required_Hero = Total_Player / 9 // max 2 heroes

	// Get and Set Hero
	for(i = 0; i < Required_Hero; i++)
	{
		id = GetRandomAlive()

		set_user_hero(id, g_sex[id])
		get_user_name(id, szName, sizeof(szName))

		if(i > 0)
			strcat(szHeroNames, ", ", sizeof(szHeroNames))

		strcat(szHeroNames, szName, sizeof(szHeroNames))
	}

	if(Required_Hero)
	{
		formatex(FullText, sizeof(FullText), "%L", LANG_OFFICIAL, "NOTICE_HERO_FOR_ALL", szHeroNames)

		for(i = 1; i <= g_MaxPlayers; i++)
		{
			if(!is_user_connected(i) || !is_user_alive(i) || g_zombie[i] || g_hero[i])
				continue

			client_print(i, print_center, FullText)
		}
	}
}
public set_user_hero(id, player_sex)
{
	if(!is_user_alive(id) || g_gamemode != MODE_HERO || g_hero[id] || g_zombie[id])
		return 
	
	rg_drop_items_by_slot(id, InventorySlotType:CS_WEAPONSLOT_PRIMARY)
	rg_drop_items_by_slot(id, InventorySlotType:CS_WEAPONSLOT_SECONDARY)
	
	// Set Var
	g_hero_locked[id] = 0
	g_hero[id] = player_sex == SEX_MALE ? HERO_ANDREY : HERO_KATE
	
	// Give NVG
	g_HasNvg[id] = 1
	set_user_nightvision(id, 0, 1, 0)
	
	set_scoreboard_attrib(id, 2)
	
	// Set Model
	static Model[64]
	
	if(g_hero[id] == HERO_ANDREY)
		ArrayGetString(hero_model_male, get_random_array(hero_model_male), Model, sizeof(Model))
	else if(g_hero[id] == HERO_KATE)
		ArrayGetString(hero_model_female, get_random_array(hero_model_female), Model, sizeof(Model))
	
	set_model(id, Model)
	client_print(id, print_center, "%L", LANG_OFFICIAL, g_hero[id] == HERO_ANDREY ? "NOTICE_HERO_FOR_ANDREY" : "NOTICE_HERO_FOR_KATE")
	
	ExecuteForward(g_Forwards[FWD_USER_HERO], g_fwResult, id, g_hero[id])
	set_task(1.0, "Lock_Hero", id)
	
	return 
}

public Lock_Hero(id)
{
	if(!is_user_connected(id))
		return
		
	g_hero_locked[id] = 1
}

public set_user_zombie(id, attacker, inflictor, Origin_Zombie, Respawn)
{
	if(!is_user_alive(id))
		return
	if(g_gamestatus < STATUS_PLAY)
		return

	static DeathSound[64], PlayerModel[64]
	static zombie_maxhealth, zombie_maxarmor;
	static start_zombie_health[2], start_zombie_armor[2] , respawn_zombie_health, respawn_zombie_armor

	if(is_user_alive(attacker))
	{
		if(pev_valid(inflictor))
		{
			rg_death_notice(id, attacker, inflictor);
			UpdateFrags(attacker, id, 1, 1, 1)
			fm_cs_set_user_money(attacker, fm_cs_get_user_money(attacker) + 500, true)
		}
		
		switch(g_gamemode)
		{
			case MODE_MUTATION: handle_evolution(attacker, 1.0)
			case MODE_HERO:
			{
				switch(g_zombie_type[attacker])
				{
					case ZOMBIE_HOST: handle_evolution(attacker, g_hero[id] ? 10.0 : 3.0)
					case ZOMBIE_ORIGIN: handle_evolution(attacker, g_hero[id] ? 5.0  : 2.0)
				}
			}
		}
	}

	reset_player(id, 0, Respawn)
	g_zombie[id] = 1
	
	// Zombie Class
	if(!Respawn)
	{
		if(Origin_Zombie)
		{
			g_level[id] = 2

			set_dhudmessage(0, 160, 0, MAIN_HUD_X, MAIN_HUD_Y_BOTTOM , 2, 1.0, 3.0, 0.005 , 0.1)
			show_dhudmessage(id, "%L", LANG_PLAYER, "ZOMBIE_COMING")
		}
		else
			g_level[id] = 1
		g_iEvolution[id] = 0.0
		
		if (g_gamemode >= MODE_MUTATION)
			set_menu_zombieclass(id)
	}
	
	// Fix "Dead" Atrib
	set_scoreboard_attrib(id, 0)
	
	switch(g_sex[id])
	{
		case SEX_MALE: ArrayGetString(sound_infect_male, get_random_array(sound_infect_male), DeathSound, sizeof(DeathSound))
		case SEX_FEMALE: ArrayGetString(sound_infect_female, get_random_array(sound_infect_female), DeathSound, sizeof(DeathSound))
	}
	
	if(!Respawn)
		EmitSound(id, CHAN_VOICE, DeathSound)
		
	zombie_appear_sound(Respawn)	
		
	// Set Health
	zombie_maxhealth = g_level[id] > 2 ? zombie_level3_health : zombie_level2_health
	zombie_maxarmor  = g_level[id] > 2 ? zombie_level3_armor  : zombie_level2_armor

	start_zombie_health[ZOMBIE_ORIGIN] = floatround(float(g_firsthuman) / float(g_firstzombie) * 1000.0)
	start_zombie_health[ZOMBIE_HOST]   = clamp( floatround( get_user_health(attacker) * g_flinfect_multi[id] ), zombie_minhealth, zombie_maxhealth)

	start_zombie_armor[ZOMBIE_ORIGIN]  = zombie_maxarmor
	start_zombie_armor[ZOMBIE_HOST]    = clamp( floatround( get_user_armor(attacker)  * g_flinfect_multi[id] ), zombie_minarmor, zombie_maxarmor)

	respawn_zombie_health = clamp( floatround(g_StartHealth[id] * g_health_reduce_percent ), zombie_minhealth, zombie_maxhealth )
	respawn_zombie_armor  = clamp( floatround(g_StartArmor[id]  * g_health_reduce_percent ), zombie_minarmor, zombie_maxarmor)

	fm_set_rendering(id)
	fm_reset_user_weapon(id)
	
	// Set Zombie
	set_team(id, TEAM_ZOMBIE)
	g_zombie_type[id] = Origin_Zombie ? ZOMBIE_ORIGIN : ZOMBIE_HOST

	g_StartHealth[id] = Respawn ? respawn_zombie_health : start_zombie_health[ g_zombie_type[id] ]
	g_StartArmor[id]  = Respawn ? respawn_zombie_armor  : start_zombie_armor [ g_zombie_type[id] ]

	set_zombie_nvg(id, 1)
	set_weapon_anim(id, 3)
	
	fm_set_user_health(id, g_StartHealth[id])
	set_pev(id, pev_max_health, float(g_StartHealth[id]))
	fm_cs_set_user_armor(id, g_StartArmor[id], ARMOR_KEVLAR)

	fm_set_user_speed(id, ArrayGetCell(g_zombie_type[id] == ZOMBIE_HOST ? zombie_speed_host : zombie_speed_origin , g_zombie_class[id]))
	set_pev(id, pev_gravity, ArrayGetCell(zombie_gravity, g_zombie_class[id]))

	ArrayGetString(g_zombie_type[id] == ZOMBIE_HOST ? zombie_model_host : zombie_model_origin, g_zombie_class[id], PlayerModel, sizeof(PlayerModel))
	set_model(id, PlayerModel)
	
	if(g_gamemode == MODE_MUTATION)
		SendScenarioMsg(id, g_evo_need_infect[g_zombie_type[id]] - floatround(g_iEvolution[id]))

	ExecuteForward(g_Forwards[FWD_USER_INFECT], g_fwResult, id, attacker, Respawn ? INFECT_RESPAWN : INFECT_VICTIM)

	gameplay_check()
}

public handle_evolution(id, Float:value)
 {
	if(g_level[id] >= 3)
		return

	switch(g_gamemode)
	{
		case MODE_MUTATION: 
		{
			g_iEvolution[id] += value;
			SendScenarioMsg(id, g_evo_need_infect[g_zombie_type[id]] - floatround(g_iEvolution[id]))
			if(g_iEvolution[id] == g_evo_need_infect[g_zombie_type[id]]) UpdateLevelZombie(id)
		}
		case MODE_HERO:
		{
			g_iEvolution[id] += value
			if(g_iEvolution[id] > 9.9) UpdateLevelZombie(id)
		}
	}
}

public handle_countdown(Float:gametime)
{
	static Float:starttime, count
	starttime = g_roundstart_time + g_countdown_count
	count = floatround(starttime - gametime, floatround_ceil)

	if(gametime > starttime) { start_game_now(); return; }

	client_print(0, print_center, "%L", LANG_OFFICIAL, "GAME_COUNTDOWN", count)

	static sound[64]
	format(sound, charsmax(sound), sound_game_count, count)
					
	PlaySound(0, sound)
}

public handle_round_timeout(Float:gametime)
{
	static Float:endtime;
	endtime = g_roundstart_time + float(get_member_game(m_iRoundTimeSecs))

	if(gametime > endtime)
		TerminateRound(TEAM_HUMAN)
}

public handle_respawn_countdown(id, Float:gametime, Float:respawntime)
{
	static countdown, anim_finish
	
	anim_finish = get_member(id, m_fSequenceFinished)
	countdown = floatround(respawntime - gametime, floatround_ceil)

	if(countdown)
	{
		switch(anim_finish)
		{
			case true: { Dead_Effect(id, countdown); client_print(id, print_center, "%L", LANG_OFFICIAL, "ZOMBIE_RESPAWN", countdown); }
			case false: { set_member(id, m_flRespawnPending, respawntime + 1.0); }
		}
	}
}

public set_menu_zombieclass(id)
{
	if(!is_user_bot(id))
	{
		show_menu_zombieclass(id, 0)
		return
	}

	static classid
	classid = random_num(0, g_zombieclass_i - 1)

	ExecuteForward(g_Forwards[FWD_USER_CHANGE_CLASS], g_fwResult, id, g_zombie_class[id], classid)

	g_zombie_class[id] = classid
	set_zombie_class(id, g_zombie_class[id])
}
public show_menu_zombieclass(id, page)
{
	if(!is_user_connected(id))
		return
	if(!g_zombie[id] || g_gamemode <= MODE_ORIGINAL)
		return
		
	if(pev_valid(id) == 2) set_member(id, m_iMenu, CS_Menu_OFF)

	static i, class_name[128], class_desc[128], class_id[128], String[2][64], menuwpn_title[64], temp_string[128]
	format(menuwpn_title, 63, "%L:", LANG_PLAYER, "MENU_CLASSZOMBIE_TITLE")
	new mHandleID = menu_create(menuwpn_title, "menu_selectclass_handle")
	
	for (i = 0; i < g_zombieclass_i; i++)
	{
		String[0][0] = '^0'
		String[1][0] = '^0'

		ArrayGetString(zombie_name, i, class_name, charsmax(class_name))
		ArrayGetString(zombie_desc, i, class_desc, charsmax(class_desc))
		formatex(class_id, charsmax(class_name), "%i", i)

		if(!g_unlocked_class[id][i] && ArrayGetCell(zombie_lockcost, i))
		{	
			formatex(String[0], 63, "%L", LANG_OFFICIAL, "MENU_LOCKED")
			formatex(String[1], 63, "%L", LANG_OFFICIAL, "MENU_UNLOCK_COST")
				
			formatex(temp_string, charsmax(temp_string), "%s \r[%s]\n (%s: \r$%i\n)", class_name, String[0], String[1], ArrayGetCell(zombie_lockcost, i))
			
			menu_additem(mHandleID, temp_string, class_id)
		}
		else
		{
			formatex(temp_string, charsmax(temp_string), "%s \y(%s)", class_name, class_desc)
			menu_additem(mHandleID, temp_string, class_id)
		}
	}
	
	menu_display(id, mHandleID, page)
	
	remove_task(id+TASK_CHOOSECLASS)
	set_task(float(g_classchoose_time), "Remove_ChooseClass", id+TASK_CHOOSECLASS)
	client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_PLAYER, "ZOMBIE_SELECTCLASS_NOTICE", g_classchoose_time)
}

public Remove_ChooseClass(id)
{
	id -= TASK_CHOOSECLASS
	
	if(!is_user_connected(id))
		return
	if(!g_zombie[id])
		return
		
	g_can_choose_class[id] = 0
}

public menu_selectclass_handle(id, menu, item)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED
	if(!g_zombie[id]) 
		return PLUGIN_HANDLED
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	if(!g_can_choose_class[id])
	{
		client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_PLAYER, "MENU_CANT_SELECT_CLASS", g_classchoose_time)
		return PLUGIN_HANDLED
	}
	
	new idclass[32], name[32], access, classid
	menu_item_getinfo(menu, item, access, idclass, 31, name, 31, access)
	
	classid = str_to_num(idclass)	
	
	if(!ArrayGetCell(zombie_lockcost, classid) || g_unlocked_class[id][classid] )
	{
		ExecuteForward(g_Forwards[FWD_USER_CHANGE_CLASS], g_fwResult, id, g_zombie_class[id], classid)
		
		g_zombie_class[id] = classid
		set_zombie_class(id, g_zombie_class[id])
		
		ExecuteForward(g_Forwards[FWD_USER_INFECT], g_fwResult, id, -1, INFECT_CHANGECLASS)

		fm_reset_user_weapon(id, false)
		set_weapon_anim(id, 3)
		menu_destroy(menu)
		
		if(classid != 0)
			g_can_choose_class[id] = 0
	} 
	else 
	{
		static lock_cost
		lock_cost = ArrayGetCell(zombie_lockcost, classid)
		
		if(fm_cs_get_user_money(id) >= lock_cost)
		{
			g_unlocked_class[id][classid] = 1
			fm_cs_set_user_money(id, fm_cs_get_user_money(id) - lock_cost)
			client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_PLAYER, "MENU_UNLOCKED_CLASS")
			menu_selectclass_handle(id, menu, item)
		} 
		else 
		{
			client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_PLAYER, "MENU_CANT_UNLOCK_CLASS")
			menu_destroy( menu )
			show_menu_zombieclass(id, 0)
		}
	} 
	
	return PLUGIN_HANDLED
}

public set_zombie_class(id, idclass)
{
	if(!is_user_connected(id))
		return
	if(!g_zombie[id])
		return
		
	static PlayerModel[64]

	switch(g_zombie_type[id])
	{
		case ZOMBIE_HOST:
		{
			fm_set_user_speed(id, ArrayGetCell(zombie_speed_host, g_zombie_class[id]))
			ArrayGetString(zombie_model_host, g_zombie_class[id], PlayerModel, sizeof(PlayerModel))
		}
		case ZOMBIE_ORIGIN:
		{
			fm_set_user_speed(id, ArrayGetCell(zombie_speed_origin, g_zombie_class[id]))
			ArrayGetString(zombie_model_origin, g_zombie_class[id], PlayerModel, sizeof(PlayerModel))
		}
	}
	
	set_model(id, PlayerModel)
	set_pev(id, pev_gravity, ArrayGetCell(zombie_gravity, g_zombie_class[id]))
	
	Event_CheckWeapon(id)
}

public set_human_model(id)
{
	static Model[64]
	
	switch(g_sex[id])
	{
		case SEX_FEMALE: ArrayGetString(human_model_female, get_random_array(human_model_female), Model, sizeof(Model))
		default: ArrayGetString(human_model_male, get_random_array(human_model_male), Model, sizeof(Model))
	}
	
	set_model(id, Model)
}

public reset_player(id, new_player, zombie_respawn)
{
	if(new_player)
	{
		g_sex[id] = sex_selection(id)
		g_RespawnTime[id] = g_respawn_time
		g_iMaxLevel[id] = 10
		g_iEvolution[id] = 0.0
		g_flinfect_multi[id] = 0.5
		g_zombie_class[id] = 0
		for(new i = 0; i < MAX_ZOMBIECLASS; i++)
			g_unlocked_class[id][i] = 0
	}

	if(!zombie_respawn)
	{
		g_zombie[id] = g_hero[id] = 0
		g_hero_locked[id] = g_HasNvg[id] = 0
		g_can_choose_class[id] = 1
		g_level[id] = 0		
		g_iEvolution[id] = 0.0
	} else {
		g_hero[id] = 0
		g_hero_locked[id] = g_HasNvg[id] = 0
	}
}

public sex_selection(id)
{
	if(!is_user_connected(id))
		return SEX_NONE
	
	return random_num(0, 2) > 0 ? SEX_FEMALE : SEX_MALE
}

public do_random_spawn(id, retry_count)
{
	if(!pev_valid(id) && !zb3_get_player_spawn_count() )
		return

	static hull, Float:Origin[3], random_mem
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	random_mem = random_num(0, zb3_get_player_spawn_count())
	Origin[0] = zb3_get_player_spawn_cord(random_mem,0)
	Origin[1] = zb3_get_player_spawn_cord(random_mem,1)
	Origin[2] = zb3_get_player_spawn_cord(random_mem,2)

	if(is_hull_vacant(Origin, hull))
	{
		engfunc(EngFunc_SetOrigin, id, Origin)
	}
	else
	{
		if(retry_count > 0)
		{
			retry_count--
			do_random_spawn(id, retry_count)
		}
	}
}

public zombie_appear_sound(comeback)
{
	static ComingSound[64]
	
	if(!comeback)
		ArrayGetString(sound_zombie_coming, get_random_array(sound_zombie_coming), ComingSound, sizeof(ComingSound))
	else
		ArrayGetString(sound_zombie_comeback, get_random_array(sound_zombie_comeback), ComingSound, sizeof(ComingSound))
	
	if(get_gametime() - 0.1 > g_Delay_ComeSound)
	{
		PlaySound(0, ComingSound)
		g_Delay_ComeSound = get_gametime()
	}
}

public UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	// Set attacker frags
	if(is_user_connected(attacker))
		set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))
	
	// Set victim deaths
	if(is_user_connected(victim))
		fm_cs_set_user_deaths(victim, fm_cs_get_user_deaths(victim) + deaths)
	
	// Update scoreboard with attacker and victim info
	if (scoreboard)
	{
		if(is_user_connected(attacker))
		{
			message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
			write_byte(attacker) // id
			write_short(pev(attacker, pev_frags)) // frags
			write_short(fm_cs_get_user_deaths(attacker)) // deaths
			write_short(0) // class?
			write_short(get_member(attacker, m_iTeam)) // team
			message_end()
		}
		
		if(is_user_connected(victim))
		{
			message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
			write_byte(victim) // id
			write_short(pev(victim, pev_frags)) // frags
			write_short(fm_cs_get_user_deaths(victim)) // deaths
			write_short(0) // class?
			write_short(get_member(victim, m_iTeam)) // team
			message_end()
		}
	}
}

// ======================== SET MODELS ============================
// ================================================================

public set_model(id, const model[])
{
	if(!is_user_alive(id))
		return

	static Buffer[64];
	formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", model, model)

	if(file_exists(Buffer, true))
		rg_set_user_model(id, model, true);
}
// ========================= GAME STOCKS ==========================
// ================================================================
stock get_color_level(id, num)
{
	new color[3]
	switch (g_level[id])
	{
		case 1..3: color = g_zombie[id] ? {137,191,20} : {0,177,0}
		case 4..5: color = {137,191,20}
		case 6..7: color = {250,229,0}
		case 8..9: color = {243,127,1}
		case 10: color = {255,3,0}
		case 11..13: color = {127,40,208}
		default: color = {0,177,0}
	}
	
	return color[num];
}

stock client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	if(index == 0)
	{
		for(new i = 1; i <= g_MaxPlayers; i++)
		{
			if(is_user_connected(i))
			{
				message_begin(MSG_ONE_UNRELIABLE, g_Msg_SayText, _, i);
				write_byte(i);
				write_string(szMsg);
				message_end();	
			}
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_SayText, _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 

stock check_user_admin(id)
{
	if (get_user_flags(id) & ADMIN_LEVEL_G) 
		return 1
		
	return 0
}

// Set User Deaths
stock fm_cs_set_user_deaths(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != 2)
		return;
	
	set_member(id, m_iDeaths, value);
}

stock fm_cs_get_user_deaths(id)
{
	return get_member(id, m_iDeaths);
}

stock set_scoreboard_attrib(id, attrib = 0) // 0 - Nothing; 1 - Dead; 2 - VIP
{
	if(!is_user_connected(id))
		return
		
	message_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"))
	write_byte(id) // id
	switch(attrib)
	{
		case 1: write_byte(1<<0)
		case 2: write_byte(1<<2)
		default: write_byte(0)
	}
	message_end()	
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock fm_set_user_speed(id, Float:speed)
{
	if(!is_user_alive(id))
		return
		
	g_UsingCustomSpeed[id] = 1
	g_PlayerMaxSpeed[id] = speed		
		
	/*
	set_pev(id, pev_maxspeed, speed)
	ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
	
	client_print(id, print_chat, "Speed %f", speed)*/
}

stock fm_reset_user_speed(id)
{
	if(!is_user_alive(id))
		return
	static Float:speed
	speed = ArrayGetCell(g_level[id] > 1 ? zombie_speed_origin : zombie_speed_host, g_zombie_class[id])

	g_UsingCustomSpeed[id] = g_zombie[id] ? 1 : 0

	if(g_zombie[id]) g_PlayerMaxSpeed[id] = speed
	else rg_reset_maxspeed(id)
}

stock fm_reset_user_weapon(id, bool:strip = true)
{
	if(!is_user_alive(id))
		return

	static ent, Float:distance, Float:scalar;

	if(strip)
		rg_remove_all_items(id, false)

	switch(g_zombie[id])
	{
		case true: 
		{
			ent = rg_give_custom_item(id, "weapon_knife", GT_REPLACE, KNIFE_IMPULSE)

			if(ent)
			{
				distance = get_member(ent, m_Knife_flSwingDistance)
				scalar = ArrayGetCell(zombie_claw_distance1, g_zombie_class[id])

				if(scalar > 0.0)
					set_member(ent, m_Knife_flSwingDistance, distance * scalar)

				distance = get_member(ent, m_Knife_flStabDistance)
				scalar = ArrayGetCell(zombie_claw_distance2,  g_zombie_class[id])

				if(scalar > 0.0)
					set_member(ent, m_Knife_flStabDistance, distance * scalar)
			}
		}
		case false: rg_give_default_items(id)

	}
}

stock round(num)
{	
	return num - num % 100
}

stock GetRandomAlive()
{
	new id, check_vl
	
	while(!check_vl)
	{
		id = random_num(1, g_MaxPlayers)
		if (is_user_alive(id) && !g_zombie[id] && !g_hero[id]) check_vl = 1
	}
	
	return id
}

stock get_random_array(Array:array_name)
{
	return random_num(0, ArraySize(array_name) - 1)
}

stock GetTotalPlayer({PlayerTeams,_}:team, alive)
{
	static total, id, playeralive, playerconnected, TeamName:playerteam;
	total = 0
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		playerconnected = is_user_connected(id)
		if(!playerconnected)
			continue

		playeralive = is_user_alive(id)
		if(alive && !playeralive)
			continue

		playerteam = fm_cs_get_user_team(id)
		if(playerteam == TEAM_UNASSIGNED || playerteam == TEAM_SPECTATOR)
			continue

		switch(team)
		{
			case TEAM_ZOMBIE: if(g_zombie[id]) total++
			case TEAM_HUMAN: if(!g_zombie[id]) total++
			default: total++
		}
	}
	
	return total;	
}

stock GetRespawningCount()
{
	for(new i = 1; i <= g_MaxPlayers; i++)
	{
		if(!is_user_connected(i) || !g_zombie[i])
			continue

		if(get_member(i, m_flRespawnPending))
			return true;
	}
	
	return false;
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock StopSound(id)
{
	if(!is_user_connected(id))
		return
		
	client_cmd(id, "mp3 stop; stopsound")
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock fm_cs_set_user_armor(client, armorvalue, ArmorType:armortype)
{
	rg_set_user_armor(client, armorvalue, armortype);
}

stock fm_cs_get_user_money(client)
{
	return get_member(client, m_iAccount);
}

stock fm_cs_set_user_money(client, money, flash=1)
{
	rg_add_account(client, money, AS_SET, flash ? true : false )
}

stock fm_cs_get_weapon_id(entity)
{
	return rg_get_iteminfo(entity, ItemInfo_iId)
}

stock TeamName:fm_cs_get_user_team(client)
{
	if(!pev_valid(client))
		return TEAM_UNASSIGNED

	return get_member(client, m_iTeam);
}

stock fm_cs_set_user_team(id, TeamName:team)
{
	rg_set_user_team(id, team)
}

public SendScenarioMsg(id, num)
{
	new hostage[10]
	if(num > 4)
		formatex(hostage, charsmax(hostage), "number_%i", num)
	else
		formatex(hostage, charsmax(hostage), "hostage%i", num)

	message_begin(MSG_ONE, get_user_msgid("Scenario"), .player = id)
	write_byte(g_level[id] < 3 ? 1 : 0); // status (0=hide, 1=show, 2=flash)
	write_string(hostage) // sprite
	write_byte(255)
	message_end()
}

// ======================== Round Terminator ======================
// ================================================================
stock bool:TerminateRound({PlayerTeams,_}:team)
{
	new sound[64]; sound[0] = '^0'
	
	switch(team)
	{
		case TEAM_ZOMBIE: ArrayGetString(sound_win_zombie, get_random_array(sound_win_zombie), sound, sizeof(sound))
		case TEAM_HUMAN: ArrayGetString(sound_win_human, get_random_array(sound_win_human), sound, sizeof(sound))
	}
	
	g_gamestatus = STATUS_ENDROUND

	rg_update_teamscores(team == TEAM_HUMAN, team == TEAM_ZOMBIE);
	rg_round_end(team == TEAM_START ? 3.0 : 5.0, WINSTATUS_NONE, ROUND_NONE, g_WinText[team]);

	if(sound[0]) PlaySound(0, sound)
	
	ExecuteForward(g_Forwards[FWD_GAME_END], g_fwResult, team)
	
	return true;
}
// ========================= DATA LOADER ==========================
// ================================================================
public load_config_file()
{
	static buffer[128], Array:DummyArray
	
	get_mapname(g_mapname, charsmax(g_mapname))

	amx_load_setting_string( false, SETTING_FILE, "Game Sub-Mode", "GAMEMODE", buffer, sizeof(buffer), DummyArray);
	if( str_to_num(buffer) >= MODE_ORIGINAL ) g_gamemode = clamp( str_to_num(buffer), MODE_ORIGINAL, MODE_HERO)
	else g_gamemode = MODE_HERO

	amx_load_setting_string( false, SETTING_FILE, "Game Sub-Mode", "MUTANT_ORIGIN_EVO_REQ", buffer, sizeof(buffer), DummyArray); 
	g_evo_need_infect[ZOMBIE_ORIGIN] = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Game Sub-Mode", "MUTANT_HOST_EVO_REQ", buffer, sizeof(buffer), DummyArray); 
	g_evo_need_infect[ZOMBIE_HOST] = str_to_num(buffer)

	// GamePlay Configs
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "COUNTDOWN", buffer, sizeof(buffer), DummyArray); g_countdown_count = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "ZB_LV2_HEALTH", buffer, sizeof(buffer), DummyArray); zombie_level2_health = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "ZB_LV3_HEALTH", buffer, sizeof(buffer), DummyArray); zombie_level3_health = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "ZB_LV2_ARMOR", buffer, sizeof(buffer), DummyArray); zombie_level2_armor = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "ZB_LV3_ARMOR", buffer, sizeof(buffer), DummyArray); zombie_level3_armor = str_to_num(buffer)

	amx_load_setting_string( false, SETTING_FILE, "Config Value", "MIN_HEALTH_ZOMBIE", buffer, sizeof(buffer), DummyArray); zombie_minhealth = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "MIN_ARMOR_ZOMBIE", buffer, sizeof(buffer), DummyArray); zombie_minarmor = str_to_num(buffer)

	amx_load_setting_string( false, SETTING_FILE, "Config Value", "GRENADE_POWER", buffer, sizeof(buffer), DummyArray); grenade_default_power = str_to_num(buffer)
	
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "HUMAN_HEALTH", buffer, sizeof(buffer), DummyArray); human_health = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "HUMAN_ARMOR", buffer, sizeof(buffer), DummyArray); human_armor = str_to_num(buffer)
	
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "CLASS_CHOOSE_TIME", buffer, sizeof(buffer), DummyArray); g_classchoose_time = str_to_num(buffer)

	amx_load_setting_string( false, SETTING_FILE, "Config Value", "ZOMBIE_RESPAWN_TIME", buffer, sizeof(buffer), DummyArray); g_respawn_time = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "ZOMBIE_RESPAWN_SPR", g_respawn_icon, sizeof(g_respawn_icon), DummyArray)
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "ZOMBIE_RESPAWN_HEALTH_REDUCE_MULTI", buffer, charsmax(buffer), DummyArray)
	g_health_reduce_percent = 1.0 - floatclamp( floatabs( str_to_float(buffer) ), 0.0, 0.9 )
	
	// Load Hero
	amx_load_setting_string( true, SETTING_FILE, "Hero Config", "HERO_MODEL", buffer, 0, hero_model_male)
	amx_load_setting_string( true, SETTING_FILE, "Hero Config", "HEROINE_MODEL",buffer, 0, hero_model_female)
	
	// Weather & Sky Configs
	amx_load_setting_string( false, MAP_FILE, g_mapname, "RAIN", buffer, sizeof(buffer), DummyArray); g_rain = str_to_num(buffer)
	amx_load_setting_string( false, MAP_FILE, g_mapname, "SNOW", buffer, sizeof(buffer), DummyArray); g_snow = str_to_num(buffer)
	amx_load_setting_string( false, MAP_FILE, g_mapname, "FOG" , buffer, sizeof(buffer), DummyArray); g_fog = str_to_num(buffer)

	amx_load_setting_string( false, MAP_FILE, g_mapname, "FOG_DENSITY", g_fog_density, charsmax(g_fog_density), DummyArray)
	amx_load_setting_string( false, MAP_FILE, g_mapname, "FOG_COLOR", g_fog_color, charsmax(g_fog_color), DummyArray)
	
	amx_load_setting_string( false, MAP_FILE, g_mapname, "SKY", g_sky, charsmax(g_sky), DummyArray)
	amx_load_setting_string( false, MAP_FILE, g_mapname, "LIGHT", g_light, charsmax(g_light), DummyArray)

	// NightVision
	amx_load_setting_string( false, SETTING_FILE, "Night Vision", "NVG_ALPHA", buffer, sizeof(buffer), DummyArray); g_NvgAlpha = str_to_num(buffer)

	// Load NVG Config
	amx_load_setting_string( false, SETTING_FILE, "Night Vision", "NVG_HUMAN_COLOR_R", buffer, sizeof(buffer), DummyArray); g_NvgColor[TEAM_HUMAN][0] = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Night Vision", "NVG_HUMAN_COLOR_G", buffer, sizeof(buffer), DummyArray); g_NvgColor[TEAM_HUMAN][1] = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Night Vision", "NVG_HUMAN_COLOR_B", buffer, sizeof(buffer), DummyArray); g_NvgColor[TEAM_HUMAN][2] = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Night Vision", "NVG_ZOMBIE_COLOR_R", buffer, sizeof(buffer), DummyArray); g_NvgColor[TEAM_ZOMBIE][0] = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Night Vision", "NVG_ZOMBIE_COLOR_G", buffer, sizeof(buffer), DummyArray); g_NvgColor[TEAM_ZOMBIE][1] = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Night Vision", "NVG_ZOMBIE_COLOR_B", buffer, sizeof(buffer), DummyArray); g_NvgColor[TEAM_ZOMBIE][2] = str_to_num(buffer)

	// Load Human Models
	amx_load_setting_string( true, SETTING_FILE, "Config Value", "PLAYER_MODEL_MALE", buffer, 0, human_model_male)
	amx_load_setting_string( true, SETTING_FILE, "Config Value", "PLAYER_MODEL_FEMALE", buffer, 0, human_model_female)
	
	// Load Sounds
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "ZOMBIE_START", buffer, 0, sound_game_start)
	amx_load_setting_string( false, SETTING_FILE, "Sounds", "ZOMBIE_COUNT", sound_game_count, sizeof(sound_game_count), DummyArray)
	amx_load_setting_string( false, SETTING_FILE, "Sounds", "REMAINING_TIME", sound_remain_time, sizeof(sound_remain_time), DummyArray)
	
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "ZOMBIE_COMING", buffer, 0, sound_zombie_coming)
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "ZOMBIE_COMEBACK", buffer, 0, sound_zombie_comeback)
	
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "WIN_HUMAN", buffer, 0, sound_win_human)
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "WIN_ZOMBIE", buffer, 0, sound_win_zombie)
	
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "HUMAN_DEATH", buffer, 0, sound_infect_male)
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "FEMALE_DEATH", buffer, 0, sound_infect_female)
	
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "ZOMBIE_ATTACK", buffer, 0, sound_zombie_attack)
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "ZOMBIE_HITWALL", buffer, 0, sound_zombie_hitwall)
	amx_load_setting_string( true, SETTING_FILE, "Sounds", "ZOMBIE_SWING", buffer, 0, sound_zombie_swing)
	
	amx_load_setting_string( false, SETTING_FILE, "Sounds", "AMBIENCE", sound_ambience, sizeof(sound_ambience), DummyArray)
	amx_load_setting_string( false, SETTING_FILE, "Sounds", "HUMAN_LEVELUP", sound_human_levelup, sizeof(sound_human_levelup), DummyArray)

	// Restore Health Config
	amx_load_setting_string( false, SETTING_FILE, "Restore Health", "RESTORE_HEALTH_TIME", buffer, sizeof(buffer), DummyArray); Restore_Health_Time = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Restore Health", "RESTORE_HEALTH_DMG_LV1", buffer, sizeof(buffer), DummyArray); Restore_Amount_Host = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Restore Health", "RESTORE_HEALTH_DMG_LV2", buffer, sizeof(buffer), DummyArray); Restore_Amount_Origin = str_to_num(buffer)

}

public amx_load_setting_string( bool:IsArray ,const filename[], const setting_section[], setting_key[], return_string[], string_size, Array:array_handle)
{
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty filename")
		return false;
	}

	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Can't load settings: empty section/key")
		return false;
	}
	
	if ( IsArray && array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Array not initialized")
		return false;
	}

	// Build customization file path
	new path[256]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
		return false;
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
#if defined _DEBUG
		server_print("[ZB3] [%s] = N/A", setting_section)
#endif
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], values[1024], current_value[128]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and value
		switch(IsArray)
		{
			case false: strtok(linedata, key, charsmax(key), current_value, charsmax(current_value), '=')
			case true:  strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		}
		
		// Trim spaces
		trim(key)
		trim(current_value)

		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			switch(IsArray)
			{
				case true:
				{
					while (values[0] != 0 && strtok(values, current_value, charsmax(current_value), values, charsmax(values), ','))
					{
						// Trim spaces
						trim(current_value)
						trim(values)

						ArrayPushString(array_handle, current_value) // Add to array
#if defined _DEBUG
						server_print("[ZB3] [%s] %s = %s", setting_section, setting_key, current_value)
#endif
					}
				}
				case false:
				{
					formatex(return_string, string_size, "%s", current_value)
#if defined _DEBUG
					server_print("[ZB3] [%s] %s = %s", setting_section, setting_key, return_string)
#endif
				}
			}

			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}
