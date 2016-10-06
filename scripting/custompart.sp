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

// #define TYPE_PART (1<<1);
// #define TYPE_PACKAGE (1<<2);

enum PartType
{
  TYPE_PART=0,
  TYPE_PACKAGE
};

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

Handle PartKV;
Handle cvarChatCommand;
Handle cvarMaxBackPack;

int g_iChatCommand=0;

int g_iMaxEnablePartCount;
int g_iMaxPartSlot=1;

int SelectedPackage[MAXPLAYERS+1];

public void OnPluginStart()
{
  cvarChatCommand = CreateConVar("cp_chatcommand", "파츠,part,스킬");
  cvarMaxBackPack = CreateConVar("cp_player_max_backpack", "30", "백팩 사이즈", _, true, 1.0);

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
	GetConVarString(cvarChatCommand, cvarV, sizeof(cvarV));

	for (int i=0; i<ExplodeString(cvarV, ",", g_strChatCommand, sizeof(g_strChatCommand), sizeof(g_strChatCommand[])); i++)
	{
		LogMessage("[CP] Added chat command: %s", g_strChatCommand[i]);
		g_iChatCommand++;
	}
}

public void OnClientPutInServer(int client)
{
    // int parts[g_iMaxEnablePartCount];
    // GetClientParts(client, parts);
    // SoftClientParts(client, parts);
    SoftClientParts(client);
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
        GetPartString(part, "name", item, sizeof(item));
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
    // Format(item, sizeof(item), "%t", "part_temp");
    // menu.AddItem("....", item);

    int packageCount=0;
    bool compilerNo = true; // LOLOLOLOL
    do
    {
        if(!IsValidPart(++packageCount, TYPE_PACKAGE))
            break;

        GetPartString(packageCount, "name", item, sizeof(item), TYPE_PACKAGE);
        menu.AddItem("....", item);
    }
    while(compilerNo);
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

        case MenuAction_Select:
        {
            ShowPackageInfo(client, item+1, true);
        }
    }
}

void ShowPackageInfo(int client, int packageIndex, bool viewInShop = false)
{
    SelectedPackage[client] = packageIndex;

    Menu menu = new Menu(ShowPackageInfoM);
    char item[600];
    char temp[200];

    GetPartString(packageIndex, "name", temp, sizeof(temp), TYPE_PACKAGE);
    Format(item, sizeof(item), "패키지 정보:\n -  이름: %s", temp);

    GetPartString(packageIndex, "description", temp, sizeof(temp), TYPE_PACKAGE);
    Format(item, sizeof(item), "%s\n - 설명: %s", item, temp);

    GetPartString(packageIndex, "ability_description", temp, sizeof(temp), TYPE_PACKAGE);
    Format(item, sizeof(item), "%s\n - 능력 설명: %s", item, temp);

    // GetPartString(packageIndex, "ability_description", temp, sizeof(temp), TYPE_PACKAGE);
    Format(item, sizeof(item), "%s\n - 가격: %d", item, GetPackageMoney(packageIndex));

    if(viewInShop)
    {
        Format(item, sizeof(item), "%s\n 구매할 시 현재 가지고 있는 머니에서 차감됩니다.\n계속하시겠습니까?", item);
        menu.AddItem("....", "네, 구매하겠습니다.");
    }
    menu.SetTitle(item);
    SetMenuExitButton(menu, true);
    menu.Display(client, 90);
}

public int ShowPackageInfoM(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
        case MenuAction_End:
        {
            CloseHandle(menu);
        }

        case MenuAction_Select:
        {
            int money = GetClientMoney(client);
            if(money >= GetPackageMoney(SelectedPackage[client]))
            {
                SetClientMoney(client, money - GetPackageMoney(SelectedPackage[client]))
                ChoosePackage(client, SelectedPackage[client]);
            }
            else
            {
                CPrintToChat(client, "{yellow}[CP]{default} "); // 머니 부족
            }
        }
    }
}

void ChoosePackage(int client, int packageIndex)
{
    char keyV[100][15]; // TODO: 커스터마이즈
    char temp[300];
    int partList[100];
    int count=0;

    GetPartString(packageIndex, "parts", temp, sizeof(temp), TYPE_PACKAGE);
    ExplodeString(temp, ";", keyV, 100, 15);

    while((partList[count] = StringToInt(partList[count])) > 0)
        count++;

    int random = GetRandomInt(0, count);

    // partList[random] is answer.

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

void Player_PartBackpack(int client, bool selectforslot = false)
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

int GetPackageMoney(int packageIndex)
{
    KvRewind(PartKV);

    char item[30];
    Format(item, sizeof(item), "package%i", packageIndex);

    KvJumpToKey(PartKV, item);
    return KvGetNum(PartKV, "money", 0);
}

int GetClientMoney(int client)
{
    char temp[50];
    Handle CustomPartCookie = RegClientCookie("custompart_money", "?", CookieAccess_Protected);

    GetClientCookie(client, CustomPartCookie, temp, sizeof(temp));
    return StringToInt(temp);
}

void SetClientMoney(int client, int money)
{
    char temp[50];
    Handle CustomPartCookie = RegClientCookie("custompart_money", "?", CookieAccess_Protected);

    Format(temp, sizeof(temp), "%i", money);
    SetClientCookie(client, CustomPartCookie, temp);
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

public bool GetPartString(int partIndex, const char[] name, char[] partStr, int buffer, PartType type = TYPE_PART)
{
    if(!IsValidPart(partIndex, type)) // TODO: IS THIS NEEDED???
    {
      Format(name, buffer, "");
      return false;
    }

    char item[50];
    Format(temp, sizeof(temp), "%s%i", type == TYPE_PACKAGE ? "package" : "part", partIndex);

    KvRewind(PartKV);

    KvJumpToKey(PartKV, item);
    KvGetString(PartKV, name, partStr, buffer);

    return true;
}

void

public int GetClientParts(int client, int[] parts)
{
  char temp[50];
  Handle CustomPartCookie;
  int partIndex;

  int backpackSize;
  for(backpackSize=0; backpackSize < sizeof(parts); backpackSize++)
  {
    Format(temp, sizeof(temp), "custompart_backpack_%i", backpackSize);
    CustomPartCookie = RegClientCookie(temp, "?", CookieAccess_Protected);

    GetClientCookie(client, CustomPartCookie, temp, sizeof(temp));
    partIndex = StringToInt(temp);

    parts[backpackSize] = partIndex;
/*
    if(!IsValidPart(partIndex))
        break;
*/
  }

  return backpackSize;
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

public void SoftClientParts(int client)
{
    int parts[GetClientPartCount(client)];
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

    SetClientParts(client, parts);
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

int GetClientBackpackAdditionalSize(int client)
{
    Handle CustomPartCookie = RegClientCookie("custompart_backpacksize", "?", CookieAccess_Protected);
    char temp[20];
    GetClientCookie(client, CustomPartCookie, temp, sizeof(temp));

    return StringToInt(temp);
}

void SetClientBackpackAdditionalSize(int client, int size)
{
    Handle CustomPartCookie = RegClientCookie("custompart_backpacksize", "?", CookieAccess_Protected);
    char temp[20];

    Format(temp, sizeof(temp), "%i", size);
    SetClientCookie(client, CustomPartCookie, temp);
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

bool IsValidPart(int partIndex, PartType type = TYPE_PART)
{
    KvRewind(PartKV);

    char temp[30];
    Format(temp, sizeof(temp), "%s%i", type == TYPE_PACKAGE ? "package" : "part", partIndex);

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
  g_iMaxEnablePartCount = 0;

  char key[30];
  do
  {
      Format(key, sizeof(key), "part%i", ++g_iMaxEnablePartCount); // TODO: Make sure g_iMaxEnablePartCount.....
  }
  while(KvJumpToKey(PartKV, key));
}

stock bool IsValidClient(client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
}
