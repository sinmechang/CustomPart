/*
||||****|||**||||**||||****|||*******|||||****|||||***|||||***|||||||||||||||
||**|||||||**||||**||***|||||||||*||||||**||||**|||**|*|||*|**|||||||||||||||
||**|||||||**||||**||||****||||||*||||||**||||**|||**||*|*||**|||||||||||||||
||||****||||******|||***|||||||||*||||||||****|||||**|||*|||**|||||||||||||||

|||||||||||||||||||||******||||||||*|||||****|||||*******||||||||||||||||||||
|||||||||||||||||||||**||||**|||||*|*||||**||**||||||*|||||||||||||||||||||||
|||||||||||||||||||||******||||||*****|||****||||||||*|||||||||||||||||||||||
|||||||||||||||||||||**|||||||||*||||*|||**||**||||||*|||||||||||||||||||||||

Core Plugin By Nopied◎
*/
 // TODO: config 파일 탐색 및 자료 반영.
#include <sourcemod>
#include <morecolors>

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

char g_strConfig[PLATFORM_MAX_PATH];

public Plugin:myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

public void OnPluginStart()
{
    LogMessage("Debug for CustomPart");

    RegConsoleCmd("custompart", Command_PartSystem, "");
    RegConsoleCmd("part", Command_PartSystem, "");

    LoadTranslations("custompart");
    LoadTranslations("common.phrases");
    LoadTranslations("core.phrases");
}

public Action Command_PartSystem(int client, int args)
{
     if (!IsValidClient(client)) return Plugin_Continue;

     char item[PLATFORM_MAX_PATH];
     Menu menu = new Menu(Command_PartSystemM);

     menu.SetTitle("%t", "part_menu_title");

     Format(item, sizeof(item), "%t", "part_menu_1");
     menu.AddItem("view who's part who called menu", item);
     Format(item, sizeof(item), "%t", "part_menu_2");
     menu.AddItem("shop", item);
     Format(item, sizeof(item), "%t", "part_menu_3");
     menu.AddItem("PartBackpack", item);
/*     Format(item, sizeof(item), "%t", "part_menu_4");
     menu.AddItem("ChangeLog", item); */
     SetMenuExitButton(menu, true);
     menu.Display(client, 90);

     return Plugin_Continue;
}

public int Command_PartSystemM(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_End:
        {
          CloseHandle(menu);
        }

        case MenuAction_Select:
        {
            switch(param2)
            {
              case 0:  // 플레이어의 파츠 설정
              {
                Player_Equip(param1);
              }
              case 1: // 상점
              {
                Player_Shop(param1);
              }
              case 2: // 보관함
              {
                 Player_Backpack(param1);
              }
    /*          case 3:  // 버전 패치 사항
              {
                 ChangeLog(param1);
              }
    */
            }
        }
    }
}

void Player_Equip(client)
{
    char item[PLATFORM_MAX_PATH];
    Menu menu = new Menu(Command_PlayerEquipM);

    menu.SetTitle("%t", "part_equip_title");
    Format(item, sizeof(item), "%t", "part_temp");
    menu.AddItem("....", item);
    SetMenuExitButton(menu, true);
    menu.Display(client, 90);
}

public int Command_PlayerEquipM(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_End:
        {
          CloseHandle(menu);
        }
    }
}

void Player_Shop(client)
{
    char item[PLATFORM_MAX_PATH];
    Menu menu = new Menu(Command_PlayerShopM);

    menu.SetTitle("%t", "part_shop_title");
    Format(item, sizeof(item), "%t", "part_temp");
    menu.AddItem("....", item);
    SetMenuExitButton(menu, true);
    menu.Display(client, 90);
}

public int Command_PlayerShopM(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_End:
        {
          CloseHandle(menu);
        }
    }
}

void Player_Backpack(int client)
{
    char item[PLATFORM_MAX_PATH];
    Menu menu = new Menu(Command_PlayerBackpackM);

    menu.SetTitle("%t", "part_backpack_title");
    Format(item, sizeof(item), "%t", "part_partbackpack");
    menu.AddItem("partbackpack.", item);
    Format(item, sizeof(item), "%t", "part_packagebackpack");
    menu.AddItem("packagebackpack.", item);
    SetMenuExitButton(menu, true);
    menu.Display(client, 90);
}

public int Command_PlayerBackpackM(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_End:
        {
          CloseHandle(menu);
        }
        case MenuAction_Select:
        {
            switch(param2)
            {
              case 0: // 파츠 보관함
              {
                  Player_PartBackpack(param1);
              }
              case 1: // 패키지 보관함
              {
                  Player_PackageBackpack(param1);
              }
            }
        }
    }
}

void Player_PartBackpack(int client)
{
    char item[PLATFORM_MAX_PATH];
    Menu menu = new Menu(Command_PlayerPartBackpackM);

    menu.SetTitle("%t", "part_partbackpack_title");
    Format(item, sizeof(item), "%t", "part_temp");
    menu.AddItem("....", item);
    SetMenuExitButton(menu, true);
    menu.Display(client, 90);
}

public int Command_PlayerPartBackpackM(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_End:
        {
          CloseHandle(menu);
        }
    }
}

void Player_PackageBackpack(int client)
{
    char item[PLATFORM_MAX_PATH];
    Menu menu = new Menu(Command_PlayerPackageBackpackM, MenuAction_Display);

    menu.SetTitle("%t", "part_partbackpack_title");
    Format(item, sizeof(item), "%t", "part_temp");
    menu.AddItem("....", item);
    SetMenuExitButton(menu, true);
    menu.Display(client, 90);
}

public int Command_PlayerPackageBackpackM(Menu menu, MenuAction action, int param1, int param2)
{
    switch(action)
    {
        case MenuAction_End:
        {
          CloseHandle(menu);
        }
    }
}

stock bool Cheak_ConfigFile()
{
    BuildPath(Path_SM, g_strConfig, sizeof(g_strConfig), "configs/custompart.cfg");
    if(!FileExists(config))
    {
        SetFailState("[CP] NO CFG FILE! (configs/custompart.cfg)");
        return false;
    }
    return true;
}

void Cheak_Parts()
{
    if(!Cheak_ConfigFile()) return;

    KeyValues kv = new KeyValues("custompart");

    if(kv.ImportFromFile(g_strConfig))
    {
        char keyitem[24];
        int rank_min = kv.GetNum("rank_min", 1);
        int rank_max = kv.GetNum("rank_max", 4);

        if(rank_min < 1)
        {
            rank_min=1;
            LogMessage("KeyValues의 \"rank_min\"은 반드시 1 이상으로 설정하셔야 됩니다.");
        }
        for (int i=rank_min; rank_min<=rank_max; i++)
        {
            Format(keyitem, sizeof(keyitem), "rankname_%d", i);

            kv.GetString(keyitem, g_strPartRankName[i], sizeof(g_strPartRankName[]), "");
        }

        kv.Rewind();
        g_iMaxPartCount=kv.GetNum("max_part_count", 200);
        g_iAbleSlot=kv.GetNum("able_slot", 0);

        if(g_iAbleSlot <= 0)
        {
            g_iAbleSlot=1;
            LogMessage("최소 1개 이상의 슬릇을 활성화 해야합니다.");
        }

        for (int i=1; i<=g_iMaxPartCount; i++)
        {
            Format(keyitem, sizeof(keyitem), "part%d", i);
            if(kv.JumpToKey(keyitem, false))
            {
                kv.GetString("name", g_strPartName[i], sizeof(g_strPartName[]), "");
                kv.GetString("description", g_strPartDescription[i], sizeof(g_strPartDescription[]), "");
                kv.GetString("ability_description", g_strPartAbliltyDescription[i], sizeof(g_strPartAbliltyDescription[]), "");

                g_bPartValid[i]=true;
                g_iPartRank[i]=Kv.GetNum("rank", -1);

                if(rank_min > g_iPartRank[i] || rank_max < g_iPartRank[i])
                {
                    g_bPartValid[i]=false;
                }
            }
            else
            {
                g_bPartValid[i]=false;
            }
        }
        CloseHandle(kv);
    }
}

static int Part()
{

}

stock bool IsValidClient(int client)
{
    return (0 < client && client < MaxClients && IsClientInGame(client));
}
