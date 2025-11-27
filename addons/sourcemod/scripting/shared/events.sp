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
		
	CreateTimer(1.0, Timer_Respawn, GetClientUserId(victim));
	if(f_PreventKillCredit[victim] > GetGameTime())
	{
		return Plugin_Stop;
	}
	TF2_SetPlayerClass_ZR(victim, CurrentClass[victim], false, false);
	//am ded
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(b_DiedToFallDamage[victim])
	{
		int OverrideAttacker = EntRefToEntIndex(i_FallDamageKillCredit[victim]);
		if(IsValidClient(OverrideAttacker))
		{
			attacker = OverrideAttacker;
			event.GetInt("attacker", GetClientUserId(attacker));
		}
	}
	int assister = GetClientOfUserId(event.GetInt("assister"));

	bool RankUp = true;
	if(IsValidEntity(i_WeaponKilledWith[victim]))
	{
		if(Attributes_Get(i_WeaponKilledWith[victim], Attrib_DerankOnly, 0.0))
		{
			RankUp = false;
		}
	}
	b_DiedToFallDamage[victim] = false;
	i_FallDamageKillCredit[victim] = 0;
	i_WeaponKilledWith[victim] = 0;
	if(RankUp)
	{
		if(IsValidClient(attacker) && attacker != victim && GameRules_GetRoundState() <= RoundState_RoundRunning)
		{
			ClientKillsThisFrame[attacker]++;
			
			RequestFrame(DelayFrame_RankPlayerUp, GetClientUserId(attacker));
			if(i_HasBeenHeadShotted[victim])
			{
				EmitSoundToClient(victim, "quake/standard/headshot.mp3", _, _, 90, _, 1.0, 100);
				EmitSoundToClient(attacker, "quake/standard/headshot.mp3", _, _, 90, _, 1.0, 100);
			}
			
			if (assister && IsValidClient(assister) && assister != attacker && assister != victim && CanClientGetAssistCredit(assister))
			{
				ClientAssistsThisLevel[assister]++;
				if (ClientAssistsThisLevel[assister] == 2)
				{
					ClientKillsThisFrame[assister]++;
					RequestFrame(DelayFrame_RankPlayerUp, GetClientUserId(assister));
				}
			}
		}
	}
	else
	{
		CPrintToChat(attacker,"%s You just deranked %N!!!!", TGG_PREFIX, victim);
		CPrintToChat(victim,"%s %N just deranked you!!!!", TGG_PREFIX, attacker);
		EmitSoundToClient(victim, "mvm/mvm_money_vanish.wav", _, _, 90, _, 1.0, 100);
		EmitSoundToClient(attacker, "mvm/mvm_money_vanish.wav", _, _, 90, _, 1.0, 100);
		ClientAtWhatScore[victim]--;
		if(ClientAtWhatScore[victim] <= 0)
		{
			ClientAtWhatScore[victim] = 0;
		}
		//fard
	}
	i_HasBeenHeadShotted[victim] = false;
	return Plugin_Continue;
}

bool CanClientGetAssistCredit(int client)
{
	// Can't get assists on last rank
	return (ClientAtWhatScore[client] + 1 < Cvar_TGG_WeaponsTillWin.IntValue);
}

stock void DelayFrame_RankPlayerUp(int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidEntity(client))
		return;
	
	if (!ClientKillsThisFrame[client])
		return;
	
	// Only allow up to 3 levels per frame, in case an explosion kills a million people
	int levels = ClientKillsThisFrame[client];
	if (levels > 3)
		levels = 3;
	
	GiveClientWeapon(client, levels);
	ClientAssistsThisLevel[client] = 0;
	ClientKillsThisFrame[client] = 0;
	
	if(ClientAtWhatScore[client] >= Cvar_TGG_WeaponsTillWin.IntValue && GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		//epic win
		ClientAtWhatScore[client] = Cvar_TGG_WeaponsTillWin.IntValue;
		
		// Make this prettier later i dunno
		Native_OnWin(client);
		CPrintToChatAll("%s %N wins the game!", TGG_PREFIX, client);
		
		ForceTeamWin(TF2_GetClientTeam(client));
	}
}
public Action Timer_Respawn(Handle timer, any uuid)
{
	int client = GetClientOfUserId(uuid);
	if(!IsValidClient(client))
		return Plugin_Stop;

	if(IsPlayerAlive(client))
		return Plugin_Stop;
		
	if(f_RetryRespawn[client] > GetGameTime())
	{
		CreateTimer(0.1, Timer_Respawn, GetClientUserId(client));
		return Plugin_Stop;
	}
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
	
	TFTeam team = TF2_GetClientTeam(client);
	if (n_ForcedTeam >= TFTeam_Red && n_ForcedTeam != team)
	{
		// mp_humans_must_join_team kinda sucks, we have to force players to a team ourselves
		TF2_ForceTeamJoin(client, n_ForcedTeam, true);
		return;
	}

	//SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_BUILDING_STATUS | HIDEHUD_CLOAK_AND_FEIGN);
	TF2_RemoveAllWeapons(client); //Remove all weapons. No matter what.

	if(Cvar_TGG_AllowFreeClassPicking.IntValue)
		CurrentClass[client] = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"));

	ViewChange_DeleteHands(client);
	ViewChange_UpdateHands(client, CurrentClass[client]);
	TF2_SetPlayerClass_ZR(client, CurrentClass[client], false, false);
	

	
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
	RequestFrame(GiveWeaponLate, GetClientUserId(client));
	RequestFrame(Frame_GiveRoundStartConds, GetClientUserId(client));
	
	// Don't show name/health of players
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | HIDEHUD_TARGET_ID);
}

stock void GiveWeaponLate(int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidEntity(client))
		return;

	GiveClientWeapon(client);
}

void Frame_GiveRoundStartConds(int userid)
{
	float gameTime = GetGameTime();
	if (f_RoundStartUberLastsUntil <= gameTime)
		return;
	
	int client = GetClientOfUserId(userid);
	if(!IsValidEntity(client))
		return;
	
	TF2_AddCondition(client, TFCond_UberchargedCanteen, f_RoundStartUberLastsUntil - gameTime);
	
	if (b_DisableCollisionOnRoundStart)
		SetEntityCollisionGroup(client, TFCOLLISION_GROUP_COMBATOBJECT);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Weapons_ResetRound();
	
	// Set all spawnpoints to a specific team if humans can only join one team
	TFTeam team = TFTeam_Unassigned;
	char teamName[8];
	
	if (mp_humans_must_join_team)
	{
		mp_humans_must_join_team.GetString(teamName, sizeof(teamName));
		
		if (!StrContains(teamName, "red"))
			team = TFTeam_Red;
		else if (!StrContains(teamName, "blu"))
			team = TFTeam_Blue;
		
		RequestFrame(Frame_SetMapSpawnPointsPostTeamSwitch, team);
	}
	
	// Set up spawn über and player collision removal to last up to a certain time, even if players respawn/spawn late
	const float freezeTime = 5.0;
	const float extraUberTime = 1.5;
	
	float gameTime = GetGameTime();
	f_RoundStartUberLastsUntil = gameTime + freezeTime + extraUberTime;
	b_DisableCollisionOnRoundStart = false;
	
	int clients, spawnpoints;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			clients++;
			
			GiveClientWeapon(client, 0);
			TF2_AddCondition(client, TFCond_UberchargedCanteen, f_RoundStartUberLastsUntil - gameTime);
		}
	}
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != -1)
	{
		if (!GetEntProp(entity, Prop_Data, "m_bDisabled"))
			spawnpoints++;
	}
	
	// Only disable collisions if there are more players than spawnpoints
	if (clients > spawnpoints)
	{
		b_DisableCollisionOnRoundStart = true;
		CreateTimer(freezeTime + extraUberTime, Timer_EnableCollision, _, TIMER_FLAG_NO_MAPCHANGE);
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && IsPlayerAlive(client))
			{
				SetEntityCollisionGroup(client, TFCOLLISION_GROUP_COMBATOBJECT);
			}
		}
	}
}

Action Timer_EnableCollision(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && IsPlayerAlive(client))
		{
			SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);
		}
	}
	
	return Plugin_Continue;
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