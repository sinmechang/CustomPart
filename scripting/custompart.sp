// TODO 1: PrintTo... 함수들을 로그 관련으로 교체할 것.

#include <sourcemod>
#include <clientprefs>
#include <morecolors>

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

#define DEBUG true

#define CHATCOMMAND_MAXLEN 20
#define STRING_MAXLEN 52

Handle g_hCvarChatCommand;
Handle g_hUserCookie;
Handle g_hUserEquipCookie;

char g_strChatCommand[CHATCOMMAND_MAXLEN][STRING_MAXLEN];
char g_strConfig[PLATFORM_MAX_PATH];

char[][] g_strPartName;
char[][] g_strPartDescription; // 의문: 동적 배열이 2차원에 먹히던가?
char[][] g_strPartAbliltyDescription;

bool[] g_bPartValid={false, ...};
bool g_bCashedCookie[MAXPLAYERS+1]={false, ...};

int g_iClientPart[MAXPLAYERS+1][];

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
  menu.AddItem("Backpack", item);


}

public void OnMapStart()
{
  Cheak_Parts();
}


public void OnClientCookiesCached(int client)
{
  g_bCashedCookie[client]=true;
}

public void OnClientDisconnect(int client)
{
  g_bCashedCookie[client]=false;
}

void Cheak_Parts() // 본 함수는 반드시 g_strConfig이 등록되고 나서 사용할 것.
{
  if(!Cheak_ConfigFile()) return;

  KeyValues kv = new KeyValues("custompart");

  if(kv.ImportFromFile(g_strConfig))
  {
    // char selection[PLATFORM_MAX_PATH];
    char keyitem[PLATFORM_MAX_PATH];

    kv.Rewind();

    for (int i=1; i<=kv.GetNum("max_part_count", 200); i++)
    {
      Format(keyitem, sizeof(keyitem), "part%d", i);
      if(kv.JumpToKey(keyitem, false))
      {
        kv.GetString("name", g_strPartName[i], sizeof(g_strPartName[]), "");
        kv.GetString("description", g_strPartDescription[i], sizeof(g_strPartDescription[]), "");
        kv.GetString("ability_description", g_strPartAbliltyDescription[i], sizeof(g_strPartAbliltyDescription[]), "");

        g_bPartValid[i] = true;
      }

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

stock bool IsValidClient(int client)
{
    return (0 < client && client < MaxClients && IsClientInGame(client));
}
