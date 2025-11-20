#pragma semicolon 1
#pragma newdecls required

float TickrateModify;
int TickrateModifyInt;

ConVar Cvar_GGR_WeaponsTillWin;
ConVar Cvar_GGR_AllowFreeClassPicking;


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
ConVar sv_cheats;
ConVar mp_friendlyfire;
DynamicHook g_DHookRocketExplode; //from mikusch but edited
int m_bOnlyIterateItemViewAttributes;
int m_Item;
bool IsInsideManageRegularWeapons;
int iref_PropAppliedToRocket[MAXENTITIES];
float f_RoundStartUberLastsUntil;

ConVar tf_scout_air_dash_count;

int h_NpcSolidHookType[MAXENTITIES];
bool b_IsATrigger[MAXENTITIES];
bool b_IsATriggerHurt[MAXENTITIES];
int i_CustomWeaponEquipLogic[MAXENTITIES]={0, ...};
int i_SavedActualWeaponSlot[MAXENTITIES]={-1, ...};
int i_WeaponModelIndexOverride[MAXENTITIES];
int i_WeaponBodygroup[MAXENTITIES];
int i_WeaponForceClass[MAXENTITIES];
float f_WeaponSizeOverride[MAXENTITIES];
float f_WeaponSizeOverrideViewmodel[MAXENTITIES];
char c_WeaponUseAbilitiesHud[MAXENTITIES][16];
int i_Hex_WeaponUsesTheseAbilities[MAXENTITIES];
int i_Viewmodel_PlayerModel[MAXENTITIES] = {-1, ...};
int i_Worldmodel_WeaponModel[MAXPLAYERS] = {-1, ...};
int i_PlayerModelOverrideIndexWearable[MAXPLAYERS] = {-1, ...};
bool b_HideCosmeticsPlayer[MAXPLAYERS];
int WeaponRef_viewmodel[MAXPLAYERS] = {-1, ...};
int HandRef[MAXPLAYERS] = {-1, ...};
bool b_IsAMedigun[MAXENTITIES];
float f_PreventMovementClient[MAXENTITIES];
bool b_ThisEntityIsAProjectileForUpdateContraints[MAXENTITIES];
float f_WandDamage[MAXENTITIES]; //
int i_WandWeapon[MAXENTITIES]; //
int i_WandParticle[MAXENTITIES]; //Only one allowed, dont use more. ever. ever ever. lag max otherwise.
int i_WandOwner[MAXENTITIES]; //				//785

int StoreWeapon[MAXENTITIES];

Function EntityFuncAttack[MAXENTITIES];
Function EntityFuncAttack2[MAXENTITIES];
Function EntityFuncAttack3[MAXENTITIES];
Function EntityFuncReload4[MAXENTITIES];
Function EntityFuncReloadCreate[MAXENTITIES];
TFClassType CurrentClass[MAXPLAYERS]={TFClass_Scout, ...};
TFClassType WeaponClass[MAXPLAYERS]={TFClass_Scout, ...};


int g_particleCritText;
int g_particleMiniCritText;

bool i_HasBeenHeadShotted[MAXPLAYERS];
int ClientAtWhatScore[MAXPLAYERS];