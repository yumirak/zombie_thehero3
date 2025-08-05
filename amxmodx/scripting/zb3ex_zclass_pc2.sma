#include <amxmodx>
#include <fakemeta>
#include <zombie_thehero2>

#define PLUGIN "NST Zombie Class Pc"
#define VERSION "1.0"
#define AUTHOR "NST"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zclasscfg/psycho.ini"
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
new Float:g_smoke_cooldown[2], Float:g_smoke_time[2]
new sprites_smoke[64], sound_smoke[64]
new g_zombie_classid

// Main Vars
new id_smoke1
new g_smoke[33], Float:g_smoke_origin[33][3]
// Task offsets
enum (+= 50)
{
	TASK_SMOKE = 22000,
	TASK_SMOKE_EXP
}
// IDs inside tasks
#define ID_SMOKE (taskid - TASK_SMOKE)
#define ID_SMOKE_EXP (taskid - TASK_SMOKE_EXP)

#define LANG_OFFICIAL LANG_PLAYER

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
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
	zb3_register_zcooldown(g_smoke_cooldown[ZOMBIE_HOST], g_smoke_cooldown[ZOMBIE_ORIGIN]);
	
	// Precache Class Resource
	id_smoke1 = precache_model(sprites_smoke)
	
	engfunc(EngFunc_PrecacheSound, sound_smoke)
}

public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_PSYCHO_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_PSYCHO_DESC")
	
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

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SMOKE_TIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_smoke_time[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SMOKE_TIME_HOST", buffer, sizeof(buffer), DummyArray); g_smoke_time[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SMOKE_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_smoke_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SMOKE_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_smoke_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SMOKE_START", sound_smoke, sizeof(sound_smoke), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SMOKE_SPR", sprites_smoke, sizeof(sprites_smoke), DummyArray);
}

public zb3_user_infected(id, infector, infect_flag)
{
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	switch(infect_flag)
	{
		case INFECT_VICTIM: 
		{
			reset_skill(id)
		}
	}
}

public reset_skill(id)
{
	g_smoke[id] = 0

	if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id))
		reset_skill(id)
}

// public cmd_drop(id)
public zb3_do_skill(id, class, skullnum)
{
	if(class != g_zombie_classid || skullnum != 0)
		return 0
	if(g_smoke[id])
		return 0
		
	Do_Smoke(id)
	return 1
}

public Do_Smoke(id)
{
	g_smoke[id] = 1
		
	// task smoke exp
	pev(id,pev_origin,g_smoke_origin[id])
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
	SmokeExplode(id+TASK_SMOKE_EXP)
		
	// task remove smoke
	new Float:time_s
	time_s = g_smoke_time[zb3_get_user_zombie_type(id)] // zb3_get_user_level(id) > 1 ? float(SMOKE_TIME_ORIGIN) : float(SMOKE_TIME_HOST)

	if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
	set_task(time_s, "RemoveSmoke", id+TASK_SMOKE)
		
	EmitSound(id, CHAN_VOICE, sound_smoke)

	return PLUGIN_HANDLED
	
}

public SmokeExplode(taskid)
{
	new id = ID_SMOKE_EXP
	
	// remove smoke
	if (!g_smoke[id] || !zb3_get_user_zombie(id) || zb3_get_user_zombie_class(id) != g_zombie_classid)
	{
		if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
		return;
	}
	
	new Float:origin[3]
	origin[0] = g_smoke_origin[id][0] + random_num(-25,25)
	origin[1] = g_smoke_origin[id][1] + random_num(-25,25)
	origin[2] = g_smoke_origin[id][2] + random_num(0,25)
	
	new flags = pev(id, pev_flags)
	if (!((flags & FL_DUCKING) && (flags & FL_ONGROUND)))
		origin[2] -= 36.0
	
	Create_Smoke_Group(origin)
	
	// task smoke exp
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
	set_task(0.5, "SmokeExplode", id+TASK_SMOKE_EXP)
	
	return;
}
public RemoveSmoke(taskid)
{
	new id = ID_SMOKE
	
	// remove smoke
	g_smoke[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
Create_Smoke_Group(Float:position[3])
{
	new Float:origin[12][3]
	get_spherical_coord(position, 40.0, 0.0, 0.0, origin[0])
	get_spherical_coord(position, 40.0, 90.0, 0.0, origin[1])
	get_spherical_coord(position, 40.0, 180.0, 0.0, origin[2])
	get_spherical_coord(position, 40.0, 270.0, 0.0, origin[3])
	get_spherical_coord(position, 100.0, 0.0, 0.0, origin[4])
	get_spherical_coord(position, 100.0, 45.0, 0.0, origin[5])
	get_spherical_coord(position, 100.0, 90.0, 0.0, origin[6])
	get_spherical_coord(position, 100.0, 135.0, 0.0, origin[7])
	get_spherical_coord(position, 100.0, 180.0, 0.0, origin[8])
	get_spherical_coord(position, 100.0, 225.0, 0.0, origin[9])
	get_spherical_coord(position, 100.0, 270.0, 0.0, origin[10])
	get_spherical_coord(position, 100.0, 315.0, 0.0, origin[11])
	
	for (new i = 0; i < 3; i++)
	{
			create_Smoke(origin[i], id_smoke1, 70, 0)
	}
}
create_Smoke(const Float:position[3], sprite_index, life, framerate)
{
	// Alphablend sprite, move vertically 30 pps
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE) // TE_SMOKE (5)
	engfunc(EngFunc_WriteCoord, position[0]) // position.x
	engfunc(EngFunc_WriteCoord, position[1]) // position.y
	engfunc(EngFunc_WriteCoord, position[2]) // position.z
	write_short(sprite_index) // sprite index
	write_byte(life) // scale in 0.1's
	write_byte(framerate) // framerate
	message_end()
}
get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}
