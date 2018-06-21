#if defined __custompart_cp_part_prop_included
	#endinput
#endif

#define __custompart_cp_part_prop_included

enum PartPropValueType
{
	PartProp_PropIndex,
	PartProp_Rank,
	PartProp_GlowIndex,
	PartProp_CustomPart,

	PartPropValue_Last
};

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
