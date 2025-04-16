#include <amxmodx>
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "[ZB3EX] Stock Weapons"
#define VERSION "1.0"
#define AUTHOR ""

// Primary and Secondary Weapon Names
new const WEAPONNAMES[][] = { "", "P228 Compact", "", "Schmidt Scout", "HE Grenade", "Leone YG1265 Auto Shotgun", "", "Ingram MAC-10", "Steyr AUG A1",
	"Smoke Grenade", ".40 Dual Elites", "ES Five-seveN", "UMP 45", "SG-550 Auto-Sniper", "IMI Galil", "Clarion 5.56",
	"K&M .45 Tactical", "9x19mm Sidearm", "AWP Magnum Sniper", "K&M Sub-Machine Gun", "M249 Para Machinegun",
	"Leone 12 Gauge Super", "Maverick M4A1 Carbine", "Schmidt Machine Pistol", "G3SG1 Auto-Sniper", "Flashbang", "Night Hawk .50C",
	"SG-552 Commando", "AK-47 Kalashnikov", "Seal Knife", "ES P90" }

new Array:weapon_list_num

new g_weapon[ MAX_WEAPONS ];
new g_iWeaponSlot[ MAX_WEAPONS ]
new g_szWeaponName[ MAX_WEAPONS ][16]
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	weapon_list_num = ArrayCreate(1, 1) // weapon id to be listed in weaponmenu

	ListWeapon()
}

public ListWeapon()
{
	static iSlot

	for ( new i = 1 ; i < MAX_WEAPONS - 1; i++ )
	{
		if( WEAPONNAMES[i][0] == 0)
			continue

		g_iWeaponSlot[i] = rg_get_weapon_info(i, WI_SLOT)
		iSlot = g_iWeaponSlot[i]

		if (iSlot < CS_WEAPONSLOT_PRIMARY ||iSlot > CS_WEAPONSLOT_GRENADE )
			continue

		rg_get_weapon_info(i, WI_NAME, g_szWeaponName[i], charsmax(g_szWeaponName))
		if( g_szWeaponName[i][0] == 0 )
			continue

		g_weapon[i] = zb3_register_weapon( WEAPONNAMES[i], iSlot, 0 )
		ArrayPushCell( weapon_list_num, g_weapon[i] )
	}

}
public zb3_weapon_selected_post(id, wpnid)
{
	for ( new i = 1 ; i < MAX_WEAPONS - 1; i++ )
	{
		if( g_iWeaponSlot[i] == 0 )
			continue

		if( wpnid == ArrayGetCell( weapon_list_num, g_weapon[i]) )
			get_weapon( id, i )
	}
}

public get_weapon(id, wpnid)
{
	static ammo_name[32]
	static ammo_count, ammo_multi

	rg_give_item(id, g_szWeaponName[wpnid] )
	rg_get_weapon_info( wpnid, WI_AMMO_NAME, ammo_name, sizeof(ammo_name) )

	for( new i = 0; i < 6; i++)
	{
		rg_give_item(id, ammo_name )
	}

	switch(g_iWeaponSlot[wpnid])
	{
		case PRIMARY_WEAPON_SLOT..PISTOL_SLOT: ammo_multi = 2
		case GRENADE_SLOT: ammo_multi = 1
	}

	if( ammo_multi > 0 )
	{
		ammo_count = clamp( rg_get_weapon_info( wpnid, WI_MAX_ROUNDS ) * ammo_multi , 0, 240 )
		rg_set_user_bpammo(id, WeaponIdType:wpnid, ammo_count )
	}
}
