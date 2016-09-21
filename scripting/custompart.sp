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

#include <sourcemod>
#include <clientprefs>
#include <morecolors>

#define PLUGIN_NAME "CustomPart Core"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

Handle PartKV;
Handle g_hCvarChatCommand;

int g_iChatCommand=0;

public void OnPluginStart()
{
  g_hCvarChatCommand = CreateConVar("cp_chatcommand", "파츠,part,스킬");

  AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");

  CheckPartConfigFile();

  LoadTranslations("custompart");
  LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
}

public void OnMapStart()
{
	ChangeChatCommand();
  CheckPartConfigFile();
}

void ChangeChatCommand()
{
	g_iChatCommand = 0;

	char cvarV[100];
	GetConVarString(g_hCvarChatCommand, cvarV, sizeof(cvarV));

	for (int i=0; i<ExplodeString(cvarV, ",", g_strChatCommand, sizeof(g_strChatCommand), sizeof(g_strChatCommand[])); i++)
	{
		LogMessage("[CP] Added chat command: %s", g_strChatCommand[i]);
		g_iChatCommand++;
	}
}

public Action Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client)) return Plugin_Continue;

	char strChat[100];
	char temp[2][64];
	GetCmdArgString(strChat, sizeof(strChat));

	int start;

	if(strChat[start] == '"') start++;
	if(strChat[start] == '!' || strChat[start] == '/') start++;
	strChat[strlen(strChat)-1] = '\0';
	ExplodeString(strChat[start], " ", temp, 2, 64, true);

	for (int i=0; i<=g_iChatCommand; i++)
	{
		if(StrEqual(temp[0], g_strChatCommand[i], true))
		{
			if(temp[1][0] != '\0')
			{
				return Plugin_Handled;
			}

			ViewPartMenu(client);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

void ViewPartMenu(int client)
{
  Handle menu = 
}

void CheckPartConfigFile()
{
  if(PartKV != INVALID_HANDLE)
  {
    CloseHandle(PartKV);
    PartKV = INVALID_HANDLE;
  }

  char config[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, config, sizeof(config), "configs/custompart.cfg");

  if(!FileExists(config))
  {
      SetFailState("[CP] NO CFG FILE! (configs/custompart.cfg)");
      return;
  }

  PartKV = CreateKeyValues("CustomPart");

  if(!FileToKeyValues(PartKV, config))
  {
    SetFailState("[CP] configs/custompart.cfg is broken?!");
  }
  KvRewind(PartKV);
}

stock bool IsValidClient(client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
}
