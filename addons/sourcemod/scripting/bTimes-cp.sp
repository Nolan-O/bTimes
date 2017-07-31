#pragma semicolon 1

#include <bTimes-core>

public Plugin:myinfo = 
{
    name = "[bTimes] Checkpoints", 
    author = "blacky", 
    description = "Checkpoints plugin for the timer", 
    version = VERSION, 
    url = "http://steamcommunity.com/id/blaackyy/"
}

#include <sdktools>
#include <sourcemod>
#include <bTimes-timer>
#include <bTimes-random>
#include <bTimes-zones>
#include <smlib/entities>

#define MAX_CP 20

enum
{
    GameType_CSS, 
    GameType_CSGO
};

new g_range_one[MAXPLAYERS];
new g_range_two[MAXPLAYERS];

new g_GameType;

new Float:g_cp[MAXPLAYERS + 1][MAX_CP][3][3];
new g_cpcount[MAXPLAYERS + 1];

new bool:g_UsePos[MAXPLAYERS + 1] =  { true, ... };
new bool:g_UseVel[MAXPLAYERS + 1] =  { true, ... };
new bool:g_UseAng[MAXPLAYERS + 1] =  { true, ... };

new g_LastUsed[MAXPLAYERS + 1], 
bool:g_HasLastUsed[MAXPLAYERS + 1];

new bool:g_BlockTpTo[MAXPLAYERS + 1][MAXPLAYERS + 1];

new String:g_msg_start[128], 
String:g_msg_varcol[128], 
String:g_msg_textcol[128];

// Cvars
new Handle:g_hAllowCp;

public OnPluginStart()
{
    decl String:sGame[64];
    GetGameFolderName(sGame, sizeof(sGame));
    
    if (StrEqual(sGame, "cstrike"))
        g_GameType = GameType_CSS;
    else if (StrEqual(sGame, "csgo"))
        g_GameType = GameType_CSGO;
    else
        SetFailState("This timer does not support this game (%s)", sGame);
    
    // Cvars
    g_hAllowCp = CreateConVar("timer_allowcp", "1", "Allows players to use the checkpoint plugin's features.", 0, true, 0.0, true, 1.0);
    
    AutoExecConfig(true, "cp", "timer");
    
    // Commands
    RegConsoleCmdEx("sm_telelast", SM_TeleLast, "Teleports to last checkpoint.");
    RegConsoleCmdEx("sm_cp", SM_CP, "Opens the checkpoint menu.");
    RegConsoleCmdEx("sm_checkpoint", SM_CP, "Opens the checkpoint menu.");
    RegConsoleCmdEx("sm_tele", SM_Tele, "Teleports you to the specified checkpoint.");
    RegConsoleCmdEx("sm_tp", SM_Tele, "Teleports you to the specified checkpoint.");
    RegConsoleCmdEx("sm_save", SM_Save, "Saves a new checkpoint.");
    RegConsoleCmdEx("sm_tpto", SM_TpTo, "Teleports you to a player.");
    
    // Makes FindTarget() work properly
    LoadTranslations("common.phrases");
}

public OnClientPutInServer(client)
{
    g_cpcount[client] = 0;
    
    for (new i = 1; i <= MaxClients; i++)
    {
        g_BlockTpTo[i][client] = false;
    }
}

public OnTimerChatChanged(MessageType, String:Message[])
{
    if (MessageType == 0)
    {
        Format(g_msg_start, sizeof(g_msg_start), Message);
        ReplaceMessage(g_msg_start, sizeof(g_msg_start));
    }
    else if (MessageType == 1)
    {
        Format(g_msg_varcol, sizeof(g_msg_varcol), Message);
        ReplaceMessage(g_msg_varcol, sizeof(g_msg_varcol));
    }
    else if (MessageType == 2)
    {
        Format(g_msg_textcol, sizeof(g_msg_textcol), Message);
        ReplaceMessage(g_msg_textcol, sizeof(g_msg_textcol));
    }
}

ReplaceMessage(String:message[], maxlength)
{
    if (g_GameType == GameType_CSS)
    {
        ReplaceString(message, maxlength, "^", "\x07", false);
    }
    else if (g_GameType == GameType_CSGO)
    {
        ReplaceString(message, maxlength, "^A", "\x0A");
        ReplaceString(message, maxlength, "^1", "\x01");
        ReplaceString(message, maxlength, "^2", "\x02");
        ReplaceString(message, maxlength, "^3", "\x03");
        ReplaceString(message, maxlength, "^4", "\x04");
        ReplaceString(message, maxlength, "^5", "\x05");
        ReplaceString(message, maxlength, "^6", "\x06");
        ReplaceString(message, maxlength, "^7", "\x07");
    }
}

public Action:SM_TpTo(client, args)
{
    if (GetConVarBool(g_hAllowCp))
    {
        if (IsPlayerAlive(client))
        {
            if (args == 0)
            {
                OpenTpToMenu(client);
            }
            else
            {
                decl String:argString[250];
                GetCmdArgString(argString, sizeof(argString));
                new target = FindTarget(client, argString, false, false);
                
                if (client != target)
                {
                    if (target != -1)
                    {
                        if (IsPlayerAlive(target))
                        {
                            if (IsFakeClient(target))
                            {
                                new Float:pos[3];
                                GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
                                
                                StopTimer(client);
                                TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
                            }
                            else
                            {
                                SendTpToRequest(client, target);
                            }
                        }
                        else
                        {
                            PrintColorText(client, "%s%sTarget not alive.", 
                                g_msg_start,
                                g_msg_textcol);
                        }
                    }
                    else
                    {
                        OpenTpToMenu(client);
                    }
                }
                else
                {
                    PrintColorText(client, "%s%sYou can't target yourself.", 
                        g_msg_start,
                        g_msg_textcol);
                }
            }
        }
        else
        {
            PrintColorText(client, "%s%sYou must be alive to use the sm_tpto command.", 
                g_msg_start,
                g_msg_textcol);
        }
    }
    
    return Plugin_Handled;
}

OpenTpToMenu(client)
{
    new Handle:menu = CreateMenu(Menu_Tpto);
    SetMenuTitle(menu, "Select player to teleport to");
    
    decl String:sTarget[MAX_NAME_LENGTH], String:sInfo[8];
    for (new target = 1; target <= MaxClients; target++)
    {
        if (target != client && IsClientInGame(target))
        {
            GetClientName(target, sTarget, sizeof(sTarget));
            IntToString(GetClientUserId(target), sInfo, sizeof(sInfo));
            AddMenuItem(menu, sInfo, sTarget);
        }
    }
    
    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Tpto(Handle:menu, MenuAction:action, client, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        
        new target = GetClientOfUserId(StringToInt(info));
        if (target != 0)
        {
            if (IsFakeClient(target))
            {
                new Float:vPos[3];
                Entity_GetAbsOrigin(target, vPos);
                
                StopTimer(client);
                TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
            }
            else
            {
                SendTpToRequest(client, target);
            }
        }
        else
        {
            PrintColorText(client, "%s%sTarget not in game.", 
                g_msg_start,
                g_msg_textcol);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

SendTpToRequest(client, target)
{
    if (g_BlockTpTo[target][client] == false)
    {
        new Handle:menu = CreateMenu(Menu_TpRequest);
        
        decl String:sInfo[16];
        new UserId = GetClientUserId(client);
        
        SetMenuTitle(menu, "%N wants to teleport to you", client);
        
        Format(sInfo, sizeof(sInfo), "%d;a", UserId);
        AddMenuItem(menu, sInfo, "Accept");
        
        Format(sInfo, sizeof(sInfo), "%d;d", UserId);
        AddMenuItem(menu, sInfo, "Deny");
        
        Format(sInfo, sizeof(sInfo), "%d;b", UserId);
        AddMenuItem(menu, sInfo, "Deny & Block");
        
        DisplayMenu(menu, target, 20);
    }
    else
    {
        PrintColorText(client, "%s%s%N %sblocked all tpto requests from you.", 
            g_msg_start,
            g_msg_varcol, 
            target, 
            g_msg_textcol);
    }
}

public Menu_TpRequest(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        
        decl String:sInfoExploded[2][16];
        ExplodeString(info, ";", sInfoExploded, 2, 16);
        
        new client = GetClientOfUserId(StringToInt(sInfoExploded[0]));
        
        if (client != 0)
        {
            if (sInfoExploded[1][0] == 'a') // accept
            {
                new Float:vPos[3];
                Entity_GetAbsOrigin(param1, vPos);
                
                StopTimer(client);
                TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
                
                PrintColorText(client, "%s%s%N %saccepted your request.", 
                    g_msg_start,
                    g_msg_varcol, 
                    param1, 
                    g_msg_textcol);
            }
            else if (sInfoExploded[1][0] == 'd') // deny
            {
                PrintColorText(client, "%s%s%N %sdenied your request.", 
                    g_msg_start,
                    g_msg_varcol, 
                    param1, 
                    g_msg_textcol);
            }
            else if (sInfoExploded[1][0] == 'b') // deny and block
            {
                g_BlockTpTo[param1][client] = true;
                PrintColorText(client, "%s%s%N %sdenied denied your request and blocked future requests from you.", 
                    g_msg_start,
                    g_msg_varcol, 
                    param1, 
                    g_msg_textcol);
            }
        }
        else
        {
            PrintColorText(param1, "%s%sThe tp requester is no longer in game.", 
                g_msg_start,
                g_msg_textcol);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

TeleToLastCP(client)
{
    if(GetConVarBool(g_hAllowCp))
    {
    if (!IsPlayerAlive(client))
    {
        PrintColorText(client, "%sMust be alive to use this.", 
            g_msg_start,
            g_msg_textcol);
    }
    else
    {
        if (g_cpcount[client] > 0)
        {
            TeleportToCheckpoint(client, g_cpcount[client] - 1);
        }
        else
        {
            PrintColorText(client, "%s%sNo CPs saved.", 
                g_msg_start,
                g_msg_textcol);
        }
    }
}
}

public Action:SM_TeleLast(client, args)
{
    TeleToLastCP(client);
}

public Action:SM_CP(client, args)
{
    if (GetConVarBool(g_hAllowCp))
    {
        OpenCheckpointMenu(client);
    }
    
    return Plugin_Handled;
}

OpenCheckpointMenu(client)
{
    new Handle:menu = CreateMenu(Menu_Checkpoint);
    
    SetMenuTitle(menu, "Checkpoint Menu");
    AddMenuItem(menu, "Save", "Save");
    AddMenuItem(menu, "Teleport", "Teleport");
    AddMenuItem(menu, "Delete", "Delete");
    AddMenuItem(menu, "DeleteAll", "Delete All");
    AddMenuItem(menu, "DeleteRange", "Delete CP Range");
    AddMenuItem(menu, "Settings", "Settings");
    
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Checkpoint(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        
        if (StrEqual(info, "Save"))
        {
            SaveCheckpoint(param1);
            OpenCheckpointMenu(param1);
        }
        else if (StrEqual(info, "Teleport"))
        {
            OpenTeleportMenu(param1);
        }
        else if (StrEqual(info, "Delete"))
        {
            OpenDeleteMenu(param1);
        }
        else if (StrEqual(info, "DeleteAll"))
        {
            OpenDeleteAllMenu(param1);
        }
        else if (StrEqual(info, "DeleteRange"))
        {
            OpenDeleteRangeMenu(param1);
        }
        else if (StrEqual(info, "Settings"))
        {
            OpenSettingsMenu(param1);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

OpenSettingsMenu(client)
{
    new Handle:menu = CreateMenu(Menu_Settings);
    SetMenuTitle(menu, "CP Settings");
    AddMenuItem(menu, "usepos", g_UsePos[client] ? "Use position: Yes":"Use position: No");
    AddMenuItem(menu, "usevel", g_UseVel[client] ? "Use velocity: Yes":"Use velocity: No");
    AddMenuItem(menu, "useang", g_UseAng[client] ? "Use angles: Yes":"Use angles: No");
    
    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
public Menu_Settings(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if (StrEqual(info, "usepos"))
        {
            g_UsePos[param1] = !g_UsePos[param1];
            OpenSettingsMenu(param1);
        }
        if (StrEqual(info, "usevel"))
        {
            g_UseVel[param1] = !g_UseVel[param1];
            OpenSettingsMenu(param1);
        }
        if (StrEqual(info, "useang"))
        {
            g_UseAng[param1] = !g_UseAng[param1];
            OpenSettingsMenu(param1);
        }
        if (StrEqual(info, "back"))
        {
            OpenCheckpointMenu(param1);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack)
        {
            OpenCheckpointMenu(param1);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

OpenDeleteRangeMenu(client)
{
    if (g_cpcount[client] >= 2)
    {
        new Handle:menu = CreateMenu(Menu_DeleteRange1);
        SetMenuTitle(menu, "First CP Selection");
        AddMenuItem(menu, "add1", "Add 1");
        AddMenuItem(menu, "add10", "Add 10");
        AddMenuItem(menu, "remove1", "Remove 1");
        AddMenuItem(menu, "remove10", "Remove 10");
        AddMenuItem(menu, "confirm", "Confirm");
        
        SetMenuExitBackButton(menu, true);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
    }
    else
    {
        PrintColorText(client, "%s%sNo available CPs or only 1 CP not allowing a range.", 
            g_msg_start,
            g_msg_textcol);
        OpenCheckpointMenu(client);
    }
}

public Menu_DeleteRange1(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if (StrEqual(info, "add1"))
        {
            if (g_range_one[param1] == g_cpcount[param1] - 1)
            {
                PrintColorText(param1, "%s%sCannot have CP1 equal to highest CP.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu(param1);
            }
            else
            {
                g_range_one[param1]++;
                PrintColorText(param1, "%s%sCP1: %s%d", 
                    g_msg_start,
                    g_msg_textcol, 
                    g_msg_varcol, 
                    g_range_one[param1]);
                OpenDeleteRangeMenu(param1);
            }
        }
        if (StrEqual(info, "add10"))
        {
            if (g_range_one[param1] <= g_cpcount[param1] - 1 && g_range_one[param1] >= g_cpcount[param1] - 10)
            {
                PrintColorText(param1, "%s%sCannot have CP1 equal to highest CP.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu(param1);
            }
            else
            {
                g_range_one[param1] += 10;
                PrintColorText(param1, "%s%sCP1: %s%d", 
                    g_msg_start,
                    g_msg_textcol, 
                    g_msg_varcol, 
                    g_range_one[param1]);
                OpenDeleteRangeMenu(param1);
            }
        }
        if (StrEqual(info, "remove1"))
        {
            if (g_range_one[param1] == 1)
            {
                PrintColorText(param1, "%s%sTrying to delete lower than 1 CP.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu(param1);
            }
            else if (g_range_one[param1] == 0)
            {
                PrintColorText(param1, "%s%sCannot specify negative CPs.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu(param1);
            }
            else
            {
                g_range_one[param1]--;
                PrintColorText(param1, "%s%sCP1: %s%d", 
                    g_msg_start,
                    g_msg_textcol, 
                    g_msg_varcol, 
                    g_range_one[param1]);
                OpenDeleteRangeMenu(param1);
            }
        }
        if (StrEqual(info, "remove10"))
        {
            if (g_range_one[param1] >= 1 && g_range_one[param1] < 11)
            {
                PrintColorText(param1, "%s%sTrying to delete lower than 1 CP.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu(param1);
            }
            else if (g_range_one[param1] == 0)
            {
                PrintColorText(param1, "%s%sCannot specify negative CPs.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu(param1);
            }
            else
            {
                g_range_one[param1] -= 10;
                PrintColorText(param1, "%s%sCP1: %s%d", 
                    g_msg_start,
                    g_msg_textcol, 
                    g_msg_varcol, 
                    g_range_one[param1]);
                OpenDeleteRangeMenu(param1);
            }
        }
        if (StrEqual(info, "confirm"))
        {
            OpenDeleteRangeMenu2(param1);
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack)
        {
            OpenCheckpointMenu(param1);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

OpenDeleteRangeMenu2(client)
{
    if (g_cpcount[client] >= 2)
    {
        new Handle:menu = CreateMenu(Menu_DeleteRange2);
        SetMenuTitle(menu, "Second CP Selection");
        AddMenuItem(menu, "add1", "Add 1");
        AddMenuItem(menu, "add10", "Add 10");
        AddMenuItem(menu, "remove1", "Remove 1");
        AddMenuItem(menu, "remove10", "Remove 10");
        AddMenuItem(menu, "confirm", "Confirm");
        
        SetMenuExitBackButton(menu, true);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
    }
    else
    {
        PrintColorText(client, "%s%sNo available CPs or only 1 CP not allowing a range.", 
            g_msg_start,
            g_msg_textcol);
        OpenCheckpointMenu(client);
    }
}


public Menu_DeleteRange2(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if (StrEqual(info, "add1"))
        {
            if (g_range_two[param1] == g_cpcount[param1])
            {
                PrintColorText(param1, "%s%sCannot have CP2 higher than highest CP.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu2(param1);
            }
            else
            {
                g_range_two[param1]++;
                PrintColorText(param1, "%s%sCP2: %s%d", 
                    g_msg_start,
                    g_msg_textcol, 
                    g_msg_varcol, 
                    g_range_two[param1]);
                OpenDeleteRangeMenu2(param1);
            }
        }
        if (StrEqual(info, "add10"))
        {
            if (g_range_two[param1] <= g_cpcount[param1] - 1 && g_range_two[param1] >= g_cpcount[param1] - 9 || g_range_two[param1] == g_cpcount[param1])
            {
                PrintColorText(param1, "%s%sCannot have CP2 higher than highest CP.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu2(param1);
            }
            else
            {
                g_range_two[param1] += 10;
                PrintColorText(param1, "%s%sCP2: %s%d", 
                    g_msg_start,
                    g_msg_textcol, 
                    g_msg_varcol, 
                    g_range_two[param1]);
                OpenDeleteRangeMenu2(param1);
            }
        }
        if (StrEqual(info, "remove1"))
        {
            if (g_range_two[param1] == 1)
            {
                PrintColorText(param1, "%s%sTrying to delete lower than 1 CP.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu2(param1);
            }
            else if (g_range_two[param1] == 0)
            {
                PrintColorText(param1, "%s%sCannot specify negative CPs.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu2(param1);
            }
            else
            {
                g_range_two[param1]--;
                PrintColorText(param1, "%s%sCP2: %s%d", 
                    g_msg_start,
                    g_msg_textcol, 
                    g_msg_varcol, 
                    g_range_two[param1]);
                OpenDeleteRangeMenu2(param1);
            }
        }
        if (StrEqual(info, "remove10"))
        {
            if (g_range_two[param1] >= 1 && g_range_two[param1] < 11)
            {
                PrintColorText(param1, "%s%sTrying to delete lower than 1 CP.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu2(param1);
            }
            else if (g_range_two[param1] == 0)
            {
                PrintColorText(param1, "%s%sCannot specify negative CPs.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu2(param1);
            }
            else
            {
                g_range_two[param1] -= 10;
                PrintColorText(param1, "%s%sCP2: %s%d", 
                    g_msg_start,
                    g_msg_textcol, 
                    g_msg_varcol, 
                    g_range_two[param1]);
                OpenDeleteRangeMenu2(param1);
            }
        }
        if (StrEqual(info, "confirm"))
        {
            if (g_range_one[param1] >= g_range_two[param1])
            {
                PrintColorText(param1, "%s%sCP1 is greater than or equal to CP2.", 
                    g_msg_start,
                    g_msg_textcol);
                OpenDeleteRangeMenu2(param1);
            }
            else
            {
                for (new i = g_range_one[param1]; i <= g_range_two[param1]; ++i)
                {
                    DeleteCheckpoint(param1, g_range_one[param1]);
                }
                OpenCheckpointMenu(param1);
                g_range_one[param1] = 0;
                g_range_two[param1] = 0;
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack)
        {
            OpenDeleteRangeMenu(param1);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}


OpenDeleteAllMenu(client)
{
    if (g_cpcount[client] != 0)
    {
        new Handle:menu = CreateMenu(Menu_DeleteAll);
        SetMenuTitle(menu, "Are you sure?");
        AddMenuItem(menu, "yes", "Yes");
        AddMenuItem(menu, "no", "No");
        
        SetMenuExitBackButton(menu, false);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
    }
    else
    {
        PrintColorText(client, "%s%sNo available CPs.", 
            g_msg_start,
            g_msg_textcol);
        OpenCheckpointMenu(client);
    }
}

public Menu_DeleteAll(Handle:menu, MenuAction:action, param1, param2)
{
    
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        if (StrEqual(info, "yes"))
        {
            g_cpcount[param1] = 0;
            OpenCheckpointMenu(param1);
        }
        else if (StrEqual(info, "no"))
        {
            OpenCheckpointMenu(param1);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

OpenTeleportMenu(client)
{
    new Handle:menu = CreateMenu(Menu_Teleport);
    SetMenuTitle(menu, "Teleport");
    AddMenuItem(menu, "lastused", "Last used");
    AddMenuItem(menu, "lastsaved", "Last saved");
    
    decl String:tpString[8], String:infoString[8];
    for (new i = 0; i < g_cpcount[client]; i++)
    {
        Format(tpString, sizeof(tpString), "CP %d", i + 1);
        Format(infoString, sizeof(infoString), "%d", i);
        AddMenuItem(menu, infoString, tpString);
    }
    
    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_Teleport(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        
        if (StrEqual(info, "lastused"))
        {
            TeleportToLastUsed(param1);
            OpenTeleportMenu(param1);
        }
        else if (StrEqual(info, "lastsaved"))
        {
            TeleToLastCP(param1);
            OpenTeleportMenu(param1);
        }
        else
        {
            decl String:infoGuess[8];
            for (new i = 0; i < g_cpcount[param1]; i++)
            {
                Format(infoGuess, sizeof(infoGuess), "%d", i);
                if (StrEqual(info, infoGuess))
                {
                    TeleportToCheckpoint(param1, i);
                    OpenTeleportMenu(param1);
                    break;
                }
            }
        }
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack)
        {
            OpenCheckpointMenu(param1);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
}

OpenDeleteMenu(client)
{
    if (g_cpcount[client] != 0)
    {
        new Handle:menu = CreateMenu(Menu_Delete);
        SetMenuTitle(menu, "Delete");
        
        decl String:display[16], String:info[8];
        for (new i = 0; i < g_cpcount[client]; i++)
        {
            Format(display, sizeof(display), "Delete %d", i + 1);
            IntToString(i, info, sizeof(info));
            AddMenuItem(menu, info, display);
        }
        
        SetMenuExitBackButton(menu, true);
        SetMenuExitButton(menu, true);
        DisplayMenu(menu, client, MENU_TIME_FOREVER);
    }
    else
    {
        PrintColorText(client, "%s%sNo available CPs.", 
            g_msg_start,
            g_msg_textcol);
        OpenCheckpointMenu(client);
    }
    
    
}

public Menu_Delete(Handle:menu, MenuAction:action, param1, param2)
{
    if (action == MenuAction_Select)
    {
        decl String:info[32];
        GetMenuItem(menu, param2, info, sizeof(info));
        
        DeleteCheckpoint(param1, StringToInt(info));
        OpenDeleteMenu(param1);
    }
    else if (action == MenuAction_Cancel)
    {
        if (param2 == MenuCancel_ExitBack)
        {
            OpenCheckpointMenu(param1);
        }
    }
    else if (action == MenuAction_End)
        CloseHandle(menu);
    
}

public Action:SM_Tele(client, args)
{
    if (args != 0)
    {
        decl String:sArg[255];
        GetCmdArgString(sArg, sizeof(sArg));
        
        new checkpoint = StringToInt(sArg) - 1;
        TeleportToCheckpoint(client, checkpoint);
    }
    else
    {
        ReplyToCommand(client, "[SM] Usage: sm_tele <Checkpoint number>");
    }
    
    return Plugin_Handled;
}

public Action:SM_Save(client, argS)
{
    SaveCheckpoint(client);
    
    return Plugin_Handled;
}

SaveCheckpoint(client)
{
    if (GetConVarBool(g_hAllowCp))
    {
        if (g_cpcount[client] < MAX_CP)
        {
            Entity_GetAbsOrigin(client, g_cp[client][g_cpcount[client]][0]);
            Entity_GetAbsVelocity(client, g_cp[client][g_cpcount[client]][1]);
            GetClientEyeAngles(client, g_cp[client][g_cpcount[client]][2]);
            
            g_cpcount[client]++;
            
            PrintColorText(client, "%s%sCP %s%d%s saved.", 
                g_msg_start,
                g_msg_textcol, 
                g_msg_varcol, 
                g_cpcount[client], 
                g_msg_textcol);
        }
        else
        {
            PrintColorText(client, "%s%sToo many CPs.", 
                g_msg_start,
                g_msg_textcol);
        }
    }
}

DeleteCheckpoint(client, cpnum)
{
    if (0 <= cpnum <= g_cpcount[client])
    {
        for (new i = cpnum + 1; i < MAX_CP; i++)
        for (new i2 = 0; i2 < 3; i2++)
        for (new i3 = 0; i3 < 3; i3++)
        g_cp[client][i - 1][i2][i3] = g_cp[client][i][i2][i3];
        g_cpcount[client]--;
        
        if (cpnum == g_LastUsed[client] || g_cpcount[client] < g_LastUsed[client])
            g_HasLastUsed[client] = false;
        else if (cpnum < g_LastUsed[client])
            g_LastUsed[client]--;     
    }
    else
    {
        PrintColorText(client, "%s%sCP %s%d%s doesn't exist", 
            g_msg_start,
            g_msg_textcol, 
            g_msg_varcol, 
            cpnum + 1, 
            g_msg_textcol);
    }
}

TeleportToCheckpoint(client, cpnum)
{
    if (GetConVarBool(g_hAllowCp))
    {
        if (0 <= cpnum < g_cpcount[client])
        {
            new Float:vPos[3];
            for (new i; i < 3; i++)
            vPos[i] = g_cp[client][cpnum][0][i];
            vPos[2] += 5.0;
            
            StopTimer(client);
            //SetEntityFlags(client, GetEntityFlags(client) & ~FL_ONGROUND);
            
            // Prevent using velocity with checkpoints inside start zones so players can't abuse it to beat times
            if (g_UsePos[client] == false)
            {
                new Float:vClientPos[3];
                Entity_GetAbsOrigin(client, vClientPos);
                
                if (Timer_InsideZone(client, MAIN_START) != -1 || Timer_InsideZone(client, BONUS_START) != -1)
                {
                    TeleportEntity(client, 
                        g_UsePos[client] ? g_cp[client][cpnum][0]:NULL_VECTOR, 
                        g_UseAng[client] ? g_cp[client][cpnum][2]:NULL_VECTOR, 
                        Float: { 0.0, 0.0, 0.0 } );
                }
                else
                {
                    TeleportEntity(client, 
                        g_UsePos[client] ? g_cp[client][cpnum][0]:NULL_VECTOR, 
                        g_UseAng[client] ? g_cp[client][cpnum][2]:NULL_VECTOR, 
                        g_UseVel[client] ? g_cp[client][cpnum][1]:NULL_VECTOR);
                }
            }
            else
            {
                if (!Timer_IsPointInsideZone(vPos, MAIN_START, 0) && !Timer_IsPointInsideZone(vPos, BONUS_START, 0))
                {
                    TeleportEntity(client, 
                        g_UsePos[client] ? g_cp[client][cpnum][0]:NULL_VECTOR, 
                        g_UseAng[client] ? g_cp[client][cpnum][2]:NULL_VECTOR, 
                        g_UseVel[client] ? g_cp[client][cpnum][1]:NULL_VECTOR);
                }
                else
                {
                    TeleportEntity(client, 
                        g_UsePos[client] ? g_cp[client][cpnum][0]:NULL_VECTOR, 
                        g_UseAng[client] ? g_cp[client][cpnum][2]:NULL_VECTOR, 
                        Float: { 0.0, 0.0, 0.0 } );
                }
            }
            
            g_HasLastUsed[client] = true;
            g_LastUsed[client] = cpnum;
        }
        else
        {
            PrintColorText(client, "%s%sCP %s%d%s doesn't exist", 
                g_msg_start,
                g_msg_textcol, 
                g_msg_varcol, 
                cpnum + 1, 
                g_msg_textcol);
        }
    }
}

TeleportToLastUsed(client)
{
    if (GetConVarBool(g_hAllowCp))
    {
        if (g_HasLastUsed[client] == true)
        {
            TeleportToCheckpoint(client, g_LastUsed[client]);
        }
        else
        {
            PrintColorText(client, "%s%sNo last used CP.", 
                g_msg_start,
                g_msg_textcol);
        }
    }
}
