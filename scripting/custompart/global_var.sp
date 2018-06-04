#define	MAX_EDICT_BITS	12
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

#define INVALID_PARTID -1

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

	public int GetPartSymbol(int partIndex)
	{
		char temp[30];
		int id = -1;
		Format(temp, sizeof(temp), "part%i", partIndex);

		if(this.GetNameSymbol(temp, id))
			return id;

		return -1;
	}

	public bool ImportPartConfig(CPConfigKeyValues victimKv, int partIndex)
	{
		int preSpot;
		bool result;
		this.GetSectionSymbol(preSpot);

		if((result = this.JumpToKeySymbol(this.GetPartSymbol(partIndex))))
			victimKv.Import(this);

		this.JumpToKeySymbol(preSpot);

		return result;
	}

	public CPPart LoadPart(int partIndex)
	{
		if(this.JumpToKeySymbol(this.GetPartSymbol(partIndex)))
		{
			CPPart tempPart = new CPPart(partIndex);
			if(IsPartActive(partIndex))
			{
				tempPart.Active = true;
				tempPart.DurationMax = GetActivePartDuration(partIndex);
			}

			return tempPart;
		}

		return null;
	}

	public bool CanUsePartClass(const int partIndex, const TFClassType class)
	{
		static const char classnames[][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
		char classes[80];
		CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));

		if(this.ImportPartConfig(kv, partIndex))
		{
			kv.GetString("able_to_class", classes, sizeof(classes));
			delete kv;

			if(classes[0] == '\0')
				return true;

			else if(!StrContains(classes, classnames[view_as<int>(class)], false))
				return true;
		}
		return false;
	}

	public int GetValidPartCount(PartRank rank = Rank_None)
	{
		int count;
		int part;
		int integerRank = view_as<int>(rank);
		char indexKey[20];

		if(this.GotoFirstSubKey())
		{
			do
			{
				this.GetSectionName(indexKey, sizeof(indexKey));
				if(!StrContains(indexKey, "part"))
				{
					ReplaceString(indexKey, sizeof(indexKey), "part", "");
					if(this.JumpToKeySymbol(this.GetPartSymbol((part = StringToInt(indexKey)))))
					{
						if(part <= 0) continue;

						if(rank == Rank_None || this.GetNum("rank") == integerRank)
							count++;
					}
				}
			}
			while(this.GotoNextKey());
		}
		this.Rewind();

		return count;
	}

	public void GetValidPartArray(PartRank rank, int[] parts, int size)
	{
		int count;
		int part;
		int integerRank = view_as<int>(rank);
		char indexKey[20];

		if(this.GotoFirstSubKey())
		{
			do
			{
				this.GetSectionName(indexKey, sizeof(indexKey));
				if(!StrContains(indexKey, "part"))
				{
					ReplaceString(indexKey, sizeof(indexKey), "part", "");
					if(this.JumpToKeySymbol(this.GetPartSymbol((part = StringToInt(indexKey)))))
					{
						if(part <= 0) continue;

						if(rank == Rank_None || this.GetNum("rank") == integerRank)
							parts[count++] = part;
					}
				}
			}
			while(this.GotoNextKey() && count < size);
		}
		this.Rewind();
	}

	public int RandomPart(int client, PartRank rank)
	{
		ArrayList parts = new ArrayList();
		int count = 0;
		int part;

		char indexKey[20];
		TFClassType class = TF2_GetPlayerClass(client);
		EngineVersion gameEngine = GetEngineVersion();

		if(this.GotoFirstSubKey())
		{
			do
			{
				this.GetSectionName(indexKey, sizeof(indexKey));
				if(!StrContains(indexKey, "part"))
				{
					ReplaceString(indexKey, sizeof(indexKey), "part", "");
					if(this.JumpToKeySymbol(this.GetPartSymbol((part = StringToInt(indexKey)))))
					{
						if(part <= 0) continue;

						if(GetPartRank(part) == rank && IsCanUseWeaponPart(client, part)
						&& this.GetNum("not_able_in_random", 0) <= 0
						) // TODO: 타 게임 지원
						{
						if(gameEngine == Engine_TF2 && !this.CanUsePartClass(part, class))
							continue;

							count++;
							parts.Push(part);
						}
					}
				}
			}
			while(this.GotoNextKey());
		}

		this.Rewind();

		SetRandomSeed(GetTime());
		int answer;

		if(count <= 0)
		{
			parts.Close();

			int integerRank = view_as<int>(rank);
			if(--integerRank < 0)
				return 0;

			// answer = this.RandomPart(client, view_as<PartRank>(integerRank)); // TODO; 등급 개편
		}
		else
		{
			answer = parts.Get(GetRandomInt(0, count-1));
		}
		parts.Close();

		return answer;
	}

	public bool IsPartActive(const int partIndex)
	{
		int num;
		CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));

		if(this.ImportPartConfig(kv, partIndex))
		{
			num = kv.GetNum("active_part", 0) > 0;
			delete kv;
		}

		return num > 0;
	}
}

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
		char rankExtensions[][] = {"base", "normal", "rare", "hero", "legend", "another"};;

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
