/* AMX Mod X
*	[ZP] Extra: Skull-4
*
* http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community
*
* This file is provided as is (no warranties)
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_thehero2>
#include <xs>


// #define _DEBUG_CMD "say /ak47long"

#define PLUGIN "[ZB3] Supply: CV-47 60R"
#define VERSION "1.3"
#define AUTHOR "KORD_12.7"

#pragma semicolon 1
#pragma ctrlchar '\'

//**********************************************
//* Weapon Settings.                           *
//**********************************************
//#define WEAPONLIST

// Main
#define WEAPON_REFERANCE		"weapon_ak47"
#define WEAPON_NAME 			"weapon_ak47L"

#define WEAPON_MAX_CLIP			60
#define WEAPON_DEFAULT_AMMO		240

#define WEAPON_MAX_SPEED		240.0
#define WEAPON_FOV_ZOOM			55

#define WEAPON_MULTIPLIER_DAMAGE 	2.2 // 36 * 2
#define WEAPON_MULTIPLIER_ACCURACY 	0.5
#define WEAPON_MULTIPLIER_RECOIL 	0.5

#define WEAPON_TIME_NEXT_IDLE 		2.00
#define WEAPON_TIME_NEXT_ATTACK 	0.1
#define WEAPON_TIME_DELAY_DEPLOY 	1.0
#define WEAPON_TIME_DELAY_RELOAD 	2.5

// Extra
#define ITEM_NAME			"CV-47 60R" 

// Models
#define MODEL_WORLD		"models/zombie_thehero/supplybox_item/w_ak47_60r.mdl"
#define MODEL_VIEW		"models/zombie_thehero/supplybox_item/v_ak47_60r.mdl"
#define MODEL_PLAYER	"models/zombie_thehero/supplybox_item/p_ak47_60r.mdl"
// Sounds
#define SOUND_FIRE		"weapons/ak47_60r_shoot.wav"

// Sprites
#if defined WEAPONLIST
#define WEAPON_HUD_TXT		"sprites/weapon_ak47l.txt"
#define WEAPON_HUD_SPR_1	"sprites/640hud7.spr"
#define WEAPON_HUD_SPR_2	"sprites/640hud32.spr"
#endif

// Animation
#define ANIM_EXTENSION		"ak47"

// Animation sequences
enum
{	
	ANIM_IDLE,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_1,
	ANIM_SHOOT_2,
	ANIM_SHOOT_3
};

//**********************************************
//* Some macroses.                             *
//**********************************************

#define SET_MODEL(%0,%1)		engfunc(EngFunc_SetModel, %0, %1)
#define SET_ORIGIN(%0,%1)		engfunc(EngFunc_SetOrigin, %0, %1)

#define PRECACHE_MODEL(%0)		engfunc(EngFunc_PrecacheModel, %0)
#define PRECACHE_SOUND(%0)		engfunc(EngFunc_PrecacheSound, %0)
#define PRECACHE_GENERIC(%0)		engfunc(EngFunc_PrecacheGeneric, %0)

#define PRECACHE_MODEL2(%0)		PrecacheSoundsFromModel(%0)

//**********************************************
//* PvData Offsets.                            *
//**********************************************

// Linux extra offsets
#define extra_offset_weapon		4
#define extra_offset_player		5

// CWeaponBox
#define m_rgpPlayerItems_CWeaponBox	34

// CBasePlayerItem
#define m_pPlayer			41
#define m_pNext				42

// CBasePlayerWeapon
#define m_flNextPrimaryAttack		46
#define m_flNextSecondaryAttack		47
#define m_flTimeWeaponIdle		48
#define m_iPrimaryAmmoType		49
#define m_iClip				51
#define m_fInReload			54
#define m_iDirection			60
#define m_iShotsFired			64
#define m_fWeaponState			74
#define m_flAccuracy			62
// CBaseMonster
#define m_flNextAttack			83

// CBasePlayer
#define m_iFOV				363
#define m_rgpPlayerItems_CBasePlayer	367
#define m_pActiveItem			373
#define m_rgAmmo_CBasePlayer		376
#define m_szAnimExtention		492


//**********************************************
//* Let's code our weapon.                     *
//**********************************************

Weapon_OnPrecache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL2(MODEL_VIEW);
	
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);
	
	PRECACHE_SOUND(SOUND_FIRE);
	#if defined WEAPONLIST
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR_2);
	#endif
}

Weapon_OnSpawn(const iItem)
{
	// Setting world model.
	SET_MODEL(iItem, MODEL_WORLD);
}

Weapon_OnDeploy(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
	
	static iszViewModel;
	if (iszViewModel || (iszViewModel = engfunc(EngFunc_AllocString, MODEL_VIEW)))
	{
		set_pev_string(iPlayer, pev_viewmodel2, iszViewModel);
	}
	
	static iszPlayerModel;
	if (iszPlayerModel || (iszPlayerModel = engfunc(EngFunc_AllocString, MODEL_PLAYER)))
	{
		set_pev_string(iPlayer, pev_weaponmodel2, iszPlayerModel);
	}
	
	set_pdata_string(iPlayer, m_szAnimExtention * 4, ANIM_EXTENSION, -1, extra_offset_player * 4);
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_DEPLOY, extra_offset_weapon);
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_DEPLOY, extra_offset_player);

	Weapon_SendAnim(iPlayer, ANIM_DRAW);
}

Weapon_OnHolster(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iPlayer, iClip, iAmmoPrimary
	
	// Cancel any reload in progress.
	set_pdata_int(iItem, m_fInReload, 0, extra_offset_weapon);
}

Weapon_OnIdle(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary
	
	ExecuteHamB(Ham_Weapon_ResetEmptySound, iItem);

	if (get_pdata_int(iItem, m_flTimeWeaponIdle, extra_offset_weapon) > 0.0)
	{
		return;
	}
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);
	Weapon_SendAnim(iPlayer, ANIM_IDLE);
}

Weapon_OnReload(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	if (min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary) <= 0)
	{
		return;
	}

	if (get_pdata_int(iPlayer, m_iFOV, extra_offset_player) != 90)
	{
		Weapon_OnSecondaryAttack(iItem, iPlayer, iClip, iAmmoPrimary);
	}
	
	set_pdata_int(iItem, m_iClip, 0, extra_offset_weapon);
	
	ExecuteHam(Ham_Weapon_Reload, iItem);
	
	set_pdata_int(iItem, m_iClip, iClip, extra_offset_weapon);
	
	set_pdata_float(iPlayer, m_flNextAttack, WEAPON_TIME_DELAY_RELOAD, extra_offset_player);
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_DELAY_RELOAD, extra_offset_weapon);
	
	Weapon_SendAnim(iPlayer, ANIM_RELOAD);
}

Weapon_OnPrimaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iAmmoPrimary

	CallOrigFireBullets3(iItem);

	if (iClip <= 0)
	{
		return;
	}
	
	static iFlags, iAnimDesired, iWeaponState; 
	new Float: vecPuncheAngle[3];
	static szAnimation[64], Float: vecVelocity[3];
	
	iFlags = pev(iPlayer, pev_flags);

	Weapon_SendAnim(iPlayer, random_num(ANIM_SHOOT_1,ANIM_SHOOT_3));
		
	formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXTENSION);
	
	if ((iAnimDesired = lookup_sequence(iPlayer, szAnimation)) == -1)
	{
		iAnimDesired = 0;
	}
	
	pev(iPlayer, pev_punchangle, vecPuncheAngle);
	xs_vec_mul_scalar(vecPuncheAngle, WEAPON_MULTIPLIER_RECOIL, vecPuncheAngle);
	set_pev(iPlayer, pev_punchangle, vecPuncheAngle);

	pev(iPlayer, pev_velocity, vecVelocity);
	set_pev(iPlayer, pev_sequence, iAnimDesired);
	
	set_pdata_int(iItem, m_fWeaponState, iWeaponState, extra_offset_weapon);
	
	set_pdata_float(iItem, m_flTimeWeaponIdle, WEAPON_TIME_NEXT_IDLE, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextPrimaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flNextSecondaryAttack, WEAPON_TIME_NEXT_ATTACK, extra_offset_weapon);
	set_pdata_float(iItem, m_flAccuracy, WEAPON_MULTIPLIER_ACCURACY, extra_offset_weapon);

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);
}

Weapon_OnSecondaryAttack(const iItem, const iPlayer, const iClip, const iAmmoPrimary)
{
	#pragma unused iClip, iAmmoPrimary

	set_pdata_float(iItem, m_flNextSecondaryAttack, 0.3, extra_offset_weapon);
	set_pdata_int(iPlayer, m_iFOV, get_pdata_int(iPlayer, m_iFOV, extra_offset_player) == 90 ? WEAPON_FOV_ZOOM : 90, extra_offset_player);
}

//*********************************************************************
//*           Don't modify the code below this line unless            *
//*          	 you know _exactly_ what you are doing!!!             *
//*********************************************************************

#define MSG_WEAPONLIST 78

#define _CALLFUNC(%0,%1,%2) \
									\
	Weapon_On%0							\
	(								\
		%1, 							\
		%2,							\
									\
		get_pdata_int(%1, m_iClip, extra_offset_weapon),	\
		GetAmmoInventory(%2, PrimaryAmmoIndex(%1))		\
	) 

#define STATEMENT_FALLBACK(%0,%1,%2)	public %0()<>{return %1;} public %0()<%2>{return %1;}

#define MESSAGE_BEGIN(%0,%1,%2,%3)	engfunc(EngFunc_MessageBegin, %0, %1, %2, %3)
#define MESSAGE_END()			message_end()

#define WRITE_ANGLE(%0)			engfunc(EngFunc_WriteAngle, %0)
#define WRITE_BYTE(%0)			write_byte(%0)
#define WRITE_COORD(%0)			engfunc(EngFunc_WriteCoord, %0)
#define WRITE_STRING(%0)		write_string(%0)
#define WRITE_SHORT(%0)			write_short(%0)

#define MDLL_Spawn(%0)			dllfunc(DLLFunc_Spawn, %0)
#define MDLL_Touch(%0,%1)		dllfunc(DLLFunc_Touch, %0, %1)

//**********************************************
//* Motor!.                                    *
//**********************************************

new g_iszWeaponKey;
new g_iForwardDecalIndex;
new g_iItemID;
#define IsValidPev(%0) (pev_valid(%0) == 2)
#define IsCustomItem(%0) (pev(%0, pev_impulse) == g_iszWeaponKey)

public plugin_precache()
{
	Weapon_OnPrecache();

	g_iItemID = zb3_register_supply_item(ITEM_NAME);
	g_iszWeaponKey = engfunc(EngFunc_AllocString, WEAPON_NAME);
	g_iForwardDecalIndex = register_forward(FM_DecalIndex, "FakeMeta_DecalIndex_Post", true);
	
	register_message(MSG_WEAPONLIST, "MsgHook_WeaponList");
	register_message(get_user_msgid("DeathMsg"), "MsgHook_Death");
#if defined _DEBUG_CMD
	register_clcmd(_DEBUG_CMD, "Cmd_WeaponGive");
#endif
	register_clcmd(WEAPON_NAME, "Cmd_WeaponSelect");

}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	RegisterHam(Ham_Spawn, 		"weaponbox", 		"HamHook_Weaponbox_Spawn_Post", true);

	RegisterHam(Ham_TraceAttack,	"func_breakable",	"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,	"hostage_entity",	"HamHook_Entity_TraceAttack", 	false);
	RegisterHam(Ham_TraceAttack,	"info_target", 		"HamHook_Entity_TraceAttack",	false);
	RegisterHam(Ham_TraceAttack,	"player", 		"HamHook_Entity_TraceAttack",	false);
	
	RegisterHam(Ham_Item_Deploy,		WEAPON_REFERANCE, 	"HamHook_Item_Deploy_Post",	true);
	RegisterHam(Ham_Item_Holster,		WEAPON_REFERANCE,	"HamHook_Item_Holster",		false);
	RegisterHam(Ham_Item_PostFrame,		WEAPON_REFERANCE, 	"HamHook_Item_PostFrame",	false);
	RegisterHam(Ham_Item_AttachToPlayer,	WEAPON_REFERANCE, 	"HamHook_Item_AttachToPlayer",	false);
	RegisterHam(Ham_CS_Item_GetMaxSpeed,	WEAPON_REFERANCE, 	"HamHook_Item_GetMaxSpeed",	false);

	RegisterHam(Ham_Weapon_Reload,		WEAPON_REFERANCE, 	"HamHook_Item_Reload",		false);
	RegisterHam(Ham_Weapon_WeaponIdle,	WEAPON_REFERANCE, 	"HamHook_Item_WeaponIdle",	false);
	RegisterHam(Ham_Weapon_PrimaryAttack,	WEAPON_REFERANCE, 	"HamHook_Item_PrimaryAttack",	false);
	
	RegisterHam(Ham_RemovePlayerItem,	"player", 		"HamHook_RemovePlayerItem",	false);
	
	register_forward(FM_SetModel,		"FakeMeta_SetModel",			false);
	register_forward(FM_TraceLine,		"FakeMeta_TraceLine_Post",		true);
	register_forward(FM_PlaybackEvent,	"FakeMeta_PlaybackEvent",		false);
	register_forward(FM_UpdateClientData,	"FakeMeta_UpdateClientData_Post",	true);
	
	unregister_forward(FM_DecalIndex, g_iForwardDecalIndex, true);
}

public Cmd_WeaponGive(const iPlayer)
{
	Weapon_Give(iPlayer);
}

public zb3_supply_item_give(id, wpnid)
{
	if (wpnid == g_iItemID)
	{
		Weapon_Give(id);
	}
}
/*
public plugin_natives()
{
	register_native("zb3_getitem_num", "native_getitem", 1);
}
public native_getitem(id, itemid)
{
	if (itemid == 1) 
	{
		Weapon_Give(id);
	}
}*/

//**********************************************
//* Block client weapon.                       *
//**********************************************

public FakeMeta_UpdateClientData_Post(const iPlayer, const iSendWeapons, const CD_Handle)
{
	static iActiveItem;
	
	if (!IsValidPev(iPlayer))
	{
		return FMRES_IGNORED;
	}
	
	iActiveItem = get_pdata_cbase(iPlayer, m_pActiveItem, extra_offset_player);
	
	if (!IsValidPev(iActiveItem) || !IsCustomItem(iActiveItem))
	{
		return FMRES_IGNORED;
	}
	
	set_cd(CD_Handle, CD_flNextAttack, get_gametime() + 0.001);
	return FMRES_IGNORED;
}

//**********************************************
//* Item (weapon) hooks.                       *
//**********************************************

public HamHook_Item_GetMaxSpeed(const iItem)
{
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return HAM_IGNORED;
	}
	
	SetHamReturnFloat(WEAPON_MAX_SPEED);
	return HAM_OVERRIDE;
}

public HamHook_Item_Deploy_Post(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_CALLFUNC(Deploy, iItem, iPlayer);
	return HAM_IGNORED;
}

public HamHook_Item_Holster(const iItem)
{
	new iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	set_pev(iPlayer, pev_viewmodel, 0);
	set_pev(iPlayer, pev_weaponmodel, 0);
	
	_CALLFUNC(Holster, iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_WeaponIdle(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}

	_CALLFUNC(Idle, iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_Reload(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_CALLFUNC(Reload, iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PrimaryAttack(const iItem)
{
	static iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	_CALLFUNC(PrimaryAttack, iItem, iPlayer);
	return HAM_SUPERCEDE;
}

public HamHook_Item_PostFrame(const iItem)
{
	static iButton, iPlayer; 
	
	if (!CheckItem(iItem, iPlayer))
	{
		return HAM_IGNORED;
	}
	
	// Complete reload
	if (get_pdata_int(iItem, m_fInReload, extra_offset_weapon))
	{
		new iClip		= get_pdata_int(iItem, m_iClip, extra_offset_weapon); 
		new iPrimaryAmmoIndex	= PrimaryAmmoIndex(iItem);
		new iAmmoPrimary	= GetAmmoInventory(iPlayer, iPrimaryAmmoIndex);
		new iAmount		= min(WEAPON_MAX_CLIP - iClip, iAmmoPrimary);
		
		set_pdata_int(iItem, m_iClip, iClip + iAmount, extra_offset_weapon);
		set_pdata_int(iItem, m_fInReload, false, extra_offset_weapon);

		SetAmmoInventory(iPlayer, iPrimaryAmmoIndex, iAmmoPrimary - iAmount);
	}
	
	// Call secondary attack
	if ((iButton = pev(iPlayer, pev_button)) & IN_ATTACK2 
		&& get_pdata_float(iItem, m_flNextSecondaryAttack, extra_offset_weapon) < 0.0)
	{
		_CALLFUNC(SecondaryAttack, iItem, iPlayer);
		set_pev(iPlayer, pev_button, iButton & ~IN_ATTACK2);
	}
	
	return HAM_IGNORED;
}

//**********************************************
//* Weapon list update.                        *
//**********************************************

new g_aWeaponListData[8];

public Cmd_WeaponSelect(const iPlayer)
{
	engclient_cmd(iPlayer, WEAPON_REFERANCE);
	return PLUGIN_HANDLED;
}

public MsgHook_WeaponList(const iMsgID, const iMsgDest, const iMsgEntity)
{
	new szWeaponName[32];
	get_msg_arg_string(1, szWeaponName, charsmax(szWeaponName));
		
	if (!strcmp(szWeaponName, WEAPON_REFERANCE))
	{
		for (new i, a = sizeof g_aWeaponListData; i < a; i++)
		{
			g_aWeaponListData[i] = get_msg_arg_int(i + 2);
		}
	}
}

public HamHook_Item_AttachToPlayer(const iItem, const iPlayer)
{
	if (!IsValidPev(iItem) || !IsValidPev(iPlayer))
	{
		return HAM_IGNORED;
	}
	#if defined WEAPONLIST
	if (IsCustomItem(iItem))
	{
		SendWeaponListUpdate(iPlayer, WEAPON_NAME);
	}
	#endif
	
	return HAM_IGNORED;
}

public HamHook_RemovePlayerItem(const iPlayer, const iItem)
{
	if (!IsValidPev(iItem) || !IsValidPev(iPlayer))
	{
		return HAM_IGNORED;
	}
	#if defined WEAPONLIST
	if (IsCustomItem(iItem))
	{
		SendWeaponListUpdate(iPlayer, WEAPON_REFERANCE);
	}
	#endif
	return HAM_IGNORED;
}
#if defined WEAPONLIST
SendWeaponListUpdate(const iPlayer, const szWeaponName[32])
{
	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, MSG_WEAPONLIST, {0.0, 0.0, 0.0}, iPlayer);
	WRITE_STRING(szWeaponName);
		
	for (new i, a = sizeof g_aWeaponListData; i < a; i++)
	{
		WRITE_BYTE(g_aWeaponListData[i]);
	}
	
	MESSAGE_END();
}
#endif
//**********************************************
//* Fire Bullets.                              *
//**********************************************

CallOrigFireBullets3(const iItem)
{
	
	state stFireBullets: Enabled;
	ExecuteHam(Ham_Weapon_PrimaryAttack, iItem);
	state stFireBullets: Disabled;
}

public FakeMeta_TraceLine_Post(const Float: vecTraceStart[3], const Float: vecTraceEnd[3], const fNoMonsters, const iEntToSkip, const iTrace) <stFireBullets: Enabled>
{
	static Float: vecEndPos[3];
	
	get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	engfunc(EngFunc_TraceLine, vecEndPos, vecTraceStart, fNoMonsters, iEntToSkip, 0);
	
	UTIL_GunshotDecalTrace(0);
	UTIL_GunshotDecalTrace(iTrace, true);
	
	return FMRES_IGNORED;
}
STATEMENT_FALLBACK(FakeMeta_TraceLine_Post, FMRES_IGNORED, stFireBullets: Disabled)

public HamHook_Entity_TraceAttack(const iEntity, const iAttacker, const Float: flDamage) <stFireBullets: Enabled>
{
	SetHamParamFloat(3, flDamage * WEAPON_MULTIPLIER_DAMAGE);
	return HAM_IGNORED;
}
STATEMENT_FALLBACK(HamHook_Entity_TraceAttack, HAM_IGNORED, stFireBullets: Disabled)

public MsgHook_Death() <stFireBullets: Enabled>
{
	static szTruncatedWeaponName[32];
	
	if (szTruncatedWeaponName[0] == EOS)
	{
		copy(szTruncatedWeaponName, charsmax(szTruncatedWeaponName), WEAPON_NAME);
		replace(szTruncatedWeaponName, charsmax(szTruncatedWeaponName), "weapon_", "");
	}
	
	set_msg_arg_string(4, szTruncatedWeaponName);
	return PLUGIN_CONTINUE;
}
STATEMENT_FALLBACK(MsgHook_Death, PLUGIN_CONTINUE, stFireBullets: Disabled)

public FakeMeta_PlaybackEvent() <stFireBullets: Enabled>
{
	return FMRES_SUPERCEDE;
}
STATEMENT_FALLBACK(FakeMeta_PlaybackEvent, FMRES_IGNORED, stFireBullets: Disabled)

//**********************************************
//* Weaponbox world model.                     *
//**********************************************

public HamHook_Weaponbox_Spawn_Post(const iWeaponBox)
{
	if (IsValidPev(iWeaponBox))
	{
		state (IsValidPev(pev(iWeaponBox, pev_owner))) stWeaponBox: Enabled;
	}
	
	return HAM_IGNORED;
}

public FakeMeta_SetModel(const iEntity) <stWeaponBox: Enabled>
{
	state stWeaponBox: Disabled;
	
	if (!IsValidPev(iEntity))
	{
		return FMRES_IGNORED;
	}
	
	#define MAX_ITEM_TYPES	6
	
	for (new i, iItem; i < MAX_ITEM_TYPES; i++)
	{
		iItem = get_pdata_cbase(iEntity, m_rgpPlayerItems_CWeaponBox + i, extra_offset_weapon);
		
		if (IsValidPev(iItem) && IsCustomItem(iItem))
		{
			SET_MODEL(iEntity, MODEL_WORLD);
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}
STATEMENT_FALLBACK(FakeMeta_SetModel, FMRES_IGNORED, stWeaponBox: Disabled)

//**********************************************
//* Create and check our custom weapon.        *
//**********************************************

Weapon_Create(const Float: vecOrigin[3] = {0.0, 0.0, 0.0}, const Float: vecAngles[3] = {0.0, 0.0, 0.0})
{
	new iWeapon;

	static iszAllocStringCached;
	if (iszAllocStringCached || (iszAllocStringCached = engfunc(EngFunc_AllocString, WEAPON_REFERANCE)))
	{
		iWeapon = engfunc(EngFunc_CreateNamedEntity, iszAllocStringCached);
	}
	
	if (!IsValidPev(iWeapon))
	{
		return FM_NULLENT;
	}
	
	MDLL_Spawn(iWeapon);
	SET_ORIGIN(iWeapon, vecOrigin);
	
	set_pdata_int(iWeapon, m_iClip, WEAPON_MAX_CLIP, extra_offset_weapon);

	set_pev(iWeapon, pev_impulse, g_iszWeaponKey);
	set_pev(iWeapon, pev_angles, vecAngles);
	
	Weapon_OnSpawn(iWeapon);
	
	return iWeapon;
}

Weapon_Give(const iPlayer)
{
	if (!IsValidPev(iPlayer))
	{
		return FM_NULLENT;
	}
	
	new iWeapon, Float: vecOrigin[3];
	pev(iPlayer, pev_origin, vecOrigin);
	
	if ((iWeapon = Weapon_Create(vecOrigin)) != FM_NULLENT)
	{
		Player_DropWeapons(iPlayer, ExecuteHamB(Ham_Item_ItemSlot, iWeapon));
		
		set_pev(iWeapon, pev_spawnflags, pev(iWeapon, pev_spawnflags) | SF_NORESPAWN);
		MDLL_Touch(iWeapon, iPlayer);
		
		SetAmmoInventory(iPlayer, PrimaryAmmoIndex(iWeapon), WEAPON_DEFAULT_AMMO);
		
		return iWeapon;
	}
	
	return FM_NULLENT;
}

Player_DropWeapons(const iPlayer, const iSlot)
{
	new szWeaponName[32], iItem = get_pdata_cbase(iPlayer, m_rgpPlayerItems_CBasePlayer + iSlot, extra_offset_player);

	while (IsValidPev(iItem))
	{
		pev(iItem, pev_classname, szWeaponName, charsmax(szWeaponName));
		engclient_cmd(iPlayer, "drop", szWeaponName);

		iItem = get_pdata_cbase(iItem, m_pNext, extra_offset_weapon);
	}
}

Weapon_SendAnim(const iPlayer, const iAnim)
{
	set_pev(iPlayer, pev_weaponanim, iAnim);

	MESSAGE_BEGIN(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	WRITE_BYTE(iAnim);
	WRITE_BYTE(0);
	MESSAGE_END();
}

bool: CheckItem(const iItem, &iPlayer)
{
	if (!IsValidPev(iItem) || !IsCustomItem(iItem))
	{
		return false;
	}
	
	iPlayer = get_pdata_cbase(iItem, m_pPlayer, extra_offset_weapon);
	
	if (!IsValidPev(iPlayer))
	{
		return false;
	}
	
	return true;
}

//**********************************************
//* Decals.                                    *
//**********************************************

#define INSTANCE(%0) ((%0 == -1) ? 0 : %0)

new Array: g_hDecals;

public FakeMeta_DecalIndex_Post()
{
	if (!g_hDecals)
	{
		g_hDecals = ArrayCreate(1, 1);
	}
	
	ArrayPushCell(g_hDecals, get_orig_retval());
}

UTIL_GunshotDecalTrace(const iTrace, const bool: bIsGunshot = false)
{
	static iHit;
	static iMessage;
	static iDecalIndex;
	
	static Float: flFraction; 
	static Float: vecEndPos[3];
	
	iHit = INSTANCE(get_tr2(iTrace, TR_pHit));
	
	if (iHit  && !IsValidPev(iHit) || (pev(iHit, pev_flags) & FL_KILLME))
	{
		return;
	}
	
	if (pev(iHit, pev_solid) != SOLID_BSP && pev(iHit, pev_movetype) != MOVETYPE_PUSHSTEP)
	{
		return;
	}
	
	iDecalIndex = ExecuteHamB(Ham_DamageDecal, iHit, 0);
	
	if (iDecalIndex < 0 || iDecalIndex >=  ArraySize(g_hDecals))
	{
		return;
	}
	
	iDecalIndex = ArrayGetCell(g_hDecals, iDecalIndex);
	
	get_tr2(iTrace, TR_flFraction, flFraction);
	get_tr2(iTrace, TR_vecEndPos, vecEndPos);
	
	if (iDecalIndex < 0 || flFraction >= 1.0)
	{
		return;
	}
	
	if (bIsGunshot)
	{
		iMessage = TE_GUNSHOTDECAL;
	}
	else
	{
		iMessage = TE_DECAL;
		
		if (iHit != 0)
		{
			if (iDecalIndex > 255)
			{
				iMessage = TE_DECALHIGH;
				iDecalIndex -= 256;
			}
		}
		else
		{
			iMessage = TE_WORLDDECAL;
			
			if (iDecalIndex > 255)
			{
				iMessage = TE_WORLDDECALHIGH;
				iDecalIndex -= 256;
			}
		}
	}
	
	MESSAGE_BEGIN(MSG_PAS, SVC_TEMPENTITY, vecEndPos, 0);
	WRITE_BYTE(iMessage);
	WRITE_COORD(vecEndPos[0]);
	WRITE_COORD(vecEndPos[1]);
	WRITE_COORD(vecEndPos[2]);
	
	if (bIsGunshot)
	{
		WRITE_SHORT(iHit);
		WRITE_BYTE(iDecalIndex);
	}
	else 
	{
		WRITE_BYTE(iDecalIndex);
		
		if (iHit)
		{
			WRITE_SHORT(iHit);
		}
	}
    
	MESSAGE_END();
}

//**********************************************
//* Get and precache sounds from weapon model. *
//**********************************************

PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if ((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for (new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);

			for (k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if (iEvent != 5004)
				{
					continue;
				}

				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if (strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					PRECACHE_SOUND(szSoundPath);
				}
				
				// server_print(" * Sound: %s", szSoundPath);
			}
		}
	}
	
	fclose(iFile);
}

//**********************************************
//* Ammo Inventory.                            *
//**********************************************

PrimaryAmmoIndex(const iItem)
{
	return get_pdata_int(iItem, m_iPrimaryAmmoType, extra_offset_weapon);
}

GetAmmoInventory(const iPlayer, const iAmmoIndex)
{
	if (iAmmoIndex == -1)
	{
		return -1;
	}

	return get_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, extra_offset_player);
}

SetAmmoInventory(const iPlayer, const iAmmoIndex, const iAmount)
{
	if (iAmmoIndex == -1)
	{
		return 0;
	}

	set_pdata_int(iPlayer, m_rgAmmo_CBasePlayer + iAmmoIndex, iAmount, extra_offset_player);
	return 1;
}
