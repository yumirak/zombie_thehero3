#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3EX] ZClass: Light"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Light"
new const zclass_desc[] = "Hiding"
new const zclass_sex = SEX_FEMALE
new const zclass_lockcost = 0
new const zclass_hostmodel[] = "speed_zombi_host"
new const zclass_originmodel[] = "speed_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_speed_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_speed_zombi.mdl"
new const zclass_clawsinvisible[] = "models/zombie_thehero/v_knife_speed_zombi_invisible.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zombibomb_speed_zombi.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zombibomb_speed_zombi.mdl"
new const Float:zclass_gravity = 0.7
new const Float:zclass_speedhost = 295.0
new const Float:zclass_speedorigin = 295.0
new const Float:zclass_knockback = 3.0
new const Float:zclass_painshock = 0.1
new const Float:zclass_dmgmulti  = 1.3

new const DeathSound[2][] =
{
	"zombie_thehero/zombi_death_female_1.wav",
	"zombie_thehero/zombi_death_female_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombi_hurt_female_1.wav",
	"zombie_thehero/zombi_hurt_female_2.wav"	
}
new const HealSound[] = "zombie_thehero/zombi_heal_female.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution_female.wav"
new const Float:ClawsDistance1 = 1.0
new const Float:ClawsDistance2 = 1.1

new g_zombie_classid, g_can_invisible[33], g_invis[33], Float:g_current_time[33]
new const invisible_startsound[] = "zombie_thehero/zombi_pressure_female.wav"

#define LANG_OFFICIAL LANG_PLAYER

#define INVISIBLE_TIME_HOST 10.0
#define INVISIBLE_TIME_ORIGIN 20.0
#define INVISIBLE_COOLDOWN_HOST 30.0
#define INVISIBLE_COOLDOWN_ORIGIN 30.0
#define INVISIBLE_SPEED_HOST 195
#define INVISIBLE_SPEED_ORIGIN 215

#define INVISIBLE_FOV 100

// Task
#define TASK_INVISIBLE 13000
#define TASK_COOLDOWN 13001

new g_synchud1

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	register_event("HLTV", "Event_CheckWeapon", "be", "1=1")
	
	register_clcmd("drop", "cmd_drop")

	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage", false);

	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
}

public plugin_precache()
{
	// Register Zombie Class
	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speedhost, zclass_speedorigin, zclass_knockback, zclass_dmgmulti, zclass_painshock, 
	ClawsDistance1, ClawsDistance2)
	
	zb3_set_zombie_class_data(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin, 
	DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound)
	
	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheSound, invisible_startsound)
	engfunc(EngFunc_PrecacheModel, zclass_clawsinvisible)
}
public zb3_user_infected(id, infector, infect_flag)
{
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	switch(infect_flag)
	{
		case INFECT_VICTIM: reset_skill(id, true) 
		case INFECT_CHANGECLASS:
		{
			if(g_invis[id]) {
				zb3_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 16)
				zb3_set_user_speed(id, zb3_get_user_level(id) > 1 ? INVISIBLE_SPEED_ORIGIN : INVISIBLE_SPEED_HOST)
			}
		} 
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
		g_current_time[id] = zb3_get_user_level(id) > 1 ? INVISIBLE_COOLDOWN_ORIGIN + INVISIBLE_TIME_ORIGIN : INVISIBLE_COOLDOWN_HOST + INVISIBLE_TIME_HOST

	g_can_invisible[id] = reset_time ? 1 : 0
	g_invis[id] = 0

	zb3_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255)
	if(task_exists(id+TASK_INVISIBLE)) remove_task(id+TASK_INVISIBLE)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id))
		reset_skill(id, false)
}

public zb3_user_dead(id) 
{
	if(!zb3_get_user_zombie(id) || zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	reset_skill(id, false)
}

public Event_CheckWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(!zb3_get_user_zombie(id))
		return 1
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 1
	
	if(!g_invis[id])
		return 1
	static ViewModel[64]
	pev(id, pev_viewmodel2, ViewModel, sizeof(ViewModel))

	if(!equal(ViewModel, zclass_clawsinvisible) && get_user_weapon(id) == CSW_KNIFE ) 
		set_pev(id, pev_viewmodel2, zclass_clawsinvisible)
	return 0
}

public fw_takedamage(victim, inflictor, attacker, Float: damage)
{
	if(!is_user_alive(victim))
		return HAM_IGNORED;
	if(!zb3_get_user_zombie(victim))
		return HAM_IGNORED;
	if( zb3_get_user_zombie_class(victim) != g_zombie_classid)
		return HAM_IGNORED;
	if(!g_invis[victim])
		return HAM_IGNORED;
	
	damage *= 2.0;
	SetHamParamFloat(4, damage);
	
	return HAM_HANDLED;
}
public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(!zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return PLUGIN_CONTINUE
	if(!g_can_invisible[id] || g_invis[id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZOMBIE_SKILL_NOT_READY", zclass_desc , floatround(get_cooldowntime(id) - g_current_time[id]))
		return PLUGIN_HANDLED
	}
		
	Do_Invisible(id)	
		
	return PLUGIN_HANDLED
}

public Do_Invisible(id)
{
	zb3_reset_user_speed(id)
	
	// Set Vars
	g_invis[id] = 1
	g_can_invisible[id] = 0
	g_current_time[id] = 0.0
	
	// Set Render Red
	zb3_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 16)

	// Set MaxSpeed & Gravity
	zb3_set_user_speed(id, zb3_get_user_level(id) > 1 ? INVISIBLE_SPEED_ORIGIN : INVISIBLE_SPEED_HOST)
	
	// Play Berserk Sound
	EmitSound(id, CHAN_VOICE, invisible_startsound)

	// Set Invisible Claws
	set_pev(id, pev_viewmodel2, zclass_clawsinvisible)
	
	// Set Time
	static Float:SkillTime
	SkillTime = zb3_get_user_level(id) > 1 ? INVISIBLE_TIME_ORIGIN : INVISIBLE_TIME_HOST
	if(task_exists(id+TASK_INVISIBLE)) remove_task(id+TASK_INVISIBLE)
	set_task(SkillTime, "Remove_Invisible", id+TASK_INVISIBLE)
}

public Remove_Invisible(id)
{
	id -= TASK_INVISIBLE

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	if(!g_invis[id])
		return	

	// Set Vars
	g_invis[id] = 0
	//g_can_invisible[id] = 0	
	
	// Reset Rendering
	zb3_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255)
	
	// Remove Invisible Claws
	new Claws[128]
	formatex(Claws, sizeof(Claws), "models/zombie_thehero/%s", zb3_get_user_level(id) > 1 ? zclass_clawsmodelorigin : zclass_clawsmodelhost)
	set_pev(id, pev_viewmodel2, Claws)
	
	// Reset Speed
	static Float:DefaultSpeed
	DefaultSpeed = zb3_get_user_level(id) > 1 ? zclass_speedorigin : zclass_speedhost
	
	zb3_set_user_speed(id, floatround(DefaultSpeed))		
}

public zb3_skill_show(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
	if(g_current_time[id] < get_cooldowntime(id))
		g_current_time[id]++
	
	static percent

	percent = floatround(floatclamp(g_current_time[id] / get_cooldowntime(id) * 100.0, 0.0, 100.0))
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_synchud1, "%L", LANG_PLAYER, "ZOMBIE_SKILL_SINGLE", zclass_desc, percent)

	if(percent >= 99) {
		if(!g_can_invisible[id]) g_can_invisible[id] = 1
	}	
}
public zb3_zombie_evolution(id, level)
{
	if(level > 1 && zb3_get_user_zombie(id) && zb3_get_user_zombie_class(id) == g_zombie_classid )
	{
		if(g_invis[id] && task_exists(id+TASK_INVISIBLE) )
		{
			remove_task(id+TASK_INVISIBLE)
			Remove_Invisible(id+TASK_INVISIBLE) // break invisibility when evolution
		}
	}
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
stock Float:get_cooldowntime(id)
{
	if(!zb3_get_user_zombie(id))
		return 0.0
	return zb3_get_user_level(id) > 1 ? INVISIBLE_COOLDOWN_ORIGIN : INVISIBLE_COOLDOWN_HOST
}
