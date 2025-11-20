#pragma semicolon 1
#pragma newdecls required



#define GRAVATON_WAND_MAX_CHARGES 9.0
#define GRAVATON_WAND_CHARGES_GAIN 0.3	//how much per PRIMARY ATTACK you get
#define GRAVATON_WAND_GRAVITATION_COLLAPSE_COST 4.5

#define GRAVATON_WAND_SHOWER_CAST_SOUND1 "weapons/boxing_gloves_crit_enabled.wav"
#define GRAVATON_WAND_SHOWER_CAST_SOUND2 "items/japan_fundraiser/tf_zen_tingsha_05.wav"

#define GRAVATON_WAND_SHOWER_END_SOUND1 "weapons/bumper_car_decelerate.wav"
#define LANTEAN_WAND_SHOT_1 	"weapons/physcannon/energy_sing_flyby1.wav"
#define LANTEAN_WAND_SHOT_2 	"weapons/physcannon/energy_sing_flyby2.wav"

static int LaserIndex;

static const char Spark_Sound[][] = {
	"ambient/energy/spark1.wav",
	"ambient/energy/spark2.wav",
	"ambient/energy/spark3.wav",
	"ambient/energy/spark4.wav",
	"ambient/energy/spark5.wav",
	"ambient/energy/spark6.wav",
};

static const char Zap_Sound[][] = {
	"ambient/energy/zap1.wav",
	"ambient/energy/zap2.wav",
	"ambient/energy/zap3.wav",
	"ambient/energy/zap5.wav",
	"ambient/energy/zap6.wav",
	"ambient/energy/zap7.wav",
	"ambient/energy/zap8.wav",
	"ambient/energy/zap9.wav",
};

public void Gravaton_Wand_MapStart()
{
	PrecacheSound(GRAVATON_WAND_SHOWER_CAST_SOUND1, true);
	PrecacheSound(GRAVATON_WAND_SHOWER_CAST_SOUND2, true);

	PrecacheSound(GRAVATON_WAND_SHOWER_END_SOUND1, true);
	PrecacheSound(LANTEAN_WAND_SHOT_1);
	PrecacheSound(LANTEAN_WAND_SHOT_2);

	for (int i = 0; i < (sizeof(Zap_Sound));	   i++) { PrecacheSound(Zap_Sound[i]);	   }
	for (int i = 0; i < (sizeof(Spark_Sound));	   i++) { PrecacheSound(Spark_Sound[i]);	   }

	LaserIndex = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public void Gravaton_Wand_Primary_Attack(int client, int weapon, bool crit, int slot)
{
	float Time= 2.5;
	float Radius = 175.0;

	Radius *= Attributes_Get(weapon, 103, 1.0);
	Radius *= Attributes_Get(weapon, 104, 1.0);
	Radius *= Attributes_Get(weapon, 475, 1.0);
	Radius *= Attributes_Get(weapon, 101, 1.0);
	Radius *= Attributes_Get(weapon, 102, 1.0);

	float damage = 65.0;
		
	damage *= Attributes_Get(weapon, 410, 1.0);

	float pos[3];
	float ang[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, ang);
	Handle TempTrace = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, BulletAndMeleeTrace, client);

	float vec[3];

	TR_GetEndPosition(vec, TempTrace);
	delete TempTrace;

	int color[4];
	color[0] = 240;
	color[1] = 240;
	color[2] = 240;
	color[3] = 120;

	int loop_for = 7;
	float Seperation = 12.5;
	loop_for = 2;
	Seperation = 7.5;
	Time = 0.85;

	int viewmodelModel;
	viewmodelModel = EntRefToEntIndex(i_Viewmodel_PlayerModel[client]);

	if(IsValidEntity(viewmodelModel))
	{
		float fPos[3], fAng[3];
		GetAttachment(viewmodelModel, "effect_hand_l", fPos, fAng);
		TE_SetupBeamPoints(fPos, vec, LaserIndex, 0, 0, 0, 0.25, 2.5, 2.5, 1, 4.0, color, 0);
		TE_SendToAll();
	}
	else
	{
		GetClientEyePosition(client, pos);
		TE_SetupBeamPoints(pos, vec, LaserIndex, 0, 0, 0, 0.25, 2.5, 2.5, 1, 4.0, color, 0);
		TE_SendToAll();
	}

	


	Handle data;
	CreateDataTimer(Time, Smite_Timer_Gravaton_Wand, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackFloat(data, vec[0]);
	WritePackFloat(data, vec[1]);
	WritePackFloat(data, vec[2]);
	WritePackCell(data, Radius);
	WritePackCell(data, EntIndexToEntRef(client));
	WritePackCell(data, EntIndexToEntRef(weapon));
	WritePackCell(data, damage); 

	switch(GetRandomInt(1, 2))
	{
		case 1:
		{
			EmitSoundToAll(LANTEAN_WAND_SHOT_1, client, _, 65, _, 0.35, 160);
		}
		case 2:
		{
			EmitSoundToAll(LANTEAN_WAND_SHOT_2, client, _, 65, _, 0.35, 160);
		}
	}
	vec[2]+= Seperation*loop_for+10.0;
	float thicc = 3.0;
	float Offset_Time = Time /=loop_for;
	for(int i = 1 ; i <= loop_for ; i++)
	{
		float timer = Offset_Time*i;
		if(timer<=0.02)
			timer=0.02;
		TE_SetupBeamRingPoint(vec, Radius*0.5, 0.0, LaserIndex, LaserIndex, 0, 1, timer, thicc, 0.1, color, 1, 0);

		if(i == loop_for)
			TE_SendToAll();
		else
			TE_SendToClient(client);
		vec[2]-=Seperation;
	}
}

public Action Smite_Timer_Gravaton_Wand(Handle Smite_Logic, DataPack data)
{
	ResetPack(data);
		
	float startPosition[3];
	startPosition[0] = ReadPackFloat(data);
	startPosition[1] = ReadPackFloat(data);
	startPosition[2] = ReadPackFloat(data);
	float Ionrange = ReadPackCell(data);
	int client = EntRefToEntIndex(ReadPackCell(data));
	float damage = ReadPackCell(data);
	
	
	if (!IsValidClient(client))
	{
		return Plugin_Stop;
	}
				

	CreateExplosion(client, startPosition, damage, 125, RoundToNearest(Ionrange));
	
	DataPack pack_boom = new DataPack();
	pack_boom.WriteFloat(startPosition[0]);
	pack_boom.WriteFloat(startPosition[1]);
	pack_boom.WriteFloat(startPosition[2]);
	pack_boom.WriteCell(1);
	RequestFrame(MakeExplosionFrameLater, pack_boom);

	float sky_Loc[3]; sky_Loc = startPosition;
	sky_Loc[2]+=200.0;

	int color[4];
	color[0] = 240;
	color[1] = 240;
	color[2] = 240;
	color[3] = 120;

	switch(GetRandomInt(1, 2))
	{
		case 1:
		{
			EmitSoundToAll(Zap_Sound[GetRandomInt(0, sizeof(Zap_Sound)-1)], 0, SNDCHAN_STATIC, 80, _, 1.0, SNDPITCH_NORMAL, -1, startPosition);
		}
		case 2:
		{
			EmitSoundToAll(Spark_Sound[GetRandomInt(0, sizeof(Spark_Sound)-1)], 0, SNDCHAN_STATIC, 80, _, 1.0, SNDPITCH_NORMAL, -1, startPosition);
		}		
	}

	TE_SetupBeamPoints(startPosition, sky_Loc, LaserIndex, 0, 0, 0, 0.75, 11.0, 1.0, 1, 8.0, color, 0);
	TE_SendToAll();


	return Plugin_Continue;
}
