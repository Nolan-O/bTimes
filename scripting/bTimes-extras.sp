#include <sourcemod>
#include <sdktools>
#include <smlib/clients>

public Plugin:myinfo = {
    name = "[bTimes] Extras",
    description = "Weapon commands and cvar enforcement",
    author = "",
    version = "1.0",
    url = ""
}

new bool:g_bCanReceiveWeapons[MAXPLAYERS] = {true, ...};

public OnClientDisconnect(client)
{
    g_bCanReceiveWeapons[client] = true;
}

public void:SetConVar(String:cvar1[], String:n_val[])
{
    new Handle:cvar = FindConVar(cvar1);
    if(cvar){
        SetConVarString(cvar, n_val);
    }
}

GiveWeapon(client, String:wep[])
{
    if(IsPlayerAlive(client) && g_bCanReceiveWeapons[client]){
        new e_wep = GetPlayerWeaponSlot(client, 1);
        if(e_wep != -1){
            RemovePlayerItem(client, e_wep);
            AcceptEntityInput(e_wep, "Kill");
        }
        e_wep = GetPlayerWeaponSlot(client, 0);
        if(e_wep != -1){
            RemovePlayerItem(client, e_wep);
            AcceptEntityInput(e_wep, "Kill");
        }
        GivePlayerItem(client, wep, 0);
    }
}

public OnPluginStart()
{
    SetConVar("sv_enablebunnyhopping", "1");
    SetConVar("sv_airaccelerate", "100");
    SetConVar("sv_maxvelocity", "100000");
    SetConVar("sv_friction", "4");
    SetConVar("sv_accelerate", "5");
    SetConVar("sv_alltalk", "1");
    
    HookEvent("server_cvar", OnCvarChange, EventHookMode_Pre);
    
    RegConsoleCmd("sm_glock", GiveGlock, "Gives player glock");
    RegConsoleCmd("sm_usp", GiveUsp, "Gives player usp");
    RegConsoleCmd("sm_knife", GiveKnife, "Gives player knife");
    RegConsoleCmd("sm_nightvision", GiveNvgs, "Gives player night vision goggles");
    RegConsoleCmd("sm_nvgs", GiveNvgs, "Gives player night vision goggles");
    RegConsoleCmd("sm_m4a1", GiveM4A1, "Gives player m4a1");
    RegConsoleCmd("sm_deagle", GiveDeagle, "Gives player deagle");
    RegConsoleCmd("sm_elite", GiveElite, "Gives player elite");
    RegConsoleCmd("sm_m3", GiveM3, "Gives player m3");
    RegConsoleCmd("sm_xm1014", GiveXM1014, "Gives player xm1014");
    RegConsoleCmd("sm_galil", GiveGalil, "Gives player galil");
    RegConsoleCmd("sm_ak47", GiveAK47, "Gives player ak47");
    RegConsoleCmd("sm_sg552", GiveSG552, "Gives player sg552");
    RegConsoleCmd("sm_awp", GiveAWP, "Gives player awp");
    RegConsoleCmd("sm_g3sg1", GiveG3SG1, "Gives player g3sg1");
    RegConsoleCmd("sm_famas", GiveFamas, "Gives player famas");
    RegConsoleCmd("sm_p228", GiveP228, "Gives player p228");
    RegConsoleCmd("sm_aug", GiveAUG, "Gives player aug");
    RegConsoleCmd("sm_sg550", GiveSG550, "Gives player sg550");
    RegConsoleCmd("sm_tmp", GiveTMP, "Gives player tmp");
    RegConsoleCmd("sm_mac10", GiveMac10, "Gives player mac10");
    RegConsoleCmd("sm_mp5navy", GiveMp5Navy, "Gives player mp5navy");
    RegConsoleCmd("sm_ump45", GiveUMP45, "Gives player ump45");
    RegConsoleCmd("sm_p90", GiveP90, "Gives player p90");
    RegConsoleCmd("sm_m249", GiveM249, "Gives player m249");
    RegAdminCmd("sm_stripweps", StripWeapons, ADMFLAG_GENERIC, "Strips a player's weapons and blocks them from weapon commands");
    RegAdminCmd("sm_stripweapons", StripWeapons, ADMFLAG_GENERIC, "Strips a player's weapons and blocks them from weapon commands");
}

public Action:GiveM249(client, args)
{
    GiveWeapon(client, "weapon_m249");
    return Plugin_Handled;
}

public Action:GiveP90(client, args)
{
    GiveWeapon(client, "weapon_p90");
    return Plugin_Handled;
}

public Action:GiveUMP45(client, args)
{
    GiveWeapon(client, "weapon_ump45");
    return Plugin_Handled;
}

public Action:GiveMp5Navy(client, args)
{
    GiveWeapon(client, "weapon_mp5navy");
    return Plugin_Handled;
}

public Action:GiveMac10(client, args)
{
    GiveWeapon(client, "weapon_mac10");
    return Plugin_Handled;
}

public Action:GiveTMP(client, args)
{
    GiveWeapon(client, "weapon_tmp");
    return Plugin_Handled;
}

public Action:GiveSG550(client, args)
{
    GiveWeapon(client, "weapon_sg550");
    return Plugin_Handled;
}

public Action:GiveAUG(client, args)
{
    GiveWeapon(client, "weapon_aug");
    return Plugin_Handled;
}

public Action:GiveP228(client, args)
{
    GiveWeapon(client, "weapon_p228");
    return Plugin_Handled;
}

public Action:GiveG3SG1(client, args)
{
    GiveWeapon(client, "weapon_g3sg1");
    return Plugin_Handled;
}

public Action:GiveAWP(client, args)
{
    GiveWeapon(client, "weapon_awp");
    return Plugin_Handled;
}

public Action:GiveSG552(client, args)
{
    GiveWeapon(client, "weapon_sg552");
    return Plugin_Handled;
}

public Action:GiveAK47(client, args)
{
    GiveWeapon(client, "weapon_ak47");
    return Plugin_Handled;
}

public Action:GiveGalil(client, args)
{
    GiveWeapon(client, "weapon_galil");
    return Plugin_Handled;
}

public Action:GiveXM1014(client, args)
{
    GiveWeapon(client, "weapon_xm1014");
    return Plugin_Handled;
}

public Action:GiveM3(client, args)
{
    GiveWeapon(client, "weapon_m3");
    return Plugin_Handled;
}

public Action:GiveSeven(client, args)
{
    GiveWeapon(client, "weapon_seven");
    return Plugin_Handled;
}

public Action:GiveElite(client, args)
{
    GiveWeapon(client, "weapon_elite");
    return Plugin_Handled;
}

public Action:GiveDeagle(client, args)
{
    GiveWeapon(client, "weapon_deagle");
    return Plugin_Handled;
}

public Action:GiveFamas(client, args)
{
    GiveWeapon(client, "weapon_famas");
    return Plugin_Handled;
}

public Action:GiveM4A1(client, args)
{
    GiveWeapon(client, "weapon_m4a1");
    return Plugin_Handled;
}

public Action:StripWeapons(client, args)
{
    decl String:arg1[32];
    GetCmdArg(1, arg1, sizeof(arg1));
    //Yes you can use this on bots
    new target = Client_FindByName(arg1);
    if(target == -1)
    {
        PrintToChat(client, "Could not find that player");
        return Plugin_Handled;
    }
    if(g_bCanReceiveWeapons[target])
    {
        g_bCanReceiveWeapons[target] = false;
        if(IsPlayerAlive(target)){
            new e_wep = GetPlayerWeaponSlot(target, 1);
            if(e_wep != -1){
                RemovePlayerItem(target, e_wep);
                AcceptEntityInput(e_wep, "Kill");
            }
        }
        PrintToChat(client, "Player '%N' can no longer use weapon commands", target);
        PrintToChat(target, "An admin has stripped your ability to use weapon commands!");
    }
    else
    {
        g_bCanReceiveWeapons[target] = true;
        PrintToChat(client, "Player '%N' can now use weapons commands again", target);
        PrintToChat(target, "Weapon command access has been restored.");
    }
    return Plugin_Handled;
}

public Action:GiveGlock(client, args)
{
    GiveWeapon(client, "weapon_glock");
    return Plugin_Handled;
}

public Action:GiveUsp(client, args)
{
    GiveWeapon(client, "weapon_usp");
    return Plugin_Handled;
}

public Action:GiveKnife(client, args)
{
    GiveWeapon(client, "weapon_knife");
    return Plugin_Handled;
}

public Action:GiveNvgs(client, args)
{
    if(IsPlayerAlive(client)){
        if(GetEntProp(client, Prop_Send, "m_bHasNightVision" ) != 0){
            SetEntProp(client, Prop_Send, "m_bHasNightVision", 0);
        }
        GivePlayerItem(client, "item_nvgs", 0);
    }
    return Plugin_Handled;
}

public Action:OnCvarChange(Handle:event, const String:name[], bool:dontbroadcast)
{
    decl String:cvar_string[64];
    GetEventString(event, "cvarname", cvar_string, 64);
    if(StrEqual(cvar_string, "sv_airaccelerate"))
        SetConVar("sv_airaccelerate", "100");
    else if(StrEqual(cvar_string, "sv_enablebunnyhopping"))
        SetConVar("sv_enablebunnyhopping", "1");
    else if(StrEqual(cvar_string, "sv_maxvelocity"))
        SetConVar("sv_maxvelocity", "1000000");
    else if(StrEqual(cvar_string, "sv_accelerate"))
        SetConVar("sv_accelerate", "5");
    else if(StrEqual(cvar_string, "sv_alltalk"))
        SetConVar("sv_alltalk", "1");               //any more??
    return Plugin_Handled;
}