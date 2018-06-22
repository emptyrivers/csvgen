-- Copyright © 2018 by Allen Faure. All Rights Relinquished.



-- engine

local isGenerating, csv, editbox
local lines, itemData = {}, {}

local function gatherItemData()
   wipe(itemData)
   for i = 1, 17 do 
      if i ~= 4 then
         local action = EquipmentManager_UnequipItemInSlot(i)
         if action then 
            EquipmentManager_RunAction(action)
         end
         local slotData = GetInventoryItemsForSlot(i, {})
         if i ~= 12 and i ~= 14 then
            local equippedData = {}
            for location in pairs(slotData) do
               local _, _, bags, _, slot, bag = EquipmentManager_UnpackLocation(location)
               if bags then
                  tinsert(equippedData, {bag = bag, slot = slot, equipped = false})
               end
            end
            equippedData.totalCombos = #equippedData + 1 -- add one for having nothing in that slot
            equippedData.currentCombo = 0
            itemData[i] = equippedData
         else
            itemData[i] = itemData[i-1]
            local total = #itemData[i]
            itemData[i].totalCombos = 1 + total + total * (total - 1)/2
         end
      end
   end
   isGenerating = true
end
local function changeGear()

end
local function npcid(unit)

end

local function generateLine()
   local utc, plvl, tlvl, id, agi, psta, tsta = 
   time(), UnitLevel'player', UnitLevel'target', npcid'target', select(2,UnitStat('player',2)), C_PaperDollInfo.GetStaggerPercentage('player')
   tinsert(lines, ("%d,%d,%s,%s,%d,%.2f,%.2f"):format(utc or 0, plvl or 0, tlvl or "", id or "", agi or 0, psta or 0, tsta or 0 ))
   return changeGear()
end



hooksecurefunc("PaperDollFrame_UpdateStats",function() -- probably could do this a bit earlier but eh
   if isGenerating then
      return generateLine()
   end
end)

-- interface

csv = CreateFrame("FRAME", "CSV", UIParent)
csv:Hide()
csv:SetPoint("CENTER")
csv:SetSize(200, 30)
csv:EnableMouse(true)
csv:SetFrameStrata("HIGH")
csv:SetMovable(true)
csv:RegisterForDrag("LeftButton")
csv:SetScript("OnDragStart", function(self) self:StartMoving() end)
csv:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)


local csvbg = csv:CreateTexture(nil, "BACKGROUND")
csvbg:SetColorTexture(.1, .1, .1, .8)
csvbg:SetAllPoints()

local genbutton = CreateFrame("BUTTON", nil, csv)
genbutton:SetSize(70, 20)
genbutton:SetPoint("LEFT", 3, 0)

local gentext = genbutton:CreateFontString(nil, "ARTWORK")
gentext:SetFont("Fonts\\FRIZQT__.TTF", 12)
gentext:SetText("Generate!")
gentext:SetAllPoints()

local genhighlight = genbutton:CreateTexture(nil, "HIGHLIGHT")
genhighlight:SetColorTexture(210/255, 173/255, 18/255, .1)
genhighlight:SetAllPoints()

local closebutton = CreateFrame("BUTTON", nil, csv)
closebutton:SetSize(20, 20)
closebutton:SetPoint("RIGHT", -3, 0)

local closetext = closebutton:CreateFontString(nil, "ARTWORK")
closetext:SetFont("Fonts\\FRIZQT__.TTF", 12)
closetext:SetText("X")
closetext:SetAllPoints()

local closehighlight = closebutton:CreateTexture(nil, "HIGHLIGHT")
closehighlight:SetColorTexture(210/255, 173/255, 18/255, .1)
closehighlight:SetAllPoints()

local scroll = CreateFrame("SCROLLFRAME", nil, csv)
scroll:SetPoint("TOP", csv, "BOTTOM", 0, -4)
scroll:SetSize(70, 120)
-- scroll:SetScript("OnEscapePressed", function(self) self:Hide() end)
scroll:Hide()

local scrollbg = scroll:CreateTexture(nil, "BACKGROUND")
scrollbg:SetColorTexture(.1, .1, .1, .8)
scrollbg:SetAllPoints()

editbox = CreateFrame("EDITBOX", nil, scroll)
editbox:SetMultiLine(true)
editbox:SetTextInsets(1, 1, 1, 1)
editbox:SetAllPoints()



-- slash (command, not fiction)

local function toggle() if csv:IsShown() then csv:Hide() else csv:Show() end end
local function show() csv:Show() end
local function hide() csv:Hide() end
local function gen() 
   if InCombatLockdown() then return end
   return gatherItemData()
end
local function help() print [[
usage:
/csv show or /csv open: shows the interface
/csv hide or /csv close: hides the interfase
/csv run or /csv generate or /csv gen: opens the interface, and generates a csv dump]]
end
local switch = setmetatable(
   {
      toggle   = toggle,
      open     = show,
      show     = show,
      hide     = hide,
      close    = hide,
      generate = gen,
      gen      = gen,
      run      = gen,
      help     = help,
   }, 
   {
      __index  = function() return help end,
      __call   = function(self, case, ...) return self[case](...) end,
   }
)
SLASH_CSV1 = "/csv"
function SlashCmdList.CSV(msg)
   local parsed, rest = msg:match("^%s*(%S+)")
   return switch(parsed or "toggle", rest)
end

csv:RegisterEvent("PLAYER_REGEN_DISABLED")
csv:RegisterEvent("PLAYER_REGEN_ENABLED")
csv:SetScript("OnEvent", function(self, event)
   if event == "PLAYER_REGEN_DISABLED" then
      genbutton:Disable()
      gentext:SetText("In combat :(")
      isGenerating = nil
      wipe(lines)
   else
      gentext:SetText("Generate!")
      genbutton:Enable()
   end
end)

genbutton:SetScript("OnClick", gen)
closebutton:SetScript("OnClick", hide)