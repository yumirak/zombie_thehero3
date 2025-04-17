#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <zombie_thehero2>
#include <xs>

#define PLUGIN "[Zombie: The Hero] Addon: SupplyBox"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define supplybox_model  "models/zombie_thehero/supplybox.mdl"
#define supplybox_drop_sound "zombie_thehero/supply_drop.wav"
#define supplybox_pickup_sound "zombie_thehero/supply_pickup.wav"

#define SUPPLYBOX_CLASSNAME "supplybox"
#define SUPPLYBOX_MAX 32 // supply in 1 round
#define SUPPLYBOX_NUM 6 // supply deployed at a time
#define SUPPLYBOX_TOTAL_IN_TIME 6 // supply total in map at a time
#define SUPPLYBOX_DROPTIME 30 // supply delay next drop

#define TASK_SUPPLYBOX 128256
#define TASK_SUPPLYBOX2 138266
#define TASK_SUPPLYBOX_HELP 129257
#define TASK_SUPPLYBOX_WAIT 130259

// Hard Code
new g_supplybox_num, supplybox_count, supplybox_ent[SUPPLYBOX_MAX],
bool:made_supplybox, g_newround, g_endround
new g_maxplayers, g_msgHostagePos , g_msgHostageK

// Spawn Point Research
#define MAX_RETRY 40
new g_Forwards, g_dummy_forward

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_maxplayers = get_maxplayers()
	g_msgHostagePos = get_user_msgid("HostagePos")
	g_msgHostageK = get_user_msgid("HostageK")
	register_message(g_msgHostagePos, "message_hostagepos")

	//register_event("HLTV", "Event_Newround", "a", "1=0", "2=0")
	g_Forwards = CreateMultiForward("zb3_touch_supply", ET_IGNORE, FP_CELL)
	register_touch(SUPPLYBOX_CLASSNAME, "player", "fw_Touch_SupplyBox")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, supplybox_model)
	
	engfunc(EngFunc_PrecacheSound, supplybox_drop_sound)
	engfunc(EngFunc_PrecacheSound, supplybox_pickup_sound)
	
}

public radar_scan()
{	
	for (new id = 1; id < g_maxplayers; id++)
	{
		if (!is_user_alive(id) || is_user_bot(id) || zb3_get_user_zombie(id)) continue;
		
		// scan supply box
		if (!supplybox_count) continue;
		
		new i = 1, next_ent 
		static Float:origin[3]//, Buffer[32], ent_classname[32]
		//formatex(Buffer, sizeof(Buffer), SUPPLYBOX_CLASSNAME, ent_classname)
		while(i < SUPPLYBOX_MAX)
		{
			next_ent = supplybox_ent[i]
			if (next_ent && entity_get_string(next_ent, EV_SZ_classname, SUPPLYBOX_CLASSNAME, 32)) //, ,SUPPLYBOX_CLASSNAME
			{
				pev(next_ent, pev_origin, origin)
				
				message_begin_f(MSG_ONE_UNRELIABLE, g_msgHostagePos, _, id)
				write_byte(id)
				write_byte(i)		
				write_coord_f(origin[0])
				write_coord_f(origin[1])
				write_coord_f(origin[2])
				message_end()
			
				message_begin(MSG_ONE_UNRELIABLE, g_msgHostageK, {0,0,0}, id)
				write_byte(i)
				message_end()
				//client_print(id, print_chat, "[%i] [%i] [%i] [%i]", next_ent, origin[0], origin[1], origin[2])
			}
			i++
		}
		//client_print(id, print_chat, "[%i][%i]", supplybox_count, i)
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
		made_supplybox = false
		g_newround = 1
		g_endround = 0
		
		remove_supplybox()
		supplybox_count = 0
		
		if(task_exists(TASK_SUPPLYBOX)) remove_task(TASK_SUPPLYBOX)
		if(task_exists(TASK_SUPPLYBOX2)) remove_task(TASK_SUPPLYBOX2)
		if(task_exists(TASK_SUPPLYBOX_HELP)) remove_task(TASK_SUPPLYBOX_HELP)	
	}
	case GAMESTART_ZOMBIEAPPEAR:
	{
		if(!made_supplybox)
		{
			g_newround = 0
			made_supplybox = true
			
			if(task_exists(TASK_SUPPLYBOX)) remove_task(TASK_SUPPLYBOX)
			set_task(float(SUPPLYBOX_DROPTIME), "create_supplybox", TASK_SUPPLYBOX)
		}
	}
	}
}
public zb3_game_end() g_endround = 1

public remove_supplybox()
{
	remove_entity_name(SUPPLYBOX_CLASSNAME)
	
	for (new i = 0; i < SUPPLYBOX_MAX; i++)
		supplybox_ent[i] = 0
	for (new i = 1; i < zb3_get_player_spawn_count(); i++)
		zb3_set_player_spawn_used(i, false)
}

public create_supplybox()
{
	if (supplybox_count >= SUPPLYBOX_MAX ||  g_newround || g_endround) 
		return

	if (task_exists(TASK_SUPPLYBOX)) remove_task(TASK_SUPPLYBOX)
	set_task(float(SUPPLYBOX_DROPTIME), "create_supplybox", TASK_SUPPLYBOX)
	
	if(supplybox_count >= SUPPLYBOX_TOTAL_IN_TIME)
		return;
	
	for(new i = 1; i < g_maxplayers; i++)
	{
		if(!is_user_alive(i) || is_user_bot(i) || zb3_get_user_zombie(i))
			continue;

		client_cmd(i, "spk ^"%s^"", supplybox_drop_sound)
		client_print(i, print_center, "%L", LANG_PLAYER, "NOTICE_ITEM_BROADCAST")	
	}

	g_supplybox_num = 0
	create_supplybox2()

	if (task_exists(TASK_SUPPLYBOX2)) remove_task(TASK_SUPPLYBOX2)
	set_task(0.5, "create_supplybox2", TASK_SUPPLYBOX2, _, _, "b")	
}

public create_supplybox2()
{
	if (supplybox_count >= SUPPLYBOX_MAX || supplybox_count >= SUPPLYBOX_TOTAL_IN_TIME || g_newround || g_endround)
	{
		remove_task(TASK_SUPPLYBOX2)
		return
	}
	
	supplybox_count++
	g_supplybox_num++

	new ent = create_entity("info_target")
	
	entity_set_string(ent, EV_SZ_classname, SUPPLYBOX_CLASSNAME)
	entity_set_model(ent, supplybox_model)	
	entity_set_size(ent,Float:{-2.0,-2.0,-2.0},Float:{5.0,5.0,5.0})
	entity_set_int(ent,EV_INT_solid, SOLID_TRIGGER)
	entity_set_int(ent,EV_INT_movetype,MOVETYPE_TOSS)
	entity_set_int(ent, EV_INT_iuser1, 0)
	entity_set_int(ent, EV_INT_iuser2, supplybox_count)
	
	do_random_spawn(ent, MAX_RETRY)
	
	supplybox_ent[supplybox_count] = ent

	if ((g_supplybox_num >= SUPPLYBOX_NUM) && task_exists(TASK_SUPPLYBOX2)) 
		remove_task(TASK_SUPPLYBOX2)
}

public fw_Touch_SupplyBox(ent, id)
{
	if(!pev_valid(ent))
		return
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return
	
	//zb3_supplybox_random_getitem(id, zb3_get_user_hero(id) ? 1 : 0)
	ExecuteForward(g_Forwards, g_dummy_forward, id)
	emit_sound(id, CHAN_VOICE, supplybox_pickup_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new num_box = entity_get_int(ent, EV_INT_iuser2)
	new spawn_num_used = entity_get_int(ent, EV_INT_iuser1)

	zb3_set_player_spawn_used(spawn_num_used, false) // reset used origin
	supplybox_ent[num_box] = 0 
	supplybox_count--

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
	
	if(is_hull_vacant(Origin, hull) && !zb3_get_player_spawn_used(random_mem) )
	{
		engfunc(EngFunc_SetOrigin, id, Origin)
		zb3_set_player_spawn_used(random_mem, true)
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

stock normalize(Float:fIn[3], Float:fOut[3], Float:fMul) // By sontung0
{
	new Float:fLen = xs_vec_len(fIn)
	xs_vec_copy(fIn, fOut)
	
	fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen
	fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul
}

