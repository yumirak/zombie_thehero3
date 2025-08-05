#include <amxmodx>
#include <reapi>
#include <xs>
#include <fakemeta_util>
#include <engine>
#define MSGFUNCWEAPONLIST
#define GUNSHOTDECALTRACE
#define CREATESMOKE
#define EJECTBRASS
#include <zb3_wpn_stock>
#include <zombie_thehero2>

#define ID_CUSWPN 1678942
#define STRN_BASEWPN "weapon_ak47"
#define STRN_CUSWPN "weapon_svdex"
#define DAMAGE_CUSWPN 404.0
#define CLIP_CUSWPN 20
#define ROF_CUSWPN 0.4
#define RECOIL_CUSWPN 0.6
#define ACCURACY_CUSWPN 0.5
#define MAXAMMO_CUSWPN 240

#define RELOAD_TIME 3.8

#define SWITCH_TIME 2.0

#define GRENADE_CLASSNAME "svdex_grenade"
#define GRENADE_MAXAMMO 10
#define GRENADE_DAMAGE 1000.0
#define GRENADE_RADIUS 192.0
#define GRENADE_RELOAD	3.0
#define GRENADE_AMMOID 1
#define GRENADE_VELOCITY 1800

#define GRENADE_MAX GRENADE_MAXAMMO

new const WeaponModel[][] = 
{
	"models/zombi/hero_wpn/v_svdex.mdl",
	"models/zombi/hero_wpn/p_svdex.mdl",
	"models/zombi/hero_wpn/w_svdex.mdl",
	"models/zombi/hero_wpn/shell_svdex.mdl",
}

new const WeaponSounds[][] = 
{
	"weapons/svdex-1.wav",
	"weapons/svdex-2.wav"
}

new const WeaponSprites[][] = 
{
	"sprites/laserbeam.spr",
	"sprites/zerogxplode.spr",
	"sprites/steam1.spr"
}

new const WeaponGeneric[][] = 
{
	"sprites/640hud7_2.spr",
	"sprites/640hud36_2.spr",
	"sprites/640hud41_2.spr",
	"sprites/weapon_svdex.txt",
	"sound/weapons/svdex_clipin.wav",
	"sound/weapons/svdex_clipout.wav",
	"sound/weapons/svdex_clipon.wav",
	"sound/weapons/svdex_draw.wav",
	"sound/weapons/svdex_foley1.wav",
	"sound/weapons/svdex_foley2.wav",
	"sound/weapons/svdex_foley3.wav",
	"sound/weapons/svdex_foley4.wav"
}

enum
{
	MODEL_VIEW,
	MODEL_PLAYER,
	MODEL_WORLD,
	MODEL_SHELL
}

enum 
{
	SPRITE_LASER,
	SPRITE_EXPLO,
	SPRITE_STEAM
}

enum
{	
	ANIM_IDLE,
	ANIM_SHOOT,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_GREN_IDLE,
	ANIM_GREN_SHOOT1,
	ANIM_GREN_SHOOT2,
	ANIM_GREN_DRAW,
	ANIM_MOVE_TO_GREN,
	ANIM_MOVE_TO_CARBINE
};

new i, pPlayer, pEntity, iSprite[sizeof(WeaponSprites)]

public plugin_precache()
{
	for(i=0;i< sizeof WeaponSounds;i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	for(i=0;i< sizeof WeaponSprites;i++)
		iSprite[i] = engfunc(EngFunc_PrecacheModel, WeaponSprites[i])
	for(i=0;i< sizeof WeaponModel;i++)
		engfunc(EngFunc_PrecacheModel, WeaponModel[i])
	for(i=0;i< sizeof WeaponGeneric;i++)
		engfunc(EngFunc_PrecacheGeneric, WeaponGeneric[i])
}

public plugin_init()
{
	register_plugin("SVDEX", "", "406")

	RegisterHam(Ham_Weapon_PrimaryAttack, STRN_BASEWPN, "Fw_Ham_Weapon_PrimaryAttack")
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "Fw_RG_CBasePlayer_AddPlayerItem", 1)
	RegisterHookChain(RG_CBasePlayer_RemovePlayerItem, "Fw_RG_CBasePlayer_RemovePlayerItem", 1)

	register_forward(FM_UpdateClientData, "Fw_FM_UpdateClientData_Post", 1)
	register_touch(GRENADE_CLASSNAME, "*", "fw_GrenadeTouch");

	RegisterHookChain(RG_CBasePlayerWeapon_DefaultReload, "Fw_RG_CBasePlayerWeapon_DefaultReload")
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "Fw_RG_CBasePlayerWeapon_DefaultDeploy")
	RegisterHookChain(RG_CBasePlayerWeapon_ItemPostFrame, "Fw_RG_CBasePlayerWeapon_ItemPostFrame")
	RegisterHookChain(RG_CWeaponBox_SetModel, "Fw_RG_CWeaponBox_SetModel")

	// register_clcmd("svdex", "give")

	register_clcmd(STRN_CUSWPN, "lastinv")
}

public zb3_user_become_hero(id, hero_type)
{
	if(hero_type == HERO_ANDREY) give(id);
}

public zb3_supply_refill_ammo(id)
{
	static ent;

	if(!rg_find_ent_by_owner(ent, STRN_BASEWPN, id))
		return
	if(!is_custom(ent, ID_CUSWPN))
		return;

	zb3_give_user_ammo(id, ent)
	set_member(ent, m_Weapon_iGlock18ShotsFired, GRENADE_MAXAMMO);
	SetExtraAmmo(id, GRENADE_AMMOID, get_member(ent, m_Weapon_iGlock18ShotsFired))
}

public give(player)
{
	if(!is_user_alive(player)) 
		return

	pEntity = rg_give_custom_item(player, STRN_BASEWPN, GT_DROP_AND_REPLACE, ID_CUSWPN)

	if(!is_entity(pEntity)) return	

	set_member(pEntity, m_Weapon_iClip, CLIP_CUSWPN)
	set_member(pEntity, m_Weapon_flBaseDamage, DAMAGE_CUSWPN);
	set_member(pEntity, m_Weapon_iGlock18ShotsFired, GRENADE_MAXAMMO);
	rg_set_iteminfo(pEntity, ItemInfo_iMaxClip, CLIP_CUSWPN)
	rg_set_iteminfo(pEntity, ItemInfo_iMaxAmmo1, MAXAMMO_CUSWPN)
	zb3_give_user_ammo(player, pEntity)

	static Float:vuser4[3]
	vuser4[0] = 510.0;
	vuser4[1] = 0.65;
	vuser4[2] = 0.0;
	set_entvar(pEntity, var_vuser4, vuser4)
}

public Fw_RG_CBasePlayer_AddPlayerItem(player, entity)
{
	if(!is_custom(entity, ID_CUSWPN))
		return HC_CONTINUE;

	MsgFunc_WeaponList(player, entity, STRN_CUSWPN, GRENADE_AMMOID, GRENADE_MAXAMMO)
	return HC_CONTINUE;
}
public Fw_RG_CBasePlayer_RemovePlayerItem(player, entity)
{
	if(!is_custom(entity, ID_CUSWPN))
		return HC_CONTINUE;

	MsgFunc_WeaponList(player, entity, STRN_BASEWPN)
	return HC_CONTINUE;
}

public Fw_RG_CBasePlayerWeapon_ItemPostFrame(const this)
{
	if(get_entvar(this, var_impulse) != ID_CUSWPN) return

	static iButton, bMode;
	pPlayer = get_member(this, m_pPlayer);
	iButton = get_entvar(pPlayer, var_button);

	if(!(iButton & IN_ATTACK2)) return

	bMode = get_member(this, m_Weapon_bSecondarySilencerOn)
	// Call secondary attack
	if (iButton & IN_ATTACK2 && get_member(this, m_Weapon_flNextSecondaryAttack) < 0.0) 
	{
		set_entvar(pPlayer, var_button, iButton & ~IN_ATTACK2);
		rg_weapon_send_animation(this, bMode ? ANIM_MOVE_TO_CARBINE : ANIM_MOVE_TO_GREN)

		set_member(this, m_Weapon_bSecondarySilencerOn, bMode ? false : true)
		set_member(this, m_Weapon_flTimeWeaponIdle, SWITCH_TIME + (bMode ? 1.0 : 9999.0))
		set_member(this, m_Weapon_flNextPrimaryAttack, SWITCH_TIME + 0.1)
		set_member(this, m_Weapon_flNextSecondaryAttack, SWITCH_TIME + 0.1)

	}
}

public Fw_RG_CBasePlayerWeapon_DefaultReload(const this, iClipSize, iAnim, Float:fDelay)
{
	if(get_entvar(this, var_impulse) != ID_CUSWPN) return

	SetHookChainArg( 2, ATYPE_INTEGER, CLIP_CUSWPN)
	SetHookChainArg( 3, ATYPE_INTEGER, ANIM_RELOAD)
	SetHookChainArg( 4, ATYPE_FLOAT, RELOAD_TIME)

	pPlayer = get_member(this, m_pPlayer);
	set_member(pPlayer, m_iFOV, DEFAULT_NO_ZOOM);
}

public Fw_RG_CBasePlayerWeapon_DefaultDeploy(const entity, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal)
{
	if(!is_custom(entity, ID_CUSWPN)) 
		return
	
	SetHookChainArg( 2, ATYPE_STRING, WeaponModel[MODEL_VIEW])
	SetHookChainArg( 3, ATYPE_STRING, WeaponModel[MODEL_PLAYER])
	SetHookChainArg( 4, ATYPE_INTEGER, ANIM_DRAW)

	set_member(entity, m_Weapon_bSecondarySilencerOn, false)

	pPlayer = get_member(entity, m_pPlayer);
	SetExtraAmmo(pPlayer, GRENADE_AMMOID, get_member(entity, m_Weapon_iGlock18ShotsFired))
}

public Fw_RG_CWeaponBox_SetModel(entity, const szModelName[])
{
	static iEntID, iEntSlot

	iEntID = rg_get_weapon_info(STRN_BASEWPN, WI_ID);
	iEntSlot = rg_get_weapon_info(iEntID, WI_SLOT);
	pEntity = get_member(entity, m_WeaponBox_rgpPlayerItems, iEntSlot)

	if(is_entity(pEntity) && get_entvar(pEntity, var_impulse) == ID_CUSWPN)
		SetHookChainArg(2, ATYPE_STRING, WeaponModel[MODEL_WORLD])
}

public Fw_Ham_Weapon_PrimaryAttack(entity)
{
	if(!is_custom(entity, ID_CUSWPN)) return HAM_IGNORED

	static iClip, iTraceLine, iPlaybackEvent, bool:bMode, Float:vPunch[3]

	bMode = get_member(entity, m_Weapon_bSecondarySilencerOn)
	pPlayer = get_member(entity, m_pPlayer)

	switch(bMode)
	{
		case true: 
		{
			if(!get_member(pEntity, m_Weapon_iGlock18ShotsFired))
				return HAM_SUPERCEDE

			Create_Grenade(pPlayer, entity)
		}
		case false:
		{
			iClip = get_member(entity, m_Weapon_iClip)
			if(!iClip) return HAM_IGNORED

			iTraceLine = register_forward(FM_TraceLine, "Fw_FM_TraceLine_Post", 1)
			iPlaybackEvent = register_forward(FM_PlaybackEvent, "Fw_FM_PlaybackEvent")
			ExecuteHam(Ham_Weapon_PrimaryAttack, entity)
			unregister_forward(FM_TraceLine, iTraceLine, 1)
			unregister_forward(FM_PlaybackEvent, iPlaybackEvent)
		}
	}
	
	set_member(entity, m_Weapon_flTimeWeaponIdle, (bMode ? 9999.0 : 1.0 ))
	set_member(entity, m_Weapon_flNextPrimaryAttack, bMode ? GRENADE_RELOAD : ROF_CUSWPN);
	set_member(entity, m_Weapon_flAccuracy, ACCURACY_CUSWPN);

	get_entvar(pPlayer, var_punchangle, vPunch)
	xs_vec_mul_scalar(vPunch, RECOIL_CUSWPN, vPunch);
	set_entvar(pPlayer, var_punchangle, vPunch)
	
	emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[bMode], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	rg_weapon_send_animation(pPlayer, bMode ? ANIM_GREN_SHOOT1 : ANIM_SHOOT)
	rg_set_animation(pPlayer, PLAYER_ATTACK1);
	EjectBrass(pPlayer, get_member(entity, m_AK47_iShell), 1);

	return HAM_SUPERCEDE
}

public Fw_FM_TraceLine_Post(Float:vecStart[3], Float:vecEnd[3], noMonsters, pentToSkip, iTrace)
{
	if(noMonsters) return
	if(!GunshotDecalTrace(iTrace, true)) return
	get_tr2(iTrace, TR_vecEndPos, vecEnd)
	get_tr2(iTrace, TR_vecPlaneNormal, vecStart)
	CreateSmoke(SMOKE_WALLPUFF, vecEnd, vecStart, 0.5, Float:{40.0, 40.0, 40.0})
}

public Fw_FM_UpdateClientData_Post(player, sendWeapons, cd)
{
	if (!is_user_alive(player))
		return FMRES_IGNORED;
	
	pEntity = get_member(player, m_pActiveItem)
	
	if (!is_entity(pEntity) || get_entvar(pEntity, var_impulse) != ID_CUSWPN)
		return FMRES_IGNORED;
	
	set_cd(cd, CD_flNextAttack, get_gametime() + 0.001);
	return FMRES_IGNORED;
}
public Fw_FM_PlaybackEvent() return FMRES_SUPERCEDE
public lastinv(player) engclient_cmd(player, STRN_BASEWPN)


// GRENADE ENTITY
public Create_Grenade(id, wpn_ent)
{
	static Ent; 
	Ent = rg_create_entity("info_target")
	if(!is_entity(Ent)) 
		return;
	
	static Float:Origin[3], Float:Angles[3];
	
	get_entvar(id, var_origin, Origin);
	get_entvar(id, var_angles, Angles);
	
	set_entvar(Ent, var_movetype, MOVETYPE_PUSHSTEP);
	set_entvar(Ent, var_solid, SOLID_BBOX);
	
	set_entvar(Ent, var_classname, GRENADE_CLASSNAME);
	engfunc(EngFunc_SetModel, Ent, WeaponModel[MODEL_SHELL]);
	set_entvar(Ent, var_origin, Origin);
	set_entvar(Ent, var_angles, Angles);
	set_entvar(Ent, var_owner, id);
	set_entvar(Ent, var_iuser1, wpn_ent);
	
	// Create Velocity
	static Float:Velocity[3]
	velocity_by_aim(id, GRENADE_VELOCITY, Velocity)
	set_entvar(Ent, var_velocity, Velocity);

	set_member(wpn_ent, m_Weapon_iGlock18ShotsFired, get_member(wpn_ent, m_Weapon_iGlock18ShotsFired) - 1);
	SetExtraAmmo(id, GRENADE_AMMOID, get_member(wpn_ent, m_Weapon_iGlock18ShotsFired))
	
	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(Ent); // entity
	write_short(iSprite[SPRITE_LASER]); // sprite
	write_byte(20);  // life
	write_byte(4);  // width
	write_byte(200); // r
	write_byte(200);  // g
	write_byte(200);  // b
	write_byte(200); // brightness
	message_end();
}

public fw_GrenadeTouch(ent, touch)
{
	if(!is_entity(ent))
		return;

	static owner, wpn_ent;
	owner = get_entvar(ent, var_owner);
	wpn_ent = get_entvar(ent, var_iuser1);

	rg_multidmg_clear();
	rg_multidmg_add(wpn_ent, touch, GRENADE_DAMAGE, (DMG_NEVERGIB | DMG_GRENADE));
	rg_multidmg_apply(wpn_ent, owner);
	rg_multidmg_clear();

	Make_Explosion(ent, wpn_ent, owner);
	engfunc(EngFunc_RemoveEntity, ent);
}

public Make_Explosion(ent, wpn_ent, owner)
{
	static Float:Origin[3];
	get_entvar(ent, var_origin, Origin);
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_short(iSprite[SPRITE_EXPLO]);	// sprite index
	write_byte(40);	// scale in 0.1's
	write_byte(20);	// framerate
	write_byte(0);	// flags
	message_end();
	
	// Put decal on "world" (a wall)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL);
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_byte(random_num(46, 48));
	message_end();	
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	engfunc(EngFunc_WriteCoord, Origin[0]);
	engfunc(EngFunc_WriteCoord, Origin[1]);
	engfunc(EngFunc_WriteCoord, Origin[2]);
	write_short(iSprite[SPRITE_STEAM]);	// sprite index 
	write_byte(50);	// scale in 0.1's 
	write_byte(10);	// framerate 
	message_end();
	
	while((i = find_ent_in_sphere(i, Origin, GRENADE_RADIUS)) != 0)
	{
		if(!is_user_alive(i))
			continue;
		if(get_member(i, m_iTeam) == get_member(owner, m_iTeam))
			continue

		rg_multidmg_clear();
		rg_multidmg_add(wpn_ent, i, i == owner ? GRENADE_DAMAGE / 4.0 : GRENADE_DAMAGE, (DMG_NEVERGIB | DMG_GRENADE));
		rg_multidmg_apply(wpn_ent, owner);
		rg_multidmg_clear();
	}
}

stock SetExtraAmmo(const iPlayer, const iAmmoID, const iClip)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, iPlayer);
	write_byte(iAmmoID);
	write_byte(iClip);
	message_end();
}
