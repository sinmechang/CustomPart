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

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

Handle PartKV;
Handle cvarChatCommand;

Handle OnTouchedPartProp;
Handle OnTouchedPartPropPost;
Handle OnGetPart;
Handle OnGetPartPost;

int g_iChatCommand=0;
char g_strChatCommand[42][50];

int MaxPartGlobalSlot=1;

bool enabled;

TFTeam PropForTeam;

Handle cvarPropCount;
Handle cvarPropVelocity;
Handle cvarPropForNoBossTeam;
Handle cvarPropSize;

// int ActivedPartCount[MAXPLAYERS+1];
int MaxPartSlot[MAXPLAYERS+1];
int LastSelectedSlot[MAXPLAYERS+1];
ArrayList ActivedPartSlotArray[MAXPLAYERS+1];
// ArrayList PartSlotCoolTimeArray[MAXPLAYERS+1];


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

    OnTouchedPartProp = CreateGlobalForward("CP_OnTouchedPartProp", ET_Hook, Param_Cell, Param_Cell);
    OnTouchedPartPropPost = CreateGlobalForward("CP_OnTouchedPartProp_Post", ET_Hook, Param_Cell, Param_Cell);
    OnGetPart = CreateGlobalForward("CP_OnGetPart", ET_Hook, Param_Cell, Param_Cell);
    OnGetPartPost = CreateGlobalForward("CP_OnGetPart_Post", ET_Hook, Param_Cell, Param_Cell);

	return APLRes_Success;
}

public void OnPluginStart()
{
  cvarChatCommand = CreateConVar("cp_chatcommand", "파츠,part,스킬");

  cvarPropCount = CreateConVar("cp_prop_count", "1", "생성되는 프롭 갯수, 0은 생성을 안함", _, true, 0.0);
  cvarPropVelocity = CreateConVar("cp_prop_velocity", "250.0", "프롭 생성시 흩어지는 최대 속도, 설정한 범위 내로 랜덤으로 속도가 정해집니다.", _, true, 0.0);
  cvarPropForNoBossTeam = CreateConVar("cp_prop_for_team", "2", "0 혹은 1은 제한 없음, 2는 레드팀에게만, 3은 블루팀에게만. (생성도 포함됨.)", _, true, 0.0, true, 2.0);
  cvarPropSize = CreateConVar("cp_prop_size", "50.0", "캡슐 섭취 범위", _, true, 0.1);

  RegConsoleCmd("slot", TestSlot);

  AddCommandListener(Listener_Say, "say");
  AddCommandListener(Listener_Say, "say_team");

  LoadTranslations("custompart");
  LoadTranslations("common.phrases");
  LoadTranslations("core.phrases");

  HookEvent("player_spawn", OnPlayerSpawn);
  HookEvent("player_death", OnPlayerDeath);

  // HookEvent("teamplay_round_start", OnRoundStart);
  // HookEvent("teamplay_round_win", OnRoundEnd);

  // RegPluginLibrary("custompart");
  for(int client=1; client<=MaxClients; client++)
  {
      ActivedPartSlotArray[client] = new ArrayList();
      ActivedPartSlotArray[client].Resize(50);
  }
}
/*
public Action OnRoundStart(Handle event, const char[] name, bool dont)
{


}

public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{

}
*/
public Action TestSlot(int client, int args)
{
    RefrashPartSlotArray(client, true);
    CPrintToChatAll("%N's slot. size = %i, MaxPartSlot = %i", client, ActivedPartSlotArray[client].Length, MaxPartSlot[client]);

    for(int count = 0; count < MaxPartSlot[client]; count++)
    {
        CPrintToChatAll("[%i] %i", count, ActivedPartSlotArray[client].Get(count));
    }
}

public void OnMapStart()
{
	ChangeChatCommand();
    CheckPartConfigFile();
    CreateTimer(0.2, PrecacheTimer);
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

public void OnClientDisconnect(int client)
{
    ActivedPartSlotArray[client].Clear();
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    if(enabled)
    {
        int client = GetClientOfUserId(GetEventInt(event, "userid"));

        MaxPartSlot[client] = MaxPartGlobalSlot;
        RefrashPartSlotArray(client);
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
        char partAccount[128];
        int colors[4];

        GetPartModelString(partRank, modelPath, sizeof(modelPath));
        Format(partAccount, sizeof(partAccount), "partEntId=%i?partRank=%i?settingPartIndex=0", prop, view_as<int>(partRank));

        Debug("생성된 파츠: %s", partAccount);

        SetEntityModel(prop, modelPath);
        SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
        SetEntProp(prop, Prop_Send, "m_CollisionGroup", 2);
        SetEntPropString(prop, Prop_Data, "m_iName", partAccount);
        // SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16); // 0x0004
        SetEntProp(prop, Prop_Send, "m_usSolidFlags", 0x0004);
        DispatchSpawn(prop);

        GetPartRankColor(partRank, colors);

        int glow = TF2_CreateGlow(prop);
        TF2_SetGlowColor(glow, colors);

        TeleportEntity(prop, position, NULL_VECTOR, velocity);
        // TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);

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
            RefrashPartSlotArray(client, true);
            part = GetPartPropInfo(entity, Info_CustomInfo);
            if(!IsValidPart(part))
                part = RandomPart(client, rank);

            slot = FindActiveSlots(client);

            Debug("확정된 파츠: %i, slot = %i, rank = %i", part, slot, view_as<int>(rank));

            if(part <= 0 || slot < 0) // 유효한 파츠이나 파츠 슬릇 체크
            {
                IgnoreAndKickIt(client, entity);
                return Plugin_Continue;
            }

            action = Forward_OnGetPart(tempClient, tempEntity);
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
            Forward_OnGetPart_Post(client, entity);

            SetClientPart(client, slot, part);
            ViewPart(client, slot);
            PrintCenterText(client, "파츠를 흭득하셨습니다!");

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
	char temp[2][64];
	GetCmdArgString(strChat, sizeof(strChat));

	int start;

	if(strChat[start] == '"') start++;
	if(strChat[start] == '!' || strChat[start] == '/') start++;
	strChat[strlen(strChat)-1] = '\0';
	ExplodeString(strChat[start], " ", temp, 2, 64, true);

	for (int i=0; i<=g_iChatCommand; i++)
	{
		if(StrEqual(temp[0], g_strChatCommand[i], true))
		{
			if(temp[1][0] != '\0')
			{
				return Plugin_Handled;
			}

			ViewPart(client);
			return Plugin_Handled;
		}
	}


	return Plugin_Continue;

}

void ViewPart(int client, int slot=0)
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
        Format(item, sizeof(item), "%s\n설명: %s", item, tempItem);
        // menu.AddItem("description", item, ITEMDRAW_DISABLED);

        GetPartString(part, "ability_description", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n능력 설명: %s", item, tempItem);
        // menu.AddItem("ability_description", item, ITEMDRAW_DISABLED);

        GetPartString(part, "idea_owner_nickname", tempItem, sizeof(tempItem));
        if(item[0] != '\0') Format(item, sizeof(item), "%s\n아이디어 제공: %s\n\n", item, tempItem);
        else Format(item, sizeof(item), "%s\nPOTRY SERVER ORIGINAL CUSTOMPART\n\n", item);
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
          switch(item)
          {
              case 0:
              {
                ViewPart(client, LastSelectedSlot[client]-1);
              }
              case 1:
              {
                ViewPart(client, LastSelectedSlot[client]+1);
              }
          }
      }
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
            // Debug("RandomPart: %s", key);
            if(!StrContains(key, "part"))
            {
                ReplaceString(key, sizeof(key), "part", "");
                // Debug("RandomPart: %s", key);
                if(IsValidPart((part = StringToInt(key))))
                {
                    // Debug("컨픽에서 %d 파츠를 발견함.", part);
                    if(part <= 0) continue;

                    if(((isBoss && CanUsePartBoss(part))
                    || (!isBoss && CanUsePartClass(part, class)))
                    && GetPartRank(part) == rank
                    && KvGetNum(clonedHandle, "not_able_in_random", 0) <= 0
                    )
                    {
                        count++;
                        parts.Push(part);
                        Debug("%d 파츠가 랜덤 리스트에 오름. rank = %i, 파츠랭크 = %i", part, view_as<int>(rank), view_as<int>(GetPartRank(part)));
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

    Debug("%d가 RandomPart에서 반환됨.", answer);
    return answer;
}

PartRank RandomPartRank()
{
    int ranklist[4];
    ranklist[0] = 45;
    ranklist[1] = 30;
    ranklist[2] = 20;
    ranklist[3] = 5;

    SetRandomSeed(GetTime());

    int total = ranklist[0] + ranklist[1] + ranklist[2] + ranklist[3];
    int winner = GetRandomInt(0, total);
    int tempcount;

    PartRank rank;

    for(int count; count < 4; count++)
    {
        tempcount += ranklist[count];

        if(tempcount >= winner)
        {
            if(count == 0)  rank = Rank_Normal;
            else if(count == 1) rank = Rank_Rare;
            else if(count == 2) rank = Rank_Hero;
            else if(count == 3) rank = Rank_Legend;

            break;
        }
    }

    return rank;
}

bool IsPartActived(int client, int partIndex)
{
    return ActivedPartSlotArray[client].FindValue(partIndex) != -1;
}

int FindActiveSlots(int client)
{
    for(int i = 0;  i < MaxPartSlot[client]; i++)
    {
        int value = ActivedPartSlotArray[client].Get(i);
        if(value <= 0 && !IsValidPart(value))
            return i;
    }
    return -1;
}

int GetClientPart(int client, int slot)
{
    if(IsValidSlot(client, slot))
        return ActivedPartSlotArray[client].Get(slot);

    return INVALID_PARTID;
}

void SetClientPart(int client, int slot, int value) // return: 적용된 슬릇 값.
{
    if(!IsValidSlot(client, slot)) return;

    ActivedPartSlotArray[client].Set(slot, value);
}

void RefrashPartSlotArray(int client, bool holdParts=false)
{
    int beforeSize = ActivedPartSlotArray[client].Length;
    int[] beforeCell = new int[beforeSize]

    for(int count=0; count<beforeSize; count++)
    {
        beforeCell[count] = ActivedPartSlotArray[client].Get(count);
    }

    ActivedPartSlotArray[client].Clear();
    ActivedPartSlotArray[client].Resize(MaxPartSlot[client]);

    for(int count=0; count<MaxPartSlot[client]; count++)
    {
        if(holdParts && IsValidPart(beforeCell[count])) ActivedPartSlotArray[client].Set(count, beforeCell[count]);
        else ActivedPartSlotArray[client].Set(count, 0);
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
    if(MaxPartSlot[client] > slot && slot >= 0)
        return true;

    return false;
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
    int find = view_as<int>(partinfo);

    char propName[150];
    char partIndexString[3][50];
    char temp[2][32];

    GetEntPropString(prop, Prop_Data, "m_iName", propName, sizeof(propName));
    Debug("%s", propName);
    ExplodeString(propName, "?", partIndexString, sizeof(partIndexString), sizeof(partIndexString[]));
    Debug("%s", partIndexString[find]);
    ExplodeString(partIndexString[find], "=", temp, sizeof(temp), sizeof(temp[]));
    Debug("%s | %s", temp[0], temp[1]);

    return StringToInt(temp[1]);
}

void SetPartPropInfo(int prop, PartInfo partinfo, int value, bool changeModel = false)
{
    int find = view_as<int>(partinfo);

    char propName[150];
    char partIndexString[3][50];
    char temp[2][50];

    GetEntPropString(prop, Prop_Data, "m_iName", propName, sizeof(propName));

    ExplodeString(propName, "?", partIndexString, sizeof(partIndexString), sizeof(partIndexString[]));
    ExplodeString(partIndexString[find], "=", temp, sizeof(temp), sizeof(temp[]));

    Format(temp[1], sizeof(temp[]), "%i", value);
    StrCat(temp[0], sizeof(temp[]), temp[1]);
    strcopy(partIndexString[find], sizeof(partIndexString), temp[0]);
    ImplodeStrings(partIndexString, sizeof(partIndexString), "?", propName, sizeof(propName));

    SetEntPropString(prop, Prop_Data, "m_iName", propName);

    if(changeModel)
    {
        char model[PLATFORM_MAX_PATH];
        GetPartModelString(view_as<PartRank>(GetPartPropInfo(prop, Info_Rank)), model, sizeof(model));

        SetEntityModel(prop, model);
    }
}

void PropToPartProp(int prop, int partIndex=0, PartRank rank=Rank_Normal, bool createLight, bool changeModel=false, bool IsFake=false)
{
    char partAccount[150];

    Format(partAccount, sizeof(partAccount), "partEntId=%i?partRank=%i?settingPartIndex=%i", prop, view_as<int>(rank));

    SetEntPropString(prop, Prop_Data, "m_iName", partAccount);

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

        else if(!StrContains(classes, classnames[view_as<int>(class)]))
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
    RefrashPartSlotArray(GetNativeCell(1), GetNativeCell(2));
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

public Action Forward_OnGetPart(int client, int part)
{
    Action action;
    Call_StartForward(OnGetPart);
    Call_PushCell(client);
    Call_PushCell(part);
    Call_Finish(action);

    return action;
}

void Forward_OnGetPart_Post(int client, int part)
{
    Call_StartForward(OnGetPartPost);
    Call_PushCell(client);
    Call_PushCell(part);
    Call_Finish();
}

int GetClientMaxSlot(int client)
{
    return MaxPartSlot[client];
}

void SetClientMaxSlot(int client, int maxSlot)
{
    MaxPartSlot[client] = maxSlot;
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
