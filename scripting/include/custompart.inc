#if defined _custompart_included
 #endinput
#endif
#define _custompart_included

enum PartRank
{
    Rank_None=-1,
    Rank_Normal=0,
    Rank_Rare,
    Rank_Hero,
    Rank_Legend,
    Rank_Another,
    Rank_Raindow
};

methodmap CustomPartProp
{
    public CustomPartProp(int entity, int partIndex, PartRank rank, int parentIndex = 0)
    {
        return this;
    }

    property int partIndex
    {
        public get()
        {

        }
        public set()
        {

        }
    }
    property int parentIndex
    {
        public get()
        {

        }
        public set()
        {

        }
    }
    property int entIndex
    {
        public get()
        {

        }
        public set()
        {

        }
    }
    property PartRank partRank
    {
        public get()
        {

        }
        public set()
        {

        }
    }
}
