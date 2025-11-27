#pragma semicolon 1
#pragma newdecls required

enum struct CvarInfo
{
	ConVar cvar;
	char value[16];
	char defaul[16];
	int OldFlags;
	int FlagsToDelete;
	bool enforce;
}

static ArrayList CvarList;
static ArrayList CvarMapList;
static bool CvarEnabled;

void ConVar_ConfigsExecuted()
{
	CvarList = new ArrayList(sizeof(CvarInfo));

	sv_cheats = ConVar_Add("sv_cheats", "0", false, (FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_CHEAT));
	mp_friendlyfire = ConVar_Add("mp_friendlyfire", "1", true, (FCVAR_NOTIFY | FCVAR_CHEAT));
	tf_scout_air_dash_count = ConVar_Add("tf_scout_air_dash_count", "0", false); 
	mp_humans_must_join_team = ConVar_Add("mp_humans_must_join_team", "red"); 	//only reds allowed

	Cvar_TGG_WeaponsTillWin = CreateConVar("tgg_weapons_till_win", "25", "How many kills untill a player wins");
	Cvar_TGG_AllowFreeClassPicking = CreateConVar("tgg_allowfreeclasspicking", "0", "are players allowed to have classes for vanity");
	ConVar_Add("tf_weapon_criticals_distance_falloff", "1.0"); //Remove crits
	ConVar_Add("tf_weapon_minicrits_distance_falloff", "1.0"); //Remove crits
	ConVar_Add("tf_weapon_criticals", "0.0");			//Remove crits
	ConVar_Add("tf_weapon_criticals_melee", "0.0");		//Remove crits
	ConVar_Add("tf_avoidteammates_pushaway", "0"); 
	ConVar_Add("tf_dropped_weapon_lifetime", "0.0"); 	//Remove dropped weapons
	ConVar_Add("tf_spawn_glows_duration", "0.0"); 		//No glow duration
	ConVar_Add("tf_avoidteammates", "0.0"); 			//always touch
	ConVar_Add("mp_autoteambalance", "0"); 				//balance
	ConVar_Add("mp_teams_unbalance_limit", "0"); 		//balance
	ConVar_ToggleDo();

}

static ConVar ConVar_Add(const char[] name, const char[] value, bool enforce=true, int flagsremove = FCVAR_CHEAT)
{
	CvarInfo info;
	info.cvar = FindConVar(name);
	info.OldFlags = info.cvar.Flags;
	info.cvar.Flags &= ~(flagsremove);
	info.FlagsToDelete = flagsremove;
	strcopy(info.value, sizeof(info.value), value);
	info.enforce = enforce;

	if(CvarEnabled)
		info.cvar.GetString(info.defaul, sizeof(info.defaul));

	CvarList.PushArray(info);
	
	if(CvarEnabled)
	{
		info.cvar.AddChangeHook(ConVar_OnChanged);
		if(value[0])
			info.cvar.SetString(info.value);
	}
	
	return (info.cvar);
}

stock void ConVar_AddTemp(const char[] name, const char[] value, bool enforce=true)
{
	CvarInfo info;
	info.cvar = FindConVar(name);
	if(!info.cvar)
	{
		LogError("Invalid cvar \"%s\" from being set from config", name);
		return;
	}
	
	if(info.cvar.Flags & FCVAR_PROTECTED)
	{
		LogError("Blocked \"%s\" from being set from config", name);
		return;
	}
	
	info.OldFlags = info.cvar.Flags;
	info.cvar.Flags &= ~FCVAR_CHEAT;
	strcopy(info.value, sizeof(info.value), value);
	info.enforce = enforce;

	if(CvarEnabled)
		info.cvar.GetString(info.defaul, sizeof(info.defaul));

	if(!CvarMapList)
		CvarMapList = new ArrayList(sizeof(CvarInfo));

	CvarMapList.PushArray(info);
	
	if(CvarEnabled)
	{
		info.cvar.AddChangeHook(ConVar_OnChanged);
		if(value[0])
			info.cvar.SetString(info.value);
	}
}

stock void ConVar_RemoveTemp(const char[] name)
{
	if(CvarMapList)
	{
		ConVar cvar = FindConVar(name);
		int index = CvarMapList.FindValue(cvar, CvarInfo::cvar);
		if(index != -1)
		{
			CvarInfo info;
			CvarMapList.GetArray(index, info);
			CvarMapList.Erase(index);

			if(CvarEnabled)
			{
				info.cvar.RemoveChangeHook(ConVar_OnChanged);
				info.cvar.SetString(info.defaul);
			}
		}
	}
}

//its better to-inforce the flags.
void ConVar_ToggleDo()
{
	if(!CvarList)
		return;
	CvarInfo info;
	int length = CvarList.Length;
	for(int i; i<length; i++)
	{
		CvarList.GetArray(i, info);
		info.cvar.Flags &= ~(info.FlagsToDelete);
		CvarList.SetArray(i, info);
	}
}
void ConVar_Enable()
{
	if(!CvarEnabled)
	{
		CvarInfo info;
		int length = CvarList.Length;
		for(int i; i<length; i++)
		{
			CvarList.GetArray(i, info);
			info.cvar.GetString(info.defaul, sizeof(info.defaul));
			CvarList.SetArray(i, info);
			
			if(info.value[0])
				info.cvar.SetString(info.value);

			info.cvar.AddChangeHook(ConVar_OnChanged);
		}

		if(CvarMapList)
		{
			length = CvarMapList.Length;
			for(int i; i<length; i++)
			{
				CvarMapList.GetArray(i, info);
				info.cvar.GetString(info.defaul, sizeof(info.defaul));
				CvarMapList.SetArray(i, info);

				if(info.value[0])
					info.cvar.SetString(info.value);
					
				info.cvar.AddChangeHook(ConVar_OnChanged);
			}
		}

		CvarEnabled = true;
	}
}

void ConVar_Disable()
{
	if(CvarEnabled)
	{
		CvarInfo info;
		int length = CvarList.Length;
		for(int i; i<length; i++)
		{
			CvarList.GetArray(i, info);
			info.cvar.RemoveChangeHook(ConVar_OnChanged);
			info.cvar.SetString(info.defaul);
			info.cvar.Flags = info.OldFlags;
		}

		if(CvarMapList)
		{
			length = CvarMapList.Length;
			for(int i; i<length; i++)
			{
				CvarMapList.GetArray(i, info);

				info.cvar.RemoveChangeHook(ConVar_OnChanged);
				info.cvar.SetString(info.defaul);
				info.cvar.Flags = info.OldFlags;
			}

			delete CvarMapList;
		}

		CvarEnabled = false;
	}
}

public void ConVar_OnChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	CvarInfo info;
	int index = CvarList.FindValue(cvar, CvarInfo::cvar);
	if(index != -1)
	{
		CvarList.GetArray(index, info);

		if(!StrEqual(newValue, info.value))
		{
			if(info.enforce)
			{
				strcopy(info.defaul, sizeof(info.defaul), newValue);
				CvarList.SetArray(index, info);
				info.cvar.SetString(info.value);
			}
		}
	}

	if(CvarMapList)
	{
		int index2 = CvarMapList.FindValue(cvar, CvarInfo::cvar);
		if(index2 != -1)
		{
			CvarMapList.GetArray(index2, info);

			if(!StrEqual(newValue, info.value))
			{
				if(info.enforce)
				{
					strcopy(info.defaul, sizeof(info.defaul), newValue);
					CvarMapList.SetArray(index2, info);
					info.cvar.SetString(info.value);
				}
			}
		}
	}
}


stock void Convars_FixClientsideIssues(int client)
{
	SendConVarValue(client, tf_scout_air_dash_count, "1");
	//set to 1 for a frame...
	DataPack pack = new DataPack();
	pack.WriteCell(EntIndexToEntRef(client));
	RequestFrame(Convars_FixClientsideIssuesFrameAfter, pack);
}
stock void Convars_FixClientsideIssuesFrameAfter(DataPack pack)
{
	pack.Reset();
	int client = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidEntity(client))
	{
		delete pack;
		return;
	}

	//set to 0 afterwards.
	SendConVarValue(client, tf_scout_air_dash_count, "0");
	delete pack;
}
