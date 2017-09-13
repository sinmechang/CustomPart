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
#define PLUGIN_VERSION "2.0 : Dev"

#define MAX_ENTITY_COUNT 2048

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

/*
ArrayList GlobalPartPropIndex;
ArrayList GlobalPartPropRank;
ArrayList GlobalPartPropParent;
*/
ArrayList AlivePartPropInfo;

KeyValues GlobalPartKV;
KeyValues GlobalPartDataKV;
// ArrayList ActivedPartSlotArray[MAXPLAYERS+1];
// ArrayList ActivedDurationArray[MAXPLAYERS+1];
/*
ConVar cvarPropCount;
ConVar cvarPropVelocity;
ConVar cvarPropForNoBossTeam;
*/
ConVar cvarPropSize;
ConVar cvarPropCooltime;

bool enabled = true;

int MaxPartGlobalSlot;
float PartGetCoolTime[MAXPLAYERS+1];

// TODO: Freak Fortress 2와 호환이 가능하게 설계해야함.
/*
    보스가 파츠를 주울 수 있는 지의 여부 파악
*/
// TODO: 커스텀파츠 커스텀마이즈
/*
    등록된 파츠의 모든 값을 확인할 수 있도록 변경

    아이템 능력치 적용을 메인 플러그인에서 해결할 것.
    ㄴ 각 아이템의 기본 능력치 값을 따내야 함
*/
// TODO: 파츠의 흭득 로직
/*
    파츠의 흭득 로직은 프레임 간격으로 확인, 등록한 사이즈 범위 내에 있고 파츠가 시야에 보여야 주울 수 있도록 변경.

    예전과는 다르게, 팀 제한을 삭제시킬 것.
    파츠의
*/
// TODO: 유저 슬릇 초기화 문제
/*
    유저 파츠의 초기화 시점
        - 유저 스폰 시
        - 유저 사망 시
        - 유저가 서버에서 퇴장 시


*/
// TODO: 파츠가 근처에 있는 사람에게는 메세지 허드로 무슨 파츠인지 보여줘야함.
// TODO: MethodMap을 사용을 할까?
/*
    MethodMap

        - CustomPartProp
            - propIndex
            - partIndex
            - parentIndex
*/

/*
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{

}
*/

public void OnPluginStart()
{
    cvarPropSize = CreateConVar("cp_prop_size", "50.0", "캡슐 섭취 범위", _, true, 0.1);
    cvarPropCooltime = CreateConVar("cp_prop_cooltime", "1.0", "캡슐 섭취 쿨타임.", _, true, 0.1);

    HookEvent("player_death", OnPlayerDeath);

    if(GlobalPartProp == INVALID_HANDLE)
    {
        GlobalPartProp = new ArrayList();
        GlobalPartProp.Resize(150); // 맵상의 파츠 갯수만큼
    }

    if(GlobalPartPropRank == INVALID_HANDLE)
    {
        GlobalPartProp = new ArrayList();
        GlobalPartProp.Resize(150);
    }

    if(GlobalPartPropParent == INVALID_HANDLE)
    {
        GlobalPartPropParent = new ArrayList();
        GlobalPartPropParent.Resize(150);
    }

    for(int client=1; client<=MaxClients; client++)
    {
        if(ActivedPartSlotArray[client] == INVALID_HANDLE)
        {
            ActivedPartSlotArray[client] = new ArrayList();
            ActivedPartSlotArray[client].Resize(50);
        }

        if(ActivedDurationArray[client] == INVALID_HANDLE)
        {
            ActivedDurationArray[client] = new ArrayList();
            ActivedDurationArray[client].Resize(50);
        }
    }
}

public void OnMapStart()
{
    CheckPartConfigFile();
    CheckPartDataFile();
}

public void OnClientPostAdminCheck(int client)
{
    if(ActivedPartSlotArray[client] != INVALID_HANDLE)
    {

    }
}

public void OnGameFrame()
{
    if() // 파츠 흭득 여부
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
        // NormalizeVector(velocity, velocity);

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

        if((IsCorrectTeam(client)
        || (IsBoss(client) && CanUseSystemBoss() && rank == Rank_Another))
        )
		{
            part = GetPartPropInfo(entity, Info_CustomIndex);
            if(!IsValidPart(part))
                part = RandomPart(client, rank);

            slot = FindActiveSlot(client);
            tempPart = part;
            // Debug("확정된 파츠: %i, slot = %i, rank = %i", part, slot, view_as<int>(rank));

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
            PartGetCoolTime[client] = GetGameTime() + GetConVarFloat(cvarPropCooltime);
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

void CheckPartConfigFile()
{
    // 기본 파츠 모델 캐시 및 다운로드 테이블 등록
    // 유저 공용 파츠 슬릇을 구함
    // "configs/custompart.cfg"에서 "setting"가 없을 경우, 플러그인이 비활성화됩니다.
    if(GlobalPartKV != INVALID_HANDLE)
    {
        GlobalPartKV.Close();
        GlobalPartKV = INVALID_HANDLE;
    }

    char config[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, config, sizeof(config), "configs/custompart.cfg");
    enabled = false;

    if(!FileExists(config))
    {
        SetFailState("[CP] NO CFG FILE! (configs/custompart.cfg)");
        return;
    }

    GlobalPartKV = new KeyValues("CustomPart");

    if(!GlobalPartKV.ImportFromFile(config))
    {
        SetFailState("[CP] configs/custompart.cfg is broken?!");
    }

    GlobalPartKV.Rewind();
    if(GlobalPartKV.JumpToKey("setting"))
    {
        MaxPartGlobalSlot = GlobalPartKV.GetNum("able_slot", 1);

        char key[PLATFORM_MAX_PATH];
        char path[PLATFORM_MAX_PATH];
        char modelExtensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
        char matExtensions[][] = {".vmt", ".vtf"};
        char rankExtensions[][] = {"base", "normal", "rare", "hero", "legend", "another"};

        for(int count=0; count < sizeof(rankExtensions); count++)
        {
            Format(key, sizeof(key), "part_%s_model", rankExtensions[count]);

            for(int i=0; i<sizeof(modelExtensions); i++)
            {
                GlobalPartKV.GetString(key, path, sizeof(path));
                Format(path, sizeof(path), "%s%s", path, modelExtensions[i]);
                if(modelExtensions[i][0] ! '\0' && FileExists(path, true))
                {
                    AddFileToDownloadsTable(path);
                    PrecacheModel(path);
                }
            }

            Format(key, sizeof(key), "part_%s_mat", rankExtensions[count]);

            for(int i=0; i<sizeof(matExtensions); i++)
            {
                GlobalPartKV.GetString(key, path, sizeof(path));
                Format(path, sizeof(path), "%s%s", path, matExtensions[i]);
                if(matExtensions[i][0] != '\0' && FileExists(path, true))
                {
                    AddFileToDownloadsTable(path);
                }
            }

        }
        enabled = true;
    }

    /*
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
    */
}

void CheckPartDataFile()
{
    // 파츠의 데이터를 GlobalPartDataKV에 불러옵니다.
    // 특정 파츠의 모델, 텍스쳐를 캐시 및 다운로드 테이블에 등록합니다.
    //

    if(GlobalPartDataKV != INVALID_HANDLE)
    {
        GlobalPartDataKV.Close();
        GlobalPartDataKV = INVALID_HANDLE;
    }

    char config[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, config, sizeof(config), "configs/custompart_data.cfg");

    if(!FileExists(config))
    {
        SetFailState("[CP] NO CFG FILE! (configs/custompart_data.cfg)");
        return;
    }

    GlobalPartDataKV = new KeyValues("CustomPartData");

    if(!GlobalPartDataKV.ImportFromFile(config))
    {
        SetFailState("[CP] configs/custompart_data.cfg is broken?!");
    }

    GlobalPartDataKV.Rewind();

    int partCount = GetValidPartCount(Rank_None);
    int[] partArray = new int[partCount];
    GetValidPartArray(Rank_None, partArray, partCount);

    for(int loop=0; loop<partCount; loop++)
    {
        char temp[12];
        char path[PLATFORM_MAX_PATH];
        char tempPath[PLATFORM_MAX_PATH];
        char modelExtensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};

        Format(temp, sizeof(temp), "part%i", partArray[loop]);

        if(!GlobalPartDataKV.JumpToKey(temp))
            continue;

        GlobalPartDataKV.GetString("part_model", tempPath, sizeof(tempPath));
        for(int i=0; i<sizeof(modelExtensions); i++)
        {
            Format(path, sizeof(path), "%s%s", tempPath, modelExtensions[i]);

            if(!FileExists(path, true))     continue;

            if(i == 0)
                PrecacheModel(path);
            AddFileToDownloadsTable(path);
        }

        if(!GlobalPartDataKV.JumpToKey("part_mat"))
        {
            LogMessage("''%s'' NOT HAVE part_mat", temp);
            continue;
        }

        char matExtensions[][]={".vmt", ".vtf"};

        for(int i=0; i<sizeof(matExtensions); i++)
        {
            Format(path, sizeof(path), "%s%s", tempPath, matExtensions[i]);

            if(!FileExists(path, true))     continue;

            AddFileToDownloadsTable(path);
        }
    }

}

public void GetPartModelString(int partIndex = 0, PartRank partRank, char[] model, int bufferLength)
{
    // TODO: partIndex의 관계를 확실히 할 것
    if(partIndex <= 0)
    {
        KeyValues kv = new KeyValues("CustomPart");

        kv.Import(GlobalPartKV);
        kv.Rewind();

        if(KvJumpToKey(GlobalPartKV, "setting"))
        {
            int rank = view_as<int>(partRank);
            char path[PLATFORM_MAX_PATH];
            char rankExtensions[][]={"normal", "rare", "hero", "legend", "another"};

            Format(path, sizeof(path), "part_%s_model", rankExtensions[rank]);
            kv.GetString(path, path, sizeof(path));

            Format(model, bufferLength, "%s.mdl", path);
        }
    }
    else // 파츠 커스텀 모델
    {
        KeyValues kv = new KeyValues("CustomPartData");

        kv.Import(GlobalPartDataKV);
        kv.Rewind();
    }



    // 해당 파츠
}

int GetValidPartCount(PartRank rank = Rank_None)
{
    int count;
    int part;
    int integerRank = view_as<int>(rank);

    KeyValues clonedkv = new KeyValues("CustomPartData");
    clonedkv.Import(GlobalPartDataKV);
    clonedkv.Rewind();

    char key[20];

    if(clonedkv.GotoFirstSubKey())
    {
        do
        {
            clonedkv.GetSectionName(key, sizeof(key));
            if(!StrContains(key, "part"))
            {
                ReplaceString(key, sizeof(key), "part", "");
                if(IsValidPart((part = StringToInt(key))))
                {
                    if(part <= 0) continue;

                    if(rank == Rank_None || clonedkv.GetNum("rank") == integerRank)
                        count++;
                }
            }
        }
        while(clonedkv.GotoNextKey());
    }

    delete clonedkv;

    return count;
}

public void GetValidPartArray(PartRank rank, int[] parts, int size)
{
    int count;
    int part;
    int integerRank = view_as<int>(rank);

    KeyValues clonedkv = new KeyValues("CustomPartData");
    clonedkv.Import(GlobalPartDataKV);
    clonedkv.Rewind();

    char key[20];

    if(clonedkv.GotoFirstSubKey())
    {
        do
        {
            clonedkv.GetSectionName(key, sizeof(key));
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

    delete clonedkv;
}

public void GetPartRankColor(PartRank rank, int colors[4])
{
    switch(rank)
    {
        case Rank_None:
        {
            colors[0] = 166;
            colors[1] = 166;
            colors[2] = 166;
        }
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

stock int CheckRoundState()
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
		case RoundState_RoundRunning, RoundState_Stalemate:
		{
			return 1;
		}
		default:
		{
			return 2;
		}
	}
	return -1;
}
