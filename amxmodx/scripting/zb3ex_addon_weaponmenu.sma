#include <amxmodx>
#include <reapi>
#define PRINT_CHAT_COLOR
#include <zombie_thehero2>

#define PLUGIN "[ZB3] Addon: Weapon"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define LANG_FILE "zombie_thehero2.txt"
#define GAME_LANG LANG_SERVER

#define MAX_WEAPON 46
#define MAX_TYPE 4
#define MAX_FORWARD 4

new const MenuHandle[WPN_MAX + 1][] =
{
	"wpn_none", // dummy
	"wpn_pri",
	"wpn_sec",
	"wpn_melee",
	"wpn_grenade",
	"get_wpn"
}
new const MenuLang[WPN_MAX + 1][] =
{
	"SHOP_NONE", // dummy
	"SHOP_PRIMARY",
	"SHOP_SECONDARY",
	"SHOP_MELEE",
	"SHOP_GRENADE",
	"SHOP_GET",
}
enum (+= 50)
{
	TASK_ROLL = 11000,
	TASK_GIVE
}

new g_Forwards[MAX_FORWARD], g_GotWeapon[33]
new g_WeaponList[5][MAX_WEAPON], g_WeaponListCount[5]
new g_PreWeapon[33][5], g_FirstWeapon[5], g_TotalWeaponCount, g_UnlockedWeapon[33][MAX_WEAPON]
new Array:ArWeaponName, Array:ArWeaponType, Array:ArWeaponCost
new g_RegWeaponCount
new g_MaxPlayers, g_fwResult, g_MsgSayText
new g_synchud1
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)

	g_Forwards[WPN_PRE_BOUGHT] = CreateMultiForward("zb3_weapon_selected_pre", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_BOUGHT] = CreateMultiForward("zb3_weapon_selected_post", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_REMOVE] = CreateMultiForward("zb3_remove_weapon", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_ADDAMMO] = CreateMultiForward("zb3_refill_weapon", ET_IGNORE, FP_CELL, FP_CELL)
	
	g_MsgSayText = get_user_msgid("SayText")
	g_MaxPlayers = get_maxplayers()
	g_synchud1 = CreateHudSyncObj(SYNCHUD_NOTICE)
	register_clcmd("buyammo1", "Native_OpenWeapon")
}

public plugin_precache()
{
	ArWeaponName = ArrayCreate(64, 1)
	ArWeaponType = ArrayCreate(1, 1)
	ArWeaponCost = ArrayCreate(1, 1)
	
	// Initialize
	static i
	for(i = 1; i < WPN_MAX; i++)
		g_FirstWeapon[i] = -1
}

public plugin_cfg()
{
	// Initialize 2
	static Type, i, j
	for(i = 1; i <= g_MaxPlayers; i++)
	{
		for(j = 1; j < WPN_MAX; j++)
			g_PreWeapon[i][j] = g_FirstWeapon[j]
	}
	
	// Handle WeaponList
	for(i = 1; i < WPN_MAX; i++)
		g_WeaponListCount[i] = 0

	for(i = 0; i < g_TotalWeaponCount; i++)
	{
		Type = ArrayGetCell(ArWeaponType, i)
		g_WeaponList[Type][g_WeaponListCount[Type]] = i
		g_WeaponListCount[Type]++
	}
}

public plugin_natives()
{
	register_native("zb3_register_weapon","Native_RegisterWeapon", 1)
	#if 0
	// NYI
	register_native("Mileage_OpenWeapon", "Native_OpenWeapon", 1)
	register_native("Mileage_GiveRandomWeapon", "Native_GiveRandomWeapon", 1)
	
	register_native("Mileage_RemoveWeapon", "Native_RemoveWeapon", 1)
	register_native("Mileage_ResetWeapon", "Native_ResetWeapon", 1)
	register_native("Mileage_Weapon_RefillAmmo", "Native_RefillAmmo", 1)
	
	register_native("Mileage_WeaponAllow_Set", "Native_SetUseWeapon", 1)
	register_native("Mileage_WeaponAllow_Get", "Native_GetUseWeapon", 1)
	#endif
}
	
public Native_RegisterWeapon(const Name[], weapon_type, unlock_cost)
{
	param_convert(1)

	ArrayPushString(ArWeaponName, Name)
	ArrayPushCell(ArWeaponType, weapon_type)
	ArrayPushCell(ArWeaponCost, unlock_cost)
	
	if(g_FirstWeapon[weapon_type] == -1) 
		g_FirstWeapon[weapon_type] = g_TotalWeaponCount

	g_TotalWeaponCount++
	
	g_RegWeaponCount++
	return g_RegWeaponCount - 1
}

public Native_GiveRandomWeapon(id)
{
	new Pri, Sec
	
	Pri = random(g_WeaponListCount[WPN_PRIMARY])  //ListPri[random(g_Count[0])]
	Sec = random(g_WeaponListCount[WPN_SECONDARY]) //ListSec[random(g_Count[1])]
	
	switch(random_num(0, 100))
	{
		case 0..70:
		{
			rg_drop_items_by_slot(id, PRIMARY_WEAPON_SLOT)
			ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id,  Pri)

			if(!g_UnlockedWeapon[id][Pri]) 
				g_UnlockedWeapon[id][Pri] = 1
		}
		case 71..100:
		{
			rg_drop_items_by_slot(id, PISTOL_SLOT)
			ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id,  Sec)
			if(!g_UnlockedWeapon[id][Sec]) 
				g_UnlockedWeapon[id][Sec] = 1
		}
	}
}

public Native_OpenWeapon(id) 
{
	if(!is_user_alive(id))
		return
		
	Show_MainEquipMenu(id)
}

public Native_RemoveWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	Remove_PlayerWeapon(id)
}

public Native_ResetWeapon(id, NewPlayer)
{
	if(!is_user_alive(id))
		return
		
	Reset_PlayerWeapon(id, NewPlayer)
}

public Native_RefillAmmo(id)
{
	if(!is_user_alive(id))
		return
		
	Refill_PlayerWeapon(id)
}

public Native_SetUseWeapon(id, Allow)
{
	if(!is_user_alive(id))
		return
	g_GotWeapon[id] = Allow ? 0 : 1
}

public Native_GetUseWeapon(id)
{
	if(!is_user_alive(id))
		return 0
		
	return g_GotWeapon[id]
}

public client_putinserver(id)
{
	Reset_PlayerWeapon(id, 1)
}

public client_disconnected(id)
{
	Reset_PlayerWeapon(id, 1)
}

public zb3_user_spawned(id)
{
	if(zb3_get_user_zombie(id)) return

	// Reset
	Native_ResetWeapon(id, 0)
	Native_RemoveWeapon(id)
	Native_SetUseWeapon(id, 1)
	
	// Open
	Player_Equipment(id)

	static szTemp[128]

	formatex(szTemp, sizeof(szTemp), "%L", GAME_LANG, "SHOP_MISSCLICK")
	client_printc(id, szTemp)
}

public zb3_user_dead(id, Attacker, Headshot)
{
	if(zb3_get_user_zombie(id))
		return 
		
	Native_SetUseWeapon(id, 0)
}

public zb3_user_infected(id, Attacker, ClassID)
{
	Native_SetUseWeapon(id, 0)
}

public zevo_equipment_menu(id) Show_MainEquipMenu(id)

public Remove_PlayerWeapon(id)
{
	static i 
	for(i = 1; i < WPN_MAX; i++)
		if(g_PreWeapon[id][i] != 1) ExecuteForward(g_Forwards[WPN_REMOVE], g_fwResult, id, g_PreWeapon[id][i])
}

public Refill_PlayerWeapon(id)
{
	static i;

	for(i = 1; i < WPN_MAX; i++)
		if(g_PreWeapon[id][i] != 1) ExecuteForward(g_Forwards[WPN_ADDAMMO], g_fwResult, id, g_PreWeapon[id][i])
}

public Reset_PlayerWeapon(id, NewPlayer)
{
	static i
	if(NewPlayer)
	{
		for(i = 1; i < WPN_MAX; i++)
			g_PreWeapon[id][i] = g_FirstWeapon[i]

		for(i = 0; i < MAX_WEAPON; i++)
			g_UnlockedWeapon[id][i] = 0
	}
	
	g_GotWeapon[id] = 0
}

public Player_Equipment(id)
{
	if(zb3_get_randomizer())
	{
		remove_task(id+TASK_ROLL); remove_task(id+TASK_GIVE)
		set_task(random_float(1.0, 2.0), "RandomWeapon", id+TASK_ROLL)
		return
	}

	if(!is_user_bot(id)) Show_MainEquipMenu(id)
	else set_task(random_float(0.25, 1.0), "Bot_RandomWeapon", id)
}

public Show_MainEquipMenu(id)
{
	if(!is_user_alive(id) || g_GotWeapon[id])
		return
	
	static i, Menu, WeaponName[64], LangText[64], SystemName[64]; 
	formatex(SystemName, sizeof(SystemName), "[%L] %L", GAME_LANG, "GAME_BRANDING", GAME_LANG, "SHOP_WEAPON")
	Menu = menu_create(SystemName, "MenuHandle_MainEquip")
	
	for(i = 1; i <= WPN_MAX; i++)
	{
		if(i == WPN_MAX)
		{
			formatex(LangText, sizeof(LangText), "\y%L", GAME_LANG, "SHOP_GET")
			menu_additem(Menu, LangText, "get_wpn")
			continue
		}
		if(g_PreWeapon[id][i] >= 0)
		{
			ArrayGetString(ArWeaponName, g_PreWeapon[id][i], WeaponName, sizeof(WeaponName))
			formatex(LangText, sizeof(LangText), "%L \y%s\w", GAME_LANG, MenuLang[i], WeaponName)
		} else {
			formatex(LangText, sizeof(LangText), "%L \d N/A \w", GAME_LANG, MenuLang[i])
		}
		menu_additem(Menu, LangText, MenuHandle[i])
	}

	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, 0)
}



public MenuHandle_MainEquip(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id) || zb3_get_user_zombie(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)
	static i

	for(i = 1;i <= WPN_MAX;i++)
	{
		if(equal(Data, MenuHandle[i]))
		{
			if(i == WPN_MAX) { Equip_Weapon(id); continue; }
			if(g_WeaponListCount[i]) Show_WpnSubMenu(id, i, 0)
			else Show_MainEquipMenu(id)
		}
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Show_WpnSubMenu(id, WpnType, Page)
{
	static MenuName[64]
	formatex(MenuName, sizeof(MenuName), "[%L] %L", GAME_LANG, "GAME_BRANDING", GAME_LANG, MenuLang[WpnType])

	new Menu = menu_create(MenuName, "MenuHandle_WpnSubMenu")

	static WeaponType, WeaponName[32], MenuItem[64], MenuItemID[4]
	static WeaponPrice, Money; Money = get_member(id, m_iAccount); // cs_get_user_money(id)
	
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		WeaponType = ArrayGetCell(ArWeaponType, i)
		if(WpnType != WeaponType)
			continue
		
		ArrayGetString(ArWeaponName, i, WeaponName, sizeof(WeaponName))
		WeaponPrice = ArrayGetCell(ArWeaponCost, i)

		ExecuteForward(g_Forwards[WPN_PRE_BOUGHT], g_fwResult, id, g_PreWeapon[id][WeaponType])
		if(WeaponPrice > 0)
		{
			if(g_UnlockedWeapon[id][i]) 
				formatex(MenuItem, sizeof(MenuItem), "%s", WeaponName)
			else {
				if(Money >= WeaponPrice) formatex(MenuItem, sizeof(MenuItem), "%s \y($%i)\w", WeaponName, WeaponPrice)
				else formatex(MenuItem, sizeof(MenuItem), "\d%s \r($%i)\w", WeaponName, WeaponPrice)
			}
		} else {
			formatex(MenuItem, sizeof(MenuItem), "%s", WeaponName)
		}
		
		num_to_str(i, MenuItemID, sizeof(MenuItemID))
		menu_additem(Menu, MenuItem, MenuItemID)
	}
   
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, Page)
}

public MenuHandle_WpnSubMenu(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		Show_MainEquipMenu(id)
		
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id) || zb3_get_user_zombie(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)

	new ItemId = str_to_num(Data)
	new WeaponType, WeaponPrice, WeaponName[32]
	
	WeaponType = ArrayGetCell(ArWeaponType, ItemId)
	WeaponPrice = ArrayGetCell(ArWeaponCost, ItemId)
	ArrayGetString(ArWeaponName, ItemId, WeaponName, sizeof(WeaponName))

	new Money = get_member(id, m_iAccount);
	new OutputInfo[128]

	if(!g_UnlockedWeapon[id][ItemId])
	{
		if(!WeaponPrice) 
		{
			g_UnlockedWeapon[id][ItemId] = 1
			g_PreWeapon[id][WeaponType] = ItemId
			Show_MainEquipMenu(id)
		} 
		else if(Money >= WeaponPrice) 
		{
			g_UnlockedWeapon[id][ItemId] = 1
			g_PreWeapon[id][WeaponType] = ItemId
			rg_add_account(id, Money - WeaponPrice, AS_SET, true)
			Show_MainEquipMenu(id)
		} else {
			formatex(OutputInfo, sizeof(OutputInfo), "%L", GAME_LANG, "SHOP_NOT_ENOUGH_MONEY", WeaponName ,WeaponPrice)
			client_printc(id, OutputInfo)
			Show_MainEquipMenu(id)	
		}
	} else {						
		g_PreWeapon[id][WeaponType] = ItemId
		Show_MainEquipMenu(id)
	}

	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Equip_Weapon(id)
{
	if(!is_user_alive(id) || zb3_get_user_zombie(id) || zb3_get_user_hero(id))
		return;

	static i
	for(i = 1; i < WPN_MAX; i++)
	{
		rg_remove_items_by_slot(id, InventorySlotType:i);
		ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][i])
	}
	
	g_GotWeapon[id] = 1
}

public Bot_RandomWeapon(id)
{
	static i 

	for(i = 1; i < WPN_MAX; i++)
		pick_random_weapon_type(id, i)

	Equip_Weapon(id)
}

public RandomWeapon(id)
{
	id -= TASK_ROLL
	static i, szWeaponName[32], szPrint[128];
	szWeaponName[0] =  szPrint[0] = '^0'
	for(i = 1; i < WPN_MAX; i++)
	{
		pick_random_weapon_type(id, i)
		ArrayGetString(ArWeaponName, g_PreWeapon[id][i], szWeaponName, sizeof(szWeaponName))

		if(i < WPN_MAX - 1)
			strcat(szWeaponName, ", ", sizeof(szWeaponName))

		strcat(szPrint, szWeaponName, sizeof(szPrint))
	}
	set_hudmessage(255, 255, 255, -1.0, 0.25, 2, 1.0, 5.0, 0.005, 0.1)
	ShowSyncHudMsg(id, g_synchud1, "%L^n%s", LANG_SERVER, "RANDOM_WEAPON_NOTICE", szPrint)

	set_task(random_float(1.1, 2.0), "RandomWeaponGive", id+TASK_GIVE)
}
public RandomWeaponGive(id)
{
	id -= TASK_GIVE
	Equip_Weapon(id)
}
public pick_random_weapon_type(id, type)
{
	static FoundType;
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		FoundType = ArrayGetCell(ArWeaponType, i)
		if(FoundType != type)
			continue
		if(random_num(0, 2) > 0)
			continue
		
		g_PreWeapon[id][type] = i;
	}
}

