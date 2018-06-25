#if defined __custompart_cp_global_included
	#endinput
#endif

#define __custompart_cp_global_included


enum PartRank
{
	Rank_None = -1,
	Rank_Normal = 0,
	Rank_Rare,
	Rank_Hero,
	Rank_Legend,
	Rank_Another,
	Rank_Rainbow
};

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

	public native int GetPartDefaultFlag(const int partIndex);

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

		if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
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
			this.GetValue("empty_message", "message", values, bufferLength, client);
		}
		else
		{
			this.GetValue("", key, values, bufferLength, client);
		}
	}
}
