#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3EX] ZClass: Light"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zombie_thehero2/zclasscfg/light.ini"
new const SETTING_CONFIG[] = "Config"
new const SETTING_MODELS[] = "Models"
new const SETTING_SOUNDS[] = "Sounds"
new const SETTING_SKILL[] = "Skill"

new const zombi_death_sound[][] = // temp until we have global precache list
{
	"zombie_thehero/zombi_female_breath.wav",
	"zombie_thehero/zombi_female_headdown.wav",
	"zombie_thehero/zombi_female_headup.wav",
	"zombie_thehero/zombi_female_laugh.wav",
	"zombie_thehero/zombi_female_scream.wav"
}

new zclass_sex, zclass_lockcost
new zclass_name[32], zclass_desc[32], zclass_hostmodel[32], zclass_originmodel[32], zclass_clawsmodelhost[32], zclass_clawsmodelorigin[32]
new zombiegrenade_modelhost[64], zombiegrenade_modelorigin[64], zclass_clawsinvisible[64], HealSound[64], EvolSound[64]
new Float:zclass_gravity, Float:zclass_speedhost, Float:zclass_speedorigin, Float:zclass_knockback
new Float:zclass_dmgmulti, Float:zclass_painshock, Float:ClawsDistance1, Float:ClawsDistance2
new Array:DeathSound, DeathSoundString1[64], DeathSoundString2[64]
new Array:HurtSound, HurtSoundString1[64], HurtSoundString2[64]
new Float:g_invis_time[2], Float:g_invis_cooldown[2], g_invis_speed[2], invisible_startsound[64]

new g_zombie_classid, g_can_invisible[33], g_invis[33], Float:g_current_time[33]

#define LANG_OFFICIAL LANG_PLAYER

// Task
#define TASK_INVISIBLE 13000
#define TASK_COOLDOWN 13001

new g_synchud1

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	
	register_event("HLTV", "Event_CheckWeapon", "be", "1=1")
	
	register_clcmd("drop", "cmd_drop")

	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage", false);

	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
}

public plugin_precache()
{
	static size, i;
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
	engfunc(EngFunc_PrecacheSound, invisible_startsound)
	engfunc(EngFunc_PrecacheModel, zclass_clawsinvisible)

	size = sizeof(zombi_death_sound)
	for(i = 0; i < size; i++)
		engfunc(EngFunc_PrecacheSound, zombi_death_sound[i])
}

public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_SPEED_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_SPEED_DESC")
	
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

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_VIEWMODEL", zclass_clawsinvisible, sizeof(zclass_clawsinvisible), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_TIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_invis_time[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_TIME_HOST", buffer, sizeof(buffer), DummyArray); g_invis_time[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_invis_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_invis_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_SPEED_ORIGIN", buffer, sizeof(buffer), DummyArray); g_invis_speed[ZOMBIE_ORIGIN] = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_SPEED_HOST", buffer, sizeof(buffer), DummyArray); g_invis_speed[ZOMBIE_HOST] = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_START", invisible_startsound, sizeof(invisible_startsound), DummyArray);

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
				zb3_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransColor, 16)
				zb3_set_user_speed(id, g_invis_speed[zb3_get_user_zombie_type(id)])
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
		g_current_time[id] = g_invis_cooldown[zb3_get_user_zombie_type(id)]

	g_can_invisible[id] = reset_time ? 1 : 0
	g_invis[id] = 0

	zb3_set_user_rendering(id)
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
	zb3_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransColor, 16)

	// Set MaxSpeed & Gravity
	zb3_set_user_speed(id, g_invis_speed[zb3_get_user_zombie_type(id)])
	
	// Play Berserk Sound
	EmitSound(id, CHAN_VOICE, invisible_startsound)

	// Set Invisible Claws
	set_pev(id, pev_viewmodel2, zclass_clawsinvisible)
	
	// Set Time
	static Float:SkillTime
	SkillTime = g_invis_time[zb3_get_user_zombie_type(id)]
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
	zb3_set_user_rendering(id)
	
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
	return g_invis_cooldown[zb3_get_user_zombie_type(id)]
}
