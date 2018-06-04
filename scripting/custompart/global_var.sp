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

	public int GetPartSymbol(const int partIndex)
	{
		char temp[30];
		int id = -1;
		Format(temp, sizeof(temp), "part%i", partIndex);

		if(this.GetNameSymbol(temp, id))
			return id;

		return -1;
	}

	public bool ImportPartConfig(CPConfigKeyValues victimKv, const int partIndex)
	{
		int preSpot;
		bool result;
		this.GetSectionSymbol(preSpot);

		if((result = this.JumpToKeySymbol(this.GetPartSymbol(partIndex))))
			victimKv.Import(this);

		this.JumpToKeySymbol(preSpot);

		return result;
	}

	public CPPart LoadPart(const int partIndex)
	{
		if(this.JumpToKeySymbol(this.GetPartSymbol(partIndex)))
		{
			CPPart tempPart = new CPPart(partIndex);
			if(this.IsPartActive(partIndex))
			{
				tempPart.Active = true;
				tempPart.DurationMax = GetActivePartDuration(partIndex);
			}

			this.Rewind();
			return tempPart;
		}

		return null;
	}

	public bool IsValidPart(const int partIndex)
	{
		return this.GetPartSymbol(partIndex) > -1;
	}

	public bool CanUsePartClass(const int partIndex, const TFClassType class)
	{
		static const char classnames[][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
		char classes[80];
		CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));

		if(this.ImportPartConfig(kv, partIndex))
			kv.GetString("able_to_class", classes, sizeof(classes));

		delete kv;

		if(classes[0] == '\0')
			return true;

		else if(StrContains(classes, classnames[view_as<int>(class)]) > -1)
			return true;

		return false;
	}

	public int GetValidPartCount(const PartRank rank = Rank_None)
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

				if(StrContains(indexKey, "part") > -1 && this.JumpToKey(indexKey))
				{
					ReplaceString(indexKey, sizeof(indexKey), "part", "");
					part = StringToInt(indexKey);

					if(part <= 0) continue;

					if(rank == Rank_None || this.GetNum("rank") == integerRank)
						count++;
				}

			}
			while(this.GotoNextKey());
		}
		this.Rewind();

		return count;
	}

	public void GetValidPartArray(const PartRank rank, const int[] parts, const int size)
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
				if(StrContains(indexKey, "part") > -1 && this.JumpToKey(indexKey))
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
		this.Rewind();
	}

	public int RandomPart(const int client, const PartRank rank)
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
				if(StrContains(indexKey, "part") > -1 && this.JumpToKey(indexKey))
				{
					ReplaceString(indexKey, sizeof(indexKey), "part", "");
					part = StringToInt(indexKey);

					if(part <= 0) continue;

					if(this.GetPartRank(part) == rank && this.IsCanUseWeaponPart(client, part)
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
			num = kv.GetNum("active_part", 0) > 0;

		delete kv;
		return num > 0;
	}

	public PartRank GetPartRank(const int partIndex)
	{
		CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));
		int rank = view_as<int>(Rank_Normal);

		if(this.ImportPartConfig(kv, partIndex))
	        rank = kv.GetNum("rank", 0);

		delete kv;
	    return view_as<PartRank>(rank);
	}

	public float GetActivePartDuration(const int partIndex)
	{
		CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));
		float duration = 0.0;

		if(this.ImportPartConfig(kv, partIndex))
	        duration = kv.GetFloat("active_duration", 8.0);

		delete kv;
	    return duration;
	}

	public float GetActivePartCooldown(const int partIndex)
	{
		CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));
		float cooldown = 0.0;

		if(this.ImportPartConfig(kv, partIndex))
	        cooldown = kv.GetFloat("active_cooldown", 8.0);

	    delete kv;
	    return cooldown;
	}

	public float GetPartMaxChargeDamage(const int partIndex)
	{
		CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));
		float maxChargeDamage = 0.0;

		if(this.ImportPartConfig(kv, partIndex))
	        maxChargeDamage = KvGetFloat(PartKV, "active_max_charge", 100.0);

		delete kv;
	    return maxChargeDamage;
	}

	public bool IsCanUseWeaponPart(const int client, const int partIndex)
	{
	    int index, count, value;
	   	char key[20];

		CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));
		if(!this.ImportPartConfig(kv, partIndex))
			return false;

	    for(int slot = 0; slot < 5; slot++)
	    {
	        count = 0;

	        if(IsValidEntity(weapon))
	        {
	            index = GetEntProp(GetPlayerWeaponSlot(client, slot), Prop_Send, "m_iItemDefinitionIndex");
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
	            while(1 == 1);
	        }
	    }

	    return false;
	}

	public void GetPartString(const int partIndex, const char[] key, char[] values, const int bufferLength, const int client = 0)
	{
		CPConfigKeyValues kv = view_as<CPConfigKeyValues>(new KeyValues("custompart"));
		bool validClient = (client > 0 && IsClientInGame(client));

		if(!this.ImportPartConfig(kv, partIndex))
	    {
			if(validClient)
				SetGlobalTransTarget(client);

	        Format(values, bufferLength, "%t", "cp_empty");

			SetGlobalTransTarget(LANG_SERVER);
	    }
	    else
	    {
			char langId[4];

			if(validClient)
			    GetLanguageInfo(GetClientLanguage(client), langId, sizeof(langId));
			else
			    Format(langId, sizeof(langId), "en");

			if(!StrEqual(langId, "en"))
			{
			    if(!kv.JumpToKey(langId))
			    {
			        LogError("[CP] not found languageId in ''part%i'' ''%s''", partIndex, langId);
			        // 이 경우에는 그냥 영어로 변경.
			    }
			}

	        kv.GetString(key, values, bufferLength);
			delete kv;
	    }
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
