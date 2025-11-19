#pragma semicolon 1
#pragma newdecls required

float TickrateModify;
int TickrateModifyInt;

ConVar Cvar_GGR_WeaponsTillWin;


Handle g_hSetLocalOrigin;
Handle g_hSetLocalAngles;
Handle g_hSnapEyeAngles;
Handle g_hSetAbsVelocity;
Handle g_hSetAbsOrigin;
Handle g_hStudio_FindAttachment;
Handle g_hRecalculatePlayerBodygroups;
Handle SDKSetSpeed;
DynamicHook HookItemIterateAttribute;
Handle g_hImpulse;
ArrayList RawEntityHooks;
ConVar sv_cheats;
int m_bOnlyIterateItemViewAttributes;
int m_Item;

ConVar tf_scout_air_dash_count;

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