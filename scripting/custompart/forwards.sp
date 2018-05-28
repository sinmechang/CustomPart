Handle OnTouchedPartProp;
Handle OnTouchedPartPropPost;
Handle OnGetPart;
Handle OnGetPartPost;
Handle OnSlotClear;
Handle PreActivePart;
Handle OnActivedPart;
Handle OnActivedPartEnd;
Handle OnClientCooldownEnd;
Handle OnActivedPartTime;

void Init_Forwards()
{
    OnTouchedPartProp = CreateGlobalForward("CP_OnTouchedPartProp", ET_Hook, Param_Cell, Param_CellByRef);
    OnTouchedPartPropPost = CreateGlobalForward("CP_OnTouchedPartProp_Post", ET_Hook, Param_Cell, Param_Cell);
    OnGetPart = CreateGlobalForward("CP_OnGetPart", ET_Hook, Param_Cell, Param_CellByRef, Param_CellByRef);
    OnGetPartPost = CreateGlobalForward("CP_OnGetPart_Post", ET_Hook, Param_Cell, Param_Cell);
    OnSlotClear = CreateGlobalForward("CP_OnSlotClear", ET_Hook, Param_Cell, Param_Cell, Param_Cell);
    PreActivePart = CreateGlobalForward("CP_PreActivePart", ET_Hook, Param_Cell, Param_CellByRef);
    OnActivedPart = CreateGlobalForward("CP_OnActivedPart", ET_Hook, Param_Cell, Param_Cell);
    OnActivedPartEnd = CreateGlobalForward("CP_OnActivedPartEnd", ET_Hook, Param_Cell, Param_Cell);
    OnClientCooldownEnd = CreateGlobalForward("CP_OnClientCooldownEnd", ET_Hook, Param_Cell);
    OnActivedPartTime = CreateGlobalForward("CP_OnActivedPartTime", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
}

public Action Forward_OnTouchedPartProp(int client, int &prop)
{
    Action action;
    Call_StartForward(OnTouchedPartProp);
    Call_PushCell(client);
    Call_PushCellRef(prop);
    Call_Finish(action);

    return action;
}

void Forward_OnTouchedPartProp_Post(int client, int prop)
{
    Call_StartForward(OnTouchedPartPropPost);
    Call_PushCell(client);
    Call_PushCell(prop);
    Call_Finish();
}

public Action Forward_OnGetPart(int client, int &prop, int &partIndex)
{
    Action action;
    Call_StartForward(OnGetPart);
    Call_PushCell(client);
    Call_PushCellRef(prop);
    Call_PushCellRef(partIndex);
    Call_Finish(action);

    return action;
}

void Forward_OnGetPart_Post(int client, int partIndex)
{
    Call_StartForward(OnGetPartPost);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_Finish();
}

public Action Forward_OnSlotClear(int client, int partIndex, bool gotoNextRound)
{
    Action action;
    Call_StartForward(OnSlotClear);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_PushCell(gotoNextRound);
    Call_Finish(action);

    return action;
}

public Action Forward_PreActivePart(int client, int &partIndex)
{
    Action action;
    Call_StartForward(PreActivePart);
    Call_PushCell(client);
    Call_PushCellRef(partIndex);
    Call_Finish(action);

    return action;
}

public void Forward_OnActivedPart(int client, int partIndex)
{
    Call_StartForward(OnActivedPart);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_Finish();
}

public void Forward_OnActivedPartEnd(int client, int partIndex)
{
    Call_StartForward(OnActivedPartEnd);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_Finish();
}

public void Forward_OnClientCooldownEnd(int client)
{
    Call_StartForward(OnClientCooldownEnd);
    Call_PushCell(client);
    Call_Finish();
}

public Action Forward_OnActivedPartTime(int client, int partIndex, float &duration)
{
    Action action;

    Call_StartForward(OnActivedPartTime);
    Call_PushCell(client);
    Call_PushCell(partIndex);
    Call_PushFloatRef(duration);
    Call_Finish(action);

    return action;
}
