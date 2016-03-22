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


// TODO 1: PrintTo... 함수들을 로그 관련으로 교체할 것.

#include <sourcemod>
#include <clientprefs>
#include <morecolors>

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

#define DEBUG true

#define CHATCOMMAND_MAXLEN 20
#define STRING_MAXLEN 52


// 광역 변수 중에 동적 배열 선언한 것은 에러일으킬 각이긴 한데. 일단 실험용임.

Handle g_hCvarChatCommand;
Handle g_hUserCookie;
Handle g_hUserEquipCookie;
Handle g_hUserCooldownCookie;
// g_hUserCooldownCookie의 경우.
// "(1번 슬릇);(2번 슬릇);(3번 슬릇)과 같이 형식을 지킬것."

char g_strChatCommand[CHATCOMMAND_MAXLEN][STRING_MAXLEN];
char g_strConfig[PLATFORM_MAX_PATH];

char[][] g_strPartName;
char[][] g_strPartRankName;
char[][] g_strPartDescription; // 의문: 동적 배열이 2차원에 먹히던가?
char[][] g_strPartAbliltyDescription;
char[][] g_strClientInventory

bool[] g_bPartValid={false, ...};
bool g_bCashedCookie[MAXPLAYERS+1]={false, ...};

int g_iAbleSlot;
int g_iMaxPartCount;
int[] g_iPartRank;
int g_iClientPackage[MAXPLAYERS+1][];
int g_iClientPart[MAXPLAYERS+1][];
int g_iClientEquipPart[MAXPLAYERS+1][];
int g_iClientPartCooldown[MAXPLAYERS+1][]; // 이것은 서버에 접속을 하고 플레이를 해야만 카운트되도록 설계

public Plugin:myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

public void OnPluginStart()
{
  PrintToServer("Starting up CUSTOMPART..."); // TODO 1

  Cheak_Parts();

  g_hCvarChatCommand=CreateConVar("custompart_chatcommand", "custompart,part,파츠,커스텀파츠,스킬"); // TODO 채팅 트리거 작업
  g_hUserCookie=RegClientCookie("Custompart_usercookie", "YupYup", CookieAccess_Public);
  g_hUserEquipCookie=RegClientCookie("Custompart_userequipcookie", "YUP, YUP", CookieAccess_Public);
  g_hUserCooldownCookie=RegClientCookie("Custompart_usercooldowncookie", "YUP YUP YUP", CookieAccess_Public);

  RegConsoleCmd("part", Command_PartSystem);
  RegConsoleCmd("custompart", Command_PartSystem);

  LoadTranslations("custompart");
  LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
}

public Action Command_PartSystem(int client, int args)
{
  if (!IsValidClient(client)) return Plugin_Continue;
  if (!g_bCashedCookie[client])
  {
    CPrintToChat(client, "%t %t", "CP_tag", "Cookie_not_cashed");
    return Plugin_Continue;
  }

  char item[PLATFORM_MAX_PATH];
  Menu menu = new Menu(Command_PartSystemM);

  menu.SetTitle("%t", "part_menu_title");

  Format(item, sizeof(item), "%t", "part_menu_1");
  menu.AddItem("view who's part who called menu", item);
  Format(item, sizeof(item), "%t", "part_menu_2");
  menu.AddItem("shop", item);
  Format(item, sizeof(item), "%t", "part_menu_3");
  menu.AddItem("PartBackpack", item);
  Format(item, sizeof(item), "%t", "part_menu_4");
  menu.AddItem("ChangeLog", item);
  SetMenuExitButton(menu, true);

  menu.Display(client, 90);

  return Plugin_Handled;
}

public Command_PartSystemM(Menu menu, MenuAction action, int param1, int param2)
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
        case 0: // 플레이어의 파츠 설정
        {
          Player_Equip(param1);
        }
        case 1: // 상점
        {
          Player_Shop(param1);
        }
        case 2: // 보관함
        {
          Player_PartBackpack(param1);
        }
        case 3:
        {
          Player_PackageBackpack(param1);
        }
        case 4: // 버전 패치 사항
        {
          ChangeLog(param1);
        }
      }
    }
  }
}

void Player_Equip(int client)
{
  char item[PLATFORM_MAX_PATH];
  Menu menu = new Menu(Player_EquipM);
  menu.SetTitle("%t", "part_equip_title");

  for(int i=0; i<=g_iAbleSlot; i++)
  {
    Format(item, sizeof(item), "%t", "part_equip_menu", i); //?????
    menu.AddItem("slot_menu", item);
  }
  SetMenuExitButton(menu, true);

  menu.Display(client, 90);
}

void Player_EquipM(Menu menu, MenuAction action, int param1, int param2)
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
        case 0:
        {
          /* code */
        }
      }
    }
  }
}

void Player_Shop(int client)
{

}

void Player_PartBackpack(int client)
{

}

void Player_PackageBackpack(int client)
{

}

public void OnMapStart()
{
  Cheak_Parts();
}


public void OnClientCookiesCached(int client)
{
  char item[STRING_MAXLEN][STRING_MAXLEN];
  char CookieV[PLATFORM_MAX_PATH];
  int nbase;

  g_bCashedCookie[client]=true;
  GetClientCookie(g_hUserCookie, CookieV, sizeof(CookieV));

  for (int i=0; i<=ExplodeString(CookieV, ",", item, sizeof(item), sizeof(item[])); i++)
  {
    StringToInt(item[i], nbase);
    if(nbase != 0)
    {
      if(g_bPartValid[nbase]) g_iClientPart[client][i]=nbase;
      else // TODO: 동일한 등급의 파츠 패키지를 줘야함.
      {

      }
    }
  }
  GetClientCookie(g_hUserEquipCookie, CookieV, sizeof(CookieV));

  for (int i=0; i<=ExplodeString(CookieV, ",", item, sizeof(item), sizeof(item[])); i++)
  {
    StringToInt(item[i], nbase);
    if(nbase != 0) // TODO:
    {
      if(g_bPartValid[nbase]) g_iClientEquipPart[client][i]=nbase;
      else // TODO: 이것같은 경우는 슬릇을 비워놓고 동일한 등급의 파츠 패키지를 줘야함
      {

      }
    }
  }
  GetClientCookie(g_hUserCooldownCookie, CookieV, sizeof(CookieV));
  StringToInt(CookieV, g_iClientPartCooldown[client]);
}

public void OnClientDisconnect(int client)
{
  g_bCashedCookie[client]=false;
}

void Cheak_Parts() // 본 함수는 반드시 g_strConfig이 등록되고 나서 사용할 것.
{
  if(!Cheak_ConfigFile()) return;
  g_bPartValid[]={false, ...};


  KeyValues kv = new KeyValues("custompart");

  if(kv.ImportFromFile(g_strConfig))
  {
    char keyitem[PLATFORM_MAX_PATH];
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
          if(DEBUG) LogMessage("선택한 %d는 rank_min 혹은 rank_max와 유효한 범위 내에 있지 않음.", i);
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

stock bool IsValidClient(int client)
{
    return (0 < client && client < MaxClients && IsClientInGame(client));
}
