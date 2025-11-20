#pragma semicolon 1
#pragma newdecls required



enum struct ItemInfo
{
	char WeaponName[256];
	bool HasNoClip;
	int Reload_ModeForce;
	float WeaponScore;
	char Classname[36];
	char WeaponHudExtra[16];
	char Desc[256];
	int CustomWeaponOnEquip;

	int Index;
	int Attrib[32];
	float Value[32];
	int Attribs;
	float WeaponSizeOverride;
	float WeaponSizeOverrideViewmodel;
	char WeaponModelOverride[128];
	int Weapon_Bodygroup;
	int WeaponModelIndexOverride;
	int WeaponForceClass;
	int Ammo;
	float Cooldown[3];

	Function FuncAttack;
	Function FuncAttack2;
	Function FuncAttack3;
	Function FuncReload4;
	Function FuncWeaponCreated;
	void Self(ItemInfo info)
	{
		info = this;
	}

	
	bool SetupKV(KeyValues kv, const char[] name, const char[] prefix="")
	{
		static char buffer[512];
		
		Format(buffer, sizeof(buffer), "%sdesc", prefix);
		kv.GetString(buffer, this.Desc, 256);
		
		Format(buffer, sizeof(buffer), "%sclassname", prefix);
		kv.GetString(buffer, this.Classname, 36);
		Format(buffer, sizeof(buffer), "%sscore", prefix);
		this.WeaponScore = kv.GetFloat(buffer, 0.0);
		
		Format(buffer, sizeof(buffer), "%sindex", prefix);
		this.Index = kv.GetNum(buffer);
		
		Format(buffer, sizeof(buffer), "%sreload_mode", prefix);
		this.Reload_ModeForce = kv.GetNum(buffer);
		
		Format(buffer, sizeof(buffer), "%sviewmodel_force_class", prefix);
		this.WeaponForceClass			= kv.GetNum(buffer, 0);

		Format(buffer, sizeof(buffer), "%sno_clip", prefix);
		this.HasNoClip				= view_as<bool>(kv.GetNum(buffer));
		
		Format(buffer, sizeof(buffer), "%sammo", prefix);
		this.Ammo = kv.GetNum(buffer);

		Format(buffer, sizeof(buffer), "%smodel_weapon_override", prefix);
		kv.GetString(buffer, this.WeaponModelOverride, sizeof(buffer));

		Format(buffer, sizeof(buffer), "%sweapon_bodygroup", prefix);
		this.Weapon_Bodygroup	= kv.GetNum(buffer, -1);

		Format(buffer, sizeof(buffer), "%sweapon_custom_size", prefix);
		this.WeaponSizeOverride			= kv.GetFloat(buffer, 1.0);

		Format(buffer, sizeof(buffer), "%sweapon_custom_size_viewmodel", prefix);
		this.WeaponSizeOverrideViewmodel			= kv.GetFloat(buffer, 1.0);

		if(this.WeaponModelOverride[0])
		{
			this.WeaponModelIndexOverride = PrecacheModel(this.WeaponModelOverride, true);
		}
		else
		{
			this.WeaponModelIndexOverride = 0;
		}
	
		
		Format(buffer, sizeof(buffer), "%sfunc_attack", prefix);
		kv.GetString(buffer, buffer, sizeof(buffer));
		this.FuncAttack = GetFunctionByName(null, buffer);
		
		Format(buffer, sizeof(buffer), "%sfunc_attack2", prefix);
		kv.GetString(buffer, buffer, sizeof(buffer));
		this.FuncAttack2 = GetFunctionByName(null, buffer);
		
		Format(buffer, sizeof(buffer), "%sfunc_attack3", prefix);
		kv.GetString(buffer, buffer, sizeof(buffer));
		this.FuncAttack3 = GetFunctionByName(null, buffer);
		
		Format(buffer, sizeof(buffer), "%sfunc_attack4", prefix);
		kv.GetString(buffer, buffer, sizeof(buffer));
		this.FuncReload4 = GetFunctionByName(null, buffer);

		Format(buffer, sizeof(buffer), "%sfunc_weapon_created", prefix);
		kv.GetString(buffer, buffer, sizeof(buffer));
		this.FuncWeaponCreated = GetFunctionByName(null, buffer);

		Format(buffer, sizeof(buffer), "%sweapon_hud_extra", prefix);
		kv.GetString(buffer, this.WeaponHudExtra, sizeof(buffer));
		
		
		static char buffers[64][16];
		Format(buffer, sizeof(buffer), "%sattributes", prefix);
		kv.GetString(buffer, buffer, sizeof(buffer));
		this.Attribs = ExplodeString(buffer, ";", buffers, sizeof(buffers), sizeof(buffers[])) / 2;
		for(int i; i < this.Attribs; i++)
		{
			this.Attrib[i] = StringToInt(buffers[i*2]);
			if(!this.Attrib[i])
			{
				LogMessage("Found invalid attribute on '%s'", name);
				this.Attribs = i;
				break;
			}
			
			this.Value[i] = StringToFloat(buffers[i*2+1]);
		}


		return true;
	}
}
/*
	"weapons"
	{
		"SMG"	//Weapon name for inside and translations
		{
			"score"							"1.0"										 //1.0 means its pretty very OP, 0.0 means its very garbage
			"classname"						"tf_weapon_bonesaw"
			"attributes"					"2 ; 2.2 ; 6 ; 0.7"
			"index"							"198"   


			"func_attack"					"Fusion_Melee_Empower_StatePre"		//m1 attack
			//idealy these shouldnt be used often
			"func_attack2"					"Fusion_Melee_Empower_StatePre"		//m2
			"func_attack2"					"Fusion_Melee_Empower_StatePre"		//R
			"func_attack4"					"Fusion_Melee_Empower_StatePre"		//M3??

			"model_weapon_override"			"models/zombie_riot/weapons/custom_weaponry_1_52.mdl"
			"weapon_bodygroup"				"1024"
			"weapon_custom_size_viewmodel"  "0.8"
			"weapon_custom_size"			"1.4"
			"ability_onequip"				"0"	
			"no_clip"						"0"
 			"reload_mode"					"1"  //1 means entire clip, 2 means one at a time. default is whatever the weapon had as a norm.
			//This will override the weapon third and first person model.
			"viewmodel_force_class"		"8"
		}

	}

*/
static ArrayList WeaponList;
void Weapons_ConfigsExecuted()
{
	if(WeaponList)
		delete WeaponList;
	
	WeaponList = new ArrayList(sizeof(ItemInfo));
	
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), CONFIG_CFG, "weapons");
	KeyValues kv = new KeyValues("Weapons");
	kv.SetEscapeSequences(true);
	kv.ImportFromFile(buffer);

	
	kv.GotoFirstSubKey();
	do
	{
		ConfigSetup(kv);
	} 
		while(kv.GotoNextKey());
	delete kv;
}


static void ConfigSetup(KeyValues kv)
{
	int Score = kv.GetNum("score", -1);
	if(Score == -1)
	{
		return;
	}
	ItemInfo info;
	kv.GetSectionName(info.WeaponName, sizeof(info.WeaponName));
	info.WeaponName[0] = CharToUpper(info.WeaponName[0]);
	info.SetupKV(kv, info.WeaponName);
	WeaponList.PushArray(info);
	//Register all weapons currently in the config
}


int Weapons_GiveSpecificItem(int client, const char[] name)
{
	static ItemInfo info;
	int length = WeaponList.Length;
	for(int i; i<length; i++)
	{
		WeaponList.GetArray(i, info);

		if(StrEqual(name, info.WeaponName, false))
		{
			int entity = Weapons_GiveItem(client, i);
			Manual_Impulse_101(client, GetClientHealth(client));
			return entity;
		}
	}
	
	ThrowError("Unknown item name %s", name);
	return -1;
}




int Weapons_GiveItem(int client, int index, bool &use=false, bool &found=false)
{
	if(!WeaponList)
	{
		return -1;
	}
	if(!IsPlayerAlive(client))
	{
		return -1; //STOP. BAD!
	}
	//incase.
	TF2_RemoveCondition(client, TFCond_Taunting);
	int entity = -1;
	static ItemInfo info;

	int length = WeaponList.Length;

	if(index > -1 && index < length)
	{
		WeaponList.GetArray(index, info);
		if(info.Classname[0])
		{
			int saveslot = TF2_GetClassnameSlot(info.Classname);

			int GiveWeaponIndex = info.Index;
			int class = info.WeaponForceClass;

			if(GiveWeaponIndex > 0)
			{
				entity = SpawnWeapon(client, info.Classname, GiveWeaponIndex, 5, 6, info.Attrib, info.Value, info.Attribs, class);	
				
				i_SavedActualWeaponSlot[entity] = saveslot;
				
				HidePlayerWeaponModel(client, entity, true);

			}
			else
			{
				PrintToChatAll("Somehow have an invalid GiveWeaponIndex!!!!! [%i] report to admin now!",GiveWeaponIndex);
				LogMessage("Weapon Spawned thats bad!");
				LogMessage("Name of client %N and index %i",client,client);
				LogMessage("info.Classname: %s",info.Classname);
				LogMessage("info.Attrib: %s",info.Attrib);
				LogMessage("info.Value: %s",info.Value);
				LogMessage("info.Attribs: %s",info.Attribs);
				ThrowError("Somehow have an invalid GiveWeaponIndex!!!!! [%i] info.Classname %s ",GiveWeaponIndex,info.Classname);
			}

			StoreWeapon[entity] = index;
			
			if(entity > MaxClients)
			{
				if(info.CustomWeaponOnEquip != 0)
				{
					i_CustomWeaponEquipLogic[entity] = info.CustomWeaponOnEquip;
				}
			
				
				if(info.Ammo > 0)
				{
					SetEntProp(entity, Prop_Send, "m_iPrimaryAmmoType", info.Ammo);
				}
				i_Hex_WeaponUsesTheseAbilities[entity] = 0;
	
				if(info.FuncAttack != INVALID_FUNCTION)
				{
					i_Hex_WeaponUsesTheseAbilities[entity] |= ABILITY_M1; //m1 status to weapon
				}
				if(info.FuncAttack2 != INVALID_FUNCTION)
				{
					i_Hex_WeaponUsesTheseAbilities[entity] |= ABILITY_M2; //m2 status to weapon
				}
				if(info.FuncAttack3 != INVALID_FUNCTION)
				{
					i_Hex_WeaponUsesTheseAbilities[entity] |= ABILITY_R;  //R status to weapon
				}
				Format(c_WeaponUseAbilitiesHud[entity],sizeof(c_WeaponUseAbilitiesHud[]),"%s",info.WeaponHudExtra);	
				
				i_WeaponForceClass[entity] 				= class;
				i_WeaponModelIndexOverride[entity] 		= info.WeaponModelIndexOverride;

				f_WeaponSizeOverride[entity]			= info.WeaponSizeOverride;
				f_WeaponSizeOverrideViewmodel[entity]	= info.WeaponSizeOverrideViewmodel;
				
				i_WeaponBodygroup[entity] 				= info.Weapon_Bodygroup;

				EntityFuncAttack[entity] = info.FuncAttack;
				EntityFuncAttack2[entity] = info.FuncAttack2;
				EntityFuncAttack3[entity] = info.FuncAttack3;
				EntityFuncReload4[entity]  = info.FuncReload4;
				EntityFuncReloadCreate [entity]  = info.FuncWeaponCreated;
				



				if (info.Reload_ModeForce == 1)
				{
				//	SetWeaponViewPunch(entity, 100.0); unused.
					SetEntProp(entity, Prop_Data, "m_bReloadsSingly", 0);
				}
				else if (info.Reload_ModeForce == 2)
				{
					SetEntProp(entity, Prop_Data, "m_bReloadsSingly", 1);
				}

				if(use)
				{
					Weapons_SwapToItem(client, entity);
					use = false;
				}
			}
		}
	}
	
	bool EntityIsAWeapon = false;
	if(entity > MaxClients)
	{
		EntityIsAWeapon = true;
	}

	if(EntityIsAWeapon)
	{
		/*
			Attributes to Arrays Here
		*/

		if(Attributes_Get(entity, 4015, 0.0) >= 1.0)
		{
			SetEntPropFloat(entity, Prop_Send, "m_flNextPrimaryAttack", FAR_FUTURE);
		}
		if(Attributes_Get(entity, Attrib_SetSecondaryDelayInf, 0.0) >= 1.0)
		{
			SetEntPropFloat(entity, Prop_Send, "m_flNextSecondaryAttack", FAR_FUTURE);
		}

	}

	ViewChange_PlayerModel(client);
	ViewChange_Update(client);
	return entity;
}



void Weapons_SwapToItem(int client, int swap, bool SwitchDo = true)
{
	if(swap == -1)
		return;
	
	char classname[36], buffer[36];
	GetEntityClassname(swap, classname, sizeof(classname));

	int slot = TF2_GetClassnameSlot(classname, swap);
	
	int length = GetMaxWeapons(client);
	for(int i; i < length; i++)
	{
		if(GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i) == swap)
		{
			for(int a; a < length && a != i; a++)
			{
				int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", a);
				if(weapon > MaxClients)
				{
					GetEntityClassname(weapon, buffer, sizeof(buffer));
					if(TF2_GetClassnameSlot(buffer, weapon) == slot)
					{
						SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", swap, a);
						SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", weapon, i);
						break;
					}
				}
			}
		}
	}
	if(SwitchDo)
		SetPlayerActiveWeapon(client, swap);
	int WeaponValidCheck = 0;

	//make sure to fake swap aswell!
	while(WeaponValidCheck != swap)
	{
		WeaponValidCheck = Weapons_CycleItems(client, slot);
		if(WeaponValidCheck == -1)
			break;
	}
}


// Returns the top most weapon (or -1 for no change)
int Weapons_CycleItems(int client, int slot, bool ChangeWeapon = true)
{
	char buffer[36];
	
	int topWeapon = -1;
	int firstWeapon = -1;
	int previousIndex = -1;
	int length = GetMaxWeapons(client);
	for(int i; i < length; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if(weapon != -1)
		{
			GetEntityClassname(weapon, buffer, sizeof(buffer));
			if(TF2_GetClassnameSlot(buffer, weapon) == slot)
			{
				if(firstWeapon == -1)
					firstWeapon = weapon;

				if(previousIndex != -1)
				{
					// Replace this weapon with the previous slot (1 <- 2)
					if(ChangeWeapon)
						SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", weapon, previousIndex);
					if(topWeapon == -1)
						topWeapon = weapon;
				}

				previousIndex = i;
			}
		}
	}

	if(firstWeapon != -1)
	{
		// First to Last (7 <- 0)
		if(ChangeWeapon)
			SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", firstWeapon, previousIndex);
	}

	return topWeapon;
}



void Weapons_ApplyAttribs(int client)
{
	if(!WeaponList)
		return;

	Attributes_RemoveAll(client);
	
	TFClassType ClassForStats = WeaponClass[client];
	
	StringMap map = new StringMap();


	float HealthDoLogic = RemoveExtraHealth(ClassForStats, 0.1);
	map.SetValue("125", HealthDoLogic);
	map.SetValue("26", (200.0));		// Health

	map.SetValue("343", 1.0); //sentry attackspeed fix
	map.SetValue("526", 1.0);//
	map.SetValue("4049", 1.0);// Elemental Res

	map.SetValue("442", 1.0);	// Move Speed
	map.SetValue("49", 1);		// no doublejumps

	map.SetValue("740", 0.0);	// No Healing from mediguns, allow healing from pickups
	if(f_PreventMovementClient[client] > GetGameTime())
	{
		map.SetValue("819", 1.0);
		map.SetValue("820", 1.0);
		map.SetValue("821", 1.0);
		map.SetValue("107", 0.001);
		map.SetValue("698", 1.0);
		//try prevent.
	}
	else
	{
		float MovementSpeed = 400.0;
		
		map.SetValue("107", RemoveExtraSpeed(ClassForStats, MovementSpeed));		// Move Speed
	}


	float value;
	char buffer1[12];
	StringMapSnapshot snapshot = map.Snapshot();
	int length = snapshot.Length;
	int attribs = 0;
	for(int i; i < length; i++)
	{

		snapshot.GetKey(i, buffer1, sizeof(buffer1));
		if(map.GetValue(buffer1, value))
		{
			int index = StringToInt(buffer1);

			if(Attributes_Set(client, index, value))
				attribs++;

		}
	}
	
	delete snapshot;
	delete map;
	TF2_AddCondition(client, TFCond_Dazed, 0.001);
}



enum struct WeaponInfo
{
	int InternalWeaponID;
	float ScoreSave;
}
static ArrayList WeaponListRound;
void Weapons_ResetRound()
{
	Zero(ClientAtWhatScore);
	
	if(WeaponListRound)
		delete WeaponListRound;
	
	WeaponListRound = new ArrayList(sizeof(WeaponInfo));
	

	int length = WeaponList.Length;

		
	int WeaponsPick;
	int[] WeaponsPicking = new int[length];

	for(int i; i<length; i++)
	{
		//Pick up All weapons
		WeaponsPicking[WeaponsPick++] = i;
	}

	SortIntegers(WeaponsPicking, length, Sort_Random);
	
	int MaxWeapons = Cvar_GGR_WeaponsTillWin.IntValue;
	if(MaxWeapons > length)
	{
		Cvar_GGR_WeaponsTillWin.IntValue = length;
		MaxWeapons = length;
	}
	
	WeaponInfo Weplist;
	ItemInfo info;
	for(int i; i<MaxWeapons; i++)
	{
		Weplist.InternalWeaponID = WeaponsPicking[i];
		WeaponList.GetArray(WeaponsPicking[i], info);
		Weplist.ScoreSave = info.WeaponScore;
		
		WeaponListRound.PushArray(Weplist);
	}
	WeaponListRound.SortCustom(SortScoresWeapons);
}
public int SortScoresWeapons(int iIndex1, int iIndex2, Handle hMap, Handle hHandle)
{
    float Score1 = GetArrayCell(hMap, iIndex1, WeaponInfo::ScoreSave);
    float Score2 = GetArrayCell(hMap, iIndex2, WeaponInfo::ScoreSave);
    
    return (Score1 < Score2);
}


void GiveClientWeapon(int client, int Upgrade = 0)
{
	if(!WeaponListRound)
		return;

	int GiveWeapon = ClientAtWhatScore[client];
	GiveWeapon += Upgrade;
	ClientAtWhatScore[client] = GiveWeapon;
	
	// Don't give a weapon if we're beyond the max rank
	if(GiveWeapon >= Cvar_GGR_WeaponsTillWin.IntValue)
		return;
	
	if (Upgrade >= 1)
		EmitSoundToClient(client, SOUND_LEVELUP, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
	
	WeaponInfo Weplist;
	WeaponListRound.GetArray(GiveWeapon, Weplist);
	
	RemoveAllWeapons(client);
	Weapons_GiveItem(client, Weplist.InternalWeaponID);
	Manual_Impulse_101(client, ReturnEntityMaxHealth(client));
	SDKCall_GiveCorrectAmmoCount(client);
	RequestFrames(GiveHealth, 1, GetClientUserId(client));
}


public void GiveHealth(int uuid)
{
	int client = GetClientOfUserId(uuid);
	if(!IsValidClient(client))
		return;

	if(!IsPlayerAlive(client))
		return;
		
	int team = GetClientTeam(client);
	if(team <= 1)
		return;
	Manual_Impulse_101(client, ReturnEntityMaxHealth(client));
	SDKCall_GiveCorrectAmmoCount(client);
}
