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
	CreateTimer(1.0, Timer_Respawn, GetClientUserId(victim));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(IsValidClient(attacker) && attacker != victim)
	{
		GiveClientWeapon(attacker, 1);
		if(i_HasBeenHeadShotted[victim])
		{
			EmitSoundToClient(victim, "quake/standard/headshot.mp3", _, _, 90, _, 1.0, 100);
			EmitSoundToClient(attacker, "quake/standard/headshot.mp3", _, _, 90, _, 1.0, 100);
		}
		
		if(ClientAtWhatScore[attacker] >= Cvar_GGR_WeaponsTillWin.IntValue && GameRules_GetRoundState() == RoundState_RoundRunning)
		{
			//epic win
			ClientAtWhatScore[attacker] = Cvar_GGR_WeaponsTillWin.IntValue;
			
			// Make this prettier later i dunno
			PrintToChatAll("%N wins the game!", attacker);
			
			ForceTeamWin(TF2_GetClientTeam(attacker));
		}
	}
	i_HasBeenHeadShotted[victim] = false;
	return Plugin_Continue;
}
public Action Timer_Respawn(Handle timer, any uuid)
{
	int client = GetClientOfUserId(uuid);
	if(!IsValidClient(client))
		return Plugin_Stop;

	if(IsPlayerAlive(client))
		return Plugin_Stop;
		
	int team = GetClientTeam(client);
	if(team <= 1)
		return Plugin_Stop;
	TF2_RespawnPlayer(client);
	TF2_AddCondition(client, TFCond_UberchargedCanteen, 1.0);
	TF2_AddCondition(client, TFCond_MegaHeal, 1.0);
	return Plugin_Stop;
}
public void OnPlayerResupply(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(!client)
		return;

	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_BUILDING_STATUS | HIDEHUD_CLOAK_AND_FEIGN);
	TF2_RemoveAllWeapons(client); //Remove all weapons. No matter what.

	if(Cvar_GGR_AllowFreeClassPicking.IntValue)
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
	
	const float flFreezeTime = 5.0;
	float gameTime = GetGameTime();
	f_RoundStartUberLastsUntil = gameTime + flFreezeTime + 1.0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			GiveClientWeapon(client, 0);
			TF2_AddCondition(client, TFCond_UberchargedCanteen, f_RoundStartUberLastsUntil - gameTime);
		}
	}
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