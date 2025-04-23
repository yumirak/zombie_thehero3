#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Sting Finger"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zombie_thehero2/zclasscfg/sting.ini"
new const SETTING_CONFIG[] = "Config"
new const SETTING_MODELS[] = "Models"
new const SETTING_SOUNDS[] = "Sounds"
new const SETTING_SKILL[] = "Skill"
// Zombie Configs
new zclass_sex, zclass_lockcost
new zclass_name[32], zclass_desc[32], zclass_desc2[32], zclass_hostmodel[32], zclass_originmodel[32], zclass_clawsmodelhost[32], zclass_clawsmodelorigin[32]
new zombiegrenade_modelhost[64], zombiegrenade_modelorigin[64], HealSound[64], EvolSound[64]
new Float:zclass_gravity, Float:zclass_speedhost, Float:zclass_speedorigin, Float:zclass_knockback
new Float:zclass_dmgmulti, Float:zclass_painshock, Float:ClawsDistance1, Float:ClawsDistance2
new Array:DeathSound, DeathSoundString1[64], DeathSoundString2[64]
new Array:HurtSound, HurtSoundString1[64], HurtSoundString2[64]
new Float:g_tentacle_cooldown[2], Float:g_tentacle_range[2], Float:g_tentacle_starttime, Float:g_jump_cooldown[2], Float:g_jump_gravity[2], Float:g_jump_starttime, Float:g_jump_time[2]
new TentacleSound[64], HeavyJumpSound[64]

new g_zombie_classid
new g_synchud1, Float:g_current_time[33], Float:g_current_time2[33]
new g_can_tentacle[33], g_can_hj[33], g_hj_ing[33], g_temp_attack[33], m_iBlood[2]

#define LANG_OFFICIAL LANG_PLAYER

#define TASK_HEAVYJUMP 312543
#define TASK_HEAVYJUMP_START 423423

// Tentacle
#define TENTACLE_ANIM 8
#define TENTACLE_PLAYERANIM 91

// Heavy Jump
#define HEAVYJUMP_ANIM 9
#define HEAVYJUMP_PLAYERANIM 98

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_CmdStart, "fw_CmdStart")	
	register_clcmd("drop", "cmd_drop")
	
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
	engfunc(EngFunc_PrecacheSound, TentacleSound)
	engfunc(EngFunc_PrecacheSound, HeavyJumpSound)
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
}

public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_RESIDENT_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_RESIDENT_DESC")
	formatex(zclass_desc2, charsmax(zclass_desc2), "%L", LANG_OFFICIAL, "ZCLASS_RESIDENT_DESC2")
	
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

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TENTACLE_STARTTIME", buffer, sizeof(buffer), DummyArray); g_tentacle_starttime = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TENTACLE_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_tentacle_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TENTACLE_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_tentacle_cooldown[ZOMBIE_HOST] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TENTACLE_DISTANCE_ORIGIN", buffer, sizeof(buffer), DummyArray); g_tentacle_range[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TENTACLE_DISTANCE_HOST", buffer, sizeof(buffer), DummyArray); g_tentacle_range[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAVYJUMP_STARTTIME", buffer, sizeof(buffer), DummyArray); g_jump_starttime = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAVYJUMP_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_jump_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAVYJUMP_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_jump_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAVYJUMP_TIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_jump_time[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAVYJUMP_TIME_HOST", buffer, sizeof(buffer), DummyArray); g_jump_time[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAVYJUMP_AMOUNT_ORIGIN", buffer, sizeof(buffer), DummyArray); g_jump_gravity[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAVYJUMP_AMOUNT_HOST", buffer, sizeof(buffer), DummyArray); g_jump_gravity[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "TENTACLE_SOUND", TentacleSound, sizeof(TentacleSound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAVYJUMP_SOUND", HeavyJumpSound, sizeof(HeavyJumpSound), DummyArray);
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
			if(g_hj_ing[id]) {
				zb3_set_user_gravity(id, g_jump_gravity[zb3_get_user_zombie_type(id)])
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
	{
		g_current_time[id] = g_tentacle_cooldown[zb3_get_user_zombie_type(id)]
		g_current_time2[id] = g_jump_cooldown[zb3_get_user_zombie_type(id)]
	} 

	g_can_tentacle[id] = reset_time ? 1 : 0
	g_can_hj[id] = reset_time ? 1 : 0
	g_hj_ing[id] = 0

	if(task_exists(id+TASK_HEAVYJUMP)) remove_task(id+TASK_HEAVYJUMP)
	if(task_exists(id+TASK_HEAVYJUMP_START)) remove_task(id+TASK_HEAVYJUMP_START)
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
	if(!g_can_tentacle[id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZOMBIE_SKILL_NOT_READY", zclass_desc , floatround(get_cooldowntime(id) - g_current_time[id]))
		return PLUGIN_HANDLED
	}

	Do_Tentacle(id)

	return PLUGIN_HANDLED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || zb3_get_mode() <= MODE_ORIGINAL)
		return FMRES_IGNORED
	if(!zb3_get_user_zombie(id))
		return FMRES_IGNORED
	if(zb3_get_user_zombie_class(id) != g_zombie_classid || zb3_get_mode() == MODE_MUTATION && zb3_get_user_zombie_type(id) != ZOMBIE_ORIGIN)
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if((CurButton & IN_RELOAD) && !(pev(id, pev_oldbuttons) & IN_RELOAD))
	{
		if(!g_can_hj[id] || g_hj_ing[id])
		{
			client_print(id, print_center, "%L", LANG_PLAYER, "ZOMBIE_SKILL_NOT_READY", zclass_desc2 , floatround(get_cooldowntime2(id) -  g_current_time2[id]))
			return PLUGIN_HANDLED
		}
			
		Do_HeavyJump(id)				
	}
		
	return FMRES_IGNORED
}

public Do_Tentacle(id)
{
	g_can_tentacle[id] = 0
	g_current_time[id] = 0.0
	
	set_weapons_timeidle(id, g_tentacle_starttime)
	set_player_nextattack(id, g_tentacle_starttime)
	
	do_fake_attack(id)
	
	set_weapon_anim(id, TENTACLE_ANIM)
	//set_entity_anim(id, TENTACLE_PLAYERANIM, 1.0)
	set_pev(id, pev_sequence, TENTACLE_PLAYERANIM)
	
	EmitSound(id, CHAN_ITEM, TentacleSound)
	Check_Tentacle(id)
}

public Check_Tentacle(id)
{
	#define MAX_POINT 4
	static Float:Max_Distance, Float:Point[MAX_POINT][3], Float:TB_Distance
	
	Max_Distance = g_tentacle_range[zb3_get_user_zombie_type(id)]
	TB_Distance = Max_Distance / float(MAX_POINT)
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < MAX_POINT; i++)
		get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(zb3_get_user_zombie(i))
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		if(is_wall_between_points(MyOrigin, VicOrigin, id))
			continue

		if(get_distance_f(VicOrigin, Point[0]) <= 35.0 
		|| get_distance_f(VicOrigin, Point[1]) <= 35.0
		|| get_distance_f(VicOrigin, Point[2]) <= 35.0
		|| get_distance_f(VicOrigin, Point[3]) <= 35.0)
		{
			VicOrigin[2] += 15.0
			create_blood(VicOrigin)
			zb3_infect(i, id, false, false)
		}

	}		
}

public Do_HeavyJump(id)
{
	g_can_hj[id] = 0
	g_hj_ing[id] = 1
	g_current_time2[id] = 0.0
	
	set_weapons_timeidle(id, g_jump_starttime)
	set_player_nextattack(id, g_jump_starttime)
	
	do_fake_attack(id)
	set_weapon_anim(id, HEAVYJUMP_ANIM)
	set_pev(id, pev_sequence, HEAVYJUMP_PLAYERANIM)
	
	EmitSound(id, CHAN_ITEM, HeavyJumpSound)
	set_task(g_jump_starttime, "Start_HeavyJump", id+TASK_HEAVYJUMP_START)
}

public Start_HeavyJump(id)
{
	id -= TASK_HEAVYJUMP_START
	
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
	if(!g_hj_ing[id])
		return

	zb3_set_user_gravity(id, g_jump_gravity[zb3_get_user_zombie_type(id)])
	
	set_task(g_jump_time[zb3_get_user_zombie_type(id)], "Stop_HeavyJump", id+TASK_HEAVYJUMP)
}

public Stop_HeavyJump(id)
{
	id -= TASK_HEAVYJUMP
	
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
	if(!g_hj_ing[id])
		return
	zb3_reset_user_gravity(id)
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
	if(g_current_time2[id] < get_cooldowntime2(id))
		g_current_time2[id]++
	
	static percent , percent2
	
	// Tentacle Skill
	percent = floatround(floatclamp((g_current_time[id] / get_cooldowntime(id)) * 100.0, 0.0, 100.0))
	// HeavyJump Skill
	percent2 = floatround(floatclamp((g_current_time2[id] / get_cooldowntime2(id)) * 100.0, 0.0, 100.0))

	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0) // "[G] - %s (%i%%)^n[R] - %s (%i%%)"
	ShowSyncHudMsg(id, g_synchud1, "%L", LANG_PLAYER, "ZOMBIE_SKILL_DOUBLE", zclass_desc, percent, zclass_desc2, percent2)
	
	if(percent == 100 && !g_can_tentacle[id])
		g_can_tentacle[id] = 1
	
	if(percent2 == 100 && !g_can_hj[id])
	{
		g_can_hj[id] = 1
		g_hj_ing[id] = 0
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

public do_fake_attack(id)
{
	if(!is_user_alive(id))
		return
	
	static ent
	ent = fm_find_ent_by_owner(-1, "weapon_knife", id)
	
	if(pev_valid(ent)) 
	{
		g_temp_attack[id] = 1
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)	
		g_temp_attack[id] = 0
	}
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
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	return floatround(get_distance_f(end, EndPos))
} 

stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
}
stock Float:get_cooldowntime(id)
{
	if(!zb3_get_user_zombie(id))
		return 0.0
	return g_tentacle_cooldown[zb3_get_user_zombie_type(id)]
}
stock Float:get_cooldowntime2(id)
{
	if(!zb3_get_user_zombie(id))
		return 0.0
	return g_jump_cooldown[zb3_get_user_zombie_type(id)] 
}
