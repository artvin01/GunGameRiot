#pragma semicolon 1
#pragma newdecls required

static int i_ProjectileIndex;
Function func_WandOnTouch[MAXENTITIES];
#define ENERGY_BALL_MODEL	"models/weapons/w_models/w_drg_ball.mdl"

void WandStocks_Map_Precache()
{
	i_ProjectileIndex = PrecacheModel(ENERGY_BALL_MODEL);
}

stock void WandProjectile_ApplyFunctionToEntity(int projectile, Function Function)
{
	func_WandOnTouch[projectile] = Function;
}

stock Function func_WandOnTouchReturn(int entity)
{
	return func_WandOnTouch[entity];
}

void WandProjectile_GamedataInit()
{
	CEntityFactory EntityFactory = new CEntityFactory("zr_projectile_base", OnCreate_Proj, OnDestroy_Proj);
	EntityFactory.DeriveFromClass("tf_projectile_rocket");
	EntityFactory.BeginDataMapDesc()
	.EndDataMapDesc(); 

	EntityFactory.Install();
}

stock int Wand_Projectile_Spawn(int client,
float speed,
float time,
float damage,
int WandId,
int weapon,
const char[] WandParticle,
float CustomAng[3] = {0.0,0.0,0.0},
bool hideprojectile = true,
float CustomPos[3] = {0.0,0.0,0.0}) //This will handle just the spawning, the rest like particle effects should be handled within the plugins themselves. hopefully.
{
	float fAng[3], fPos[3];
	if(client <= MaxClients)
	{
		GetClientEyeAngles(client, fAng);
		GetClientEyePosition(client, fPos);
	}

	if(CustomAng[0] != 0.0 || CustomAng[1] != 0.0)
	{
		fAng[0] = CustomAng[0];
		fAng[1] = CustomAng[1];
		fAng[2] = CustomAng[2];
	}
	if(CustomPos[0] != 0.0 || CustomPos[1] != 0.0)
	{
		fPos[0] = CustomPos[0];
		fPos[1] = CustomPos[1];
		fPos[2] = CustomPos[2];
	}

	if(speed >= 3000.0)
	{
		speed = 3000.0;
		//if its too fast, then it can cause projectile devietion
	}

	if(client <= MaxClients && CustomPos[0] == 0.0 && CustomPos[1] == 0.0)
	{
		float tmp[3];
		float actualBeamOffset[3];
		float BEAM_BeamOffset[3];
		BEAM_BeamOffset[0] = 0.0;
		BEAM_BeamOffset[1] = -8.0;
		BEAM_BeamOffset[2] = -10.0;

		tmp[0] = BEAM_BeamOffset[0];
		tmp[1] = BEAM_BeamOffset[1];
		tmp[2] = 0.0;
		VectorRotate(tmp, fAng, actualBeamOffset);
		actualBeamOffset[2] = BEAM_BeamOffset[2];
		fPos[0] += actualBeamOffset[0];
		fPos[1] += actualBeamOffset[1];
		fPos[2] += actualBeamOffset[2];
	}


	float fVel[3], fBuf[3];
	GetAngleVectors(fAng, fBuf, NULL_VECTOR, NULL_VECTOR);
	fVel[0] = fBuf[0]*speed;
	fVel[1] = fBuf[1]*speed;
	fVel[2] = fBuf[2]*speed;

	int entity = CreateEntityByName("zr_projectile_base");
	if(IsValidEntity(entity))
	{
		i_WandOwner[entity] = EntIndexToEntRef(client);
		if(IsValidEntity(weapon))
			i_WandWeapon[entity] = EntIndexToEntRef(weapon);
			
		f_WandDamage[entity] = damage;
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client); //No owner entity! woo hoo
		//Edit: Need owner entity, otheriwse you can actuall hit your own god damn rocket and make a ding sound. (Really annoying.)
		SetEntDataFloat(entity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected")+4, 0.0, true);	// Damage should be nothing. if it somehow goes boom.
		SetTeam(entity, GetTeam(client));
		int frame = GetEntProp(entity, Prop_Send, "m_ubInterpolationFrame");
		TeleportEntity(entity, fPos, fAng, NULL_VECTOR);
		DispatchSpawn(entity);
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fVel);
		SetEntPropVector(entity, Prop_Send, "m_angRotation", fAng); //set it so it can be used
		SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", fVel);
	//	SetEntProp(entity, Prop_Send, "m_flDestroyableTime", GetGameTime());
		//make rockets visible on spawn.
		SetEntPropFloat(entity, Prop_Data, "m_flSimulationTime", GetGameTime());
		SetEntProp(entity, Prop_Send, "m_ubInterpolationFrame", frame);
		
		SetEntityCollisionGroup(entity, 27);
		for(int i; i<4; i++) //This will make it so it doesnt override its collision box.
		{
			SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", i_ProjectileIndex, _, i);
		}
		SetEntityModel(entity, ENERGY_BALL_MODEL);

		//Make it entirely invis. Shouldnt even render these 8 polygons.
	//	SetEntProp(entity, Prop_Send, "m_fEffects", GetEntProp(entity, Prop_Send, "m_fEffects") &~ EF_NODRAW);
		
		if(hideprojectile)
		{
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR); //Make it entirely invis.
			SetEntityRenderColor(entity, 255, 255, 255, 0);
		}

		int particle = 0;

		if(WandParticle[0]) //If it has something, put it in. usually it has one, but incase its invis for some odd reason, allow it to be that.
		{
			particle = ParticleEffectAt(fPos, WandParticle, 0.0); //Inf duartion
			TeleportEntity(particle, NULL_VECTOR, fAng, NULL_VECTOR);
			SetParent(entity, particle);	
			SetEntityCollisionGroup(particle, 27);
			i_WandParticle[entity] = EntIndexToEntRef(particle);
		}

		if(time > 60.0)
		{
			time = 60.0;
		}

		if(time > 0.1) //Make it vanish if there is no time set, or if its too big of a timer to not even bother.
		{
			DataPack pack;
			CreateDataTimer(time, Timer_RemoveEntity_CustomProjectileWand, pack, TIMER_FLAG_NO_MAPCHANGE);
			pack.WriteCell(EntIndexToEntRef(entity));
			pack.WriteCell(EntIndexToEntRef(particle));
		}
		//so they dont get stuck on entities in the air.
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER); 

		SDKHook(entity, SDKHook_Think, ProjectileBaseThink);
		SDKHook(entity, SDKHook_ThinkPost, ProjectileBaseThinkPost);

		if(h_NpcSolidHookType[entity] != 0)
			DHookRemoveHookID(h_NpcSolidHookType[entity]);
		h_NpcSolidHookType[entity] = 0;
		h_NpcSolidHookType[entity] = g_DHookRocketExplode.HookEntity(Hook_Pre, entity, Wand_DHook_RocketExplodePre); 
		SDKHook(entity, SDKHook_ShouldCollide, Never_ShouldCollide);
		SDKHook(entity, SDKHook_StartTouch, Wand_Base_StartTouch);

		return entity;
	}

	//Somehow failed...
	return -1;
}

public void ProjectileBaseThink(int Projectile)
{	
	/*
		Why does this exist?
		When using FSOLID_NOT_SOLID | FSOLID_TRIGGER to fix projectiles getting stuck in npcs i.e. setting speed to 0
		Another problem acurred.

		When a projectile chekcs the world, these flags can cause the projectile to just go through entities without calling start touch.
		My guess is tat a trace that happens only checks the world, and not any entities.

		This fires a trace ourselves and calls whatever we need.
	*/

	ArrayList Projec_HitEntitiesInTheWay = new ArrayList();
	DataPack packFilter = new DataPack();
	packFilter.WriteCell(Projec_HitEntitiesInTheWay);
	packFilter.WriteCell(Projectile);
	
	static float AbsOrigin[3];
	GetAbsOrigin(Projectile, AbsOrigin);
	static float CurrentVelocity[3];
	GetEntPropVector(Projectile, Prop_Data, "m_vecAbsVelocity", CurrentVelocity);

	CurrentVelocity[0] *= 0.05;
	CurrentVelocity[1] *= 0.05;
	CurrentVelocity[2] *= 0.05;

	static float VecEndLocation[3];
	VecEndLocation[0] = AbsOrigin[0] + CurrentVelocity[0];
	VecEndLocation[1] = AbsOrigin[1] + CurrentVelocity[1];
	VecEndLocation[2] = AbsOrigin[2] + CurrentVelocity[2];

//	int g_iPathLaserModelIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
//	TE_SetupBeamPoints(AbsOrigin, VecEndLocation, g_iPathLaserModelIndex, g_iPathLaserModelIndex, 0, 30, 1.0, 1.0, 0.1, 5, 0.0, view_as<int>({255, 0, 255, 255}), 30);
//	TE_SendToAll();
	Handle trace = TR_TraceRayFilterEx( AbsOrigin, VecEndLocation, ( MASK_ALL ), RayType_EndPoint, ProjectileTraceHitTargets, packFilter );
	delete packFilter;
	delete trace;

	int length = Projec_HitEntitiesInTheWay.Length;
	for (int i = 0; i < length; i++)
	{
		int entity_traced = Projec_HitEntitiesInTheWay.Get(i);
		Wand_Base_StartTouch(Projectile, entity_traced);
	}
	delete Projec_HitEntitiesInTheWay;
	
}

bool ProjectileTraceHitTargets(int entity, int contentsMask, DataPack packFilter)
{
	if(entity == 0)
	{
		return false;
	}
	packFilter.Reset();
	ArrayList Projec_HitEntitiesInTheWay = packFilter.ReadCell();
	int iExclude = packFilter.ReadCell();
	if(entity == iExclude)
	{
		return false;
	}
	int target = entity;
	target = Target_Hit_Wand_Detection(iExclude, entity);
		
	if(target > 0)
	{
		//This will automatically take care of all the checks, very handy. force it to also target invul enemies.
		//Add a new entity to the arrray list
		Projec_HitEntitiesInTheWay.Push(entity);
	}
	return false;
}

public void ProjectileBaseThinkPost(int Projectile)
{
	CBaseCombatCharacter(Projectile).SetNextThink(GetGameTime() + 0.05);
}
public MRESReturn Wand_DHook_RocketExplodePre(int arrow)
{
	return MRES_Supercede; //DONT.
}

public Action Timer_RemoveEntity_CustomProjectileWand(Handle timer, DataPack pack)
{
	pack.Reset();
	int Projectile = EntRefToEntIndex(pack.ReadCell());
	int Particle = EntRefToEntIndex(pack.ReadCell());
	if(IsValidEntity(Projectile) && Projectile>MaxClients)
	{
		RemoveEntity(Projectile);
	}
	if(IsValidEntity(Particle) && Particle>MaxClients)
	{
		RemoveEntity(Particle);
	}
	return Plugin_Stop; 
}


public void Wand_Base_StartTouch(int entity, int other)
{
	int target = other;
	target = Target_Hit_Wand_Detection(entity, other);
	Function func = func_WandOnTouch[entity];
	if(func && func != INVALID_FUNCTION)
	{
		Call_StartFunction(null, func);
		Call_PushCell(entity);
		Call_PushCell(target);
		Call_Finish();
		//todo: convert all on death and on take damage to this.
		return;
	}
}

static void OnCreate_Proj(CBaseCombatCharacter body)
{
	int extra_index = EntRefToEntIndex(iref_PropAppliedToRocket[body.index]);
	if(IsValidEntity(extra_index))
		RemoveEntity(extra_index);

	iref_PropAppliedToRocket[body.index] = INVALID_ENT_REFERENCE;
	return;
}
static void OnDestroy_Proj(CBaseCombatCharacter body)
{
	int extra_index = EntRefToEntIndex(iref_PropAppliedToRocket[body.index]);
	if(IsValidEntity(extra_index))
		RemoveEntity(extra_index);

	iref_PropAppliedToRocket[body.index] = INVALID_ENT_REFERENCE;

	func_WandOnTouch[body.index] = INVALID_FUNCTION;

	return;
}

stock int ApplyCustomModelToWandProjectile(int rocket, char[] modelstringname, float ModelSize, char[] defaultAnimation, float OffsetDown = 0.0)
{
	int extra_index = EntRefToEntIndex(iref_PropAppliedToRocket[rocket]);
	if(IsValidEntity(extra_index))
		RemoveEntity(extra_index);
	
	int entity = CreateEntityByName("prop_dynamic_override");
	if(IsValidEntity(entity))
	{
		DispatchKeyValue(entity, "targetname", "rpg_fortress");
		DispatchKeyValue(entity, "model", modelstringname);
		
		
		static float rocketOrigin[3];
		static float rocketang[3];
		GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", rocketOrigin);
		GetEntPropVector(rocket, Prop_Data, "m_angRotation", rocketang);
		int frame = GetEntProp(entity, Prop_Send, "m_ubInterpolationFrame");
		TeleportEntity(entity, rocketOrigin, rocketang, NULL_VECTOR);
		SetEntPropFloat(entity, Prop_Data, "m_flSimulationTime", GetGameTime());
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Send, "m_ubInterpolationFrame", frame);
		MakeObjectIntangeable(entity);
		if(OffsetDown == 0.0)
			SetParent(rocket, entity);
		else
		{
			float Offset3[3];
			Offset3[2] = OffsetDown;
			SetParent(rocket, entity, "root", Offset3, false);
		}
		iref_PropAppliedToRocket[rocket] = EntIndexToEntRef(entity);
		
		if(defaultAnimation[0])
		{	
			/*
			CBaseCombatCharacter npc = view_as<CBaseCombatCharacter>(entity);
			npc.AddActivityViaSequence(defaultAnimation);
			*/
		}
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", ModelSize);
		return entity;
	}
	return -1;
}


stock int Target_Hit_Wand_Detection(int owner_projectile, int other_entity)
{
	if(owner_projectile < 1)
	{
		return -1; //I dont exist?
	}
	int owner = EntRefToEntIndex(i_WandOwner[owner_projectile]);
	if(owner == other_entity)
		return -1;
	if(other_entity < 0)
	{
		return -1; //I dont exist?
	}
	else if(other_entity == 0)
	{
		return 0;
	}
	else if(b_ThisEntityIsAProjectileForUpdateContraints[owner_projectile] && b_ThisEntityIsAProjectileForUpdateContraints[other_entity])
	{
		return -1;
	}
	else if(IsValidEnemy(owner_projectile, other_entity, true, true))
	{
		
		return other_entity;
	}
	return 0;
}


public bool Never_ShouldCollide(int client, int collisiongroup, int contentsmask, bool originalResult)
{
	return false;
} 