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

public Action BonkBat_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(victim != -1 && attacker != -1 && (damagetype & DMG_CLUB) && damage > 0.0)
    {
        EmitSoundToAll(BonkBat_Sound, victim, SNDCHAN_ITEM, 70, _, 1.0);
        damage = 1.0;
        Attributes_Set(victim, Attrib_MultiplyFallDamage, 10.0); 
        return Plugin_Changed;
    }
    
    return Plugin_Continue;
}
