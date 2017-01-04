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

#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <custompart>

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

#define INVALID_PARTID -1

#define	MAX_EDICT_BITS	12
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

Handle PartKV;
Handle CPHud;
Handle CPChargeHud;
Handle cvarChatCommand;

Handle OnTouchedPartProp;
Handle OnTouchedPartPropPost;
Handle OnGetPart;
Handle OnGetPartPost;
Handle OnSlotClear;
Handle PreActivePart;
Handle OnActivedPart;
Handle OnActivedPartEnd;
Handle OnClientCooldownEnd;

int g_iChatCommand=0;
char g_strChatCommand[42][50];

int MaxPartGlobalSlot=1;

bool enabled;

TFTeam PropForTeam;

Handle cvarPropCount;
Handle cvarPropVelocity;
Handle cvarPropForNoBossTeam;
Handle cvarPropSize;

int NeedHelpPart;
int CPFlags[MAXPLAYERS+1];

int MaxPartSlot[MAXPLAYERS+1];
int LastSelectedSlot[MAXPLAYERS+1];
PartRank SelectedBookRank[MAXPLAYERS+1];

ArrayList ActivedPartSlotArray[MAXPLAYERS+1];
ArrayList ActivedDurationArray[MAXPLAYERS+1];

float PartCharge[MAXPLAYERS+1];
float PartMaxChargeDamage[MAXPLAYERS+1];
float PartCooldown[MAXPLAYERS+1];

// TODO: 최적화
PartRank PartPropRank[MAX_EDICTS+1];
int PartPropCustomIndex[MAX_EDICTS+1];

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
    CreateNative("CP_RandomPartRank", Native_RandomPartRank);

    OnTouchedPartProp = CreateGlobalForward("CP_OnTouchedPartProp", ET_Hook, Param_Cell, Param_Cell);
    OnTouchedPartPropPost = CreateGlobalForward("CP_OnTouchedPartProp_Post", ET_Hook, Param_Cell, Param_Cell);
    OnGetPart = CreateGlobalForward("CP_OnGetPart", ET_Hook, Param_Cell, Param_Cell, Param_Cell);
    OnGetPartPost = CreateGlobalForward("CP_OnGetPart_Post", ET_Hook, Param_Cell, Param_Cell);
    OnSlotClear = CreateGlobalForward("CP_OnSlotClear", ET_Hook, Param_Cell, Param_Cell, Param_Cell);
    PreActivePart = CreateGlobalForward("CP_PreActivePart", ET_Hook, Param_Cell, Param_Cell);
    OnActivedPart = CreateGlobalForward("CP_OnActivedPart", ET_Hook, Param_Cell, Param_Cell);
    OnActivedPartEnd = CreateGlobalForward("CP_OnActivedPart", ET_Hook, Param_Cell, Param_Cell);
    OnClientCooldownEnd = CreateGlobalForward("CP_OnClientCooldownEnd", ET_Hook, Param_Cell);

	return APLRes_Success;
}

public void OnPluginStart()
{
      cvarChatCommand = CreateConVar("cp_chatcommand", "파츠,part,스킬");

      cvarPropCount = CreateConVar("cp_prop_count", "1", "생성되는 프롭 갯수, 0은 생성을 안함", _, true, 0.0);
      cvarPropVelocity = CreateConVar("cp_prop_velocity", "250.0", "프롭 생성시 흩어지는 최대 속도, 설정한 범위 내로 랜덤으로 속도가 정해집니다.", _, true, 0.0);
      cvarPropForNoBossTeam = CreateConVar("cp_prop_for_team", "2", "0 혹은 1은 제한 없음, 2는 레드팀에게만, 3은 블루팀에게만. (생성도 포함됨.)", _, true, 0.0, true, 2.0);
      cvarPropSize = CreateConVar("cp_prop_size", "50.0", "캡슐 섭취 범위", _, true, 0.1);

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

      // HookEvent("teamplay_round_start", OnRoundStart);
      HookEvent("teamplay_round_win", OnRoundEnd);

      CPHud = CreateHudSynchronizer();
      CPChargeHud = CreateHudSynchronizer();

      CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT);

      for(int client=1; client<=MaxClients; client++)
      {
          ActivedPartSlotArray[client] = new ArrayList();
          ActivedPartSlotArray[client].Resize(50);

          ActivedDurationArray[client] = new ArrayList();
          ActivedDurationArray[client].Resize(50);
      }
}


public Action GivePart(int client, int args)
{
    if(!enabled)
	{
		return Plugin_Continue;
	}

	if(args != 2)
	{
		CReplyToCommand(client, "{yellow}[CP]{default} Usage: !givepart <target> <points>");
		return Plugin_Handled;
	}

    char num[25];
    int part;
	char stringPoints[8];
	char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, num, sizeof(num));
	part = StringToInt(num);

	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

    if(!IsValidPart(part)) return Plugin_Handled;

	if(matches>1)
	{
		for(int target; target<matches; target++)
		{
			if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
			{
                int slot = FindActiveSlot(targets[target]);
                if(IsValidSlot(targets[target], slot))
                {
                    SetClientPart(targets[target], slot, part);
                    PartMaxChargeDamage[targets[target]] += GetPartMaxChargeDamage(part);
                    Forward_OnGetPart_Post(targets[target], part);
                    CPrintToChatAll("{yellow}[CP]{default} %N님이 %N에게 %i가 추가됨.", client, targets[target], part);
                }
            }
		}
	}
	else
	{
        int slot = FindActiveSlot(targets[0]);
        if(IsValidSlot(targets[0], slot))
        {
            SetClientPart(targets[0], slot, part);
            PartMaxChargeDamage[targets[0]] += GetPartMaxChargeDamage(part);
            Forward_OnGetPart_Post(targets[0], part);
            CPrintToChatAll("{yellow}[CP]{default} %N님이 %N에게 %i가 추가됨.", client, targets[0], part);
        }
	}
	return Plugin_Handled;
}

public void OnGameFrame()
{
    if(CheckRoundState() != 1) return;

    float duration;
    // int part;

    for(int client=1; client<=MaxClients; client++)
    {
        if(!IsClientInGame(client)
        || ActivedDurationArray[client] == INVALID_HANDLE
        || ActivedPartSlotArray[client] == INVALID_HANDLE)
        continue;

        if(IsPlayerAlive(client))
        {
            if(IsClientHaveDuration(client))
            {
                for(int count=0; count<MaxPartSlot[count]; count++)
                {
                    duration = GetClientActiveSlotDuration(client, count);
                    if(duration != -1.0 && duration <= 0.0)
                    {
                        SetClientActiveSlotDuration(client, count, -1.0);
                        Forward_OnActivedPartEnd(client, GetClientPart(client, count));
                    }
                }

                if(!IsClientHaveDuration(client)) // 능력 지속시간이 끝났을 경우, 쿨타임 부여
                {
                    PartCooldown[client] = GetClientTotalCooldown(client) + GetGameTime();
                }
            }
            else
            {
                if(PartCooldown[client] != -1.0 && PartCooldown[client] <= GetGameTime())
                {
                    PartCooldown[client] = -1.0;
                    Forward_OnClientCooldownEnd(client);
                }
            }
        }
    }
}


public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
    for(int client=1; client<=MaxClients; client++)
    {
        CPFlags[client] = 0;

        bool changed = false;

        if(ActivedPartSlotArray[client].Length > 0) // TODO: 동일한 역할들을 묶어놓기.
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

                if(!IsValidPart(temp)) continue;

                tempPart = temp;
                tempGoToNextRound = false;

                action = Forward_OnSlotClear(tempClient, tempPart, tempGoToNextRound);

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

                             if(IsPartActive(maxSlot[target]))
                                 PartMaxChargeDamage[client] += GetPartMaxChargeDamage(maxSlot[target]);
                         }
                }
            }
        }
    }
}

public Action ClientTimer(Handle timer)
{
    int target;
    int part;
    bool hasActivePart = false;
    char HudMessage[200];
    char partName[100];

    if(CheckRoundState() != 1)
        return Plugin_Continue;

    for(int client=1; client<=MaxClients; client++)
    {
        hasActivePart = false;
        if(!IsClientInGame(client)) continue;

        if(!(CPFlags[client] & CPFLAG_DISABLE_HUD))
        {
            SetHudTextParams(0.8, 0.1, 0.22, 255, 228, 0, 185);

            if(IsPlayerAlive(client))
            {
                target = client;
                Format(HudMessage, sizeof(HudMessage), "활성화된 파츠:");
            }
            else
            {
                target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
                Format(HudMessage, sizeof(HudMessage), "관전 중인 상대 파츠:");
            }

            if(IsValidClient(target))
            {
                int partcount = 0;
                for(int count = 0; count < MaxPartSlot[target]; count++)
                {
                    if(IsValidSlot(target, count) && IsValidPart((part = GetClientPart(target, count))))
                    {
                        if(IsPartActive(part))
                            hasActivePart = true;

                        if(partcount <= 5)
                        {
                            GetPartString(part, "name", partName, sizeof(partName));
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
                    SetHudTextParams(-1.0, 0.76, 0.22, 255, 228, 0, 185);

                    int ragemeter = RoundFloat(PartCharge[target]*(PartMaxChargeDamage[target]/100.0));

                    if(GetClientPartCooldown(target) > 0.0)
                    {
                        Format(HudMessage, sizeof(HudMessage), "액티브 파츠 쿨타임: %.1f", GetClientPartCooldown(target));
                    }
                    else if(IsClientHaveDuration(target))
                    {
                        int activeCount=0;

                        for(int count=0; count<MaxPartSlot[target]; count++)
                        {
                            if(GetClientActiveSlotDuration(target, count) > 0.0 && IsValidPart((part = GetClientPart(target, count))))
                            {
                                GetPartString(part, "name", partName, sizeof(partName));
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
        Action action;
        RefrashPartSlotArray(client, true, true);

        // PartCooldown[client] = GetClientTotalCooldown(client);

        for(int count=0; count<MaxPartSlot[client]; count++)
        {
            int part = GetClientPart(client, count);
            if(IsPartActive(part))
            {
                action = Forward_PreActivePart(client, part);
                if(action == Plugin_Handled)
                    continue;

                SetClientActiveSlotDuration(client, count, GetActivePartDuration(part));
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
        PartPropRank[entity] = Rank_Normal;
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

            if(!IsValidPart(tempPart)) continue;

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
    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
    // ActivedPartSlotArray[client] = view_as<ArrayList>(INVALID_HANDLE);
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    if(enabled)
    {
        int client = GetClientOfUserId(GetEventInt(event, "userid"));
        bool changed = false;

        if(ActivedPartSlotArray[client].Length > 0) // 아마도 될껄?
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

                if(!IsValidPart(temp)) continue;

                tempPart = temp;
                tempGoToNextRound = false;

                action = Forward_OnSlotClear(tempClient, tempPart, tempGoToNextRound);

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

                             if(IsPartActive(maxSlot[target]))
                                 PartMaxChargeDamage[client] += GetPartMaxChargeDamage(maxSlot[target]);
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
    if(IsValidClient(client) && IsValidClient(attacker) && IsPlayerAlive(attacker))
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
    int prop = CreateEntityByName("prop_physics_override");
    if(IsValidEntity(prop))
    {
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
/*
		if(((IsCorrectTeam(client) && CanUseSystemClass(TF2_GetPlayerClass(client)))
        || (IsBoss(client) && CanUseSystemBoss() && rank == Rank_Another))
        ) // FIXME:
*/
        if((IsCorrectTeam(client)
        || (IsBoss(client) && CanUseSystemBoss() && rank == Rank_Another))
        )
		{
            part = GetPartPropInfo(entity, Info_CustomIndex);
            if(!IsValidPart(part))
                part = RandomPart(client, rank);

            slot = FindActiveSlot(client);
            tempPart = part;

            Debug("확정된 파츠: %i, slot = %i, rank = %i", part, slot, view_as<int>(rank));

            if(part <= 0 || slot < 0) // 유효한 파츠이나 파츠 슬릇 체크
            {
                IgnoreAndKickIt(client, entity);
                return Plugin_Continue;
            }

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
            PrintCenterText(client, "파츠를 흭득하셨습니다!");

            if(IsPartActive(part))
            {
                PartMaxChargeDamage[client] += GetPartMaxChargeDamage(part);
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

public Action Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client)) return Plugin_Continue;

	char strChat[100];
	char temp[3][64];
	GetCmdArgString(strChat, sizeof(strChat));

	int start;

	if(strChat[start] == '"') start++;
	if(strChat[start] == '!' || strChat[start] == '/') start++;
	strChat[strlen(strChat)-1] = '\0';
	ExplodeString(strChat[start], " ", temp, 3, 64, true);

	for (int i=0; i<=g_iChatCommand; i++)
	{
		if(StrEqual(temp[0], g_strChatCommand[i], true))
		{
			if(temp[1][0] != '\0')
			{
				return Plugin_Continue;
			}

			ViewSlotPart(client);
			return Plugin_Handled;
		}
	}

    if(StrEqual(temp[0], "파츠도감", true)
    || StrEqual(temp[0], "partbook", true)
    || StrEqual(temp[0], "partinfo", true))
    {
        if(temp[1][0] != '\0')
        {
            return Plugin_Continue;
        }

        ViewPartBook(client);
        return Plugin_Handled;
    }

	return Plugin_Continue;
}

void ViewPartBook(int client)
{
    Menu menu = new Menu(OnSelectedBook);

    menu.SetTitle("등급별로 파츠를 보실 수 있습니다.\n무엇을 보실건가요?");

    menu.AddItem("일반", "일반 등급");
    menu.AddItem("희귀", "희귀 등급");
    menu.AddItem("영웅", "영웅 등급");
    menu.AddItem("전설", "전설 등급");
    menu.AddItem("어나더", "어나더 등급");

    menu.ExitButton = true;

    menu.Display(client, 40);
}

public int OnSelectedBook(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
      case MenuAction_Select:
      {
          SelectedBookRank[client] = view_as<PartRank>(item)
          LastSelectedSlot[client] = 0;
          ViewPartBookItem(client, SelectedBookRank[client], LastSelectedSlot[client]);
      }
    }
}

void ViewPartBookItem(int client, PartRank rank, int pos)
{
    char partName[80];
    char item[500];
    char tempItem[200];

    int count = GetValidPartCount(rank);
    int[] partArray = new int[count]
    GetValidPartArray(rank, partArray, count);

    int part = partArray[pos];

    Menu menu = new Menu(OnSelectedBookItem);

    GetPartString(part, "name", tempItem, sizeof(tempItem));
    Format(item, sizeof(item), "이름: %s", tempItem);
    // menu.AddItem("name", item, ITEMDRAW_DISABLED);

    GetPartString(part, "description", tempItem, sizeof(tempItem));
    Format(item, sizeof(item), "%s\n\n설명: %s", item, tempItem);
    // menu.AddItem("description", item, ITEMDRAW_DISABLED);

    GetPartString(part, "ability_description", tempItem, sizeof(tempItem));
    Format(item, sizeof(item), "%s\n\n능력 설명: %s", item, tempItem);
    // menu.AddItem("ability_description", item, ITEMDRAW_DISABLED);

    GetPartString(part, "idea_owner_nickname", tempItem, sizeof(tempItem));
    if(tempItem[0] != '\0') Format(item, sizeof(item), "%s\n\n아이디어 제공: %s\n\n", item, tempItem);
    else Format(item, sizeof(item), "%s\n\nPOTRY SERVER ORIGINAL CUSTOMPART\n\n", item);
    // menu.AddItem("idea_owner_nickname", item, ITEMDRAW_DISABLED);

    menu.SetTitle(item);

    int itemFlags;
    if(pos - 1 >= 0)
        Format(item, sizeof(item), "이전으로");
    else
    {
        itemFlags = ITEMDRAW_DISABLED;
        Format(item, sizeof(item), "이전 파츠가 없습니다.");
    }
    menu.AddItem("older", item, itemFlags);

    itemFlags = 0;

    if(pos + 1 < count)
        Format(item, sizeof(item), "다음으로");
    else
    {
        itemFlags = ITEMDRAW_DISABLED;
        Format(item, sizeof(item), "다음 파츠가 없습니다.");
    }
    menu.AddItem("newer", item, itemFlags);

    menu.ExitButton = true;
    menu.Display(client, 40);
}

public int OnSelectedBookItem(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
      case MenuAction_Select:
      {
          switch(item)
          {
              case 0:
              {
                ViewPartBookItem(client, SelectedBookRank[client], --LastSelectedSlot[client]);
              }
              case 1:
              {
                ViewPartBookItem(client, SelectedBookRank[client], ++LastSelectedSlot[client]);
              }
          }
      }
    }
}

void ViewPart(int client, int partIndex)
{
    if(IsValidPart(partIndex))
    {
        char item[500];
        char tempItem[200];
        Format(item, sizeof(item), "방금 흭득한 파츠:");

        GetPartString(partIndex, "name", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n\n이름: %s", item, tempItem);

        GetPartString(partIndex, "ability_description", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n능력 설명: %s", item, tempItem);

        PrintHintText(client, item);
    }
}

void ViewSlotPart(int client, int slot=0)
{
    if(IsValidSlot(client, slot))
    {
        int part;

        if(!IsValidPart((part = GetClientPart(client, slot))))
            part = INVALID_PARTID;

        char item[500];
        char tempItem[200];
        Menu menu = new Menu(OnSelectedSlotItem);
        // menu.SetTitle("현재 파츠: (슬릇: %i / %i)", slot+1, MaxPartSlot[client]);
        Format(item, sizeof(item), "현재 파츠: (슬릇: %i / %i)", slot+1, MaxPartSlot[client]);

        GetPartString(part, "name", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n\n이름: %s", item, tempItem);
        // menu.AddItem("name", item, ITEMDRAW_DISABLED);

        GetPartString(part, "description", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n\n설명: %s", item, tempItem);
        // menu.AddItem("description", item, ITEMDRAW_DISABLED);

        GetPartString(part, "ability_description", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n\n능력 설명: %s", item, tempItem);
        // menu.AddItem("ability_description", item, ITEMDRAW_DISABLED);

        GetPartString(part, "idea_owner_nickname", tempItem, sizeof(tempItem));
        if(tempItem[0] != '\0') Format(item, sizeof(item), "%s\n\n아이디어 제공: %s\n\n", item, tempItem);
        else Format(item, sizeof(item), "%s\n\nPOTRY SERVER ORIGINAL CUSTOMPART\n\n", item);
        // menu.AddItem("idea_owner_nickname", item, ITEMDRAW_DISABLED);

        menu.SetTitle(item);

        int itemFlags;
        if(slot - 1 >= 0)
            Format(item, sizeof(item), "이전 슬릇으로");
        else
        {
            itemFlags = ITEMDRAW_DISABLED;
            Format(item, sizeof(item), "이전 슬릇이 없습니다.");
        }
        menu.AddItem("older", item, itemFlags);

        itemFlags = 0;

        if(slot + 1 < MaxPartSlot[client])
            Format(item, sizeof(item), "다음 슬릇으로");
        else
        {
            itemFlags = ITEMDRAW_DISABLED;
            Format(item, sizeof(item), "다음 슬릇이 없습니다.");
        }
        menu.AddItem("newer", item, itemFlags);
        menu.ExitButton = true;

        LastSelectedSlot[client] = slot;

        menu.Display(client, 40);
    }
}

public int OnSelectedSlotItem(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
      case MenuAction_Select:
      {
          RefrashPartSlotArray(client, true, true);
          switch(item)
          {
              case 0:
              {
                ViewSlotPart(client, --LastSelectedSlot[client]);
              }
              case 1:
              {
                ViewSlotPart(client, ++LastSelectedSlot[client]);
              }
          }
      }
    }
}

public int OnSelected(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
    }
}

int GetValidPartCount(PartRank rank = Rank_None)
{
    int count;
    int part;
    int integerRank = view_as<int>(rank);

    Handle clonedHandle = CloneHandle(PartKV);
    KvRewind(clonedHandle);
    char key[20];

    if(KvGotoFirstSubKey(clonedHandle))
    {
        do
        {
            KvGetSectionName(clonedHandle, key, sizeof(key));
            if(!StrContains(key, "part"))
            {
                ReplaceString(key, sizeof(key), "part", "");
                if(IsValidPart((part = StringToInt(key))))
                {
                    if(part <= 0) continue;

                    if(rank == Rank_None || KvGetNum(PartKV, "rank") == integerRank)
                        count++;
                }
            }
        }
        while(KvGotoNextKey(clonedHandle));
    }

    return count;
}

public void GetValidPartArray(PartRank rank, int[] parts, int size)
{
    int count;
    int part;
    int integerRank = view_as<int>(rank);

    Handle clonedHandle = CloneHandle(PartKV);
    KvRewind(clonedHandle);
    char key[20];

    if(KvGotoFirstSubKey(clonedHandle))
    {
        do
        {
            KvGetSectionName(clonedHandle, key, sizeof(key));
            if(!StrContains(key, "part"))
            {
                ReplaceString(key, sizeof(key), "part", "");
                if(IsValidPart((part = StringToInt(key))))
                {
                    if(part <= 0) continue;

                    if(rank == Rank_None || KvGetNum(PartKV, "rank") == integerRank)
                        parts[count++] = part;
                }
            }
        }
        while(KvGotoNextKey(clonedHandle) && count < size);
    }
}

int RandomPart(int client, PartRank rank)
{
    ArrayList parts = new ArrayList();
    int count = 0;
    int part;

    char key[20];
    bool isBoss = IsBoss(client);
    TFClassType class = TF2_GetPlayerClass(client);

    Handle clonedHandle = CloneHandle(PartKV);
    KvRewind(clonedHandle);

    if(KvGotoFirstSubKey(clonedHandle))
    {
        do
        {
            KvGetSectionName(clonedHandle, key, sizeof(key));
            if(!StrContains(key, "part"))
            {
                ReplaceString(key, sizeof(key), "part", "");
                if(IsValidPart((part = StringToInt(key))))
                {
                    if(part <= 0) continue;

                    if(((isBoss && CanUsePartBoss(part))
                    || (!isBoss && CanUsePartClass(part, class) && !CanUsePartBoss(part))) // FIXME: 보스의 파츠를 인간도 먹어버림.
                    && GetPartRank(part) == rank && IsCanUseWeaponPart(client, part)
                    && KvGetNum(clonedHandle, "not_able_in_random", 0) <= 0
                    )
                    {
                        count++;
                        parts.Push(part);
                    }
                }
            }
        }
        while(KvGotoNextKey(clonedHandle));
    }

    SetRandomSeed(GetTime());
    int answer;

    if(count <= 0)
    {
        parts.Close();

        int integerRank = view_as<int>(rank);
        if(--integerRank < 0)
            return 0;

        answer = RandomPart(client, view_as<PartRank>(integerRank));
    }
    else
    {
        answer = parts.Get(GetRandomInt(0, count-1));
    }
    parts.Close();

    // Debug("%d가 RandomPart에서 반환됨.", answer);
    return answer;
}

PartRank RandomPartRank(bool includeAnother=false)
{
    int ranklist[5];
    ranklist[0] = 50;
    ranklist[1] = 40;
    ranklist[2] = 25;
    ranklist[3] = 10;
    ranklist[4] = 20;

    SetRandomSeed(GetTime() + GetRandomInt(-100, 100));

    int total;
    if(!includeAnother)
        total = ranklist[0] + ranklist[1] + ranklist[2] + ranklist[3];
    else
        total = ranklist[0] + ranklist[1] + ranklist[2] + ranklist[3] + ranklist[4];

    int winner = GetRandomInt(0, total);
    int tempcount;

    PartRank rank;

    for(int count; count < 5; count++)
    {
        tempcount += ranklist[count];

        if(tempcount >= winner)
        {
            if(count == 0)  rank = Rank_Normal;
            else if(count == 1) rank = Rank_Rare;
            else if(count == 2) rank = Rank_Hero;
            else if(count == 3) rank = Rank_Legend;
            else if(count == 4) rank = Rank_Another;

            break;
        }
    }

    return rank;
}

void NoticePart(int client, int partIndex)
{
    char partName[100];
    GetPartString(partIndex, "name", partName, sizeof(partName));

    CPrintToChatAll("{yellow}[CP]{default} {red}%N{default}님의 {limegreen}%s{default} 발동!", client, partName);
    NeedHelpPart = partIndex;
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
    for(int i = 0;  i < MaxPartSlot[client]; i++)
    {
        int value = ActivedPartSlotArray[client].Get(i);
        // Debug("[%i] %d", i, value);
        if(value <= 0 || !IsValidPart(value))
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

    ActivedPartSlotArray[client].Set(slot, value);
}

void RefrashPartSlotArray(int client, bool holdParts=false, bool holdCooltime=false)
{
    int beforeSize = ActivedPartSlotArray[client].Length;

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

    for(int count=0; count<MaxPartSlot[client]; count++)
    {
        if(holdParts)
        {
            part = beforeCell[count];
            cooltime = beforeCooltime[count];

            if(IsValidPart(part))
            {
                ActivedPartSlotArray[client].Set(count, part);

                if(holdCooltime)
                {
                    ActivedDurationArray[client].Set(count, cooltime);
                }
            }
//
        }
        else
        {
            ActivedPartSlotArray[client].Set(count, 0);
            ActivedDurationArray[client].Set(count, -1.0);

        }
        // Debug("%N: [%i] %i", client, count, ActivedPartSlotArray[client].Get(count));
    }

}


bool IsValidPart(int partIndex)
{
    KvRewind(PartKV);

    char temp[30];
    Format(temp, sizeof(temp), "part%i", partIndex);

    if(KvJumpToKey(PartKV, temp))
        return true;

    return false;
}

bool IsValidSlot(int client, int slot)
{
    if(MaxPartSlot[client] > slot
        && ActivedPartSlotArray[client].Length > slot
        && slot >= 0)
        return true;

    return false;
}

bool IsPartActive(int partIndex)
{
    if(IsValidPart(partIndex))
    {
        return KvGetNum(PartKV, "active_part", 0) > 0;
    }

    return false;
}

bool IsCanUseWeaponPart(int client, int partIndex)
{
    int weapon;
    int index;
    char key[20];
    int count;
    int value;
    bool what=true;

    if(!IsValidPart(partIndex)) return false;

    for(int slot=0; slot<5; slot++)
    {
        count = 0;
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEntity(weapon))
        {
            index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
            do
            {
                Format(key, sizeof(key), "only_allow_weapon%i", ++count);
                value = KvGetNum(PartKV, key, 0);

                if(value == index)
                    return true;

                else if(count <= 1 && value <= 0)
                    return true;

                else if(value <= 0)
                    break;
            }
            while(what);
        }
    }

    return false;
}

bool IsClientHaveActivePart(int client)
{
    int part;

    for(int count=0; count<MaxPartSlot[client]; count++)
    {
        part = GetClientPart(client, count);
        if(IsPartActive(part))
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

        if(IsValidSlot(client, count) && IsValidPart(part))
        {
            totalCooldown += GetActivePartDuration(part);
        }
    }

    return totalCooldown;
}

float GetClientPartCooldown(int client)
{
    float cooldown = PartCooldown[client] - GetGameTime();
    return cooldown > 0.0 ? cooldown : 0.0;
}

void SetClientPartCooldown(int client, float cooldown)
{
    float realCooldown = duration + GetGameTime();
    PartCooldown[client] = realCooldown;
}

float GetActivePartDuration(int partIndex)
{
    if(IsValidPart(partIndex))
    {
        return KvGetFloat(PartKV, "active_duration", 8.0);
    }

    return 0.0;
}

float GetActivePartCooldown(int partIndex)
{
    if(IsValidPart(partIndex))
    {
        return KvGetFloat(PartKV, "active_cooldown", 8.0);
    }

    return 0.0;
}

float GetClientActiveSlotDuration(int client, int slot)
{
    if(IsValidSlot(client, slot))
    {
        float duration = ActivedDurationArray[client].Get(slot) - GetGameTime();
        float realDuration;

        if(duration > 0.0)
        {
            realDuration = duration;
        }
        else if(ActivedDurationArray[client].Get(slot) == -1.0)
        {
            realDuration = -1.0;
        }
        else
        {
            realDuration = 0.0;
        }

        return realDuration;
    }

    return -1.0;
}

void SetClientActiveSlotDuration(int client, int slot, float duration)
{
    if(IsValidSlot(client, slot))
    {
        float realDuration = duration + GetGameTime();

        if(realDuration <= GetGameTime() || duration <= 0.0)
            realDuration = -1.0;

        ActivedDurationArray[client].Set(slot, realDuration);
    }
}

bool IsClientHaveDuration(int client)
{
    for(int count=0; count<MaxPartSlot[client]; count++)
    {
        if(IsValidSlot(client, count))
        {
            if(ActivedDurationArray[client].Get(count) > GetGameTime() && ActivedDurationArray[client].Get(count) != -1.0)
                return true;
        }
    }

    return false;
}

float GetPartMaxChargeDamage(int partIndex)
{
    if(IsValidPart(partIndex))
    {
        return KvGetFloat(PartKV, "active_max_charge", 100.0);
    }

    return 0.0;
}

PartRank GetPartRank(int partIndex)
{
    if(IsValidPart(partIndex))
    {
        return view_as<PartRank>(KvGetNum(PartKV, "rank"));
    }

    return Rank_Normal;
}

public void GetPartString(int partIndex, char[] key, char[] values, int bufferLength)
{
    if(partIndex == -1)
    {
        Format(values, bufferLength, "비어있음!");
    }
    else if(IsValidPart(partIndex))
    {
        KvGetString(PartKV, key, values, bufferLength);
    }
}

int GetPartPropInfo(int prop, PartInfo partinfo)
{
    switch(partinfo)
    {
      case Info_Rank:
      {
        return view_as<int>(PartPropRank[prop]);
      }

      case Info_CustomIndex:
      {
        return PartPropCustomIndex[prop];
      }
    }

    return -1;
}

void SetPartPropInfo(int prop, PartInfo partinfo, any value, bool changeModel = false)
{
    switch(partinfo)
    {
      case Info_Rank:
      {
        // PartPropRank[prop] = view_as<PartRank>(value);
        PartPropRank[prop] = value;
      }

      case Info_CustomIndex:
      {
        PartPropCustomIndex[prop] = value;
      }
    }

    if(changeModel)
    {
        char model[PLATFORM_MAX_PATH];
        GetPartModelString(view_as<PartRank>(GetPartPropInfo(prop, Info_Rank)), model, sizeof(model));

        SetEntityModel(prop, model);
    }
}

void PropToPartProp(int prop, int partIndex=0, PartRank rank=Rank_Normal, bool createLight, bool changeModel=false, bool IsFake=false)
{
    if(!IsValidEntity(prop)) return;

    SetPartPropInfo(prop, Info_Rank, rank, changeModel);
    SetPartPropInfo(prop, Info_CustomIndex, partIndex, changeModel);

    SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
    SetEntProp(prop, Prop_Send, "m_CollisionGroup", 2);

    if(createLight)
    {
        int colors[4];
        int glow = TF2_CreateGlow(prop);
        GetPartRankColor(rank, colors);
        TF2_SetGlowColor(glow, colors);
    }

    if(changeModel)
    {
        char model[PLATFORM_MAX_PATH];
        GetPartModelString(view_as<PartRank>(GetPartPropInfo(prop, Info_Rank)), model, sizeof(model));

        SetEntityModel(prop, model);
    }

    if(IsFake)
    {
        CreateTimer(2.0, FakePickup, EntIndexToEntRef(prop));
        SDKHook(prop, SDKHook_SetTransmit, FakePropTransmit);

    }
    else
    {
        CreateTimer(0.05, OnPickup, EntIndexToEntRef(prop));
    }
    DispatchSpawn(prop);
}

bool CanUsePartBoss(int partIndex)
{
    if(IsValidPart(partIndex))
    {
        return KvGetNum(PartKV, "able_to_boss", 0) > 0;
    }
    return false;
}

bool CanUseSystemBoss()
{
    Handle clonedHandle = CloneHandle(PartKV);
    KvRewind(clonedHandle);
    char key[20];

    do
    {
        KvGetSectionName(clonedHandle, key, sizeof(key));
        if(!StrContains(key, "part"))
        {
            ReplaceString(key, sizeof(key), "part", "");
            if(IsValidPart(StringToInt(key)))
            {
                if(KvGetNum(PartKV, "able_to_boss", 0) > 0)
                    return true;
            }
        }
    }
    while(KvGotoNextKey(clonedHandle));
    return false;
}

bool CanUsePartClass(int partIndex, TFClassType class)
{
    char classnames[][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
    char classes[80];
    if(IsValidPart(partIndex))
    {
        KvGetString(PartKV, "able_to_class", classes, sizeof(classes));
        if(classes[0] == '\0')
            return true;

        else if(!StrContains(classes, classnames[view_as<int>(class)], false))
            return true;
    }
    return false;
}

bool CanUseSystemClass(TFClassType class)
{
    char classnames[][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
    char classes[80];
    char key[20];

    Handle clonedHandle = CloneHandle(PartKV);
    KvRewind(clonedHandle);

    do
    {
        KvGetSectionName(clonedHandle, key, sizeof(key));
        if(!StrContains(key, "part"))
        {
            ReplaceString(key, sizeof(key), "part", "");
            if(IsValidPart(StringToInt(key)))
            {
                KvGetString(PartKV, "able_to_class", classes, sizeof(classes));
                if(classes[0] == '\0')
                    return true;

                else if(!StrContains(classes, classnames[view_as<int>(class)]))
                    return true;
            }
        }
    }
    while(KvGotoNextKey(clonedHandle));
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
    return IsValidPart(GetNativeCell(1));
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

public Native_RandomPartRank(Handle plugin, int numParams)
{
    return _:RandomPartRank(GetNativeCell(1));
}

public Action Forward_OnTouchedPartProp(int client, int prop)
{
    Action action;
    Call_StartForward(OnTouchedPartProp);
    Call_PushCell(client);
    Call_PushCell(prop);
    Call_Finish(action);

    return action;
}

void Forward_OnTouchedPartProp_Post(int client, int prop)
{
    Call_StartForward(OnTouchedPartPropPost);
    Call_PushCell(client);
    Call_PushCell(prop);
    Call_Finish();
}

public Action Forward_OnGetPart(int client, int prop, int partIndex)
{
    Action action;
    Call_StartForward(OnGetPart);
    Call_PushCell(client);
    Call_PushCell(prop);
    Call_PushCell(partIndex);
    Call_Finish(action);

    return action;
}

void Forward_OnGetPart_Post(int client, int partIndex)
{
    Call_StartForward(OnGetPartPost);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_Finish();
}

public Action Forward_OnSlotClear(int client, int partIndex, bool gotoNextRound)
{
    Action action;
    Call_StartForward(OnSlotClear);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_PushCell(gotoNextRound);
    Call_Finish(action);

    return action;
}

public Action Forward_PreActivePart(int client, int partIndex)
{
    Action action;
    Call_StartForward(PreActivePart);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_Finish(action);

    return action;
}

public void Forward_OnActivedPart(int client, int partIndex)
{
    Call_StartForward(OnActivedPart);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_Finish();
}

public void Forward_OnActivedPartEnd(int client, int partIndex)
{
    Call_StartForward(OnActivedPartEnd);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_Finish();
}

public void Forward_OnClientCooldownEnd(int client)
{
    Call_StartForward(OnClientCooldownEnd);
    Call_PushCell(client);
    Call_Finish();
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
}

void CheckPartConfigFile()
{
  if(PartKV != INVALID_HANDLE)
  {
    CloseHandle(PartKV);
    PartKV = INVALID_HANDLE;
  }

  char config[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, config, sizeof(config), "configs/custompart.cfg");
  enabled = false;

  if(!FileExists(config))
  {
      SetFailState("[CP] NO CFG FILE! (configs/custompart.cfg)");
      return;
  }

  PartKV = CreateKeyValues("CustomPart");

  if(!FileToKeyValues(PartKV, config))
  {
    SetFailState("[CP] configs/custompart.cfg is broken?!");
  }

  // MaxEnablePartCount = 0;
  KvRewind(PartKV);
  if(KvJumpToKey(PartKV, "setting"))
  {
      MaxPartGlobalSlot = KvGetNum(PartKV, "able_slot", 1);

      char key[PLATFORM_MAX_PATH];
      char path[PLATFORM_MAX_PATH];
      // char downloadPath[PLATFORM_MAX_PATH];
      char modelExtensions[][]={".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
      char matExtensions[][]={".vmt", ".vtf"};
      char rankExtensions[][]={"base", "normal", "rare", "hero", "legend", "another"};
      // char modelMat[][]={"model", "mat"};

      for(int count=0; count < sizeof(rankExtensions); count++)
      {
          Format(key, sizeof(key), "part_%s_model", rankExtensions[count]);

          for(int i=0; i<sizeof(modelExtensions); i++)
          {
              KvGetString(PartKV, key, path, sizeof(path));
              Format(path, sizeof(path), "%s%s", path, modelExtensions[i]);
              if(FileExists(path, true))
              {
                  AddFileToDownloadsTable(path);
                  PrecacheModel(path);
              }
          }

          Format(key, sizeof(key), "part_%s_mat", rankExtensions[count]);

          for(int i=0; i<sizeof(matExtensions); i++)
          {
              KvGetString(PartKV, key, path, sizeof(path));
              Format(path, sizeof(path), "%s%s", path, matExtensions[i]);
              if(FileExists(path, true))
              {
                  AddFileToDownloadsTable(path);
              }
          }

      }
      enabled = true;
  }

  if(enabled)
  {
      for(int client = 1; client <= MaxClients; client++)
      {
          if(IsClientInGame(client) && ActivedPartSlotArray[client] == INVALID_HANDLE)
          {
              RefrashPartSlotArray(client);
          }
      }
  }
}

public void GetPartRankColor(PartRank rank, int colors[4])
{
    switch(rank)
    {
      case Rank_Rare:
      {
          colors[0] = 0;
          colors[1] = 84;
          colors[2] = 255;
      }
      case Rank_Hero:
      {
          colors[0] = 131;
          colors[1] = 36;
          colors[2] = 255;
      }
      case Rank_Legend:
      {
          colors[0] = 255;
          colors[1] = 187;
          colors[2] = 0;
      }
      case Rank_Another:
      {
          colors[0] = 34;
          colors[1] = 116;
          colors[2] = 28;
      }
      default:
      {
          colors[0] = 255;
          colors[1] = 255;
          colors[2] = 255;
      }
    }
    colors[3] = 255;
}

public void GetPartModelString(PartRank partRank, char[] model, int bufferLength)
{
    KvRewind(PartKV);
    if(KvJumpToKey(PartKV, "setting"))
    {
        int rank = view_as<int>(partRank);
        char path[PLATFORM_MAX_PATH];
        char rankExtensions[][]={"normal", "rare", "hero", "legend", "another"};

        Format(path, sizeof(path), "part_%s_model", rankExtensions[rank]);
        KvGetString(PartKV, path, path, sizeof(path));

        Format(model, bufferLength, "%s.mdl", path);
    }
}

public Action PrecacheTimer(Handle timer)
{
	PrecacheThings();
}

void PrecacheThings()
{
	PropForTeam = view_as<TFTeam>(GetConVarInt(cvarPropForNoBossTeam));
}

stock bool IsValidClient(client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
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

void KickEntity(int client, int entity)
{
	float clientEyeAngles[3];
	float vecrt[3];
	float angVector[3];

	GetClientEyeAngles(client, clientEyeAngles);
	GetAngleVectors(clientEyeAngles, angVector, vecrt, NULL_VECTOR);
	NormalizeVector(angVector, angVector);

	angVector[0] *= 1200.0;
	angVector[1] *= 1200.0;
	angVector[2] *= 1200.0;

	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, angVector);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
	// SDKHook(entity, SDKHook_PreThinkPost, OnStuckTest);
	// CreateTimer(0.02, OnStuckTest, entity);
}

int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
		default:
		{
			return 2;
		}
	}
	return -1;  //Compiler bug-doesn't recognize 'default' as a valid catch-all
}

stock int TF2_CreateGlow(int iEnt)
{
	char strName[126], strClass[64];
	GetEntityClassname(iEnt, strClass, sizeof(strClass));
	Format(strName, sizeof(strName), "%s%i", strClass, iEnt);
	DispatchKeyValue(iEnt, "targetname", strName);

	char strGlowColor[18];
	Format(strGlowColor, sizeof(strGlowColor), "%i %i %i %i", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(180, 255));

	int ent = CreateEntityByName("tf_glow");
	DispatchKeyValue(ent, "targetname", "RainbowGlow");
	DispatchKeyValue(ent, "target", strName);
	DispatchKeyValue(ent, "Mode", "0");
	DispatchKeyValue(ent, "GlowColor", strGlowColor);
	DispatchSpawn(ent);

	AcceptEntityInput(ent, "Enable");

	return ent;
}

stock int TF2_HasGlow(int owner, int iEnt)
{
	int index = -1;
	while ((index = FindEntityByClassname(index, "tf_glow")) != -1)
	{
		if (GetEntPropEnt(index, Prop_Send, "m_hTarget") == iEnt
        && GetEntPropEnt(index, Prop_Send, "m_hOwnerEntity") == owner)
		{
			return index;
		}
	}

	return -1;
}

stock void TF2_SetGlowColor(int ent, const int colors[4])
{
    AcceptEntityInput(ent, "Disable");

    char strGlowColor[18];
	Format(strGlowColor, sizeof(strGlowColor), "%i %i %i %i", colors[0], colors[1], colors[2], colors[3]);

    DispatchKeyValue(ent, "GlowColor", strGlowColor);
    AcceptEntityInput(ent, "Enable");
}


stock bool CheckCollision(float cylinderOrigin[3], float colliderOrigin[3], float maxDistance)// (float cylinderOrigin[3], float colliderOrigin[3], float maxDistance, float zMin, float zMax)
{
/*
	if (colliderOrigin[2] < zMin || colliderOrigin[2] > zMax)
		return false;
*/
	return GetVectorDistance(cylinderOrigin, colliderOrigin) <= maxDistance;
}

stock bool IsBoss(int client)
{
    return FF2_GetBossIndex(client) != -1;
}
