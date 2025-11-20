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
#include <sourcescramble>
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

#define SOUND_LEVELUP "gungame_riot/levelup.mp3"

#include "global_arrays.sp"
#include "stocks_override.sp"
#include "stocks.sp"
#include "weapons.sp"
#include "configs.sp"
#include "viewchanges.sp"
#include "attributes.sp"
#include "sdkcalls.sp"
#include "dhooks.sp"
#include "events.sp"
#include "sdkhooks.sp"
#include "convars.sp"
#include "wand_projectile.sp"


#include "weapons/weapon_boom_stick.sp"
#include "weapons/weapon_fists_of_kahml.sp"
#include "weapons/weapon_arrow_shot.sp"
#include "weapons/weapon_default_wand.sp"

public Plugin myinfo =
{
	name		=	"Gun Game Riot",
	author		=	"Artvin",
	description	=	"Gun Game But taken to the extreme",
	version		=	"manual"
};


public void OnPluginStart()
{
	
	Core_DoTickrateChanges();
	DHook_Setup();
	SDKCall_Setup();
	Events_PluginStart();
	SDKHook_PluginStart();
	ConVar_PluginStart();
	WandProjectile_GamedataInit();
	
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
	f_RoundStartUberLastsUntil = 0.0;
	//precache or fastdl
	g_particleCritText = PrecacheParticleSystem("crit_text");
	g_particleMiniCritText = PrecacheParticleSystem("minicrit_text");
	ConVar_ToggleDo();
	PrecacheSound("zombiesurvival/headshot1.wav");
	PrecacheSound("zombiesurvival/headshot2.wav");
	PrecacheSound("quake/standard/headshot.mp3");
	PrecacheSound(SOUND_LEVELUP);

	Zero(h_NpcSolidHookType);
	Weapon_Arrow_Shoot_Map_Precache();
	BoomStick_MapPrecache();
	KahmlFistMapStart();
	WandStocks_Map_Precache();
	Wand_Map_Precache();
}

public void OnConfigsExecuted()
{
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
	
}
public void OnClientPutInServer(int client)
{
	Core_DoTickrateChanges();
	
	SDKHook_HookClient(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity < 0)
		return;
	if (entity > 2048)
		return;
	if (!IsValidEntity(entity))
		return;

	i_SavedActualWeaponSlot[entity] = -1;
	b_IsATrigger[entity] = false;
	b_IsATriggerHurt[entity] = false;
	b_IsAMedigun[entity] = false;
	b_ThisEntityIsAProjectileForUpdateContraints[entity] = false;
	if(!StrContains(classname, "trigger_teleport")) //npcs think they cant go past this sometimes, lol
	{
		b_IsATrigger[entity] = true;
	}
	else if (!StrContains(classname, "tf_weapon_medigun")) 
	{
		b_IsAMedigun[entity] = true;
	}
	else if(!StrContains(classname, "tf_projecti"))
	{
		//This can only be on red anyways.
		b_ThisEntityIsAProjectileForUpdateContraints[entity] = true;
	}
	else if(!StrContains(classname, "trigger_hurt")) //npcs think they cant go past this sometimes, lol
	{
		b_IsATrigger[entity] = true;
		b_IsATriggerHurt[entity] = true;
	}
	else if (StrEqual(classname, "tf_player_manager"))
	{
		SDKHook(entity, SDKHook_ThinkPost, OnTFPlayerManagerThinkPost);	
	}
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
	TickrateModifyInt = RoundToNearest(tickrate);

	TickrateModify = tickrate / 66.0;
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