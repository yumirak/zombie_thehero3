#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>
#include <reapi>

#define PLUGIN "[ZB3] Zombie Class: Deimos"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zclasscfg/deimos.ini"
new const SETTING_CONFIG[] = "Config"
new const SETTING_MODELS[] = "Models"
new const SETTING_SOUNDS[] = "Sounds"
new const SETTING_SKILL[] = "Skill"

new zclass_sex, zclass_lockcost
new zclass_name[32], zclass_desc[32], zclass_hostmodel[32], zclass_originmodel[32], zclass_clawsmodelhost[32], zclass_clawsmodelorigin[32]
new zombiegrenade_modelhost[64], zombiegrenade_modelorigin[64], HealSound[64], EvolSound[64]
new Float:zclass_gravity, Float:zclass_speed, Float:zclass_knockback
new Float:zclass_dmgmulti, Float:zclass_painshock
new DeathSound[64], HurtSound[64]

new Float:g_shock_cooldown[2], g_shock_range[2], g_shock_radius, Float:g_shock_starttime, g_shock_velocity
new SkillStart[64], SkillHit[64], SkillExp[64], SkillSpr[64], SkillTrail[64], SkillModel[64]

new g_SkillSpr_Id, g_SkillTrail_Id
new g_zombie_classid

#define LANG_OFFICIAL LANG_PLAYER

#define SHOCK_CLASSNAME "deimos_shock"
#define SHOCK_ANIM 8
#define SHOCK_PLAYERANIM 10

#define TASK_SKILLING 31000

new  g_Msg_Shake

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(SHOCK_CLASSNAME, "fw_Shock_Think")
	register_touch(SHOCK_CLASSNAME, "*", "fw_Shock_Touch")
	
	g_Msg_Shake = get_user_msgid("ScreenShake")
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
	zb3_register_zcooldown(g_shock_cooldown[ZOMBIE_HOST], g_shock_cooldown[ZOMBIE_ORIGIN]);
	
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
public zb3_game_start(start_type)
{
	remove_entity_name(SHOCK_CLASSNAME)
}

// public cmd_drop(id)
public zb3_do_skill(id, class, skullnum)
{
	if(class != g_zombie_classid || skullnum != 0)
		return 0
	if(get_user_weapon(id) != CSW_KNIFE)
		return 0

	Do_Skill(id)
	return 1
}

public Do_Skill(id)
{
	set_member(id, m_flTimeWeaponIdle, g_shock_starttime + 3.0);
	set_member(id, m_flNextAttack, g_shock_starttime + 1.0)
	rg_weapon_send_animation(id, SHOCK_ANIM)
	rg_set_animation(id, PLAYER_ATTACK2);
	
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
	
	// for(new i = 0; i < 2; i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(g_SkillSpr_Id)
		write_byte(20)
		write_byte(30)
		write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND)
		message_end()
	}
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && is_user_alive(victim) && !zb3_get_user_zombie(victim) && !zb3_get_user_hero(victim))
	{
		static pEntity, j
		pEntity = -1
		
		for(j = 1;j <= 2; j++)
		{
			pEntity = get_member(victim, m_rgpPlayerItems, j);
			if(is_entity(pEntity))
			{
				rg_drop_items_by_slot(victim, InventorySlotType:j)
				break;
			}
		}

		EmitSound(victim, CHAN_ITEM, SkillHit)
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

stock EmitSound(id, chan, const file_sound[])
{
	if(!pev_valid(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
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
