#if defined __custompart_cp_part_included
	#endinput
#endif

#define __custompart_cp_part_included

enum PartValueType
{
	Part_PartIndex,
	Part_ParentIndex,
	Part_Flags,
	Part_KeyValues,
	Part_Duration,
	Part_DurationMax,
	Part_Active,

	PartValue_Last
};

methodmap CPPart < ArrayList {
	public CPPart(int partIndex)
	{
		CPPart array = view_as<CPPart>(new ArrayList(64, PartValue_Last));

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

	public CPPart KillSelf(bool force = false) // 강제로 제거는 킬 이벤트를 생략함.
	{
		if(!force)
		{
			Forward_OnSlotClear(this.Parent, this.Index);

			if(part.Duration > 0.0)
			{
				Forward_OnActivedPartEnd(client, partIndex);
			}
		}

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

	property int Parent {
		public get()
		{
			return this.GetValue(Part_ParentIndex);
		}
		public set(int index)
		{
			this.SetValue(Part_ParentIndex, index);
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

    property CPConfigKeyValues KeyValue {
		public get()
		{
			return this.GetValue(Part_KeyValues);
		}
		public set(CPConfigKeyValues kv)
		{
			this.SetValue(Part_KeyValues, kv);
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
