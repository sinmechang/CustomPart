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
#include <freak_fortress_2>

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

#define INVALID_PARTID -1

enum PartRank
{
    Rank_Normal=0,
    Rank_Rare,
    Rank_Hero,
    Rank_Legend,
    Rank_Another
};

enum PartInfo
{
    Info_EntId=0,
    Info_Rank,
    Info_CustomInfo
};

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

Handle PartKV;
Handle cvarChatCommand;

int g_iChatCommand=0;

int MaxPartGlobalSlot=1;

bool enabled;

TFTeam PropForTeam;

Handle cvarPropCount;
Handle cvarPropVelocity;
Handle cvarPropForNoBossTeam;
Handle cvarPropSize;

int ActivedPartCount[MAXPLAYERS+1];
int MaxPartSlot[MAXPLAYERS+1];
ArrayList ActivedPartSlotArray[MAXPLAYERS+1];

public void OnPluginStart()
{
  cvarChatCommand = CreateConVar("cp_chatcommand", "파츠,part,스킬");

  cvarPropCount = CreateConVar("cp_prop_count", "1", "생성되는 프롭 갯수, 0은 생성을 안함", _, true, 0.0);
  cvarPropVelocity = CreateConVar("cp_prop_velocity", "250.0", "프롭 생성시 흩어지는 최대 속도, 설정한 범위 내로 랜덤으로 속도가 정해집니다.", _, true, 0.0);
  cvarPropForNoBossTeam = CreateConVar("cp_prop_for_team", "2", "0 혹은 1은 제한 없음, 2는 레드팀에게만, 3은 블루팀에게만. (생성도 포함됨.)", _, true, 0.0, true, 2.0);
  cvarPropSize = CreateConVar("cp_prop_size", "50.0", "캡슐 섭취 범위", _, true, 0.1);

  AddCommandListener(Listener_Say, "say");
  AddCommandListener(Listener_Say, "say_team");

  CheckPartConfigFile();

  LoadTranslations("custompart");
  LoadTranslations("common.phrases");
  LoadTranslations("core.phrases");

  HookEvent("player_spawn", OnPlayerSpawn);
  HookEvent("player_death", OnPlayerDeath);

  for(int client = 1;  client < MaxClients; client++)
  {
    ActivedPartSlotArray[client] = ArrayList();
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

public void OnClientPutInServer(int client)
{

}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    MaxPartSlot[client] = MaxPartGlobalSlot;
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
}

int SpawnCustomPart(PartRank partRank, float position[3], float velocity[3], bool IsFake)
{
    int prop = CreateEntityByName("prop_physics_override");
    if(IsValidEntity(prop))
    {
        char modelPath[PLATFORM_MAX_PATH];
        char partAccount[128];
        int colors[4];

        GetPartModelString(partRank, modelPath);
        Format(partAccount, sizeof(partAccount), "partEntId=%i?partRank=%i?settingPartIndex=0", prop);

        SetEntityModel(prop, modelPath);
        SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
        SetEntProp(prop, Prop_Send, "m_CollisionGroup", 2);
        SetEntPropString(prop, Prop_Send, "m_iName", partAccount);
        // SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16); // 0x0004
        SetEntProp(prop, Prop_Send, "m_usSolidFlags", 0x0004);
        DispatchSpawn(prop);

        GetPartRankColor(partRank, colors);
        TF2_SetGlowColor(TF2_CreateGlow(prop), colors);

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
		if((IsCorrectTeam(client) && CanUseSystemClass(TF2_GetPlayerClass(client)))
        || (IsBoss(client) && CanUseSystemBoss(client) && view_as<PartRank>(GetPartPropInfo(entity, Info_Rank)) == Rank_Another)
        )
		{
			char centerMessage[100];
			PrintCenterText(client, "파츠를 흭득하셨습니다!");

            int part = RandomPart(client, GetPartPropInfo(entity, Info_Rank));
            SetPlayerPartSlot(client, FindActiveSlots(client), part);

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

public Action Listener_Say(int client, const char[] command, int argc)
{
    /*
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

			ViewPartMenu(client);
			return Plugin_Handled;
		}
	}
    */

	return Plugin_Continue;

}

void ViewPartMenu(int client)
{

}

int RandomPart(int client, PartRank rank)
{
    int[] parts;
    int count = 0;
    int part;

    char key[20];
    bool isBoss = IsBoss(client);
    TFClassType class = TF2_GetPlayerClass(client);

    Handle clonedHandle = CloneHandle(PartKV);
    KvRewind(clonedHandle);

    do
    {
        KvGetSectionName(clonedHandle, key, sizeof(key));
        if(!StrContains(key, "part"))
        {
            ReplaceString(key, sizeof(key), "part", "");
            if(IsValidPart((part = StringToInt(key))))
            {
                if((isBoss && CanUsePartBoss(part))
                || (!isBoss && CanUsePartClass(part, class))
                )
                {
                    parts[count++] = part;
                }
            }
        }
    }
    while(KvGotoNextKey(clonedHandle));

    return parts[GetRandomInt(0, count-1)];
}

PropRank RandomPartRank()
{
    int ranklist[4];
    ranklist[0] = 45;
    ranklist[1] = 30;
    ranklist[2] = 20;
    ranklist[3] = 10;

    int total = ranklist[0] + ranklist[1] + ranklist[2] + ranklist[3];
    total -= GetRandomInt(0, total);

    PropRank rank;

    for(int count; count<sizeof(count); count++)
    {
        total -= ranklist[count];

        if(total <= 0)
        {
            if(count == 0)  rank = Rank_Normal;
            else if(count == 1) rank = Rank_Rare;
            else if(count == 2) rank = Rank_Hero;
            else if(count == 3) rank = Rank_Legend;
        }
    }

    return rank;
}

int FindActiveSlots(int client)
{
    for(int i = 0;  i < MaxPartSlot[client]; i++)
    {
        if(ActivedPartSlotArray[client].Get(slot) == 0)
            return i;
    }
    return 0;
}

int GetPlayerPartslot(int client, int slot)
{
    return ActivedPartSlotArray[client].Get(slot);
}

void SetPlayerPartSlot(int client, int slot, int value, bool reset)
{

    ActivedPartSlotArray[client].Set(slot, value);
    if(reset)
    {
        ActivedPartSlotArray[client].Clear();
    }
    ActivedPartSlotArray[client].Resize(MaxPartSlot[client]);
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

PropRank GetPartRank(int partIndex)
{
    if(IsValidPart(partIndex))
    {
        return view_as<PropRank>(KvGetNum(PartKV, "rank"));
    }

    return Rank_Normal;
}

int GetPartPropInfo(int prop, PartInfo partinfo)
{
    int find = view_as<int>(partinfo);

    char propName[150];
    char partIndexString[3][50];
    char temp[2][32];

    GetEntPropString(prop, Prop_Send, "m_iName", propName, sizeof(propName));

    ExplodeString(propName, "?", partIndexString, sizeof(partIndexString), sizeof(partIndexString[]));
    ExplodeString(partIndexString[find], "=", temp, sizeof(temp), sizeof(temp[]));

    return StringToInt(temp[1]);
}

void SetPartPropInfo(int prop, PartInfo partinfo, int value, bool changeModel = false)
{
    int find = view_as<int>(partinfo);

    char propName[150];
    char partIndexString[3][50];
    char temp[2][50];

    GetEntPropString(prop, Prop_Send, "m_iName", propName, sizeof(propName));

    ExplodeString(propName, "?", partIndexString, sizeof(partIndexString), sizeof(partIndexString[]));
    ExplodeString(partIndexString[find], "=", temp, sizeof(temp), sizeof(temp[]));

    Format(temp[1], sizeof(temp[]), "%i", value);
    StrCat(temp[0], sizeof(temp[]), temp[1]);
    strcopy(partIndexString[find], sizeof(partIndexString), temp[0]);
    ImplodeStrings(partIndexString, sizeof(partIndexString), "?", propName, sizeof(propName));

    SetEntPropString(prop, Prop_Send, "m_iName", propName);

    if(changeModel)
    {
        char model[PLATFORM_MAX_PATH];
        GetPartModelString(view_as<PropRank>(GetPartPropInfo(prop, Info_Rank)), model);

        SetEntityModel(prop, model);
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

void CheckPartConfigFile()
{
  if(PartKV != INVALID_HANDLE)
  {
    CloseHandle(PartKV);
    PartKV = INVALID_HANDLE;
  }

  char config[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, config, sizeof(config), "configs/custompart.cfg");

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
      char rankExtensions[][]={"normal", "rare", "hero", "legend", "another"};
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

public void GetPartModelString(PartRank partRank, char[] model)
{
    KvRewind(PartKV);
    if(KvJumpToKey(PartKV, "setting"))
    {
        int rank = view_as<int>(partRank);
        char path[PLATFORM_MAX_PATH];
        char rankExtensions[][]={"normal", "rare", "hero", "legend", "another"};

        Format(path, sizeof(path), "part_%s_model", rankExtensions[rank]);
        KvGetString(PartKV, path, path, sizeof(path));

        Format(model, sizeof(model), "%s.mdl", path);
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

stock int TF2_CreateGlow(int iEnt, char strGlowColor[18])
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

stock void TF2_SetGlowColor(int ent, int colors[4])
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
