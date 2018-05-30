void ViewPartBook(int client)
{
    Menu menu = new Menu(OnSelectedBook);

    menu.SetTitle("등급별로 파츠를 보실 수 있습니다.\n무엇을 보실건가요?");

    menu.AddItem("일반", "일반 등급");
    menu.AddItem("희귀", "희귀 등급");
    menu.AddItem("영웅", "영웅 등급");
    menu.AddItem("전설", "전설 등급");
    menu.AddItem("어나더", "어나더 등급");

    menu.ExitButton = true;

    menu.Display(client, 40);
}

public int OnSelectedBook(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
      case MenuAction_Select:
      {
          SelectedBookRank[client] = view_as<PartRank>(item)
          LastSelectedSlot[client] = 0;
          ViewPartBookItem(client, SelectedBookRank[client], LastSelectedSlot[client]);
      }
    }
}

void ViewPartBookItem(int client, PartRank rank, int pos)
{
    char item[500];
    char tempItem[200];

    int count = GetValidPartCount(rank);
    int[] partArray = new int[count]
    GetValidPartArray(rank, partArray, count);

    int part = partArray[pos];

    Menu menu = new Menu(OnSelectedBookItem);

    GetPartString(part, "name", tempItem, sizeof(tempItem));
    Format(item, sizeof(item), "이름: %s", tempItem);
    // menu.AddItem("name", item, ITEMDRAW_DISABLED);

    GetPartString(part, "description", tempItem, sizeof(tempItem));
    Format(item, sizeof(item), "%s\n\n설명: %s", item, tempItem);
    // menu.AddItem("description", item, ITEMDRAW_DISABLED);

    GetPartString(part, "ability_description", tempItem, sizeof(tempItem));
    Format(item, sizeof(item), "%s\n\n능력 설명: %s", item, tempItem);
    // menu.AddItem("ability_description", item, ITEMDRAW_DISABLED);

    GetPartString(part, "idea_owner_nickname", tempItem, sizeof(tempItem));
    if(tempItem[0] != '\0') Format(item, sizeof(item), "%s\n\n아이디어 제공: %s\n\n", item, tempItem);
    else Format(item, sizeof(item), "%s\n\nPOTRY SERVER ORIGINAL CUSTOMPART\n\n", item);
    // menu.AddItem("idea_owner_nickname", item, ITEMDRAW_DISABLED);

    menu.SetTitle(item);

    int itemFlags;
    if(pos - 1 >= 0)
        Format(item, sizeof(item), "이전으로");
    else
    {
        itemFlags = ITEMDRAW_DISABLED;
        Format(item, sizeof(item), "이전 파츠가 없습니다.");
    }
    menu.AddItem("older", item, itemFlags);

    itemFlags = 0;

    if(pos + 1 < count)
        Format(item, sizeof(item), "다음으로");
    else
    {
        itemFlags = ITEMDRAW_DISABLED;
        Format(item, sizeof(item), "다음 파츠가 없습니다.");
    }
    menu.AddItem("newer", item, itemFlags);

    menu.ExitButton = true;
    menu.Display(client, 40);
}

public int OnSelectedBookItem(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
      case MenuAction_Select:
      {
          switch(item)
          {
              case 0:
              {
                ViewPartBookItem(client, SelectedBookRank[client], --LastSelectedSlot[client]);
              }
              case 1:
              {
                ViewPartBookItem(client, SelectedBookRank[client], ++LastSelectedSlot[client]);
              }
          }
      }
    }
}

void ViewPart(int client, int partIndex)
{
    if(IsValidPart(partIndex))
    {
        char item[300];
        char tempItem[200];

        GetPartString(partIndex, "name", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "방금 흭득한 파츠: %s", tempItem);

        GetPartString(partIndex, "ability_description", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n능력 설명: %s", item, tempItem);

        GetPartString(partIndex, "idea_owner_nickname", tempItem, sizeof(tempItem));
        if(tempItem[0] != '\0')
            Format(item, sizeof(item), "%s\n아이디어 제공자: %s", item, tempItem);
        else
            Format(item, sizeof(item), "%s\nPOTRY SERVER ORIGINAL CUSTOMPART", item);

        PrintHintText(client, item);
    }
}

void ViewSlotPart(int client, int slot=0)
{
    if(IsValidSlot(client, slot))
    {
        int part;

        if(!IsValidPart((part = GetClientPart(client, slot))))
            part = INVALID_PARTID;

        char item[500];
        char tempItem[200];
        Menu menu = new Menu(OnSelectedSlotItem);
        // menu.SetTitle("현재 파츠: (슬릇: %i / %i)", slot+1, MaxPartSlot[client]);
        Format(item, sizeof(item), "현재 파츠: (슬릇: %i / %i)", slot+1, MaxPartSlot[client]);

        GetPartString(part, "name", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n\n이름: %s", item, tempItem);
        // menu.AddItem("name", item, ITEMDRAW_DISABLED);

        GetPartString(part, "description", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n\n설명: %s", item, tempItem);
        // menu.AddItem("description", item, ITEMDRAW_DISABLED);

        GetPartString(part, "ability_description", tempItem, sizeof(tempItem));
        Format(item, sizeof(item), "%s\n\n능력 설명: %s", item, tempItem);
        // menu.AddItem("ability_description", item, ITEMDRAW_DISABLED);

        GetPartString(part, "idea_owner_nickname", tempItem, sizeof(tempItem));
        if(tempItem[0] != '\0') Format(item, sizeof(item), "%s\n\n아이디어 제공: %s\n\n", item, tempItem);
        else Format(item, sizeof(item), "%s\n\nPOTRY SERVER ORIGINAL CUSTOMPART\n\n", item);
        // menu.AddItem("idea_owner_nickname", item, ITEMDRAW_DISABLED);

        menu.SetTitle(item);

        int itemFlags;
        if(slot - 1 >= 0)
            Format(item, sizeof(item), "이전 슬릇으로");
        else
        {
            itemFlags = ITEMDRAW_DISABLED;
            Format(item, sizeof(item), "이전 슬릇이 없습니다.");
        }
        menu.AddItem("older", item, itemFlags);

        itemFlags = 0;

        if(slot + 1 < MaxPartSlot[client])
            Format(item, sizeof(item), "다음 슬릇으로");
        else
        {
            itemFlags = ITEMDRAW_DISABLED;
            Format(item, sizeof(item), "다음 슬릇이 없습니다.");
        }
        menu.AddItem("newer", item, itemFlags);
        menu.ExitButton = true;

        LastSelectedSlot[client] = slot;

        menu.Display(client, 40);
    }
}

public int OnSelectedSlotItem(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
      case MenuAction_Select:
      {
          RefrashPartSlotArray(client, true, true);
          switch(item)
          {
              case 0:
              {
                ViewSlotPart(client, --LastSelectedSlot[client]);
              }
              case 1:
              {
                ViewSlotPart(client, ++LastSelectedSlot[client]);
              }
          }
      }
    }
}

public int OnSelected(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
    }
}
