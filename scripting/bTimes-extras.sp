#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = {
    name = "[bTimes] Extras",
    description = "Weapon commands and cvar enforcement",
    author = "",
    version = "1.0",
    url = ""
}

public void:SetConVar(String:cvar1[], String:n_val[])
{
    new Handle:cvar = FindConVar(cvar1);
    if(cvar){
        SetConVarString(cvar, n_val);
    }
}

public OnPluginStart()
{
    SetConVar("sv_enablebunnyhopping", "1");
    SetConVar("sv_airaccelerate", "1000");
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
}

public Action:GiveGlock(client, args)
{
    //I get the feeling we shouldn't put this in a function for some reason
    if(IsPlayerAlive(client)){
        new e_wep = GetPlayerWeaponSlot(client, 1);
        if(e_wep != -1){
            RemovePlayerItem(client, e_wep);
            AcceptEntityInput(e_wep, "Kill");
        }
        GivePlayerItem(client, "weapon_glock", 0);
    }
    return Plugin_Handled;
}

public Action:GiveUsp(client, args)
{
    if(IsPlayerAlive(client)){
        new e_wep = GetPlayerWeaponSlot(client, 1);
        if(e_wep != -1){
            RemovePlayerItem(client, e_wep);
            AcceptEntityInput(e_wep, "Kill");
        }
        GivePlayerItem(client, "weapon_usp", 0);
    }
    return Plugin_Handled;
}

public Action:GiveKnife(client, args)
{
    if(IsPlayerAlive(client)){
        new e_wep = GetPlayerWeaponSlot(client, 1);
        if(e_wep != -1){
            RemovePlayerItem(client, e_wep);
            AcceptEntityInput(e_wep, "Kill");
        }
        GivePlayerItem(client, "weapon_knife", 0);
    }
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
        SetConVar("sv_airaccelerate", "1000");
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