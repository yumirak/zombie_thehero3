#include <amxmodx>
#include <amxmisc>
//#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "[Zombie: The Hero] Zombie Item"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define MAX_CLASS 20
#define DELAY_TIME 2.0
new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "zombie_thehero2/items.ini"

/// ============== CONFIGS ===================
new Array:model_host, Array:model_origin
new ZOMBIEBOM_IDSPRITES_EXP,
ZOMBIEBOM_P_MODEL[64], ZOMBIEBOM_W_MODEL[64]

const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_BLAST = 1123
new Array:viewmodel_sound

new const hit_sound[3][] =
{
	"player/bhit_flesh-1.wav",
	"player/bhit_flesh-2.wav",
	"player/bhit_flesh-3.wav"
}	
/// ==========================================

// Item: x Health & Armor
new g_x_health_armor, g_x_health_armor_cost, g_x_health_armor_name[24], g_x_health_armor_desc[24],  g_had_x_health_armor[33], g_x_health_armor_used[33],
g_x_health_armor_hp, g_x_health_armor_ap

// Item: Zombie Grenade
new zombie_grenade, zombie_grenade_cost, zombie_grenade_name[24], zombie_grenade_desc[24],
g_had_zombie_grenade[33], g_zombie_grenade_model[24], g_zombie_grenade_sound[64], g_zombie_grenade_sprite[64],
Float:g_zombie_grenade_radius, Float:g_zombie_grenade_power
// Item: Immediate Respawn
new g_im_respawn, g_im_respawn_cost, g_im_respawn_name[24], g_im_respawn_desc[24], g_had_im_respawn[33]

// Item: 70% Infect Health
new g_70_infect, g_70_infect_cost, g_70_infect_name[24], g_70_infect_desc[24], g_had_70_infect[33]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("TextMsg", "event_restart", "a", "2=#Game_will_restart_in")
	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")
	register_forward(FM_SetModel, "fw_SetModel")
	
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
}
public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(g_70_infect_name, charsmax(g_70_infect_name), "%L", LANG_SERVER, "ITEM_70INFECT_NAME")
	formatex(g_70_infect_desc, charsmax(g_70_infect_desc), "%L", LANG_SERVER, "ITEM_70INFECT_DESC")

	formatex(g_im_respawn_name, charsmax(g_im_respawn_name), "%L", LANG_SERVER, "ITEM_IM_NAME")
	formatex(g_im_respawn_desc, charsmax(g_im_respawn_desc), "%L", LANG_SERVER, "ITEM_IM_DESC")

	formatex(g_x_health_armor_name, charsmax(g_x_health_armor_name), "%L", LANG_SERVER, "ITEM_HABOOST_NAME")
	formatex(g_x_health_armor_desc, charsmax(g_x_health_armor_desc), "%L", LANG_SERVER, "ITEM_HABOOST_DESC")

	formatex(zombie_grenade_name, charsmax(zombie_grenade_name), "%L", LANG_SERVER, "ITEM_ZGREN_NAME")
	formatex(zombie_grenade_desc, charsmax(zombie_grenade_name), "%L", LANG_SERVER, "ITEM_ZGREN_DESC")

	zb3_load_setting_string(false, SETTING_FILE, "70% Infect", "COST", buffer, sizeof(buffer), DummyArray); g_70_infect_cost = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Instant Respawn", "COST", buffer, sizeof(buffer), DummyArray); g_im_respawn_cost = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, "HP AP Addition", "COST", buffer, sizeof(buffer), DummyArray); g_x_health_armor_cost = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "HP AP Addition", "HP_ADD", buffer, sizeof(buffer), DummyArray); g_x_health_armor_hp = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "HP AP Addition", "AP_ADD", buffer, sizeof(buffer), DummyArray); g_x_health_armor_ap = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, "Zombie Grenade", "COST", buffer, sizeof(buffer), DummyArray); zombie_grenade_cost = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Zombie Grenade", "MODEL", g_zombie_grenade_model, sizeof(g_zombie_grenade_model), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, "Zombie Grenade", "SPRITE", g_zombie_grenade_sprite, sizeof(g_zombie_grenade_sprite), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, "Zombie Grenade", "SOUND", g_zombie_grenade_sound, sizeof(g_zombie_grenade_sound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, "Zombie Grenade", "RADIUS", buffer, sizeof(buffer), DummyArray); g_zombie_grenade_radius = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Zombie Grenade", "POWER", buffer, sizeof(buffer), DummyArray); g_zombie_grenade_power = str_to_float(buffer)
	zb3_load_setting_string(true,  SETTING_FILE, "Zombie Grenade", "SOUND_VIEWMODEL", buffer, 0, viewmodel_sound);
}
public plugin_precache()
{
	register_dictionary(LANG_FILE)

	model_host = ArrayCreate(64, 1)
	model_origin = ArrayCreate(64, 1)
	viewmodel_sound = ArrayCreate(64, 1)

	load_cfg()
	
	format(ZOMBIEBOM_P_MODEL, charsmax(ZOMBIEBOM_P_MODEL), "models/zombie_thehero/p_%s.mdl", g_zombie_grenade_model)
	format(ZOMBIEBOM_W_MODEL, charsmax(ZOMBIEBOM_W_MODEL), "models/zombie_thehero/w_%s.mdl", g_zombie_grenade_model)
	
	precache_model(ZOMBIEBOM_P_MODEL)
	precache_model(ZOMBIEBOM_W_MODEL)
	
	ZOMBIEBOM_IDSPRITES_EXP = precache_model(g_zombie_grenade_sprite)
	precache_sound(g_zombie_grenade_sound)	
	
	static Temp_String[128], i, size

	size = ArraySize(model_host)
	for(i = 0; i < size; i++)
	{
		ArrayGetString(model_host, i, Temp_String, sizeof(Temp_String))
		engfunc(EngFunc_PrecacheModel, Temp_String)
	}

	size = ArraySize(model_origin)
	for(i = 0; i < size; i++)
	{
		ArrayGetString(model_origin, i, Temp_String, sizeof(Temp_String))
		engfunc(EngFunc_PrecacheModel, Temp_String)
	}

	size = ArraySize(viewmodel_sound) // sizeof(zombi_bomb_sound)
	for(i = 0; i < size; i++)
	{
		ArrayGetString(viewmodel_sound, i, Temp_String, charsmax(Temp_String))
		engfunc(EngFunc_PrecacheSound, Temp_String)
	}

	if(zb3_get_mode() >= MODE_ORIGINAL) 
	{
		g_x_health_armor = zb3_register_item(g_x_health_armor_name, g_x_health_armor_desc, g_x_health_armor_cost, TEAM2_ZOMBIE, 1)
		g_70_infect = zb3_register_item(g_70_infect_name, g_70_infect_desc, g_70_infect_cost, TEAM2_ZOMBIE, 1)
	}
	if(zb3_get_mode() >= MODE_MUTATION) 
		zombie_grenade = zb3_register_item(zombie_grenade_name, zombie_grenade_desc, zombie_grenade_cost, TEAM2_ZOMBIE, 1)
	if(zb3_get_mode() >= MODE_HERO) 
		g_im_respawn = zb3_register_item(g_im_respawn_name, g_im_respawn_desc, g_im_respawn_cost, TEAM2_ZOMBIE, 1)
}

public plugin_natives()
{
	register_native("zb3_register_zbgre_model", "native_reg_zbgr_model", 1)
}

public native_reg_zbgr_model(const v_model_host[], const v_model_origin[])
{
	param_convert(1)
	param_convert(2)	
	
	ArrayPushString(model_host, v_model_host)
	ArrayPushString(model_origin, v_model_origin)
	
	precache_model(v_model_host)
	precache_model(v_model_origin)
}

public zb3_game_start(start_type)
{
	for(new i = 0; i < MAX_PLAYERS;i++)
		g_x_health_armor_used[i] = 0
}

public event_restart()
{
	for(new i = 1; i < MAX_PLAYERS;i++)
	{
		reset_value(i)
	}
}

public zb3_item_selected_post(id, itemid)
{
	if(itemid == g_x_health_armor)
		g_had_x_health_armor[id] = 1
	else if(itemid == zombie_grenade) {
		g_had_zombie_grenade[id] = 1
		zombie_grenade_handle(id)
	} else if(itemid == g_im_respawn) {
		g_had_im_respawn[id] = 1
		zb3_set_user_respawn_time(id, 0)
	} else if(itemid == g_70_infect) {
		g_had_70_infect[id] = 1
		zb3_set_user_infect_mod(id, 0.7)
	}
}

public zb3_user_infected(id)
{
	x_health_armor_handle(id)
	zombie_grenade_handle(id)
}
#if 0 // Needed ? 
public zb3_zombie_evolution(id, level)
{
	if(level > 1)
	{
		if(g_had_zombie_grenade[id] && get_user_weapon(id) == CSW_HEGRENADE)
		{
			new model[64]
			ArrayGetString(zb3_get_user_zombie_type(id) ? model_origin : model_host, zb3_get_user_zombie_class(id), model, charsmax(model))
			
			set_pev(id, pev_viewmodel2, model)
			set_pev(id, pev_weaponmodel2, ZOMBIEBOM_P_MODEL)
		}
	}
}

public zb3_user_change_class(id, class)
{
	if(g_had_zombie_grenade[id] && get_user_weapon(id) == CSW_HEGRENADE)
	{
		new model[64]
		ArrayGetString(zb3_get_user_zombie_type(id) ? model_origin : model_host, zb3_get_user_zombie_class(id), model, charsmax(model))
		
		set_pev(id, pev_viewmodel2, model)
		set_pev(id, pev_weaponmodel2, ZOMBIEBOM_P_MODEL)
	}	
}
#endif 
public client_putinserver(id)
{
	reset_value(id)
}

public reset_value(id)
{
	g_had_x_health_armor[id] = 0
	g_x_health_armor_used[id] = 0
	g_had_zombie_grenade[id] = 0
	g_had_im_respawn[id] = 0
	
	g_had_70_infect[id] = 0

	zb3_reset_user_respawn_time(id)
	zb3_reset_user_infect_mod(id)
}

// ================= Item: x Health & Armor
public x_health_armor_handle(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_level(id) > 1)
		return
	if(!g_had_x_health_armor[id])
		return
	if(g_x_health_armor_used[id])
		return
		
	static Float:Health, Float:Armor, Float:MaxHealth, Float:MaxArmor, Float:NewHealth, Float:NewArmor
	
	Health = float(zb3_get_user_starthealth(id))
	Armor =  float(zb3_get_user_startarmor(id))
	MaxHealth =  float(zb3_get_user_maxhealth(id))
	MaxArmor =  float(zb3_get_user_maxarmor(id))

	// client_print(id, print_chat,"HP = %f, AP = %f", Health, Armor)

	NewHealth = floatclamp(Health + g_x_health_armor_hp, Health, MaxHealth)
	NewArmor = floatclamp(Armor + g_x_health_armor_ap, Armor, MaxArmor)
	
	// client_print(id, print_chat,"NEW! HP = %f, AP = %f", NewHealth, NewArmor)

	zb3_set_user_starthealth(id, floatround(NewHealth))
	zb3_set_user_startarmor(id, floatround(NewArmor))
	
	zb3_set_user_health(id, floatround(NewHealth))
	rg_set_user_armor(id, floatround(NewArmor), ARMOR_KEVLAR)

	g_x_health_armor_used[id] = 1
}
// ================= Item: Zombie Grenade
public zombie_grenade_handle(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(!g_had_zombie_grenade[id])
		return	
	
	rg_give_item(id, "weapon_hegrenade")
	rg_switch_best_weapon(id)
}

public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return FMRES_IGNORED;

	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	// Get attacker
	static attacker
	attacker = pev(entity, pev_owner)
	
	// Get whether grenade's owner is a zombie
	if (zb3_get_user_zombie(attacker))
	{
		if (model[9] == 'h' && model[10] == 'e') // Zombie Bomb
		{
			// Set grenade type on the thrown grenade entity
			set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_BLAST)
			engfunc(EngFunc_SetModel, entity, ZOMBIEBOM_W_MODEL)

			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if(dmgtime > get_gametime())
		return HAM_IGNORED
	
	// Check if it's one of our custom nades
	switch (pev(entity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_BLAST:
		{
			zombiebomb_explode(entity)
		}
		
		default: return HAM_IGNORED
	}
	
	return HAM_SUPERCEDE;	
}

stock zombiebomb_explode(ent)
{
	// Get origin
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	// Make the explosion
	EffectZombieBomExp(ent)
	
	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, g_zombie_grenade_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Collisions
	static victim
	victim = -1
	
	new Float:fOrigin[3],Float:fDistance,Float:fDamage
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, g_zombie_grenade_radius)) != 0)
	{
		// Only effect alive non-spawnprotected humans
		if (!is_user_alive(victim))
			continue;
		
		// get value
		pev(victim, pev_origin, fOrigin)
		if(is_wall_between_points(originF, fOrigin, victim))
			continue		
		
		fDistance = get_distance_f(fOrigin, originF)
		fDamage = g_zombie_grenade_power - floatmul(g_zombie_grenade_power, floatdiv(fDistance, g_zombie_grenade_radius))//get the damage value
		fDamage *= estimate_take_hurt(originF, victim, 0)//adjust
		if (fDamage < 0)
			continue
	
		shake_screen(victim)
		hook_ent2(victim, originF, g_zombie_grenade_power, 2)
		emit_sound(victim, CHAN_AUTO, hit_sound[random(sizeof(hit_sound))], 1.0, ATTN_NORM, 0, PITCH_NORM)	
	
		continue;
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, ent)
}

stock EffectZombieBomExp(id)
{
	static i, j, Float:origin[3];
	pev(id,pev_origin,origin);

	for(i = 0; i < 3;i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
		write_byte(TE_EXPLOSION); // TE_EXPLOSION
		for(j = 0; j < 3;j++)
			write_coord(floatround(origin[j]));
		write_short(ZOMBIEBOM_IDSPRITES_EXP); // sprites
		write_byte(40); // scale in 0.1's
		write_byte(30); // framerate
		write_byte(14); // flags 
		message_end(); // message end
	}
}

stock manage_effect_action(iEnt, Float:fEntOrigin[3], Float:fPoint[3], Float:fDistance, Float:fDamage)
{
	new Float:Velocity[3]
	pev(iEnt, pev_velocity, Velocity)
	
	new Float:fTime = floatdiv(fDistance, fDamage)
	new Float:fVelocity[3]
	fVelocity[0] = floatdiv((fEntOrigin[0] - fPoint[0]), fTime) + Velocity[0]*0.5
	fVelocity[1] = floatdiv((fEntOrigin[1] - fPoint[1]), fTime) + Velocity[1]*0.5
	fVelocity[2] = floatdiv((fEntOrigin[2] - fPoint[2]), fTime) + Velocity[2]*0.5
	set_pev(iEnt, pev_velocity, fVelocity)
	
	return 1
}

stock shake_screen(id)
{
	if(!is_user_connected(id))
		return
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"),{0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	new Float:fl_Time = distance_f / speed
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	set_pev(ent, pev_velocity, fl_Velocity)
}

stock Float:estimate_take_hurt(Float:fPoint[3], ent, ignored) 
{
	new Float:fOrigin[3]
	new tr
	new Float:fFraction
	pev(ent, pev_origin, fOrigin)
	engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, ignored, tr)
	get_tr2(tr, TR_flFraction, fFraction)
	if ( fFraction == 1.0 || get_tr2( tr, TR_pHit ) == ent ) //no valid enity between the explode point & player
		return 1.0
	return 0.6//if has fraise, lessen blast hurt
}

public event_CurWeapon(id)
{
	if (!is_user_alive(id)) return;
	
	new plrWeapId = get_user_weapon(id)
	if (plrWeapId == CSW_HEGRENADE && g_had_zombie_grenade[id])
	{
		if(zb3_get_user_zombie(id))
		{
			new model[64]
			ArrayGetString(zb3_get_user_zombie_type(id) ? model_origin : model_host, zb3_get_user_zombie_class(id), model, charsmax(model))
			
			set_pev(id, pev_viewmodel2, model)
			set_pev(id, pev_weaponmodel2, ZOMBIEBOM_P_MODEL)
		}
	}
}

// ================ Stock
stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
} 
