#include <amxmodx>
#include <reapi>
#include <xs>
#include <fakemeta_util>
#include <engine>
#define MSGFUNCWEAPONLIST
#define GUNSHOTDECALTRACE
#include <zb3_wpn_stock>
#include <zombie_thehero2>

#define ID_CUSWPN 1034689
#define STRN_BASEWPN "weapon_m3"
#define STRN_CUSWPN "weapon_qbarrel"
#define DAMAGE_CUSWPN 270.0
#define CLIP_CUSWPN 4
#define ROF_CUSWPN 0.4
#define RECOIL_CUSWPN 0.5
#define ACCURACY_CUSWPN 0.5
#define MAXAMMO_CUSWPN 150

#define RELOAD_TIME 3.0


new const WeaponModel[][] = 
{
	"models/zombie_thehero/hero_wpn/v_qbarrel.mdl",
	"models/zombie_thehero/hero_wpn/p_qbarrel.mdl",
	"models/zombie_thehero/hero_wpn/w_qbarrel.mdl"
}

new const WeaponSounds[][] = 
{
	"weapons/qbarrel_shoot.wav",
	"weapons/qbarrel_clipin1.wav",
	"weapons/qbarrel_clipin2.wav",
	"weapons/qbarrel_clipout1.wav",
	"weapons/qbarrel_draw.wav"
}

new const WeaponSprites[][] = 
{
	"sprites/640hud7_2.spr",
	"sprites/640hud36_2.spr",
	"sprites/640hud41_2.spr"
}

new const WeaponGeneric[][] = 
{
	"sprites/weapon_qbarrel.txt"
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
	ANIM_SHOOT_A,
	ANIM_SHOOT_B,
	ANIM_RELOAD,
	ANIM_DRAW
};

new i, pPlayer, pEntity

public plugin_precache()
{
	for(i=0;i< sizeof WeaponSounds;i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	for(i=0;i< sizeof WeaponSprites;i++)
		engfunc(EngFunc_PrecacheModel, WeaponSprites[i])
	for(i=0;i< sizeof WeaponModel;i++)
		engfunc(EngFunc_PrecacheModel, WeaponModel[i])
	for(i=0;i< sizeof WeaponGeneric;i++)
		engfunc(EngFunc_PrecacheGeneric, WeaponGeneric[i])
}

public plugin_init()
{
	register_plugin("QBARREL", "", "406")

	RegisterHam(Ham_Weapon_PrimaryAttack, STRN_BASEWPN, "Fw_Ham_Weapon_PrimaryAttack")
	RegisterHam(Ham_Item_AddToPlayer, STRN_BASEWPN, "Fw_Ham_Item_AddToPlayer", 1)

	register_forward(FM_UpdateClientData, "Fw_FM_UpdateClientData_Post", 1)

	RegisterHookChain(RG_CBasePlayerWeapon_DefaultShotgunReload, "Fw_RG_CBasePlayerWeapon_DefaultShotgunReload")
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "Fw_RG_CBasePlayerWeapon_DefaultDeploy")
	RegisterHookChain(RG_CBasePlayerWeapon_ItemPostFrame, "Fw_RG_CBasePlayerWeapon_ItemPostFrame")
	RegisterHookChain(RG_CWeaponBox_SetModel, "Fw_RG_CWeaponBox_SetModel")

	register_clcmd("qbarrel", "give")

	register_clcmd(STRN_CUSWPN, "lastinv")
}

public zb3_user_become_hero(id, hero_type)
{
	if(hero_type == HERO_KATE) give(id);
}

public zb3_supply_refill_ammo(id)
{
	static ent;

	if(!rg_find_ent_by_owner(ent, STRN_BASEWPN, id))
		return
	if(!is_custom(ent, ID_CUSWPN))
		return;

	zb3_give_user_ammo(id, ent)
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
}

public Fw_Ham_Item_AddToPlayer(entity, player)
{
	if(get_entvar(entity, var_impulse) != ID_CUSWPN) 
		return

	MsgFunc_WeaponList(player, entity, STRN_CUSWPN)
}

public Fw_RG_CBasePlayerWeapon_ItemPostFrame(const this)
{
	if(get_entvar(this, var_impulse) != ID_CUSWPN) return

	static iButton;
	pPlayer = get_member(this, m_pPlayer);
	iButton = get_entvar(pPlayer, var_button);

	if(!(iButton & IN_ATTACK2)) return

	// Call secondary attack
	if (iButton & IN_ATTACK2 && get_member(this, m_Weapon_flNextSecondaryAttack) < 0.0) 
	{
		set_entvar(pPlayer, var_button, iButton & ~IN_ATTACK2);

		while(get_member(this, m_Weapon_iClip) > 0)
			Fw_Ham_Weapon_PrimaryAttack(this)

		set_member(this, m_Weapon_flTimeWeaponIdle, 1.0)
		set_member(this, m_Weapon_flNextPrimaryAttack, 0.1)
		set_member(this, m_Weapon_flNextSecondaryAttack, 0.1)
	}
}

public Fw_RG_CBasePlayerWeapon_DefaultShotgunReload(const this, iAnim, iStartAnim, Float:fDelay, Float:fStartDelay, const pszReloadSound1[], const pszReloadSound2[])
{
	if(get_entvar(this, var_impulse) != ID_CUSWPN) 
		return HC_CONTINUE

	rg_weapon_reload(this, rg_get_iteminfo(this, ItemInfo_iMaxClip), ANIM_RELOAD, RELOAD_TIME);

	SetHookChainReturn(ATYPE_BOOL, false)
	return HC_SUPERCEDE;
}

public Fw_RG_CBasePlayerWeapon_DefaultDeploy(const entity, szViewModel[], szWeaponModel[], iAnim, szAnimExt[], skiplocal)
{
	if(get_entvar(entity, var_impulse) != ID_CUSWPN) 
		return
	
	SetHookChainArg( 2, ATYPE_STRING, WeaponModel[MODEL_VIEW])
	SetHookChainArg( 3, ATYPE_STRING, WeaponModel[MODEL_PLAYER])
	SetHookChainArg( 4, ATYPE_INTEGER, ANIM_DRAW)
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
	if(get_entvar(entity, var_impulse) != ID_CUSWPN) return HAM_IGNORED

	static iClip, iTraceLine, iPlaybackEvent, Float:vPunch[3]

	pPlayer = get_member(entity, m_pPlayer)

	iClip = get_member(entity, m_Weapon_iClip)
	if(!iClip) return HAM_IGNORED

	iTraceLine = register_forward(FM_TraceLine, "Fw_FM_TraceLine_Post", 1)
	iPlaybackEvent = register_forward(FM_PlaybackEvent, "Fw_FM_PlaybackEvent")
	ExecuteHam(Ham_Weapon_PrimaryAttack, entity)
	unregister_forward(FM_TraceLine, iTraceLine, 1)
	unregister_forward(FM_PlaybackEvent, iPlaybackEvent)

	set_member(entity, m_Weapon_flTimeWeaponIdle, 1.0)
	set_member(entity, m_Weapon_flNextPrimaryAttack, ROF_CUSWPN);
	set_member(entity, m_Weapon_flAccuracy, ACCURACY_CUSWPN);

	get_entvar(pPlayer, var_punchangle, vPunch)
	xs_vec_mul_scalar(vPunch, RECOIL_CUSWPN, vPunch);
	set_entvar(pPlayer, var_punchangle, vPunch)
	
	emit_sound(pPlayer, CHAN_WEAPON, WeaponSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	rg_weapon_send_animation(pPlayer, ANIM_SHOOT_A)
	rg_set_animation(pPlayer, PLAYER_ATTACK1);

	return HAM_SUPERCEDE
}

public Fw_FM_TraceLine_Post(Float:vecStart[3], Float:vecEnd[3], noMonsters, pentToSkip, iTrace)
{
	if(noMonsters) return
	GunshotDecalTrace(iTrace, true)
}

public Fw_FM_UpdateClientData_Post(player, sendWeapons, cd)
{
#if 0
	if(!is_user_alive(player)) return
	pEntity = get_member(player, m_pActiveItem)
	if(is_entity(pEntity) && get_entvar(pEntity, var_impulse) == ID_CUSWPN)
		set_cd(cd, CD_flNextAttack, 99999.0)
#else
	if (!is_user_alive(player))
		return FMRES_IGNORED;
	
	pEntity = get_member(player, m_pActiveItem)
	
	if (!is_entity(pEntity) || get_entvar(pEntity, var_impulse) != ID_CUSWPN)
		return FMRES_IGNORED;
	
	set_cd(cd, CD_flNextAttack, get_gametime() + 0.001);
	return FMRES_IGNORED;
#endif
}
public Fw_FM_PlaybackEvent() return FMRES_SUPERCEDE
public lastinv(player) engclient_cmd(player, STRN_BASEWPN)
