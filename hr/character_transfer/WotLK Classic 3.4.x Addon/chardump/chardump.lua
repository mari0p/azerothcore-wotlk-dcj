local myJSON = json.json
CHDMP = CHDMP or {}
local private = {}
private.dmp = {};


function private.GetGlobalInfo()
    local retTbl            = {}
    retTbl.locale           = GetLocale();
    retTbl.realm            = GetRealmName();
    retTbl.realmlist        = GetCVar("realmList");
    local version, build, date, tocversion = GetBuildInfo();
    retTbl.clientbuild      = build;
    return retTbl;
end
function private.GetUnitInfo()
    local retTbl            = {}
    retTbl.name             = UnitName("player");
    local _, class          = UnitClass("player");
    retTbl.class            = class;
    retTbl.level            = UnitLevel("player");
    local _,race            = UnitRace("player");
    retTbl.race             = race;
    retTbl.gender           = UnitSex("player");
    local honorableKills    = GetPVPLifetimeStats()
    retTbl.kills            = honorableKills;
    retTbl.honor            = 0;
    retTbl.arenapoints      = 0;
    retTbl.money            = GetMoney();
    retTbl.specs            = GetNumTalentGroups();
    return retTbl;
end
function private.GetSpellData()
    local retTbl = {}
    for i = 1, GetNumSpellTabs() do
        local name, texture , offset, numSpells = GetSpellTabInfo(i);
        if name == nil or numSpells == nil then
            break;
        end
        for s = offset + 1, offset + numSpells do
            local spellInfo = GetSpellLink(s, BOOKTYPE_SPELL);
            if spellInfo ~= nil then
                for spellid in string.gmatch(GetSpellLink(s, BOOKTYPE_SPELL),".-Hspell:(%d+).*") do 
                    retTbl[spellid] = i;
                    --print("adding spell " .. spellid .. " from tab " .. i)
                end 
            end
        end
    end
    private.ILog("Spells DONE..."); 
    return retTbl;
end
function private.GetGlyphData()
    local retTbl = {}
    for i = 1, GetNumTalentGroups() do
        retTbl[i] = {}
        local curid = {[1] = 1,[2] = 1}
        for j = 1, 6 do
            local _, glyphType, glyphSpellID, _ = GetGlyphSocketInfo(j,i);
            if not retTbl[i][glyphType] then 
                retTbl[i][glyphType] = {} 
            end
            if not glyphSpellID then 
                glyphSpellID = -1;
            end
            retTbl[i][glyphType][curid[glyphType]] = glyphSpellID;
            curid[glyphType] = curid[glyphType]+1;
        end

        local numTabs = GetNumTalentTabs();
    for tt=1, numTabs do
            DEFAULT_CHAT_FRAME:AddMessage(GetTalentTabInfo(tt)..":");
            local numTalents = GetNumTalents(tt);
            for t=1, numTalents do
                nameTalent, icon, tier, column, currRank, maxRank= GetTalentInfo(tt,t);
                DEFAULT_CHAT_FRAME:AddMessage("- "..nameTalent..": "..currRank.."/"..maxRank);
            end
        end
    end
    private.ILog("Glyphs DONE..."); 
    return retTbl;
end
function private.GetCurrencyData()
    local retTbl = {}
    for i = 1, GetCurrencyListSize() do
        local name, _, _, _, _, count, _, _, itemID = GetCurrencyListInfo(i)
        retTbl[i] = {['C'] = count, ['I'] = itemID};
    end 
    return retTbl;
end
function private.GetMACData()
    local retTbl = {}
    for i = 1, GetNumCompanions("MOUNT") do
        local _, _, M = GetCompanionInfo("MOUNT", i);
        retTbl["M:"..i] = M;
    end
    for i = 1, GetNumCompanions("CRITTER") do
        local _, _, C = GetCompanionInfo("CRITTER", i);
        retTbl["C:"..i] = C;
    end    
    private.ILog("Mounts & Critters DONE...");    
    return retTbl;
end
function private.GetAchievements()
    local retTbl = {}
    for _, j in pairs(CHDMP.AchievementIds) do
        IDNumber, _, _,Completed, Month, Day, Year, _, _, _, _ = GetAchievementInfo(j)
        if IDNumber and Completed then
            local posixtime = time{year = 2000 + Year, month = Month, day = Day};
            if posixtime then
                retTbl[IDNumber] = {["I"] = IDNumber, ["D"] = posixtime}
            end
        end
    end
    private.ILog("Achievements DONE...");
    return retTbl;
end
function private.GetRepData()
    local retTbl = {}
    for i = 1, GetNumFactions() do 
        local name, _, _, _, _, earnedValue, _, canToggleAtWar, _, _, _, _, _ = GetFactionInfo(i)
        retTbl[i] = {["N"] = name, ["V"] = earnedValue, ["F"] = bit.bor(((not canToggleAtWar) and 16) or 0)} 
    end
    private.ILog("Reputations DONE...");
    return retTbl;
end
function private.GetIData()
    local retTbl = {}
    for i = 1, 74 do 
        local itemLink = GetInventoryItemLink("player", i) 
        if itemLink then 
            local itemName, itemLink_, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink)
            local charges = 0           
            local equipSlot = itemEquipLoc
            if equipSlot == "INVTYPE_BAG" then
                count = 1
            else
                count = GetInventoryItemCount("player",i)
                charges = GetItemCount(itemLink,nil,true)
            end
        
            local current, maximumDur = GetInventoryItemDurability(i);

            --print("Adding " .. itemLink)
            local entry, chant, Gem1, Gem2, Gem3 = string.match(itemLink,"Hitem:(%d*):(%d*):(%d*):(%d*):(%d*)")
            retTbl["0000:"..i] =  {["I"] = entry, ["C"] = count, ["E"] = chant, ["G1"] = Gem1, ["G2"] = Gem2, ["G3"] = Gem3, ["D"] = maximumDur, ["CH"] = charges}
            print("entry = " .. entry .. ", count = " .. count .. ",G1= " .. (Gem1 or "") ..  ",G2= " .. (Gem2 or "") ..  ",G3= " .. (Gem3 or "") .. ",D= " ..(maximumDur or "") .. ",CH= " ..(charges or "") )

        end 
    end
    for bag = 0, 11 do 
        for slot = 1, GetContainerNumSlots(bag) do 
            local itemLink = GetContainerItemLink(bag, slot) 
            if itemLink then 
                --print("Adding " .. itemLink)
                local _, count, _, _, _ = GetContainerItemInfo(bag, slot); 
                local current, maximumDur = GetContainerItemDurability(bag, slot);
                local charges = GetItemCount(itemLink,nil,true)

                local p = bag + 1000;

                local entry, chant, Gem1, Gem2, Gem3 = string.match(itemLink,"Hitem:(%d*):(%d*):(%d*):(%d*):(%d*)")
                retTbl[p..":"..slot] =  {["I"] = entry, ["C"] = count, ["E"] = chant, ["G1"] = Gem1, ["G2"] = Gem2, ["G3"] = Gem3, ["D"] = maximumDur, ["CH"] = charges}
                --print("entry = " .. entry .. ", count = " .. count .. ",G1= " .. (Gem1 or "") ..  ",G2= " .. (Gem2 or "") ..  ",G3= " .. (Gem3 or "") .. ",D= " ..(maximumDur or ""))
    
            end 
        end 
    end
    private.ILog("Inventory DONE...");    
    return retTbl;
end
function private.GetSkillData()
    local retTbl = {}
    for i = 1, GetNumSkillLines() do 
        local skillName, isHeader, _, skillRank, _, _, skillMaxRank, _, _, _, _, _, _ = GetSkillLineInfo(i)
        retTbl[i] = {["N"] = skillName,["C"] = skillRank,["M"] = skillMaxRank}
    end
    return retTbl;
end
function private.CreateCharDump()
    private.dmp.ginf        = private.trycall(private.GetGlobalInfo, private.ErrLog)    or {private.ErrLog};
    private.dmp.uinf        = private.trycall(private.GetUnitInfo, private.ErrLog)      or {private.ErrLog};
    --private.dmp.rep         = private.trycall(private.GetRepData, private.ErrLog)       or {private.ErrLog};
    --private.dmp.achiev      = private.trycall(private.GetAchievements, private.ErrLog)  or {private.ErrLog};
    private.dmp.glyphs      = private.trycall(private.GetGlyphData, private.ErrLog)     or {private.ErrLog};
    private.dmp.creature    = private.trycall(private.GetMACData, private.ErrLog)       or {private.ErrLog};
    private.dmp.spells      = private.trycall(private.GetSpellData, private.ErrLog)     or {private.ErrLog};
    private.dmp.skills      = private.trycall(private.GetSkillData, private.ErrLog)     or {private.ErrLog};
    private.dmp.inventory   = private.trycall(private.GetIData, private.ErrLog)         or {private.ErrLog};
    private.dmp.currency    = private.trycall(private.GetCurrencyData, private.ErrLog)  or {private.ErrLog};
    return b64_enc(myJSON.encode(private.dmp));
end
function private.Log(str_in)
    print("\124c0080C0FF  "..str_in.."\124r");
end
function private.ErrLog(err_in)
    private.errlog = private.errlog or ""
    private.errlog = private.errlog .. "err=" .. b64_enc(err_in) .. "\n"
    print("\124c00FF0000"..(err_in or "nil").."\124r");
end
function private.GetCharDump()
    return b64_enc(private.CreateCharDump());
end
function private.ILog(str_in)
    print("\124c0080FF80"..str_in.."\124r");
end
function private.trycall(f,herr)
    local status, result = xpcall(f,herr)
    if status then 
        return result;
    end
    return status;
end
function private.SaveCharData(data_in)
    private.ILog("AzerothShard chardump DONE: you can find dump here: WoW Folder \\WTF\\Account\\%Username%\\SavedVariables\\chardump.lua ");    
    CHDMP_DATA  = data_in
    CHDMP_KEY   = "f7519722aa975a5dab2e49c18d9b175cd8047a36"
    CHDMP_VER   = GetAddOnMetadata("chardump", "Version")
end
function private.TradeSkillFrame_OnShow_Hook(frame, force)
    if private.done == true then
        return
    end

    if frame and frame.GetName and frame:GetName() == "TradeSkillFrame" then
		private.dmp.recipes = private.dmp.recipes or {};
		for i=1, GetNumTradeSkills() do
			local link = GetTradeSkillRecipeLink(i);
			if link then
				local spellId = tonumber(link:match("enchant:(%d+)")); 
				private.dmp.recipes[spellId] = spellId;
			end
		end

		print("Profession scanned!")


        local isLink, _ = IsTradeSkillLinked();
        if isLink == nil then
            local link = GetTradeSkillListLink();
            if link then
		        local skillname = link:match("%[(.-)%]");
		        private.dmp = private.dmp or {};
		        private.dmp.skilllink = private.dmp.skilllink or {};
				private.dmp.skilllink[skillname] = link;
				print("AzerothShard chardump: TradeSkillFrame_Show",skillname,link)
            end
        end

		private.SaveCharData(private.GetCharDump())
    end 
end

hooksecurefunc(_G, "ShowUIPanel", private.TradeSkillFrame_OnShow_Hook);

SLASH_CHDMP1 = "/chardump";
SlashCmdList["CHDMP"] = function(msg)
    if msg == "done" then
        private.done = true;
        return;
    elseif msg == "help" then
        return;
    else
        private.done = false;
    end

    private.SaveCharData(private.GetCharDump())
end
