#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3EX] ZClass: Light"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zclasscfg/light.ini"
new const SETTING_CONFIG[] = "Config"
new const SETTING_MODELS[] = "Models"
new const SETTING_SOUNDS[] = "Sounds"
new const SETTING_SKILL[] = "Skill"

new zclass_sex, zclass_lockcost
new zclass_name[32], zclass_desc[32], zclass_hostmodel[32], zclass_originmodel[32], zclass_clawsmodelhost[32], zclass_clawsmodelorigin[32]
new zombiegrenade_modelhost[64], zombiegrenade_modelorigin[64], zclass_clawsinvisible[64], HealSound[64], EvolSound[64]
new Float:zclass_gravity, Float:zclass_speed, Float:zclass_knockback
new Float:zclass_dmgmulti, Float:zclass_painshock
new DeathSound[64], HurtSound[64]

new Array:GenericSound
new Float:g_invis_time[2], Float:g_invis_cooldown[2], g_invis_speed[2], invisible_startsound[64]

new g_zombie_classid, g_invis[33]
new buffer[128]
#define LANG_OFFICIAL LANG_PLAYER

// Task
enum (+= 50)
{
	TASK_INVISIBLE = 23000,
	TASK_COOLDOWN
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	
	register_event("HLTV", "Event_CheckWeapon", "be", "1=1")
	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage", false);

}

public plugin_precache()
{
	static size, i;
	register_dictionary(LANG_FILE)

	GenericSound = ArrayCreate(64, 1)

	load_cfg()

	// Register Zombie Class
	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback, zclass_dmgmulti, zclass_painshock)

	zb3_set_zombie_class_model(zclass_hostmodel, zclass_originmodel)
	zb3_set_zombie_class_viewmodel(zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zb3_set_zombie_class_sound(DeathSound, HurtSound, HealSound, EvolSound)

	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	zb3_register_zcooldown(g_invis_cooldown[ZOMBIE_HOST], g_invis_cooldown[ZOMBIE_ORIGIN]);
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheSound, invisible_startsound)
	engfunc(EngFunc_PrecacheModel, zclass_clawsinvisible)

	size = ArraySize(GenericSound)
	for(i = 0; i < size; i++)
	{
		ArrayGetString(GenericSound, i, buffer, charsmax(buffer))
		format(buffer, charsmax(buffer), "sound/%s", buffer)
		engfunc(EngFunc_PrecacheGeneric, buffer)
	}
}

public load_cfg()
{
	static Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_SPEED_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_SPEED_DESC")
	
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "COST", buffer, sizeof(buffer), DummyArray); zclass_lockcost = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "GENDER", buffer, sizeof(buffer), DummyArray); zclass_sex = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "GRAVITY", buffer, sizeof(buffer), DummyArray); zclass_gravity = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SPEED", buffer, sizeof(buffer), DummyArray); zclass_speed = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "KNOCKBACK", buffer, sizeof(buffer), DummyArray); zclass_knockback = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "DAMAGE_MULTIPLIER", buffer, sizeof(buffer), DummyArray); zclass_dmgmulti = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "PAINSHOCK", buffer, sizeof(buffer), DummyArray); zclass_painshock = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "PLAYERMODEL_ORIGIN", zclass_originmodel, sizeof(zclass_originmodel), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "PLAYERMODEL_HOST", zclass_hostmodel, sizeof(zclass_hostmodel), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "VIEWMODEL_ORIGIN", zclass_clawsmodelorigin, sizeof(zclass_clawsmodelorigin), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "VIEWMODEL_HOST", zclass_clawsmodelhost, sizeof(zclass_clawsmodelhost), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "GRENADE_VIEWMODEL_ORIGIN", zombiegrenade_modelorigin, sizeof(zombiegrenade_modelorigin), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_MODELS, "GRENADE_VIEWMODEL_HOST", zombiegrenade_modelhost, sizeof(zombiegrenade_modelhost), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SOUNDS, "DEATH", DeathSound, sizeof(DeathSound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SOUNDS, "HURT", HurtSound, sizeof(HurtSound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SOUNDS, "HEAL", HealSound, sizeof(HealSound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SOUNDS, "EVOL", EvolSound, sizeof(EvolSound), DummyArray);\
	zb3_load_setting_string(true,  SETTING_FILE, SETTING_SOUNDS, "GENERIC", buffer, 0, GenericSound);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_VIEWMODEL", zclass_clawsinvisible, sizeof(zclass_clawsinvisible), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_TIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_invis_time[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_TIME_HOST", buffer, sizeof(buffer), DummyArray); g_invis_time[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_invis_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_invis_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_SPEED_ORIGIN", buffer, sizeof(buffer), DummyArray); g_invis_speed[ZOMBIE_ORIGIN] = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_SPEED_HOST", buffer, sizeof(buffer), DummyArray); g_invis_speed[ZOMBIE_HOST] = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "INVISIBLE_START", invisible_startsound, sizeof(invisible_startsound), DummyArray);

}
public zb3_user_infected(id, infector, infect_flag, newclass, oldclass)
{
	if(newclass != g_zombie_classid)
	{
		if(oldclass != g_zombie_classid)
			return

		reset_skill(id)
		return;
	}

	switch(infect_flag)
	{
		case INFECT_CHANGECLASS..INFECT_EVOLUTION:
		{
			if(!g_invis[id])
				return

			zb3_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransColor, 16)
			zb3_set_user_speed(id, g_invis_speed[zb3_get_user_zombie_type(id)])
			set_pev(id, pev_viewmodel2, zclass_clawsinvisible)
		}
		default: reset_skill(id)
	}
}

public reset_skill(id)
{
	g_invis[id] = 0
	if(task_exists(id+TASK_INVISIBLE)) remove_task(id+TASK_INVISIBLE)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id))
		reset_skill(id)
}

public zb3_user_dead(id) 
{
	if(!zb3_get_user_zombie(id) || zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	reset_skill(id)
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
// public cmd_drop(id)
public zb3_do_skill(id, class, skullnum)
{
	if(class != g_zombie_classid || skullnum != 0)
		return 0
	Do_Invisible(id)	
	return 1
}

public Do_Invisible(id)
{
	zb3_reset_user_speed(id)
	g_invis[id] = 1
	// Set Render Red
	zb3_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransColor, 16)

	// Set MaxSpeed & Gravity
	zb3_set_user_speed(id, g_invis_speed[zb3_get_user_zombie_type(id)])
	
	// Play Berserk Sound
	emit_sound(id, CHAN_VOICE, invisible_startsound, 1.0, ATTN_NORM, 0, PITCH_NORM)

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
	g_invis[id] = 0
	
	// Reset Rendering
	zb3_set_user_rendering(id)
	
	// Remove Invisible Claws
	new Claws[128]
	formatex(Claws, sizeof(Claws), "models/%s/%s", GAMEDIR, zb3_get_user_level(id) > 1 ? zclass_clawsmodelorigin : zclass_clawsmodelhost)
	set_pev(id, pev_viewmodel2, Claws)

	zb3_reset_user_speed(id)	
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
