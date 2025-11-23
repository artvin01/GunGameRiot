#pragma semicolon 1
#pragma newdecls required


// Credits to @Spookmaster
#define SOUND_LOADOUT_CYCLE				"weapons/shotgun_cock_forward.wav"
#define HOOK_FIRE						"weapons/grappling_hook_shoot.wav"
#define HOOK_REEL						"weapons/grappling_hook_reel_start.wav"
#define HOOK_DETACH						"weapons/grappling_hook_reel_stop.wav"
#define HOOK_CONTACT_ENEMY				"weapons/grappling_hook_impact_flesh.wav"
#define HOOK_CONTACT_SURFACE			"weapons/grappling_hook_impact_default.wav"
#define SOUND_HOOK_COMBO				")mvm/mvm_tele_activate.wav"
#define NOPE				 			"buttons/button10.wav"
#define SOUND_TURBO_BONUS_ACTIVATE		"weapons/dragon_gun_motor_start.wav"
#define SOUND_TURBO_BONUS_REMOVED		"weapons/dragon_gun_motor_stop.wav"
#define SOUND_TURBO_BONUS_LOOP			"weapons/dragon_gun_motor_loop_dry.wav"
#define SOUND_BATTERY_IMPACT			")mvm/mvm_tank_smash.wav"
#define SOUND_BATTERY_ACTIVATE			")weapons/rocket_pack_boosters_charge.wav"
#define SOUND_BATTERY_DASH				")weapons/rocket_pack_boosters_fire.wav"
#define SOUND_BATTERY_END				")weapons/rocket_pack_boosters_shutdown.wav"
#define SOUND_CROUCH_TOGGLE				"weapons/vaccinator_toggle.wav"
#define SOUND_CRUSHER_WHOOSH			")misc/halloween/strongman_fast_whoosh_01.wav"
#define SOUND_CRUSHER_LAND_1			")misc/halloween/strongman_fast_impact_01.wav"
#define SOUND_CRUSHER_LAND_2			")weapons/airstrike_small_explosion_01.wav"
#define SOUND_OXIDIZER_EXPLODE			")weapons/flare_detonator_explode.wav"
#define SOUND_IGNITE_START				"weapons/fx/rics/pomson_projectile_impact_flesh.wav"
#define SOUND_IGNITE_END				"player/flame_out.wav"

#define PARTICLE_DOOMSDAY_BULLET		"bullet_shotgun_tracer01_red"
#define PARTICLE_RAILGUN_RED			"sniper_dxhr_rail_red"
#define PARTICLE_RAILGUN_BLUE			"sniper_dxhr_rail_blue"
#define PARTICLE_RAILGUN_IMPACT_BLUE	"drg_cow_explosioncore_charged_blue"
#define PARTICLE_RAILGUN_IMPACT_RED		"drg_cow_explosioncore_charged"
#define PARTICLE_CRIT					"crit_text"
#define PARTICLE_BATTERY_FOOT			"rockettrail"
#define PARTICLE_BATTERY_BEGIN			"heavy_ring_of_fire"
#define PARTICLE_BATTERY_FOOT_BLAST		"ExplosionCore_MidAir_Jumper"
#define PARTICLE_CRUSHER_LAND			"hammer_impact_button_dust2"
#define PARTICLE_OXIDIZER_RED			"flaregun_trail_crit_red"
#define PARTICLE_OXIDIZER_BLUE			"flaregun_trail_crit_blue"
#define PARTICLE_OXIDIZER_EXPLODE_RED	"ExplosionCore_MidAir_Flare"
#define PARTICLE_OXIDIZER_EXPLODE_BLUE	"ExplosionCore_MidAir_Flare"

int Hook_Victim[MAXPLAYERS] = {-1, ...};
int Hook_Owner[MAXENTITIES] = {-1, ...};
int Hook_Hook[MAXPLAYERS] = {-1, ...};
bool Hook_Reeling[MAXPLAYERS] = { false, ... };
bool Hook_CurrentlyPulling[MAXPLAYERS] = { false, ... };
float Hook_CD[MAXPLAYERS] = {0.0, ...};
float Hook_Velocity[MAXPLAYERS] = {0.0, ...};
float Hook_DetatchTime[MAXPLAYERS] = {0.0, ...};
float Hook_DetatchGameTime[MAXPLAYERS] = {0.0, ...};
float Hook_Force[MAXPLAYERS] = {0.0, ...};
float Hook_DMG[MAXPLAYERS] = {0.0, ...};
float Hook_HorizontalSpeed[MAXPLAYERS] = {0.0, ...};
float Hook_VerticalDeg[MAXPLAYERS] = {0.0, ...};
float Hook_Elasticity[MAXPLAYERS] = {0.0, ...};
float Hook_MaxRange[MAXPLAYERS] = {0.0, ...};
float Hook_BonusVictim[MAXPLAYERS] = {0.0, ...};
float Hook_RecallPenalty[MAXPLAYERS] = {0.0, ...};
float Hook_DisconnectDamage[MAXPLAYERS] = {0.0, ...};
float Hook_AutoDisconnectRange[MAXPLAYERS] = {0.0, ...};
float Hook_TargetLocation[MAXPLAYERS][3];
float HS_LastCheckAt[MAXPLAYERS] = {0.0, ...};
float HS_HookshotReelDistance[MAXPLAYERS] = {0.0, ...};
float Hook_NextUse[MAXPLAYERS] = {0.0, ...};
#define HS_MIN_LENGTH 20.0 // hammer units, minimum length of hookshot relative to eye level
#define HS_CHECK_INTERVAL 0.05
#define HS_LIMP_MIN_DISTANCE 100.0 // if the player is this many HU closer to the hook than they should be, the rope is limp, and does not affect their motion
#define HS_ROPE_TOP_DISCREPANCY_ALLOWANCE 50.0 // HU of allowed discrepancy in any axis for the end points of the rope (prevents oddities in the ceiling from snapping the rope)
#define HS_DEFAULT_ELASTIC_INTENSITY 900.0
#define HS_ELASTIC_BASE_DISTANCE 100.0
#define HS_HUD_TEXT_LENGTH (MAX_CENTER_TEXT_LENGTH*2)
#define HS_FLAG_COOLDOWN_ON_UNHOOK 0x0001
#define HS_FLAG_GLOW_HACK 0x0002

int RopeModelIndex;

static Handle Local_Timer[MAXPLAYERS] = {null, ...};
public void HookshotMapStart()
{
	PrecacheSound(HOOK_FIRE, true);
	PrecacheSound(HOOK_REEL, true);
	PrecacheSound(HOOK_DETACH, true);
	PrecacheSound(HOOK_CONTACT_ENEMY, true);
	PrecacheSound(HOOK_CONTACT_SURFACE, true);
	RopeModelIndex = PrecacheModel("materials/swamp/cable/rope_swamp.vmt");

}
public void HookshotCreate(int client, int weapon)
{
	if (Local_Timer[client] != null)
	{
		delete Local_Timer[client];
		Local_Timer[client] = null;
	}
	
	/*

        "arg0"    "10.0"        //Starting cooldown
        "arg1"    "17.5"        //Cooldown
        "arg2"    "3000.0"    //Hook velocity
        "arg3"    "3.0"        //Time until the hook auto-detatches after hitting a surface
        "arg4"    "200.0"        //Hook reel-in speed
        "arg5"    "500.0"        //Damage dealt on contact if the hook hits an enemy directly
        "arg6"    "1.0"        //Horizontal speed multiplier, higher = the faster the hook swings around the center
        "arg7"    "0.8"        //Vertical degradation
        "arg8"    "0.33"        //Hook elasticity. The higher this is, the faster the hook pulls you.
        "arg9"    "2000.0"    //Max range, in hammer units (0.0 or below: infinite)
        "arg10"    "120.0"        //Bonus hook hitbox size when attempting to hit an enemy
        "arg11"    "2.0"        //Cooldown when recalling the hook before it hits a surface
        "arg12"    "50.0"        //Upon any attack by the user dealing this much damage to the player they have hooked, the hook is automatically disconnected.
        "arg13"    "50.0"        //Range in which you will automatically unhook.
	*/
	float time = 0.1;
	Hook_CD[client] = 1.0;
	Hook_Velocity[client] = 3000.0;
	Hook_DetatchTime[client] = 3.0;
	Hook_Force[client] = 200.0;
	Hook_DMG[client] = 25.0;
	Hook_HorizontalSpeed[client] = 1.0;
	Hook_VerticalDeg[client] = 0.8;
	Hook_Elasticity[client] = 0.33;
	Hook_MaxRange[client] = 2000.0;
	Hook_BonusVictim[client] = 120.0;
	Hook_RecallPenalty[client] = 2.0;
	Hook_DisconnectDamage[client] = 10.0;
	Hook_AutoDisconnectRange[client] = 50.0;

	Hook_NextUse[client] = GetGameTime() + time;

	DataPack pack;
	Local_Timer[client] = CreateDataTimer(0.1, Timer_Local, pack, TIMER_REPEAT);
	pack.WriteCell(client);
	pack.WriteCell(EntIndexToEntRef(client));
	pack.WriteCell(EntIndexToEntRef(weapon));
	SDKUnhook(client, SDKHook_PreThink, HookShotPrethink);
	SDKHook(client, SDKHook_PreThink, HookShotPrethink);
}

void HookShotPrethink(int client)
{
	//prob laggy
	if(!IsValidClient(client) || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		SDKUnhook(client, SDKHook_PreThink, HookShotPrethink);
		return;
	}
	bool Mouse2 = (GetClientButtons(client) & IN_ATTACK2) != 0;
	if(Mouse2)
	{
		if(Hook_NextUse[client] < GetGameTime() && !IsValidEntity(Hook_Hook[client]))
		{
			if(Hook_Reeling[client])
				StopSound(client, SNDCHAN_AUTO, HOOK_REEL);
			Hook_Fire(client);
		}
	}
}
static Action Timer_Local(Handle timer, DataPack pack)
{
	pack.Reset();
	int clientidx = pack.ReadCell();
	int client = EntRefToEntIndex(pack.ReadCell());
	int weapon = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidClient(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || !IsValidEntity(weapon))
	{
		Local_Timer[clientidx] = null;
		if(IsValidClient(client))
		{
			PrintCenterText(client, "");
			SDKUnhook(client, SDKHook_PreThink, HookShotPrethink);
		}
		return Plugin_Stop;
	}	
	PrintCenterText(client, "Press [M2] To Hook a target");

	return Plugin_Continue;
}

public void Hook_Fire(int client)
{
	if (!IsValidClient(client))
		return;
	
	int hook = CreateEntityByName("tf_projectile_grapplinghook");
	if (IsValidEntity(hook))
	{
		Hook_Owner[hook] = client;
		Hook_Hook[client] = EntIndexToEntRef(hook);
		
		float vAngles[3], vPosition[3], vVelocity[3], vBuffer[3];
		GetClientEyeAngles(client, vAngles);
		GetClientEyePosition(client, vPosition);
		vPosition[2] += -30.0;
		
		int iTeam = GetClientTeam(client);
		
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		
		float spd = Hook_Velocity[client];
	
		vVelocity[0] = vBuffer[0]*spd;
		vVelocity[1] = vBuffer[1]*spd;
		vVelocity[2] = vBuffer[2]*spd;
		
		SetEntPropEnt(hook, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(hook,    Prop_Send, "m_bCritical", 0, 1);
		SetEntProp(hook,    Prop_Send, "m_iTeamNum",     iTeam, 1);
		SetEntProp(hook,    Prop_Send, "m_nSkin", (iTeam-2));
			
		TeleportEntity(hook, vPosition, vAngles, NULL_VECTOR);
		SetVariantInt(iTeam);
		AcceptEntityInput(hook, "TeamNum", -1, -1, 0);
		SetVariantInt(iTeam);
		AcceptEntityInput(hook, "SetTeam", -1, -1, 0); 
			
		DispatchSpawn(hook);
		TeleportEntity(hook, NULL_VECTOR, NULL_VECTOR, vVelocity);
		
		SDKHook(hook, SDKHook_Touch, Hook_Touch);
		SDKHook(client, SDKHook_PreThink, Hook_ConnectionPreThink);
	}
	
	Hook_NextUse[client] = GetGameTime() + Hook_CD[client];
	EmitSoundToClient(client, HOOK_FIRE, _, _, 80);
	Hook_Reeling[client] = true;
	Hook_CurrentlyPulling[client] = false;
}

void Hook_Disconnect(int client, bool early)
{
	int hook = EntRefToEntIndex(Hook_Hook[client]);
	if (IsValidEntity(hook))
		CreateTimer(0.0, Timer_RemoveEntity, EntIndexToEntRef(hook), TIMER_FLAG_NO_MAPCHANGE);

	Hook_Hook[client] = -1;
	Hook_Victim[client] = -1;
	Hook_CurrentlyPulling[client] = false;

	if (Hook_Reeling[client])
	{
		EmitSoundToClient(client, HOOK_DETACH, _, _, 80);
	}

	Hook_Reeling[client] = false;
	StopSound(client, SNDCHAN_AUTO, HOOK_REEL);

	Hook_NextUse[client] = GetGameTime() + (early ? Hook_RecallPenalty[client] : Hook_CD[client]);

	SDKUnhook(client, SDKHook_PreThink, Hook_PreThink);
	SDKUnhook(client, SDKHook_PreThink, Hook_ConnectionPreThink);
}

public Action Hook_ConnectionPreThink(int client)
{
	int Hook = EntRefToEntIndex(Hook_Hook[client]);
	if (!IsValidEntity(Hook))
	{
		SDKUnhook(client, SDKHook_PreThink, Hook_ConnectionPreThink);

		return Plugin_Stop;
	}
	else
	{
		float HookLoc[3];
		GetEntPropVector(Hook, Prop_Send, "m_vecOrigin", HookLoc);
		
		float UserLoc[3];
		GetClientAbsOrigin(client, UserLoc);
		
		if (GetVectorDistance(UserLoc, HookLoc) > Hook_MaxRange[client] && Hook_MaxRange[client] > 0.0)
		{
			Hook_Disconnect(client, true);
		}
		else
		{
			bool hooked = false;
			
			for (int i = 1; i <= MaxClients && !hooked; i++)
			{
				if (IsValidMulti(i, false, _))
				{
					float VicLoc[3];
					GetClientAbsOrigin(i, VicLoc);
					
					if (GetVectorDistance(HookLoc, VicLoc, true) <= Pow(Hook_BonusVictim[client], 2.0))
					{
						VicLoc[2] += 45.0;
						TeleportEntity(Hook, VicLoc, NULL_VECTOR, NULL_VECTOR);
						hooked = true;
						SDKUnhook(client, SDKHook_PreThink, Hook_ConnectionPreThink);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}



public Action Hook_PreThink(int client)
{
	if (GetGameTime() >= Hook_DetatchGameTime[client]|| (Hook_Victim[client] > 0 && !IsValidMulti(Hook_Victim[client], false, _)))
	{
		Hook_Disconnect(client, false);
	}
	else
	{
		if (IsValidMulti(Hook_Victim[client], false, _))
		{
			GetClientAbsOrigin(Hook_Victim[client], Hook_TargetLocation[client]);
			Hook_TargetLocation[client][2] += 50.0;
		}
		
					// need our check delta, not main update delta
		float checkDelta = GetEngineTime() - HS_LastCheckAt[client];
		
					// need the current distance
		static float clientOrigin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientOrigin);
		float distance = GetVectorDistance(clientOrigin, Hook_TargetLocation[client]);
		if (distance < Hook_AutoDisconnectRange[client])
		{
			Hook_Disconnect(client, false);
			return Plugin_Continue;
		}
		
					// reel in
		HS_HookshotReelDistance[client] = fmax(HS_MIN_LENGTH, HS_HookshotReelDistance[client] - (checkDelta * Hook_Force[client]));
		
		float excessDistance = distance - HS_HookshotReelDistance[client];
		float limpDistance = HS_HookshotReelDistance[client] - distance;
		
					// we do a number of checks in here. however, if the rope is limp, none of these checks apply.
		if (checkDelta >= HS_CHECK_INTERVAL && limpDistance < HS_LIMP_MIN_DISTANCE)
		{
						// get the player's current velocity
			static float bossVelocity[3];
			GetEntPropVector(client, Prop_Data, "m_vecVelocity", bossVelocity);
			
						// degrade excess negative z, but only if there's excess distance
			if (bossVelocity[2] < 0 && excessDistance > 0.0)
			bossVelocity[2] *= Hook_VerticalDeg[client];
			
						// horizontal pull first. I'd rather keep the variables here limited in scope.
						// and also keep the indentation the same as the other velocity tweaks
						// though this always executes
			{
							// need adjust positions of things that 
				static float adjustedBossPos[3];
				adjustedBossPos[0] = clientOrigin[0];
				adjustedBossPos[1] = clientOrigin[1];
				adjustedBossPos[2] = 0.0;
				static float adjustedHookPos[3];
				adjustedHookPos[0] = Hook_TargetLocation[client][0];
				adjustedHookPos[1] = Hook_TargetLocation[client][1];
				adjustedHookPos[2] = 0.0;
				
							// get our velocity vector and normalize it
				static float elasticVelocity[3];
				MakeVectorFromPoints(clientOrigin, Hook_TargetLocation[client], elasticVelocity);
				NormalizeVector(elasticVelocity, elasticVelocity);
				
							// the pull in HUPS factors in the length of the rope. if I used a static speed,
							// the physics would seem screwy with long vs. short ropes
				for (int axis = 0; axis <= 1; axis++)
				{
					elasticVelocity[axis] *= ((Hook_HorizontalSpeed[client] * HS_HookshotReelDistance[client]) * checkDelta);
					
								// add this to the player's current velocity. no limits.
					bossVelocity[axis] += elasticVelocity[axis];
				}
			}
			
						// now we need to persuade the user's position to match where we think it should be.
						// doing this every tick would have stability issues to say the least, so lets try doing it only 10 times per second
			if (excessDistance > 0.0)
			{
							// persuade the boss' position in the direction of the hook
							// unlike the player motion velocity, there are no limits.
				static float elasticVelocity[3];
				MakeVectorFromPoints(clientOrigin, Hook_TargetLocation[client], elasticVelocity);
				NormalizeVector(elasticVelocity, elasticVelocity);
				
							// our fun little equation for the velocity modifier
				for (int axis = 0; axis <= 2; axis++)
				{
					elasticVelocity[axis] *= Hook_Elasticity[client] * ((excessDistance / HS_ELASTIC_BASE_DISTANCE) * checkDelta * HS_DEFAULT_ELASTIC_INTENSITY);
					
								// add this to the player's current velocity. no limits.
					bossVelocity[axis] += elasticVelocity[axis];
				}
			}
			
						// apply the changes to player velocity
			
			if (GetEntityFlags(client) & FL_ONGROUND != 0)
			{
				bossVelocity[2] += 100.0;
			}
			
			SetEntPropVector(client, Prop_Data, "m_vecVelocity", bossVelocity);
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, bossVelocity);
			
						// finally, schedule the next check
			HS_LastCheckAt[client] = GetEngineTime();
		}
		
		float UserLoc[3];
		GetClientAbsOrigin(client, UserLoc);
		
		UserLoc[2] += 50.0;
		SpawnBeam_Vectors(UserLoc, Hook_TargetLocation[client], 0.1, 255, 255, 255, 255, RopeModelIndex, 3.0, 3.0, 1, 0.1);	//TODO: Replace this with a real env_beam eventually so it doesn't look so jank
	}
	
	return Plugin_Continue;
}



public Action Hook_Touch(int hook, int other)
{
	int client = Hook_Owner[hook];
	if (!IsValidMulti(client))
		return Plugin_Continue;
		
	char entname[255];
	GetEntityClassname(other, entname, 255);
	
	bool Passed = true;
	
	if(client == other)
		Passed = false;
	
	if (StrContains(entname, "info_") != -1 || StrContains(entname, "trigger_") != -1)
	{
		Passed = false;
	}
	
	if (StrContains(entname, "func_") != -1)
	{
		if (!StrEqual("func_brush", entname)
			&& !StrEqual("func_door", entname) && !StrEqual("func_detail", entname) && !StrEqual("func_wall", entname) && !StrEqual("func_rotating", entname)
			&& !StrEqual("func_reflective_glass", entname) && !StrEqual("func_physbox", entname) && !StrEqual("func_movelinear", entname) && !StrEqual("func_door_rotating", entname)
			&& !StrEqual("func_breakable", entname))
		{
			Passed = false;
		}
	}
		
	if (Passed)
	{
		float HookLoc[3];
		GetEntPropVector(hook, Prop_Send, "m_vecOrigin", HookLoc);
		Hook_TargetLocation[client] = HookLoc;

		if (IsValidMulti(other, false, _))
		{
			EmitSoundToClient(client, HOOK_CONTACT_ENEMY, _, _, 80);
			EmitSoundToClient(other, HOOK_CONTACT_ENEMY, _, _, 80);
			SDKHooks_TakeDamage(other, hook, client, Hook_DMG[client]);
			//PlayRandomSound(client, "sound_hook_attach_player", client);
			Hook_Victim[client] = other;
		}
		else
		{
			EmitSoundToClient(client, HOOK_CONTACT_SURFACE, _, _, 80);
			//PlayRandomSound(client, "sound_hook_attach", client);
		}
			
		EmitSoundToClient(client, HOOK_REEL, _, _, 80);
		Hook_DetatchGameTime[client] = GetGameTime() + Hook_DetatchTime[client];
		HS_LastCheckAt[client] = GetEngineTime();
			
		SDKUnhook(client, SDKHook_PreThink, Hook_ConnectionPreThink);
		SDKHook(client, SDKHook_PreThink, Hook_PreThink);
		Hook_CurrentlyPulling[client] = true;

		SDKUnhook(hook, SDKHook_Touch, Hook_Touch);
		RemoveEntity(hook);
	}
	
	return Plugin_Handled;
}

