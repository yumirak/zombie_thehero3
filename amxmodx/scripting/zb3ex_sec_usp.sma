#include <amxmodx>
#include <cstrike>
#include <zombie_thehero2>
#include <fun>

#define PLUGIN "[Zombie: The Hero] Secondary Weapon: USP"
#define VERSION "2.0"
#define AUTHOR "Dias"

new g_usp

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	g_usp = zb3_register_weapon("KM .45 Tactical (USP)", WPN_SECONDARY, 0)
}

public zb3_weapon_selected_post(id, wpnid)
{
	if(wpnid == g_usp) get_usp(id)
}

public get_usp(id)
{
	give_item(id, "weapon_usp")
	cs_set_user_bpammo(id, CSW_USP, 200)
}