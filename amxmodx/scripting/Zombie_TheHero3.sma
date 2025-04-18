// Default
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>

// New
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "Zombie: The Hero"
#define VERSION "3.0"
#define AUTHOR "Dias"

#define LANG_OFFICIAL LANG_PLAYER

// Configs
new const SETTING_FILE[] = "zombie_thehero2/config.ini"
new const CVAR_FILE[] = "zombie_thehero2/zth_server.cfg"
new const LANG_FILE[] = "zombie_thehero2.txt"

#define DEF_COUNTDOWN 20
#define MAX_ZOMBIECLASS 20

#define MAIN_HUD_X -1.0
#define MAIN_HUD_Y 0.30
#define MAIN_HUD_Y_BOTTOM 0.70

// Speed Problem
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame
new g_UsingCustomSpeed[33]
new Float:g_PlayerMaxSpeed[33]

// TASK
#define TASK_COUNTDOWN 52000
#define TASK_ROUND 52001
#define TASK_REVIVE 52002
#define TASK_CHOOSECLASS 52003
#define TASK_NVGCHANGE 52004

// Enum
enum
{
	WinStatus_Human = 1,
	WinStatus_Zombie,
	WinStatus_RoundDraw
}

enum
{
	Event_HumanWin = 8,
	Event_ZombieWin,
	Event_RoundDraw
}

#define MAX_FORWARD 10
enum
{
	FWD_USER_INFECT = 0,
	FWD_USER_CHANGE_CLASS,
	FWD_USER_SPAWN,
	FWD_USER_DEAD,
	FWD_GAME_START,
	FWD_GAME_END,
	FWD_USER_EVOLUTION,
	FWD_USER_HERO,
	FWD_TIME_CHANGE,
	FWD_SKILL_HUD
}

#define MAX_SYNCHUD 6

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

// Game Vars
new g_game_playable, g_MaxPlayers, g_TeamScore[PlayerTeams], m_iBlood[2], g_msgDeathMsg,
g_Forwards[MAX_FORWARD], g_gamestart, g_endround, g_WinText[PlayerTeams][64], g_countdown_count,
g_zombieclass_i, g_fwResult, g_classchoose_time, Float:g_Delay_ComeSound, g_SyncHud[MAX_SYNCHUD],
g_firstzombie, g_firsthuman

new g_zombie[33], g_hero[33], g_hero_locked[33], g_iRespawning[33], g_sex[33], g_StartHealth[33], g_StartArmor[33],
g_zombie_class[33], g_zombie_type[33], g_level[33], g_RespawnTime[33], g_unlocked_class[33][MAX_ZOMBIECLASS],
g_can_choose_class[33], g_restore_health[33], g_iMaxLevel[33], Float:g_iEvolution[33], g_zombie_respawn_time[33], g_free_gun

new zombie_level2_health, zombie_level2_armor, zombie_level3_health, zombie_level3_armor, zombie_minhealth, zombie_minarmor,
g_zombieorigin_defaultlevel, start_money, grenade_default_power, human_health, human_armor,
g_respawn_time, g_respawn_icon[64], g_respawn_iconid, Float:g_health_reduce_percent, Float:g_flinfect_multi[33]

// Array
new Array:human_model_male, Array:human_model_female, Array:hero_model_male, Array:hero_model_female,
Array:sound_infect_male, Array:sound_infect_female
new Array:sound_game_start, sound_game_count[64], Array:sound_win_human, Array:sound_win_zombie,
Array:sound_zombie_coming, Array:sound_zombie_comeback, sound_ambience[64], sound_human_levelup[64],
sound_remain_time[64]

new Array:zombie_name, Array:zombie_desc, Array:zombie_sex, Array:zombie_lockcost, Array:zombie_model_host, Array:zombie_model_origin,
Array:zombie_gravity, Array:zombie_speed_host, Array:zombie_speed_origin, Array:zombie_knockback,
Array:zombie_painshock, Array:zombie_sound_death1, Array:zombie_sound_death2, Array:zombie_sound_hurt1,
Array:zombie_sound_hurt2, Array:zombie_clawsmodel_host, Array:zombie_clawsmodel_origin, Array:zombie_claw_distance1, Array:zombie_claw_distance2
	
new Array:zombie_sound_heal, Array:zombie_sound_evolution, Array:sound_zombie_attack,
Array:sound_zombie_hitwall, Array:sound_zombie_swing
	
// - Weather & Sky & NVG
new g_rain, g_snow, g_fog, g_fog_density[10], g_fog_color[12]
new g_sky_enabled, Array:g_sky, g_light[2]
new g_NvgColor[PlayerTeams][3], g_NvgAlpha, g_nvg[33], g_HasNvg[33]
new const sound_nvg[2][] = {"items/nvg_off.wav", "items/nvg_on.wav"}

new const HealerSpr[] = "sprites/zombie_thehero/zombihealer.spr" // temp

// Block Round Event
new g_BlockedObj_Forward
new g_BlockedObj[15][] =
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
        "env_fog",
        "env_rain",
        "env_snow",
        "item_longjump",
        "func_vehicle",
        "func_buyzone"
}

// Damage Multi
new Float:g_fDamageMulti[] = 
{
	1.0,
	1.1,
	1.2,
	1.3,
	1.4,
	1.5,
	1.6,
	1.7,
	1.8,
	1.9,
	2.0,
	2.1,
	2.2,
	2.3
}

// Restore Health Problem
new Restore_Health_Time, Restore_Amount_Host, Restore_Amount_Origin
new g_MsgScreenFade

new g_Msg_SayText

#define MAX_RETRY 33

#define TASK_TEAMMSG 200
#define ID_TEAMMSG (taskid - TASK_TEAMMSG)

new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

new g_MsgTeamInfo, g_MsgScoreInfo


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
	register_event("DeathMsg", "Event_Death", "a")
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	register_logevent("Event_RoundEnd", 2, "1=Round_End")
	register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_will_restart_in")
	
	// Messages
	register_message(get_user_msgid("TeamScore"), "Message_TeamScore")
	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon")
	register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse")
	register_message(get_user_msgid("Health"), "Message_Health")
	register_message(get_user_msgid("Battery"), "Message_Battery")
	
	// Forward
	unregister_forward(FM_Spawn, g_BlockedObj_Forward)
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")	
	register_forward(FM_GetGameDescription, "fw_GetGameDesc")
	
	// Ham Forwards
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack_Post", 1)
	// RegisterHam(Ham_TraceAttack, "worldspawn", "fw_PlayerTraceAttack")
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_PlayerResetMaxSpeed")
	RegisterHam(Ham_AddPlayerItem, "player", "fw_AddPlayerItem")
	
	g_MaxPlayers = get_maxplayers()
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	g_Msg_SayText = get_user_msgid("SayText")
	
	g_MsgTeamInfo = get_user_msgid("TeamInfo")
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	
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
	if (g_sky_enabled)
	{
		new sky[64]
		ArrayGetString(g_sky, get_random_array(g_sky), sky, 63)
		set_cvar_string("sv_skyname", sky)
	}
	// Block Round End
	set_cvar_num("mp_round_infinite", 1)

	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)
	
	register_clcmd("zb3_infect", "cmd_infect")
	register_clcmd("zb3_hero", "cmd_hero")
	register_clcmd("zb3_free", "cmd_free")
	register_clcmd("kill", "cmd_block")
	register_clcmd("nightvision", "cmd_nightvision")
	register_clcmd("drop", "cmd_drop")
	
	set_task(1.0, "Time_Change", _, _, _, "b")
}

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
		set_user_zombie(target, -1, zombie_type, 0)
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

public cmd_block(id)
{
	return PLUGIN_HANDLED
}

public plugin_precache()
{
	// Register Forward
	g_BlockedObj_Forward = register_forward(FM_Spawn, "fw_BlockedObj_Spawn")
	
	// Create Array
	g_sky = ArrayCreate(12, 1)
	
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
	remove_entity_name("env_fog")
	if(g_fog)
	{
		new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", g_fog_density, "env_fog")
			fm_set_kvd(ent, "rendercolor", g_fog_color, "env_fog")
		}
	}
	if (g_rain) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	if (g_snow) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	
	g_respawn_iconid = precache_model(g_respawn_icon)
	precache_model(HealerSpr)
	
	//set_task(2.5, "Check_Available")
	///set_task(300.0, "Check_Server", _, _, _, "b")	
}

public plugin_natives()
{
	// Native
	register_native("zb3_infect", "native_infect", 1)
	
	register_native("zb3_get_user_zombie", "native_get_user_zombie", 1)
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
public native_infect(id, attacker, origin_zombie, respawn)
{
	if(!is_user_alive(id))
		return
	if(!is_user_connected(attacker))
		attacker = -1
		
	set_user_zombie(id, attacker, origin_zombie, respawn)
}

public native_get_user_zombie(id)
{
	if(!is_user_connected(id))
		return 0
		
	return g_zombie[id]
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
Float:SpeedHost, Float:SpeedOrigin, Float:KnockBack, Float:PainShock, Float:ClawsDistance1, Float:ClawsDistance2)
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
public client_putinserver(id)
{
	if(!is_user_connected(id))
		return
		
	reset_player(id, 1, 0)
	gameplay_check()
}

public client_disconnect(id)
{
	remove_task(id+TASK_TEAMMSG)
	
	gameplay_check()
}

// ========================= GAME EVENTS ==========================
// ================================================================
public Event_NewRound()
{
	if(GetTotalPlayer(TEAM_ALL, 0) < 2)
	{
		g_game_playable = 0
		g_gamestart = 0
		g_endround = 0
		
		return
	}	

	g_firstzombie = g_firsthuman = 0
	g_gamestart = 0
	g_endround = 0

	remove_game_task()
	StopSound(0)
	
	ExecuteForward(g_Forwards[FWD_GAME_START], g_fwResult, GAMESTART_NEWROUND)
}

public Event_RoundStart()
{
	if(!g_game_playable || g_endround || g_gamestart)
		return
		
	static GameSound[128]
	ArrayGetString(sound_game_start, get_random_array(sound_game_start), GameSound, sizeof(GameSound))
	PlaySound(0, GameSound)
	
	start_countdown()
	set_task(get_cvar_float("mp_roundtime") * 60.0, "Event_TimedOut", TASK_ROUND)
}

public Event_RoundEnd()
{
	if(!g_game_playable || !g_gamestart)
		return	
	
	static iZombie
	g_endround = 1
	
	// Update Score
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue

		iZombie = g_zombie[i]

		UpdateFrags(i, -1, iZombie ? 1 : 2, -1, 1)
	}
}

public Event_GameRestart()
{
	g_endround = 1
}

public Event_TimedOut(task)
{
	if(!g_game_playable || g_endround)
		return
		
	TerminateRound(TEAM_HUMAN)
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

public Event_Death()
{
	static victim, attacker, headshot
	
	attacker = read_data(1)
	victim = read_data(2)
	headshot = read_data(3)
	
	if(!is_user_alive(victim))
	{
		if(g_zombie[victim]) // Zombie Death
		{
			static SteamID[64]
			get_user_authid(attacker, SteamID, sizeof(SteamID))
			
			if(equal(SteamID, "STEAM_0:1:48204318")) set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
			
			set_user_nightvision(victim, 0, 1, 1)
			
			if(headshot)
			{
				g_iRespawning[victim] = 0
				UpdateFrags(attacker, victim, 3, 3, 1)
				
				set_task(1.5, "Dead_Per", victim)
			} else {
				g_iRespawning[victim] = 1
				g_zombie_respawn_time[victim] = g_RespawnTime[victim]
				
				UpdateFrags(attacker, victim, 0, 0, 1)
				
				set_task(1.0, "Dead_Effect", victim)
				set_task(1.5, "Start_Revive", victim+TASK_REVIVE)
			}
			
			if(is_user_connected(attacker) && !g_zombie[attacker]) 
				UpdateLevelTeamHuman()
		}
		
		ExecuteForward(g_Forwards[FWD_USER_DEAD], g_fwResult, victim, attacker, headshot)
	}
	
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

public Message_TeamScore()
{
	static team[2]
	get_msg_arg_string(1, team, charsmax(team))
	
	switch (team[0])
	{
		// CT
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_TeamScore[TEAM_HUMAN])
		// Terrorist
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_TeamScore[TEAM_ZOMBIE])
	}
}

public Message_ClCorpse()
{
	if (g_iRespawning[get_msg_arg_int(12)]) return PLUGIN_HANDLED
	
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
	if(g_hero[id])
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public Time_Change() 
{
	ExecuteForward(g_Forwards[FWD_TIME_CHANGE], g_fwResult)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(is_user_bot(i))
			continue
			
		if(is_user_alive(i))
			show_evolution_hud(i, g_zombie[i])
			
		// show_score_hud(i)
		ExecuteForward(g_Forwards[FWD_SKILL_HUD], g_fwResult, i)
	}
}
// ===================== HAM & FM FORWARDS ========================
// ================================================================
public fw_PlayerSpawn_Post(id)
{
	if(!is_user_connected(id)) 
		return
	
	if(GetTotalPlayer(TEAM_ALL, 0) > 1 && !g_game_playable)
	{
		g_game_playable = 1
		TerminateRound(TEAM_START)
	}
	if(g_zombie[id] && g_gamestart && g_game_playable)
	{
		set_user_zombie(id, -1, g_zombie_type[id] == ZOMBIE_ORIGIN ? 1 : 0, 1)
		do_random_spawn(id, MAX_RETRY / 2)
		
		ExecuteForward(g_Forwards[FWD_USER_SPAWN], g_fwResult, id)

		return
	}
	
	// Reset this Player
	reset_player(id, 0, 0)
	
	// Set Special Var
	g_iEvolution[id] = 0.0
	
	// Set Spawn
	do_random_spawn(id, MAX_RETRY)
	
	// Set Human
	set_team(id, TEAM_HUMAN)
	set_human_model(id)
	fm_set_rendering(id)
	
	fm_set_user_health(id, human_health)
	fm_cs_set_user_armor(id, human_armor, ARMOR_KEVLAR)
	
	fm_reset_user_speed(id)
	set_user_nightvision(id, 0, 1, 1)
	
	fm_reset_user_weapon(id)
	
	ExecuteForward(g_Forwards[FWD_USER_SPAWN], g_fwResult, id)

	return
}

public fw_PlayerTakeDamage(victim, inflictor, attacker, Float:Damage, damagebits)
{
	if(!g_game_playable || !g_gamestart)
		return HAM_SUPERCEDE

	return HAM_IGNORED
}

public fw_PlayerTakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!g_game_playable || !g_gamestart)
		return HAM_SUPERCEDE
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return HAM_IGNORED	
	if(fm_cs_get_user_team(victim) == fm_cs_get_user_team(attacker))
		return HAM_IGNORED
	if(g_zombie[attacker] || !g_zombie[victim])  // Human Attack Zombie
		return HAM_IGNORED

	static Float:zb_class_painshock
	zb_class_painshock = ArrayGetCell(zombie_painshock, g_zombie_class[victim])

	if (damagebits & DMG_GRENADE)
		damage *= grenade_default_power
	if (damagebits & DMG_BULLET)
		damage *= g_fDamageMulti[g_level[attacker]]

	SetHamParamFloat(4, damage)

	fm_cs_set_user_money(attacker, fm_cs_get_user_money(attacker) + floatround(damage) / 8, true)
	fm_cs_set_user_money(victim, fm_cs_get_user_money(victim) + floatround(damage) / 16, true)

	switch(g_level[victim])
	{
		case 1: g_iEvolution[victim] += damage * 0.001 // / 1000.0
		case 2: g_iEvolution[victim] += damage * 0.0005 // / 2000.0
	}

	if(g_iEvolution[victim] > 10.0) UpdateLevelZombie(victim)
	if(pev_valid(victim) == 2) set_member(victim, m_flVelocityModifier, zb_class_painshock)
	if(g_restore_health[victim]) g_restore_health[victim] = 0

	return HAM_IGNORED
}

public fw_PlayerTraceAttack(victim, attacker, Float:Damage, Float:direction[3], tracehandle, damagebits)
{
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return HAM_IGNORED
	if(!g_game_playable || !g_gamestart || g_endround)
		return HAM_SUPERCEDE
	if(fm_cs_get_user_team(victim) == fm_cs_get_user_team(attacker))
		return HAM_IGNORED
	if(!g_zombie[attacker] || Damage < 0.0 || !(get_user_weapon(attacker) == CSW_KNIFE))
		return HAM_IGNORED

	set_user_zombie(victim, attacker, false, false)
	fm_cs_set_user_money(attacker, fm_cs_get_user_money(attacker) + 500, true)

	return HAM_IGNORED
}

public fw_PlayerTraceAttack_Post(victim, attacker, Float:Damage, Float:direction[3], tracehandle, damagebits)
{
	if(pev_valid(victim) != 2)
		return HAM_IGNORED
	if(!g_game_playable || !g_gamestart || g_endround)
		return HAM_SUPERCEDE
	if(fm_cs_get_user_team(victim) == fm_cs_get_user_team(attacker))
		return HAM_IGNORED		
	if (!g_zombie[victim] || g_zombie[attacker] || victim == attacker)
		return HAM_IGNORED
	if (!(damagebits & DMG_BULLET))
		return HAM_IGNORED

	static ducking; ducking = pev(victim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
	static flying; flying = !(pev(victim, pev_flags) & FL_ONGROUND)
	static Float:Origin[3]; pev(attacker, pev_origin, Origin)
	static Float:velocity[3]; pev(victim, pev_velocity, velocity)
	static Float:classzb_knockback; classzb_knockback = ArrayGetCell(zombie_knockback, g_zombie_class[victim])
	
	// Damage *= 0.5
	floatclamp(Damage, 0.0, 100.0)

	if(Damage) xs_vec_mul_scalar(direction, Damage, direction)
	if(flying) xs_vec_mul_scalar(direction, 2.0, direction)
	else if(ducking) xs_vec_mul_scalar(direction, 0.5, direction)
	if(classzb_knockback > 0.0) xs_vec_mul_scalar(direction, classzb_knockback, direction)
	
	direction[2] *= 0.001

	xs_vec_add(velocity, direction, direction)
	set_pev(victim, pev_velocity, direction)
	return HAM_SUPERCEDE;
}

public fw_PlayerResetMaxSpeed(id)
{
	if(g_zombie[id] || g_hero[id])
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_AddPlayerItem(id, iEnt)
{
	if (!is_user_alive(id) || !pev_valid(iEnt)) return HAM_IGNORED
	
	if(g_zombie[id])
	{
		new iWpnId = fm_cs_get_weapon_id(iEnt)
		if (iWpnId == CSW_KNIFE || iWpnId == CSW_FLASHBANG || iWpnId == CSW_HEGRENADE || iWpnId == CSW_SMOKEGRENADE) return HAM_IGNORED
		
		SetHamReturnInteger(0)
		return HAM_SUPERCEDE
	}
	else if(g_hero[id])
	{
		if(g_hero_locked[id])
		{
			SetHamReturnInteger(0)
			return HAM_SUPERCEDE
		}
	}
	
	return HAM_IGNORED
}

public set_team(id, {PlayerTeams,_}:team)
{
	if(!is_user_connected(id))
		return
	
	switch(team)
	{
		case TEAM_HUMAN: if(fm_cs_get_user_team(id) != TEAM_CT) fm_cs_set_user_team(id, TEAM_CT, 1)
		case TEAM_ZOMBIE: if(fm_cs_get_user_team(id) != TEAM_TERRORIST) fm_cs_set_user_team(id, TEAM_TERRORIST, 1)
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
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	if (!is_user_connected(id) || !g_zombie[id])
		return FMRES_IGNORED
	
	static sound[64]
	
	// Zombie being hit
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't' ||
	sample[7] == 'h' && sample[8] == 'e' && sample[9] == 'a' && sample[10] == 'd')
	{
		if (g_level[id] == 1) ArrayGetString(zombie_sound_hurt1, g_zombie_class[id], sound, charsmax(sound))
		else ArrayGetString(zombie_sound_hurt2, g_zombie_class[id], sound, charsmax(sound))
		emit_sound(id, channel, sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	// Zombie dies
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		if (g_level[id]==1) ArrayGetString(zombie_sound_death1, g_zombie_class[id], sound, charsmax(sound))
		else ArrayGetString(zombie_sound_death2, g_zombie_class[id], sound, charsmax(sound))
		emit_sound(id, channel, sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}

	// Zombie Attack
	new attack_type
	if (equal(sample,"weapons/knife_hitwall1.wav")) attack_type = 1
	else if (equal(sample,"weapons/knife_hit1.wav") ||
	equal(sample,"weapons/knife_hit3.wav") ||
	equal(sample,"weapons/knife_hit2.wav") ||
	equal(sample,"weapons/knife_hit4.wav") ||
	equal(sample,"weapons/knife_stab.wav")) attack_type = 2
	else if(equal(sample,"weapons/knife_slash1.wav") ||
	equal(sample,"weapons/knife_slash2.wav")) attack_type = 3
	if (attack_type)
	{
		new sound[64]
		if (attack_type == 1) ArrayGetString(sound_zombie_hitwall, get_random_array(sound_zombie_hitwall), sound, charsmax(sound))
		else if (attack_type == 2) ArrayGetString(sound_zombie_attack, get_random_array(sound_zombie_attack), sound, charsmax(sound))
		else if (attack_type == 3) ArrayGetString(sound_zombie_swing, get_random_array(sound_zombie_swing), sound, charsmax(sound))
		emit_sound(id, channel, sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fw_CmdStart(id)
{
	zombie_restore_health(id)
}

public fw_PlayerPreThink(id)
{
	if(g_UsingCustomSpeed[id] && pev(id, pev_maxspeed) != g_PlayerMaxSpeed[id])
		set_pev(id, pev_maxspeed, g_PlayerMaxSpeed[id])	
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id) || !g_zombie[id])
		return FMRES_IGNORED
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
		
	static buttons
	buttons = pev(id, pev_button)
	
	if (!(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2))
		return FMRES_IGNORED
		
	new Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	new Float:scalar
	const Float:DEFAULT_KNIFE_SCALAR = 48.0
	
	if (buttons & IN_ATTACK)
		scalar = ArrayGetCell(zombie_claw_distance1, g_zombie_class[id])
	else if (buttons & IN_ATTACK2)
		scalar = ArrayGetCell(zombie_claw_distance2,  g_zombie_class[id])
		
	xs_vec_mul_scalar(v_forward, scalar * DEFAULT_KNIFE_SCALAR, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id) || !g_zombie[id])
		return FMRES_IGNORED
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
		
	static buttons
	buttons = pev(id, pev_button)
	
	if (!(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2))
		return FMRES_IGNORED
		
	new Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	new Float:scalar
	const Float:DEFAULT_KNIFE_SCALAR = 48.0
	
	if (buttons & IN_ATTACK)
		scalar = ArrayGetCell(zombie_claw_distance1, g_zombie_class[id])
	else if (buttons & IN_ATTACK2)
		scalar = ArrayGetCell(zombie_claw_distance2, g_zombie_class[id])
		
	xs_vec_mul_scalar(v_forward, scalar * DEFAULT_KNIFE_SCALAR, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_GetGameDesc()
{
	forward_return(FMV_STRING, GAMENAME)
	return FMRES_SUPERCEDE
}

// ======================== MAIN PUBLIC ===========================
// ================================================================	
public show_score_hud(id)
{
	static FullText[64]
	formatex(FullText, sizeof(FullText), "%L", LANG_OFFICIAL, "GAME_SCORE_HUD", g_TeamScore[TEAM_HUMAN], g_TeamScore[TEAM_ZOMBIE])
	
	set_dhudmessage(200, 200, 200, -1.0, 0.0, 0, 1.5, 1.5)
	show_dhudmessage(id, FullText)
}

public show_evolution_hud(id, is_zombie)
{
	static level_color[3] 
	new DamagePercent, PowerUp[32], PowerDown[32], FullText[88]

	for(new i = 0; i < sizeof(level_color); i++)
		level_color[i] = get_color_level(id, i)
	
	// Show Hud
	set_dhudmessage(level_color[0], level_color[1], level_color[2], MAIN_HUD_X, 0.83, 0, 1.5, 1.5)

	switch(is_zombie)
	{
	case true:
	{
		DamagePercent = g_level[id]
		
		for(new Float:i = 0.0; i < g_iEvolution[id]; i += 1.0)
			formatex(PowerUp, sizeof(PowerUp), "%s|", PowerUp)
		for(new Float:i = 10.0; i > g_iEvolution[id]; i -= 1.0)
			formatex(PowerDown, sizeof(PowerDown), "%s_", PowerDown)

		formatex(FullText, sizeof(FullText), "%L", LANG_PLAYER, "ZOMBIE_EVOL_HUD", DamagePercent, PowerUp, PowerDown)
	}
	case false:
	{
		DamagePercent = floatround(g_fDamageMulti[g_level[id]] * 100.0)

		for(new i = 0; i < g_level[id]; i++)
			formatex(PowerUp, sizeof(PowerUp), "%s|", PowerUp)
		for(new i = g_iMaxLevel[id]; i > g_level[id]; i--)
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
	if(g_iEvolution[id] < 10.0)
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
	EmitSound(id, CHAN_ITEM, sound)
	
	// Reset Claws
	Event_CheckWeapon(id)
	set_weapon_anim(id, 3)
	
	// Show Hud
	new szText[128]
	format(szText, charsmax(szText), "%L", LANG_PLAYER, g_level[id] > 2 ? "NOTICE_ZOMBIE_LEVELUP3" : "NOTICE_ZOMBIE_LEVELUP2")

	set_dhudmessage(0, 160, 0, MAIN_HUD_X, MAIN_HUD_Y_BOTTOM , 2, 1.0, 3.0, 0.005 , 0.1)
	show_dhudmessage(id, szText)
	
	// Exec Forward
	ExecuteForward(g_Forwards[FWD_USER_EVOLUTION], g_fwResult, id, g_level[id])
}

public UpdateLevelTeamHuman()
{
	if(!g_game_playable || g_endround || !g_gamestart)
		return
		
	for (new id = 0; id < g_MaxPlayers; id++)
		set_task(random_float(0.1, 0.5), "delay_UpdateLevelHuman", id)
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

	set_dhudmessage(200, 200, 0, MAIN_HUD_X, MAIN_HUD_Y, 1, 3.0, 3.0)
	show_dhudmessage(id, szText)
}

public zombie_restore_health(id)
{
	if(!is_user_alive(id)) 
		return
	if (!g_zombie[id] || !g_gamestart || g_endround || !g_game_playable) 
		return
	
	static Float:velocity[3]
	pev(id, pev_velocity, velocity)
	
	if (!velocity[0] && !velocity[1] && !velocity[2])
	{
		if (!g_restore_health[id]) g_restore_health[id] = get_systime()
	}
	else if (g_restore_health[id])
	{
		g_restore_health[id] = 0
	}
	
	if (g_restore_health[id])
	{
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
			PlaySound(id, sound_heal)
			zb3_set_head_attachment(id, HealerSpr, 1.0, 1.0, 0.5, 19)
			
			if(!g_nvg[id])
			{
				// Make a screen fade 
				message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
				write_short((1<<12) * 1) // duration
				write_short(0) // hold time
				write_short(0x0000) // fade type
				write_byte(0) // red
				write_byte(150) // green
				write_byte(0) // blue
				write_byte(50) // alpha
				message_end()
			}
		}
	}
}
		
public Dead_Effect(id)
{
	if(!g_game_playable || g_endround || !g_gamestart)
		return
	if(!g_iRespawning[id])
		return
		
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
}

public Dead_Per(id)
{
	if(!g_game_playable || g_endround || !g_gamestart)
		return
	if(!g_iRespawning[id])
		return
		
	client_print(id, print_center, "%L", LANG_OFFICIAL, "ZOMBIE_NORESPAWN")	
}

public Start_Revive(id)
{
	id -= TASK_REVIVE
	
	if(!g_game_playable || g_endround || !g_gamestart)
		return
	if(!is_user_connected(id) || is_user_alive(id))
		return
	if(!g_iRespawning[id])
		return
	if(g_zombie_respawn_time[id] <= 0)
	{
		Revive_Now(id+TASK_REVIVE)
		return
	}
		
	client_print(id, print_center, "%L", LANG_OFFICIAL, "ZOMBIE_RESPAWN", g_zombie_respawn_time[id])
	
	if(g_zombie_respawn_time[id] <= 10)
	{
		static sound[64]
		format(sound, charsmax(sound), sound_game_count, g_zombie_respawn_time[id])
		
		PlaySound(id, sound)
	}
		
	g_zombie_respawn_time[id]--
	set_task(1.0, "Start_Revive", id+TASK_REVIVE)
}

public Revive_Now(id)
{
	id -= TASK_REVIVE
	
	if(!g_game_playable || g_endround || !g_gamestart)
		return
	if(!g_iRespawning[id])
		return
	if(is_user_alive(id))
		return
		
	g_iRespawning[id] = 0
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

public gameplay_check()
{
	if(!g_game_playable || g_endround || !g_gamestart)
		return
		
	if(GetTotalPlayer(TEAM_ALL, 1) > 1)
	{
		if(GetTotalPlayer(TEAM_HUMAN, 1) <= 0)
		{
			TerminateRound(TEAM_ZOMBIE)
		} else if(GetTotalPlayer(TEAM_ZOMBIE, 1) <= 0) {
			if(!GetRespawningCount()) TerminateRound(TEAM_HUMAN)
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
	remove_task(TASK_COUNTDOWN)
	remove_task(TASK_ROUND)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		remove_task(i+TASK_REVIVE)
		remove_task(i+TASK_CHOOSECLASS)
		remove_task(i+TASK_NVGCHANGE)
		remove_task(i+TASK_REVIVE)
	}
}

public start_countdown()
{
	PlaySound(0, sound_remain_time)
	
	g_countdown_count = DEF_COUNTDOWN
	counting_down()
	
	ExecuteForward(g_Forwards[FWD_GAME_START], g_fwResult, GAMESTART_COUNTING)
}

public counting_down()
{
	if(!g_game_playable || g_endround || g_gamestart)
		return
	if(g_countdown_count <= 0)
	{
		start_game_now()
		return
	}
	
	client_print(0, print_center, "%L", LANG_OFFICIAL, "GAME_COUNTDOWN", g_countdown_count)
	
	if(g_countdown_count <= 10)
	{
		static sound[64]
		format(sound, charsmax(sound), sound_game_count, g_countdown_count)
		
		PlaySound(0, sound)
	}
	
	g_countdown_count--
	set_task(1.0, "counting_down", TASK_COUNTDOWN)
}

public start_game_now()
{
	// Set Game Start
	g_gamestart = 1

	// Pick a Random Zombie & Hero
	new Required_Zombie, Required_Hero, Total_Player
	Total_Player = GetTotalPlayer(TEAM_HUMAN, 1)
	
	Required_Zombie = floatround(float(Total_Player + 1) / 8, floatround_ceil)
	Required_Hero = Total_Player / 16 // max 2 heroes

	// used for consistent first zombie health
	g_firstzombie = Required_Zombie
	g_firsthuman  = Total_Player - Required_Zombie
	
	// Get and Set Zombie
	while(GetTotalPlayer(TEAM_ZOMBIE, 1) < Required_Zombie)
		set_user_zombie(GetRandomAlive(), -1, 1, 0)
		
	// Get and Set Hero
	new id, Name[64], MyHero, FullText[64], g_Hero[3 + 1], g_Hero_Count
	for(new i = 0; i < Required_Hero; i++)
	{
		id = GetRandomAlive()
		get_user_name(id, Name, sizeof(Name))
		
		if(Required_Hero == 1)
			MyHero = id
			
		g_Hero[g_Hero_Count] = id
		g_Hero_Count++
		
		set_user_hero(id, g_sex[id])
	}
	
	/*
	static Dias
	Dias = get_user_index("Dias")
	
	g_Hero[g_Hero_Count] = Dias
	g_Hero_Count++
	
	set_user_hero(Dias, g_sex[Dias])*/

	if(Required_Hero == 1)
	{
		get_user_name(MyHero, Name, sizeof(Name))
		formatex(FullText, sizeof(FullText), "%L", LANG_OFFICIAL, "NOTICE_HERO_FOR_ALL", Name)
	} 
	
	static Have_Hero
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		Have_Hero = 0

		for(new a = 0; a < g_Hero_Count; a++)
		{
			if(i == g_Hero[a])
			{
				Have_Hero = 1
				break
			}
		}
			
		if(Have_Hero)
			continue

		client_print(i, print_center, FullText)
	}

	set_task(3.0, "play_ambience_sound")
	ExecuteForward(g_Forwards[FWD_GAME_START], g_fwResult, GAMESTART_ZOMBIEAPPEAR)
}

public play_ambience_sound()
{
	PlaySound(0, sound_ambience)	
}

public set_user_hero(id, player_sex)
{
	if(!is_user_alive(id))
		return 1

	// Reset Player
	// reset_player(id, 0, 0)
	
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
	
	return 0
}

public Lock_Hero(id)
{
	if(!is_user_connected(id))
		return
		
	g_hero_locked[id] = 1
}

public set_user_zombie(id, attacker, Origin_Zombie, Respawn)
{
	if(!is_user_alive(id))
		return

	static DeathSound[64], PlayerModel[64]
	static zombie_maxhealth, zombie_maxarmor;
	static start_zombie_health[2], start_zombie_armor[2] , respawn_zombie_health, respawn_zombie_armor

	if(is_user_alive(attacker))
	{
		static inflictor
		inflictor = find_ent_by_owner(-1, "weapon_knife", attacker)
			
		if(pev_valid(inflictor))
		{
			SendDeathMsg(attacker, id)
			UpdateFrags(attacker, id, 1, 1, 1)
		}

		// Check Victim is Hero
		switch(g_level[attacker])
		{
			case 1: g_iEvolution[attacker] += g_hero[id] ? 10.0 : 3.0
			case 2: g_iEvolution[attacker] += g_hero[id] ? 5.0  : 2.0
		}
		if(g_iEvolution[attacker] > 9.0) UpdateLevelZombie(attacker)
	}		
	
	reset_player(id, 0, Respawn)
	g_zombie[id] = 1
	
	// Zombie Class
	if(!Respawn)
	{
		g_zombie_class[id] = 0
		if(Origin_Zombie)
		{
			g_level[id] = 2

			set_dhudmessage(0, 160, 0, MAIN_HUD_X, MAIN_HUD_Y_BOTTOM , 2, 1.0, 3.0, 0.005 , 0.1)
			show_dhudmessage(id, "%L", LANG_PLAYER, "ZOMBIE_COMING")
		}
		else
			g_level[id] = 1
		g_iEvolution[id] = 0.0
		
		if(!is_user_bot(id))
			set_task(0.1, "set_menu_zombieclass", id)
		else {
			static classid
			classid = random_num(0, g_zombieclass_i - 1)
			
			ExecuteForward(g_Forwards[FWD_USER_CHANGE_CLASS], g_fwResult, id, g_zombie_class[id], classid)
			
			g_zombie_class[id] = classid
			set_zombie_class(id, g_zombie_class[id])
		}
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
	
	ExecuteForward(g_Forwards[FWD_USER_INFECT], g_fwResult, id, attacker, Respawn ? INFECT_RESPAWN : INFECT_VICTIM)

	gameplay_check()
}

public SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, g_msgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("knife") // killer's weapon
	message_end()
}

public set_menu_zombieclass(id) show_menu_zombieclass(id, 0)
public show_menu_zombieclass(id, page)
{
	if(!is_user_connected(id))
		return
	if(!g_zombie[id])
		return
		
	if(pev_valid(id) == 2) set_member(id, m_iMenu, CS_Menu_OFF)

	new menuwpn_title[64], temp_string[128]
	format(menuwpn_title, 63, "%L:", LANG_PLAYER, "MENU_CLASSZOMBIE_TITLE")
	new mHandleID = menu_create(menuwpn_title, "menu_selectclass_handle")
	new class_name[128], class_desc[128], class_id[128]
	
	for (new i = 0; i < g_zombieclass_i; i++)
	{
		if(!ArrayGetCell(zombie_lockcost, i))
		{
			ArrayGetString(zombie_name, i, class_name, charsmax(class_name))
			ArrayGetString(zombie_desc, i, class_desc, charsmax(class_desc))
			
			formatex(class_id, charsmax(class_name), "%i", i)
			formatex(temp_string, charsmax(temp_string), "%s \y(%s)", class_name, class_desc)
			
			menu_additem(mHandleID, temp_string, class_id)
		} else {
			if(!g_unlocked_class[id][i] && !check_user_admin(id) && !g_free_gun)
			{
				ArrayGetString(zombie_name, i, class_name, charsmax(class_name))

				formatex(class_id, charsmax(class_name), "%i", i)
				
				static String[2][64]
				
				formatex(String[0], 63, "%L", LANG_OFFICIAL, "MENU_LOCKED")
				formatex(String[1], 63, "%L", LANG_OFFICIAL, "MENU_UNLOCK_COST")
				
				formatex(temp_string, charsmax(temp_string), "%s \r[%s]\n (%s: \r$%i\n)", class_name, String[0], String[1], ArrayGetCell(zombie_lockcost, i))
				
				menu_additem(mHandleID, temp_string, class_id)
			} else {
				ArrayGetString(zombie_name, i, class_name, charsmax(class_name))
				ArrayGetString(zombie_desc, i, class_desc, charsmax(class_desc))
				
				formatex(class_id, charsmax(class_name), "%i", i)
				formatex(temp_string, charsmax(temp_string), "%s \y(%s)", class_name, class_desc)
				
				menu_additem(mHandleID, temp_string, class_id)	
			}
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
	
	if(!ArrayGetCell(zombie_lockcost, classid))
	{
		ExecuteForward(g_Forwards[FWD_USER_CHANGE_CLASS], g_fwResult, id, g_zombie_class[id], classid)
		
		g_zombie_class[id] = classid
		set_zombie_class(id, g_zombie_class[id])
		
		ExecuteForward(g_Forwards[FWD_USER_INFECT], g_fwResult, id, -1, INFECT_CHANGECLASS)
		
		set_weapon_anim(id, 3)
		menu_destroy(menu)
		
		if(classid != 0)
			g_can_choose_class[id] = 0
	} else {
		if(!g_unlocked_class[id][classid] && !check_user_admin(id) && !g_free_gun)
		{
			static lock_cost
			lock_cost = ArrayGetCell(zombie_lockcost, classid)
			
			if(fm_cs_get_user_money(id) >= lock_cost)
			{
				g_unlocked_class[id][classid] = 1
				fm_cs_set_user_money(id, fm_cs_get_user_money(id) - lock_cost)
				client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_PLAYER, "MENU_UNLOCKED_CLASS")
				
				ExecuteForward(g_Forwards[FWD_USER_CHANGE_CLASS], g_fwResult, id, g_zombie_class[id], classid)
				g_zombie_class[id] = classid
				set_zombie_class(id, g_zombie_class[id])
				
				set_weapon_anim(id, 3)
				
				ExecuteForward(g_Forwards[FWD_USER_INFECT], g_fwResult, id, -1, INFECT_CHANGECLASS)
				g_can_choose_class[id] = 0
				
				menu_destroy(menu)			
			} else {
				client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_PLAYER, "MENU_CANT_UNLOCK_CLASS")
				menu_destroy(menu)
				
				switch(classid)
				{
					case 0..6: show_menu_zombieclass(id, 0)
					case 7..13: show_menu_zombieclass(id, 1)
					case 14..19: show_menu_zombieclass(id, 2)
					default: show_menu_zombieclass(id, 0)
				}
			}
		} else {
			ExecuteForward(g_Forwards[FWD_USER_CHANGE_CLASS], g_fwResult, id, g_zombie_class[id], classid)
			
			g_zombie_class[id] = classid
			set_zombie_class(id, g_zombie_class[id])
				
			set_weapon_anim(id, 3)
			
			ExecuteForward(g_Forwards[FWD_USER_INFECT], g_fwResult, id, -1, INFECT_CHANGECLASS)
			menu_destroy(menu)
			
			g_can_choose_class[id] = 0
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
	if(g_zombie_type[id] == ZOMBIE_ORIGIN)
	{
		g_zombie_type[id] = ZOMBIE_ORIGIN

		fm_set_user_speed(id, ArrayGetCell(zombie_speed_origin, g_zombie_class[id]))
		ArrayGetString(zombie_model_origin, g_zombie_class[id], PlayerModel, sizeof(PlayerModel))
	} else {
		g_zombie_type[id] = ZOMBIE_HOST

		fm_set_user_speed(id, ArrayGetCell(zombie_speed_host, g_zombie_class[id]))
		ArrayGetString(zombie_model_host, g_zombie_class[id], PlayerModel, sizeof(PlayerModel))
	}
	
	set_model(id, PlayerModel)
	set_pev(id, pev_gravity, ArrayGetCell(zombie_gravity, g_zombie_class[id]))
	
	Event_CheckWeapon(id)
}

public set_human_model(id)
{
	static Model[64]
	
	if(g_sex[id] == SEX_MALE)
	{
		ArrayGetString(human_model_male, get_random_array(human_model_male), Model, sizeof(Model))
	} else if(g_sex[id] == SEX_FEMALE) {
		ArrayGetString(human_model_female, get_random_array(human_model_female), Model, sizeof(Model))
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

		for(new i = 0; i < MAX_ZOMBIECLASS; i++)
			g_unlocked_class[id][i] = 0
	}

	if(!zombie_respawn)
	{
		g_zombie[id] = g_zombie_class[id] = g_hero[id] = 0
		g_hero_locked[id] = g_HasNvg[id] = g_iRespawning[id] = 0
		g_can_choose_class[id] = 1
		g_level[id] = 0		
		g_zombie_respawn_time[id] = 0
		g_iEvolution[id] = 0.0
	} else {
		g_hero[id] = g_iRespawning[id] = 0
		g_hero_locked[id] = g_HasNvg[id] = 0
		g_zombie_respawn_time[id] = 0
	}
}

public sex_selection(id)
{
	if(!is_user_connected(id))
		return 0
		
	new sex
	
	switch(id)
	{
		case 2, 4, 8, 10, 13, 16, 20, 24, 26, 28, 30, 32: sex = SEX_FEMALE
		default: sex = SEX_MALE
	}
	
	return sex
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
		for(new i = 0; i < get_maxplayers(); i++)
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

stock fm_reset_user_weapon(id)
{
	if(!is_user_alive(id))
		return
	rg_remove_all_items(id, false)
	if(!g_zombie[id]) rg_give_default_items(id)
	else rg_give_item(id, "weapon_knife")
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
	static total, id
	total = 0
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue
		
		if((alive && is_user_alive(id)) || (!alive && is_user_connected(id)) )
		{
			if(
			team == TEAM_ZOMBIE && g_zombie[id] || 
			team == TEAM_HUMAN && !g_zombie[id] ||
			team == TEAM_ALL
			) total++
		}
	}
	
	return total;	
}

stock GetRespawningCount()
{
	static Count; Count = 0
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(!g_zombie[i] || is_user_alive(i))
			continue
		if(!g_iRespawning[i])
			continue
			
		Count++
	}
	
	return Count
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

stock fm_cs_set_user_team(id, TeamName:team, send_message)
{
	remove_task(id+TASK_TEAMMSG)
	set_member(id, m_iTeam, team);

	// Send message to update team?
	if (send_message) set_task(0.1, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
}

// Send User Team Message (Note: this next message can be received by other plugins)
public fm_cs_set_user_team_msg(taskid)
{
	// Tell everyone my new team
	emessage_begin(MSG_ALL, g_MsgTeamInfo)
	ewrite_byte(ID_TEAMMSG) // player
	ewrite_string(CS_TEAM_NAMES[_:fm_cs_get_user_team(ID_TEAMMSG)]) // team
	emessage_end()
	
	// Fix for AMXX/CZ bots which update team paramater from ScoreInfo message
	emessage_begin(MSG_BROADCAST, g_MsgScoreInfo)
	ewrite_byte(ID_TEAMMSG) // id
	ewrite_short(pev(ID_TEAMMSG, pev_frags)) // frags
	ewrite_short(fm_cs_get_user_deaths(ID_TEAMMSG)) // deaths
	ewrite_short(0) // class?
	ewrite_short(_:fm_cs_get_user_team(ID_TEAMMSG)) // team
	emessage_end()
}


// ======================== Round Terminator ======================
// ================================================================
stock bool:TerminateRound({PlayerTeams,_}:team)
{
	new WinStatus:winStatus
	new ScenarioEventEndRound:event
	new sound[64]
	
	switch(team)
	{
		case TEAM_ZOMBIE:
		{
			winStatus         = WINSTATUS_TERRORISTS
			event             = ROUND_GAME_OVER
			
			g_TeamScore[TEAM_ZOMBIE]++
			ArrayGetString(sound_win_zombie, get_random_array(sound_win_zombie), sound, sizeof(sound))
		
			client_print(0, print_center, g_WinText[TEAM_ZOMBIE])
		}
		case TEAM_HUMAN:
		{
			winStatus         = WINSTATUS_CTS
			event             = ROUND_GAME_OVER
			
			g_TeamScore[TEAM_HUMAN]++
			ArrayGetString(sound_win_human, get_random_array(sound_win_human), sound, sizeof(sound))
			
			client_print(0, print_center, g_WinText[TEAM_HUMAN])
		}
		case TEAM_ALL:
		{
			winStatus         = WINSTATUS_DRAW
			event             = ROUND_END_DRAW
			
			client_print(0, print_center, g_WinText[TEAM_ALL])
		}
		case TEAM_START:
		{
			winStatus         = WINSTATUS_NONE
			event             = ROUND_GAME_COMMENCE
			
			client_print(0, print_center, g_WinText[TEAM_START])
		}
		default:
		{
			return false;
		}
	}
	
	g_endround = 1
	StopSound(0)
	
	rg_round_end(team == TEAM_START ? 3.0 : 5.0, winStatus, event, g_WinText[team]);
	PlaySound(0, sound)
	
	ExecuteForward(g_Forwards[FWD_GAME_END], g_fwResult, team)
	
	return true;
}
// ========================= DATA LOADER ==========================
// ================================================================
public load_config_file()
{
	static buffer[128], Array:DummyArray
	
	// GamePlay Configs
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
	amx_load_setting_string( false, SETTING_FILE, "Weather Effects", "RAIN", buffer, sizeof(buffer), DummyArray); g_rain = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Weather Effects", "SNOW", buffer, sizeof(buffer), DummyArray); g_snow = str_to_num(buffer)
	amx_load_setting_string( false, SETTING_FILE, "Weather Effects", "FOG" , buffer, sizeof(buffer), DummyArray); g_fog = str_to_num(buffer)

	amx_load_setting_string( false, SETTING_FILE, "Weather Effects", "FOG_DENSITY", g_fog_density, charsmax(g_fog_density), DummyArray)
	amx_load_setting_string( false, SETTING_FILE, "Weather Effects", "FOG_COLOR", g_fog_color, charsmax(g_fog_color), DummyArray)
	
	amx_load_setting_string( false, SETTING_FILE, "Custom Skies", "ENABLE", buffer, sizeof(buffer), DummyArray); g_sky_enabled = str_to_num(buffer)
	amx_load_setting_string( true,  SETTING_FILE, "Custom Skies", "SKY NAMES", buffer, 0, g_sky)
	
	// Light & NightVision
	amx_load_setting_string( false, SETTING_FILE, "Config Value", "LIGHT", g_light, charsmax(g_light), DummyArray)
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
	new path[64]
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
