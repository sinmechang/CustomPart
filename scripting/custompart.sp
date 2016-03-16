// TODO 1: PrintTo... 함수들을 로그 관련으로 교체할 것.

#include <sourcemod>
#include <clientprefs>

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

#define CHATCOMMAND_MAXLEN 20
#define STRING_MAXLEN 52

Handle g_hKeyValue;
Handle g_hCvarChatCommand;
Handle g_hUserCookie;
Handle g_hUserEquipCookie;

char g_strChatCommand[CHATCOMMAND_MAXLEN][STRING_MAXLEN];
char g_strConfig[PLATFORM_MAX_PATH];

int[] g_iPart;
/*
enum Equip
{

};
*/

public Plugin:myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

public void OnPluginStart()
{
  PrintToServer("Starting up CUSTOMPART..."); // TODO 1
  if(!Cheak_ConfigFile())
  {
    SetFailState("[CP] NO CFG FILE! (configs/custompart.cfg)");
  }
  Cheak_Parts();

  g_hCvarChatCommand=CreateConVar("custompart_chatcommand", "custompart,part,파츠,커스텀파츠,스킬");
}

public void OnMapStart()
{
  if(Cheak_ConfigFile()) Cheak_Parts();
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
  // 사용하려는 게임을 체크해야함
}

void Cheak_Parts() // 본 함수는 반드시 g_strConfig이 등록되고 나서 사용할 것.
{
  g_hKeyValue = CreateKeyValue("custompart");

  if(FileToKeyValues(g_hKeyValue, g_strConfig))
  {
    KvRewind(g_hKeyValue);
    if(KvGotoFirstSubKey(g_hKeyValue))
    {
      do
      {
        char keyitem[PLATFORM_MAX_PATH];

      }
      while(KvGotoNextKey(g_hKeyValue))
    }
}
