#pragma semicolon 1
#pragma newdecls required

static char BonkBat_Sound[64] = "tf2ware_ultimate/bonk_bat_hit.wav";

public void BonkBat_MapStart()
{
    PrecacheSound(BonkBat_Sound);
}

public Action BonkBat_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(victim != -1 && attacker != -1 && (damagetype & DMG_CLUB))
    {
        damage = 1.0;
        
        // unground
        // SetPropEntity(victim, "m_hGroundEntity", null)
        SetEntPropEnt(victim, Prop_Send, "m_hGroundEntity", null);
        // victim.RemoveFlag(FL_ONGROUND)
        
        
        // local scale = 450.0
        // local dir = attacker.EyeAngles().Forward()
        // local vel = victim.GetAbsVelocity()
        // dir.z = Max(dir.z, 0.0)
        // vel += dir * scale
        // vel.z += scale
        // victim.SetAbsVelocity(vel)				
        // victim.EmitSound(bat_hit_sound)
    }
}