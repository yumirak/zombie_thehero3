#include <amxmodx>
#include <reapi>
#include <xs>
#include <engine>
#define MSGFUNCWEAPONLIST
#define GUNSHOTDECALTRACE
#define CREATESMOKE
#define EJECTBRASS
#include <zb3_wpn_stock>
#include <zombie_thehero2>

#define ID_CUSWPN 14678923
#define STRN_BASEWPN "weapon_p90"
#define STRN_CUSWPN "weapon_mp7a1D"
#define DAMAGE_CUSWPN 54.0
#define CLIP_CUSWPN 80
#define RECOIL_CUSWPN 0.6
#define ACCURACY_CUSWPN 0.5
#define MAXAMMO_CUSWPN 240

#define RELOAD_TIME 3.43

new const LANG_FILE[] = "zombie_thehero2.txt"

new const WeaponModel[][] = 
{
	"models/zombi/supplybox_item/v_dual_mp7a1.mdl",
	"models/zombi/supplybox_item/p_dual_mp7a1.mdl",
	"models/zombi/supplybox_item/w_dual_mp7a1.mdl"
}

new const WeaponSounds[][] = 
{
	"weapons/dmp7-1.wav"
}

new const WeaponGeneric[][] = 
{
	"sprites/640hud7_2.spr",
	"sprites/640hud21_2.spr",
	"sprites/weapon_mp7a1d.txt",
	"sound/weapons/dmp7_draw.wav",
	"sound/weapons/dmp7_drop.wav",
	"sound/weapons/mp7_foley2.wav",
	"sound/weapons/mp7_foley4.wav"
}

enum
{
	MODEL_VIEW,
	MODEL_PLAYER,
	MODEL_WORLD
}

enum
{	
	ANIM_IDLE,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_RIGHT,
	ANIM_SHOOT_LEFT
};

new i, pPlayer, pEntity
new g_item1, g_item1_name[16]

public load_cfg()
{
	formatex(g_item1_name, charsmax(g_item1_name), "%L", LANG_SERVER, "SUPPLY_ITEM_DMP7A1")
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)

	load_cfg()

	for(i=0;i< sizeof WeaponSounds;i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	for(i=0;i< sizeof WeaponModel;i++)
		engfunc(EngFunc_PrecacheModel, WeaponModel[i])
	for(i=0;i< sizeof WeaponGeneric;i++)
		engfunc(EngFunc_PrecacheGeneric, WeaponGeneric[i])
}

public plugin_init()
{
	register_plugin(g_item1_name, "", "406")

	RegisterHam(Ham_Weapon_PrimaryAttack, STRN_BASEWPN, "Fw_Ham_Weapon_PrimaryAttack")
	RegisterHookChain(RG_CBasePlayer_AddPlayerItem, "Fw_RG_CBasePlayer_AddPlayerItem", 1)
	RegisterHookChain(RG_CBasePlayer_RemovePlayerItem, "Fw_RG_CBasePlayer_RemovePlayerItem", 1)

	register_forward(FM_UpdateClientData, "Fw_FM_UpdateClientData_Post", 1)
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultReload, "Fw_RG_CBasePlayerWeapon_DefaultReload")
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "Fw_RG_CBasePlayerWeapon_DefaultDeploy")
	RegisterHookChain(RG_CWeaponBox_SetModel, "Fw_RG_CWeaponBox_SetModel")

	g_item1 = zb3_register_supply_item(g_item1_name);

	// register_clcmd("mp7a1d", "give")
	register_clcmd(STRN_CUSWPN, "lastinv")
}

public zb3_supply_item_give(id, wpnid)
{
	if (wpnid == g_item1)
		give(id);
}

public give(player)
{
	if(!is_user_alive(player)) 
		return

	pEntity = rg_give_custom_item(player, STRN_BASEWPN, GT_DROP_AND_REPLACE, ID_CUSWPN)

	if(!is_entity(pEntity)) return	

	set_member(pEntity, m_Weapon_iClip, CLIP_CUSWPN)
	set_member(pEntity, m_Weapon_flBaseDamage, DAMAGE_CUSWPN);
	rg_set_iteminfo(pEntity, ItemInfo_iMaxClip, CLIP_CUSWPN)
	rg_set_iteminfo(pEntity, ItemInfo_iMaxAmmo1, MAXAMMO_CUSWPN)
	zb3_give_user_ammo(player, pEntity)

	static Float:vuser4[3]
	vuser4[0] = 170.0;
	vuser4[1] = 0.5;
	vuser4[2] = 0.0;
	set_entvar(pEntity, var_vuser4, vuser4)
}

public Fw_RG_CBasePlayer_AddPlayerItem(player, entity)
{
	if(!is_custom(entity, ID_CUSWPN))
		return HC_CONTINUE;

	MsgFunc_WeaponList(player, entity, STRN_CUSWPN)
	return HC_CONTINUE;
}
public Fw_RG_CBasePlayer_RemovePlayerItem(player, entity)
{
	if(!is_custom(entity, ID_CUSWPN))
		return HC_CONTINUE;

	MsgFunc_WeaponList(player, entity, STRN_BASEWPN)
	return HC_CONTINUE;
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
	SetHookChainArg( 5, ATYPE_STRING, "dualpistols")
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

	static iClip, iTraceLine, iPlaybackEvent, Float:vPunch[3]
	
	iClip = get_member(entity, m_Weapon_iClip)
	if(!iClip) return HAM_IGNORED

	pPlayer = get_member(entity, m_pPlayer)
	iTraceLine = register_forward(FM_TraceLine, "Fw_FM_TraceLine_Post", 1)
	iPlaybackEvent = register_forward(FM_PlaybackEvent, "Fw_FM_PlaybackEvent")
	ExecuteHam(Ham_Weapon_PrimaryAttack, entity)
	unregister_forward(FM_TraceLine, iTraceLine, 1)
	unregister_forward(FM_PlaybackEvent, iPlaybackEvent)
	
	set_member(entity, m_Weapon_flTimeWeaponIdle, 1.033)
	set_member(entity, m_Weapon_flAccuracy, ACCURACY_CUSWPN);

	get_entvar(pPlayer, var_punchangle, vPunch)
	xs_vec_mul_scalar(vPunch, RECOIL_CUSWPN, vPunch);
	set_entvar(pPlayer, var_punchangle, vPunch)
	
	emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	rg_weapon_send_animation(pPlayer, iClip & 1 ? ANIM_SHOOT_LEFT : ANIM_SHOOT_RIGHT)
	rg_set_animation(pPlayer, iClip & 1 ? PLAYER_ATTACK1 : PLAYER_ATTACK2);
	EjectBrass(pPlayer, get_member(entity, m_P90_iShell), 1);

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
	if(!is_user_alive(player)) return
	pEntity = get_member(player, m_pActiveItem)
	if(is_entity(pEntity) && get_entvar(pEntity, var_impulse) == ID_CUSWPN)
		set_cd(cd, CD_flNextAttack, 99999.0)
}
public Fw_FM_PlaybackEvent() return FMRES_SUPERCEDE
public lastinv(player) engclient_cmd(player, STRN_BASEWPN)
