#pragma semicolon 1
#pragma newdecls required

static char BonkBat_Sound[64] = "tf2ware_ultimate/bonk_bat_hit.wav";
static int BonkBat_ModelIndex;

public void BonkBat_MapStart()
{
    AddFileToDownloadsTable("sound/tf2ware_ultimate/bonk_bat_hit.wav");
    AddFileToDownloadsTable("models/weapons/c_models/tf2ware/c_bonk_bat.mdl");
    AddFileToDownloadsTable("materials/models/weapons/c_items/tf2ware/c_candy_cane_blu.vmt");
    AddFileToDownloadsTable("materials/models/weapons/c_items/tf2ware/c_candy_cane_blu.vtf");
    AddFileToDownloadsTable("materials/models/weapons/c_items/tf2ware/c_candy_cane_red.vmt");
    AddFileToDownloadsTable("materials/models/weapons/c_items/tf2ware/c_candy_cane_red.vtf");
    
    PrecacheSound(BonkBat_Sound);
    BonkBat_ModelIndex = PrecacheModel("models/weapons/c_models/tf2ware/c_bonk_bat.mdl");
   
}

// public void BonkBat_OnCreate(int client, int weapon)
// {
//     for (int i = 0; i < 4; i++)
//     {
// 		SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", BonkBat_ModelIndex, 4, i);
//     }
//     SetEntProp(weapon, Prop_Send, "m_bBeingRepurposedForTaunt", 1, 1);
//     SetEntProp(weapon, Prop_Send, "m_nRenderMode", 1); // kRenderTransColor
// }

public Action BonkBat_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(victim != -1 && attacker != -1 && (damagetype & DMG_CLUB))
    {
        if(damage > 0.0)
        {
            EmitSoundToAll(BonkBat_Sound, victim, SNDCHAN_ITEM, 70, _, 1.0);
        }
        
        damage = 1.0;
        
        // unground
        // SetPropEntity(victim, "m_hGroundEntity", null)
        SetEntPropEnt(victim, Prop_Send, "m_hGroundEntity", -1);
        // victim.RemoveFlag(FL_ONGROUND)
        SetEntProp(victim, Prop_Data, "m_fFlags", (GetEntProp(victim, Prop_Data, "m_fFlags") & ~FL_ONGROUND));
        
        // local scale = 450.0
        float scale = 450.0;
        
        ScaleVector(damageForce, scale);
        
        // // local dir = attacker.EyeAngles().Forward()
        // float eyeangles[3], dir[3], vel[3], origin[3];
        // GetClientEyeAngles(attacker, eyeangles);
        // GetAngleVectors(eyeangles, dir, NULL_VECTOR, NULL_VECTOR);
        // // local vel = victim.GetAbsVelocity()
        // GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vel); 
        // // dir.z = Max(dir.z, 0.0)
        // dir[2] = BonkBat_Max(dir[2], 0.0);
        // // vel += dir * scale
        // ScaleVector(dir, scale);
        
        // float final_vel[3];
        // AddVectors(vel, dir, final_vel);
        // // vel.z += scale
        // final_vel[2] += scale;
        // // victim.SetAbsVelocity(vel)
        // Custom_SetAbsVelocity(victim, vel);				
        // // victim.EmitSound(bat_hit_sound)
        // GetClientAbsOrigin(victim, origin);
        
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}

public float BonkBat_Max(float f1, float f2)
{
    return f1 > f2 ? f1 : f2;
}