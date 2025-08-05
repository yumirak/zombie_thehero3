#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Heavy"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zclasscfg/heavy.ini"
new const SETTING_CONFIG[] = "Config"
new const SETTING_MODELS[] = "Models"
new const SETTING_SOUNDS[] = "Sounds"
new const SETTING_SKILL[] = "Skill"
// Zombie Configs
new zclass_sex, zclass_lockcost
new zclass_name[32], zclass_desc[32], zclass_hostmodel[32], zclass_originmodel[32], zclass_clawsmodelhost[32], zclass_clawsmodelorigin[32]
new zombiegrenade_modelhost[64], zombiegrenade_modelorigin[64], HealSound[64], EvolSound[64]
new Float:zclass_gravity, Float:zclass_speed, Float:zclass_knockback
new Float:zclass_dmgmulti, Float:zclass_painshock
new DeathSound[64], HurtSound[64]

new Float:g_trap_cooldown[2], Float:g_trap_time[2], Float:g_trap_livetime[2]
new TrapSlow[64], model_trap[64], sound_trapsetup[64], sound_trapped[64]

new g_zombie_classid

#define TRAP_CLASSNAME "zb_trap"
#define TRAP_INVISIBLE 150

// Vars
new g_msgScreenShake

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)

	register_touch(TRAP_CLASSNAME, "*", "fw_Trap_Touch")
	register_think(TRAP_CLASSNAME, "fw_Trap_Think")

	g_msgScreenShake = get_user_msgid("ScreenShake")
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)

	load_cfg()

	// Register Zombie Class
	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback, zclass_dmgmulti, zclass_painshock)

	zb3_set_zombie_class_model(zclass_hostmodel, zclass_originmodel)
	zb3_set_zombie_class_viewmodel(zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zb3_set_zombie_class_sound(DeathSound, HurtSound, HealSound, EvolSound)

	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	zb3_register_zcooldown(g_trap_cooldown[ZOMBIE_HOST], g_trap_cooldown[ZOMBIE_ORIGIN]);
	
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
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SOUNDS, "EVOL", EvolSound, sizeof(EvolSound), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_trap_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_trap_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_TIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_trap_time[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_TIME_HOST", buffer, sizeof(buffer), DummyArray); g_trap_time[ZOMBIE_HOST] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_LIVETIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_trap_livetime[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_LIVETIME_HOST", buffer, sizeof(buffer), DummyArray); g_trap_livetime[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_MODEL", model_trap, sizeof(model_trap), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_SPR_SLOW", TrapSlow, sizeof(TrapSlow), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_SOUND_START", sound_trapsetup, sizeof(sound_trapsetup), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TRAP_SOUND_TRAPPED", sound_trapped, sizeof(sound_trapped), DummyArray);
}

public zb3_game_start(start_type)
{
	remove_entity_name(TRAP_CLASSNAME)
}

// public cmd_drop(id)
public zb3_do_skill(id, class, skullnum)
{
	if(class != g_zombie_classid || skullnum != 0)
		return 0

	return create_trap(id)
}

public fw_Trap_Think(ent)
{
	if(!is_entity(ent))
		return

	static owner, catchid, Float:Time, Float:CurTime; 
	owner = pev(ent, pev_owner)
	pev(ent, pev_fuser1, Time)
	CurTime = get_gametime()

	if(!zb3_get_user_zombie(owner) || (CurTime > Time))
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return
	}	

	switch(pev(ent, pev_sequence)) // trap animation
	{
		case 1: 
		{ 
			switch(pev(ent, pev_frame))
			{
				case 0..230: set_pev(ent, pev_frame, pev(ent, pev_frame) + 1.0)
				default: set_pev(ent, pev_frame, 20.0)
			}
		}
		default: set_pev(ent, pev_frame, 0.0)
	}	
	
	set_pev(ent, pev_nextthink, CurTime + 0.025)

	catchid = pev(ent, pev_iuser1)
	
	if(!is_user_alive(catchid))
		return

	if(!zb3_get_user_zombie(catchid))
	{
		zb3_do_knockback(ent, catchid, 100.0, ZB3_KFL_PULL)
	}
	else
	{
		engfunc(EngFunc_RemoveEntity, ent)
		return
	}

}

public fw_Trap_Touch(ent, id)
{
	if(!is_entity(id) || !is_user_alive(id) || zb3_get_user_zombie(id))
		return

	if (pev(ent, pev_iuser1) > 0)
		return

	Trapped(id, ent)
}

public Trapped(id, ent)
{
	// set ent trapped of player
	set_pev(ent, pev_iuser1, id)
	set_pev(ent, pev_fuser1, get_gametime() + g_trap_time[zb3_get_user_zombie_type(id)])
	set_pev(ent, pev_sequence, 1)

	// set screen shake
	user_screen_shake(id, 4, 2, 5)
			
	// play sound
	emit_sound(id, CHAN_AUTO, sound_trapped, 1.0, ATTN_NORM, 0, PITCH_NORM)

	// reset invisible model trapped
	fm_set_rendering(ent)
}

public create_trap(id)
{
	if (!zb3_get_user_zombie(id)) 
		return 0;
	
	// get origin
	new Float:origin[3]
	pev(id, pev_origin, origin)

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) 
		return 0;
	
	// Set trap data
	set_pev(ent, pev_classname, TRAP_CLASSNAME)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, MOVETYPE_TOSS)
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_iuser1, -1)
	set_pev(ent, pev_fuser1, get_gametime() + g_trap_livetime[zb3_get_user_zombie_type(id)])
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
	
	// Set trap size
	new Float:mins[3] = { -40.0, -40.0, 0.0 }
	new Float:maxs[3] = { 40.0, 40.0, 30.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// Set trap model
	engfunc(EngFunc_SetModel, ent, model_trap)

	// Set trap position
	set_pev(ent, pev_origin, origin)
	emit_sound(id, CHAN_AUTO, sound_trapsetup, 1.0, ATTN_NORM, 0, PITCH_NORM)

	// set invisible
	fm_set_rendering(ent ,kRenderFxNone, 0, 0, 0, kRenderTransAlpha, TRAP_INVISIBLE)
	return 1;
}

stock user_screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) // ??
	write_short((1<<12)*duration) // ??
	write_short((1<<12)*frequency) // ??
	message_end()
}
