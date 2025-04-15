#include <amxmodx>
#include <cstrike>
#include <zombie_thehero2>
#include <fun>

#define PLUGIN "[Zombie: The Hero] Secondary Weapon: Desert Eagle"
#define VERSION "2.0"
#define AUTHOR "Dias"

new g_de

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	g_de = zb3_register_weapon("Nighthawk .50C (Desert Eagle)", WPN_SECONDARY, 0)
}

public zb3_weapon_selected_post(id, wpnid)
{
	if(wpnid == g_de) get_de(id)
}

public get_de(id)
{
	give_item(id, "weapon_deagle")
	cs_set_user_bpammo(id, CSW_DEAGLE, 200)
}