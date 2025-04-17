#include <amxmodx>
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "[ZB3EX] SupplyBox Item"
#define VERSION "2.0"
#define AUTHOR "Dias"

#if REAPI_VERSION_MINOR < 26
// Primary and Secondary Weapon Names
new const WEAPONSLOT[] = { 0, CS_WEAPONSLOT_SECONDARY, 0, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_GRENADE, CS_WEAPONSLOT_PRIMARY, 0, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY,
	CS_WEAPONSLOT_GRENADE, CS_WEAPONSLOT_SECONDARY, CS_WEAPONSLOT_SECONDARY, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY,
	CS_WEAPONSLOT_SECONDARY, CS_WEAPONSLOT_SECONDARY, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY,
	CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_GRENADE, CS_WEAPONSLOT_SECONDARY,
	CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_PRIMARY, CS_WEAPONSLOT_KNIFE, CS_WEAPONSLOT_PRIMARY }
#endif

new g_wpn_i
new Array:Supply_Item_Name
new g_forward[2]
static g_forward_dummy
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	g_forward[FWD_SUPPLY_ITEM_GIVE] = CreateMultiForward("zb3_supply_item_give", ET_IGNORE, FP_CELL, FP_CELL)
	g_forward[FWD_SUPPLY_AMMO_GIVE] = CreateMultiForward("zb3_supply_refill_ammo", ET_IGNORE, FP_CELL)
	register_dictionary("zombie_thehero2.txt")
	
}
public plugin_precache()
{
	Supply_Item_Name = ArrayCreate(64, 1)
}

public plugin_natives()
{
	//register_native("zb3_supplybox_random_getitem", "native_getitem", 1)
	register_native("zb3_register_supply_item", "native_register_supply_item", 1)
}

public native_register_supply_item(const Name[])
{
	param_convert(1)
	
	ArrayPushString(Supply_Item_Name, Name)
	
	g_wpn_i++
	return g_wpn_i - 1
}

public zb3_touch_supply(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_hero(id)) 
	{
		get_ammo_supply(id)
		return;
	}
	
	switch(random_num(0, 50))
	{
		// temporary get supply item
		case 0..20: { get_ammo_supply(id); notice_supply(id, "Grenades and Magazines Set"); }
		case 21..30: { zb3_set_user_nvg(id, 1, 1, 1, 0); notice_supply(id, "Nightvision Googles"); }
		case 31..50: get_registered_random_weapon(id)
	}
}

public get_registered_random_weapon(id)
{
	if(!is_user_alive(id))
		return
	
	static wpn_id , Temp_String[64]
	
	wpn_id = random_num(0, g_wpn_i - 1)

	ExecuteForward(g_forward[FWD_SUPPLY_ITEM_GIVE], g_forward_dummy, id, wpn_id)
	ArrayGetString(Supply_Item_Name, wpn_id, Temp_String, sizeof(Temp_String))
	notice_supply(id,Temp_String)
}

public get_ammo_supply(id)
{
	new ammo_name[32], weapon_name[32]
	new ammo_count, ammo_max_rounds
	new weapon_slot

	for( new i = 1; i < MAX_WEAPONS - 1; i++)
	{
#if REAPI_VERSION_MINOR < 26
		weapon_slot = WEAPONSLOT[i]
#else
		weapon_slot = rg_get_weapon_info( i, WI_SLOT )
#endif
		if ( weapon_slot == 0 || weapon_slot == CS_WEAPONSLOT_C4 || weapon_slot == CS_WEAPONSLOT_KNIFE )
			continue

		ammo_max_rounds = rg_get_weapon_info( i, WI_MAX_ROUNDS )
		rg_get_weapon_info( i, WI_AMMO_NAME, ammo_name, sizeof(ammo_name) )
		rg_get_weapon_info( i, WI_NAME, weapon_name, sizeof(weapon_name))
#if REAPI_VERSION_MINOR < 26
		if(weapon_slot == CS_WEAPONSLOT_GRENADE)
#else
		if( rg_get_weapon_info( i, WI_SLOT ) == CS_WEAPONSLOT_GRENADE )
#endif
			rg_give_item(id, weapon_name )

		for( new i = 0; i < 6; i++)
			rg_give_item(id, ammo_name )

		ammo_count = clamp( ammo_max_rounds * ( weapon_slot == CS_WEAPONSLOT_GRENADE ? 1 : 2 ), 0, 240 )
		rg_set_user_bpammo(id, WeaponIdType:i, ammo_count )
	}
	ExecuteForward(g_forward[FWD_SUPPLY_AMMO_GIVE], g_forward_dummy, id)
}

stock notice_supply(id, const itemname[])
{
	new buffer[256], name[64]
	get_user_name(id, name, sizeof(name))
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP_BROADCAST", name, itemname)
	
	for (new i = 1; i <= get_maxplayers(); i++)
	{
		 if (!is_user_connected(i) || i == id) continue;
		 client_print(i, print_center, buffer)
	}
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP", itemname)
	client_print(id, print_center, buffer)
}

