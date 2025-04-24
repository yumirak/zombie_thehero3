#include <amxmodx>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Heavy"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define IsValidPev(%0) (pev_valid(%0) == 2)

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zombie_thehero2/zclasscfg/heavy.ini"
new const SETTING_CONFIG[] = "Config"
new const SETTING_MODELS[] = "Models"
new const SETTING_SOUNDS[] = "Sounds"
new const SETTING_SKILL[] = "Skill"
// Zombie Configs
new zclass_sex, zclass_lockcost
new zclass_name[32], zclass_desc[32], zclass_hostmodel[32], zclass_originmodel[32], zclass_clawsmodelhost[32], zclass_clawsmodelorigin[32]
new zombiegrenade_modelhost[64], zombiegrenade_modelorigin[64], HealSound[64], EvolSound[64]
new Float:zclass_gravity, Float:zclass_speedhost, Float:zclass_speedorigin, Float:zclass_knockback
new Float:zclass_dmgmulti, Float:zclass_painshock, Float:ClawsDistance1, Float:ClawsDistance2
new Array:DeathSound, DeathSoundString1[64], DeathSoundString2[64]
new Array:HurtSound, HurtSoundString1[64], HurtSoundString2[64]
new Float:g_trap_cooldown[2], Float:g_trap_time[2]
new TrapSlow[64], model_trap[64], sound_trapsetup[64], sound_trapped[64]

new g_zombie_classid, g_can_set_trap[33], Float:g_current_time[33]

#define TRAP_CLASSNAME "zb_trap"
#define TASK_COOLDOWN 12001
#define TRAP_INVISIBLE 150
#define MAX_TRAP 10
// IDs inside tasks
#define TASK_REMOVETRAP 12938
#define ID_REMOVETRAP (taskid - TASK_REMOVETRAP)

// Vars
new g_total_traps[33], g_msgScreenShake, g_player_trapped[33]
new TrapEnt[33][MAX_TRAP]

new g_synchud1

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	register_clcmd("drop", "cmd_drop")

	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")

	g_msgScreenShake = get_user_msgid("ScreenShake")
	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)

	DeathSound = ArrayCreate(64, 1)
	HurtSound = ArrayCreate(64, 1)

	load_cfg()

	ArrayGetString(DeathSound, 0, DeathSoundString1, charsmax(DeathSoundString1))
	ArrayGetString(DeathSound, 1, DeathSoundString2, charsmax(DeathSoundString2))
	ArrayGetString(HurtSound, 0, HurtSoundString1, charsmax(HurtSoundString1))
	ArrayGetString(HurtSound, 1, HurtSoundString2, charsmax(HurtSoundString2))

	// Register Zombie Class
	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speedhost, zclass_speedorigin, zclass_knockback, zclass_dmgmulti, zclass_painshock, 
	ClawsDistance1, ClawsDistance2)
	
	zb3_set_zombie_class_data(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin, 
	DeathSoundString1, DeathSoundString2, HurtSoundString1, HurtSoundString2, HealSound, EvolSound)
	
	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheModel, model_trap)
	engfunc(EngFunc_PrecacheSound, sound_trapsetup)
	engfunc(EngFunc_PrecacheSound, sound_trapped)
	engfunc(EngFunc_PrecacheModel, TrapSlow)
}

public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_PLAYER, "ZCLASS_HEAVY_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_PLAYER, "ZCLASS_HEAVY_DESC")
	
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "COST", buffer, sizeof(buffer), DummyArray); zclass_lockcost = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "GENDER", buffer, sizeof(buffer), DummyArray); zclass_sex = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "GRAVITY", buffer, sizeof(buffer), DummyArray); zclass_gravity = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SPEED_ORIGIN", buffer, sizeof(buffer), DummyArray); zclass_speedorigin = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SPEED_HOST", buffer, sizeof(buffer), DummyArray); zclass_speedhost = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "KNOCKBACK", buffer, sizeof(buffer), DummyArray); zclass_knockback = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "DAMAGE_MULTIPLIER", buffer, sizeof(buffer), DummyArray); zclass_dmgmulti = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "PAINSHOCK", buffer, sizeof(buffer), DummyArray); zclass_painshock = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SLASH_DISTANCE", buffer, sizeof(buffer), DummyArray); ClawsDistance1 = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "STAB_DISTANCE", buffer, sizeof(buffer), DummyArray); ClawsDistance2 = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "PLAYERMODEL_ORIGIN", zclass_originmodel, sizeof(zclass_originmodel), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "PLAYERMODEL_HOST", zclass_hostmodel, sizeof(zclass_hostmodel), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "VIEWMODEL_ORIGIN", zclass_clawsmodelorigin, sizeof(zclass_clawsmodelorigin), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "VIEWMODEL_HOST", zclass_clawsmodelhost, sizeof(zclass_clawsmodelhost), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "GRENADE_VIEWMODEL_ORIGIN", zombiegrenade_modelorigin, sizeof(zombiegrenade_modelorigin), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "GRENADE_VIEWMODEL_HOST", zombiegrenade_modelhost, sizeof(zombiegrenade_modelhost), DummyArray);

	zb3_load_setting_string(true,  SETTING_FILE, SETTING_SOUNDS, "DEATH", buffer, 0, DeathSound);
	zb3_load_setting_string(true,  SETTING_FILE, SETTING_SOUNDS, "HURT", buffer, 0, HurtSound);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SOUNDS, "HEAL", HealSound, sizeof(HealSound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SOUNDS, "EVOL", EvolSound, sizeof(EvolSound), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_trap_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_trap_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_TIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_trap_time[ZOMBIE_HOST] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_TIME_HOST", buffer, sizeof(buffer), DummyArray); g_trap_time[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_MODEL", model_trap, sizeof(model_trap), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_SPR_SLOW", TrapSlow, sizeof(TrapSlow), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_SOUND_START", sound_trapsetup, sizeof(sound_trapsetup), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_SOUND_TRAPPED", sound_trapped, sizeof(sound_trapped), DummyArray);
}

public zb3_user_spawned(id)
{
	if( g_player_trapped[id] )
		g_player_trapped[id] = 0
}

public zb3_user_infected(id, infector, infect_flag)
{
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	switch(infect_flag)
	{
		case INFECT_VICTIM: reset_skill(id, true) 
	}
}
public zb3_user_change_class(id, oldclass, newclass)
{
	if(newclass == g_zombie_classid && oldclass != newclass)
		reset_skill(id, true)
	if(oldclass == g_zombie_classid)
		reset_skill(id, false)
}

public reset_skill(id, bool:reset_time)
{
	if( reset_time ) 
		g_current_time[id] = g_trap_cooldown[zb3_get_user_zombie_type(id)]

	g_can_set_trap[id] = reset_time ? 1 : 0

	if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
	if (g_total_traps[id]) remove_traps_player(id)
}
public zb3_user_dead(id) 
{
	reset_skill(id, false)
}

public zb3_game_start(start_type)
{
	if(start_type == GAMESTART_NEWROUND)
	{
		for (new i = 0; i <= MAX_PLAYERS; i++)
		{
			if ( !is_user_alive(i))
				continue
			remove_traps_player(i)
			g_player_trapped[i] = 0
		}
	}

	remove_traps()
}

public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(!zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return PLUGIN_CONTINUE
	if(!g_can_set_trap[id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZOMBIE_SKILL_NOT_READY", zclass_desc , floatround(g_trap_cooldown[zb3_get_user_zombie_type(id)] - g_current_time[id]))
		return PLUGIN_HANDLED
	}

	if(g_total_traps[id])
		remove_traps_player(id)

	Do_Trap(id)

	return PLUGIN_HANDLED
}

public Do_Trap(id)
{
	g_can_set_trap[id] = 0
	g_current_time[id] = 0.0
	
	// set trapping
	create_trap(id)

	// play sound
	EmitSound(id, sound_trapsetup)

	return PLUGIN_HANDLED
}
// don't move when traped (called per frame)

public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id) || !g_player_trapped[id])  // call only when someone got trapped
		return;

	new ent_trap = g_player_trapped[id]
	if(!pev_valid(ent_trap))
	{
		if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
		RemoveTrap(id+TASK_REMOVETRAP)
		return;
	}
	
	if (ent_trap && pev_valid(ent_trap)) // player is trapped 
	{	
		if(zb3_get_user_zombie(id)) // release trapped player when infected
		{
			if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
			RemoveTrap(id+TASK_REMOVETRAP)
			return;
		}

		zb3_set_user_speed(id, 1)

		switch(pev(ent_trap, pev_sequence)) // trap animation
		{
			case 1: 
			{ 
				switch(pev(ent_trap, pev_frame))
				{
					case 0..230: set_pev(ent_trap, pev_frame, pev(ent_trap, pev_frame) + 1.0)
					default: set_pev(ent_trap, pev_frame, 20.0)
				}
			}
			default: { set_pev(ent_trap, pev_sequence, 1); set_pev(ent_trap, pev_frame, 0.0); }
		}
	}
	
}
// touch trap (called per frame)
public pfn_touch(ptr, ptd)
{
	if(pev_valid(ptr) && !zb3_get_user_zombie(ptd)) // call only when human touches trap
	{
		static classname[32]
		pev(ptr, pev_classname, classname, charsmax(classname))
		
		if(equal(classname, TRAP_CLASSNAME))
		{
			if (is_user_alive(ptd) && g_player_trapped[ptd] != ptr && pev(ptr, pev_sequence) != 1) // don't repeat trap a trapped player
			{
				Trapped(ptd, ptr)
			}
		}
	}
}

Trapped(id, ent_trap)
{
	// check trapped
	for (new i=1; i< get_maxplayers(); i++)
	{
		if (is_user_connected(i) && g_player_trapped[i]==ent_trap) return;
	}
	
	// set ent trapped of player
	g_player_trapped[id] = ent_trap
	
	// set screen shake
	user_screen_shake(id, 4, 2, 5)
			
	// play sound
	EmitSound(id, sound_trapped)

	// reset invisible model trapped
	fm_set_rendering(ent_trap)
	
	// set task remove trap
	if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
	set_task(g_trap_time[zb3_get_user_zombie_type(id)], "RemoveTrap", id+TASK_REMOVETRAP)
}
public RemoveTrap(taskid)
{
	new id = ID_REMOVETRAP
	
	// remove trap
	remove_trapped_when_infected(id)
	
	if (task_exists(taskid)) remove_task(taskid)
}
remove_trapped_when_infected(id)
{
	new p_trapped = g_player_trapped[id]
	if (p_trapped)
	{
		// remove trap
		remove_traps_player( pev(p_trapped, pev_owner) , p_trapped )
		g_player_trapped[id] = 0
		zb3_reset_user_speed(id)
	}
}
create_trap(id)
{
	if (!zb3_get_user_zombie(id)) return -1;
	
	// get origin
	new Float:origin[3]
	pev(id, pev_origin, origin)

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return -1;
	
	// Set trap data
	set_pev(ent, pev_classname, TRAP_CLASSNAME)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_owner, id)
	//set_pev(ent, pev_iuser1, id)
	
	// Set trap size
	new Float:mins[3] = { -20.0, -20.0, 0.0 }
	new Float:maxs[3] = { 20.0, 20.0, 30.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// Set trap model
	engfunc(EngFunc_SetModel, ent, model_trap)

	// Set trap position
	set_pev(ent, pev_origin, origin)
	
	// set invisible
	fm_set_rendering(ent ,kRenderFxNone, 0, 0, 0, kRenderTransAlpha, TRAP_INVISIBLE)
	
	// trap counter
	g_total_traps[id]++
	TrapEnt[id][g_total_traps[id]] = ent
	
	return -1;
}

remove_traps_player(id, ent = 0)
{
	if( ent )
	{
		if (pev_valid(ent))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			g_total_traps[id]--
		}
		return
	}

	new iTotalTrap = g_total_traps[id]
	for (new i = 1; i <= iTotalTrap; i++)
	{
		new trap_ent = TrapEnt[id][i]

		if (pev_valid(trap_ent))
		{
			engfunc(EngFunc_RemoveEntity, trap_ent)
			g_total_traps[id]--
		}
	}
	
}

remove_traps()
{
	for (new i = 0; i <= MAX_TRAP; i++)
	{
		new trap_ent = fm_find_ent_by_class(-1, TRAP_CLASSNAME)

		if (pev_valid(trap_ent))
		{
			engfunc(EngFunc_RemoveEntity, trap_ent)
		}
	}
}

user_screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) // ??
	write_short((1<<12)*duration) // ??
	write_short((1<<12)*frequency) // ??
	message_end()
}

public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
		
	if(g_current_time[id] < g_trap_cooldown[zb3_get_user_zombie_type(id)])
		g_current_time[id]++
	
	static percent
	
	percent = floatround(floatclamp((g_current_time[id] / g_trap_cooldown[zb3_get_user_zombie_type(id)]) * 100.0, 0.0, 100.0))
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_synchud1, "%L", LANG_PLAYER, "ZOMBIE_SKILL_SINGLE", zclass_desc, percent)
	if(percent >= 99) 
		g_can_set_trap[id] = 1
		
}

stock EmitSound(id, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, CHAN_VOICE, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
