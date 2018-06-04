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
