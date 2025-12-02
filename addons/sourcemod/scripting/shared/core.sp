#pragma semicolon 1
#pragma newdecls required

#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>
#include <dhooks>
#undef AUTOLOAD_EXTENSIONS
#tryinclude <tf2items>
#define AUTOLOAD_EXTENSIONS
#include <tf_econ_data>

#include <tf2attributes>
#include <morecolors>
#include <tf2utils>
#include <cbasenpc>
#include <collisionhook>
//#include <sourcescramble>
//#include <handledebugger>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#define CONFIG_CFG	CONFIG ... "/%s.cfg"

#define MAXENTITIES 2048
#pragma dynamic	131072

#define ABILITY_NONE				 0		  	//Nothing special.
#define ABILITY_M1				(1 << 1) 
#define ABILITY_M2				(1 << 2) 
#define ABILITY_R				(1 << 3) 	

#define	HIDEHUD_WEAPONSELECTION		( 1<<0 )	// Hide ammo count & weapon selection
#define	HIDEHUD_FLASHLIGHT			( 1<<1 )
#define	HIDEHUD_ALL					( 1<<2 )
#define HIDEHUD_HEALTH				( 1<<3 )	// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD			( 1<<4 )	// Hide when local player's dead
#define HIDEHUD_NEEDSUIT			( 1<<5 )	// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS			( 1<<6 )	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT				( 1<<7 )	// Hide all communication elements (saytext, voice icon, etc)
#define	HIDEHUD_CROSSHAIR			( 1<<8 )	// Hide crosshairs
#define	HIDEHUD_VEHICLE_CROSSHAIR	( 1<<9 )	// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE			( 1<<10 )
#define HIDEHUD_BONUS_PROGRESS		( 1<<11 )	// Hide bonus progress display (for bonus map challenges)
#define HIDEHUD_BUILDING_STATUS		( 1<<12 )  
#define HIDEHUD_CLOAK_AND_FEIGN		( 1<<13 )   
#define HIDEHUD_PIPES_AND_CHARGE		( 1<<14 )	
#define HIDEHUD_METAL		( 1<<15 )	
#define HIDEHUD_TARGET_ID		( 1<<16 )	

#define SOUND_LEVELUP "turbo_gungame/levelup.mp3"
#define SOUND_FINALLEVEL "ui/duel_challenge_accepted_with_restriction.wav"

enum struct SpawnPointInfo
{
	int ref;
	TFTeam originalTeam;
}

#include "global_arrays.sp"
#include "stocks_override.sp"
#include "stocks.sp"
#include "weapons.sp"
#include "configs.sp"
#include "console.sp"
#include "viewchanges.sp"
#include "attributes.sp"
#include "sdkcalls.sp"
#include "dhooks.sp"
#include "events.sp"
#include "sdkhooks.sp"
#include "convars.sp"
#include "wand_projectile.sp"
#include "natives.sp"


#include "weapons/weapon_boom_stick.sp"
#include "weapons/weapon_fists_of_kahml.sp"
#include "weapons/weapon_arrow_shot.sp"
#include "weapons/weapon_default_wand.sp"
#include "weapons/weapon_ant_jar.sp"
#include "weapons/weapon_builder.sp"
#include "weapons/weapon_toucher.sp"
#include "weapons/weapon_wand_gravaton.sp"
#include "weapons/weapon_vehicular_manslaughter.sp"
#include "weapons/weapon_bonk_bat.sp"
#include "weapons/weapon_sharedtakedamage.sp"
#include "weapons/weapon_sharedfuncattack.sp"
#include "weapons/weapon_kamikaze.sp"
#include "weapons/weapon_ant_eraser.sp"
#include "weapons/weapon_dupstepgun.sp"
#include "weapons/weapon_cow_mangler.sp"
#include "weapons/weapon_scp018.sp"
#include "weapons/weapon_firestaff.sp"
#include "weapons/weapon_cspy.sp"
#include "weapons/weapon_hax.sp"
#include "weapons/weapon_reverse_rocket.sp"
#include "weapons/weapon_fartgun.sp"
#include "weapons/weapon_poisoned_sandvich.sp"
#include "weapons/weapon_hookshot.sp"
#include "weapons/weapon_redeemer.sp"
#include "weapons/weapon_barracks.sp"

public Plugin myinfo =
{
	name		=	"Gun Game Riot",
	author		=	"Artvin, wo",
	description	=	"Gun Game But taken to the extreme",
	version		=	"manual"
};


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	Natives_PluginLoad();

	return APLRes_Success;
}
public void OnPluginStart()
{
	Core_DoTickrateChanges();
	DHook_Setup();
	SDKCall_Setup();
	Events_PluginStart();
	SDKHook_PluginStart();
	WandProjectile_GamedataInit();
	Console_PluginStart();
	
	SpawnPointArray = new ArrayList(sizeof(SpawnPointInfo));
	
	RegAdminCmd("sm_give_gun", Command_ForceGiveGunName, ADMFLAG_ROOT, "Give a gun to a person");
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		char classname[64];
		if (GetEntityClassname(entity, classname, sizeof(classname)))
			OnEntityCreated(entity, classname);
	}
}

public void OnMapStart()
{
	SDKHooks_ClearAll();
	SDKHook_MapStart();
	ViewChange_MapStart();
	Zero(f_PreventMovementClient);
	Zero(f_PreventKillCredit);
	Zero(f_RetryRespawn);
	f_RoundStartUberLastsUntil = 0.0;
	//precache or fastdl
	g_particleCritText = PrecacheParticleSystem("crit_text");
	g_particleMiniCritText = PrecacheParticleSystem("minicrit_text");
	ConVar_ToggleDo();
	PrecacheSound("zombiesurvival/headshot1.wav");
	PrecacheSound("zombiesurvival/headshot2.wav");
	PrecacheSound("quake/standard/headshot.mp3");
	PrecacheSound("ambient/explosions/explode_3.wav");
	PrecacheSound(SOUND_LEVELUP);
	PrecacheSound(SOUND_FINALLEVEL);
	PrecacheSound("mvm/mvm_money_vanish.wav");
	
	
	AddFileToDownloadsTable("sound/zombiesurvival/headshot1.wav");
	AddFileToDownloadsTable("sound/zombiesurvival/headshot2.wav");
	AddFileToDownloadsTable("sound/quake/standard/headshot.mp3");
	AddFileToDownloadsTable("sound/turbo_gungame/levelup.mp3");
	
	AddFileToDownloadsTable("models/zombie_riot/weapons/custom_weaponry_1_52.dx80.vtx");
	AddFileToDownloadsTable("models/zombie_riot/weapons/custom_weaponry_1_52.dx90.vtx");
	AddFileToDownloadsTable("models/zombie_riot/weapons/custom_weaponry_1_52.mdl");
	AddFileToDownloadsTable("models/zombie_riot/weapons/custom_weaponry_1_52.vvd");

	AddFileToDownloadsTable("models/zombie_riot/weapons/ruina_models_1_2_2.dx80.vtx");
	AddFileToDownloadsTable("models/zombie_riot/weapons/ruina_models_1_2_2.dx90.vtx");
	AddFileToDownloadsTable("models/zombie_riot/weapons/ruina_models_1_2_2.mdl");
	AddFileToDownloadsTable("models/zombie_riot/weapons/ruina_models_1_2_2.vvd");

	AddFileToDownloadsTable("models/zombie_riot/weapons/ruina_models_2_5.dx80.vtx");
	AddFileToDownloadsTable("models/zombie_riot/weapons/ruina_models_2_5.dx90.vtx");
	AddFileToDownloadsTable("models/zombie_riot/weapons/ruina_models_2_5.mdl");
	AddFileToDownloadsTable("models/zombie_riot/weapons/ruina_models_2_5.vvd");
	AddFileToDownloadsTable("models/zombie_riot/weapons/soldier_hands/c_soldier_arms.dx80.vtx");
	AddFileToDownloadsTable("models/zombie_riot/weapons/soldier_hands/c_soldier_arms.dx90.vtx");
	AddFileToDownloadsTable("models/zombie_riot/weapons/soldier_hands/c_soldier_arms.mdl");
	AddFileToDownloadsTable("models/zombie_riot/weapons/soldier_hands/c_soldier_arms.vvd");
	AddFileToDownloadsTable("materials/models/custom_weaponry/grey.vtf");
	AddFileToDownloadsTable("materials/models/custom_weaponry/grey.vmt");
	AddFileToDownloadsTable("materials/models/custom_weaponry/blue.vmt");
	AddFileToDownloadsTable("materials/models/custom_weaponry/blue_test_2.vmt");
	AddFileToDownloadsTable("materials/models/custom_weaponry/glow_inner_2.vmt");
	AddFileToDownloadsTable("materials/models/custom_weaponry/glow_inner.vmt");
	AddFileToDownloadsTable("materials/models/custom_weaponry/weaponry_solid_white.vtf");
	AddFileToDownloadsTable("materials/models/custom_weaponry/weaponry_solid_white_2.vtf");
	AddFileToDownloadsTable("materials/models/custom_weaponry/weaponry_trans_white.vtf");
	AddFileToDownloadsTable("materials/models/custom_weaponry/weaponry_trans_white_2.vtf");
	
	Weapon_Arrow_Shoot_Map_Precache();
	BoomStick_MapPrecache();
	KahmlFistMapStart();
	WandStocks_Map_Precache();
	Wand_Map_Precache();
	Gravaton_Wand_MapStart();
	VehicularManslaughter_Precache();
	BonkBat_MapStart();
	SharedTakeDamage_Mapstart();
	KamikazeMapStart();
	DupStepGunMapStart();
	CowMangler_Precache();
	Hax_Precache();
	Init_SCP18();
	ReverseRocket_Precache();
	FartGun_Precache();
	PosionSandvichMapStart();
	HookshotMapStart();
	Spell_MapStart();
	Redeemer_Precache();
	
	SpawnPointArray.Clear();
}

public void OnConfigsExecuted()
{
	ConVar_ConfigsExecuted();
	ConVar_Enable();
	Configs_ConfigsExecuted();
	Weapons_ConfigsExecuted();
	Weapons_ResetRound();
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
			OnClientPutInServer(client);
	}
}

public void OnPluginEnd()
{
	ConVar_Disable();
	SetMapSpawnPointsToTeam(TFTeam_Unassigned, false);
}

public void OnClientPutInServer(int client)
{
	Core_DoTickrateChanges();
	
	SDKHook_HookClient(client);
	ValidTargetToHit[client] = true;
	ClientFirstTimeChoosingTeam[client] = true;
}
public void OnGameFrame()
{
	SCP18_Tick();
}
public void OnEntityCreated(int entity, const char[] classname)
{
	if(!StrContains(classname, "info_player_teamspawn"))
	{
		// This is a non-networked entity, we're directly looking at its ref
		RequestFrame(Frame_SpawnPointCreated, entity);
		return;
	}
	
	if (entity < 0)
		return;
	if (entity > 2048)
		return;
	if (!IsValidEntity(entity))
		return;
	b_IsAProjectile[entity] = false;
	ValidTargetToHit[entity] = false;
	i_SavedActualWeaponSlot[entity] = -1;
	b_IsATrigger[entity] = false;
	b_IsATriggerHurt[entity] = false;
	b_IsAMedigun[entity] = false;
	if(!StrContains(classname, "trigger_teleport")) //npcs think they cant go past this sometimes, lol
	{
		b_IsATrigger[entity] = true;
	}
	else if (!StrContains(classname, "tf_weapon_medigun")) 
	{
		b_IsAMedigun[entity] = true;
	}
	else if (!StrContains(classname, "tf_ammo_pack")) 
	{
		SDKHook(entity, SDKHook_SpawnPost, Delete_instantly);
	}
	else if(!StrContains(classname, "tf_projecti"))
	{
		b_IsAProjectile[entity] = true;
	}
	/*
	else if(!StrContains(classname, "func_wall")
	|| !StrContains(classname, "func_ladder"))
	{
		//crashes with custom projectiles
		SDKHook(entity, SDKHook_SpawnPost, Delete_instantly);
	//	b_IsAProjectile[entity] = true;
	}
	*/
	else if(!StrContains(classname, "trigger_hurt")) //npcs think they cant go past this sometimes, lol
	{
		b_IsATrigger[entity] = true;
		b_IsATriggerHurt[entity] = true;
	}
	else if (StrEqual(classname, "tf_player_manager"))
	{
		SDKHook(entity, SDKHook_ThinkPost, OnTFPlayerManagerThinkPost);	
	}
	else if(!StrContains(classname, "item_healthkit_medium"))
	{
		SDKHook(entity, SDKHook_Touch, SandvichTouch);
	}
	else if(!StrContains(classname, "obj_"))
	{
		ValidTargetToHit[entity] = true;
	}
}

void Frame_SpawnPointCreated(int entity)
{
	// Spawn points are created when a game (not round) starts in some maps, so we clean up the list if more spawns were added at a later point (because why would a map do this mid round)
	// Needs to be a frame late because m_iTeamNum isn't initialized even in SDKHook_OnSpawnPost
	// This is only used to store info about spawn points
	
	float time = GetGameTime();
	static float lastTime;
	
	if (time != lastTime)
		SpawnPointArray.Clear();
	
	TFTeam team = view_as<TFTeam>(GetEntProp(entity, Prop_Send, "m_iTeamNum"));
	
	SpawnPointInfo info;
	info.ref = entity;
	info.originalTeam = team;
	SpawnPointArray.PushArray(info);
	lastTime = time;
}

void Frame_SetMapSpawnPointsPostTeamSwitch(TFTeam team)
{
	SetMapSpawnPointsToTeam(team, true);
}

void SetMapSpawnPointsToTeam(TFTeam team, bool respawn)
{
	n_ForcedTeam = team;
	
	int length = SpawnPointArray.Length;
	for (int i = length - 1; i >= 0; i--)
	{
		SpawnPointInfo info;
		SpawnPointArray.GetArray(i, info);
		
		int entity = info.ref;
		if (!IsValidEntity(entity))
		{
			SpawnPointArray.Erase(i);
			continue;
		}
		
		// Setting the team to unassigned/spectator restores the spawn point's original team
		SetVariantInt(team <= TFTeam_Spectator ? view_as<int>(info.originalTeam) : view_as<int>(team));
		AcceptEntityInput(entity, "SetTeam");
	}
	
	if (respawn)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client) || !IsPlayerAlive(client) || TF2_GetClientTeam(client) <= TFTeam_Spectator)
				continue;
			
			TFTeam playerTeam = TF2_GetClientTeam(client);
			if (playerTeam <= TFTeam_Spectator)
				continue;
			
			if (playerTeam != team)
				TF2_ForceTeamJoin(client, team, false);
			
			RequestFrame(Frame_RespawnPlayer, GetClientUserId(client));
		}
	}
}

static Action SandvichTouch(int entity, int target)
{
	if(target < 1 || target > MaxClients)
		return Plugin_Continue;
	
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client < 1 || client > MaxClients || client == target)
		return Plugin_Continue;
	
	RemoveEntity(entity);
	SDKHooks_TakeDamage(target, client, client, 420.0, DMG_PREVENT_PHYSICS_FORCE, _, {0.0, 0.0, 0.0});
	return Plugin_Handled;
}

public void OnEntityDestroyed(int entity)
{
	if (entity < 0)
		return;
	if (entity > 2048)
		return;

	Attributes_EntityDestroyed(entity);

	
	if (!IsValidEntity(entity))
		return;
	DHook_EntityDestoryed();
}
void Core_DoTickrateChanges()
{
	//needs to get called a few times just incase.
	//it isnt expensive so it really doesnt matter.
	float tickrate = 1.0 / GetTickInterval();
//	TickrateModifyInt = RoundToNearest(tickrate);

	TickrateModify = tickrate / 66.0;
}

public void Delete_instantly(int entity)
{
	RemoveEntity(entity);
}



public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int index, Handle &item)
{
	//strip players of all weapons at all times
	if(!StrContains(classname, "tf_wear"))
	{
		switch(index)
		{	
			case 57, 131, 133, 231, 405, 406, 444, 608, 642, 1099, 1144:
			{
				if(!item)
					return Plugin_Stop;
				
				TF2Items_SetFlags(item, OVERRIDE_ATTRIBUTES);
				TF2Items_SetNumAttributes(item, 0);
				return Plugin_Changed;
			}
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


public void OnClientDisconnect(int client)
{
	ViewChange_ClientDisconnect(client);
}



public Action Command_ForceGiveGunName(int client, int args)
{
	//What are you.
	if(args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: Command_ForceGiveGunName <target> <name of gun>");
        return Plugin_Handled;
    }
    
	static char targetName[MAX_TARGET_LENGTH];
    
	static char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	
	char buf[64];
	GetCmdArg(2, buf, sizeof(buf));

	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;
	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}
	
	for(int target; target<matches; target++)
	{
		RemoveAllWeapons(targets[target]);
		int weapon = Weapons_GiveSpecificItem(targets[target], buf);
		OnWeaponSwitchPost(targets[target] , weapon);
	}
	
	return Plugin_Handled;
}


public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(condition == TFCond_SpawnOutline) //this is a hopefully prevention for client crashes, i am unsure why this happens.
	//Idea got from a client dump.
	{
		TF2_RemoveCondition(client, TFCond_SpawnOutline);
	}
	else if (condition == TFCond_Slowed && IsPlayerAlive(client))
	{
		SDKCall_SetSpeed(client);
	}
	else if (condition == TFCond_Taunting && (f_PreventMovementClient[client] > GetGameTime()))
	{
		TF2_RemoveCondition(client, TFCond_Taunting);
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(IsValidClient(client) && IsPlayerAlive(client)) //Need this, i think this has a chance to return -1 for some reason. probably disconnect.
	{
		switch(condition)
		{
			case TFCond_Zoomed:
			{
				ViewChange_Update(client);
			}
			case TFCond_Slowed:
			{
				SDKCall_SetSpeed(client);
			}
			case TFCond_Taunting:
			{
				Viewchange_UpdateDelay(client);
			}
		}
	}
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	Function func = EntityPlayerCMD[client];
	if(func && func!=INVALID_FUNCTION)
	{
		Call_StartFunction(null, func);
		Call_PushCell(client);
		Call_PushCellRef(buttons);
		Call_PushCellRef(impulse);
		Call_PushArray(vel, sizeof(vel));
		Call_PushArray(angles, sizeof(angles));
		Call_PushCellRef(weapon);
		Call_PushCellRef(subtype);
		Call_PushCellRef(cmdnum);
		Call_PushCellRef(tickcount);
		Call_PushCellRef(seed);
		Call_PushArray(mouse, sizeof(mouse));
		Call_Finish();
	}
	return Plugin_Changed;
}
public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] classname, bool &result)
{
	Action action = Plugin_Continue;
	Function func = EntityFuncAttack[weapon];
	if(func && func!=INVALID_FUNCTION)
	{
		int slot = 1;
		Call_StartFunction(null, func);
		Call_PushCell(client);
		Call_PushCell(weapon);
		Call_PushCellRef(result);
		Call_PushCell(slot);	//This is m1 :)
		Call_Finish(action);
	}
	return action;
}