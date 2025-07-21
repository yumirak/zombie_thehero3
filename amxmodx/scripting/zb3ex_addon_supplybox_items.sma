#include <amxmodx>
#include <zombie_thehero2>

#define PLUGIN "[ZB3EX] SupplyBox Item"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const LANG_FILE[] = "zombie_thehero2.txt"

new g_item[2];
new g_item1_name[32], g_item2_name[32]

public load_cfg()
{
	formatex(g_item1_name, charsmax(g_item1_name), "%L", LANG_SERVER, "SUPPLY_ITEM_AMMO")
	formatex(g_item2_name, charsmax(g_item2_name), "%L", LANG_SERVER, "SUPPLY_ITEM_NVGS")
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)

	load_cfg()
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	g_item[0] = zb3_register_supply_item(g_item1_name);
	g_item[1] = zb3_register_supply_item(g_item2_name);
}

public zb3_supply_item_give(id, itemid)
{
	if(itemid == g_item[1])
		zb3_set_user_nvg(id, 1, 1, 1, 0)
}