local frame = summonsumFrame or CreateFrame("FRAME", "summonsumFrame");
frame:RegisterEvent("UNIT_SPELLCAST_SENT");
-- soulshard id = 6265
-- ritual of summoning id = 698
local function shardCount()
  local n = 0;
  for i=0,4 do
    for j=1,20 do
      item = GetContainerItemID(i, j);
      if item == 6265 then
        n = n + 1;
      end
    end
  end
  return n
end

local function summonsum(self, event, arg1, arg2, arg3, arg4, ...)
  -- spirit tap test = 1454
  if arg4 == 1454 then
    local broadcastChannel = "PARTY";
    if IsInRaid("LE_PARTY_CATEGORY_HOME") then
      broadcastChannel = "RAID";
    end
    local target = UnitName("target");
    shards = shardCount();
    SendChatMessage("Summoning " .. target .. " please click portal, " .. shards .. " soulshard(s) remaining", broadcastChannel, nil, nil);
  else
    return
  end
end

frame:SetScript("OnEvent", summonsum);
