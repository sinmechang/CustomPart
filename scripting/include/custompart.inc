#if defined __custompart_included
	#endinput
#endif

#define __custompart_included

#include "custompart/forwards.sp"


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
    TODO: For v2

    - <int> CP_GetSlotPartCount(int client, int slot);
    - CP_RemovePartOnMap(void);
    - CP_EnableClientSlot(int client, int slot);
    - CP_DisableClientSlot(int client, int slot, char[] reason);
    - CP_GetSlotPartName(int client, int slot, char[] slotPartName, int buffer);
    - CP_SetSlotPartName(int client, int slot, char[] slotPartName);
    - <int> CP_GetAllPartCountOnMap();
    - CP_GetAllPartOnMap(int[] &parts, int maxcount);

    .. and use MethodMap.
*/
enum PartValueType
{
	Part_PartIndex,
	Part_Flags,
	Part_Duration,
	Part_DurationMax,
	Part_Active,

	PartValue_Last
};

enum PartPropValueType
{
	PartProp_PropIndex,
	PartProp_Rank,
	PartProp_GlowIndex,
	PartProp_CustomPart,

	PartPropValue_Last
};

enum ClientValueType
{
    Client_Index, // Just client index.
    Client_Flags, // CPFlags
	Client_ActiveCooldown, // PartCooldown
	Client_GetCoolTime, // PartGetCoolTime

	Client_Charge, // PartCharge
	Client_MaxChargeDamage, // PartMaxChargeDamage

	Client_MaxSlotCount, // MaxPartSlot
	Client_PartSlot, // NOTE: This is array.
	/*
		ActivedPartSlotArray
		ActivedDurationArray
	*/
    ClientValue_Last // NOTE: Keep this at this position.
};

enum SlotValueType
{
	Slot_SlotIndex,
	Slot_PartIndex,

	SlotValue_Last
};


methodmap CPPart < ArrayList {
	public CPPart(int partIndex)
	{
		CPPart array = view_as<CPPart>(new ArrayList(4, PartValue_Last));

		for(int loop = 0; loop < view_as<int>(PartValue_Last); loop++)
		{
			array.Set(loop, 0);
		}

		array.Set(view_as<int>(Part_PartIndex), partIndex);
		return array;
	}

	public any GetValue(PartValueType valueType)
	{
		return this.Get(view_as<int>(valueType));
	}

	public void SetValue(PartValueType valueType, any value)
	{
		this.Set(view_as<int>(valueType), value);
	}

	public CPPart KillSelf()
	{
		delete this;

		return null;
	}

	property int Index {
		public get()
		{
			return this.GetValue(Part_PartIndex);
		}
		public set(int partIndex)
		{
			this.SetValue(Part_PartIndex, partIndex);
		}
	}

	property int Flags {
		public get()
		{
			return this.GetValue(Part_Flags);
		}
		public set(int flags)
		{
			this.SetValue(Part_Flags, flags);
		}
	}

	property float Duration {
		public get()
		{
			return this.GetValue(Part_Duration) - GetGameTime();
		}
		public set(float time)
		{
			this.SetValue(Part_Duration, time + GetGameTime());
		}
	}

	property float DurationMax {
		public get()
		{
			return this.GetValue(Part_DurationMax);
		}
		public set(float time)
		{
			this.SetValue(Part_DurationMax, time);
		}
	}

	property bool Active {
		public get()
		{
			return this.GetValue(Part_Active);
		}
		public set(bool enable)
		{
			this.SetValue(Part_Active, enable);
		}
	}
/*
	public Action TriggerOnGet(int client, CPPartProp partprop = null)
	{
		int propIndex =
		Forward_OnGetPart(client, )
	}
*/
}

methodmap CPPartProp < ArrayList {
	public CPPartProp(int partIndex)
	{
		CPPartProp array = view_as<CPPartProp>(new ArrayList(PLATFORM_MAX_PATH, PartPropValue_Last));

		for(int loop = 0; loop < view_as<int>(PartPropValue_Last); loop++)
		{
			array.Set(loop, 0);
		}

		array.Set(view_as<int>(PartProp_PropIndex), partIndex);
		return array;
	}

	public any GetValue(PartPropValueType valueType)
	{
		return this.Get(view_as<int>(valueType));
	}

	public void SetValue(PartPropValueType valueType, any value)
	{
		this.Set(view_as<int>(valueType), value);
	}

	property int PropIndex {
		public get()
		{
			return this.GetValue(PartProp_PropIndex);
		}
		public set(int partPropIndex)
		{
			this.SetValue(PartProp_PropIndex, partPropIndex);
		}
	}

	property PartRank Rank {
		public get()
		{
			return this.GetValue(PartProp_PropIndex);
		}
		public set(PartRank partPropRank)
		{
			this.SetValue(PartProp_Rank, partPropRank);
		}
	}

	property int GlowIndex {
		public get()
		{
			return this.GetValue(PartProp_GlowIndex);
		}
		public set(int glowEntityIndex)
		{
			this.SetValue(PartProp_GlowIndex, glowEntityIndex);
		}
	}

	property CPPart CustomPart {
		public get()
		{
			return this.GetValue(PartProp_CustomPart);
		}
		public set(CPPart part)
		{
			this.SetValue(PartProp_CustomPart, part);
		}
	}
}

methodmap CPClientPartSlot < ArrayList {
	public CPClientPartSlot(int maxSlot)
	{
		CPClientPartSlot array = view_as<CPClientPartSlot>(new ArrayList(4, maxSlot));

		for(int slotLoop = 0; slotLoop < maxSlot; slotLoop++)
		{
			ArrayList insideArray = new ArrayList(4, view_as<int>(SlotValue_Last));
			for(int loop = 0; loop < view_as<int>(SlotValue_Last); loop++)
			{
				insideArray.Set(loop, 0);
			}
			array.Set(slotLoop, insideArray);
		}

		return array;
	}
/*
	// Unused for now :3
    public any GetValue(SlotValueType valueType)
	{
		return this.Get(view_as<int>(valueType));
	}

	public void SetValue(SlotValueType valueType, any value)
	{
		this.Set(view_as<int>(valueType), value);
	}
*/
	public CPClientPartSlot KillSelf()
	{
		ArrayList insideArray;

		for(int slotLoop = 0; slotLoop < this.Length; slotLoop++)
		{
			insideArray = this.Get(slotLoop);
			delete insideArray;
		}

		delete this;
		return null;
	}

	public void ResizeSlot(int size)
	{
		int beforeSize = this.Length - 1;
		int afterSize = size - 1;
		CPPart array;

		if(size < beforeSize)
		{
			for(; beforeSize >= afterSize; beforeSize--)
			{
				array = this.Get(beforeSize);
				array.KillSelf();
			}

			this.Resize(size);
		}
		else if(size > beforeSize)
		{
			this.Resize(size);

			for(beforeSize++; beforeSize <= afterSize; beforeSize++)
			{
				ArrayList insideArray = new ArrayList(4, view_as<int>(SlotValue_Last));
				this.Set(beforeSize, insideArray);
			}
		}
	}

	public CPPart GetPart(int slot)
	{
		return this.Get(slot);
	}

	public void SetPart(int slot, CPPart part)
	{
		CPPart tempPart = this.Get(slot);
		if(tempPart != null)
			tempPart.KillSelf();

		this.Set(slot, part);
	}
}

methodmap CPClient < ArrayList {
	public CPClient(int client, int maxSlotCount)
	{
		CPClient array = view_as<CPClient>(new ArrayList(4, view_as<int>(ClientValue_Last)));

		for(int loop = 0; loop < view_as<int>(ClientValue_Last); loop++)
		{
			array.Set(loop, 0);
		}

		array.Set(view_as<int>(Client_Index), client);
		array.Set(view_as<int>(Client_PartSlot), new CPClientPartSlot(maxSlotCount));

		return array;
	}

    public any GetValue(ClientValueType valueType)
	{
		return this.Get(view_as<int>(valueType));
	}

	public void SetValue(ClientValueType valueType, any value)
	{
		this.Set(view_as<int>(valueType), value);
	}

	public CPClient KillSelf()
	{
		CPClientPartSlot array = this.GetValue(Client_PartSlot);
		delete array;
		delete this;

		return null; // Always!
	}

	property int Index {
		public get()
		{
			return this.GetValue(Client_Index);
		}
	}

	property int Flags {
		public get()
		{
			return this.GetValue(Client_Flags);
		}

		public set(const int flags)
		{
			this.SetValue(Client_Flags, flags);
		}
	}

	property float ActiveCooldown {
		public get()
		{
			return this.GetValue(Client_ActiveCooldown) - GetGameTime();
		}

		public set(const float time)
		{
			this.SetValue(Client_ActiveCooldown, time + GetGameTime());
		}
	}

	property float GetCoolTime {
		public get()
		{
			return this.GetValue(Client_GetCoolTime) - GetGameTime();
		}

		public set(const float cooltime)
		{
			this.SetValue(Client_GetCoolTime, cooltime + GetGameTime());
		}
	}

	property float Charge {
		public get()
		{
			return this.GetValue(Client_Charge);
		}

		public set(const float charge)
		{
			this.SetValue(Client_Charge, charge);
		}
	}

	property float MaxChargeDamage {
		public get()
		{
			return this.GetValue(Client_MaxChargeDamage);
		}

		public set(const float maxChargeDamage)
		{
			this.SetValue(Client_MaxChargeDamage, maxChargeDamage);
		}
	}

	property int MaxSlotCount {
		public get()
		{
			return this.GetValue(Client_MaxSlotCount);
		}

		public set(const int maxSlotCount)
		{
			CPClientPartSlot array = this.GetValue(Client_PartSlot);
			array.ResizeSlot(maxSlotCount);
			this.SetValue(Client_MaxSlotCount, maxSlotCount);
		}
	}

	property CPClientPartSlot PartSlot {
		public get()
		{
			return this.GetValue(Client_PartSlot);
		}
	}
}

/*
* 해당 슬롯의 파츠 값을 확인 함.
*
* @param client 클라이언트.
* @param slot 확인 할 슬롯
* @return 0은 그 슬롯이 비어있다는 것, 그 외에는 파츠 값.
*
*/
native int CP_GetClientPart(int client, int slot);

/*
* 해당 슬롯에 파츠 값을 부여 함.
*
* @param client 클라이언트.
* @param slot 부여할 슬롯
* @param value
* @noreturn
*
* 만약 slot이 플레이어의 최대 슬롯보다 클 경우에는 적용되지 않음.
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
* 플레이어의 슬롯을 새로 고침
*
* *** 중요 ***
*   - 슬롯 관련을 다루기 전에는 반드시 본 함수를 사용할 것.
*   - 만약 최대 슬롯을 건드리지 않았다면 굳이 이 함수를 쓰지 않아도 괜찮음.
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
* @param partIndex 확인할 파츠 값.
* @return 파츠가 유효할 경우 true.
*
*/
native bool CP_IsValidPart(int partIndex);

/*
* 해당 플레이어의 해당 슬롯이 유효한지 확인함.
*
* @param client 클라이언트
* @param slot  확인할 슬롯
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
*   해당 클라이언트의 슬롯 최대량을 구함.
*
*   @param client 구할 클라이언트
*   @return 그 클라이언트의 슬롯 값
*
*/
native int CP_GetClientMaxSlot(int client);

/*
*   해당 클라이언트의 슬롯 최대량을 구함.
*
*   @param client 정할 클라이언트
*   @param maxSlot 정할 슬롯크기
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
*   해당 클라이언트의 비어있는 슬롯을 찾음.
*
*   @param client 클라이언트
*   @return 비어있는 파츠 슬롯값을 반환함. 아닐경우 -1.
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

native int CP_RandomPart(int client, PartRank rank);

native PartRank CP_RandomPartRank(bool includeAnother=false);

native int CP_GetClientCPFlags(int client);

native void CP_SetClientCPFlags(int client, int flags);
/*
*
*
*
*/
forward Action CP_OnTouchedPartProp(int client, int &prop);

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
forward Action CP_OnGetPart(int client, int &prop, int &partIndex);

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
forward Action CP_PreActivePart(int client, int &partIndex);

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

/*
* 0.1초마다 호출됨.
*
*
*/
forward Action CP_OnActivedPartTime(int client, int partIndex, float &duration);
