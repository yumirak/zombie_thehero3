#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Banshee"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zombie_thehero2/zclasscfg/banshee.ini"
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
new BatModel[64], BatFireSound[64], BatFlySound[64], BatFailSound[64], Catch_Player_Male[64], Catch_Player_Female[64], BatExpSpr[64]
new Float:g_bat_cooldown[2], g_bat_range[2], Float:g_bat_starttime, g_bat_velocity[2], g_bat_catch_velocity[2], Float:g_bat_timelive[2]

new g_zombie_classid
new g_synchud1, g_Msg_Shake, g_BatExpSpr_Id, Float:g_current_time[33]
new g_can_skill[33], g_skilling[33]

const pev_catched = pev_iuser1
const pev_catchid = pev_iuser2
const pev_maxdistance = pev_iuser3
const pev_catchedspeed = pev_iuser4
const pev_timechange = pev_fuser1
const pev_livetime = pev_fuser2

#define LANG_OFFICIAL LANG_PLAYER

#define BAT_CLASSNAME "bat"
#define BAT_FOV 100
#define BAT_ANIM 2
#define BAT_PLAYERANIM 151
#define BAT_PLAYERANIM_HOLD 152

#define TASK_SKILLING 312312
#define TASK_CATCHING 423423
#define TASK_BATFLYING 23423

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_clcmd("drop", "cmd_drop")
	
	//register_forward(FM_EmitSound, "fw_EmitSound")
	//register_forward(FM_TraceLine, "fw_TraceLine")
	//register_forward(FM_TraceHull, "fw_TraceHull")		

	RegisterHam(Ham_TakeDamage, "player", "fw_takedamage", false);

	register_touch(BAT_CLASSNAME, "*", "fw_Bat_Touch")
	register_think(BAT_CLASSNAME, "fw_Bat_Think")	
	g_Msg_Shake = get_user_msgid("ScreenShake")
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
	engfunc(EngFunc_PrecacheModel, BatModel)
	engfunc(EngFunc_PrecacheSound, BatFireSound)
	engfunc(EngFunc_PrecacheSound, BatFailSound)
	engfunc(EngFunc_PrecacheSound, BatFlySound)
	engfunc(EngFunc_PrecacheSound, Catch_Player_Male)
	engfunc(EngFunc_PrecacheSound, Catch_Player_Female)
	
	g_BatExpSpr_Id = engfunc(EngFunc_PrecacheModel, BatExpSpr)
}

public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_BANSHEE_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_BANSHEE_DESC")
	
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

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_START_TIME", buffer, sizeof(buffer), DummyArray); g_bat_starttime = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_TIMELIVE_ORIGIN", buffer, sizeof(buffer), DummyArray); g_bat_timelive[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_TIMELIVE_HOST", buffer, sizeof(buffer), DummyArray); g_bat_timelive[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_bat_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_bat_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_SPEED_ORIGIN", buffer, sizeof(buffer), DummyArray); g_bat_velocity[ZOMBIE_ORIGIN] = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_SPEED_HOST", buffer, sizeof(buffer), DummyArray); g_bat_velocity[ZOMBIE_HOST] = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_CATCH_SPEED_ORIGIN", buffer, sizeof(buffer), DummyArray); g_bat_catch_velocity[ZOMBIE_ORIGIN] = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_CATCH_SPEED_HOST", buffer, sizeof(buffer), DummyArray); g_bat_catch_velocity[ZOMBIE_HOST] = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_MAX_DISTANCE_ORIGIN", buffer, sizeof(buffer), DummyArray); g_bat_range[ZOMBIE_ORIGIN] = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_MAX_DISTANCE_HOST", buffer, sizeof(buffer), DummyArray); g_bat_range[ZOMBIE_HOST] = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_SOUND_START", BatFireSound, sizeof(BatFireSound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_SOUND_FLY", BatFlySound, sizeof(BatFlySound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_SOUND_FAIL", BatFailSound, sizeof(BatFailSound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_CATCH_MALE", Catch_Player_Male, sizeof(Catch_Player_Male), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_CATCH_FEMALE", Catch_Player_Female, sizeof(Catch_Player_Female), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_SPR_EXPLO", BatExpSpr, sizeof(BatExpSpr), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BAT_MODEL", BatModel, sizeof(BatModel), DummyArray);
}
public zb3_user_infected(id, infector, infect_flag)
{
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	switch(infect_flag)
	{
		case INFECT_VICTIM: reset_skill(id, true) 
		case INFECT_CHANGECLASS: if(g_skilling[id]) zb3_set_user_speed(id, 1)
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
		g_current_time[id] = g_bat_cooldown[zb3_get_user_zombie_type(id)]

	g_can_skill[id] = reset_time ? 1 : 0
	g_skilling[id] = 0

	if(task_exists(id+TASK_SKILLING)) remove_task(id+TASK_SKILLING)
	if(task_exists(id+TASK_CATCHING)) remove_task(id+TASK_CATCHING)
	if(task_exists(id+TASK_BATFLYING)) remove_task(id+TASK_BATFLYING)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id))
		reset_skill(id, false)
}

public zb3_user_dead(id) 
{
	if(!zb3_get_user_zombie(id))
		return;
	if( zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	reset_skill(id, false)
}

public Event_NewRound()
{
	remove_entity_name(BAT_CLASSNAME)
}
public fw_takedamage(victim, inflictor, attacker, Float: damage)
{
	if(!is_user_alive(victim))
		return HAM_IGNORED;
	if(!zb3_get_user_zombie(victim))
		return HAM_IGNORED;
	if( zb3_get_user_zombie_class(victim) != g_zombie_classid)
		return HAM_IGNORED;
	if(!g_skilling[victim])
		return HAM_IGNORED;
	
	damage *= 0.5;
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
	if(get_user_weapon(id) != CSW_KNIFE)
		return PLUGIN_HANDLED
	if(!g_can_skill[id] || g_skilling[id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZOMBIE_SKILL_NOT_READY", zclass_desc , floatround(get_cooldowntime(id) - g_current_time[id]))
		return PLUGIN_HANDLED
	}
	if(pev(id, pev_flags) & FL_DUCKING)
	{
		client_print(id, print_chat, "%L", LANG_OFFICIAL, "ZOMBIE_BANSHEE_NODUCK")
		return PLUGIN_HANDLED
	}	
	
	Do_Skill(id)

	return PLUGIN_HANDLED
}

public Do_Skill(id)
{
	g_can_skill[id] = 0
	g_skilling[id] = 1
	g_current_time[id] = 0.0
	
	zb3_set_user_speed(id, 1)
	
	set_weapons_timeidle(id, 99999.0)
	set_player_nextattack(id, 99999.0)
	
	set_weapon_anim(id, BAT_ANIM)
	set_entity_anim(id, BAT_PLAYERANIM, 0.35)
	
	EmitSound(id, CHAN_ITEM, BatFireSound)
	set_task(g_bat_starttime, "Skilling", id+TASK_SKILLING)
}

public Skilling(id)
{
	id -= TASK_SKILLING
	
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
	
	CreateBat(id)
}

public CreateBat(id)
{
	new bat
	bat = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(bat))
		return
		
	static Float:BatOrigin[3], Float:Angles[3], Float:Velocity[3]
	
	get_position(id, 50.0, 0.0, 0.0, BatOrigin)
	pev(id, pev_angles, Angles)
	
	set_pev(bat, pev_origin, BatOrigin)
	set_pev(bat, pev_angles, Angles)
	
	engfunc(EngFunc_SetModel, bat, BatModel)
	engfunc(EngFunc_SetSize, bat, {-10.0,-7.5,-4.0}, {10.0,7.5,4.0})
	
	set_pev(bat, pev_classname, BAT_CLASSNAME)
	set_pev(bat, pev_solid, 2)
	set_pev(bat, pev_movetype, MOVETYPE_FLY)
	set_pev(bat, pev_owner, id)
	// set_pev(bat, pev_fuser1, g_bat_timelive[zb3_get_user_zombie_type(id)]) //(zb3_get_user_level(id) > 1 ? BAT_TIMELIVE_ORIGIN : BAT_TIMELIVE_HOST))
	
	velocity_by_aim(id, g_bat_velocity[zb3_get_user_zombie_type(id)], Velocity)
	set_pev(bat, pev_velocity, Velocity)
	
	set_entity_anim(bat, 0, 1.0)
	set_pev(bat, pev_nextthink, get_gametime() + 0.1)
	
	// Set Secret Data
	set_pev(bat, pev_catched, 0)
	set_pev(bat, pev_catchid, 0)
	set_pev(bat, pev_maxdistance, g_bat_range[zb3_get_user_zombie_type(id)])
	set_pev(bat, pev_catchedspeed, g_bat_catch_velocity[zb3_get_user_zombie_type(id)])
	
	set_pev(bat, pev_timechange, 0.0)
	set_pev(bat, pev_livetime, g_bat_timelive[zb3_get_user_zombie_type(id)])

	EmitSound(bat, CHAN_BODY, BatFlySound)
}

public fw_Bat_Think(ent)
{
	if(!pev_valid(ent))
		return

	static Owner
	Owner = pev(ent, pev_owner)
	
	if(!is_user_alive(Owner) || zb3_get_user_zombie_class(Owner) != g_zombie_classid)
	{
		Bat_Explosion(ent)
		return
	}		
		
	static catched, catchid
	
	catched = pev(ent, pev_catched)
	catchid = pev(ent, pev_catchid)
	
	if(get_gametime() - 1.0 > pev(ent, pev_timechange))
	{
		set_pev(ent, pev_livetime, pev(ent, pev_livetime) - 1.0)
		set_pev(ent, pev_timechange, get_gametime())
	}
	
	if(pev(ent, pev_livetime) <= 0.0)
	{
		Bat_Explosion(ent)
		Reset_Owner(Owner)
				
		return
	}
	
	if(catched)
	{
		if(is_user_alive(catchid))
		{
			if(entity_range(catchid, Owner) >= 70)
				hook_ent(catchid, Owner, float(pev(ent, pev_catchedspeed)))
			else 
			{
				Bat_Explosion(ent)
				Reset_Owner(Owner)
				
				return
			}
		} else {
			Bat_Explosion(ent)
			Reset_Owner(Owner)
			
			return
		}
	} else {
		if(entity_range(ent, Owner) > pev(ent, pev_maxdistance))
		{
			Bat_Explosion(ent)
			Reset_Owner(Owner)
			
			return
		}
	}
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public fw_Bat_Touch(bat, id)
{
	if(!pev_valid(bat))
		return
	
	static Owner
	Owner = pev(bat, pev_owner)
	
	if(!is_user_alive(Owner) || zb3_get_user_zombie_class(Owner) != g_zombie_classid)
	{
		Bat_Explosion(bat)
		return
	}
	
	if(is_user_alive(id))
	{
		Catch_Player(bat, id, Owner)
	} else {
		Bat_Explosion(bat)
		Reset_Owner(Owner)
	}
}

public Catch_Player(ent, id, owner)
{
	if(!pev_valid(ent) || !is_user_alive(id) || zb3_get_user_zombie_class(owner) != g_zombie_classid)
		return
	
	set_pev(ent, pev_catched, 1)
	set_pev(ent, pev_catchid, id)
	set_pev(ent, pev_solid, SOLID_NOT)
	set_pev(ent, pev_aiment, id)
	set_pev(ent, pev_movetype, MOVETYPE_FOLLOW)

	if(!zb3_get_user_zombie(id))
	{
		if(!zb3_get_user_hero(id))
		{
			ScreenShake(id)
			EmitSound(id, CHAN_VOICE, zb3_get_user_sex(id) == SEX_MALE ? Catch_Player_Male : Catch_Player_Female)
		} else {
			Bat_Explosion(ent)
			Reset_Owner(owner)
			
			return
		}
	}
}

public Reset_Owner(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
		
	g_can_skill[id] = 0
	g_skilling[id] = 0

	zb3_set_user_speed(id, zb3_get_user_level(id) > 1 ? floatround(zclass_speedorigin) : floatround(zclass_speedhost))
	
	set_weapons_timeidle(id, 1.0)
	set_player_nextattack(id, 1.0)
	set_weapon_anim(id, 3)
}

public Bat_Explosion(ent)
{
	if(!pev_valid(ent))
		return	
		
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_BatExpSpr_Id)
	write_byte(40)
	write_byte(30)
	write_byte(0)
	message_end()		
	
	EmitSound(ent, CHAN_BODY, BatFailSound)
	engfunc(EngFunc_RemoveEntity, ent)	
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
		
	if(percent >= 100) {
		if(!g_can_skill[id])
		{
			g_can_skill[id] = 1
			g_skilling[id] = 0
		}
	}	
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!pev_valid(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
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

stock set_weapons_timeidle(id, Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	const m_flTimeWeaponIdle = 48
	
	new entwpn = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if (pev_valid(entwpn)) set_pdata_float(entwpn, m_flTimeWeaponIdle, TimeIdle + 3.0, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	const m_flNextAttack = 83
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock set_entity_anim(ent, anim, Float:framerate)
{
	if(!pev_valid(ent))
		return
		
	set_pev(ent, pev_animtime, get_gametime())
	set_pev(ent, pev_framerate, framerate)
	set_pev(ent, pev_sequence, anim)
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

public ScreenShake(id)
{
	if(!is_user_connected(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Shake, _, id)
	write_short(255<<14)
	write_short(10<<14)
	write_short(255<<14)
	message_end()
}

stock hook_ent(victim, attacker, Float:speed)
{
	if(!pev_valid(victim) || !pev_valid(attacker))
		return
	
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3], Float:VicOrigin[3]
	
	pev(victim, pev_origin, EntOrigin)
	pev(attacker, pev_origin, VicOrigin)
	
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	if (distance_f > 60.0)
	{
		new Float:fl_Time = distance_f / speed
		
		fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time
	} else {
		fl_Velocity[0] = 0.0
		fl_Velocity[1] = 0.0
		fl_Velocity[2] = 0.0
	}

	entity_set_vector(victim, EV_VEC_velocity, fl_Velocity)
}
stock Float:get_cooldowntime(id)
{
	if(!zb3_get_user_zombie(id))
		return 0.0
		
	return g_bat_cooldown[zb3_get_user_zombie_type(id)]
}
