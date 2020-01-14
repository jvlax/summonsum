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
  return n
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

local function summonsum(self, event, arg1, arg2, arg3, arg4, ...)
  if event == "ADDON_LOADED" and arg1 == "summonsum" then
    if lazyList == nil then
      lazyList = {}
    end
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    -- spirit tap test = 1454
    if arg3 == 698 then
      local broadcastChannel = "PARTY"
      if IsInRaid("LE_PARTY_CATEGORY_HOME") then
        broadcastChannel = "RAID"
      end
      local target = UnitName("target")
      shards = shardCount() - 1;
      local shardGrammar = "soulshards"
      if shards == 1 then
        shardGrammar = "soulshard"
      end
      SendChatMessage("Summoning " .. target .. " please click portal, " .. shards .. " " .. shardGrammar .. " remaining", broadcastChannel, nil, nil)
      lazyList[target] = (lazyList[target] or 0) + 1
    else
      return
    end
  end
end

SLASH_SUM1 = "/sum"
SlashCmdList["SUM"] = function(functionName)
  local command, arg1, arg2 = strsplit(" ", functionName, 3)
  if command == "report" then
    if (arg1) then
      if arg1 == "whisper" then
        if arg2 == nil then
          print("please enter a player to whisper to")
          return
        else
          SendChatMessage("Top 3 lazy bastards", arg1, nil, arg2)
          local n = 1
          for k,v in spairs(lazyList, function(t,a,b) return t[b] < t[a] end) do
            SendChatMessage(n .. ". " .. k .. " summoned " .. v .. " times" , arg1, nil, arg2)
            n = n + 1
            if n == 3 then
              return
            end
          end
        end
      else
        SendChatMessage("Top 3 lazy bastards", arg1, nil, nil)
        local n = 1
        for k,v in spairs(lazyList, function(t,a,b) return t[b] < t[a] end) do
          SendChatMessage(n .. ". " .. k .. " summoned " .. v .. " times" , arg1, nil, nil)
          n = n + 1
          if n == 3 then
            return
          end
        end
      end
    end
  end
end


frame:SetScript("OnEvent", summonsum)
