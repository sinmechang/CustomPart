
#define CPFLAG_DONOTCLEARSLOT (1<<1)
#define CPFLAG_DISABLE_HUD (1<<2)

enum PartRank
{
    Rank_None=-1,
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
    Info_CustomIndex
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
* @param holdCooltime 새로고침하면서 원래 있던 쿨타임을 유지시킬지 지정.
*   - 기본은 false, 만약 유지한다면 반드시 true로 지정할 것.
* @noreturn
*
*/
native void CP_RefrashPartSlotArray(int client, bool holdParts=false, bool holdCooltime=false);

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
* 해당 프롭의 정보를 구함.
*
*  @param prop 확인할 프롭
*  @param partInfo 확인할 정보
*  @return 확인할 정보의 값.
**************
*
*   이 함수는 정수(int)형으로 반환함. (PartRank는 형변환이 필요함)
*
*/
native int CP_GetPartPropInfo(int prop, PartInfo partInfo);

/*
*  해당 프롭의 정보를 정함.
*
*   @param prop 설정할 프롭
*   @param partInfo 설정할 정보
*   @param value 설정할 값  **** 형변환 필요없음!
*   @param changeModel true일 경우, 그 랭크의 모델로 바뀜.
*   @noreturn
*
*
*/
native void CP_SetPartPropInfo(int prop, PartInfo partinfo, any value, bool changeModel = false);

/*
*   해당 엔티티를 파츠 프롭으로 정함.
*
*   @param prop 설정할 프롭
*   @param partIndex 설정할 파츠의 값 (0일 경우, 닿을 시 랜덤)
*   @param rank 설정할 파츠의 랭크
*   @param createLight 윤곽선 표시여부
*   @param changeModel true일 경우, 그 랭크의 모델로 바뀜.
*   @param IsFake 가짜 파츠 설정
*   @noreturn
*
*
*/
native void CP_PropToPartProp(int prop, int partIndex=0, PartRank rank=Rank_Normal, bool createLight, bool changeModel=false, bool IsFake=false);

/*
*   해당 클라이언트의 슬릇 최대량을 구함.
*
*   @param client 구할 클라이언트
*   @return 그 클라이언트의 슬릇값
*
*/
native int CP_GetClientMaxSlot(int client);

/*
*   해당 클라이언트의 슬릇 최대량을 구함.
*
*   @param client 정할 클라이언트
*   @param maxSlot 정할 슬릇크기
*   @noreturn
*
*/
native void CP_SetClientMaxSlot(int client, int maxSlot);

/*
*   해당 클라이언트의 특정 파츠를 다른 파츠로 바꿈.
*
*   @param client 정할 클라이언트
*   @param beforePartIndex 이 파츠를..
*   @param afterPartIndex 이 파츠로 바꾸기
*   @return 성공적으로 바뀌었을 경우, true로 반환함.
*
*/
native bool CP_ReplacePartSlot(int client, int beforePartIndex, int afterPartIndex);

/*
*   해당 클라이언트의 비어있는 슬릇을 찾음.
*
*   @param client 클라이언트
*   @return 비어있는 파츠 슬릇값을 반환함. 아닐경우 -1.
*
*/
native int CP_FindActiveSlot(int client);

/*
*   해당 클라이언트의 파츠 발동을 알리는 함수.
*
*   @param client 클라이언트
*   @param partIndex 알릴 파츠
*   @noreturn
*
*/
native void CP_NoticePart(int client, int partIndex);

native float CP_GetClientActiveSlotDuration(int client, int slot);

native void CP_SetClientActiveSlotDuration(int client, int slot, float value);

native float CP_GetClientTotalCooldown(int client);

native float CP_GetClientPartCharge(int client);

native void CP_SetClientPartCharge(int client, float charge);

native float CP_GetClientPartMaxChargeDamage(int client);

native float CP_SetClientPartMaxChargeDamage(int client, float chargeDamage);

native void CP_AddClientPartCharge(int client, float charge);

native int CP_FindPart(int client, int partIndex);

native bool CP_IsEnabled();

native PartRank CP_RandomPartRank(bool includeAnother=false);
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
forward Action CP_OnGetPart(int client, int prop, int partIndex);

/*
*
*
*
*/
forward void CP_OnGetPart_Post(int client, int partIndex);

/*
*
*
*
*/
forward Action CP_OnSlotClear(int client, int partIndex, bool gotoNextRound);

/*
*
*
*
*/
forward Action CP_PreActivePart(int client, int partIndex);

/*
*
*
*
*/
forward void CP_OnActivedPart(int client, int partIndex);

/*
*
*
*
*/
forward void CP_OnActivedPartEnd(int client, int partIndex);

/*
*
*
*
*/
forward void CP_OnClientCooldownEnd(int client);
