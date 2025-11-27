#pragma semicolon 1
#pragma newdecls required

float TickrateModify;
//int TickrateModifyInt;

ConVar Cvar_TGG_WeaponsTillWin;
ConVar Cvar_TGG_AllowFreeClassPicking;


Handle g_hSetLocalOrigin;
Handle g_hSetLocalAngles;
Handle g_hSnapEyeAngles;
Handle g_hSetAbsVelocity;
Handle g_hSetAbsOrigin;
Handle g_hStudio_FindAttachment;
Handle g_hRecalculatePlayerBodygroups;
Handle SDKSetSpeed;
Handle g_hCTFCreateArrow;
Handle g_hSDKWorldSpaceCenter;
DynamicHook HookItemIterateAttribute;
Handle g_hImpulse;
ArrayList RawEntityHooks;
int m_bOnlyIterateItemViewAttributes;
int m_Item;
//bool IsInsideManageRegularWeapons;
int iref_PropAppliedToRocket[MAXENTITIES];
float f_RoundStartUberLastsUntil;
bool b_DisableCollisionOnRoundStart;
bool b_IsAProjectile[MAXENTITIES];
ArrayList SpawnPointArray;
TFTeam n_ForcedTeam;

ConVar sv_cheats;
ConVar mp_friendlyfire;
ConVar tf_scout_air_dash_count;
ConVar mp_humans_must_join_team;

int i_WeaponVMTExtraSetting[MAXENTITIES];
bool b_IsATrigger[MAXENTITIES];
bool b_IsATriggerHurt[MAXENTITIES];
int i_CustomWeaponEquipLogic[MAXENTITIES]={0, ...};
float f_PreventKillCredit[MAXENTITIES]={0.0, ...};
int i_SavedActualWeaponSlot[MAXENTITIES]={-1, ...};
int i_WeaponModelIndexOverride[MAXENTITIES];
int i_WeaponBodygroup[MAXENTITIES];
int i_WeaponForceClass[MAXENTITIES];
float f_WeaponSizeOverride[MAXENTITIES];
float f_WeaponSizeOverrideViewmodel[MAXENTITIES];
char c_WeaponUseAbilitiesHud[MAXENTITIES][16];
char c_WeaponName[MAXPLAYERS][64];
int i_Hex_WeaponUsesTheseAbilities[MAXENTITIES];
int i_Viewmodel_PlayerModel[MAXENTITIES] = {-1, ...};
int i_Worldmodel_WeaponModel[MAXPLAYERS] = {-1, ...};
int WeaponRef_viewmodel[MAXPLAYERS] = {-1, ...};
int HandRef[MAXPLAYERS] = {-1, ...};
bool b_IsAMedigun[MAXENTITIES];
float f_PreventMovementClient[MAXENTITIES];
float f_WandDamage[MAXENTITIES]; //
int i_WandWeapon[MAXENTITIES]; //
int i_WandParticle[MAXENTITIES]; //Only one allowed, dont use more. ever. ever ever. lag max otherwise.
int i_WandOwner[MAXENTITIES]; //				//785
int i_WeaponKilledWith[MAXPLAYERS];
bool b_DiedToFallDamage[MAXPLAYERS];
int i_FallDamageKillCredit[MAXPLAYERS];

float f_RetryRespawn[MAXPLAYERS]={0.0, ...};
int StoreWeapon[MAXENTITIES];
bool ValidTargetToHit[MAXENTITIES];

Function EntityFuncAttack[MAXENTITIES];
Function EntityFuncAttack2[MAXENTITIES];
Function EntityFuncAttack3[MAXENTITIES];
Function EntityFuncReload4[MAXENTITIES];
Function EntityFuncReloadCreate[MAXENTITIES];
Function EntityFuncRemove[MAXENTITIES];
Function EntityFuncJarate[MAXENTITIES];
Function EntityFuncTakeDamage[MAXENTITIES];
Function EntityPlayerCMD[MAXENTITIES];
TFClassType CurrentClass[MAXPLAYERS]={TFClass_Scout, ...};
TFClassType WeaponClass[MAXPLAYERS]={TFClass_Scout, ...};


int g_particleCritText;
int g_particleMiniCritText;

bool i_HasBeenHeadShotted[MAXPLAYERS];
int ClientAtWhatScore[MAXPLAYERS];
int ClientAssistsThisLevel[MAXPLAYERS];
int ClientKillsThisFrame[MAXPLAYERS];
int ClientFirstTimeChoosingTeam[MAXPLAYERS];