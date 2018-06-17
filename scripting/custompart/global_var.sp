#define	MAX_EDICT_BITS	12
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

#define INVALID_PARTID -1

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

	public native int GetPartSymbol(const int partIndex);

	public native void ExportSelf(CPConfigKeyValues victimKv);

	public native CPPart LoadPart(const int partIndex);

	public native bool IsValidPart(const int partIndex);

	public native bool JumpToPart(const int partIndex);

	public native bool CanUsePartClass(const int partIndex, const TFClassType class);

	public native int GetValidPartCount(const PartRank rank = Rank_None);

	public native int RandomPart(const int client, PartRank rank);

	public native bool IsPartActive(const int partIndex);

	public native PartRank GetPartRank(const int partIndex);

	public native float GetActivePartDuration(const int partIndex);

	public native float GetActivePartCooldown(const int partIndex);

	public native float GetPartMaxChargeDamage(const int partIndex);

	public native bool IsCanUseWeaponPart(const int client, const int partIndex);

	public void GetValidPartArray(const PartRank rank, int[] parts, const int size)
	{
		int count;
		int part;
		int integerRank = view_as<int>(rank);
		char indexKey[20];

		this.Rewind();

		if(this.GotoFirstSubKey())
		{
			do
			{
				this.GetSectionName(indexKey, sizeof(indexKey));
				if(StrContains(indexKey, "part") > -1)
				{
					ReplaceString(indexKey, sizeof(indexKey), "part", "");
					part = StringToInt(indexKey);

					if(part <= 0) continue;

					if(rank == Rank_None || this.GetNum("rank") == integerRank)
						parts[count++] = part;

				}
			}
			while(this.GotoNextKey() && count < size);
		}
	}

	public bool GetValue(const char[] keyName, const char[] key, char[] value, const int buffer, const int client = 0)
	{
		char langId[4];

		if(client > 0 && IsClientInGame(client))
			GetLanguageInfo(GetClientLanguage(client), langId, sizeof(langId));
		else
			Format(langId, sizeof(langId), "en");

		CPConfigKeyValues cloned = view_as<CPConfigKeyValues>(new KeyValues("custompart"));


		if(keyName[0] != '\0')
		{
			int id;

			this.GetSectionSymbol(id);
			this.Rewind();

			cloned.Import(this);
			this.JumpToKeySymbol(id);

			if(!cloned.JumpToKey(keyName))
			{
				LogError("[CP] not found keyName in config ''%s''", keyName);
				delete cloned;
				return false;
			}
		}
		else {
			cloned.Import(this);
		}


		if(!StrEqual(langId, "en"))
		cloned.JumpToKey(langId);

		cloned.GetString(key, value, buffer);
		delete cloned;

		return true;
	}

	public void GetPartString(const int partIndex, const char[] key, char[] values, const int bufferLength, const int client = 0)
	{
		if(!this.JumpToPart(partIndex))
		{
			this.GetValue("empty_message", key, values, bufferLength, client);
		}
		else
		{
			this.GetValue("", key, values, bufferLength, client);
		}
	}
}

CPConfigKeyValues PartKV;
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
Handle cvarDebug;

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

void CheckPartConfigFile()
{
	if(PartKV != null)
		delete PartKV;

	enabled = false;
	PartKV = new CPConfigKeyValues();

	PartKV.Rewind();
	if(PartKV.JumpToKey("setting"))
	{
		MaxPartGlobalSlot = PartKV.GetNum("able_slot", 1);

		char key[PLATFORM_MAX_PATH];
		char path[PLATFORM_MAX_PATH];
		char modelExtensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd"};
		char matExtensions[][] = {".vmt", ".vtf"};
		char rankExtensions[][] = {"base", "normal", "rare", "hero", "legend", "another"};

		for(int count = 0; count < sizeof(rankExtensions); count++) // TODO: 등급 개편
		{
			Format(key, sizeof(key), "part_%s_model", rankExtensions[count]);

			for(int i = 0; i < sizeof(modelExtensions); i++)
			{
				PartKV.GetString(key, path, sizeof(path));
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
				PartKV.GetString(key, path, sizeof(path));
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
    PartKV.Rewind();
    if(PartKV.JumpToKey("setting"))
    {
        int rank = view_as<int>(partRank);
        char path[PLATFORM_MAX_PATH];
        char rankExtensions[][] = {"normal", "rare", "hero", "legend", "another"};

        Format(path, sizeof(path), "part_%s_model", rankExtensions[rank]);
        PartKV.GetString(path, path, sizeof(path));

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

stock void Debug(const char[] text, any ...)
{
	if(!GetConVarBool(cvarDebug)) return;

	int len = strlen(text) + 255;
	char[] formatted = new char[len];
	VFormat(formatted, len, text, 2);

	CPrintToChatAll("{yellow}[CP_DEBUG]{default} %s", formatted);
	LogMessage("[CP_DEBUG] %s", formatted);
}
