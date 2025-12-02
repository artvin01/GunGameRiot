#pragma semicolon 1
#pragma newdecls required

static NextBotActionFactory BaseAction;

void Barracks_PluginStart()
{
	BaseAction = new NextBotActionFactory("TGGBarrackBase");
	BaseAction.BeginDataMapDesc()
		.DefineIntField("m_PathFollower")
		.EndDataMapDesc();
	BaseAction.SetCallback(NextBotActionCallbackType_OnStart, OnStart);
	BaseAction.SetCallback(NextBotActionCallbackType_Update, Update);
	BaseAction.SetCallback(NextBotActionCallbackType_OnEnd, OnEnd);

	CEntityFactory factory = new CEntityFactory("tgg_barrack", OnCreate, OnRemove);
	factory.DeriveFromNPC();
	factory.SetInitialActionFactory(BaseAction);
	factory.BeginDataMapDesc()
		.DefineIntField("m_moveYawParameter")
		.DefineIntField("m_idleSequence")
		.DefineIntField("m_runSequence")
		.DefineIntField("m_attackSequence")
		.DefineVectorField("m_vecTarget")
		.DefineEntityField("m_hTarget")
		.DefineFloatField("m_flNextAttack")
		.DefineFloatField("m_flHitAttack")
	.EndDataMapDesc();

	factory.Install();
}

public void Barracks_WeaponCreated(int client, int weapon)
{
}

static void OnCreate(CBaseEntity entity)
{
	PrecacheModel("models/police.mdl");

	entity.SetPropEnt(Prop_Data, "m_hTarget", -1);

	entity.SetModel("models/police.mdl");

	entity.SetProp(Prop_Data, "m_iHealth", 99999);
	entity.SetProp(Prop_Data, "m_moveYawParameter", -1);
	entity.SetProp(Prop_Data, "m_idleSequence", -1);
	entity.SetProp(Prop_Data, "m_runSequence", -1);
	entity.SetProp(Prop_Data, "m_attackSequence", -1);

	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(entity.index);

	npc.flStepSize = 18.0;
	npc.flGravity = 800.0;
	npc.flAcceleration = 2000.0;
	npc.flJumpHeight = 85.0;
	npc.flWalkSpeed = 500.0;
	npc.flRunSpeed = 500.0;
	npc.flDeathDropHeight = 2000.0;
	npc.flMaxYawRate = 250.0;

	SDKHook(entity.index, SDKHook_SpawnPost, SpawnPost);
	SDKHook(entity.index, SDKHook_Think, Think);

	CBaseNPC_Locomotion loco = npc.GetLocomotion();
	loco.SetCallback(LocomotionCallback_ClimbUpToLedge, LocomotionClimbUpToLedge);
	loco.SetCallback(LocomotionCallback_ShouldCollideWith, LocomotionShouldCollideWith);
	loco.SetCallback(LocomotionCallback_IsEntityTraversable, LocomotionIsEntityTraversable);
}

static bool LocomotionClimbUpToLedge(CBaseNPC_Locomotion loco, const float goal[3], const float fwd[3], int entity)
{
	float feet[3];
	loco.GetFeet(feet);

	if (GetVectorDistance(feet, goal) > loco.GetDesiredSpeed())
	{
		return false;
	}

	return loco.CallBaseFunction(goal, fwd, entity);
}

static bool LocomotionShouldCollideWith(CBaseNPC_Locomotion loco, CBaseEntity other)
{
	if (other.index > 0 && other.index <= MaxClients)
	{
		return true;
	}

	return loco.CallBaseFunction(other);
}

static bool LocomotionIsEntityTraversable(CBaseNPC_Locomotion loco, CBaseEntity obstacle, TraverseWhenType when)
{
	return loco.CallBaseFunction(obstacle, when);
}

static void OnRemove(CBaseCombatCharacter entity)
{
}

static void SpawnPost(int index)
{
	CBaseCombatCharacter entity = CBaseCombatCharacter(index);
	
	entity.SetProp(Prop_Data, "m_moveYawParameter", entity.LookupPoseParameter("move_yaw"));
	entity.SetProp(Prop_Data, "m_idleSequence", entity.LookupSequence("batonidle1"));
	entity.SetProp(Prop_Data, "m_runSequence", entity.LookupSequence("walk_all"));
	entity.SetProp(Prop_Data, "m_attackSequence", entity.LookupSequence("swinggesture"));
}

static void OnStart(NextBotAction action, CBaseCombatCharacter actor, NextBotAction prevAction)
{
	action.SetData("m_PathFollower", ChasePath(LEAD_SUBJECT, _, Path_FilterIgnoreActors, Path_FilterOnlyActors));
}

static int Update(NextBotAction action, CBaseCombatCharacter actor, float interval)
{
	float vecPos[3];
	actor.GetAbsOrigin(vecPos);

	CBaseNPC pNPC = TheNPCs.FindNPCByEntIndex(actor.index);
	NextBotGroundLocomotion loco = pNPC.GetLocomotion();
	INextBot bot = pNPC.GetBot();

	bool onGround = !!(actor.GetFlags() & FL_ONGROUND);

	CBaseEntity target = actor.GetPropEnt(Prop_Data, "m_hTarget");
	if (target.IsValid())
	{
		float vecTargetPos[3];
		target.GetAbsOrigin(vecTargetPos);

		float dist = GetVectorDistance(vecTargetPos, vecPos);

		loco.FaceTowards(vecTargetPos);

		if (dist > 250.0)
		{
			ChasePath path = action.GetData("m_PathFollower");
			if (path)
			{
				loco.Run();
				path.Update(bot, target.index);
			}
		}
		else if (onGround)
		{
			//return action.SuspendFor(TestScoutBotBaitAction());
		}
	}

	float speed = loco.GetGroundSpeed();

	int sequence = actor.GetProp(Prop_Send, "m_nSequence");

	if (speed < 0.01)
	{
		int idleSequence = actor.GetProp(Prop_Data, "m_idleSequence");
		if (idleSequence != -1 && sequence != idleSequence)
		{
			actor.ResetSequence(idleSequence);
		}
	}
	else
	{
		int runSequence = actor.GetProp(Prop_Data, "m_runSequence");
		int airSequence = actor.GetProp(Prop_Data, "m_airSequence");

		if (!onGround)
		{
			if (airSequence != -1 && sequence != airSequence)
			{
				actor.ResetSequence(airSequence);
			}
		}
		else
		{			
			if (runSequence != -1 && sequence != runSequence)
			{
				actor.ResetSequence(runSequence);
			}
		}
	}

	return action.Continue();
}

static void OnEnd(NextBotAction action, CBaseCombatCharacter actor, NextBotAction nextAction)
{
	ChasePath path = action.GetData("m_PathFollower");
	if (path)
	{
		actor.MyNextBotPointer().NotifyPathDestruction(path);
		path.Destroy();
	}
}

static void UpdateTarget(CBaseCombatCharacter entity)
{
	float pos[3];
	entity.GetAbsOrigin(pos);

	float maxDist = 1200.0;
	int target = INVALID_ENT_REFERENCE;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			float otherPos[3];
			GetClientAbsOrigin(i, otherPos);

			float dist = GetVectorDistance(otherPos, pos);
			if (dist < maxDist)
			{
				maxDist = dist;
				target = EntIndexToEntRef(i);
			}
		}
	}

	entity.SetPropEnt(Prop_Data, "m_hTarget", target);
}

static void Think(int index) 
{
	CBaseCombatCharacter entity = CBaseCombatCharacter(index);

	INextBot bot = entity.MyNextBotPointer();

	UpdateTarget(entity);

	CBaseNPC npc = TheNPCs.FindNPCByEntIndex(entity);
	NextBotGroundLocomotion loco = npc.GetLocomotion();

	int moveYawParameter = entity.GetProp(Prop_Data, "m_moveYawParameter");
	int idleSequence = entity.GetProp(Prop_Data, "m_idleSequence");
	int runSequence = entity.GetProp(Prop_Data, "m_runSequence");
	int airSequence = entity.GetProp(Prop_Data, "m_attackSequence");

	float speed = loco.GetGroundSpeed();

	if(speed > 0.01)
	{
		float fwd[3], right[3], up[3];
		entity.GetVectors(fwd, right, up);

		float motionVector[3];
		loco.GetGroundMotionVector(motionVector);

		if(moveYawParameter >= 0)
		{
			float rotFwd = GetVectorDotProduct(motionVector, fwd);
			float rotRight = GetVectorDotProduct(motionVector, right);
			GetVectorAngles(motionVector, angle);

			float rotation = 
			entity.SetPoseParameter(moveYawParameter, rotation);
		}
	}
}