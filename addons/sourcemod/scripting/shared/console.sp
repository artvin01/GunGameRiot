#pragma semicolon 1
#pragma newdecls required

void Console_PluginStart()
{
	AddCommandListener(CommandListener_TeamUISetup, "team_ui_setup"); // This command is automatically executed once players skip the motd, basically a one-time server-side changeteam
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
}

Action CommandListener_TeamUISetup(int client, const char[] command, int args)
{
	// Show clients the arena fight screen instead of only letting players choose one team
	if (n_ForcedTeam <= TFTeam_Spectator)
	{
		// We have to control this since the regular changeteam command is clientside, and we don't want to use the arena team panel commands in here
		ClientFirstTimeChoosingTeam[client] = false;
		return Plugin_Continue;
	}
	
	if (client <= 0 || TF2_GetClientTeam(client) != TFTeam_Unassigned)
		return Plugin_Continue;
	
	if (!ClientFirstTimeChoosingTeam[client])
		return Plugin_Continue;
	
	ShowVGUIPanel(client, "arenateampanel");
	return Plugin_Handled;
}

Action CommandListener_JoinTeam(int client, const char[] command, int args)
{
	if (n_ForcedTeam <= TFTeam_Spectator)
	{
		ClientFirstTimeChoosingTeam[client] = false;
		return Plugin_Continue;
	}
	
	if (client <= 0 || TF2_GetClientTeam(client) != TFTeam_Unassigned)
		return Plugin_Continue;
	
	if (!ClientFirstTimeChoosingTeam[client])
		return Plugin_Continue;
	
	ClientFirstTimeChoosingTeam[client] = false;
	
	char arg[16];
	GetCmdArg(1, arg, 16);
	
	// arenateampanel uses different commands, turn them into the expected commands instead
	if (StrEqual(arg, "spectatearena"))
	{
		FakeClientCommand(client, "spectate");
	}
	else
	{
		if (n_ForcedTeam == TFTeam_Red)
			FakeClientCommand(client, "jointeam red");
		else if (n_ForcedTeam == TFTeam_Blue)
			FakeClientCommand(client, "jointeam blue");
		else
			FakeClientCommand(client, "autoteam");
	}
	
	return Plugin_Handled;
}