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

    CloseHandle(clonedHandle);

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

    CloseHandle(clonedHandle);
}

int RandomPart(int client, PartRank rank)
{
    ArrayList parts = new ArrayList();
    int count = 0;
    int part;

    char key[20];
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

                    if(CanUsePartClass(part, class)
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

    CloseHandle(clonedHandle);

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

/*
bool CanUsePartBoss(int partIndex)
{
    if(IsValidPart(partIndex))
    {
        return KvGetNum(PartKV, "able_to_boss", 0) > 0;
    }
    return false;
}
*/
/*
bool CanUseSystemBoss()
{
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
                if(IsValidPart(StringToInt(key)))
                {
                    if(KvGetNum(PartKV, "able_to_boss", 0) > 0)
                        return true;
                }
            }
        }
        while(KvGotoNextKey(clonedHandle));
    }

    CloseHandle(clonedHandle);

    return false;
}
*/

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
/*
bool CanUseSystemClass(TFClassType class)
{
    char classnames[][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
    char classes[80];
    char key[20];

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
    }

    CloseHandle(clonedHandle);

    return false;
}
*/
