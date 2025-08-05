#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>
#include <zombie_thehero2>

#define PLUGIN "[Zombie: The Hero] Human Item"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define DELAY_TIME 2.0
new const LANG_FILE[] = "zombie_thehero2.txt"
new const SETTING_FILE[] = "items.ini"

/// ===== Configs
new g_sync_hud1, g_sync_hud2
new Float:g_hud_delay[33]
new g_register, g_zombie_appear

// Wing Boot
new g_wing_boot, g_wing_boot_name[24], g_wing_boot_desc[24]
new g_wb_cost, Float:g_wb_gravity
// Double Grenade
new g_double_grenade, g_double_grenade_name[24], g_double_grenade_desc[24], g_dg_cost, g_doubled_grenade[33]

// Sprint
new g_sprint, g_sprint_name[24], g_sprint_desc[24], g_sprint_cost, Float:fastrun_time[2], Float:fastrun_speed[2]
new g_can_use_sprint[33], g_using_sprint[33], g_sprint_status[33]
new sound_fastrun_start[64], sound_fastrun_heartbeat[64], sound_breath_male[64], sound_breath_female[64]

enum (+= 50)
{
	TASK_REMOVE_DEADLYSHOT = 12000,
	TASK_REMOVE_BLOODYBLADE, 
	TASK_REMOVE_FASTRUN,
	TASK_REMOVE_SLOWRUN,
	TASK_HUMAN_SOUND,
}

// +30% Damage
new g_p30_damage, g_p30_damage_name[24], g_p30_damage_desc[24], g_p30_cost

// Deadly Shot
new g_deadlyshot, g_deadlyshot_name[24], g_deadlyshot_desc[24], g_can_use_deadlyshot[33], g_using_deadlyshot[33]
new g_deadlyshot_cost, Float:g_deadlyshot_time, g_deadlyshot_icon[64], g_deadlyshot_sound[64]

// Bloody Blade
new g_bloodyblade, g_bloodyblade_name[24], g_bloodyblade_desc[24], g_can_use_bloodyblade[33], g_using_bloodyblade[33]
new g_bloodyblade_cost, Float:g_bloodyblade_time, Float:g_bloodyblade_damage, g_bloodyblade_icon[64], g_bloodyblade_sound[64]


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_sync_hud1 = zb3_get_synchud_id(SYNCHUD_HUMANZOMBIE_ITEM)
	g_sync_hud2 = zb3_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	
	RegisterHam(Ham_Item_AddToPlayer, "weapon_hegrenade", "fw_Add_Hegrenade_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")

	register_clcmd("sp", "do_fastrun")
	register_clcmd("ds", "do_deadlyshot")
	register_clcmd("bb", "do_bloodyblade")

	register_clcmd("sprint", "do_fastrun")
	register_clcmd("deadlyshot", "do_deadlyshot")
	register_clcmd("bloodyblade", "do_bloodyblade")

	register_clcmd("use_sprint", "do_fastrun")
	register_clcmd("use_deadlyshot", "do_deadlyshot")
	register_clcmd("use_bloodyblade", "do_bloodyblade")
}

public load_cfg()
{
	static buffer[128], Array:DummyArray

	formatex(g_sprint_name, charsmax(g_sprint_name), "%L", LANG_SERVER, "ITEM_SPRINT_NAME")
	formatex(g_sprint_desc, charsmax(g_sprint_desc), "%L", LANG_SERVER, "ITEM_SPRINT_DESC")

	formatex(g_deadlyshot_name, charsmax(g_deadlyshot_name), "%L", LANG_SERVER, "ITEM_DS_NAME")
	formatex(g_deadlyshot_desc, charsmax(g_deadlyshot_desc), "%L", LANG_SERVER, "ITEM_DS_DESC")

	formatex(g_bloodyblade_name, charsmax(g_bloodyblade_name), "%L", LANG_SERVER, "ITEM_BB_NAME")
	formatex(g_bloodyblade_desc, charsmax(g_bloodyblade_desc), "%L", LANG_SERVER, "ITEM_BB_DESC")

	formatex(g_wing_boot_name, charsmax(g_wing_boot_name), "%L", LANG_SERVER, "ITEM_WB_NAME")
	formatex(g_wing_boot_desc, charsmax(g_wing_boot_desc), "%L", LANG_SERVER, "ITEM_WB_DESC")

	formatex(g_double_grenade_name, charsmax(g_double_grenade_name), "%L", LANG_SERVER, "ITEM_DG_NAME")
	formatex(g_double_grenade_desc, charsmax(g_double_grenade_desc), "%L", LANG_SERVER, "ITEM_DG_DESC")

	formatex(g_p30_damage_name, charsmax(g_p30_damage_name), "%L", LANG_SERVER, "ITEM_DMG_NAME")
	formatex(g_p30_damage_desc, charsmax(g_p30_damage_desc), "%L", LANG_SERVER, "ITEM_DMG_DESC")

	zb3_load_setting_string(false, SETTING_FILE, "Sprint", "COST", buffer, sizeof(buffer), DummyArray); g_sprint_cost = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Sprint", "FASTRUN_SPEED", buffer, sizeof(buffer), DummyArray); fastrun_speed[0] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Sprint", "FASTRUN_TIME", buffer, sizeof(buffer), DummyArray); fastrun_time[0] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Sprint", "SLOWRUN_SPEED", buffer, sizeof(buffer), DummyArray); fastrun_speed[1] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Sprint", "SLOWRUN_TIME", buffer, sizeof(buffer), DummyArray); fastrun_time[1] = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Sprint", "SOUND_CAST", sound_fastrun_start, sizeof(sound_fastrun_start), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, "Sprint", "SOUND_BEAT", sound_fastrun_heartbeat, sizeof(sound_fastrun_heartbeat), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, "Sprint", "SOUND_BREATH_MALE", sound_breath_male, sizeof(sound_breath_male), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, "Sprint", "SOUND_BREATH_FEMALE", sound_breath_female, sizeof(sound_breath_female), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, "Deadly Shot", "COST", buffer, sizeof(buffer), DummyArray); g_deadlyshot_cost = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Deadly Shot", "TIME", buffer, sizeof(buffer), DummyArray); g_deadlyshot_time = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Deadly Shot", "ICON", g_deadlyshot_icon, sizeof(g_deadlyshot_icon), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, "Deadly Shot", "SOUND_CAST", g_deadlyshot_sound, sizeof(g_deadlyshot_sound), DummyArray);
	

	zb3_load_setting_string(false, SETTING_FILE, "Bloody Blade", "COST", buffer, sizeof(buffer), DummyArray); g_bloodyblade_cost = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Bloody Blade", "TIME", buffer, sizeof(buffer), DummyArray); g_bloodyblade_time = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Bloody Blade", "DAMAGE", buffer, sizeof(buffer), DummyArray); g_bloodyblade_damage = str_to_float(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Bloody Blade", "ICON", g_bloodyblade_icon, sizeof(g_bloodyblade_icon), DummyArray);
	zb3_load_setting_string(false, SETTING_FILE, "Bloody Blade", "SOUND_CAST", g_bloodyblade_sound, sizeof(g_bloodyblade_sound), DummyArray);

	zb3_load_setting_string(false, SETTING_FILE, "Gravity", "COST", buffer, sizeof(buffer), DummyArray); g_wb_cost = str_to_num(buffer)
	zb3_load_setting_string(false, SETTING_FILE, "Gravity", "GRAVITY", buffer, sizeof(buffer), DummyArray); g_wb_gravity = str_to_float(buffer)

	zb3_load_setting_string(false, SETTING_FILE, "Grenade", "COST", buffer, sizeof(buffer), DummyArray); g_dg_cost = str_to_num(buffer)

	zb3_load_setting_string(false, SETTING_FILE, "Damage 30%", "COST", buffer, sizeof(buffer), DummyArray); g_p30_cost = str_to_num(buffer)
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)

	load_cfg()

	precache_sound(sound_fastrun_start)
	precache_sound(sound_fastrun_heartbeat)
	precache_sound(sound_breath_male)
	precache_sound(sound_breath_female)

	precache_sound(g_deadlyshot_sound)
	precache_sound(g_bloodyblade_sound)
	
	precache_model(g_deadlyshot_icon)
	precache_model(g_bloodyblade_icon)
	
	if(zb3_get_mode() >= MODE_ORIGINAL)
		g_wing_boot = zb3_register_item(g_wing_boot_name, g_wing_boot_desc, g_wb_cost, TEAM2_HUMAN, 1)

	if(zb3_get_mode() >= MODE_MUTATION) 
	{
		g_double_grenade = zb3_register_item(g_double_grenade_name, g_double_grenade_desc, g_dg_cost, TEAM2_HUMAN, 1)
		g_sprint = zb3_register_item(g_sprint_name, g_sprint_desc, g_sprint_cost, TEAM2_HUMAN, 1)
		g_deadlyshot = zb3_register_item(g_deadlyshot_name, g_deadlyshot_desc, g_deadlyshot_cost, TEAM2_HUMAN, 1)
		g_bloodyblade = zb3_register_item(g_bloodyblade_name, g_bloodyblade_desc, g_bloodyblade_cost, TEAM2_HUMAN, 1)
	}
	
	if(zb3_get_mode() >= MODE_HERO)
		g_p30_damage = zb3_register_item(g_p30_damage_name, g_p30_damage_desc, g_p30_cost, TEAM2_HUMAN, 1)
	
}

public client_connect(id)
{

	g_can_use_sprint[id] = 0
	g_using_sprint[id] = 0
	g_sprint_status[id] = 0
	
	g_can_use_deadlyshot[id] = 0
	g_using_deadlyshot[id] = 0

	g_can_use_bloodyblade[id] = 0
	g_using_bloodyblade[id] = 0
}

public client_putinserver(id)
{
	#if 0
	if(is_user_bot(id) && !g_register)
	{
		g_register = 1
		set_task(0.1, "do_register", id)
	}
	#endif
}

#if 0
public do_register(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}
#endif

public zb3_item_selected_post(id, itemid)
{
	if(itemid == g_wing_boot) {
		set_wing_boot(id)
	} else if(itemid == g_double_grenade) {
		set_double_grenade(id)
	} else if(itemid == g_p30_damage) {
		set_p30_damage(id)
	} else if(itemid == g_sprint) {
		set_user_item_sprint(id)
	} else if(itemid == g_deadlyshot) {
		set_user_deadlyshot(id)
	} else if(itemid == g_bloodyblade) {
		set_user_bloodyblade(id)
	}
}

public zb3_game_start(start_type) 
{
	if(start_type == 0) g_zombie_appear = 0
	else if(start_type == 2) g_zombie_appear = 1
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return
		
	static Float:CurTime
	CurTime = get_gametime()
	
	if(CurTime - DELAY_TIME > g_hud_delay[id])
	{
		sync_hud1_handle(id)
		
		g_hud_delay[id] = CurTime
	}
	
	if(g_using_sprint[id])
	{
		if(pev(id, pev_maxspeed) != fastrun_speed[g_sprint_status[id] - 1]) zb3_set_user_speed(id, floatround(fastrun_speed[g_sprint_status[id] - 1]))
	}
}

public sync_hud1_handle(id)
{
	if(is_user_bot(id))
		return

	static Temp_String[32], Temp_String_Hud[128]
	Temp_String[0] = Temp_String_Hud[0] = '^0'
	
	if(g_can_use_sprint[id])
	{
		formatex(Temp_String, sizeof(Temp_String), "%L", LANG_SERVER, "ITEM_SPRINT_NAME")
		strcat(Temp_String_Hud, Temp_String, sizeof(Temp_String_Hud))
	}

	if(g_can_use_deadlyshot[id])
	{
		formatex(Temp_String, sizeof(Temp_String), "^n%L", LANG_SERVER, "ITEM_DS_NAME")
		strcat(Temp_String_Hud, Temp_String, sizeof(Temp_String_Hud))
	}

	if(g_can_use_bloodyblade[id])
	{
		formatex(Temp_String, sizeof(Temp_String), "^n%L", LANG_SERVER, "ITEM_BB_NAME")
		strcat(Temp_String_Hud, Temp_String, sizeof(Temp_String_Hud))
	}
	
	set_hudmessage(255, 255, 255, -1.0, 0.10, 0, 0.0, 2.1)
	ShowSyncHudMsg(id, g_sync_hud2, Temp_String_Hud)
}

public zb3_user_spawned(id)
{
	if(!is_user_connected(id))
		return
		
	reset_all_item(id)
	set_wing_boot(id)
	set_double_grenade(id)
	set_user_item_sprint(id)
	set_p30_damage(id)
	set_user_deadlyshot(id)
	set_user_bloodyblade(id)
	
	return
}

public zb3_user_infected(id)
{
	reset_all_item(id)
}

public reset_all_item(id)
{
	g_can_use_sprint[id] = 0
	g_using_sprint[id] = 0
	g_sprint_status[id] = 0
	g_can_use_deadlyshot[id] = 0
	g_using_deadlyshot[id] = 0	
	g_can_use_bloodyblade[id] = 0
	g_using_bloodyblade[id] = 0
}
// =========== Item: Wing Boot
public set_wing_boot(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!zb3_get_own_item(id, g_wing_boot))
	{
		zb3_reset_user_gravity(id)
		return
	}

	zb3_set_user_gravity(id, g_wb_gravity);
}

// =========== Item: Double Grenade
public fw_Add_Hegrenade_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(zb3_get_user_zombie(id))
		return HAM_IGNORED			
		
	if(!g_doubled_grenade[id])
		set_double_grenade(id)
		
	return HAM_HANDLED
}

public set_double_grenade(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!zb3_get_own_item(id, g_double_grenade))
		return
		
	g_doubled_grenade[id] = 1
	rg_give_item(id, "weapon_hegrenade")
	
	rg_set_user_bpammo(id, WEAPON_HEGRENADE, 2)
}

// ============ Item: Sprint
public set_user_item_sprint(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!zb3_get_own_item(id, g_sprint))
		return	
		
	g_can_use_sprint[id] = 1
	g_using_sprint[id] = 0
	g_sprint_status[id] = 0

	remove_task(id+TASK_REMOVE_FASTRUN)
	remove_task(id+TASK_REMOVE_SLOWRUN)
	
	client_print(id, print_chat, "'bind <key> sp' to use Sprint")
	// client_cmd(id, "bind F1 fastrun")
}

public do_fastrun(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_zombie_appear)
		return
	
	if(g_can_use_sprint[id] && !g_using_sprint[id])
	{
		g_can_use_sprint[id] = 0
		g_using_sprint[id] = 1
		g_sprint_status[id] = 1
		
		remove_task(id+TASK_REMOVE_FASTRUN)
		set_task(fastrun_time[0], "task_remove_fastrun", id+TASK_REMOVE_FASTRUN)
		
		zb3_set_user_speed(id, floatround(fastrun_speed[0]))
		
		emit_sound(id, CHAN_AUTO, sound_fastrun_start, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		set_task(1.0, "task_human_sound", id+TASK_HUMAN_SOUND, _, _, "b")
	}
}

public task_human_sound(id)
{
	id -= TASK_HUMAN_SOUND
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return			
	}
	if(!zb3_get_own_item(id, g_sprint))
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!g_using_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return
	}
	
	if (g_sprint_status[id] == 1)
	{
		emit_sound(id, CHAN_VOICE, sound_fastrun_heartbeat, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	else if (g_sprint_status[id] == 2)
	{
		static Sex
		Sex = zb3_get_user_sex(id)

		emit_sound(id, CHAN_VOICE, Sex == SEX_MALE ? sound_breath_male : sound_breath_female, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public task_remove_fastrun(id)
{
	id -= TASK_REMOVE_FASTRUN
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!zb3_get_own_item(id, g_sprint))
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!g_using_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return
	}	
	
	g_sprint_status[id] = 2
	
	remove_task(id+TASK_REMOVE_SLOWRUN)
	set_task(fastrun_time[1], "task_remove_slowrun", id+TASK_REMOVE_SLOWRUN)
	
	zb3_reset_user_speed(id)
	zb3_set_user_speed(id, floatround(fastrun_speed[1]))
}

public task_remove_slowrun(id)
{
	id -= TASK_REMOVE_SLOWRUN
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!zb3_get_own_item(id, g_sprint))
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return		
	}
	if(!g_using_sprint[id])
	{
		remove_task(id+TASK_HUMAN_SOUND)
		return
	}	
	
	g_sprint_status[id] = 0
	g_using_sprint[id] = 0
	
	zb3_reset_user_speed(id)
}

// ============ Item: +30% Damage
public set_p30_damage(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!zb3_get_own_item(id, g_p30_damage))
	{
		zb3_reset_user_maxlevel(id)
		return	
	}
		
	zb3_set_user_maxlevel(id, 13)
	zb3_set_user_level(id, zb3_get_user_level(id) + 3)
}

// =============== Item: Deadly Shot
public set_user_deadlyshot(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!zb3_get_own_item(id, g_deadlyshot))
		return	
		
	g_can_use_deadlyshot[id] = 1
	g_using_deadlyshot[id] = 0

	remove_task(id+TASK_REMOVE_DEADLYSHOT)
	client_print(id, print_chat, "'bind <key> ds' to use Deadly Shot")
	// client_cmd(id, "bind F2 use_deadlyshot")	
}

public do_deadlyshot(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_zombie_appear)
		return		
	
	if(g_can_use_deadlyshot[id] && !g_using_deadlyshot[id])
	{
		g_can_use_deadlyshot[id] = 0
		g_using_deadlyshot[id] = 1
		
		zb3_set_head_attachment(id, g_deadlyshot_icon, g_deadlyshot_time, 1.0, 1.0, 0)
		emit_sound(id, CHAN_AUTO, g_deadlyshot_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		remove_task(id+TASK_REMOVE_DEADLYSHOT)
		set_task(g_deadlyshot_time, "task_remove_headshot", id+TASK_REMOVE_DEADLYSHOT)
	}
}

public task_remove_headshot(id)
{
	id -= TASK_REMOVE_DEADLYSHOT
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!zb3_get_own_item(id, g_deadlyshot))
		return
	if(g_can_use_deadlyshot[id])
		return		
		
	g_can_use_deadlyshot[id] = 0
	g_using_deadlyshot[id] = 0
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || !is_user_alive(attacker) || !is_user_alive(victim))
		return HAM_IGNORED;
		
	if(g_using_bloodyblade[attacker] && get_user_weapon(attacker) == CSW_KNIFE)
		SetHamParamFloat(3, damage * g_bloodyblade_damage)
	if(g_using_deadlyshot[attacker] && get_user_weapon(attacker) != CSW_KNIFE)
		set_tr2(tracehandle, TR_iHitgroup, HIT_HEAD)
	
	return HAM_IGNORED
}

// ================ Skill: Bloody Blade
public set_user_bloodyblade(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!zb3_get_own_item(id, g_bloodyblade))
		return	
		
	g_can_use_bloodyblade[id] = 1
	g_using_bloodyblade[id] = 0
	
	remove_task(id+TASK_REMOVE_BLOODYBLADE)

	client_print(id, print_chat, "'bind <key> bb' to use Bloody Blade")
	// client_cmd(id, "bind F3 use_bloodyblade")		
}

public do_bloodyblade(id)
{
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return	
	if(!g_zombie_appear)
		return		
	
	if(g_can_use_bloodyblade[id] && !g_using_bloodyblade[id])
	{
		g_can_use_bloodyblade[id] = 0
		g_using_bloodyblade[id] = 1
		zb3_set_head_attachment(id, g_bloodyblade_icon, g_bloodyblade_time, 1.0, 1.0, 0)
		
		emit_sound(id, CHAN_AUTO, g_bloodyblade_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)

		remove_task(id+TASK_REMOVE_BLOODYBLADE)
		set_task(g_bloodyblade_time, "task_remove_bloodyblade", id+TASK_REMOVE_BLOODYBLADE)
	}
}

public task_remove_bloodyblade(id)
{
	id -= TASK_REMOVE_BLOODYBLADE
	
	if(!is_user_alive(id))
		return
	if(zb3_get_user_zombie(id))
		return			
	if(!zb3_get_own_item(id, g_bloodyblade))
		return	
	if(g_can_use_bloodyblade[id])
		return	

	g_can_use_bloodyblade[id] = 0
	g_using_bloodyblade[id] = 0
}
