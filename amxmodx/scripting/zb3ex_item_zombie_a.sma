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
new const SETTING_FILE[] = "items.ini"

/// ============== CONFIGS ===================
new Array:model_host, Array:model_origin
new ZOMBIEBOM_IDSPRITES_EXP,
ZOMBIEBOM_P_MODEL[64], ZOMBIEBOM_W_MODEL[64]

const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_BLAST = 1123
new Array:viewmodel_sound
/// ==========================================

// Item: x Health & Armor
new g_x_health_armor, g_x_health_armor_cost, g_x_health_armor_name[24], g_x_health_armor_desc[24], g_x_health_armor_used[33],
g_x_health_armor_hp, g_x_health_armor_ap

// Item: Zombie Grenade
new zombie_grenade, zombie_grenade_cost, zombie_grenade_name[24], zombie_grenade_desc[24],
g_zombie_grenade_model[24], g_zombie_grenade_sound[64], g_zombie_grenade_sprite[64],
Float:g_zombie_grenade_radius, Float:g_zombie_grenade_power
// Item: Immediate Respawn
new g_im_respawn, g_im_respawn_cost, g_im_respawn_name[24], g_im_respawn_desc[24]

// Item: 70% Infect Health
new g_70_infect, g_70_infect_cost, g_70_infect_name[24], g_70_infect_desc[24]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "Fw_RG_CBasePlayerWeapon_DefaultDeploy")
	
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
	
	formatex(ZOMBIEBOM_P_MODEL, charsmax(ZOMBIEBOM_P_MODEL), "models/%s/p_%s.mdl", GAMEDIR, g_zombie_grenade_model)
	formatex(ZOMBIEBOM_W_MODEL, charsmax(ZOMBIEBOM_W_MODEL), "models/%s/w_%s.mdl", GAMEDIR, g_zombie_grenade_model)
	
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
		format(Temp_String, charsmax(Temp_String), "sound/%s", Temp_String)
		engfunc(EngFunc_PrecacheGeneric, Temp_String)
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
	static Buffer[128]

	param_convert(1)
	param_convert(2)	

	ArrayPushString(model_host, v_model_host)
	formatex(Buffer, sizeof(Buffer), "models/%s/%s", GAMEDIR, v_model_host)
	engfunc(EngFunc_PrecacheModel, Buffer)	
	
	ArrayPushString(model_origin, v_model_origin)	
	formatex(Buffer, sizeof(Buffer), "models/%s/%s", GAMEDIR, v_model_origin)
	engfunc(EngFunc_PrecacheModel, Buffer)	
}

public zb3_game_start(start_type)
{
	for(new i = 0; i < MAX_PLAYERS;i++)
		g_x_health_armor_used[i] = 0
}

public zb3_item_selected_post(id, itemid)
{
	if(itemid == zombie_grenade) {
		zombie_grenade_handle(id)
	} else if(itemid == g_im_respawn) {
		zb3_set_user_respawn_time(id, 0)
	} else if(itemid == g_70_infect) {
		zb3_set_user_infect_mod(id, 0.7)
	}
}

public zb3_user_infected(id, infector, infect_flag)
{
	if(infect_flag != INFECT_CHANGECLASS)
		reset_item(id)  
}
public reset_item(id)
{
	x_health_armor_handle(id)
	zombie_grenade_handle(id)
	infect_mod_handle(id)
	respawn_time_handle(id)
}

public client_putinserver(id)
{
	reset_value(id)
}

public reset_value(id)
{
	g_x_health_armor_used[id] = 0

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
	if(!zb3_get_own_item(id, g_x_health_armor))
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
	if(!zb3_get_own_item(id, zombie_grenade))
		return	
	
	rg_give_custom_item(id, "weapon_hegrenade", GT_REPLACE, IMPULSE_GRENADE)
	rg_switch_best_weapon(id)
}
public infect_mod_handle(id)
{
	if(!zb3_get_own_item(id, g_70_infect))
	{
		zb3_reset_user_infect_mod(id)
		return
	}

	zb3_set_user_infect_mod(id, 0.7)
	return
}
public respawn_time_handle(id)
{
	if(!zb3_get_own_item(id, g_im_respawn))
	{
		zb3_reset_user_respawn_time(id)
		return
	}

	zb3_set_user_respawn_time(id, 0)
	return
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
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, g_zombie_grenade_radius)) != 0)
	{
		if (!is_user_alive(victim))
			continue;

		zb3_do_knockback(ent, victim, zb3_get_user_zombie(victim) ? g_zombie_grenade_power : g_zombie_grenade_power * 2.0)
		shake_screen(victim)
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
 
public Fw_RG_CBasePlayerWeapon_DefaultDeploy(const entity, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal)
{
	if(get_entvar(entity, var_impulse) != IMPULSE_GRENADE)
		return
	
	static pPlayer, ViewModel[64], Buffer[128]
	pPlayer = get_member(entity, m_pPlayer)

	if(!is_user_alive(pPlayer))
		return

	ArrayGetString(zb3_get_user_zombie_type(pPlayer) ? model_origin : model_host, zb3_get_user_zombie_class(pPlayer), ViewModel, charsmax(ViewModel))
	format(Buffer, sizeof(Buffer), "models/%s/%s", GAMEDIR, ViewModel)

	SetHookChainArg( 2, ATYPE_STRING, Buffer)
	SetHookChainArg( 3, ATYPE_STRING, ZOMBIEBOM_P_MODEL)
	SetHookChainArg( 4, ATYPE_INTEGER, 3)
}
