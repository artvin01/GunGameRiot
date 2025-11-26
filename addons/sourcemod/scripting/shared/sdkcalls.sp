#pragma semicolon 1
#pragma newdecls required


static Handle SDKEquipWearable;
static Handle SDKGetMaxHealth;
static Handle g_hSetAbsAngle;
void SDKCall_Setup()
{
	GameData gamedata = LoadGameConfigFile("sm-tf2.games");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetVirtual(gamedata.GetOffset("RemoveWearable") - 1);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(!SDKEquipWearable)
		LogError("[Gamedata] Could not find RemoveWearable");
	
	delete gamedata;
	
	gamedata = LoadGameConfigFile("sdkhooks.games");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_ByValue);
	SDKGetMaxHealth = EndPrepSDKCall();
	if(!SDKGetMaxHealth)
		LogError("[Gamedata] Could not find GetMaxHealth");
		
	delete gamedata;


	gamedata = LoadGameConfigFile("zombie_riot");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::SetLocalOrigin");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	g_hSetLocalOrigin = EndPrepSDKCall();
	if(!g_hSetLocalOrigin)
		LogError("[Gamedata] Could not find CBaseEntity::SetLocalOrigin");
		
		
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::SetAbsAngles");
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	g_hSetAbsAngle = EndPrepSDKCall();
	if(!g_hSetAbsAngle)
		LogError("[Gamedata] Could not find CBaseEntity::SetAbsAngles");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBaseEntity::WorldSpaceCenter");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByRef);
	if ((g_hSDKWorldSpaceCenter = EndPrepSDKCall()) == null) SetFailState("Failed to create SDKCall for CBaseEntity::WorldSpaceCenter offset!");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::SetLocalAngles");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	g_hSetLocalAngles = EndPrepSDKCall();
	if(!g_hSetLocalAngles)
		LogError("[Gamedata] Could not find CBaseEntity::SetLocalOrigin");

	//CBasePlayer
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBasePlayer::SnapEyeAngles");
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	if ((g_hSnapEyeAngles = EndPrepSDKCall()) == null) SetFailState("Failed to create SDKCall for CBasePlayer::SnapEyeAngles!");


	//( const Vector &vecOrigin, const QAngle &vecAngles, const float fSpeed, const float fGravity, ProjectileType_t projectileType, CBaseEntity *pOwner, CBaseEntity *pScorer )
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFProjectile_Arrow::Create");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hCTFCreateArrow = EndPrepSDKCall();
	if(!g_hCTFCreateArrow)
		LogError("[Gamedata] Could not find CTFProjectile_Arrow::Create");

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CBasePlayer::CheatImpulseCommands");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); //Player
	g_hImpulse = EndPrepSDKCall();
	if(!g_hImpulse)
		LogError("[Gamedata] Could not find CBasePlayer::CheatImpulseCommands");
		
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::SetAbsVelocity");
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	if ((g_hSetAbsVelocity = EndPrepSDKCall()) == null) SetFailState("Failed to create SDKCall for CBaseEntity::SetAbsVelocity");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::SetAbsOrigin");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	g_hSetAbsOrigin = EndPrepSDKCall();
	if(!g_hSetAbsOrigin)
		LogError("[Gamedata] Could not find CBaseEntity::SetAbsOrigin");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CBaseEntity::SetAbsOrigin");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	g_hSetAbsOrigin = EndPrepSDKCall();
	if(!g_hSetAbsOrigin)
		LogError("[Gamedata] Could not find CBaseEntity::SetAbsOrigin");

		
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "Studio_FindAttachment");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	//pStudioHdr
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//pAttachmentName
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);	//return index
	if((g_hStudio_FindAttachment = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create Call for Studio_FindAttachment");

	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayerShared::RecalculatePlayerBodygroups");
	if((g_hRecalculatePlayerBodygroups = EndPrepSDKCall()) == INVALID_HANDLE) SetFailState("Failed to create Call for CTFPlayerShared::RecalculatePlayerBodygroups");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::TeamFortress_SetSpeed()");
	SDKSetSpeed = EndPrepSDKCall();
	if(!SDKSetSpeed)
		LogError("[Gamedata] Could not find CTFPlayer::TeamFortress_SetSpeed()");
}



void SDKCall_EquipWearable(int client, int entity)
{
	if(SDKEquipWearable)
		SDKCall(SDKEquipWearable, client, entity);
}

void SnapEyeAngles(int client, const float viewAngles[3])
{
	SDKCall(g_hSnapEyeAngles, client, viewAngles);
}

void GetAttachment(int index, const char[] szName, float absOrigin[3], float absAngles[3])
{
	GetEntityAttachment(index, FindAttachment(index, szName), absOrigin, absAngles);
}	


int FindAttachment(int index, const char[] pAttachmentName)
{
	Address pStudioHdr = GetStudioHdr(index);
	if(pStudioHdr == Address_Null)
		return -1;
			
	return SDKCall(g_hStudio_FindAttachment, pStudioHdr, pAttachmentName) + 1;
}	

public Address GetStudioHdr(int index)
{
	if(IsValidEntity(index))
	{
		return view_as<Address>(GetEntData(index, FindDataMapInfo(index, "m_flFadeScale") + 28));
	}
		
	return Address_Null;
}	
void SDKCall_SetSpeed(int client)
{
	if(SDKSetSpeed)
	{
		SDKCall(SDKSetSpeed, client);
	}
	else
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.001);
	}
}



void SDKCall_GiveCorrectAmmoCount(int client)
{
	//how quirky.
	SetAmmo(client, 1, 9999);
	SetAmmo(client, 2, 9999);
	SetAmmo(client, 3, 9999);
}


stock void Manual_Impulse_101(int client, int health)
{

	SetConVarInt(sv_cheats, 1, false, false);
	SDKCall(g_hImpulse, client, 101);
	SetConVarInt(sv_cheats, 0, false, false);
	SDKCall_GiveCorrectAmmoCount(client);

	OnWeaponSwitchPost(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));

	if(health > 0)
		SetEntityHealth(client, health);
}

stock void SDKCall_RecalculatePlayerBodygroups(int index)
{
	if(g_hRecalculatePlayerBodygroups)
	{
		SDKCall(g_hRecalculatePlayerBodygroups, GetPlayerSharedAddress(index));
	}
}

//https://github.com/nosoop/SM-TFUtils/blob/4802fa401a86d3088feb77c8a78d758c10806112/scripting/tf2utils.sp#L1067C1-L1067C1
static Address GetPlayerSharedAddress(int client) {
	return GetEntityAddress(client)
			+ view_as<Address>(FindSendPropInfo("CTFPlayer", "m_Shared"));
}



int SDKCall_GetMaxHealth(int client)
{
	return SDKGetMaxHealth ? SDKCall(SDKGetMaxHealth, client) : GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

int ReturnEntityMaxHealth(int entity)
{
	if(entity <= MaxClients)
	{
		return SDKCall_GetMaxHealth(entity);
	}
	return GetEntProp(entity, Prop_Data, "m_iMaxHealth");
}



void SDKCall_SetLocalOrigin(int index, float localOrigin[3])
{
	if(g_hSetLocalOrigin)
	{
		SDKCall(g_hSetLocalOrigin, index, localOrigin);
	}
}

stock int SDKCall_CTFCreateArrow(float VecOrigin[3], float VecAngles[3], const float fSpeed, const float fGravity, int projectileType, int Owner, int Scorer)
{
	if(g_hCTFCreateArrow)
		return SDKCall(g_hCTFCreateArrow, VecOrigin, VecAngles, fSpeed, fGravity, projectileType, Owner, Scorer);
	
	return -1;
}

stock void WorldSpaceCenter(int entity, float vecPos[3])
{
	SDKCall(g_hSDKWorldSpaceCenter, entity, vecPos);
}


void SDKCall_SetAbsOrigin(int index, float AbsOrigin[3])
{
	if(g_hSetAbsOrigin)
	{
		SDKCall(g_hSetAbsOrigin, index, AbsOrigin);
	}
}


void SDKCall_SetAbsAngle(int index, float AbsAngle[3])
{
	if(g_hSetAbsAngle)
	{
		SDKCall(g_hSetAbsAngle, index, AbsAngle);
	}
}
