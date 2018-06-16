void Init_ConfigNatives()
{
    CreateNative("CPConfigKeyValues.GetPartSymbol", Native_CPC_GetPartSymbol);
    CreateNative("CPConfigKeyValues.ExportSelf", Native_CPC_ExportSelf);
    CreateNative("CPConfigKeyValues.LoadPart", Native_CPC_LoadPart);
    CreateNative("CPConfigKeyValues.IsValidPart", Native_CPC_IsValidPart);
    CreateNative("CPConfigKeyValues.JumpToPart", Native_CPC_JumpToPart);
    CreateNative("CPConfigKeyValues.CanUsePartClass", Native_CPC_CanUsePartClass);
    CreateNative("CPConfigKeyValues.GetValidPartCount", Native_CPC_GetValidPartCount);
    // CreateNative("CPConfigKeyValues.GetValidPartArray", Native_CPC_GetValidPartArray);
    CreateNative("CPConfigKeyValues.RandomPart", Native_CPC_RandomPart);
    CreateNative("CPConfigKeyValues.IsPartActive", Native_CPC_IsPartActive);
    CreateNative("CPConfigKeyValues.GetPartRank", Native_CPC_GetPartRank);
    CreateNative("CPConfigKeyValues.GetActivePartDuration", Native_CPC_GetActivePartDuration);
    CreateNative("CPConfigKeyValues.GetActivePartCooldown", Native_CPC_GetActivePartCooldown);
    CreateNative("CPConfigKeyValues.GetPartMaxChargeDamage", Native_CPC_GetPartMaxChargeDamage);
    CreateNative("CPConfigKeyValues.IsCanUseWeaponPart", Native_CPC_IsCanUseWeaponPart);
    // CreateNative("CPConfigKeyValues.GetPartString", Native_CPC_GetPartString);
}

public int Native_CPC_GetPartSymbol(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);

    char temp[30];
    int id = -1;
    Format(temp, sizeof(temp), "part%i", partIndex);

    if(thisKv.GetNameSymbol(temp, id))
        return id;

    return -1;
}

public int Native_CPC_ExportSelf(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    CPConfigKeyValues victimKv = GetNativeCell(2);
    int preSpot;

    thisKv.GetSectionSymbol(preSpot);
    thisKv.Rewind();

    victimKv.Import(thisKv);
    thisKv.JumpToKeySymbol(preSpot);
}

public int Native_CPC_LoadPart(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);

    if(thisKv.JumpToKeySymbol(thisKv.GetPartSymbol(partIndex)))
    {
        CPPart tempPart = new CPPart(partIndex);
        if(thisKv.IsPartActive(partIndex))
        {
            tempPart.Active = true;
            tempPart.DurationMax = thisKv.GetActivePartDuration(partIndex);
        }

        thisKv.Rewind();
        return view_as<int>(tempPart);
    }

    return 0; // == null
}

public int Native_CPC_IsValidPart(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);

    return view_as<int>(thisKv.JumpToPart(partIndex));
}

public int Native_CPC_JumpToPart(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);

    char temp[30], currentSection[30];
    Format(temp, sizeof(temp), "part%i", partIndex);
    thisKv.GetSectionName(currentSection, sizeof(currentSection));

    if(StrEqual(temp, currentSection))
    {
        return true;
    }

    thisKv.Rewind();
    return thisKv.JumpToKey(temp);
}

public int Native_CPC_CanUsePartClass(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);
    TFClassType class = GetNativeCell(3);

    static const char classnames[][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
    char classes[80];

    if(thisKv.JumpToPart(partIndex))
        thisKv.GetString("able_to_class", classes, sizeof(classes));

    if(classes[0] == '\0')
        return view_as<int>(true);

    else if(StrContains(classes, classnames[view_as<int>(class)]) > -1)
        return view_as<int>(true);

    return view_as<int>(false);
}

public int Native_CPC_GetValidPartCount(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    PartRank rank = GetNativeCell(2);

    int count;
    int part;
    int integerRank = view_as<int>(rank);
    char indexKey[20];

    thisKv.Rewind();

    if(thisKv.GotoFirstSubKey())
    {
        do
        {
            thisKv.GetSectionName(indexKey, sizeof(indexKey));

            if(StrContains(indexKey, "part") > -1 && thisKv.JumpToKey(indexKey))
            {
                ReplaceString(indexKey, sizeof(indexKey), "part", "");
                part = StringToInt(indexKey);

                if(part <= 0) continue;

                if(rank == Rank_None || thisKv.GetNum("rank") == integerRank)
                    count++;
            }

        }
        while(thisKv.GotoNextKey());
    }

    return count;
}


public int Native_CPC_RandomPart(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int client = GetNativeCell(2);
    PartRank rank = GetNativeCell(3);

    ArrayList parts = new ArrayList();
    int count = 0;
    int part;

    char indexKey[20];
    TFClassType class = TF2_GetPlayerClass(client);
    EngineVersion gameEngine = GetEngineVersion();

    thisKv.Rewind();

    if(thisKv.GotoFirstSubKey())
    {
        do
        {
            thisKv.GetSectionName(indexKey, sizeof(indexKey));
            if(StrContains(indexKey, "part") > -1)
            {
                ReplaceString(indexKey, sizeof(indexKey), "part", "");
                part = StringToInt(indexKey);

                if(part <= 0) continue;

                if(thisKv.GetPartRank(part) == rank && thisKv.IsCanUseWeaponPart(client, part)
                && thisKv.GetNum("not_able_in_random", 0) <= 0
                ) // TODO: 타 게임 지원
                {
                    if(gameEngine == Engine_TF2 && !thisKv.CanUsePartClass(part, class))
                        continue;

                    count++;
                    parts.Push(part);

                    Debug("Pushed %d", part);
                }
            }
        }
        while(thisKv.GotoNextKey());
    }

    SetRandomSeed(GetTime());
    int answer;

    if(count <= 0)
    {
        delete parts;

        int integerRank = view_as<int>(rank);
        if(--integerRank < 0)
            return 0;

        answer = thisKv.RandomPart(client, view_as<PartRank>(integerRank)); // TODO; 등급 개편
    }
    else
    {
        answer = parts.Get(GetRandomInt(0, count-1));
    }
    delete parts;

    return answer;
}

public int Native_CPC_IsPartActive(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);

    int num;

    if(thisKv.JumpToPart(partIndex))
        num = thisKv.GetNum("active_part", 0) > 0;

    return view_as<int>(num > 0);
}

public int Native_CPC_GetPartRank(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);

    int rank = view_as<int>(Rank_Normal);

    if(thisKv.JumpToPart(partIndex))
        rank = thisKv.GetNum("rank", 0);

    return rank;

}

public int Native_CPC_GetActivePartDuration(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);

    float duration = 0.0;

    if(thisKv.JumpToPart(partIndex))
        duration = thisKv.GetFloat("active_duration", 8.0);

    return view_as<int>(duration);
}

public int Native_CPC_GetActivePartCooldown(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);

    float cooldown = 0.0;

    if(thisKv.JumpToPart(partIndex))
        cooldown = thisKv.GetFloat("active_cooldown", 8.0);

    return view_as<int>(cooldown);
}

public int Native_CPC_GetPartMaxChargeDamage(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int partIndex = GetNativeCell(2);

    float maxChargeDamage = 0.0;

    if(thisKv.JumpToPart(partIndex))
        maxChargeDamage = thisKv.GetFloat("active_max_charge", 100.0);

    return view_as<int>(maxChargeDamage);
}

public int Native_CPC_IsCanUseWeaponPart(Handle plugin, int numParams)
{
    CPConfigKeyValues thisKv = GetNativeCell(1);
    int client = GetNativeCell(2);
    int partIndex = GetNativeCell(3);

    int index, count, value, weapon;
    char key[20];

    if(!thisKv.JumpToPart(partIndex))
        return view_as<int>(false);

    for(int slot = 0; slot < 5; slot++)
    {
        count = 0;
        weapon = GetPlayerWeaponSlot(client, slot);

        if(IsValidEntity(weapon))
        {
            index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
            do
            {
                Format(key, sizeof(key), "only_allow_weapon%i", ++count);
                value = thisKv.GetNum(key, 0);

                if(value == index)
                    return view_as<int>(true);

                else if(count <= 1 && value <= 0)
                    return view_as<int>(true);

                else if(value <= 0)
                    break;
            }
            while(count > 0); // lol.
        }
    }

    return view_as<int>(false);
}
