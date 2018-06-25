#if defined __custompart_cp_client_included
	#endinput
#endif

#define __custompart_cp_client_included

enum SlotValueType
{
	Slot_SlotIndex,
	Slot_PartIndex,

	SlotValue_Last
};

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
			insideArray.KillSelf(true);
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

	public void RefrashSlot(bool force = false)
	{
		CPPart part;

		for(int loop = 0; loop < array.Length; loop++)
		{
			part = this.GetPart(loop);

			if(part != null)
			{
				part.KillSelf();
			}
		}
	}

	public int FindActiveSlot() // TODO: bool startAtBack = false
	{
		CPPart value;

		for(int loop = 0; loop < this.Length; loop++)
		{
			value = this.GetPart(loop);

			if(value != null)
				return i;
		}
		return -1;
	}
}

///
///
///


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

    public void AddPartCharge(float charge)
    {
        this.Charge += charge;

        if(this.Charge > 100.0)
            this.Charge = 100.0;
        else if(this.Charge < 0.0)
            this.Charge = 0.0;
    }

	public bool IsValidSlot(int client, int slot)
	{
		if(this.MaxSlotCount > slot
			&& ((this.PartSlot != null) && (this.PartSlot).Length > slot)
			&& slot >= 0)
			return true;

		return false;
	}
}
