/*
||||****|||**||||**||||****|||*******|||||****|||||***|||||***|||||||||||||||
||**|||||||**||||**||***|||||||||*||||||**||||**|||**|*|||*|**|||||||||||||||
||**|||||||**||||**||||****||||||*||||||**||||**|||**||*|*||**|||||||||||||||
||||****||||******|||***|||||||||*||||||||****|||||**|||*|||**|||||||||||||||

|||||||||||||||||||||******||||||||*|||||****|||||*******||||||||||||||||||||
|||||||||||||||||||||**||||**|||||*|*||||**||**||||||*|||||||||||||||||||||||
|||||||||||||||||||||******||||||*****|||****||||||||*|||||||||||||||||||||||
|||||||||||||||||||||**|||||||||*||||*|||**||**||||||*|||||||||||||||||||||||

Core Plugin By Nopied◎
*/

//

#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <custompart>

#include "custompart/global_var.sp"

#include "custompart/stocks.sp"
#include "custompart/menu.sp"
#include "custompart/part_stocks.sp"

#include "custompart/natives.sp"

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
    CreateNative("CP_GetClientPart", Native_GetClientPart);
    CreateNative("CP_SetClientPart", Native_SetClientPart);
    CreateNative("CP_IsPartActived", Native_IsPartActived);
    CreateNative("CP_RefrashPartSlotArray", Native_RefrashPartSlotArray);
    CreateNative("CP_IsValidPart", Native_IsValidPart);
    CreateNative("CP_IsValidSlot", Native_IsValidSlot);
    CreateNative("CP_GetPartPropInfo", Native_GetPartPropInfo);
    CreateNative("CP_SetPartPropInfo", Native_SetPartPropInfo);
    CreateNative("CP_PropToPartProp", Native_PropToPartProp);
    CreateNative("CP_GetClientMaxSlot", Native_GetClientMaxslot);
    CreateNative("CP_SetClientMaxSlot", Native_SetClientMaxslot);
    CreateNative("CP_ReplacePartSlot", Native_ReplacePartSlot);
    CreateNative("CP_FindActiveSlot", Native_FindActiveSlot);
    CreateNative("CP_NoticePart", Native_NoticePart);
    CreateNative("CP_GetClientActiveSlotDuration", Native_GetClientActiveSlotDuration);
    CreateNative("CP_SetClientActiveSlotDuration", Native_SetClientActiveSlotDuration);
    CreateNative("CP_GetClientTotalCooldown", Native_GetClientTotalCooldown);
    CreateNative("CP_GetClientPartCharge", Native_GetClientPartCharge);
    CreateNative("CP_SetClientPartCharge", Native_SetClientPartCharge);
    CreateNative("CP_GetClientPartMaxChargeDamage", Native_GetClientPartMaxChargeDamage);
    CreateNative("CP_SetClientPartMaxChargeDamage", Native_SetClientPartMaxChargeDamage);
    CreateNative("CP_AddClientPartCharge", Native_AddClientPartCharge);
    CreateNative("CP_FindPart", Native_FindPart);
    CreateNative("CP_IsEnabled", Native_IsEnabled);
    CreateNative("CP_RandomPart", Native_RandomPart);
    CreateNative("CP_RandomPartRank", Native_RandomPartRank);
    CreateNative("CP_GetClientCPFlags", Native_GetClientCPFlags);
    CreateNative("CP_SetClientCPFlags", Native_SetClientCPFlags);

    Init_ConfigNatives();
    Init_Forwards();

    return APLRes_Success;
}

public void OnPluginStart()
{
      cvarChatCommand = CreateConVar("cp_chatcommand", "파츠,part,스킬");

      cvarPropCount = CreateConVar("cp_prop_count", "3", "생성되는 프롭 갯수, 0은 생성을 안함", _, true, 0.0);
      cvarPropVelocity = CreateConVar("cp_prop_velocity", "250.0", "프롭 생성시 흩어지는 최대 속도, 설정한 범위 내로 랜덤으로 속도가 정해집니다.", _, true, 0.0);
      cvarPropForNoBossTeam = CreateConVar("cp_prop_for_team", "0", "0 혹은 1은 제한 없음, 2는 레드팀에게만, 3은 블루팀에게만. (생성도 포함됨.)", _, true, 0.0, true, 2.0);
      cvarPropSize = CreateConVar("cp_prop_size", "50.0", "캡슐 섭취 범위", _, true, 0.1);
      cvarPropCooltime = CreateConVar("cp_prop_cooltime", "1.0", "캡슐 섭취 쿨타임.", _, true, 0.1);
      cvarDebug = CreateConVar("cp_debug", "1", "", _, true, 0.0, true, 1.0);

      RegAdminCmd("slot", TestSlot, ADMFLAG_CHEATS, "");
      RegAdminCmd("givepart", GivePart, ADMFLAG_CHEATS, "");

      AddCommandListener(Listener_Say, "say");
      AddCommandListener(Listener_Say, "say_team");

      AddCommandListener(OnCallForMedic, "voicemenu");

      LoadTranslations("custompart");
      LoadTranslations("common.phrases");
      LoadTranslations("core.phrases");

      HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
      HookEvent("player_death", OnPlayerDeath);

      HookEvent("teamplay_round_start", OnRoundStart);
      HookEvent("teamplay_round_win", OnRoundEnd);

      AllPartPropCount = 0;
      CPHud = CreateHudSynchronizer();
      CPChargeHud = CreateHudSynchronizer();

      CreateTimer(0.1, ClientTimer, _, TIMER_REPEAT);

      for(int client=1; client<=MaxClients; client++)
      {
          ActivedPartSlotArray[client] = new ArrayList();
          ActivedPartSlotArray[client].Resize(50);

          ActivedDurationArray[client] = new ArrayList();
          ActivedDurationArray[client].Resize(50);
      }
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{

    /*
    int ent = -1;

    float position[3];
    float velocity[3];

    while((ent = FindEntityByClassname(ent, "item_healthkit_*")) != -1)
    {
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);

        position[2] += GetRandomFloat(3.0, 15.0);
        int part = SpawnCustomPart(RandomPartRank(), position, velocity, false);

        if(IsValidEntity(part))
        {
            SetEntityMoveType(part, MOVETYPE_NONE);
        }
    }

    while((ent = FindEntityByClassname(ent, "item_ammopack_*")) != -1)
    {
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);

        position[2] += GetRandomFloat(3.0, 15.0);
        int part = SpawnCustomPart(RandomPartRank(), position, velocity, false);

        if(IsValidEntity(part))
        {
            SetEntityMoveType(part, MOVETYPE_NONE);
        }
    }
    */
}

public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
    for(int client=1; client<=MaxClients; client++)
    {
        CPFlags[client] = 0;

        bool changed = false;

        if(ActivedPartSlotArray[client].Length > 0) // TODO: 동일한 역할들을 묶어놓기.
        {
            RefrashPartSlotArray(client, true, true);

            Action action;
            int remainCount = 0;
            bool[] gotoNextRound = new bool[MaxPartSlot[client]]
            int temp, tempClient = client, tempPart;
            bool tempGoToNextRound = false;
            int[] maxSlot = new int[MaxPartSlot[client]]

            for(int target=0; target<MaxPartSlot[client]; target++)
            {
                temp = ActivedPartSlotArray[client].Get(target);

                if(!PartKV.IsValidPart(temp)) continue;

                tempPart = temp;
                tempGoToNextRound = false;

                action = Forward_OnSlotClear(tempClient, tempPart, tempGoToNextRound);

                float duration = GetClientActiveSlotDuration(client, target);

                if(duration <= 0.0)
                {
                    Forward_OnActivedPartEnd(client, temp);
                }

                if(action == Plugin_Handled)
                {
                    maxSlot[remainCount++] = temp;
                    gotoNextRound[remainCount] = tempGoToNextRound;
                    changed = true;
                }
            }

            RefrashPartSlotArray(client);
            MaxPartSlot[client] = MaxPartGlobalSlot;
            PartCharge[client] = 0.0;
            PartCooldown[client] = -1.0;
            PartMaxChargeDamage[client] = 0.0;

            if(changed)
            {
                int roundstate = CheckRoundState();
                for(int target=0; target<MaxPartSlot[client]; target++)
                {
                    if(target < remainCount && target < MaxPartSlot[client]
                         &&
                         (!gotoNextRound[target] || (roundstate != 1 && gotoNextRound[target]))
                         )
                         {
                             ActivedPartSlotArray[client].Set(target, maxSlot[target]);
                             Forward_OnGetPart_Post(client, maxSlot[target]);

                             if(PartKV.IsPartActive(maxSlot[target]))
                                 PartMaxChargeDamage[client] += PartKV.GetPartMaxChargeDamage(maxSlot[target]);
                         }
                }
            }
        }
        // TODO: g_hClientInfo 슬릇에 대하여.
    }
}

public Action ClientTimer(Handle timer)
{
    int target;
    int part;
    bool hasActivePart = false;
    char HudMessage[200];
    char partName[100];
    float duration;

    if(CheckRoundState() != 1)
        return Plugin_Continue;

    for(int client=1; client<=MaxClients; client++)
    {
        hasActivePart = false;
        if(!IsClientInGame(client)) continue;

        if(IsClientHaveDuration(client))
        {
            Action action;
            float tempDuration;

            for(int count=0; count<MaxPartSlot[client]; count++)
            {
                duration = GetClientActiveSlotDuration(client, count);
                part = GetClientPart(client, count);
                if(duration > 0.0)
                {
                    duration -= 0.1;
                    tempDuration = duration;

                    if(PartKV.IsValidPart(part))
                    {
                        action = Forward_OnActivedPartTime(client, part, tempDuration);
                        if(action == Plugin_Changed)
                        {
                            duration = tempDuration;
                        }
                        else if(action == Plugin_Handled || action == Plugin_Stop)
                        {
                            continue;
                        }
                    }

                    SetClientActiveSlotDuration(client, count, duration);

                    if(duration <= 0.0)
                    {
                        Forward_OnActivedPartEnd(client, GetClientPart(client, count));
                    }

                    /*


                        duration = GetClientActiveSlotDuration(client, count);

                        if(duration <= 0.0)
                        {
                            Forward_OnActivedPartEnd(client, GetClientPart(client, count));
                        }
                    */
                }

            }
        }
        else if(PartCooldown[client] > 0.0)
        {
            PartCooldown[client] -= 0.1;

            if(PartCooldown[client] <= 0.0)
            {
                Forward_OnClientCooldownEnd(client);
            }
        }

        if(!(CPFlags[client] & CPFLAG_DISABLE_HUD))
        {
            SetHudTextParams(0.7, 0.1, 0.12, 255, 228, 0, 185);

            if(IsPlayerAlive(client))
            {
                target = client;
                Format(HudMessage, sizeof(HudMessage), "활성화된 파츠: (최대 슬릇: %i)", MaxPartSlot[target]);
            }
            else
            {
                target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
                if(IsValidClient(target))
                    Format(HudMessage, sizeof(HudMessage), "관전 중인 상대 파츠: (최대 슬릇: %i)", MaxPartSlot[target]);
            }

            if(IsValidClient(target))
            {
                int partcount = 0;
                for(int count = 0; count < MaxPartSlot[target]; count++)
                {
                    if(IsValidSlot(target, count) && PartKV.IsValidPart((part = GetClientPart(target, count))))
                    {
                        if(PartKV.IsPartActive(part))
                            hasActivePart = true;

                        if(partcount <= 5)
                        {
                            PartKV.GetPartString(part, "name", partName, sizeof(partName), client);
                            Format(HudMessage, sizeof(HudMessage), "%s\n%s", HudMessage, partName);
                        }

                        partcount++;
                    }
                }
                if(partcount > 5)
                {
                    Format(HudMessage, sizeof(HudMessage), "%s\n.. 그 외 %i개!", HudMessage, partcount - 5);
                }
                ShowSyncHudText(client, CPHud, HudMessage);

                // Charge Hud

                if(hasActivePart)
                {
                    SetHudTextParams(-1.0, 0.76, 0.12, 255, 228, 0, 185);

                    int ragemeter = RoundFloat(PartCharge[target]*(PartMaxChargeDamage[target]/100.0));

                    if(IsClientHaveDuration(target))
                    {
                        int activeCount=0;

                        for(int count=0; count<MaxPartSlot[target]; count++)
                        {
                            if(GetClientActiveSlotDuration(target, count) > 0.0 && PartKV.IsValidPart((part = GetClientPart(target, count))))
                            {
                                PartKV.GetPartString(part, "name", partName, sizeof(partName), client);
                                if(activeCount == 0)
                                {
                                    Format(HudMessage, sizeof(HudMessage), "%s: %.1f", partName, GetClientActiveSlotDuration(target, count));
                                }
                                else if(activeCount < 2)
                                {
                                    Format(HudMessage, sizeof(HudMessage), "%s | %s: %.1f", HudMessage, partName, GetClientActiveSlotDuration(target, count));
                                }

                                activeCount++;
                            }
                        }

                        if(activeCount > 2)
                        {
                            Format(HudMessage, sizeof(HudMessage), "%s 그 외 %i개!", HudMessage, activeCount - 2);
                        }
                    }
                    else if(GetClientPartCooldown(target) > 0.0)
                    {
                        Format(HudMessage, sizeof(HudMessage), "액티브 파츠 쿨타임: %.1f", GetClientPartCooldown(target));
                    }
                    else
                    {
                        if(client == target)
                        {
                            if(PartCharge[target] >= 100.0)
                            {
                                Format(HudMessage, sizeof(HudMessage), "메딕을 불러 능력을 발동시키세요!");
                            }
                            else
                            {
                                Format(HudMessage, sizeof(HudMessage), "액티브 파츠 충전: %i%% / 100%% (%i / %i)", RoundFloat(PartCharge[target]), ragemeter, RoundFloat(PartMaxChargeDamage[target]));
                            }
                        }
                        else
                        {
                            Format(HudMessage, sizeof(HudMessage), "%N님의 액티브 파츠 충전: %i%% / 100%% (%i / %i)", target, RoundFloat(PartCharge[target]), ragemeter, RoundFloat(PartMaxChargeDamage[target]));
                        }
                    }
                    ShowSyncHudText(client, CPChargeHud, HudMessage);
                }
            }
        }
    }

    return Plugin_Continue;
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
    if(CheckRoundState() != 1 && IsClientInGame(client) && IsPlayerAlive(client))
        return Plugin_Continue;

    char arg1[4]; char arg2[4];
    GetCmdArg(1, arg1, sizeof(arg1));
    GetCmdArg(2, arg2, sizeof(arg2));
    if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
    {
        return Plugin_Continue;
    }

    if(!IsClientHaveActivePart(client)) return Plugin_Continue;

    if(PartCharge[client] >= 100.0 && !IsClientHaveDuration(client) && GetClientPartCooldown(client) <= 0.0)
    {
        PartCharge[client] = 0.0;
        PartCooldown[client] = GetClientTotalCooldown(client);
        Action action;

        for(int count=0; count<MaxPartSlot[client]; count++)
        {
            int part = GetClientPart(client, count);
            if(PartKV.IsPartActive(part))
            {
                action = Forward_PreActivePart(client, part);
                if(action == Plugin_Handled)
                    continue;

                SetClientActiveSlotDuration(client, count, PartKV.GetActivePartDuration(part));
                Forward_OnActivedPart(client, part);
            }
        }
    }
    else
    {
        CPrintToChat(client, "{yellow}[CP]{default} 지금은 사용하실 수 없습니다.");
    }
    return Plugin_Continue;
}

public Action TestSlot(int client, int args)
{
    RefrashPartSlotArray(client, true, true);
    CPrintToChatAll("%N's slot. size = %i, MaxPartSlot = %i", client, ActivedPartSlotArray[client].Length, MaxPartSlot[client]);

    for(int count = 0; count < MaxPartSlot[client]; count++)
    {
        CPrintToChatAll("[%i] %i", count, ActivedPartSlotArray[client].Get(count));
        CPrintToChatAll("[%i] 지속시간: %.1f", count, ActivedDurationArray[client].Get(count));
    }
    CPrintToChatAll("쿨타임: %.1f", PartCooldown[client]);
}

public void OnEntityDestroyed(int entity)
{
    if(entity >= 0)
    {
        if(PartPropRank[entity] > Rank_None)
            AllPartPropCount--;

        PartPropRank[entity] = Rank_None;
        PartPropCustomIndex[entity] = 0;
    }
}

public void OnMapStart()
{
    ChangeChatCommand();
    CheckPartConfigFile();
    CreateTimer(0.2, PrecacheTimer);

    for(int client=1; client<=MaxClients; client++)
    {
        CPFlags[client] = 0;

        if(IsClientInGame(client))
            RefrashPartSlotArray(client);

        if(g_hClientInfo[client] != null)
            g_hClientInfo[client].KillSelf();
    }
}

void ChangeChatCommand()
{
	g_iChatCommand = 0;

	char cvarV[100];
	GetConVarString(cvarChatCommand, cvarV, sizeof(cvarV));

	for (int i=0; i<ExplodeString(cvarV, ",", g_strChatCommand, sizeof(g_strChatCommand), sizeof(g_strChatCommand[])); i++)
	{
		LogMessage("[CP] Added chat command: %s", g_strChatCommand[i]);
		g_iChatCommand++;
	}
}

public OnClientPostAdminCheck(int client)
{
    g_hClientInfo[client] = new CPClient(client, MaxPartGlobalSlot);
    MaxPartSlot[client] = MaxPartGlobalSlot;

    if(enabled)
    {
        SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
    }
}

public void OnClientDisconnect(int client)
{
    if(enabled && ActivedPartSlotArray[client].Length > 0) // 아마도 될껄?
    {
        RefrashPartSlotArray(client, true);

        Action action;
        int remainCount = 0;
        int temp, tempClient = client, tempPart;
        int[] maxSlot = new int[MaxPartSlot[client]]

        for(int target=0; target<MaxPartSlot[client]; target++)
        {
            temp = ActivedPartSlotArray[client].Get(target);
            tempPart = temp;

            if(!PartKV.IsValidPart(tempPart)) continue;

            action = Forward_OnSlotClear(tempClient, tempPart, false);

            if(action == Plugin_Handled)
            {
                maxSlot[remainCount++] = temp;
            }
        }
    }

    PartCooldown[client] = 0.0;

    MaxPartSlot[client] = MaxPartGlobalSlot;
    ActivedPartSlotArray[client].Clear();
    ActivedDurationArray[client].Clear();

    if(g_hClientInfo[client] != null)
        g_hClientInfo[client].KillSelf();

    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
    // ActivedPartSlotArray[client] = view_as<ArrayList>(INVALID_HANDLE);
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    if(enabled)
    {
        int client = GetClientOfUserId(GetEventInt(event, "userid"));
        PartGetCoolTime[client] = 0.0;
        bool changed = false;

        if(ActivedPartSlotArray[client].Length > 0 && !(CPFlags[client] & CPFLAG_DONOTCLEARSLOT))
        {
            RefrashPartSlotArray(client, true);

            Action action;
            int remainCount = 0;
            bool[] gotoNextRound = new bool[MaxPartSlot[client]]
            int temp, tempClient = client, tempPart;
            bool tempGoToNextRound = false;
            int[] maxSlot = new int[MaxPartSlot[client]]

            for(int target=0; target<MaxPartSlot[client]; target++)
            {
                temp = ActivedPartSlotArray[client].Get(target);

                if(!PartKV.IsValidPart(temp)) continue;

                tempPart = temp;
                tempGoToNextRound = false;

                action = Forward_OnSlotClear(tempClient, tempPart, tempGoToNextRound);

                if(ActivedDurationArray[client].Get(target) > 0.0)
                    Forward_OnActivedPartEnd(client, temp);

                if(action == Plugin_Handled)
                {
                    maxSlot[remainCount++] = temp;
                    gotoNextRound[remainCount] = tempGoToNextRound;
                    changed = true;
                }
            }

            RefrashPartSlotArray(client);
            MaxPartSlot[client] = MaxPartGlobalSlot;
            PartCharge[client] = 0.0;
            PartCooldown[client] = -1.0;
            PartMaxChargeDamage[client] = 0.0;

            if(changed)
            {
                int roundstate = CheckRoundState();
                for(int target=0; target<MaxPartSlot[client]; target++)
                {
                    if(target < remainCount && target < MaxPartSlot[client]
                         &&
                         (!gotoNextRound[target] || (roundstate != 1 && gotoNextRound[target]))
                         )
                         {
                             ActivedPartSlotArray[client].Set(target, maxSlot[target]);
                             Forward_OnGetPart_Post(client, maxSlot[target]);

                             if(PartKV.IsPartActive(maxSlot[target]))
                                 PartMaxChargeDamage[client] += PartKV.GetPartMaxChargeDamage(maxSlot[target]);
                         }
                }
            }
        }
        else
        {
            MaxPartSlot[client] = MaxPartGlobalSlot;
            RefrashPartSlotArray(client);
            PartCharge[client] = 0.0;
            PartCooldown[client] = 0.0;
            PartMaxChargeDamage[client] = 0.0;
        }
    }
}

public void OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damagetype)
{
    if(IsValidClient(client) && IsValidClient(attacker) && IsPlayerAlive(attacker) && client != attacker)
    {
        if(PartMaxChargeDamage[attacker] > 0.0)
        {
            float realDamage = damage;
            if(damagetype & DMG_CRIT)
                realDamage *= 3.0;

            AddPartCharge(attacker, realDamage*100.0/PartMaxChargeDamage[attacker]);
        }
    }
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(!enabled || !IsCorrectTeam(client) || CheckRoundState() != 1)
    {
        return Plugin_Continue;
    }

    bool IsFake = false;
    if(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
        IsFake = true;

    for(int count = 0; count < GetConVarInt(cvarPropCount); count++)
    {
        float position[3];
        GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

        float velocity[3];
        velocity[0] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
        velocity[1] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
        velocity[2] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
        NormalizeVector(velocity, velocity);

        SpawnCustomPart(RandomPartRank(), position, velocity, IsFake);
    }

    return Plugin_Continue;
}

int SpawnCustomPart(PartRank partRank, float position[3], float velocity[3], bool IsFake)
{
    if(AllPartPropCount > 50)
    {
        return -1;
    }

    int prop = CreateEntityByName("prop_physics_override");

    if(IsValidEntity(prop))
    {
        AllPartPropCount++;

        char modelPath[PLATFORM_MAX_PATH];
        int colors[4];

        GetPartModelString(partRank, modelPath, sizeof(modelPath));

        PartPropRank[prop] = partRank;
        PartPropCustomIndex[prop] = 0;

        SetEntityModel(prop, modelPath);
        SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
        SetEntProp(prop, Prop_Send, "m_CollisionGroup", 2);

        SetEntProp(prop, Prop_Send, "m_usSolidFlags", 0x0004);
        DispatchSpawn(prop);

        GetPartRankColor(partRank, colors);

        int glow = TF2_CreateGlow(prop);
        TF2_SetGlowColor(glow, colors);

        TeleportEntity(prop, position, NULL_VECTOR, velocity);

        if(IsFake)
        {
            CreateTimer(2.0, FakePickup, EntIndexToEntRef(prop));
            SDKHook(prop, SDKHook_SetTransmit, FakePropTransmit);
        }
        else
        {
            CreateTimer(0.05, OnPickup, EntIndexToEntRef(prop));
        }
        return prop;
    }
    return -1;
}

public Action FakePropTransmit(int entity, int client)
{
	if(IsCorrectTeam(client))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action OnPickup(Handle timer, int entRef) // Copied from FF2
{
    int entity = EntRefToEntIndex(entRef);
    if(!IsValidEntity(entity))
        return Plugin_Handled;

    int client = IsEntityStuck(entity);
    if(IsValidClient(client))
    {
        Action action;
        int tempClient = client;
        int tempEntity = entity;
        int tempPart;

        if(PartGetCoolTime[client] > GetGameTime())
        {
            IgnoreAndKickIt(client, entity);
            return Plugin_Continue;
        }

        action = Forward_OnTouchedPartProp(tempClient, tempEntity);
        if(action == Plugin_Handled || action == Plugin_Stop)
        {
            IgnoreAndKickIt(client, entity);
            return Plugin_Continue;
        }
        else if(action == Plugin_Changed)
        {
            client = tempClient;
            entity = tempEntity;
        }
        Forward_OnTouchedPartProp_Post(client, entity);

        PartRank rank = view_as<PartRank>(GetPartPropInfo(entity, Info_Rank));
        int part;
        int slot;

        if(IsCorrectTeam(client))
        {
            part = GetPartPropInfo(entity, Info_CustomIndex);
            if(!PartKV.IsValidPart(part))
                part = PartKV.RandomPart(client, rank);

            slot = FindActiveSlot(client);
            tempPart = part;
            // Debug("확정된 파츠: %i, slot = %i, rank = %i", part, slot, view_as<int>(rank));

            if(part <= 0 || slot < 0) // 유효한 파츠이나 파츠 슬릇 체크
            {
                Debug("OnPickup: part = %d slot = %d", part, slot);
                IgnoreAndKickIt(client, entity);
                return Plugin_Continue;
            }

            // Debug("OnPickup: part = %d slot = %d", part, slot);
            action = Forward_OnGetPart(tempClient, tempEntity, tempPart);
            if(action == Plugin_Handled || action == Plugin_Stop)
            {
                IgnoreAndKickIt(client, entity);
                return Plugin_Continue;
            }
            else if(action == Plugin_Changed)
            {
                client = tempClient;
                entity = tempEntity;
                part = tempPart;
            }
            Forward_OnGetPart_Post(client, tempPart);

            SetClientPart(client, slot, part);
            ViewPart(client, part);
            PartGetCoolTime[client] = GetGameTime() + GetConVarFloat(cvarPropCooltime);
            PrintCenterText(client, "파츠를 흭득하셨습니다!");

            if(PartKV.IsPartActive(part))
            {
                PartMaxChargeDamage[client] += PartKV.GetPartMaxChargeDamage(part);
            }

            AcceptEntityInput(entity, "kill");
            return Plugin_Handled;
        }
        else
        {
            KickEntity(client, entity);
        }
    }

    CreateTimer(0.05, OnPickup, EntIndexToEntRef(entity));
    return Plugin_Continue;
}

void IgnoreAndKickIt(int client, int prop)
{
    KickEntity(client, prop);
    CreateTimer(0.05, OnPickup, EntIndexToEntRef(prop));
}

public Action FakePickup(Handle timer, int entRef)
{
	int entity = EntRefToEntIndex(entRef);
	if(!IsValidEntity(entity))
		return Plugin_Handled;

	int client = IsEntityStuck(entity);
	if(IsValidClient(client))
	{
		if(!IsCorrectTeam(client))
		{
			KickEntity(client, entity);
		}
		else
		{
			AcceptEntityInput(entity, "kill");
			return Plugin_Handled;
		}
	}

	CreateTimer(0.05, FakePickup, EntIndexToEntRef(entity));
	return Plugin_Continue;
}

void AddPartCharge(int client, float charge)
{
    PartCharge[client] += charge;

    if(PartCharge[client] > 100.0)
        PartCharge[client] = 100.0;
    else if(PartCharge[client] < 0.0)
        PartCharge[client] = 0.0;
}

bool IsPartActived(int client, int partIndex)
{
    return ActivedPartSlotArray[client].FindValue(partIndex) != -1;
}

bool ReplacePartSlot(int client, int beforePartIndex, int afterPartIndex)
{
    int slot = ActivedPartSlotArray[client].FindValue(beforePartIndex);
    if(slot != -1)
    {
        ActivedPartSlotArray[client].Set(slot, afterPartIndex);
        return true;
    }

    return false;
}

int FindActiveSlot(int client)
{
    // RefrashPartSlotArray(client, true, true);
    for(int i = 0;  i < MaxPartSlot[client]; i++)
    {
        int value = ActivedPartSlotArray[client].Get(i);
        // Debug("[%i] %d", i, value);
        if(value <= 0 || !PartKV.IsValidPart(value))
            return i;
    }
    return -1;
}

int GetClientPart(int client, int slot)
{
    if(IsValidSlot(client, slot))
    {
        return ActivedPartSlotArray[client].Get(slot);
    }

    return INVALID_PARTID;
}

void SetClientPart(int client, int slot, int value) // return: 적용된 슬릇 값.
{
    if(!IsValidSlot(client, slot)) return;

    int part = GetClientPart(client, slot);

    ActivedPartSlotArray[client].Set(slot, value);

    if(PartKV.IsValidPart(part))
        Forward_OnActivedPartEnd(client, part);
}

void RefrashPartSlotArray(int client, bool holdParts=false, bool holdCooltime=false)
{
    int beforeSize = ActivedPartSlotArray[client].Length;

    ActivedPartSlotArray[client].Resize(beforeSize);
    ActivedDurationArray[client].Resize(beforeSize);

    int[] beforeCell = new int[beforeSize]
    float[] beforeCooltime = new float[beforeSize]

    for(int count=0; count<beforeSize; count++)
    {
        beforeCell[count] = ActivedPartSlotArray[client].Get(count);
        beforeCooltime[count] = ActivedDurationArray[client].Get(count);
    }

    ActivedPartSlotArray[client].Clear();
    ActivedPartSlotArray[client].Resize(MaxPartSlot[client]);

    ActivedDurationArray[client].Clear();
    ActivedDurationArray[client].Resize(MaxPartSlot[client]);

    int part;
    float cooltime;

    for(int count=0; count<beforeSize; count++)
    {
        if(count < MaxPartSlot[client])
        {
            if(holdParts)
            {
                part = beforeCell[count];
                cooltime = beforeCooltime[count];

                if(PartKV.IsValidPart(part))
                {
                    ActivedPartSlotArray[client].Set(count, part);

                    if(holdCooltime)
                    {
                        ActivedDurationArray[client].Set(count, cooltime);
                    }
                    else
                    {
                        ActivedDurationArray[client].Set(count, 0.0);
                    }
                }
            }
            else
            {
                ActivedPartSlotArray[client].Set(count, 0);
                ActivedDurationArray[client].Set(count, 0.0);

            }
        }
        else
        {
            part = beforeCell[count];

            if(PartKV.IsValidPart(part))
            {
                Forward_OnSlotClear(client, part, false);
            }

        }
    }
}

bool IsValidSlot(int client, int slot)
{
    if(MaxPartSlot[client] > slot
        && ActivedPartSlotArray[client].Length > slot
        && slot >= 0)
        return true;

    return false;
}

bool IsClientHaveActivePart(int client)
{
    int part;

    for(int count=0; count<MaxPartSlot[client]; count++)
    {
        part = GetClientPart(client, count);
        if(PartKV.IsPartActive(part))
            return true;
    }
    return false;
}

float GetClientTotalCooldown(int client)
{
    int part;
    float totalCooldown;

    for(int count=0; count<MaxPartSlot[client]; count++)
    {
        part = GetClientPart(client, count);

        if(IsValidSlot(client, count) && PartKV.IsValidPart(part))
        {
            totalCooldown += PartKV.GetActivePartDuration(part);
        }
    }

    return totalCooldown;
}

float GetClientPartCooldown(int client)
{
    float cooldown = PartCooldown[client];
    return cooldown > 0.0 ? cooldown : 0.0;
}

void SetClientPartCooldown(int client, float cooldown)
{
    PartCooldown[client] = cooldown;
}

float GetClientActiveSlotDuration(int client, int slot)
{
    if(IsValidSlot(client, slot))
    {
        float duration = ActivedDurationArray[client].Get(slot);

        if(duration < 0.0)
        {
            duration = 0.0;
        }

        return duration;
    }

    return -1.0;
}

void SetClientActiveSlotDuration(int client, int slot, float duration)
{
    if(IsValidSlot(client, slot))
    {
        ActivedDurationArray[client].Set(slot, duration);
    }
}

bool IsClientHaveDuration(int client)
{
    for(int count=0; count<MaxPartSlot[client]; count++)
    {
        if(IsValidSlot(client, count))
        {
            if(ActivedDurationArray[client].Get(count) > 0.0)
                return true;
        }
    }

    return false;
}

public Native_GetClientPart(Handle plugin, int numParams)
{
    return GetClientPart(GetNativeCell(1), GetNativeCell(2));
}

public Native_SetClientPart(Handle plugin, int numParams)
{
    SetClientPart(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_IsPartActived(Handle plugin, int numParams)
{
    return _:IsPartActived(GetNativeCell(1), GetNativeCell(2));
}

public Native_RefrashPartSlotArray(Handle plugin, int numParams)
{
    RefrashPartSlotArray(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_IsValidPart(Handle plugin, int numParams)
{
    return PartKV.IsValidPart(GetNativeCell(1));
}

public Native_IsValidSlot(Handle plugin, int numParams)
{
    return IsValidSlot(GetNativeCell(1), GetNativeCell(2));
}

public Native_GetPartPropInfo(Handle plugin, int numParams)
{
    return GetPartPropInfo(GetNativeCell(1), GetNativeCell(2));
}

public Native_SetPartPropInfo(Handle plugin, int numParams)
{
    SetPartPropInfo(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4));
}

public Native_PropToPartProp(Handle plugin, int numParams)
{
    PropToPartProp(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6));
}

public Native_GetClientMaxslot(Handle plugin, int numParams)
{
    return GetClientMaxSlot(GetNativeCell(1));
}

public Native_SetClientMaxslot(Handle plugin, int numParams)
{
    SetClientMaxSlot(GetNativeCell(1), GetNativeCell(2));
}

public Native_ReplacePartSlot(Handle plugin, int numParams)
{
    return ReplacePartSlot(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_FindActiveSlot(Handle plugin, int numParams)
{
    return FindActiveSlot(GetNativeCell(1));
}

public Native_NoticePart(Handle plugin, int numParams)
{
    NoticePart(GetNativeCell(1), GetNativeCell(2));
}

public Native_GetClientActiveSlotDuration(Handle plugin, int numParams)
{
    return _:GetClientActiveSlotDuration(GetNativeCell(1), GetNativeCell(2));
}

public Native_SetClientActiveSlotDuration(Handle plugin, int numParams)
{
    SetClientActiveSlotDuration(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public Native_GetClientTotalCooldown(Handle plugin, int numParams)
{
    return _:GetClientTotalCooldown(GetNativeCell(1));
}

public Native_GetClientPartCharge(Handle plugin, int numParams)
{
    return _:PartCharge[GetNativeCell(1)];
}

public Native_SetClientPartCharge(Handle plugin, int numParams)
{
    PartCharge[GetNativeCell(1)] = GetNativeCell(2);
}

public Native_GetClientPartMaxChargeDamage(Handle plugin, int numParams)
{
    return _:PartMaxChargeDamage[GetNativeCell(1)];
}

public Native_SetClientPartMaxChargeDamage(Handle plugin, int numParams)
{
    PartMaxChargeDamage[GetNativeCell(1)] = GetNativeCell(2);
}

public Native_AddClientPartCharge(Handle plugin, int numParams)
{
    AddPartCharge(GetNativeCell(1), GetNativeCell(2));
}

public Native_FindPart(Handle plugin, int numParams)
{
    return FindPart(GetNativeCell(1), GetNativeCell(2));
}

public Native_IsEnabled(Handle plugin, int numParams)
{
    return enabled;
}

public Native_RandomPart(Handle plugin, int numParams)
{
    return _:PartKV.RandomPart(GetNativeCell(1), GetNativeCell(2));
}

public Native_RandomPartRank(Handle plugin, int numParams)
{
    return _:RandomPartRank(GetNativeCell(1));
}

public Native_GetClientCPFlags(Handle plugin, int numParams)
{
    return CPFlags[GetNativeCell(1)];
}

public Native_SetClientCPFlags(Handle plugin, int numParams)
{
     CPFlags[GetNativeCell(1)] = GetNativeCell(2);
}

int FindPart(int client, int partIndex)
{
    return ActivedPartSlotArray[client].FindValue(partIndex);
}

int GetClientMaxSlot(int client)
{
    return MaxPartSlot[client];
}

void SetClientMaxSlot(int client, int maxSlot)
{
    MaxPartSlot[client] = maxSlot;

    RefrashPartSlotArray(client, true, true);
    // ActivedPartSlotArray[client].Resize(MaxPartSlot[client]);
    // ActivedDurationArray[client].Resize(MaxPartSlot[client]);
}

stock bool IsCorrectTeam(int client)
{
	if(PropForTeam != TFTeam_Red && PropForTeam != TFTeam_Blue)
		return true;

	return PropForTeam == TF2_GetClientTeam(client);
}

stock int IsEntityStuck(int entity) // Copied from Chdata's FFF
{/*
 	float vecMin[3], vecMax[3], vecOrigin[3];

    GetEntPropVector(entity, Prop_Send, "m_vecMins", vecMin);
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMax);
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);

    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceRayPlayerOnly, entity);
    if(TR_DidHit())
	{
		return TR_GetEntityIndex();
	}
	return -1;
	*/
	float vecOrigin[3], playerOrigin[3];
	float propsize = GetConVarFloat(cvarPropSize);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerOrigin);

			if(CheckCollision(vecOrigin, playerOrigin, propsize))
				return client;
		}
	}

	return -1;
}
