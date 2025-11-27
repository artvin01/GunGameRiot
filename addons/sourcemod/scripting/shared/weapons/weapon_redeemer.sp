#pragma semicolon 1
#pragma newdecls required

static char g_Boowomp[][] = {
	"weapons/rpg/rocket1.wav",
};
static char g_CritBoost[][] = {
	"weapons/crit_power.wav",
};
#define REDEEMER_ROCKET_MODEL "models/weapons/w_missile_launch.mdl"
void Redeemer_Precache()
{
	PrecacheSoundArray(g_Boowomp);
	PrecacheSoundArray(g_CritBoost);
	PrecacheModel("models/props_spytech/tv001.mdl");
	PrecacheModel("models/empty.mdl");
	PrecacheModel(REDEEMER_ROCKET_MODEL);
}

static Handle Local_Timer[MAXPLAYERS] = {null, ...};
static int PlayerToRocket[MAXPLAYERS] = {0, ...};
public void Weapon_Redeemer(int client, int weapon, bool crit)
{
	if(Local_Timer[client] != null)
		return;
	//dont shoot
	float damage = 65.0;
	damage *= Attributes_Get(weapon, 2, 1.0);
	
	int projectile = Wand_Projectile_Spawn(client, 600.0, 0.0, damage, 0, weapon, "rockettrail",_,false);
	SetEntityModel(projectile, REDEEMER_ROCKET_MODEL);
	int Spectator = ApplyCustomModelToWandProjectile(projectile, "models/empty.mdl", 1.0, "");

	DataPack packremove;
	CreateDataTimer(20.0, Timer_RemoveEntity_Redeemer, packremove, TIMER_FLAG_NO_MAPCHANGE);
	packremove.WriteCell(EntIndexToEntRef(projectile));

	EmitSoundToClient(client, g_Boowomp[GetRandomInt(0, sizeof(g_Boowomp) - 1)], projectile, SNDCHAN_STATIC, 80, _, 1.0, 100);
	Custom_SDKCall_SetLocalOrigin(Spectator, {-45.0,0.0,5.0});	
	WandProjectile_ApplyFunctionToEntity(projectile, RedeemerTouch);
	PlayerToRocket[client] = EntIndexToEntRef(projectile);
	SetClientViewEntity(client, Spectator);
	SetEntProp(client, Prop_Send, "m_bForceLocalPlayerDraw", 1);

	DataPack pack;
	Local_Timer[client] = CreateDataTimer(0.1, Timer_Local, pack, TIMER_REPEAT);
	pack.WriteCell(client);
	pack.WriteCell(EntIndexToEntRef(client));
	pack.WriteCell(EntIndexToEntRef(projectile));
}

public Action Timer_RemoveEntity_Redeemer(Handle timer, DataPack pack)
{
	pack.Reset();
	int Projectile = EntRefToEntIndex(pack.ReadCell());
	if(IsValidEntity(Projectile) && Projectile>MaxClients)
	{
		int owner = EntRefToEntIndex(i_WandOwner[Projectile]);
		if(IsValidClient(owner))
		{
			EmitSoundToClient(owner, g_Boowomp[GetRandomInt(0, sizeof(g_Boowomp) - 1)], Projectile, SNDCHAN_STATIC, 80, SND_STOP, 1.0, 100);
			EmitSoundToClient(owner, g_CritBoost[GetRandomInt(0, sizeof(g_CritBoost) - 1)], Projectile, SNDCHAN_STATIC, 80, SND_STOP, 1.0, 100);
		}
		RemoveEntity(Projectile);
	}

	return Plugin_Stop; 
}
public void Redeemer_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	
	if(Local_Timer[client] == null)
		return;
	int Rocket = EntRefToEntIndex(PlayerToRocket[client]);
	if(!IsValidEntity(Rocket))
		return;

	float fVel[3];
	GetEntPropVector(Rocket, Prop_Data, "m_vInitialVelocity", fVel);
	float speed = getLinearVelocity(fVel);

	if(speed <= 0.0)
		return;

	float anglesrocket[3];
	GetEntPropVector(Rocket, Prop_Data, "m_angRotation", anglesrocket);
	anglesrocket[0] += float(mouse[1]) * 0.1;
	anglesrocket[1] -= float(mouse[0]) * 0.1;

	float fBuf[3];
	GetAngleVectors(anglesrocket, fBuf, NULL_VECTOR, NULL_VECTOR);
	fVel[0] = fBuf[0]*speed;
	fVel[1] = fBuf[1]*speed;
	fVel[2] = fBuf[2]*speed;
	Custom_SetAbsVelocity(Rocket, fVel);	
	SetEntPropVector(Rocket, Prop_Data, "m_angRotation", anglesrocket);
	buttons = 0;
}
static Action Timer_Local(Handle timer, DataPack pack)
{
	pack.Reset();
	int clientidx = pack.ReadCell();
	int client = EntRefToEntIndex(pack.ReadCell());
	int rocket = EntRefToEntIndex(pack.ReadCell());
	if(!IsValidClient(client) || !IsClientInGame(client))
	{
		Local_Timer[clientidx] = null;
		return Plugin_Stop;
	}	
	f_RetryRespawn[client] = GetGameTime() + 0.5;
	if(!IsValidEntity(rocket))
	{
		PrintCenterText(client, "");

		SetEntProp(client, Prop_Send, "m_bForceLocalPlayerDraw", 0);
		SetClientViewEntity(client, client);
		Local_Timer[clientidx] = null;
		return Plugin_Stop;
	}
	else
	{
		f_WandDamage[rocket] *= 1.05;
		if(f_WandDamage[rocket] >= 1000.0)
			f_WandDamage[rocket] = 1000.0;
		float fVel[3];

		PrintCenterText(client, "Control your rocket with your mouse!\nThe more it flies, the more damage it will deal.");
		SetEntProp(client, Prop_Send, "m_hObserverTarget", -1);
		GetEntPropVector(rocket, Prop_Data, "m_vInitialVelocity", fVel);
		float speed = getLinearVelocity(fVel);
		if(speed < 1500.0)
		{
			ScaleVector(fVel, 1.02);
			speed = getLinearVelocity(fVel);
			if(speed > 1500.0)
			{
				int particle = EntRefToEntIndex(i_WandParticle[rocket]);
				if(IsValidEntity(particle))
					RemoveEntity(particle);

							
				EmitSoundToClient(client,g_Boowomp[GetRandomInt(0, sizeof(g_Boowomp) - 1)], rocket, SNDCHAN_STATIC, 80, SND_STOP, 1.0, 100);
				EmitSoundToClient(client,g_Boowomp[GetRandomInt(0, sizeof(g_Boowomp) - 1)], rocket, SNDCHAN_STATIC, 80, _, 1.0, 80);
				EmitSoundToClient(client,g_CritBoost[GetRandomInt(0, sizeof(g_CritBoost) - 1)], rocket, SNDCHAN_STATIC, 80, _, 1.0, 100);

				float vAbsorigin[3];
				GetAbsOrigin(rocket, vAbsorigin);
				static float fAng[3];
				GetEntPropVector(rocket, Prop_Send, "m_angRotation", fAng);

				particle = ParticleEffectAt(vAbsorigin, "critical_rocket_red", 0.0); //Inf duartion
				TeleportEntity(particle, NULL_VECTOR, fAng, NULL_VECTOR);
				SetParent(rocket, particle);	
				SetEntityCollisionGroup(particle, 27);
				i_WandParticle[rocket] = EntIndexToEntRef(particle);
			}
			Custom_SetAbsVelocity(rocket, fVel);	
			SetEntPropVector(rocket, Prop_Data, "m_vInitialVelocity", fVel);
		}
	}

	return Plugin_Continue;
}

public void RedeemerTouch(int entity, int target)
{
	if (target >= 0)	
	{
		int owner = EntRefToEntIndex(i_WandOwner[entity]);
		if(!IsValidClient(owner))
		{
			RemoveEntity(entity);
			return;
		}
		EmitSoundToClient(owner, g_Boowomp[GetRandomInt(0, sizeof(g_Boowomp) - 1)], entity, SNDCHAN_STATIC, 80, SND_STOP, 1.0, 100);
		EmitSoundToClient(owner,g_CritBoost[GetRandomInt(0, sizeof(g_CritBoost) - 1)], entity, SNDCHAN_STATIC, 80, SND_STOP, 1.0, 100);
		int particle = EntRefToEntIndex(i_WandParticle[entity]);
		//Code to do damage position and ragdolls
		static float angles[3];
		GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
		float vecForward[3];
		GetAngleVectors(angles, vecForward, NULL_VECTOR, NULL_VECTOR);
		static float Entity_Position[3];
		WorldSpaceCenter(entity, Entity_Position);


		if(f_WandDamage[entity] < 500.0)
		{
			TF2_Explode(owner, Entity_Position, f_WandDamage[entity], 150.0, "", "common/null.wav");
			TE_Particle("rd_robot_explosion", Entity_Position, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
			EmitSoundToAll("mvm/mvm_tank_explode.wav", 0, SNDCHAN_STATIC, 60, _, 0.5,_,_,Entity_Position);
		}
		else
		{
			TF2_Explode(owner, Entity_Position, f_WandDamage[entity], 250.0, "", "common/null.wav");
			TE_Particle("hightower_explosion", Entity_Position, NULL_VECTOR, NULL_VECTOR, -1, _, _, _, _, _, _, _, _, _, 0.0);
			EmitSoundToAll("mvm/mvm_tank_explode.wav", 0, SNDCHAN_STATIC, 80, _, 0.85,_,_,Entity_Position);
		}

		if(IsValidEntity(particle))
			RemoveEntity(particle);

		if(IsValidClient(owner))
		{
			SetEntProp(owner, Prop_Send, "m_bForceLocalPlayerDraw", 0);
			SetClientViewEntity(owner, owner);
			if(Local_Timer[owner] != null)
			{
				delete Local_Timer[owner];
			}
		}
		RemoveEntity(entity);
	}
}

