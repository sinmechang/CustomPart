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

int SpawnCustomPart(PartRank partRank, float position[3], float velocity[3], bool IsFake)
{
    if(AllPartPropCount > 50)
    {
        return -1;
    }

    int prop = CreateEntityByName("prop_physics_override");

    if(IsValidEntity(prop))
    {
        AllPartPropCount++;

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

        if(g_hClientInfo[client].GetCoolTime > GetGameTime())
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

        if(IsCorrectTeam(client))
        {
            part = GetPartPropInfo(entity, Info_CustomIndex);
            if(!PartKV.IsValidPart(part))
                part = PartKV.RandomPart(client, rank);

            slot = (g_hClientInfo[client].PartSlot).FindActiveSlot();
            tempPart = part;
            // Debug("확정된 파츠: %i, slot = %i, rank = %i", part, slot, view_as<int>(rank));

            if(part <= 0 || slot < 0) // 유효한 파츠이나 파츠 슬릇 체크
            {
                Debug("OnPickup: part = %d slot = %d", part, slot);
                IgnoreAndKickIt(client, entity);
                return Plugin_Continue;
            }

            // Debug("OnPickup: part = %d slot = %d", part, slot);
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
            g_hClientInfo[client].GetCoolTime = GetGameTime() + GetConVarFloat(cvarPropCooltime);
            PrintCenterText(client, "파츠를 흭득하셨습니다!");

            if(PartKV.IsPartActive(part))
            {
                g_hClientInfo[client].MaxChargeDamage += PartKV.GetPartMaxChargeDamage(part);
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
