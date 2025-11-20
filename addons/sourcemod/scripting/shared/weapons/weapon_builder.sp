#pragma semicolon 1
#pragma newdecls required

public void BuilderSentry_WeaponCreated(int client, int weapon)
{
	SpawnWeapon(client, "tf_weapon_pda_engineer_build", 25, 5, 6, {0}, NULL_VECTOR, 0, view_as<int>(TFClass_Engineer));
	SpawnWeapon(client, "tf_weapon_pda_engineer_destroy", 26, 5, 6, {0}, NULL_VECTOR, 0, view_as<int>(TFClass_Engineer));
	
	int entity = SpawnWeapon(client, "tf_weapon_builder", 28, 5, 6, {0}, NULL_VECTOR, 0, view_as<int>(TFClass_Engineer));
	if(entity != -1)
	{
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", true, _, view_as<int>(TFObject_Sentry));
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, view_as<int>(TFObject_Dispenser));
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, view_as<int>(TFObject_Teleporter));
		SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", false, _, view_as<int>(TFObject_Sapper));
	}
}