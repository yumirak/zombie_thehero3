#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_thehero2>

#define PLUGIN "[Zombie: The Hero] Addon: Weapon"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define MAX_FORWARD 3
#define MAX_WEAPON 30

#define TASK_SELECT_WEAPON 84948534

new g_wpn_i
new Array:Weapon_Name, Array:Weapon_Type, Array:Weapon_UnlockCost
new g_forward[MAX_FORWARD]

enum
{
	FWD_WPN_SELECTED_PRE = 0,
	FWD_WPN_SELECTED_POST,
	FWD_WPN_REMOVE
}

// Main Vars
new g_selected_melee[33], g_selected_sec[33], g_selected_pri[33]
new g_unlocked_weapon[33][MAX_WEAPON]

const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

new g_wpn_primary[MAX_WEAPON], g_wpn_count
new g_wpn_primary2[MAX_WEAPON], g_wpn_count2

new g_Msg_SayText, g_free_gun

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	g_Msg_SayText = get_user_msgid("SayText")
	
	g_forward[FWD_WPN_SELECTED_PRE] = CreateMultiForward("zb3_weapon_selected_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_forward[FWD_WPN_SELECTED_POST] = CreateMultiForward("zb3_weapon_selected_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_forward[FWD_WPN_REMOVE] = CreateMultiForward("zb3_remove_weapon", ET_IGNORE, FP_CELL, FP_CELL)

	register_clcmd("zb3_free", "cmd_free")
}

public plugin_precache()
{
	Weapon_Name = ArrayCreate(64, 1)
	Weapon_Type = ArrayCreate(1, 1)
	Weapon_UnlockCost = ArrayCreate(1, 1)
}

public plugin_natives()
{
	register_native("zb3_register_weapon", "native_register_weapon", 1)
}

public cmd_free(id)
{
	g_free_gun = !g_free_gun
	client_print(id, print_console, "[ZB3 WEAPON] Free = %i", g_free_gun)
}

// ===================== AMX Forward
public client_putinserver(id)
{
	reset_user_weapon(id, 1)

	//if(is_user_bot(id) && !g_register)
	//{
	//	g_register = 1
	//	set_task(0.1, "do_register_now", id)
	//}
}

// ===================== HAM FORWARD
new g_scaned

public zb3_user_spawned(id)
{
	if(zb3_get_user_zombie(id))
		return
	
	static g_forward_dummy
	
	for(new i = 0; i < g_wpn_i; i++)
		ExecuteForward(g_forward[FWD_WPN_REMOVE], g_forward_dummy, id, i)
		
	reset_user_weapon(id, 0)
	
	if(!is_user_bot(id))
	{
		set_task(0.5, "open_menu_weapon", id)
	} else {
		set_task(0.5, "random_weapon", id)
	}
	
	if(!g_scaned)
	{
		g_scaned = 1
		
		for(new i = 0; i < g_wpn_i; i++)
		{
			if(get_weapon_type(i) == WPN_PRIMARY)
			{
				g_wpn_primary[g_wpn_count] = i
				g_wpn_count++
			}
		}
		
		for(new i = 0; i < g_wpn_i; i++)
		{
			if(get_weapon_type(i) == WPN_PRIMARY)
			{
				g_wpn_primary2[g_wpn_count2] = i
				g_wpn_count2++
			}
		}		
	}
}

public random_weapon(id)
{
	if(!is_user_alive(id))
		return
	
	static g_forward_dummy, wpn_id
	
	wpn_id = g_wpn_primary2[random_num(0, g_wpn_count2)]
	ExecuteForward(g_forward[FWD_WPN_SELECTED_POST], g_forward_dummy, id, wpn_id)		
	
	wpn_id = g_wpn_primary[random_num(0, g_wpn_count)]
	ExecuteForward(g_forward[FWD_WPN_SELECTED_POST], g_forward_dummy, id, wpn_id)	
}

// ==================== Pubic
public open_menu_weapon(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return
	if(zb3_get_user_hero(id))
		return
	
	if(!g_selected_melee[id])
	{
		do_open_menu_weapon(id, WPN_MELEE, 0)
	} else if(!g_selected_sec[id]) {
		do_open_menu_weapon(id, WPN_SECONDARY, 0)
	} else if(!g_selected_pri[id]) {
		do_open_menu_weapon(id, WPN_PRIMARY, 0)
	}
	
	remove_task(id+TASK_SELECT_WEAPON)
	set_task(20.0, "reselect_weapon", id+TASK_SELECT_WEAPON)
}

public reselect_weapon(id)
{
	id -= TASK_SELECT_WEAPON
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return
	if(zb3_get_user_hero(id))
		return
	
	if(!g_selected_melee[id])
	{
		do_open_menu_weapon(id, WPN_MELEE, 0)
	} else if(!g_selected_sec[id]) {
		do_open_menu_weapon(id, WPN_SECONDARY, 0)
	} else if(!g_selected_pri[id]) {
		do_open_menu_weapon(id, WPN_PRIMARY, 0)
	}
}

public reset_user_weapon(id, full_reset)
{
	if(!full_reset)
	{
		g_selected_melee[id] = 0
		g_selected_sec[id] = 0
		g_selected_pri[id] = 0
	} else {
		g_selected_melee[id] = 0
		g_selected_sec[id] = 0
		g_selected_pri[id] = 0
		
		for(new i = 0; i < g_wpn_i; i ++)
			g_unlocked_weapon[id][i] = 0
	}
}

public do_open_menu_weapon(id, type, page)
{
	static menu, Temp_String[128], Temp_String2[128], Temp_String3[3]
	static MyMoney
	
	MyMoney = cs_get_user_money(id)
	
	switch(type)
	{
		case WPN_MELEE: menu = menu_create("[Zombie: The Hero] Weapon: Melee", "weapon_menu_handle")
		case WPN_SECONDARY: menu = menu_create("[Zombie: The Hero] Weapon: Secondary", "weapon_menu_handle")
		case WPN_PRIMARY: menu = menu_create("[Zombie: The Hero] Weapon: Primary", "weapon_menu_handle")
	}
	
	for(new i = 0; i < g_wpn_i; i++)
	{
		if(get_weapon_type(i) == type)
		{
			if(!is_unlock_weapon(i))
			{
				ArrayGetString(Weapon_Name, i, Temp_String, sizeof(Temp_String))
				num_to_str(i, Temp_String3, sizeof(Temp_String3))
				
				menu_additem(menu, Temp_String, Temp_String3)
			} else {
				if(!g_unlocked_weapon[id][i] && !check_user_admin(id) && !g_free_gun)
				{
					if(MyMoney >= is_unlock_weapon(i))
					{
						ArrayGetString(Weapon_Name, i, Temp_String, sizeof(Temp_String))
						num_to_str(i, Temp_String3, sizeof(Temp_String3))
						
						formatex(Temp_String2, sizeof(Temp_String2), "%s \r[Locked] \y(Unlock Cost: $%i)", Temp_String, is_unlock_weapon(i))
						menu_additem(menu, Temp_String2, Temp_String3)
					} else {
						ArrayGetString(Weapon_Name, i, Temp_String, sizeof(Temp_String))
						num_to_str(i, Temp_String3, sizeof(Temp_String3))
						
						formatex(Temp_String2, sizeof(Temp_String2), "\d%s \r[Locked] \y(Unlock Cost: $%i)", Temp_String, is_unlock_weapon(i))
						menu_additem(menu, Temp_String2, Temp_String3)							
					}
				} else {
					ArrayGetString(Weapon_Name, i, Temp_String, sizeof(Temp_String))
					num_to_str(i, Temp_String3, sizeof(Temp_String3))
				
					menu_additem(menu, Temp_String, Temp_String3)	
				}
			}
		}
	}
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, page)	
}

public weapon_menu_handle(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	if(zb3_get_user_zombie(id))
		return PLUGIN_HANDLED
	if(zb3_get_user_hero(id))
		return PLUGIN_HANDLED
	
	new data[6], szName[64], access, callback
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback)
	
	new wpn_id = str_to_num(data)
	new g_forward_dummy
	
	ExecuteForward(g_forward[FWD_WPN_SELECTED_PRE], g_forward_dummy, id, wpn_id)
	
	if(g_forward_dummy == PLUGIN_HANDLED)
		return PLUGIN_HANDLED
		
	static Temp_String[128]
	static MyMoney
	
	MyMoney = cs_get_user_money(id)
	
	if(!is_unlock_weapon(wpn_id))
	{
		small_handle(id, wpn_id)
		ExecuteForward(g_forward[FWD_WPN_SELECTED_POST], g_forward_dummy, id, wpn_id)
		
		ArrayGetString(Weapon_Name, wpn_id, Temp_String, sizeof(Temp_String))
		client_printc(id, "!g[Zombie: The Hero]!n You Selected: !t%s!n", Temp_String)
	} else {
		if(!g_unlocked_weapon[id][wpn_id] && !check_user_admin(id) && !g_free_gun)
		{
			if(MyMoney >= is_unlock_weapon(wpn_id))
			{
				g_unlocked_weapon[id][wpn_id] = 1
				
				small_handle(id, wpn_id)
				ExecuteForward(g_forward[FWD_WPN_SELECTED_POST], g_forward_dummy, id, wpn_id)
		
				ArrayGetString(Weapon_Name, wpn_id, Temp_String, sizeof(Temp_String))
				client_printc(id, "!g[Zombie: The Hero]!n You have Unlocked: !t%s!n. Now You Can Use this Weapon for All Round", Temp_String)
				
				cs_set_user_money(id, MyMoney - is_unlock_weapon(wpn_id))
			} else {
				ArrayGetString(Weapon_Name, wpn_id, Temp_String, sizeof(Temp_String))
				client_printc(id, "!g[Zombie: The Hero]!n You don't have Enough money to Unlock: !t%s!n (Required: !t$%i!n)", Temp_String, is_unlock_weapon(wpn_id))
				menu_destroy(menu)
				
				do_open_menu_weapon(id, get_weapon_type(wpn_id), 0)
			}
		} else {
			ArrayGetString(Weapon_Name, wpn_id, Temp_String, sizeof(Temp_String))
			
			small_handle(id, wpn_id)
			ExecuteForward(g_forward[FWD_WPN_SELECTED_POST], g_forward_dummy, id, wpn_id)
		
			ArrayGetString(Weapon_Name, wpn_id, Temp_String, sizeof(Temp_String))
			client_printc(id, "!g[Zombie: The Hero]!n You Selected: !t%s!n", Temp_String)		
		}
	}		

	return PLUGIN_CONTINUE
}

public small_handle(id, wpn_id)
{
	switch(get_weapon_type(wpn_id))
	{
		case WPN_MELEE:
		{
			g_selected_melee[id] = 1
			
			if(!g_selected_sec[id]) do_open_menu_weapon(id, WPN_SECONDARY, 0)
			else if(!g_selected_pri[id]) do_open_menu_weapon(id, WPN_PRIMARY, 0)
		}
		case WPN_SECONDARY:
		{
			g_selected_sec[id] = 1
			drop_weapons(id, 2)
				
			if(!g_selected_pri[id]) do_open_menu_weapon(id, WPN_PRIMARY, 0)	
		}
		case WPN_PRIMARY:
		{
			g_selected_pri[id] = 1
			drop_weapons(id, 1)
		}
	}	
}

public get_weapon_type(wpn_id)
{
	if(wpn_id > g_wpn_i)
		return 1
	
	return ArrayGetCell(Weapon_Type, wpn_id)
}

public is_unlock_weapon(wpn_id)
{
	if(wpn_id > g_wpn_i)
		return 1
	
	return ArrayGetCell(Weapon_UnlockCost, wpn_id)	
}

// =========================== Weapon Native
public native_register_weapon(const Name[], weapon_type, unlock_cost)
{
	param_convert(1)
	
	ArrayPushString(Weapon_Name, Name)
	ArrayPushCell(Weapon_Type, weapon_type)
	ArrayPushCell(Weapon_UnlockCost, unlock_cost)
	
	g_wpn_i++
	return g_wpn_i - 1
}

// ==================================== STOCK 
stock client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	if(index == 0)
	{
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(is_user_connected(i))
			{
				message_begin(MSG_ONE_UNRELIABLE, g_Msg_SayText, _, i);
				write_byte(i);
				write_string(szMsg);
				message_end();	
			}
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32], weapon_ent
			get_weaponname(weaponid, wname, charsmax(wname))
			weapon_ent = fm_find_ent_by_owner(-1, wname, id)
			
			// Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
			set_pev(weapon_ent, pev_iuser1, cs_get_user_bpammo(id, weaponid))
			
			// Player drops the weapon and looses his bpammo
			engclient_cmd(id, "drop", wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}

stock check_user_admin(id)
{
	if (get_user_flags(id) & ADMIN_LEVEL_G) 
		return 1
		
	return 0
}
