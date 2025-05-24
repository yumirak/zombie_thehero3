#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <zombie_thehero2>

// Spawn Point Research
#define MAX_SPAWN_POINT 200

new Float:player_spawn_point[MAX_SPAWN_POINT][3]
new bool:player_spawn_point_used[MAX_SPAWN_POINT]
new player_spawn_point_count

public plugin_natives()
{
	register_native("zb3_get_player_spawn_cord" , "native_get_player_spawn_cord", 1)
	register_native("zb3_get_player_spawn_count","native_get_player_spawn_count",1)
	register_native("zb3_set_player_spawn_used","native_set_player_spawn_used",1)
	register_native("zb3_get_player_spawn_used","native_get_player_spawn_used",1)
}

public Float:native_get_player_spawn_cord( num, type )
{
	if( type < 0 || type > 2 || num > player_spawn_point_count )
	{
		log_error(AMX_ERR_NATIVE, "[ZB3] get random spawn cord invalid.")
		return 0.0;
	}

	return player_spawn_point[num][type]
}
public native_get_player_spawn_count()
{
	return player_spawn_point_count
}
public bool:native_set_player_spawn_used( num, bool:status )
{
	player_spawn_point_used[num] = status
}
public bool:native_get_player_spawn_used( num )
{
	return player_spawn_point_used[num]
}

public zb3_game_end() reset_spawn()
public zb3_game_start() reset_spawn()

public reset_spawn()
{
	for (new i = 1; i < player_spawn_point_count; i++)
		player_spawn_point_used[i] = false
}

public plugin_cfg()
{
	research_map()
}

// Zombie Plague
public research_map()
{
	new cfgdir[32], mapname[32], filepath[100], linedata[64]
	get_configsdir(cfgdir, charsmax(cfgdir))
	get_mapname(mapname, charsmax(mapname))
	formatex(filepath, charsmax(filepath), "%s/%s/csdm/%s.spawns.cfg", cfgdir, GAMESYSTEMNAME , mapname)

	// Use regamedll 'info_spawn_point'
	if( fm_find_ent_by_class(-1, "info_spawn_point") )
	{
		collect_spawns_ent("info_spawn_point")
		return
	}
	// Load CSDM spawns if present
	else if (file_exists(filepath))
	{
		new csdmdata[3][6], file = fopen(filepath,"rt")

		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata))

			// invalid spawn
			if(!linedata[0] || str_count(linedata,' ') < 2) continue;

			// get spawn point data
			parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5)

			// origin
			player_spawn_point[player_spawn_point_count][0] = floatstr(csdmdata[0])
			player_spawn_point[player_spawn_point_count][1] = floatstr(csdmdata[1])
			player_spawn_point[player_spawn_point_count][2] = floatstr(csdmdata[2])
			player_spawn_point_used[player_spawn_point_count] = false

			// increase spawn count
			player_spawn_point_count++
			//g_spawnCount++
			if (player_spawn_point_count >= sizeof player_spawn_point) break;
		}
		if (file) fclose(file)
	}
	else
	{
		// Collect regular spawns
		collect_spawns_ent("info_player_start")
		collect_spawns_ent("info_player_deathmatch")
	}
}
// Collect spawn points from entity origins
stock collect_spawns_ent(const classname[])
{
	static player
	while((player = engfunc(EngFunc_FindEntityByString, player, "classname", classname)) != 0)
    {
		if(!pev_valid(player))
			continue

		pev(player, pev_origin, player_spawn_point[player_spawn_point_count])
		player_spawn_point_used[player_spawn_point_count] = false

		// increase spawn count
		player_spawn_point_count++
		if (player_spawn_point_count >= sizeof player_spawn_point) break;
	}
}
// Stock by (probably) Twilight Suzuka -counts number of chars in a string
stock str_count(const str[], searchchar)
{
    new count, i, len = strlen(str)

    for (i = 0; i <= len; i++)
    {
        if(str[i] == searchchar)
            count++
    }

    return count;
}
