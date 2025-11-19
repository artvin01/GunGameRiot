#pragma semicolon 1
#pragma newdecls required

void Events_PluginStart()
{
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("post_inventory_application", OnPlayerResupply, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}



public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(!victim)
		return Plugin_Continue;
	TF2_SetPlayerClass_ZR(victim, CurrentClass[victim], false, false);
	//am ded
	RequestFrame(Respawn, GetClientUserId(victim));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(IsValidClient(attacker))
	{
		if(i_HasBeenHeadShotted[victim])
		{
			EmitSoundToClient(victim, "quake/standard/headshot.mp3", _, _, 90, _, 1.0, 100);
			EmitSoundToClient(attacker, "quake/standard/headshot.mp3", _, _, 90, _, 1.0, 100);
		}
	}
	i_HasBeenHeadShotted[victim] = false;
	return Plugin_Continue;
}
public void Respawn(int uuid)
{
	int client = GetClientOfUserId(uuid);
	if(!IsValidClient(client))
		return;

	if(IsPlayerAlive(client))
		return;
		
	int team = GetClientTeam(client);
	if(team <= 1)
		return;
	TF2_RespawnPlayer(client);
}
public void OnPlayerResupply(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(!client)
		return;

	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_BUILDING_STATUS | HIDEHUD_CLOAK_AND_FEIGN);
	TF2_RemoveAllWeapons(client); //Remove all weapons. No matter what.

	CurrentClass[client] = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"));

	ViewChange_DeleteHands(client);
	ViewChange_UpdateHands(client, CurrentClass[client]);
	TF2_SetPlayerClass_ZR(client, CurrentClass[client], false, false);
	
	if(b_HideCosmeticsPlayer[client])
	{
		int entity = MaxClients+1;
		while(TF2_GetWearable(client, entity))
		{
			SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects") | EF_NODRAW);
		}
	}

	
	int entity = MaxClients+1;
	while(TF2_GetWearable(client, entity))
	{
		switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
		{
			case 57, 131, 133, 231, 405, 406, 444, 608, 642, 1099, 1144:
				TF2_RemoveWearable(client, entity);
		}
	}

	ViewChange_PlayerModel(client);
	ViewChange_Update(client);
	Weapons_ApplyAttribs(client);
	SDKCall_GiveCorrectAmmoCount(client);
	GiveClientWeapon(client);
}



public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Weapons_ResetRound();
}

void OnTFPlayerManagerThinkPost(int entity)
{
	static int scoreOffset = -1;
	if (scoreOffset == -1)
		scoreOffset = FindSendPropInfo("CTFPlayerResource", "m_iTotalScore");
	
	int playerScores[MAXPLAYERS + 1];
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
			playerScores[client] = ClientAtWhatScore[client];
	}
	
	SetEntDataArray(entity, scoreOffset, playerScores, MaxClients + 1);
}