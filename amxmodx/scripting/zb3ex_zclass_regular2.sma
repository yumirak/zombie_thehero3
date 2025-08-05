#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Regular"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zclasscfg/regular.ini"
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
new Array:BeserkSound, BeserkSoundString1[64], BeserkSoundString2[64]
new Array:ShellColor, g_beserk_shell_color[3]
new berserk_startsound[64]
new Float:g_beserk_time[2], Float:g_beserk_cooldown[2], g_beserk_cost, g_beserk_speed //, Float:g_beserk_gravity

new g_zombie_classid, g_berserking[33]

#define LANG_OFFICIAL LANG_PLAYER

#define BERSERK_COLOR_R 255
#define BERSERK_COLOR_G 3
#define BERSERK_COLOR_B 0

#define FASTRUN_FOV 110

enum (+= 50)
{
	TASK_BERSERKING = 21000,
	TASK_COOLDOWN,
	TASK_BERSERK_SOUND
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	// // register_clcmd("drop", "cmd_drop")

	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage", false);
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)

	DeathSound = ArrayCreate(64, 1)
	HurtSound = ArrayCreate(64, 1)
	BeserkSound = ArrayCreate(64, 1)
	ShellColor = ArrayCreate(4, 1)

	load_cfg()

	ArrayGetString(DeathSound, 0, DeathSoundString1, charsmax(DeathSoundString1))
	ArrayGetString(DeathSound, 1, DeathSoundString2, charsmax(DeathSoundString2))
	ArrayGetString(HurtSound, 0, HurtSoundString1, charsmax(HurtSoundString1))
	ArrayGetString(HurtSound, 1, HurtSoundString2, charsmax(HurtSoundString2))
	ArrayGetString(BeserkSound, 0, BeserkSoundString1, charsmax(BeserkSoundString1))
	ArrayGetString(BeserkSound, 1, BeserkSoundString2, charsmax(BeserkSoundString2))

	for(new i; i < 3; i++)
	{
		static szTemp[8]
		ArrayGetString(ShellColor, i, szTemp, charsmax(szTemp)) // ArrayGetCell(ShellColor, i)
		g_beserk_shell_color[i] = str_to_num(szTemp)
		server_print("%i", g_beserk_shell_color[i])
	}

	// Precache Class Resource
	engfunc(EngFunc_PrecacheSound, berserk_startsound)
	engfunc(EngFunc_PrecacheSound, BeserkSoundString1)
	engfunc(EngFunc_PrecacheSound, BeserkSoundString2)
	
	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speedhost, zclass_speedorigin, zclass_knockback, zclass_dmgmulti, zclass_painshock, 
	ClawsDistance1, ClawsDistance2)
	
	zb3_set_zombie_class_data(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin, 
		DeathSoundString1, DeathSoundString2, HurtSoundString1, HurtSoundString2, HealSound, EvolSound)

	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	zb3_register_zcooldown(g_beserk_cooldown[ZOMBIE_HOST], g_beserk_cooldown[ZOMBIE_ORIGIN]);
}
public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_REGULAR_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_REGULAR_DESC")
	
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

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BERSERK_TIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_beserk_time[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BERSERK_TIME_HOST", buffer, sizeof(buffer), DummyArray); g_beserk_time[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BERSERK_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_beserk_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BERSERK_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_beserk_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEALTH_COST", buffer, sizeof(buffer), DummyArray); g_beserk_cost = str_to_num(buffer)
	// zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "GRAVITY", buffer, sizeof(buffer), DummyArray); g_beserk_gravity = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SPEED", buffer, sizeof(buffer), DummyArray); g_beserk_speed = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BESERK_START", berserk_startsound, sizeof(berserk_startsound), DummyArray);
	zb3_load_setting_string(true,  SETTING_FILE, SETTING_SKILL, "BESERK_SOUND", buffer, 0, BeserkSound);

	zb3_load_setting_string(true, SETTING_FILE, SETTING_SKILL, "SHELL_COLOR", buffer, 0, ShellColor);

}
public zb3_user_infected(id, infector, infect_flag)
{
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	switch(infect_flag)
	{
		case INFECT_VICTIM: reset_skill(id) 
	}
}
public zb3_user_change_class(id, oldclass, newclass)
{
	if(newclass == g_zombie_classid && oldclass != newclass)
		reset_skill(id)
	if(oldclass == g_zombie_classid)
		reset_skill(id)
}

public reset_skill(id)
{
	g_berserking[id] = 0
	
	if(task_exists(id+TASK_BERSERKING)) remove_task(id+TASK_BERSERKING)
	if(task_exists(id+TASK_BERSERK_SOUND)) remove_task(id+TASK_BERSERK_SOUND)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id))
		reset_skill(id)//set_task(0.1, "reset_skill", id)
}

public zb3_user_dead(id) 
{
	if(!zb3_get_user_zombie(id))
		return;
	if( zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	reset_skill(id)
}

public fw_takedamage(victim, inflictor, attacker, Float: damage)
{
	if(!is_user_alive(victim))
		return HAM_IGNORED;
	if(!zb3_get_user_zombie(victim))
		return HAM_IGNORED;
	if( zb3_get_user_zombie_class(victim) != g_zombie_classid)
		return HAM_IGNORED;
	if(!g_berserking[victim])
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

	Do_Berserk(id)
	return 1
}

public Do_Berserk(id)
{
	if((get_user_health(id) - g_beserk_cost) > 0)
	{
		zb3_reset_user_speed(id)
		
		// Set Vars
		g_berserking[id] = 1

		// Decrease Health
		zb3_set_user_health(id, get_user_health(id) - g_beserk_cost)
		
		// Set Render Red
		zb3_set_user_rendering(id, kRenderFxGlowShell, g_beserk_shell_color[0], g_beserk_shell_color[1], g_beserk_shell_color[2], kRenderNormal, 0)
		
		// Set MaxSpeed
		zb3_set_user_speed(id, g_beserk_speed)
		
		// Play Berserk Sound
		EmitSound(id, CHAN_VOICE, berserk_startsound)
		
		// Set Task
		set_task(2.0, "Berserk_HeartBeat", id+TASK_BERSERK_SOUND)
		
		static Float:SkillTime
		SkillTime = g_beserk_time[zb3_get_user_zombie_type(id)]
		if(task_exists(id+TASK_BERSERKING)) remove_task(id+TASK_BERSERKING)
		set_task(SkillTime, "Remove_Berserk", id+TASK_BERSERKING)
	} else {
		client_print(id, print_center, "%L", LANG_OFFICIAL, "ZOMBIE_REGULAR_CANTBERSERK")
	}
}

public Remove_Berserk(id)
{
	id -= TASK_BERSERKING

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	if(!g_berserking[id])
		return	

	// Set Vars
	g_berserking[id] = 0
	
	// Reset Rendering
	zb3_set_user_rendering(id)
	zb3_reset_user_speed(id)
}

public Berserk_HeartBeat(id)
{
	id -= TASK_BERSERK_SOUND
	
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	if(!g_berserking[id])
		return

	EmitSound(id, CHAN_VOICE, random_num(1,2) == 1 ? BeserkSoundString1 : BeserkSoundString2)

	set_task(2.0, "Berserk_HeartBeat", id+TASK_BERSERK_SOUND)
}

public zb3_zombie_evolution(id, level)
{
	if(level > 1 && zb3_get_user_zombie(id) && zb3_get_user_zombie_class(id) == g_zombie_classid)
	{
		if(g_berserking[id] && task_exists(id+TASK_BERSERKING))
		{
			remove_task(id+TASK_BERSERKING) // break berserk when evolution
			Remove_Berserk(id+TASK_BERSERKING)
		}
	}
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
