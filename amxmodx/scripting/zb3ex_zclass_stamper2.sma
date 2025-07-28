#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Stamper"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zombie_thehero2/zclasscfg/stamper.ini"
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
new CoffinModel[64], CoffinExp[64], CoffinHitSound[64], CoffinExpSpr[64], CoffinSlow[64], StampingSound[64]
new Float:g_coffin_cooldown[2], g_coffin_livetime[2], Float:g_coffin_range, g_coffin_health, Float:g_coffin_knockback
new Float:g_coffin_starttime, g_coffin_damage, g_coffin_victim_velocity, Float:g_coffin_victim_time

new const HandSound[2][] =
{
	"zombie_thehero/zombi_stamper_clap.wav",
	"zombie_thehero/zombi_stamper_glove.wav"
}

new g_zombie_classid

const UNIT_SECOND = (1<<12)

const pev_livetime = pev_iuser4
const pev_checktime = pev_fuser4

#define LANG_OFFICIAL LANG_PLAYER
#define HEALTH_OFFSET 1000

enum (+= 50)
{
	TASK_STAMPING = 26000,
	TASK_COOLDOWN,
	TASK_FREEZING
}

#define COFFIN_CLASSNAME "coffin"

#define STAMPING_ANIM 2
#define STAMPING_PLAYERANIM 10
new g_SprBeam_Id, g_SprExp_Id, g_SprBlast_Id
new g_msg_ScreenShake
new g_stamping[33]


public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// RegisterHam(Ham_TraceAttack, "info_target", "Coffin_TraceAttack")
	RegisterHam(Ham_Think, "info_target", "Coffin_Think")

	g_msg_ScreenShake = get_user_msgid("ScreenShake")
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
	zb3_register_zcooldown(g_coffin_cooldown[ZOMBIE_HOST], g_coffin_cooldown[ZOMBIE_ORIGIN]);
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheModel, CoffinModel)
	engfunc(EngFunc_PrecacheSound, StampingSound)
	engfunc(EngFunc_PrecacheSound, CoffinExp)
	engfunc(EngFunc_PrecacheSound, CoffinHitSound)
	
	g_SprBeam_Id = precache_model("sprites/shockwave.spr")
	g_SprExp_Id = precache_model("models/woodgibs.mdl")
	g_SprBlast_Id = precache_model(CoffinExpSpr)
	precache_model(CoffinSlow)
	
	for(new i = 0; i < sizeof(HandSound); i++)
		engfunc(EngFunc_PrecacheSound, HandSound[i])
}


public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_STAMPER_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_STAMPER_DESC")
	
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

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "STAMPING_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_coffin_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "STAMPING_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_coffin_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_HEALTH", buffer, sizeof(buffer), DummyArray); g_coffin_health = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_DAMAGE", buffer, sizeof(buffer), DummyArray); g_coffin_damage = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_EXP_KNOCKBACK", buffer, sizeof(buffer), DummyArray); g_coffin_knockback = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_EXP_RADIUS", buffer, sizeof(buffer), DummyArray); g_coffin_range = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_LIVETIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_coffin_livetime[ZOMBIE_ORIGIN] = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_LIVETIME_HOST", buffer, sizeof(buffer), DummyArray); g_coffin_livetime[ZOMBIE_HOST] = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "STAMPING_STARTTIME", buffer, sizeof(buffer), DummyArray); g_coffin_starttime = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HUMAN_SLOWTIME", buffer, sizeof(buffer), DummyArray); g_coffin_victim_time = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HUMAN_SLOWSPEED", buffer, sizeof(buffer), DummyArray); g_coffin_victim_velocity = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_MODEL", CoffinModel, sizeof(CoffinModel), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_SOUND_STAMP", StampingSound, sizeof(StampingSound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_SOUND_EXPLO", CoffinExp, sizeof(CoffinExp), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_SOUND_HIT", CoffinHitSound, sizeof(CoffinHitSound), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_SPR_EXPLO", CoffinExpSpr, sizeof(CoffinExpSpr), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "COFFIN_SPR_SLOW", CoffinSlow, sizeof(CoffinSlow), DummyArray);
}
public client_PostThink(id)
{
	if(task_exists(id+TASK_FREEZING))
		if(pev(id, pev_maxspeed) != g_coffin_victim_velocity) zb3_set_user_speed(id, g_coffin_victim_velocity)
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
}

public reset_skill(id)
{
	g_stamping[id] = 0
	if(task_exists(id+TASK_STAMPING)) remove_task(id+TASK_STAMPING)
	if(task_exists(id+TASK_FREEZING)) remove_task(id+TASK_FREEZING)
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

public zb3_game_start()
{
	remove_entity_name(COFFIN_CLASSNAME)
}

// public cmd_drop(id)
public zb3_do_skill(id, class, skullnum)
{
	if(class != g_zombie_classid || skullnum != 0)
		return 0
	if(get_user_weapon(id) != CSW_KNIFE)
		return 0

	Do_Stamping(id)
	return 1
}

public Do_Stamping(id)
{
	set_member(id, m_flTimeWeaponIdle, g_coffin_starttime + 3.0);
	set_member(id, m_flNextAttack, g_coffin_starttime)
	rg_weapon_send_animation(id, STAMPING_ANIM)
	set_pev(id, pev_sequence, STAMPING_PLAYERANIM)

	// Start Stamping
	set_task(g_coffin_starttime, "Set_Stamping", id+TASK_STAMPING)
}

public Set_Stamping(id)
{
	id -= TASK_STAMPING

	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 

	Create_Coffin(id)	
}

public Create_Coffin(id)
{
	static Float:Origin[3], Float:Angle1[3], Float:Angle2[3], Float:PutOrigin[3]

	pev(id, pev_origin, Origin)
	pev(id, pev_angles, Angle1)
	get_origin_distance(id, PutOrigin, 40.0)
	
	// Add Vector
	PutOrigin[2] += 25.0

	static coffin
	coffin = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if(!pev_valid(coffin))
		return
	
	// Init
	set_pev(coffin, pev_classname, COFFIN_CLASSNAME)
	
	// Origin & Angles & Vector
	pev(coffin, pev_angles, Angle2)
	Angle1[0] = Angle2[0]
	set_pev(coffin, pev_angles, Angle1)
	set_pev(coffin, pev_origin, PutOrigin)
	
	// Set Coffin Data
	entity_set_float(coffin, EV_FL_takedamage, 1.0)
	entity_set_float(coffin, EV_FL_health, float(HEALTH_OFFSET + g_coffin_health))
	engfunc(EngFunc_SetModel, coffin, CoffinModel)
	set_pev(coffin, pev_body, 1)
	set_pev(coffin, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(coffin, pev_solid, SOLID_BBOX)
	new Float:mins[3] = {-10.0, -6.0, -36.0}
	new Float:maxs[3] = {10.0, 6.0, 36.0}
	entity_set_size(coffin, mins, maxs)

	// Set Owner
	// set_pev(coffin, pev_owner, id)
	
	// Drop To Floor
	engfunc(EngFunc_DropToFloor, coffin)
	
	// Make Effect
	static Float:StampedOrigin[3]
	
	pev(coffin, pev_origin, StampedOrigin)
	StampingEffect(coffin, StampedOrigin)

	set_pev(coffin, pev_livetime, g_coffin_livetime[zb3_get_user_zombie_type(id)])//zb3_get_user_level(id) > 1 ? COFFIN_LIVETIME_ORIGIN : COFFIN_LIVETIME_HOST)
	set_pev(coffin, pev_nextthink, get_gametime() + 0.5)
	
	static Victim; Victim = -1
	while((Victim = find_ent_in_sphere(Victim, StampedOrigin, g_coffin_range)) != 0)
	{
		if(is_user_alive(Victim) && !zb3_get_user_zombie(Victim))
		{
			// Shake
			CreateScreenShake(Victim)
			// Freeze Player
			zb3_set_user_speed(Victim, g_coffin_victim_velocity)
			zb3_set_head_attachment(Victim, CoffinSlow, g_coffin_victim_time, 1.0, 1.0, 0)
			
			if(task_exists(id+TASK_FREEZING)) remove_task(id+TASK_FREEZING)
			set_task(g_coffin_victim_time, "ResetFreeze", Victim+TASK_FREEZING)
		}
	}
	
	set_task(0.1, "CheckStuck", coffin)
}

public CheckStuck(ent)
{
	if(!pev_valid(ent))
		return
		
	if(is_entity_stuck(ent)) CoffinExp_Handle(ent, 1)
}

public ResetFreeze(id)
{
	remove_task(id)
	id -= TASK_FREEZING
	
	if(!is_user_connected(id) || zb3_get_user_zombie(id))
		return
		
	zb3_reset_user_speed(id)
}

public StampingEffect(ent, Float:Origin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 200.0)
	write_short(g_SprBeam_Id)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(10)
	write_byte(0)
	write_byte(150)
	write_byte(150)
	write_byte(150)
	write_byte(200)
	write_byte(0)
	message_end()	
	
	EmitSound(ent, CHAN_BODY, StampingSound)
}

public CoffinExp_Handle(ent, Exp)
{
	if(!pev_valid(ent))
		return

	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	if(Exp)
	{
		// Exp Spr
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(g_SprBlast_Id)
		write_byte(40)
		write_byte(30)
		write_byte(14)
		message_end()
	}
	
	// Break Model
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 24)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, 16)
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, random_num(-50, 50))
	engfunc(EngFunc_WriteCoord, 25)
	write_byte(10)
	write_short(g_SprExp_Id)
	write_byte(10)
	write_byte(25)
	write_byte(BREAK_WOOD)
	message_end()
	
	if(Exp)
		emit_sound(ent, CHAN_BODY, CoffinExp,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	if(Exp)
	{
		static Victim; Victim = -1
		while((Victim = find_ent_in_sphere(Victim, Origin, g_coffin_range)) != 0)
		{
			if(!is_user_alive(Victim) || !is_valid_ent(Victim)) 
				continue
#if 0
			static Float:VictimOrigin[3], Float:Distance, Float:Speed, Float:NewSpeed, Float:Velocity[3]
			pev(Victim, pev_origin, VictimOrigin)
			
			Distance = get_distance_f(Origin, VictimOrigin)
			Speed = g_coffin_knockback
			NewSpeed = Speed * (1.0 - (Distance / g_coffin_range))
			GetSpeedVector(Origin, VictimOrigin, NewSpeed, Velocity)
			
			set_pev(Victim, pev_velocity, Velocity)
			CreateScreenShake(Victim)
			
			if(get_user_health(Victim) > g_coffin_damage) ExecuteHam(Ham_TakeDamage, Victim, 0, Victim, g_coffin_damage, DMG_BLAST)
			else ExecuteHamB(Ham_Killed, Victim, 0, 0)
#else
			zb3_do_knockback(ent, Victim, g_coffin_knockback)
			CreateScreenShake(Victim)
#endif
		}
	}
	
	if(pev_valid(ent)) engfunc(EngFunc_RemoveEntity, ent)			
}

public Coffin_Think(ent)
{
	if(!pev_valid(ent)) 
		return
	
	static ClassName[32]
	pev(ent, pev_classname, ClassName, sizeof(ClassName))
	
	if(!equal(ClassName, COFFIN_CLASSNAME)) 
		return
		
	if(get_gametime() - 1.0 > pev(ent, pev_checktime))
	{
		set_pev(ent, pev_livetime, pev(ent, pev_livetime) - 1)
		set_pev(ent, pev_checktime, get_gametime())
	}
	
	if(pev(ent, pev_livetime) <= 0 )
	{
		CoffinExp_Handle(ent, 0)
		return
	}
	if(entity_get_float(ent, EV_FL_health) - HEALTH_OFFSET < 0.0)
	{
		CoffinExp_Handle(ent, 1)
		return
	}

	set_pev(ent, pev_nextthink, get_gametime() + 0.1)
}

public Coffin_TraceAttack(ent, attacker, Float: damage, Float: direction[3], trace, damageBits)
{
	if(ent == attacker || !is_user_connected(attacker) || !pev_valid(ent)) 
		return HAM_IGNORED
	//if(get_user_weapon(attacker) != CSW_KNIFE || !zb3_get_user_zombie(attacker)) 
	//	return HAM_IGNORED
	
	new ClassName[32]
	pev(ent, pev_classname, ClassName, sizeof(ClassName))
	
	if(!equali(ClassName, COFFIN_CLASSNAME)) 
		return HAM_IGNORED
	
	new Float:End[3]
	get_tr2(trace, TR_vecEndPos, End)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, End[0])
	engfunc(EngFunc_WriteCoord, End[1])
	engfunc(EngFunc_WriteCoord, End[2])
	message_end()
	
	emit_sound(ent, CHAN_WEAPON, CoffinHitSound,  VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	return HAM_IGNORED
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!pev_valid(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock get_origin_distance(index, Float:Origin[3], Float:Dist)
{
	if(!pev_valid(index))
		return 0
	
	new Float:start[3]
	new Float:view_ofs[3]
	
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	new Float:dest[3]
	pev(index, pev_angles, dest)
	
	engfunc(EngFunc_MakeVectors, dest)
	global_get(glb_v_forward, dest)
	
	xs_vec_mul_scalar(dest, Dist, dest)
	xs_vec_add(start, dest, dest)
	
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0)
	get_tr2(0, TR_vecEndPos, Origin)
	
	return 1
}

stock CreateScreenShake(id)
{
	if(!is_user_connected(id))
		return
	
	new shake[3]
	shake[0] = random_num(2,20)
	shake[1] = random_num(2,5)
	shake[2] = random_num(2,20)
	
	message_begin(MSG_ONE_UNRELIABLE, g_msg_ScreenShake, _, id)
	write_short(UNIT_SECOND * shake[0])
	write_short(UNIT_SECOND * shake[1])
	write_short(UNIT_SECOND * shake[2])
	message_end()
}

stock is_entity_stuck(ent)
{
	if(!pev_valid(ent))
		return false
	
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(ent, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, ent, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true
	
	return false
}
#if 0
GetSpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1
}
#endif