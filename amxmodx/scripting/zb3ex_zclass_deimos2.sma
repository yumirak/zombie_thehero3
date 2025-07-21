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
new const SETTING_FILE[] = "zombie_thehero2/zclasscfg/deimos.ini"
new const SETTING_CONFIG[] = "Config"
new const SETTING_MODELS[] = "Models"
new const SETTING_SOUNDS[] = "Sounds"
new const SETTING_SKILL[] = "Skill"

new zclass_sex, zclass_lockcost
new zclass_name[32], zclass_desc[32], zclass_hostmodel[32], zclass_originmodel[32], zclass_clawsmodelhost[32], zclass_clawsmodelorigin[32]
new zombiegrenade_modelhost[64], zombiegrenade_modelorigin[64], HealSound[64], EvolSound[64]
new Float:zclass_gravity, Float:zclass_speedhost, Float:zclass_speedorigin, Float:zclass_knockback
new Float:zclass_dmgmulti, Float:zclass_painshock, Float:ClawsDistance1, Float:ClawsDistance2
new Array:DeathSound, DeathSoundString1[64], DeathSoundString2[64]
new Array:HurtSound, HurtSoundString1[64], HurtSoundString2[64]
new Float:g_shock_cooldown[2], g_shock_range[2], g_shock_radius, Float:g_shock_starttime, g_shock_velocity
new SkillStart[64], SkillHit[64], SkillExp[64], SkillSpr[64], SkillTrail[64], SkillModel[64]

new g_SkillSpr_Id, g_SkillTrail_Id
new g_zombie_classid, g_can_skill[33], Float:g_current_time[33]

#define LANG_OFFICIAL LANG_PLAYER

#define SHOCK_CLASSNAME "deimos_shock"
#define SHOCK_ANIM 8
#define SHOCK_PLAYERANIM 10

#define TASK_SKILLING 31000

new g_synchud1, g_Msg_Shake

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
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
	engfunc(EngFunc_PrecacheModel, SkillModel)
	
	engfunc(EngFunc_PrecacheSound, SkillStart)
	engfunc(EngFunc_PrecacheSound, SkillHit)
	engfunc(EngFunc_PrecacheSound, SkillExp)
	
	g_SkillSpr_Id = engfunc(EngFunc_PrecacheModel, SkillSpr)
	g_SkillTrail_Id = precache_model(SkillTrail)
}


public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_DEIMOS_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_DEIMOS_DESC")
	
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

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_shock_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_shock_cooldown[ZOMBIE_HOST] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_DISTANCE_ORIGIN", buffer, sizeof(buffer), DummyArray); g_shock_range[ZOMBIE_ORIGIN] = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_DISTANCE_HOST", buffer, sizeof(buffer), DummyArray); g_shock_range[ZOMBIE_HOST] = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_RADIUS", buffer, sizeof(buffer), DummyArray); g_shock_radius = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_STARTTIME", buffer, sizeof(buffer), DummyArray); g_shock_starttime = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_VELOCITY", buffer, sizeof(buffer), DummyArray); g_shock_velocity = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_SOUND_EXPLO", SkillExp, sizeof(SkillExp), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_SOUND_START", SkillStart, sizeof(SkillStart), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_SOUND_HIT", SkillHit, sizeof(SkillHit), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_SPR_EXPLO", SkillSpr, sizeof(SkillSpr), DummyArray); 
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_SPR_BEAM", SkillTrail, sizeof(SkillTrail), DummyArray); 
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SHOCK_MODEL", SkillModel, sizeof(SkillModel), DummyArray);
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
		g_current_time[id] = g_shock_cooldown[zb3_get_user_zombie_type(id)]

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
	
	set_weapons_timeidle(id, g_shock_starttime)
	set_player_nextattack(id, g_shock_starttime)
	set_weapon_anim(id, SHOCK_ANIM)
	set_pev(id, pev_sequence, SHOCK_PLAYERANIM)
	
	EmitSound(id, CHAN_ITEM, SkillStart)

	// Start Attack
	remove_task(id+TASK_SKILLING)
	set_task(g_shock_starttime, "Do_Shock", id+TASK_SKILLING)
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
	velocity_by_aim(id, g_shock_velocity, Velocity)
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
	
	if(entity_range(id, ent) >= g_shock_range[zb3_get_user_zombie_type(id)])
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
	return g_shock_cooldown[zb3_get_user_zombie_type(id)]
}

