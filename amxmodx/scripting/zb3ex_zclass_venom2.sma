#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_thehero2>
#include <reapi>

#define PLUGIN "[ZB3] Venom Guard"
#define VERSION "2.0"
#define AUTHOR ""

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zclasscfg/venom.ini"
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

new Array:ShellColor, g_beserk_shell_color[3]
new berserk_startsound[64]
new Float:g_beserk_time[2], Float:g_beserk_multi, Float:g_beserk_radius, Float:g_beserk_power, Float:g_beserk_cooldown[2], g_beserk_speed
new Array:DeathModel, DeathSprite[64]


new g_zombie_classid, g_berserking[33]
new g_iSpr
#define LANG_OFFICIAL LANG_PLAYER
#define DEATH_EFFECT "ef_boomer"
enum (+= 50)
{
	TASK_BERSERKING = 35000
}

enum
{
	DEATH_MODEL_GIB,
	DEATH_MODEL_POISON,
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_think(DEATH_EFFECT, "DeathEffect_Think");
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "Fw_RG_CBasePlayer_TraceAttack");
}

public plugin_precache()
{
	static szTemp[64], i, size
	register_dictionary(LANG_FILE)

	DeathModel = ArrayCreate(64, 1)
	ShellColor = ArrayCreate(4, 1)

	load_cfg()

	for(i = 0; i < sizeof(g_beserk_shell_color); i++)
	{
		ArrayGetString(ShellColor, i, szTemp, charsmax(szTemp))
		g_beserk_shell_color[i] = str_to_num(szTemp)
	}

	// Precache Class Resource
	engfunc(EngFunc_PrecacheSound, berserk_startsound)
	g_iSpr = engfunc(EngFunc_PrecacheModel, DeathSprite)

	g_zombie_classid = zb3_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback, zclass_dmgmulti, zclass_painshock)

	zb3_set_zombie_class_model(zclass_hostmodel, zclass_originmodel)
	zb3_set_zombie_class_viewmodel(zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zb3_set_zombie_class_sound(DeathSound, HurtSound, HealSound, EvolSound)

	zb3_register_zbgre_model(zombiegrenade_modelhost, zombiegrenade_modelorigin)
	zb3_register_zcooldown(g_beserk_cooldown[ZOMBIE_HOST], g_beserk_cooldown[ZOMBIE_ORIGIN]);

	size = ArraySize(DeathModel)
	for(i = 0; i < size; i++)
	{
		ArrayGetString(DeathModel, i, szTemp, charsmax(szTemp))
		engfunc(EngFunc_PrecacheModel, szTemp)
	}
}
public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_VENOM_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_VENOM_DESC")
	
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

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BERSERK_TIME_ORIGIN", buffer, sizeof(buffer), DummyArray); g_beserk_time[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BERSERK_TIME_HOST", buffer, sizeof(buffer), DummyArray); g_beserk_time[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BERSERK_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_beserk_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BERSERK_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_beserk_cooldown[ZOMBIE_HOST] = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SKILL_MULTI", buffer, sizeof(buffer), DummyArray); g_beserk_multi = str_to_float(buffer)

	// zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "GRAVITY", buffer, sizeof(buffer), DummyArray); g_beserk_gravity = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "SPEED", buffer, sizeof(buffer), DummyArray); g_beserk_speed = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "KNOCK_RADIUS", buffer, sizeof(buffer), DummyArray); g_beserk_radius = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "KNOCK_POWER", buffer, sizeof(buffer), DummyArray); g_beserk_power = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "BESERK_START", berserk_startsound, sizeof(berserk_startsound), DummyArray);

	zb3_load_setting_string(true,  SETTING_FILE, SETTING_SKILL, "SHELL_COLOR", buffer, 0, ShellColor);

	zb3_load_setting_string(true,  SETTING_FILE, SETTING_SKILL, "DEATH_MODEL", buffer, 0, DeathModel);
	zb3_load_setting_string(false,  SETTING_FILE, SETTING_SKILL, "DEATH_SPRITE", DeathSprite, sizeof(DeathSprite), DummyArray);

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
			if(!g_berserking[id])
				return

			zb3_set_user_rendering(id, kRenderFxGlowShell, g_beserk_shell_color[0], g_beserk_shell_color[1], g_beserk_shell_color[2], kRenderNormal, 0)
			zb3_set_user_speed(id, g_beserk_speed)
		}
		default: reset_skill(id)
	}
}

public reset_skill(id)
{
	g_berserking[id] = 0
	
	if(task_exists(id+TASK_BERSERKING)) remove_task(id+TASK_BERSERKING)
}

public zb3_user_spawned(id) 
{
	if(!zb3_get_user_zombie(id))
		reset_skill(id)
}

public zb3_user_dead(id) 
{
	if(!zb3_get_user_zombie(id))
		return;
	if( zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;

	reset_skill(id)
	fm_set_entity_visibility(id, 0)
	do_death_effect(id)
}

public Fw_RG_CBasePlayer_TraceAttack(id, pevAttacker, Float:flDamage, Float:vecDir[3], tracehandle, bitsDamageType)
{
	if(!is_user_alive(id))
		return HC_CONTINUE;
	if(!zb3_get_user_zombie(id))
		return HC_CONTINUE;
	if( zb3_get_user_zombie_class(id) != g_zombie_classid)
		return HC_CONTINUE;
	if(!g_berserking[id])
		return HC_CONTINUE;
	
	set_tr2(tracehandle, TR_iHitgroup, HIT_GENERIC)
	SetHookChainArg(3, ATYPE_FLOAT, flDamage * g_beserk_multi);
	SetHookChainReturn(ATYPE_INTEGER, true)
	return HC_CONTINUE;
}
// public cmd_drop(id)
public zb3_do_skill(id, class, skullnum)
{
	if(class != g_zombie_classid || skullnum != 0)
		return 0

	return Do_Berserk(id)
}

public Do_Berserk(id)
{
	g_berserking[id] = 1
	set_member(id, m_flTimeWeaponIdle, 2.0);
	set_member(id, m_flNextAttack, 2.0)
	
	rg_weapon_send_animation(id, 2)

	zb3_reset_user_speed(id)
	zb3_set_user_rendering(id, kRenderFxGlowShell, g_beserk_shell_color[0], g_beserk_shell_color[1], g_beserk_shell_color[2], kRenderNormal, 0)
	zb3_set_user_speed(id, g_beserk_speed)
	emit_sound(id, CHAN_AUTO, berserk_startsound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
	if(task_exists(id+TASK_BERSERKING)) remove_task(id+TASK_BERSERKING)
	set_task(g_beserk_time[zb3_get_user_zombie_type(id)], "Remove_Berserk", id+TASK_BERSERKING)
	return 1
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


/////////
public do_death_effect(id)
{
	static Victim; Victim = -1
	static Float:Origin[3], szModel[64];
	pev(id, pev_origin, Origin)

	for(new i = 0; i <= DEATH_MODEL_POISON;i++)
	{
		ArrayGetString(DeathModel, i, szModel, sizeof(szModel))
		MakeDeathEffect(id, szModel, i == 0 ? kRenderTransAlpha : kRenderTransAdd)
	}
	Explo(id)

	while((Victim = fm_find_ent_in_sphere(Victim, Origin, g_beserk_radius)) != 0)
	{
		if(Victim == id)
			continue
		if(!is_user_alive(Victim))
			continue
		if(zb3_get_user_zombie(Victim))
			continue
			
		zb3_do_knockback(id, Victim, g_beserk_power)
	}
}
public MakeDeathEffect(id, const Model[], ModelFx)
{
	static pEnt, Float:Origin[3]
	pev(id, pev_origin, Origin);
	
	pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	set_pev(pEnt, pev_origin, Origin);
	set_pev(pEnt, pev_owner, id);
	set_pev(pEnt, pev_classname, DEATH_EFFECT);

	set_pev(pEnt, pev_sequence, 0);
	set_pev(pEnt, pev_framerate, 1.0);
	set_pev(pEnt, pev_animtime, get_gametime());

	set_pev(pEnt, pev_movetype, MOVETYPE_TOSS)
	set_pev(pEnt, pev_solid, SOLID_NOT)
	set_pev(pEnt, pev_gravity, 2.0)	

	engfunc(EngFunc_SetModel, pEnt, Model)

	set_pev(pEnt, pev_renderamt, 255.0);
	set_pev(pEnt, pev_rendermode, ModelFx);
	set_pev(pEnt, pev_iuser4, get_systime() + 3);
	set_pev(pEnt, pev_nextthink, get_gametime())
}
public DeathEffect_Think(Ent)
{
	static Time, CurTime, Float:Amt
	pev(Ent, pev_renderamt, Amt)
	Time = pev(Ent, pev_iuser4)
	CurTime = get_systime()

	if(CurTime > Time) set_pev(Ent, pev_renderamt, Amt * 0.9)
	if(Amt < 1.0)
	{
		engfunc(EngFunc_RemoveEntity, Ent);
		return;
	}
	set_pev(Ent, pev_nextthink, get_gametime() + 0.025)
}
stock Explo(id)
{
	static Float:Origin[3]
	pev(id, pev_origin, Origin)

	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord_f(Origin[0])
	write_coord_f(Origin[1])
	write_coord_f(Origin[2] + 40.0)
	write_short(g_iSpr)	
	write_byte(10)
	write_byte(30)
	write_byte(TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NODLIGHTS)
	message_end()
}