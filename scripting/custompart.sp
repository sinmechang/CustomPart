// TODO 1: PrintTo... 함수들을 로그 관련으로 교체할 것.

#include <sourcemod>
#include <clientprefs>

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

#define CHATCOMMAND_MAXLEN 20
#define CHATCOMMAND_STRING_MAXLEN 52



Handle g_hCvarChatCommand;
Handle g_hUserCookie;
Handle g_hUserEquipCookie;

char g_strChatCommand[CHATCOMMAND_MAXLEN][CHATCOMMAND_STRING_MAXLEN];
char g_strConfig[PLATFORM_MAX_PATH];

char[][] g_strPartName;
char[][] g_strPartDescription; // 의문: 동적 배열이 2차원에 먹히던가?
char[][] g_strPartAbliltyDescription;

bool[] g_bPartValid;

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

}

public void OnMapStart()
{
  Cheak_Parts();
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
