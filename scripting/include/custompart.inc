enum PartRank
{
    Rank_Normal=0,
    Rank_Rare,
    Rank_Hero,
    Rank_Legend,
    Rank_Another
};

enum PartInfo
{
    Info_EntId=0,
    Info_Rank,
    Info_CustomInfo
};

/*
*
*
*
*/
native int CP_GetClientPart(int client, int slot);

/*
*
*
*
*/
native void CP_SetClientPart(int client, int slot, int value);

/*
*
*
*
*/
native bool CP_IsPartActived(int client, int partIndex);

/*
*
*
*
*/
native void CP_RefrashPartSlotArray(int client, bool holdParts=false);

/*
*
*
*
*/
native bool CP_IsValidPart(int partIndex);

/*
*
*
*
*/
native bool CP_IsValidSlot(int client, int slot);

/*
*
*
*
*/
native int CP_GetPartPropInfo(int prop, PartInfo partInfo);

/*
*
*
*
*/
native void CP_SetPartPropInfo(int prop, PartInfo partinfo, int value, bool changeModel = false);

/*
*
*
*
*/
native bool CP_PropToPartProp(int prop, int partIndex=0, PartRank rank=Rank_Normal, bool createLight, bool changeModel=false, bool IsFake=false);

/*
*
*
*
*/
native int CP_GetClientMaxSlot(int client);

/*
*
*
*
*/
native void CP_SetClientMaxSlot(int client, int maxSlot);

/*
*
*
*
*/
forward Action CP_OnTouchedPartProp(int client, int prop);

/*
*
*
*
*/
forward void CP_OnTouchedPartProp_Post(int client, int prop);

/*
*
*
*
*/
forward Action CP_OnGetPart(int client, int part);

/*
*
*
*
*/
forward void CP_OnGetPart_Post(int client, int part);
