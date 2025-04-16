#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <zombie_thehero2>
#include <xs>

#define PLUGIN "[Zombie: The Hero] Addon: SupplyBox"
#define VERSION "2.0"
#define AUTHOR "Dias"

// Config
const MAX_SUPPLYBOX_ENT = 100

new const supplybox_model[] = "models/zombie_thehero/supplybox.mdl"
new const supplybox_drop_sound[] = "zombie_thehero/supply_drop.wav"
new const supplybox_pickup_sound[] = "zombie_thehero/supply_pickup.wav"
new const supplybox_icon_spr[] = "sprites/zombie_thehero/icon_supplybox.spr"

#define SUPPLYBOX_CLASSNAME "supplybox"
#define SUPPLYBOX_MAX 16
#define SUPPLYBOX_NUM 2
#define SUPPLYBOX_TOTAL_IN_TIME 4
#define SUPPLYBOX_DROPTIME 30
#define SUPPLYBOX_RADARNICON_DELAY 0.5
#define SUPPLYBOX_ICON 1
#define SUPPLYBOX_ICON_SIZE 2
#define SUPPLYBOX_ICON_LIGHT 100

#define TASK_SUPPLYBOX 128256
#define TASK_SUPPLYBOX2 138266
#define TASK_SUPPLYBOX_HELP 129257
#define TASK_SUPPLYBOX_WAIT 130259

// Hard Code
new g_supplybox_num, g_supplybox_wait[33], supplybox_count, supplybox_ent[MAX_SUPPLYBOX_ENT],
g_supplybox_icon_id, bool:made_supplybox, g_newround, g_endround, Float:g_hud_supplybox_delay[33]

#define MAX_RETRY 33

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "Event_Newround", "a", "1=0", "2=0")
	register_touch(SUPPLYBOX_CLASSNAME, "player", "fw_Touch_SupplyBox")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, supplybox_model)
	
	engfunc(EngFunc_PrecacheSound, supplybox_drop_sound)
	engfunc(EngFunc_PrecacheSound, supplybox_pickup_sound)
	
	g_supplybox_icon_id = engfunc(EngFunc_PrecacheModel, supplybox_icon_spr)
}

public client_PostThink(id)
{
	if(get_gametime() - SUPPLYBOX_RADARNICON_DELAY <= g_hud_supplybox_delay[id])
		return
		
	g_hud_supplybox_delay[id] = get_gametime()
		
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return
	if(!supplybox_count)
		return
		
	static i, next_ent
	i = 1
	while(i <= supplybox_count)
	{
		next_ent = supplybox_ent[i]
		if (next_ent && pev_valid(next_ent))
		{
			create_icon_origin(id, next_ent, g_supplybox_icon_id)
		}

		i++
	}			
}

public Event_Newround()
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

public remove_supplybox()
{
	remove_entity_name(SUPPLYBOX_CLASSNAME)
	
	new supplybox_ent_reset[MAX_SUPPLYBOX_ENT]
	supplybox_ent = supplybox_ent_reset
}

public zb3_game_end() g_endround = 1
public zb3_user_infected()
{
	if(!made_supplybox)
	{
		g_newround = 0
		made_supplybox = true
		
		if(task_exists(TASK_SUPPLYBOX)) remove_task(TASK_SUPPLYBOX)
		set_task(float(SUPPLYBOX_DROPTIME), "create_supplybox", TASK_SUPPLYBOX)
	}
}

public create_supplybox()
{
	if (supplybox_count >= SUPPLYBOX_MAX || g_newround || g_endround) 
		return

	if (task_exists(TASK_SUPPLYBOX)) remove_task(TASK_SUPPLYBOX)
	set_task(float(SUPPLYBOX_DROPTIME), "create_supplybox", TASK_SUPPLYBOX)
	
	if (get_total_supplybox() >= SUPPLYBOX_TOTAL_IN_TIME) 
		return

	g_supplybox_num = 0
	create_supplybox2()
	
	client_cmd(0, "spk ^"%s^"", supplybox_drop_sound)
	client_print(0, print_center, "Supplyboxs Have Been Dropped !!!")
	
	if (task_exists(TASK_SUPPLYBOX2)) remove_task(TASK_SUPPLYBOX2)
	set_task(0.5, "create_supplybox2", TASK_SUPPLYBOX2, _, _, "b")	
}

public create_supplybox2()
{
	if (supplybox_count >= SUPPLYBOX_MAX
	|| get_total_supplybox() >= SUPPLYBOX_TOTAL_IN_TIME || g_newround || g_endround)
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
	entity_set_int(ent,EV_INT_solid,1)
	entity_set_int(ent,EV_INT_movetype,6)
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
	
	zb3_supplybox_random_getitem(id, zb3_get_user_hero(id) == 0 ? 0 : 2)
	emit_sound(id, CHAN_VOICE, supplybox_pickup_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)

	new num_box = entity_get_int(ent, EV_INT_iuser2)
	new spawn_num_used = entity_get_int(ent, EV_INT_iuser1)

	zb3_set_player_spawn_used(spawn_num_used, false) // reset used origin
	supplybox_ent[num_box] = 0
	remove_entity(ent)

	g_supplybox_wait[id] = 1
	if (task_exists(id+TASK_SUPPLYBOX_WAIT)) remove_task(id+TASK_SUPPLYBOX_WAIT)
	set_task(2.0, "remove_supplybox_wait", id+TASK_SUPPLYBOX_WAIT)
	
	return
}

public remove_supplybox_wait(id)
{
	id -= TASK_SUPPLYBOX_WAIT
	
	g_supplybox_wait[id] = 0
	if (task_exists(id+TASK_SUPPLYBOX_WAIT)) remove_task(id+TASK_SUPPLYBOX_WAIT)
}

public get_total_supplybox()
{
	new total
	for (new i = 1; i <= supplybox_count; i++)
	{
		if (supplybox_ent[i]) total += 1
	}
	return total
}

public do_random_spawn(id, retry_count)
{
	if(!pev_valid(id))
		return
	
	static hull, Float:Origin[3], random_mem
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	random_mem = random_num(0, zb3_get_player_spawn_count())
	Origin[0] = zb3_get_player_spawn_cord(random_mem,0)
	Origin[1] = zb3_get_player_spawn_cord(random_mem,1)
	Origin[2] = zb3_get_player_spawn_cord(random_mem,2)
	
	if(is_hull_vacant(Origin, hull) && !zb3_get_player_spawn_used(random_mem))
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

stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock create_icon_origin(id, ent, sprite) // By sontung0
{
	if (!pev_valid(ent)) return;
	if(!is_user_alive(id)) return
	
	new Float:fMyOrigin[3]
	entity_get_vector(id, EV_VEC_origin, fMyOrigin)
	
	new target = ent
	new Float:fTargetOrigin[3]
	entity_get_vector(target, EV_VEC_origin, fTargetOrigin)
	fTargetOrigin[2] += 40.0
	
	if (!is_in_viewcone(id, fTargetOrigin)) return;

	new Float:fMiddle[3], Float:fHitPoint[3]
	xs_vec_sub(fTargetOrigin, fMyOrigin, fMiddle)
	trace_line(-1, fMyOrigin, fTargetOrigin, fHitPoint)
							
	new Float:fWallOffset[3], Float:fDistanceToWall
	fDistanceToWall = vector_distance(fMyOrigin, fHitPoint) - 10.0
	normalize(fMiddle, fWallOffset, fDistanceToWall)
	
	new Float:fSpriteOffset[3]
	xs_vec_add(fWallOffset, fMyOrigin, fSpriteOffset)
	new Float:fScale
	fScale = 0.01 * fDistanceToWall
	
	new scale = floatround(fScale)
	scale = max(scale, 1)
	scale = min(scale, SUPPLYBOX_ICON_SIZE)
	scale = max(scale, 1)

	te_sprite(id, fSpriteOffset, sprite, scale, SUPPLYBOX_ICON_LIGHT)
}

stock te_sprite(id, Float:origin[3], sprite, scale, brightness) // By sontung0
{	
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_SPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(sprite)
	write_byte(scale) 
	write_byte(brightness)
	message_end()
}

stock normalize(Float:fIn[3], Float:fOut[3], Float:fMul) // By sontung0
{
	new Float:fLen = xs_vec_len(fIn)
	xs_vec_copy(fIn, fOut)
	
	fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen
	fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
