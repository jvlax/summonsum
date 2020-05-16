local frame = summonsumFrame or CreateFrame("FRAME", "summonsumFrame")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("ADDON_LOADED")

-- soulshard id = 6265
-- ritual of summoning id = 698
local function shardCount()
  local n = 0;
  for i = 0, 4 do
    for j = 1, 20 do
      item = GetContainerItemID(i, j);
      if item == 6265 then
        n = n + 1;
      end
    end
  end
  n = n -1;
  local shardGrammar = "soulshards"
  if n == 1 then
    shardGrammar = "soulshard"
  end
  return n .. " " .. shardGrammar
end

local function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

local function sendSSMessage(spell, channel)
  if spell == "summon" then
    for message = 1, #ssMenuList do
      if ssMenuList[message].checked == true then
        local selectedMessage = ssMenuList[message].text
        if selectedMessage == "Random" then
          randomMessage = math.random(2, #ssMenuList)
          selectedMessage = ssMenuList[randomMessage].text
        end
          local message = string.gsub(selectedMessage, "<shards>", shardCount())
          message = string.gsub(message, "<target>", UnitName("target"))
          SendChatMessage(message, channel, nil, nil)
          lazyList[UnitName("target")] = (lazyList[UnitName("target")] or 0) + 1
        end
      end
  elseif spell == "soulstone" then
    for message = 1, #ssList do
      if ssList[message].checked == true then
        local selectedMessage = ssList[message].text
        if selectedMessage == "Random" then
          randomMessage = math.random(2, #ssList)
          selectedMessage = ssList[randomMessage].text
        end
          local message = string.gsub(selectedMessage, "<shards>", shardCount())
          message = string.gsub(message, "<target>", UnitName("target"))
          SendChatMessage(message, channel, nil, nil)
          ssPlayerList[UnitName("target")] = (ssPlayerList[UnitName("target")] or 0) + 1
        end
      end
    ssList[UnitName("target")] = (ssList[UnitName("target")] or 0) + 1
  end
end

local function ssAnouncer(list, max, channel)
  local topic = ""
  local dataList = {}
  local announceMessage = ""
  if list == "Select list" then
    list = "Summon"
  end
  if channel == "Select chat" then
    channel = "PARTY"
  end
  if list == "Summon" then
    topic = "Top " .. max .. " lazy bastards"
    dataList = lazyList
  elseif list == "Soulstone" then
    topic = "Top " .. max .. " stoners"
    dataList = ssPlayerList
  end
  SendChatMessage(topic, channel, nil, nil)
  local n = 1
  for k,v in spairs(dataList, function(t,a,b) return t[b] < t[a] end) do
    if list == "Summon" then
      SendChatMessage(n .. ". " .. k .. " summoned " .. v .. " times" , channel, nil, nil)
    elseif list == "Soulstone" then
      SendChatMessage(n .. ". " .. k .. " soulstoned " .. v .. " times" , channel, nil, nil)
    end
    n = n + 1
    if n == max + 1 then
      return
    end
  end
end

local function summonsum(self, event, arg1, arg2, arg3, arg4, ...)
  if event == "ADDON_LOADED" and arg1 == "summonsum" then
    if lazyList == nil then
      lazyList = {}
    elseif ssList == nil then
      ssList = {
        {text = "Random", checked = false},
        {text = "Soulstone on <target>, <shards> remaining", checked = true}
      }
    elseif ssMenuList == nil then
      ssMenuList = {
        {text = "Random", checked = false},
        {text = "Summoning <target> please click portal, <shards> remaining", checked = true}
      }
    elseif ssPlayerList == nil then
      ssPlayerList = {}
    end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    if arg3 == 698 and arg1 == "player" then
      local broadcastChannel = "PARTY"
      if IsInRaid("LE_PARTY_CATEGORY_HOME") then
        broadcastChannel = "RAID"
      end
      sendSSMessage("summon", broadcastChannel)
      -- 11689
    elseif arg3 == 20764 or arg3 == 20763 or arg3 == 20762 or arg3 == 20707 and arg1 == "player" then
      local broadcastChannel = "SAY"
      if IsInGroup("LE_PARTY_CATEGORY_HOME") then
        broadcastChannel = "PARTY"
      elseif IsInRaid("LE_PARTY_CATEGORY_HOME") then
        broadcastChannel = "RAID"
      end
      sendSSMessage("soulstone", broadcastChannel)
    else
      return
    end
  end
end

-- Main ui window
local sumSumUI = sumSumUI or CreateFrame("frame", "sumSumUI")
sumSumUI:Hide()
sumSumUI:SetBackdrop({
  bgFile = "Interface\\FrameGeneral\\UI-Background-Rock",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = false, tileSize = 32, edgeSize = 32,
  insets = {left = 11, right = 12, top = 12, bottom = 11}
})
sumSumUI:SetWidth(512)
sumSumUI:SetHeight(400)
sumSumUI:SetPoint("CENTER", UIParent)
sumSumUI:EnableMouse(true)
sumSumUI:SetMovable(true)
sumSumUI:RegisterForDrag("LeftButton")
sumSumUI:SetScript("OnDragStart", function(AFKQuizUI) AFKQuizUI:StartMoving() end)
sumSumUI:SetScript("OnDragStop", function(AFKQuizUI) AFKQuizUI:StopMovingOrSizing() end)
sumSumUI:SetFrameStrata("FULLSCREEN_DIALOG")
 sumSumUI.closeButton = sumSumUI.closeButton or CreateFrame("button", nil, sumSumUI, "UIPanelCloseButton")
 sumSumUI.closeButton:SetPoint("TOPRIGHT", 0, 0)
 sumSumUI.closeButton:SetScript("OnClick", function(self)
   sumSumUI:Hide()
  end)

-- summon
sumSumUI.summon = sumSumUI:CreateFontString(nil, "ARTWORK")
sumSumUI.summon:SetFontObject(GameFontNormal)
sumSumUI.summon:SetPoint("TOPLEFT", 35, - 20)
sumSumUI.summon:SetText("Add a summon or soulstone message")

sumSumUI.summon = sumSumUI:CreateFontString(nil, "ARTWORK")
sumSumUI.summon:SetFontObject(GameFontNormalSmall)
sumSumUI.summon:SetPoint("TOPLEFT", 35, - 32)
sumSumUI.summon:SetText("<shards> will translate to \"n soulshards\"")


sumSumUI.summon = sumSumUI:CreateFontString(nil, "ARTWORK")
sumSumUI.summon:SetFontObject(GameFontNormalSmall)
sumSumUI.summon:SetPoint("TOPLEFT", 35, - 42)
sumSumUI.summon:SetText("<target> will translate to your current target")

sumSumUI.summon = sumSumUI:CreateFontString(nil, "ARTWORK")
sumSumUI.summon:SetFontObject(GameFontNormal)
sumSumUI.summon:SetPoint("TOPLEFT", 35, - 62)
sumSumUI.summon:SetText("Summon")

sumSumUI.summonMessage = CreateFrame("EditBox", nil, sumSumUI, "InputBoxTemplate")
sumSumUI.summonMessage:SetPoint("TOPLEFT", 35, - 85)
sumSumUI.summonMessage:SetWidth(300)
sumSumUI.summonMessage:SetHeight(5)
sumSumUI.summonMessage:SetMovable(false)
sumSumUI.summonMessage:SetAutoFocus(false)
sumSumUI.summonMessage:SetFontObject(ChatFontNormal)

sumSumUI.submitButton = CreateFrame("button", nil, sumSumUI, "UIPanelButtonTemplate")
sumSumUI.submitButton:SetPoint("TOPLEFT", 351, - 76)
sumSumUI.submitButton:SetText("Add")
sumSumUI.submitButton:SetWidth(70  )
sumSumUI.submitButton:SetHeight(22)
sumSumUI.submitButton:SetScript("OnClick", function(self)
  local message = sumSumUI.summonMessage:GetText()
  table.insert(ssMenuList, {text = message, checked = false})
end)

local dropDown = CreateFrame("FRAME", "summonSelect", sumSumUI, "UIDropDownMenuTemplate")
dropDown:SetPoint("TOPLEFT", 12, - 100)
UIDropDownMenu_SetWidth(dropDown, 125)
UIDropDownMenu_SetText(dropDown, "Select summon message")
UIDropDownMenu_JustifyText(dropDown, "LEFT")
sumSumUI.DeleteButton = CreateFrame("button", nil, sumSumUI, "UIPanelButtonTemplate")
sumSumUI.DeleteButton:SetPoint("TOPLEFT", 180, - 102)
sumSumUI.DeleteButton:SetText("Remove")
sumSumUI.DeleteButton:SetWidth(70  )
sumSumUI.DeleteButton:SetHeight(22)
sumSumUI.DeleteButton:SetScript("OnClick", function(self)
  for message = 1, #ssMenuList do
    if ssMenuList[message].text == "Random" then
      ssMenuList[1].checked = false
    end
    if ssMenuList[message].checked == true and ssMenuList[message].text ~= "Random" then
      table.remove(ssMenuList, message)
      UIDropDownMenu_SetText(dropDown, "Select summon message")
    end
  end
  ssMenuList[#ssMenuList].checked = true
  UIDropDownMenu_SetText(dropDown, ssMenuList[#ssMenuList].text)
end)

UIDropDownMenu_Initialize(dropDown, function(self, level, menu)
  local info = UIDropDownMenu_CreateInfo()
  local ssMenu = {
    { text = "Option 1", checked = false},
    { text = "Option 2", checked = true }
  }
  if ssMenuList ~= nil then
    ssMenu = ssMenuList
  end
  for option = 1, #ssMenu do
    info.text = ssMenu[option].text
    info.func = function()
      for option = 1, #ssMenu do
        ssMenu[option].checked = false
      end
      ssMenu[option].checked = true;
      local length = string.len(ssMenu[option].text)
      UIDropDownMenu_SetText(dropDown, ssMenu[option].text)
    end
    info.checked = ssMenu[option].checked
    UIDropDownMenu_AddButton(info)
  end
end)

-- Soulstone
sumSumUI.soulstone = sumSumUI:CreateFontString(nil, "ARTWORK")
sumSumUI.soulstone:SetFontObject(GameFontNormal)
sumSumUI.soulstone:SetPoint("TOPLEFT", 35, - 162)
sumSumUI.soulstone:SetText("Soulstone")

sumSumUI.soulstoneMessage = CreateFrame("EditBox", nil, sumSumUI, "InputBoxTemplate")
sumSumUI.soulstoneMessage:SetPoint("TOPLEFT", 35, - 185)
sumSumUI.soulstoneMessage:SetWidth(300)
sumSumUI.soulstoneMessage:SetHeight(5)
sumSumUI.soulstoneMessage:SetMovable(false)
sumSumUI.soulstoneMessage:SetAutoFocus(false)
sumSumUI.soulstoneMessage:SetFontObject(ChatFontNormal)

sumSumUI.submitButton2 = CreateFrame("button", nil, sumSumUI, "UIPanelButtonTemplate")
sumSumUI.submitButton2:SetPoint("TOPLEFT", 351, - 176)
sumSumUI.submitButton2:SetText("Add")
sumSumUI.submitButton2:SetWidth(70  )
sumSumUI.submitButton2:SetHeight(22)
sumSumUI.submitButton2:SetScript("OnClick", function(self)
  local message = sumSumUI.soulstoneMessage:GetText()
  table.insert(ssList, {text = message, checked = false})
end)

local dropDown2 = CreateFrame("FRAME", "soulstoneSelect", sumSumUI, "UIDropDownMenuTemplate")
dropDown2:SetPoint("TOPLEFT", 12, - 200)
UIDropDownMenu_SetWidth(dropDown2, 125)
UIDropDownMenu_SetText(dropDown2, "Select soulstone message")
UIDropDownMenu_JustifyText(dropDown2, "LEFT")
sumSumUI.DeleteButton2 = CreateFrame("button", nil, sumSumUI, "UIPanelButtonTemplate")
sumSumUI.DeleteButton2:SetPoint("TOPLEFT", 180, - 202)
sumSumUI.DeleteButton2:SetText("Remove")
sumSumUI.DeleteButton2:SetWidth(70  )
sumSumUI.DeleteButton2:SetHeight(22)
sumSumUI.DeleteButton2:SetScript("OnClick", function(self)
  for message = 1, #ssList do
    if ssList[message].text == "Random" then
      ssList[1].checked = false
    end
    if ssList[message].checked == true and ssList[message].text ~= "Random" then
      table.remove(ssList, message)
      UIDropDownMenu_SetText(dropDown2, "Select soulstone message")
    end
  end
  ssList[#ssList].checked = true
  UIDropDownMenu_SetText(dropDown2, ssList[#ssList].text)
end)

UIDropDownMenu_Initialize(dropDown2, function(self, level, menu)
  local info = UIDropDownMenu_CreateInfo()
  local ssMenu = {
    { text = "Option 1", checked = false},
    { text = "Option 2", checked = true }
  }
  if ssList ~= nil then
    ssMenu = ssList
  end
  for option = 1, #ssMenu do
    info.text = ssMenu[option].text
    info.func = function()
      for option = 1, #ssMenu do
        ssMenu[option].checked = false
      end
      ssMenu[option].checked = true;
      local length = string.len(ssMenu[option].text)
      UIDropDownMenu_SetText(dropDown2, ssMenu[option].text)
    end
    info.checked = ssMenu[option].checked
    UIDropDownMenu_AddButton(info)
  end
end)

-- announcer
sumSumUI.announcer = sumSumUI:CreateFontString(nil, "ARTWORK")
sumSumUI.announcer:SetFontObject(GameFontNormal)
sumSumUI.announcer:SetPoint("TOPLEFT", 35, - 262)
sumSumUI.announcer:SetText("Announcer")

local dropDown3 = CreateFrame("FRAME", "announcer", sumSumUI, "UIDropDownMenuTemplate")
dropDown3:SetPoint("TOPLEFT", 12, - 285)
UIDropDownMenu_SetWidth(dropDown3, 125)
UIDropDownMenu_SetText(dropDown3, "Select list")
UIDropDownMenu_JustifyText(dropDown3, "LEFT")

UIDropDownMenu_Initialize(dropDown3, function(self, level, menu)
  local info = UIDropDownMenu_CreateInfo()
  local ssMenu = {
    { text = "Summon", checked = false},
    { text = "Soulstone", checked = false }
  }
  for option = 1, #ssMenu do
    info.text = ssMenu[option].text
    info.func = function()
      for option = 1, #ssMenu do
        ssMenu[option].checked = false
      end
      ssMenu[option].checked = true;
      UIDropDownMenu_SetText(dropDown3, ssMenu[option].text)
    end
    info.checked = ssMenu[option].checked
    UIDropDownMenu_AddButton(info)
  end
end)

local dropDown4 = CreateFrame("FRAME", "announcerChannel", sumSumUI, "UIDropDownMenuTemplate")
dropDown4:SetPoint("TOPLEFT", 160, - 285)
UIDropDownMenu_SetWidth(dropDown4, 125)
UIDropDownMenu_SetText(dropDown4, "Select chat")
UIDropDownMenu_JustifyText(dropDown4, "LEFT")

UIDropDownMenu_Initialize(dropDown4, function(self, level, menu)
  local info = UIDropDownMenu_CreateInfo()
  local ssMenu = {
    { text = "say", checked = false},
    { text = "yell", checked = false },
    { text = "party", checked = false},
    { text = "raid", checked = false },
    { text = "guild", checked = false}
  }
  for option = 1, #ssMenu do
    info.text = ssMenu[option].text
    info.func = function()
      for option = 1, #ssMenu do
        ssMenu[option].checked = false
      end
      ssMenu[option].checked = true;
      UIDropDownMenu_SetText(dropDown4, ssMenu[option].text)
    end
    info.checked = ssMenu[option].checked
    UIDropDownMenu_AddButton(info)
  end
end)

sumSumUI.announcerSize = sumSumUI:CreateFontString(nil, "ARTWORK")
sumSumUI.announcerSize:SetFontObject(ChatFontNormal)
sumSumUI.announcerSize:SetPoint("TOPLEFT", 160, - 327)
sumSumUI.announcerSize:SetText("3")

local name = "MyExampleSlider"
local template = "OptionsSliderTemplate"
local slider = CreateFrame("Slider",name,sumSumUI,template)
slider:SetPoint("TOPLEFT", 35, - 325)
slider.textLow = _G[name.."Low"]
slider.textHigh = _G[name.."High"]
slider:SetMinMaxValues(1, 10)
slider.minValue, slider.maxValue = slider:GetMinMaxValues()
slider.textLow:SetText("")
slider.textHigh:SetText("")
slider:SetValue(3)
slider:SetValueStep(1)
slider:SetWidth(120)
slider:SetScript("OnValueChanged", function(self,event,arg1) sumSumUI.announcerSize:SetText(math.floor(event)) end)

sumSumUI.AnnounceButton = CreateFrame("button", nil, sumSumUI, "UIPanelButtonTemplate")
sumSumUI.AnnounceButton:SetPoint("TOPLEFT", 180, - 322)
sumSumUI.AnnounceButton:SetText("Announce")
sumSumUI.AnnounceButton:SetWidth(70  )
sumSumUI.AnnounceButton:SetHeight(22)
sumSumUI.AnnounceButton:SetScript("OnClick", function(self)
local topList = math.floor(slider:GetValue())
local list = UIDropDownMenu_GetText(dropDown3)
local channel = UIDropDownMenu_GetText(dropDown4)
ssAnouncer(list, topList, channel)
end)

SLASH_SUMSUM1 = "/sumsum"
SlashCmdList["SUMSUM"] = function(functionName)
  sumSumUI:Show()
end
frame:SetScript("OnEvent", summonsum)
