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
int g_iMaxPartSlot=1;

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

void Player_Equip(int client)
{
    char item[PLATFORM_MAX_PATH];
    Menu menu = new Menu(Command_PlayerEquipM);

    menu.SetTitle("%t", "part_equip_title");
    for(int slot=0; slot<g_iMaxPartSlot; slot++)
    {
      int part = GetClientPartSlot(client, slot);

      if(IsValidPart(part))
      {
        GetPartNameString(part, item, sizeof(item));
        menu.AddItem("....", item);
      }
      else if(GetClientPartSlotCooldownTime(client, slot) > GetTime()) // TODO: 파츠 슬릇 쿨다운
      {
        int time = GetClientPartSlotCooldownTime(client, slot) - GetTime();
        int min = time / 60;
        int hour = min / 60;

        Format(item, sizeof(item), "%t", "part_slot_overloaded", hour, min, time % 60);
        menu.AddItem("....", item, ITEMDRAW_DISABLED);
      }
      else
      {
        SetClientPartSlotCooldownTime(client, slot, 0); // 혹시 모르니 값 초기화
        Format(item, sizeof(item), "%t", "part_slot_none");
        menu.AddItem("....", item);
      }
    }
    // Format(item, sizeof(item), "%t", "part_temp");
    // menu.AddItem("....", item);
    SetMenuExitButton(menu, true);
    menu.Display(client, 90);
}

public int Command_PlayerEquipM(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
        case MenuAction_End:
        {
          CloseHandle(menu);
        }

        case MenuAction_Select:
        {
          int part = GetClientPartSlot(client, item);

          if(IsValidPart(part)) // 파츠 제거 후 과부하.
          {
            SetClientPartSlotCooldownTime(client, item, 180);
            SetClientPartSlot(client, item, 0);
            // 메세지
          }
          else // 파츠 선택
          {

          }
        }
    }
}

void Player_Shop(int client)
{
    char item[PLATFORM_MAX_PATH];
    Menu menu = new Menu(Command_PlayerShopM);

    menu.SetTitle("%t", "part_shop_title");
    Format(item, sizeof(item), "%t", "part_temp");
    menu.AddItem("....", item);
    SetMenuExitButton(menu, true);
    menu.Display(client, 90);
}

public int Command_PlayerShopM(Menu menu, MenuAction action, int client, int item)
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

public int Command_PlayerBackpackM(Menu menu, MenuAction action, int client, int item)
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

int GetClientPartSlot(int client, int slot)
{
    if(g_iMaxPartSlot >= slot || slot < 0)
      return 0;

    char temp[50];
    Format(temp, sizeof(temp), "custompart_slot_%i", slot);

    Handle CustomPartCookie = RegClientCookie(temp, "?", CookieAccess_Protected);
    GetClientCookie(client, CustomPartCookie, temp, sizeof(temp));

    return StringToInt(temp);
}

void SetClientPartSlot(int client, int slot, int partIndex)
{
  char temp[50];
  Format(temp, sizeof(temp), "custompart_slot_%i", slot);

  Handle CustomPartCookie = RegClientCookie(temp, "?", CookieAccess_Protected);
  Format(temp, sizeof(temp), "%i", slot);

  SetClientCookie(client, CustomPartCookie, temp);
}

public void GetPartNameString(int partIndex, char[] name, int buffer)
{
  if(!IsValidPart(partIndex)) // TODO: IS THIS NEEDED???
  {
    Format(name, buffer, "");
    return;
  }

  char item[20];
  Format(item, sizeof(item), "part%i", partIndex);

  KvRewind(PartKV);

  KvJumpToKey(PartKV, item);
  KvGetString(PartKV, "name", name, buffer);
}

public void GetClientParts(int client, int[] parts)
{
  char temp[50];
  Handle CustomPartCookie;
  int partIndex;

  for(int backpackSize=0; backpackSize < sizeof(parts); backpackSize++)
  {
    Format(temp, sizeof(temp), "custompart_backpack_%i", backpackSize);
    CustomPartCookie = RegClientCookie(temp, "?", CookieAccess_Protected);

    GetClientCookie(client, CustomPartCookie, temp, sizeof(temp));
    partIndex = StringToInt(temp);

    // TODO: 삭제되거나 유효하지 않은 파츠일 경우 삭제처리 그리고 백팩 정렬
    // if()

    parts[backpackSize] = partIndex;
  }
}

int GetClientPartCount(int client)
{
    char temp[50];
    Handle CustomPartCookie;

    for(int backpackSize=0; ; backpackSize++)
    {
        Format(temp, sizeof(temp), "custompart_backpack_%i", backpackSize);
        CustomPartCookie = RegClientCookie(temp, "?", CookieAccess_Protected);

        GetClientCookie(client, CustomPartCookie, temp, sizeof(temp));

        if(StringToInt(temp) <= 0)
            return backpackSize;
    }

    return -1;
}

public void SoftClientParts(int client, int[] parts)
{
    int tempParts[sizeof(parts)]; // TODO: IS THIS NEEDED!?!?!?!?
    int notValidParts[sizeof(parts)];
    int notValidCount=0;

    for(int ser=0; ser < sizeof(parts); ser++)
    {
        tempParts[ser] = parts[ser];

        if(!IsValidPart(parts[ser]))
        {
            notValidParts[notValidCount++] = ser;
        }
    }

    for(int cou = 0; cou < notValidCount; cou++)
    {
        for(int ser = notValidParts[cou]; ser < sizeof(parts); ser++)
        {
            if(ser+1 < 0 || ser+1 >= sizeof(parts))
                continue;

            if(IsValidPart(parts[ser+1]))
                tempParts[ser] = parts[ser+1];
        }
    }

    for(int ser=0; ser < sizeof(parts); ser++)
    {
        parts[ser] = tempParts[ser];
    }
}

void SetClientParts(int client, int[] parts)
{
  char temp[50];
  Handle CustomPartCookie;

  for(int backpackSize=0; backpackSize < sizeof(parts); backpackSize++)
  {
    Format(temp, sizeof(temp), "custompart_backpack_%i", backpackSize);
    CustomPartCookie = RegClientCookie(temp, "?", CookieAccess_Protected);

    Format(temp, sizeof(temp), "%i", parts[backpackSize]);
    SetClientCookie(client, CustomPartCookie, temp);
  }
}

int GetClientPartSlotCooldownTime(int client, int slot)
{
  char temp[75];
  Format(temp, sizeof(temp), "custompart_slot_cooldown_%i", slot);

  Handle CustomPartCookie = RegClientCookie(temp, "?", CookieAccess_Protected);
  GetClientCookie(client, CustomPartCookie, temp, sizeof(temp));

  return StringToInt(temp);
}

void SetClientPartSlotCooldownTime(int client, int slot, int min)
{
  char temp[75];
  Format(temp, sizeof(temp), "custompart_slot_cooldown_%i", slot);

  Handle CustomPartCookie = RegClientCookie(temp, "?", CookieAccess_Protected);
  if(min>0)
    Format(temp, sizeof(temp), "%i", GetTime()+(min*60));
  else
    temp = "";

  SetClientCookie(client, CustomPartCookie, temp);
}

bool IsValidPart(int partIndex)
{
    KvRewind(PartKV);

    char temp[30];
    Format(temp, sizeof(temp), "%i", partIndex);

    if(KvJumpToKey(PartKV, temp))
        return true;

    return false;
}

void CheckPartConfigFile()
{
  if(PartKV != INVALID_HANDLE)
  {
    CloseHandle(PartKV);
    PartKV = INVALID_HANDLE;
  }

  //

  //

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
  g_iMaxPartSlot = KvGetNum(PartKV, "able_slot", 2);
}

stock bool IsValidClient(client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
}
