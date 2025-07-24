#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <zombie_thehero2>
#include <xs>
#include <reapi>
#define PLUGIN "[Zombie: The Hero] Addon: SupplyBox"
#define VERSION "2.0"
#define AUTHOR "Dias"

new const SETTING_FILE[] = "zombie_thehero2/config.ini"
new const SETTING_CONFIG[] = "Supply Box"

#define SUPPLYBOX_IMPULSE 9124678
#define SUPPLYBOX_CLASSNAME "supplybox"

#define TASK_SUPPLYBOX 128256
#define TASK_SUPPLYBOX2 138266

new g_cfg_supplybox_drop_max, g_cfg_supplybox_drop_num, g_cfg_supplybox_cur_max, Float:g_cfg_supplybox_drop_time, Float:g_cfg_supplybox_drop_range
new Array:g_cfg_supplybox_model, supplybox_drop_sound[128], supplybox_pickup_sound[128]

// Hard Code
new g_supplybox_num, g_supplybox_cur, g_supplybox_cycle, g_can_spawn
new g_maxplayers, g_msgHostagePos , g_msgHostageK

// Spawn Point Research
#define MAX_RETRY 40
new g_forward[FWD_SUPPLY_MAX], g_dummy_forward
new g_item_i
new Array:Supply_Item_Name

public plugin_init()
{
	if(zb3_get_mode() <= MODE_ORIGINAL)
	{
		set_fail_state("[ZB3] Error: GameMode is less than 2. It's okay to ignore this error.")
		return
	}
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_maxplayers = get_maxplayers()
	g_msgHostagePos = get_user_msgid("HostagePos")
	g_msgHostageK = get_user_msgid("HostageK")
	register_message(g_msgHostagePos, "message_hostagepos")

	g_forward[FWD_SUPPLY_ITEM_GIVE] = CreateMultiForward("zb3_supply_item_give", ET_IGNORE, FP_CELL, FP_CELL)
	g_forward[FWD_SUPPLY_AMMO_GIVE] = CreateMultiForward("zb3_supply_refill_ammo", ET_IGNORE, FP_CELL)
	register_touch(SUPPLYBOX_CLASSNAME, "player", "fw_Touch_SupplyBox")
}

public plugin_precache()
{
	static i, buffer[128], buffer2[128];
	g_cfg_supplybox_model = ArrayCreate(64, 1)
	Supply_Item_Name = ArrayCreate(64, 1)

	load_cfg()

	for (i = 0; i < ArraySize(g_cfg_supplybox_model); i++)
	{
		ArrayGetString(g_cfg_supplybox_model, i, buffer, charsmax(buffer))
		format(buffer2, sizeof(buffer2), "%s", buffer, buffer)
		
		engfunc(EngFunc_PrecacheModel, buffer2)
	}

	engfunc(EngFunc_PrecacheSound, supplybox_drop_sound)
	engfunc(EngFunc_PrecacheSound, supplybox_pickup_sound)
	
}
public load_cfg()
{
	static buffer[128], Array:DummyArray

	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SUPPLYBOX_MAX", buffer, sizeof(buffer), DummyArray); g_cfg_supplybox_drop_max = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SUPPLYBOX_NUM", buffer, sizeof(buffer), DummyArray); g_cfg_supplybox_drop_num = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SUPPLYBOX_TIME", buffer, sizeof(buffer), DummyArray); g_cfg_supplybox_drop_time = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SUPPLYBOX_RANGE", buffer, sizeof(buffer), DummyArray); g_cfg_supplybox_drop_range = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SUPPLYBOX_TOTAL_IN_TIME", buffer, sizeof(buffer), DummyArray); g_cfg_supplybox_cur_max = str_to_num(buffer)

	zb3_load_setting_string(true,  SETTING_FILE, SETTING_CONFIG, "SUPPLYBOX_MODEL", buffer, 0, g_cfg_supplybox_model);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SUPPLYBOX_SOUND_DROP", supplybox_drop_sound, sizeof(supplybox_drop_sound), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, SETTING_CONFIG, "SUPPLYBOX_SOUND_PICKUP", supplybox_pickup_sound, sizeof(supplybox_pickup_sound), DummyArray);
}

public plugin_natives()
{
	register_native("zb3_register_supply_item", "native_register_supply_item", 1)
}

public native_register_supply_item(const Name[])
{
	param_convert(1)
	
	ArrayPushString(Supply_Item_Name, Name)
	
	g_item_i++
	return g_item_i - 1
}

public get_registered_random_weapon(id)
{
	if(!is_user_alive(id))
		return

	if(zb3_get_user_hero(id))
	{
		zb3_give_user_ammo(id)
		ExecuteForward(g_forward[FWD_SUPPLY_AMMO_GIVE], g_dummy_forward, id)
		return
	}

	static item_id
	item_id = random_num(0, g_item_i - 1)

	ExecuteForward(g_forward[FWD_SUPPLY_ITEM_GIVE], g_dummy_forward, id, item_id)
	ExecuteForward(g_forward[FWD_SUPPLY_AMMO_GIVE], g_dummy_forward, id)
	zb3_give_user_ammo(id)
	notice_supply(id, item_id)
}

stock notice_supply(id, itemid)
{
	new buffer[256], name[64], Temp_String[64]

	get_user_name(id, name, sizeof(name))
	ArrayGetString(Supply_Item_Name, itemid, Temp_String, sizeof(Temp_String))
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP_BROADCAST", name, Temp_String)
	
	for (new i = 1; i <= get_maxplayers(); i++)
	{
		 if (!is_user_connected(i) || i == id) continue;
		 client_print(i, print_center, buffer)
	}
	
	format(buffer, charsmax(buffer), "%L", LANG_PLAYER, "NOTICE_ITEM_PICKUP", Temp_String)
	client_print(id, print_center, buffer)
}
///////////// CREATE SUPPLY
public radar_scan()
{	
	if (!g_supplybox_cur)
		return

	for (new id = 1; id < g_maxplayers; id++)
	{
		if (!is_user_alive(id) || is_user_bot(id) || zb3_get_user_zombie(id)) continue;
		
		static i, count;
		i = count = 0
		static Float:supply_origin[3], Float:origin[3]

		pev(id, pev_origin, origin)
		while((i = find_ent_in_sphere(i, origin, 8192.0)) != 0)
		{
			if(pev(i, pev_impulse) != SUPPLYBOX_IMPULSE)
				continue

			pev(i, pev_origin, supply_origin)
#if defined _DEBUG
			client_print(id, print_chat, "[%i] [%f] [%f] [%f]", i, supply_origin[0], supply_origin[1], supply_origin[2])
#endif
			message_begin_f(MSG_ONE_UNRELIABLE, g_msgHostagePos, _, id)
			write_byte(id)
			write_byte(count)		
			write_coord_f(supply_origin[0])
			write_coord_f(supply_origin[1])
			write_coord_f(supply_origin[2])
			message_end()
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgHostageK, {0,0,0}, id)
			write_byte(count)
			message_end()
			count++
		}
	}
}

public zb3_time_change()
{
	radar_scan()
}
public zb3_game_start(start_type)
{
	switch(start_type)
	{
	case GAMESTART_NEWROUND:
	{
		g_can_spawn = 0
		
		remove_supplybox()
		g_supplybox_cur = 0
		g_supplybox_num = 0
		
		if(task_exists(TASK_SUPPLYBOX)) remove_task(TASK_SUPPLYBOX)
		if(task_exists(TASK_SUPPLYBOX2)) remove_task(TASK_SUPPLYBOX2)
	}
	case GAMESTART_ZOMBIEAPPEAR:
	{
		g_can_spawn = 1

		if(task_exists(TASK_SUPPLYBOX)) remove_task(TASK_SUPPLYBOX)
		set_task(g_cfg_supplybox_drop_time, "create_supplybox", TASK_SUPPLYBOX, _, _, "b")
	}
	}
}
public zb3_game_end() g_can_spawn = 0

public remove_supplybox()
{
	remove_entity_name(SUPPLYBOX_CLASSNAME)
}

public create_supplybox()
{
	if(g_supplybox_num >= g_cfg_supplybox_drop_max || !g_can_spawn)
	{
		remove_task(TASK_SUPPLYBOX)
		return
	}

	if(g_supplybox_cur >= g_cfg_supplybox_cur_max)
		return
	
	for(new i = 1; i < g_maxplayers; i++)
	{
		if(!is_user_alive(i) || is_user_bot(i) || zb3_get_user_zombie(i))
			continue;

		client_cmd(i, "spk ^"%s^"", supplybox_drop_sound)
		client_print(i, print_center, "%L", LANG_PLAYER, "NOTICE_ITEM_BROADCAST")	
	}

	g_supplybox_cycle = 0

	if (task_exists(TASK_SUPPLYBOX2)) remove_task(TASK_SUPPLYBOX2)
	set_task(0.5, "create_supplybox2", TASK_SUPPLYBOX2, _, _, "b")	
}

public create_supplybox2()
{
	if (g_supplybox_num >= g_cfg_supplybox_drop_max 
	||  g_supplybox_cur >= g_cfg_supplybox_cur_max 
	||  g_supplybox_cycle >= g_cfg_supplybox_drop_num || !g_can_spawn)
	{
		remove_task(TASK_SUPPLYBOX2)
		return
	}
	
	g_supplybox_cur++
	g_supplybox_num++
	g_supplybox_cycle++ 

	static szModel[128];
	ArrayGetString(g_cfg_supplybox_model, get_random_array(g_cfg_supplybox_model), szModel, sizeof(szModel))

	new ent = create_entity("info_target")

	entity_set_string(ent, EV_SZ_classname, SUPPLYBOX_CLASSNAME)
	entity_set_model(ent, szModel)	
	entity_set_size(ent,Float:{-2.0,-2.0,-2.0},Float:{5.0,5.0,5.0})
	entity_set_int(ent,EV_INT_solid, SOLID_TRIGGER)
	entity_set_int(ent,EV_INT_movetype,MOVETYPE_TOSS)
	entity_set_int(ent, EV_INT_impulse, SUPPLYBOX_IMPULSE)
	
	do_random_spawn(ent, MAX_RETRY)

}

public fw_Touch_SupplyBox(ent, id)
{
	if(!pev_valid(ent))
		return
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return

	get_registered_random_weapon(id)
	emit_sound(id, CHAN_VOICE, supplybox_pickup_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)

	g_supplybox_cur--

	remove_entity(ent)
	return
}
public do_random_spawn(id, retry_count)
{
	if(!pev_valid(id))
		return
	
	static hull, Float:Origin[3], random_mem
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	random_mem = random_num(0, zb3_get_player_spawn_count() - 1)

	Origin[0] = zb3_get_player_spawn_cord(random_mem, 0)
	Origin[1] = zb3_get_player_spawn_cord(random_mem, 1)
	Origin[2] = zb3_get_player_spawn_cord(random_mem, 2)
	
	if(is_hull_vacant(Origin, hull) && !check_nearby_supply(Origin))
	{
		engfunc(EngFunc_SetOrigin, id, Origin)
		entity_set_int(id, EV_INT_iuser1, random_mem)
	}
	else
	{
		if(retry_count > 0)
		{
			retry_count--
			do_random_spawn(id, retry_count)
		}
	}
}
public check_nearby_supply(Float:Orig[3])
{
	static i, supply; i = supply = 0
	while((i = find_ent_in_sphere(i, Orig, g_cfg_supplybox_drop_range)) != 0)
	{
		if(pev(i, pev_impulse) != SUPPLYBOX_IMPULSE)
			continue

		supply = i
	}

	return supply
}

public message_hostagepos()
{
	return PLUGIN_HANDLED;
}

stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen)) 
		return true;
	
	return false;
}

stock get_random_array(Array:array_name)
{
	return random_num(0, ArraySize(array_name) - 1)
}
