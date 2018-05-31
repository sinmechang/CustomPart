#define	MAX_EDICT_BITS	12
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

#define INVALID_PARTID -1

Handle PartKV;
Handle CPHud;
Handle CPChargeHud;
Handle cvarChatCommand;

int g_iChatCommand = 0;
char g_strChatCommand[42][50];

int MaxPartGlobalSlot = 1;

bool enabled;

TFTeam PropForTeam;

Handle cvarPropCount;
Handle cvarPropVelocity;
Handle cvarPropForNoBossTeam;
Handle cvarPropSize;
Handle cvarPropCooltime;

int CPFlags[MAXPLAYERS+1];

int MaxPartSlot[MAXPLAYERS+1];
int LastSelectedSlot[MAXPLAYERS+1];
PartRank SelectedBookRank[MAXPLAYERS+1];

ArrayList ActivedPartSlotArray[MAXPLAYERS+1];
ArrayList ActivedDurationArray[MAXPLAYERS+1];

float PartCharge[MAXPLAYERS+1];
float PartMaxChargeDamage[MAXPLAYERS+1];
float PartCooldown[MAXPLAYERS+1];
float PartGetCoolTime[MAXPLAYERS+1];

CPClient g_hClientInfo[MAXPLAYERS+1];

// TODO: 최적화
PartRank PartPropRank[MAX_EDICTS+1];
int PartPropCustomIndex[MAX_EDICTS+1];

int AllPartPropCount;

methodmap CPConfigKeyValues < KeyValues {
	public CPConfigKeyValues()
    {
        CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));

        char config[PLATFORM_MAX_PATH];
        BuildPath(Path_SM, config, sizeof(config), "configs/custompart.cfg");

        if(!kv.ImportFromFile(config))
        {
            SetFailState("[CP] configs/custompart.cfg is broken?!");
            return null;
        }

        kv.Rewind();

        return kv;
    }
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

          for(int i = 0; i < sizeof(matExtensions); i++)
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
