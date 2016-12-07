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
* 해당 슬릇의 파츠 값을 확인 함.
*
* @param client 클라이언트.
* @param slot 확인 할 슬릇
* @return 0은 그 슬릇이 비어있다는 것, 그 외에는 파츠 값.
*
*/
native int CP_GetClientPart(int client, int slot);

/*
* 해당 슬릇에 파츠 값을 부여 함.
*
* @param client 클라이언트.
* @param slot 부여할 슬릇
* @param value
* @noreturn
*
* 만약 slot이 플레이어의 최대 슬릇보다 클 경우에는 적용되지 않음.
*/
native void CP_SetClientPart(int client, int slot, int value);

/*
* 해당 클라이언트가 해당 파츠를 가지고 있는지 확인함.
*
* @param client 클라이언트.
* @param partIndex 확인할 파츠 값.
* @return 가지고 있을 경우에는 true 아니면 false.
*
*/
native bool CP_IsPartActived(int client, int partIndex);

/*
* 플레이어의 슬릇을 새로 고침
*
* *** 중요 ***
*   - 슬릇 관련을 다루기 전에는 반드시 본 함수를 사용할 것.
*   - 만약 최대 슬릇을 건드리지 않았다면 굳이 이 함수를 쓰지 않아도 괜찮음.
*
* @param client 지정할 클라이언트
* @param holdParts 새로고침 하면서 원래 있던 파츠를 유지할 것인지 지정.
*   - 기본은 false, 만약 유지한다면 반드시 true로 지정할 것.
* @noreturn
*
*/
native void CP_RefrashPartSlotArray(int client, bool holdParts=false);

/*
* 해당 파츠가 유효한지 확인함.
* 서버의 컨픽에 정상적으로 등록된 파츠들만을 유효한 파츠로 지정함.
*
* @param partIndex 확인할 파츠 갑.
* @return 파츠가 유효할 경우 true.
*
*/
native bool CP_IsValidPart(int partIndex);

/*
* 해당 플레이어의 해당 슬릇이 유효한지 확인함.
*
* @param client 클라이언트
* @param slot  확인할 슬릇
* @return 유효할 경우 true.
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
