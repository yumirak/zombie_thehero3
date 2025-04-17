#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Deimos"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

// Zombie Configs
new const zclass_name[] = "Deimos"
new const zclass_desc[] = "Shock"
new const zclass_sex = SEX_MALE
new const zclass_lockcost = 0
new const zclass_hostmodel[] = "deimoss_zombi_host"
new const zclass_originmodel[] = "deimoss_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_deimoss_zombi_host.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_deimoss_zombi.mdl"
new const zombiegrenade_modelhost[] = "models/zombie_thehero/v_zombibomb_deimoss_zombi_host.mdl"
new const zombiegrenade_modelorigin[] = "models/zombie_thehero/v_zombibomb_deimoss_zombi_origin.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speedhost = 280.0
new const Float:zclass_speedorigin = 280.0
new const Float:zclass_knockback = 0.75
new const Float:zclass_painshock = 0.25
new const DeathSound[2][] =
{
	"zombie_thehero/zombi_death_1.wav",
	"zombie_thehero/zombi_death_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombi_hurt_01.wav",
	"zombie_thehero/zombi_hurt_02.wav"	
}
new const HealSound[] = "zombie_thehero/zombi_heal.wav"
new const EvolSound[] = "zombie_thehero/zombi_evolution.wav"

new const SkillStart[] = "zombie_thehero/deimos_skill_start.wav"
new const SkillHit[] = "zombie_thehero/deimos_skill_hit.wav"
new const SkillExp[] = "zombie_thehero/zombi_bomb_exp.wav"
new const SkillSpr[] = "sprites/zombie_thehero/deimosexp.spr"
new const SkillTrail[] = "sprites/laserbeam.spr"
new const SkillModel[] = "models/zombie_thehero/w_hiddentail.mdl"

new const Float:ClawsDistance1 = 1.1
new const Float:ClawsDistance2 = 1.2

new g_SkillSpr_Id, g_SkillTrail_Id
new g_zombie_classid, g_can_skill[33], Float:g_current_time[33]

#define LANG_OFFICIAL LANG_PLAYER

#define SHOCK_CLASSNAME "deimos_shock"
#define SHOCK_ANIM 8
#define SHOCK_PLAYERANIM 10
#define SHOCK_STARTTIME 0.75
#define SHOCK_VELOCITY 1000
#define SHOCK_RADIUS 8.0 // sphere
#define SHOCK_DISTANCE_HOST 700
#define SHOCK_DISTANCE_ORIGIN 1500
#define SHOCK_COOLDOWN_HOST 15.0
#define SHOCK_COOLDOWN_ORIGIN 7.0

#define TASK_SKILLING 120022

new g_synchud1, g_Msg_Shake

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_clcmd("drop", "cmd_drop")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")	
	
	register_think(SHOCK_CLASSNAME, "fw_Shock_Think")
	register_touch(SHOCK_CLASSNAME, "*", "fw_Shock_Touch")
	
	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	g_Msg_Shake = get_user_msgid("ScreenShake")
}

public plugin_precache()
{
	// Register Zombie Class
	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speedhost, zclass_speedorigin, zclass_knockback, zclass_painshock, 
	ClawsDistance1, ClawsDistance2)
	
	zb3_set_zombie_class_data(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin, 
	DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound)
	
	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheModel, SkillModel)
	
	engfunc(EngFunc_PrecacheSound, SkillStart)
	engfunc(EngFunc_PrecacheSound, SkillHit)
	engfunc(EngFunc_PrecacheSound, SkillExp)
	
	g_SkillSpr_Id = engfunc(EngFunc_PrecacheModel, SkillSpr)
	g_SkillTrail_Id = precache_model(SkillTrail)
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
		g_current_time[id] = zb3_get_user_level(id) > 1 ? SHOCK_COOLDOWN_ORIGIN : SHOCK_COOLDOWN_HOST

	g_can_skill[id] = reset_time ? 1 : 0
	remove_task(id+TASK_SKILLING)
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
	remove_entity_name(SHOCK_CLASSNAME)
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
		return PLUGIN_CONTINUE
	if(!g_can_skill[id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZOMBIE_SKILL_NOT_READY", zclass_desc , floatround(get_cooldowntime(id) - g_current_time[id]))
		return PLUGIN_HANDLED
	}

	Do_Skill(id)

	return PLUGIN_HANDLED
}

public Do_Skill(id)
{
	g_can_skill[id] = 0
	g_current_time[id] = 0.0
	
	set_weapons_timeidle(id, SHOCK_STARTTIME)
	set_player_nextattack(id, SHOCK_STARTTIME)
	set_weapon_anim(id, SHOCK_ANIM)
	set_pev(id, pev_sequence, SHOCK_PLAYERANIM)
	
	EmitSound(id, CHAN_ITEM, SkillStart)

	// Start Attack
	remove_task(id+TASK_SKILLING)
	set_task(SHOCK_STARTTIME, "Do_Shock", id+TASK_SKILLING)
}

public Do_Shock(id)
{
	id -= TASK_SKILLING
	
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 
		
	g_can_skill[id] = 0

	// Create Light
	Create_Light(id)
}

public Create_Light(id)
{
	static Float:StartOrigin[3], Float:Velocity[3], Float:Angles[3]
	
	pev(id, pev_origin, StartOrigin)
	velocity_by_aim(id, SHOCK_VELOCITY, Velocity)
	pev(id, pev_angles, Angles)
	
	// Create Entity
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(ent))
		return
	
	set_pev(ent, pev_classname, SHOCK_CLASSNAME)
	engfunc(EngFunc_SetModel, ent, SkillModel)
	
	set_pev(ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(ent, pev_maxs, Float:{1.0, 1.0, 1.0})

	StartOrigin[2] += (pev(id, pev_flags) & FL_DUCKING) == 0 ? 30.0 : 20.0
	
	set_pev(ent, pev_origin, StartOrigin)
	set_pev(ent, pev_angles, Angles)
	
	set_pev(ent, pev_movetype, MOVETYPE_FLY)
	set_pev(ent, pev_gravity, 0.01)
	
	set_pev(ent, pev_velocity, Velocity)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_solid, SOLID_BBOX)
	
	fm_set_rendering(ent, kRenderFxNone, 0, 0, 0, kRenderNormal, 255)
	Make_TrailEffect(ent)

	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}

public fw_Shock_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id))
	{
		LightExp(ent, -1)
		return
	}
	
	if(entity_range(id, ent) >= (zb3_get_user_level(id) > 1 ? SHOCK_DISTANCE_ORIGIN : SHOCK_DISTANCE_HOST))
	{
		LightExp(ent, -1)
		return
	}
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}

public fw_Shock_Touch(shock, id)
{
	if (!pev_valid(shock)) 
		return
	
	LightExp(shock, id)
	
	return
}

public LightExp(ent, victim)
{
	if (!pev_valid(ent)) 
		return
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	for(new i = 0; i < 2; i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(g_SkillSpr_Id)
		write_byte(40)
		write_byte(30)
		write_byte(14)
		message_end()
	}
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && is_user_alive(victim) && !zb3_get_user_zombie(victim) && !zb3_get_user_hero(victim))
	{
		const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
		
		static wpnname[64]
		if(!(WPN_NOT_DROP & (1<<get_user_weapon(victim))) && get_weaponname(get_user_weapon(victim), wpnname, charsmax(wpnname)))
		{
			engclient_cmd(victim, "drop", wpnname)
			EmitSound(victim, CHAN_ITEM, SkillHit)
		}

		ScreenShake(victim)
	}
	
	EmitSound(ent, CHAN_BODY, SkillExp)
	engfunc(EngFunc_RemoveEntity, ent)
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
		if(!g_can_skill[id]) g_can_skill[id] = 1
	}	
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!pev_valid(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
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

stock Make_TrailEffect(ent)
{
	if(!pev_valid(ent))
		return

	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(ent); // entity
	write_short(g_SkillTrail_Id); // sprite
	write_byte(20);  // life
	write_byte(1);  // width
	write_byte(255); // r
	write_byte(212);  // g
	write_byte(0);  // b
	write_byte(255); // brightness
	message_end();
}

stock Float:get_cooldowntime(id)
{
	if(!zb3_get_user_zombie(id))
		return 0.0
	return zb3_get_user_level(id) > 1 ? SHOCK_COOLDOWN_ORIGIN : SHOCK_COOLDOWN_HOST;
}

