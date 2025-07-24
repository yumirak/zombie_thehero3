#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Zombie Class: Voodoo"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zombie_thehero2/zclasscfg/voodoo.ini"
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
new Array:HealAmountLevel
new Float:g_heal_cooldown[2], g_heal_amount[3], Float:g_heal_radius
new HealSkillSound[64], HealSoundMale[64], HealSoundFemale[64], HealerSpr[64], HealedSpr[64]

new g_zombie_classid, g_can_heal[33], Float:g_current_time[33]

#define LANG_OFFICIAL LANG_PLAYER

new g_synchud1, g_synchud2, g_MaxPlayers

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_clcmd("drop", "cmd_drop")
	
	g_synchud1 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	g_synchud2 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL2)
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)

	DeathSound = ArrayCreate(64, 1)
	HurtSound = ArrayCreate(64, 1)
	HealAmountLevel = ArrayCreate(64, 1)

	load_cfg()

	static i, size, szBuffer[16]

	size = sizeof(g_heal_amount)

	for(i = 0; i < size; i++)
	{
		ArrayGetString(HealAmountLevel, i, szBuffer, charsmax(szBuffer))
		g_heal_amount[i] = str_to_num(szBuffer)
	}

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
	engfunc(EngFunc_PrecacheSound, HealSoundMale)
	engfunc(EngFunc_PrecacheSound, HealSoundFemale)
	engfunc(EngFunc_PrecacheSound, HealSkillSound)
	
	engfunc(EngFunc_PrecacheModel, HealerSpr)
	engfunc(EngFunc_PrecacheModel, HealedSpr)
}

public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(zclass_name, charsmax(zclass_name), "%L", LANG_OFFICIAL, "ZCLASS_HEAL_NAME")
	formatex(zclass_desc, charsmax(zclass_desc), "%L", LANG_OFFICIAL, "ZCLASS_HEAL_DESC")
	
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

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAL_COOLDOWN_ORIGIN", buffer, sizeof(buffer), DummyArray); g_heal_cooldown[ZOMBIE_ORIGIN] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAL_COOLDOWN_HOST", buffer, sizeof(buffer), DummyArray); g_heal_cooldown[ZOMBIE_HOST] = str_to_float(buffer)
	zb3_load_setting_string(true,  SETTING_FILE, SETTING_SKILL, "HEAL_AMOUNT", buffer, 0, HealAmountLevel);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAL_RADIUS", buffer, sizeof(buffer), DummyArray); g_heal_radius = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAL_SKILL_SOUND", HealSkillSound, sizeof(HealSkillSound), DummyArray); 

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAL_SOUND_MALE", HealSoundMale, sizeof(HealSoundMale), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEAL_SOUND_FEMALE", HealSoundFemale, sizeof(HealSoundMale), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEALER_SPR", HealerSpr, sizeof(HealerSpr), DummyArray); 
	zb3_load_setting_string(false, SETTING_FILE, SETTING_SKILL, "HEALED_SPR", HealedSpr, sizeof(HealedSpr), DummyArray);
}

public zb3_user_infected(id, infector, infect_flag)
{
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return;
		
	if(infect_flag == INFECT_VICTIM) reset_skill(id, true) 	
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
		g_current_time[id] = g_heal_cooldown[zb3_get_user_zombie_type(id)] // zb3_get_user_level(id) > 1 ? HEAL_COOLDOWN_ORIGIN : HEAL_COOLDOWN_HOST

	g_can_heal[id] = reset_time ? 1 : 0
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

public fw_AddToFullPack_Post(es, e, ent, host, hostflags, player, pSet)
{
	if(!player)
		return FMRES_IGNORED
	if(!is_user_alive(ent) || !is_user_alive(host))
		return FMRES_IGNORED
	if(!zb3_get_user_zombie(ent) || !zb3_get_user_zombie(host))
		return FMRES_IGNORED
	if(zb3_get_user_zombie_class(host) != g_zombie_classid)
		return FMRES_IGNORED
	if(!zb3_get_user_nvg(host) || zb3_get_user_level(host) < 2)
		return FMRES_IGNORED
		
	static Float:CurHealth, Float:MaxHealth
	static Float:Percent, Percent2, RealPercent
	
	CurHealth = float(get_user_health(ent))
	MaxHealth = float(zb3_get_user_starthealth(ent))
	
	Percent = (CurHealth / MaxHealth) * 100.0
	Percent2 = floatround(Percent)
	RealPercent = clamp(Percent2, 1, 100)
	
	static Color[3]
	
	switch(RealPercent)
	{
		case 1..49: Color = {75, 0, 0}
		case 50..79: Color = {75, 75, 0}
		case 80..100: Color = {0, 75, 0}
	}
	
	set_es(es, ES_RenderFx, kRenderFxGlowShell)
	set_es(es, ES_RenderMode, kRenderNormal)
	set_es(es, ES_RenderColor, Color)
	set_es(es, ES_RenderAmt, 16)
	
	return FMRES_HANDLED
}


public cmd_drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE	
	if(!zb3_get_user_zombie(id))
		return PLUGIN_CONTINUE
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return PLUGIN_CONTINUE
	if(!g_can_heal[id])
	{
		client_print(id, print_center, "%L", LANG_PLAYER, "ZOMBIE_SKILL_NOT_READY", zclass_desc , floatround(get_cooldowntime(id) - g_current_time[id]))
		return PLUGIN_HANDLED
	}

	Do_Heal(id)

	return PLUGIN_HANDLED
}

public Do_Heal(id)
{
	static i, Float:Origin[3]
	static CurrentHealth, MaxHealth, RealHealth, PatientGender
	static HealAmount, HealTotalAmount, HealSingle; 
	i = RealHealth = CurrentHealth = PatientGender = MaxHealth = HealAmount = HealTotalAmount = HealSingle = 0
	g_current_time[id] = 0.0
	g_can_heal[id] = 0
	
	set_hudmessage(0, 255, 255, 0.7, 0.9, 0, 3.0, 3.0, 0.05, 3.0);

	pev(id, pev_origin, Origin)

	while((i = find_ent_in_sphere(i, Origin, g_heal_radius)) != 0)
	{
		if(!is_user_alive(i))
			continue
		if(!zb3_get_user_zombie(i))
			continue

		PatientGender = zb3_get_user_sex(i)
		CurrentHealth = get_user_health(i)
		MaxHealth = zb3_get_user_starthealth(i)
		HealAmount = g_heal_amount[zb3_get_user_level(id) - 1]

		RealHealth = clamp(CurrentHealth + HealAmount, CurrentHealth, MaxHealth)
		HealSingle = RealHealth - CurrentHealth
		HealTotalAmount += HealSingle

		if(HealSingle < 1)
			continue

		zb3_set_user_health(i, RealHealth)

		if(id == i) Heal_Icon(i, 1)
		else 
		{
			ShowSyncHudMsg(i, g_synchud2, "+ %i", HealSingle)
			Heal_Icon(i, 0)
			EmitSound(i, CHAN_AUTO, PatientGender == SEX_FEMALE ? HealSoundFemale : HealSoundMale)
		}
	}

	if(HealTotalAmount > 0)
		ShowSyncHudMsg(id, g_synchud2, "+ %i", HealTotalAmount)

	EmitSound(id, CHAN_AUTO, HealSkillSound)
}

public zb3_skill_show(id)
{
	if(!is_user_alive(id) || !zb3_get_user_zombie(id))
		return
	if(zb3_get_user_zombie_class(id) != g_zombie_classid)
		return 	
		
	if(g_current_time[id] < get_cooldowntime(id))
		g_current_time[id]++
	
	static percent
	percent = floatround(floatclamp((g_current_time[id] / get_cooldowntime(id)) * 100.0, 0.0, 100.0))

	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 3.0, 3.0)
	ShowSyncHudMsg(id, g_synchud1, "%L", LANG_PLAYER, "ZOMBIE_SKILL_SINGLE", zclass_desc, percent)

	if(percent >= 99) {
		if(!g_can_heal[id]) g_can_heal[id] = 1
	}	
}

stock Heal_Icon(id, Healer)
{
	if(!is_user_connected(id))
		return
	
	zb3_set_head_attachment(id, Healer == 1 ? HealerSpr : HealedSpr, 2.0, 1.0, 0.5, 19)
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock Float:get_cooldowntime(id)
{
	if(!zb3_get_user_zombie(id))
		return 0.0
	return g_heal_cooldown[zb3_get_user_zombie_type(id)] // zb3_get_user_level(id) > 1 ? HEAL_COOLDOWN_ORIGIN : HEAL_COOLDOWN_HOST;
}
