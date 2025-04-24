#include <amxmodx>
#include <amxmisc>
//#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>
#include <zombie_thehero2>

#define PLUGIN "[Zombie: The Hero] Zombie Item"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define MAX_CLASS 20
#define DELAY_TIME 2.0
#define ITEM_FILE "zombie_thehero_item.ini"

/// ============== CONFIGS ===================
const g_x_health_armor_cost = 5000
const zombie_grenade_cost = 7000
const g_70_infect_cost = 5000
new const ZOMBIEBOM_MODEL[] = "zombibomb"
const Float:ZOMBIEBOM_RADIUS = 250.0
const Float:ZOMBIEBOM_POWER = 700.0
new const ZOMBIEBOM_SPRITES_EXP[] = "sprites/zombie_thehero/zombiebomb_exp.spr"
new const ZOMBIEBOM_SOUND_EXP[] = "zombie_thehero/zombi_bomb_exp.wav"
const g_im_respawn_cost = 3000
new const zombi_bomb_sound[][] =
{
	"zombie_thehero/zombi_bomb_throw.wav",
	"zombie_thehero/zombi_bomb_pull_1.wav",
	"zombie_thehero/zombi_bomb_idle_4.wav",
	"zombie_thehero/zombi_bomb_idle_3.wav",
	"zombie_thehero/zombi_bomb_idle_2.wav",
	"zombie_thehero/zombi_bomb_idle_1.wav",
	"zombie_thehero/zombi_bomb_deploy.wav",
	"zombie_thehero/zombi_bomb_bounce_2.wav",
	"zombie_thehero/zombi_bomb_bounce_1.wav"
}
/// ==========================================

new Float:g_hud_delay[33], g_sync_hud1

// Item: x Health & Armor
new g_x_health_armor, g_had_x_health_armor[33], g_x_health_armor_used[33]

// Item: Zombie Grenade
new Array:model_host, Array:model_origin
new ZOMBIEBOM_IDSPRITES_EXP,
ZOMBIEBOM_P_MODEL[64], ZOMBIEBOM_W_MODEL[64]

const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_BLAST = 1123

new zombie_grenade
new g_had_zombie_grenade[33]
// Item: Immediate Respawn
new g_im_respawn, g_had_im_respawn[33]

// Item: 70% Infect Health
new g_70_infect, g_had_70_infect[33]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_event("TextMsg", "event_restart", "a", "2=#Game_will_restart_in")
	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")
	register_forward(FM_SetModel, "fw_SetModel")
	
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	
	g_sync_hud1 = zb3_get_synchud_id(SYNCHUD_HUMANZOMBIE_ITEM)
}

public plugin_precache()
{
	model_host = ArrayCreate(64, 1)
	model_origin = ArrayCreate(64, 1)
	
	format(ZOMBIEBOM_P_MODEL, charsmax(ZOMBIEBOM_P_MODEL), "models/zombie_thehero/p_%s.mdl", ZOMBIEBOM_MODEL)
	format(ZOMBIEBOM_W_MODEL, charsmax(ZOMBIEBOM_W_MODEL), "models/zombie_thehero/w_%s.mdl", ZOMBIEBOM_MODEL)
	
	precache_model(ZOMBIEBOM_P_MODEL)
	precache_model(ZOMBIEBOM_W_MODEL)
	
	ZOMBIEBOM_IDSPRITES_EXP = precache_model(ZOMBIEBOM_SPRITES_EXP)
	precache_sound(ZOMBIEBOM_SOUND_EXP)	
	
	static Temp_String[128], i, size

	size = ArraySize(model_host)
	for(i = 0; i < size; i++)
	{
		ArrayGetString(model_host, i, Temp_String, sizeof(Temp_String))
		engfunc(EngFunc_PrecacheModel, Temp_String)
	}

	size = ArraySize(model_origin)
	for(i = 0; i < size; i++)
	{
		ArrayGetString(model_origin, i, Temp_String, sizeof(Temp_String))
		engfunc(EngFunc_PrecacheModel, Temp_String)
	}

	size = sizeof(zombi_bomb_sound)
	for(i = 0; i < size; i++)
		engfunc(EngFunc_PrecacheSound, zombi_bomb_sound[i])
	

	if(zb3_get_mode() >= MODE_MUTATION) 
	{
		g_x_health_armor = zb3_register_item("x1.5 Health & Armor", "More Health & Armor for Zombie", g_x_health_armor_cost, TEAM2_ZOMBIE, 1)
		g_70_infect = zb3_register_item("70% Infect Health", "Lesser Health Penalty", g_70_infect_cost, TEAM2_ZOMBIE, 1)
		zombie_grenade = zb3_register_item("Zombie Grenade", "Knock Human Back", zombie_grenade_cost, TEAM2_ZOMBIE, 1)
		g_im_respawn = zb3_register_item("Immediate Respawn", "No Respawn Delay", g_im_respawn_cost, TEAM2_ZOMBIE, 1)
	}
}

public plugin_natives()
{
	register_native("zb3_register_zbgre_model", "native_reg_zbgr_model", 1)
}

public native_reg_zbgr_model(const v_model_host[], const v_model_origin[])
{
	param_convert(1)
	param_convert(2)	
	
	ArrayPushString(model_host, v_model_host)
	ArrayPushString(model_origin, v_model_origin)
	
	precache_model(v_model_host)
	precache_model(v_model_origin)
}

public zb3_game_start(start_type)
{
	for(new i = 0; i < MAX_PLAYERS;i++)
		g_x_health_armor_used[i] = 0
}

public event_restart()
{
	for(new i = 1; i < MAX_PLAYERS;i++)
	{
		reset_value(i)
	}
}

public zb3_item_selected_post(id, itemid)
{
	if(itemid == g_x_health_armor)
		g_had_x_health_armor[id] = 1
	else if(itemid == zombie_grenade) {
		g_had_zombie_grenade[id] = 1
		zombie_grenade_handle(id)
	} else if(itemid == g_im_respawn) {
		g_had_im_respawn[id] = 1
		zb3_set_user_respawn_time(id, 0)
	} else if(itemid == g_70_infect) {
		g_had_70_infect[id] = 1
		zb3_set_user_infect_mod(id, 0.7)
	}
}

public zb3_user_infected(id)
{
	x_health_armor_handle(id)
	zombie_grenade_handle(id)
}

public zb3_zombie_evolution(id, level)
{
	if(level > 1)
	{
		if(g_had_zombie_grenade[id] && get_user_weapon(id) == CSW_HEGRENADE)
		{
			new model[64]
			if (zb3_get_user_level(id) > 1) ArrayGetString(model_origin, zb3_get_user_zombie_class(id), model, charsmax(model))
			else ArrayGetString(model_host, zb3_get_user_zombie_class(id), model, charsmax(model))
			
			set_pev(id, pev_viewmodel2, model)
			set_pev(id, pev_weaponmodel2, ZOMBIEBOM_P_MODEL)
		}
	}
}

public zb3_user_change_class(id, class)
{
	if(g_had_zombie_grenade[id] && get_user_weapon(id) == CSW_HEGRENADE)
	{
		new model[64]
		if (zb3_get_user_level(id) > 1) ArrayGetString(model_origin, class, model, charsmax(model))
		else ArrayGetString(model_host, class, model, charsmax(model))
		
		set_pev(id, pev_viewmodel2, model)
		set_pev(id, pev_weaponmodel2, ZOMBIEBOM_P_MODEL)
	}	
}

public client_putinserver(id)
{
	reset_value(id)
}

public reset_value(id)
{
	g_had_x_health_armor[id] = 0
	g_x_health_armor_used[id] = 0
	g_had_zombie_grenade[id] = 0
	g_had_im_respawn[id] = 0
	
	g_had_70_infect[id] = 0

	zb3_reset_user_respawn_time(id)
	zb3_reset_user_infect_mod(id)
}

#if 0
public client_PostThink(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
		
	static Float:CurTime
	CurTime = get_gametime()
	
	if(CurTime - DELAY_TIME > g_hud_delay[id])
	{
		static Temp_String[128], Temp_String2[128], Temp_String3[128]
		formatex(Temp_String, sizeof(Temp_String), "[Items]^n")
		
		if(g_had_x_health_armor[id])
		{
			formatex(Temp_String2, sizeof(Temp_String2), " x1.5 Health & Armor", Temp_String)
			formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
			formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
		}
		if(g_had_zombie_grenade[id])
		{
			formatex(Temp_String2, sizeof(Temp_String2), " Zombie Grenade", Temp_String)
			formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
			formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
		}
		if(g_had_im_respawn[id])
		{
			formatex(Temp_String2, sizeof(Temp_String2), " Immediate Respawn", Temp_String)
			formatex(Temp_String3, sizeof(Temp_String3), "%s^n%s", Temp_String, Temp_String2)
			formatex(Temp_String, sizeof(Temp_String), "%s", Temp_String3)
		}

		set_hudmessage(0, 255, 0, 0.015, 0.20, 0, 2.0, 2.0)
		ShowSyncHudMsg(id, g_sync_hud1, Temp_String3)		
		
		g_hud_delay[id] = CurTime
	}
}
#endif

// ================= Item: x Health & Armor
public x_health_armor_handle(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(zb3_get_user_level(id) > 1)
		return
	if(!g_had_x_health_armor[id])
		return
	if(g_x_health_armor_used[id])
		return
		
	static Float:Health, Float:Armor, Float:MaxHealth, Float:MaxArmor, Float:NewHealth, Float:NewArmor
	
	Health = float(zb3_get_user_starthealth(id))
	Armor =  float(zb3_get_user_startarmor(id))
	MaxHealth =  float(zb3_get_user_maxhealth(id))
	MaxArmor =  float(zb3_get_user_maxarmor(id))

	NewHealth = floatclamp(Health * 1.5, Health , MaxHealth)
	NewArmor = floatclamp(Armor* 1.5 , Armor , MaxArmor)
	
	zb3_set_user_starthealth(id, floatround(NewHealth))
	zb3_set_user_startarmor(id, floatround(NewArmor))
	
	set_user_health(id, floatround(NewHealth))
	set_user_armor(id, floatround(NewArmor))

	g_x_health_armor_used[id] = 1
}
// ================= Item: Zombie Grenade
public zombie_grenade_handle(id)
{
	if(!is_user_alive(id))
		return
	if(!zb3_get_user_zombie(id))
		return
	if(!g_had_zombie_grenade[id])
		return	
	
	give_item(id, "weapon_hegrenade")
	engclient_cmd(id, "weapon_knife")
}

public fw_SetModel(entity, const model[])
{
	// We don't care
	if (strlen(model) < 8)
		return FMRES_IGNORED;

	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	// Get attacker
	static attacker
	attacker = pev(entity, pev_owner)
	
	// Get whether grenade's owner is a zombie
	if (zb3_get_user_zombie(attacker))
	{
		if (model[9] == 'h' && model[10] == 'e') // Zombie Bomb
		{
			// Set grenade type on the thrown grenade entity
			set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_BLAST)
			engfunc(EngFunc_SetModel, entity, ZOMBIEBOM_W_MODEL)

			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if(dmgtime > get_gametime())
		return HAM_IGNORED
	
	// Check if it's one of our custom nades
	switch (pev(entity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_BLAST:
		{
			zombiebomb_explode(entity)
		}
		
		default: return HAM_IGNORED
	}
	
	return HAM_SUPERCEDE;	
}

stock zombiebomb_explode(ent)
{
	// Get origin
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	// Make the explosion
	EffectZombieBomExp(ent)
	
	engfunc(EngFunc_EmitSound, ent, CHAN_AUTO, ZOMBIEBOM_SOUND_EXP, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Collisions
	static victim
	victim = -1
	
	static const hit_sound[3][] =
	{
		"player/bhit_flesh-1.wav",
		"player/bhit_flesh-2.wav",
		"player/bhit_flesh-3.wav"
	}	
	
	new Float:fOrigin[3],Float:fDistance,Float:fDamage
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, ZOMBIEBOM_RADIUS)) != 0)
	{
		// Only effect alive non-spawnprotected humans
		if (!is_user_alive(victim))
			continue;
		
		// get value
		pev(victim, pev_origin, fOrigin)
		if(is_wall_between_points(originF, fOrigin, victim))
			continue		
		
		fDistance = get_distance_f(fOrigin, originF)
		fDamage = ZOMBIEBOM_POWER - floatmul(ZOMBIEBOM_POWER, floatdiv(fDistance, ZOMBIEBOM_RADIUS))//get the damage value
		fDamage *= estimate_take_hurt(originF, victim, 0)//adjust
		if (fDamage < 0)
			continue

		// create effect
		//manage_effect_action(victim, fOrigin, originF, fDistance, fDamage * 8.0)
		
		shake_screen(victim)
		
		/*
		if(is_in_viewcone(victim, originF, 1))
		{
			hook_ent2(victim, originF, ZOMBIEBOM_POWER, 2)
			client_print(victim, print_chat, "2")
		}
		else
		{*/
		hook_ent2(victim, originF, ZOMBIEBOM_POWER, 2)
		//}
		
		//ExecuteHamB(Ham_TakeDamage, victim, 0, victim, 0.0, DMG_BULLET)
		emit_sound(victim, CHAN_BODY, hit_sound[random(sizeof(hit_sound))], 1.0, ATTN_NORM, 0, PITCH_NORM)	
	
		continue;
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, ent)
}

stock EffectZombieBomExp(id)
{
	static Float:origin[3];
	pev(id,pev_origin,origin);

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(ZOMBIEBOM_IDSPRITES_EXP); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(30); // framerate
	write_byte(14); // flags 
	message_end(); // message end
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(ZOMBIEBOM_IDSPRITES_EXP); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(30); // framerate
	write_byte(14); // flags 
	message_end(); // message end
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(ZOMBIEBOM_IDSPRITES_EXP); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(30); // framerate
	write_byte(14); // flags 
	message_end(); // message end	
}

stock manage_effect_action(iEnt, Float:fEntOrigin[3], Float:fPoint[3], Float:fDistance, Float:fDamage)
{
	new Float:Velocity[3]
	pev(iEnt, pev_velocity, Velocity)
	
	new Float:fTime = floatdiv(fDistance, fDamage)
	new Float:fVelocity[3]
	fVelocity[0] = floatdiv((fEntOrigin[0] - fPoint[0]), fTime) + Velocity[0]*0.5
	fVelocity[1] = floatdiv((fEntOrigin[1] - fPoint[1]), fTime) + Velocity[1]*0.5
	fVelocity[2] = floatdiv((fEntOrigin[2] - fPoint[2]), fTime) + Velocity[2]*0.5
	set_pev(iEnt, pev_velocity, fVelocity)
	
	return 1
}

stock shake_screen(id)
{
	if(!is_user_connected(id))
		return
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"),{0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	new Float:fl_Time = distance_f / speed
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	set_pev(ent, pev_velocity, fl_Velocity)
}

stock Float:estimate_take_hurt(Float:fPoint[3], ent, ignored) 
{
	new Float:fOrigin[3]
	new tr
	new Float:fFraction
	pev(ent, pev_origin, fOrigin)
	engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, ignored, tr)
	get_tr2(tr, TR_flFraction, fFraction)
	if ( fFraction == 1.0 || get_tr2( tr, TR_pHit ) == ent ) //no valid enity between the explode point & player
		return 1.0
	return 0.6//if has fraise, lessen blast hurt
}

public event_CurWeapon(id)
{
	if (!is_user_alive(id)) return;
	
	new plrWeapId = get_user_weapon(id)
	if (plrWeapId == CSW_HEGRENADE && g_had_zombie_grenade[id])
	{
		if(zb3_get_user_zombie(id))
		{
			new model[64]
			if (zb3_get_user_level(id) > 1) ArrayGetString(model_origin, zb3_get_user_zombie_class(id), model, charsmax(model))
			else ArrayGetString(model_host, zb3_get_user_zombie_class(id), model, charsmax(model))
			
			set_pev(id, pev_viewmodel2, model)
			set_pev(id, pev_weaponmodel2, ZOMBIEBOM_P_MODEL)
		}
	}
}

// ================ Stock
stock bool:can_see_fm(entindex1, entindex2)
{
	if (!entindex1 || !entindex2)
		return false

	if (pev_valid(entindex1) && pev_valid(entindex1))
	{
		new flags = pev(entindex1, pev_flags)
		if (flags & EF_NODRAW || flags & FL_NOTARGET)
		{
			return false
		}

		new Float:lookerOrig[3]
		new Float:targetBaseOrig[3]
		new Float:targetOrig[3]
		new Float:temp[3]

		pev(entindex1, pev_origin, lookerOrig)
		pev(entindex1, pev_view_ofs, temp)
		lookerOrig[0] += temp[0]
		lookerOrig[1] += temp[1]
		lookerOrig[2] += temp[2]

		pev(entindex2, pev_origin, targetBaseOrig)
		pev(entindex2, pev_view_ofs, temp)
		targetOrig[0] = targetBaseOrig [0] + temp[0]
		targetOrig[1] = targetBaseOrig [1] + temp[1]
		targetOrig[2] = targetBaseOrig [2] + temp[2]

		engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the had of seen player
		if (get_tr2(0, TraceResult:TR_InOpen) && get_tr2(0, TraceResult:TR_InWater))
		{
			return false
		} 
		else 
		{
			new Float:flFraction
			get_tr2(0, TraceResult:TR_flFraction, flFraction)
			if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
			{
				return true
			}
			else
			{
				targetOrig[0] = targetBaseOrig [0]
				targetOrig[1] = targetBaseOrig [1]
				targetOrig[2] = targetBaseOrig [2]
				engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the body of seen player
				get_tr2(0, TraceResult:TR_flFraction, flFraction)
				if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
				{
					return true
				}
				else
				{
					targetOrig[0] = targetBaseOrig [0]
					targetOrig[1] = targetBaseOrig [1]
					targetOrig[2] = targetBaseOrig [2] - 17.0
					engfunc(EngFunc_TraceLine, lookerOrig, targetOrig, 0, entindex1, 0) //  checks the legs of seen player
					get_tr2(0, TraceResult:TR_flFraction, flFraction)
					if (flFraction == 1.0 || (get_tr2(0, TraceResult:TR_pHit) == entindex2))
					{
						return true
					}
				}
			}
		}
	}
	return false
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
} 
