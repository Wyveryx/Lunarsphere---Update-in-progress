-- /***********************************************
--  * Lunar Items Module
--  *********************
--
--  Author	: Moongaze (Twisting Nether)
--  Description	: Locates and builds a database of every piece of food, drink, mana potion,
--                health potion, mount, and hearthstone of the player, without relying
--                on a table of pre-defined information. Is able to do away with having to
--                localize item names and keep memory usage down.
--
--  ***********************************************/

-- Notes:
-- First aid bandages, all cast spell "First Aid" , the higher the item id, the more powerful
-- the bandage (for now)
-- If I can find the "required First Aid" level, that would be more accurate in case Blizzard
-- screws the order in the future

--
-- http://thottbot.com/wotlk/s43180
-- I need to add filters for the new item level 75 foods... grrr! They need +1 strength...

-- /***********************************************
--  * Module Setup
--  *********************

-- Create our Lunar object if it's not made
if (not Lunar) then
	Lunar = {};
end

-- Add our Items module to Lunar
if (not Lunar.Items) then
	Lunar.Items = {};
end

-- Set our current version for the module (used for version checking later on)
Lunar.Items.version = 1.52;

-- Create our database settings
Lunar.Items.RunInitialize = false;
Lunar.Items.reagentString = nil;

-- Temp fix for German (and possibly other) locale item charge searching
Lunar.Items.chargesText = string.gsub(ITEM_SPELL_CHARGES, "%d%$", "");
Lunar.Items.chargesText = string.gsub(Lunar.Items.chargesText, "%%d", "(%%d+)");

Lunar.Items.itemSkillText = string.gsub(ITEM_MIN_SKILL, "%%s", "(.*)");
Lunar.Items.itemSkillText = string.gsub(Lunar.Items.itemSkillText, "%%1$s", "(.*)");
Lunar.Items.itemSkillText = string.gsub(Lunar.Items.itemSkillText, "%%2$d", "%(%%d%)");
Lunar.Items.itemSkillText = string.gsub(Lunar.Items.itemSkillText, "%(%%d%)", "%%((%%d+)%%)");

Lunar.Items.itemMinLevel = string.gsub(ITEM_MIN_LEVEL, "%%d", "(%%d+)");

--"Benötigt %1$s (%2$d)"

--Lunar.Items.itemSkillText2 = string.gsub("%s (%d) requies", "%%s", "(.*)");
--Lunar.Items.itemSkillText2 = string.gsub(Lunar.Items.itemSkillText2, "%(%%d%)", "%%((%%d+)%%)");
--/script local a, b = string.match("mount (300) requies", Lunar.Items.itemSkillText2);
--ITEM_MIN_LEVEL = "Requires Level %d"; -- Required level to use the item
--ITEM_MIN_SKILL
-- Create the item database to be used by the Item module
local itemData = {
	drink         = {},
	food          = {},
	potionHealing = {},
	potionMana    = {},
	energyDrink   = {},
	ragePotion    = {},
	bandage       = {},
	mount         = {},
	companion     = {},
	hearthstone   = {},
	charges       = {},
	healthStone   = {},
	--	manaStone	= {},
};

-- Create the search database which will store localized search strings
-- generated during initialization
local searchData = {
	drink         = nil,
	food          = nil,
	potionHealing = nil,
	potionMana    = nil,
	energyDrink   = nil,
	bandage       = nil,
	hearthstone   = nil,
	healthStone   = nil,
	weapon        = nil,
	armor         = nil,
	consume       = nil,
	misc          = nil,
	junk          = nil,
	reagent       = nil,
	charges       = nil,
	battlepet     = nil,
	--	smallPet		= nil,
	--	manaStone		= nil,
};

-- Create our list of low and high indexes for the item database
local itemStrength = {
	drink         = {},
	food          = {},
	potionHealing = {},
	potionMana    = {},
	energyDrink   = {},
	bandage       = {},
	hearthstone   = {},
	mount         = {},
	ragePotion    = {},
	charges       = {},
	companion     = {},
	healthStone   = {},
	--	smallPet		= {},
	--	manaStone		= {},
};

-- Create a list of our item table names
local itemTableNames = {
	"drink",
	"food",
	"potionHealing",
	"potionMana",
	"energyDrink",
	"ragePotion",
	"bandage",
	"mount",
	"hearthstone",
	"charges",
	"companion",
	--	"smallPet",
	"healthStone",
	--	"manaStone",
};

-- Create a table that will store bag information. Will store empty slots and total slots
--Lunar.Items.bagSlots = {};

-- Create a list of several items that fit the item spell we might be looking for
-- This list is made of most of the common items the player might have seen. Other
-- items that are not in this list that use the same spells can be found, increasing
-- the total amount of items found.
local itemSpellID = {
	drink         = "00159-01179-01205-01708-01645-08766-28399-27860-05350-03772-08077-08078-08079-02136-30703-22018-02288-",
	food          = "04540-04541-04542-04544-04601-08950-08952-27854-29451-05349-01113-01114-22895-22019-01487-08075-08076-",
	potionHealing = "00118-00858-00929-01710-03928-13446-22829-",
	potionMana    = "02455-03385-03827-06149-13443-13444-22832-28101-",
	hearthstone   = "06948-",
	energyDrink   = "07676-",
	bandage       = "03530-06450-14529-21990-08544-01251-03531-06451-14530-21991-08545-02581-",
	--	manaStone	= "05514-05513-08007-08008-22004-",
	healthStone   = "05512-",
	undersporePod = "28112-",
	ragePotion    = "05631-13442-05633-",
};

-- Create a list of special items. These all require special locations (PVP battlegrounds, instances, etc)
-- These items will be checked for locations if they are selected as the "best" item in the item
-- database. That way, if we're not in that location, the item is skipped)
local specialUseID = {
	drink         = "00000-",
	food          = "19060-19061-19062-20062-20063-20064-",
	potionHealing = "32904-32905-",
	potionMana    = "32902-32903-",
	hearthstone   = "00000-",
	energyDrink   = "00000-",
	bandage       = "19066-19067-19068-19307-20065-20066-20067-20232-20234-20235-20237-20243-20244-",
	--	manaStone	= "00000-",
	healthStone   = "00000-",
	undersporePod = "00000-",
	ragePotion    = "00000-",
	pvp           = "17348-17349-17351-17352-",
};

-- Create a list of spell types to scan for (if we're missing some)
local itemSpellScan = {};

-- Notate how many item types we're tracking
Lunar.Items.totalItemTypes = table.getn(itemTableNames);

-- Poison images for poison button types
--Lunar.Items.poisonImages = {"Spell_Nature_SlowPoison", "Ability_Rogue_DualWeild", "Ability_Poisons", "INV_Misc_Herb_16"};

-- Create a list of our ground and flying mounts, for the random feature
local groundMounts = {};
local flyingMounts = {};
local swimmingMounts = {};
local striderMounts = {};
local favouriteMounts = {};
local allMounts = {};
--#local groundMountsEpic = {};
--#local flyingMountsEpic = {};
--#local flyingMountsEpic300 = {};
--#local allMountsEpic = {};
--#local groundMountsNormal = {};

--#local has310Mounts = false;
--#local hasEpicFlyingMounts = false;
--#local hasEpicGroundMounts = false;

-- Table of spell mount icons. (pally/warlock, pally, warlock, druid);
local spellMounts = {
	[0] = "Interface\\Icons\\Spell_Nature_Swiftness",
	[1] = "Interface\\Icons\\Ability_Mount_Charger",
	[2] = "Interface\\Icons\\Ability_Mount_Dreadsteed",
	[3] = "Interface\\Icons\\Ability_Druid_FlightForm"
};

local smallPetType;

--[[
Lunar.Items.updateButton = {
	drink		= {},
	food		= {},
	potionHealing	= {},
	potionMana	= {},
	energyDrink	= {},
	ragePotion	= {},
	bandage		= {},
	mount		= {},
	hearthstone	= {},
};
--]]

-- Create our tooltip sniffer
Lunar.Items.tooltip = CreateFrame("GameTooltip", "LunarItemsTooltip", UIParent,
	BackdropTemplateMixin and "BackdropTemplate, GameTooltipTemplate");

Lunar.Items.tooltip:SetOwner(UIParent, "ANCHOR_NONE");
Lunar.Items.tooltip:ClearAllPoints();
Lunar.Items.tooltip:SetPoint("Center");
Lunar.Items.tooltip:Hide();

-- /***********************************************
--  * Functions
--  *********************

-- /***********************************************
--  * Initialize
--  * ========================
--  *
--  * Sets up the module
--  *
--  * Accepts: None
--  * Returns: None
--  *********************
function Lunar.Items:Initialize()
	-- Create our event frame
	Lunar.Items.eventFrame = CreateFrame("Frame", "LunarItemsEvents", UIParent,
		BackdropTemplateMixin and "BackdropTemplate");

	-- Register the events we'll be tracking, and then set our frame's scripting
	--	Lunar.Items.eventFrame:RegisterEvent("PLAYER_LOGIN");
	Lunar.Items.eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO");
	Lunar.Items.eventFrame:SetScript("OnEvent", function(self, event, ...) Lunar.Items:OnEvent(event, ...) end);
	Lunar.Items.eventFrame:SetScript("OnUpdate", function(self, elapsed, ...) Lunar.Items:OnUpdate(elapsed, ...) end);



	-- Try and Kickstart the Mount Selection on first login.
	-- for some reason isUsableSpell() is not correctly firing.
	-- Possibly in a void event so lets see if this works.  Should unregister itself.
	--	Lunar.Items.eventFrame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE");
end

-- /***********************************************
--  * OnEvent
--  * ========================
--  *
--  * Handles events for the module
--  *
--  * Accepts: event (passed by OnEvent)
--  * Returns: None
--  *********************
function Lunar.Items:OnEvent(event, arg1, _, _, _, _, _, _, arg8)
	-- If the player just logged in, we turn on the initialize flag (removed due to issues with
	-- loading after a patch, when user data takes a little longer to reload)
	--	if (event == "PLAYER_LOGIN") then

	-- While the player is loading, the "meeting stone changed" event fires pretty late in the
	-- process, so we use that as the trigger to start scanning our items
	if (event == "UPDATE_INSTANCE_INFO") then
		Lunar.Items.RunInitialize = true;
	end

	-- If there was a bag update, we will take a count of all items in our database, and then
	-- we will scan the updated bag, in case there is a new item that was added. Afterwards,
	-- update the high-low values of our items. This is only ran while out of combat. If you're
	-- in combat, you might be picking up items or using them and these counts don't really
	-- matter much until AFTER combat.
	if (event == "BAG_UPDATE") then
		-- if the arg is 0 (backpack) ... we must also consider that an item with
		-- a charge might have been used. So, set all containers to be scanned.
		-- Otherwise, just do the arg1 container.
		if (arg1 == 0) then
			local index;
			for index = 0, 4 do
				Lunar.Items["updateContainer" .. index] = true;
				--				Lunar.Items["updateContainer" .. index .. "Slot"] = nil;
			end
		elseif (arg1 > 0) then
			Lunar.Items["updateContainer" .. arg1] = true;
			--			Lunar.Items["updateContainer" .. arg1 .. "Slot"] = nil;
		end

		if (Lunar.combatLockdown == true) then
			Lunar.Items.combatUpdate = true;
		else
			Lunar.Items.bagUpdateTimer = 0.3;
		end
	end

	if (event == "LEARNED_SPELL_IN_TAB") or (event == "COMPANION_LEARNED") then
		Lunar.Items.scanSpellMounts = true;
		Lunar.Items.bagUpdateTimer = 0.2;
	end

	--	if (event == "CHAT_MSG_CHANNEL_NOTICE") then
	--
	--		Lunar.API:Print("Connected to Channel " .. arg1 .. "   " .. arg8);
	--
	--		if (arg8 == 1) then
	--			Lunar.API:Print("Scanning Mounts");
	--
	--			Lunar.Items:ScanForSpellMounts();
	--			Lunar.Items:UpdateLowHighItems();
	--
	----			Lunar.Items.eventFrame:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE"); -- should be no longer needed at this point.
	--		end
	--	end
end

-- /***********************************************
--  * OnUpdate
--  * ========================
--  *
--  * Handles the initialization of the module when the player's data
--  * is fully loaded into the game.
--  *
--  * Accepts: elapsed (passed by OnUpdate)
--  * Returns: None
--  *********************
function Lunar.Items:OnUpdate(elapsed)
	-- Wait for the initialize instruction...
	if (Lunar.Items.RunInitialize == false) then
		return;
	end

	-- Now make sure the buttons are loaded:
	if not (Lunar.Button.Loaded) then
		return;
	end
	Lunar.Button.Loaded = nil;

	-- Okay, time to set everything up (because the player is loaded and their
	-- BAGS are loaded...)

	-- Turn off the initialize instruction.
	Lunar.Items.RunInitialize = false;

	-- Build our table of localized search strings, and then build our
	-- item data table. After we're done, destroy the functions.
	Lunar.Items:BuildLookupStrings();
	--	Lunar.Items:BuildData();

	-- We also stop watching our original events. We're done with those
	Lunar.Items.eventFrame:UnregisterEvent("PLAYER_LOGIN");
	Lunar.Items.eventFrame:UnregisterEvent("UPDATE_INSTANCE_INFO");

	-- Add support for spell mounts (when you learn a new one ... very rare)
	Lunar.Items.eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB");
	if (Lunar.API:IsVersionRetail() == true) then
		Lunar.Items.eventFrame:RegisterEvent("COMPANION_LEARNED");
	end
	Lunar.Items:ScanForSpellMounts();

	-- Now, setup bag watching functions, so we can check our counts when we receive a new
	-- item or lose one
	Lunar.Items.eventFrame:RegisterEvent("BAG_UPDATE");

	Lunar.Items.bagUpdateTimer = 0.3
	Lunar.Items["updateContainer0"] = true;
	Lunar.Items["updateContainer1"] = true;
	Lunar.Items["updateContainer2"] = true;
	Lunar.Items["updateContainer3"] = true;
	Lunar.Items["updateContainer4"] = true;

	-- Show the startup dialog if it exists (needs to do it here, since everything is loaded)
	if (Lunar.Settings.StartupDialog) then
		Lunar.Settings.StartupDialog:Show();
	end

	-- We're done with this function. Update it to a new version that places a throttle
	-- on the bag updating code.
	Lunar.Items.eventFrame:SetScript("OnUpdate", function(self, arg1)
		if not (Lunar.Items.bagUpdateTimer) then
			return;
		end
		Lunar.Items.bagUpdateTimer = Lunar.Items.bagUpdateTimer - arg1;
		if (Lunar.Items.bagUpdateTimer <= 0) then
			--			if (Lunar.Items.scanSpellMounts) then
			--				Lunar.Items.scanSpellMounts = nil;
			--				Lunar.Items:ScanForSpellMounts();
			--				Lunar.Items:UpdateLowHighItems();
			--			end
			if (Lunar.combatLockdown == true) then
				Lunar.Items.combatUpdate = true;
			else
				local bagID;
				for bagID = 0, 4 do
					if (Lunar.Items["updateContainer" .. bagID] == true) then
						Lunar.Items:UpdateBagContents(bagID, "exists");
						--						Lunar.Items.updatedItems = true;
						if (Lunar.Items["updateContainer" .. bagID .. "Slot"] == nil) then
							Lunar.Items["updateContainer" .. bagID] = nil;
						end
						break;
					end
					if (bagID == 4) then
						Lunar.Items:UpdateItemCounts();
						Lunar.Items.bagUpdateTimer = nil;
						Lunar.Items:UpdateLowHighItems();
						if (Lunar.Button) then
							local buttonID;
							for buttonID = 1, Lunar.Button.buttonCount do
								if not (LunarSphereSettings.buttonData[buttonID].empty) then
									if (buttonID > 10) then
										Lunar.Button:UpdateCount(_G["LunarSub" .. buttonID .. "Button"]);
									else
										Lunar.Button:UpdateCount(_G["LunarMenu" .. buttonID .. "Button"]);
									end
								end
							end
						end
					end
				end
			end
		end
	end);

	if not (LunarSphereSettings.memoryDisableDefaultUI) then
		Lunar.API:HideMinimapTime(LunarSphereSettings.hideTime, true);
	end

	-- Destory these functions, we're done with them.
	Lunar.Debug("LunarSphere memory usage (before memory dump): " .. Lunar.API:MemoryUsage());
	Lunar.Items.BuildLookupStrings = nil;
	Lunar.Items.BuildData = nil;
	Lunar.Items.OnUpdate = nil;
	collectgarbage();
	Lunar.Debug("LunarSphere memory usage (after memory dump): " .. Lunar.API:MemoryUsage());
	--	Lunar.API:SupportForDrDamage();
end

-- /***********************************************
--  * DebugPrint
--  * ========================
--  *
--  * Dumps the entire database of recognized items
--  *
--  * Accepts: None
--  * Returns: None
--  *********************
function Lunar.Items:DebugPrint()
	-- Announce who we are
	DEFAULT_CHAT_FRAME:AddMessage("LunarItems Module Debug Mode");
	DEFAULT_CHAT_FRAME:AddMessage("============================");

	-- Announce what we are doing
	DEFAULT_CHAT_FRAME:AddMessage("List of recognized potions, food, drink, mounts, bandages, and hearthstone...");
	DEFAULT_CHAT_FRAME:AddMessage("============================");

	-- Announce our data
	for nameIndex = 1, Lunar.Items.totalItemTypes do
		if (itemData[itemTableNames[nameIndex]][1]) then
			if (itemTableNames[nameIndex] ~= "mount") then
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Catagory: " .. itemTableNames[nameIndex]);
				if (itemStrength[itemTableNames[nameIndex]][0]) then
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Lowest item from '" ..
						itemTableNames[nameIndex] ..
						"' catagory: " ..
						itemData[itemTableNames[nameIndex]][itemStrength[itemTableNames[nameIndex]][0]].name);
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Highest item from '" ..
						itemTableNames[nameIndex] ..
						"' catagory: " ..
						itemData[itemTableNames[nameIndex]][itemStrength[itemTableNames[nameIndex]][1]].name);
				end

				DEFAULT_CHAT_FRAME:AddMessage(
					"|cFFFFFF00All items of this type found so far that is or was in inventory:");

				for index = 1, table.getn(itemData[itemTableNames[nameIndex]]) do
					DEFAULT_CHAT_FRAME:AddMessage(itemData[itemTableNames[nameIndex]][index].name ..
						": found " .. itemData[itemTableNames[nameIndex]][index].count);
				end
			else
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Catagory: " .. itemTableNames[nameIndex]);
				DEFAULT_CHAT_FRAME:AddMessage(
					"|cFFFFFF00All items of this type found so far that is or was in inventory:");

				for index = 1, table.getn(itemData[itemTableNames[nameIndex]]) do
					local objName = itemData[itemTableNames[nameIndex]][index].name;

					if (string.sub(objName, 1, 2) == "**") then
						objName = GetSpellInfo(string.sub(objName, 3));
					end

					DEFAULT_CHAT_FRAME:AddMessage(": found: " .. objName);
				end
			end
			DEFAULT_CHAT_FRAME:AddMessage(" ");
		end
	end

	-- Drop our ending line
	DEFAULT_CHAT_FRAME:AddMessage("============================");
end

-- /***********************************************
--  * BuildLookupStrings
--  * ========================
--  *
--  * Stores localized item info into the search database
--  *
--  * Accepts: None
--  * Returns: None
--  *********************
function Lunar.Items:BuildLookupStrings()
	-- Populate the search tables with localized information to be used
	-- for checking items in inventory to see if they are the types of
	-- items we need.

	-- Create our locals
	local key, value, index;

	-- First, if we have a saved table of data, load it. While we're doing this, also
	-- delete the itemSpellID data, since we won't be searching for it anymore.
	if (LunarSphereGlobal) then
		if (LunarSphereGlobal.searchData) then
			if (LunarSphereGlobal.searchData[GetLocale()]) then
				for key, value in pairs(LunarSphereGlobal.searchData[GetLocale()]) do
					searchData[key] = value;
					itemSpellID[key] = nil;
				end
			end
		end
	end

	searchData.drink         = (C_Spell.GetSpellInfo(430) or {}).name
	searchData.food          = (C_Spell.GetSpellInfo(433) or {}).name
	searchData.potionHealing = (C_Spell.GetSpellInfo(441) or {}).name -- healing-potion
	searchData.potionMana    = (C_Spell.GetSpellInfo(2023) or {}).name -- restore-mana
	searchData.energyDrink   = (C_Spell.GetSpellInfo(9512) or {}).name
	searchData.bandage       = (C_Spell.GetSpellInfo(746) or {}).name
	searchData.healthStone   = (C_Spell.GetSpellInfo(6262) or {}).name -- minor-healthstone (works for Retail)
	searchData.refreshment   = (C_Spell.GetSpellInfo(44166) or {}).name

	Lunar.Locale["_SUMMON"]  = select(2, C_Spell.GetSpellInfo(688))

	-- Now, run through each entry in the search data and make sure it has a spell attached to it.
	-- Make sure we skip mount, rage potion, and charges
	for index = 1, Lunar.Items.totalItemTypes do
		if ((itemTableNames[index] ~= "mount") and (itemTableNames[index] ~= "ragePotion") and (itemTableNames[index] ~= "charges") and (itemTableNames[index] ~= "healthStone") and (itemTableNames[index] ~= "companion")) then
			if (searchData[itemTableNames[index]] == nil) then
				if (itemTableNames[index] == "smallPet") then
					searchData[itemTableNames[index]] = select(3, C_AuctionHouse.GetAuctionItemSubClasses(11));
				else
					-- Add our current item spell type to the search table
					table.insert(itemSpellScan, itemTableNames[index]);

					-- Grab our spell if it exists. If it does exist, remove it from the search table
					searchData[itemTableNames[index]] = Lunar.Items:GetItemSpell(itemTableNames[index]);
					if (searchData[itemTableNames[index]] ~= nil) then
						table.remove(itemSpellScan);
					end
				end
			end
		end
	end

	-- If there is nothing left for us to search for later on, destroy the search table and the
	-- item spell function.
	if (itemSpellScan) then
		if (table.getn(itemSpellScan) == 0) then
			itemSpellScan = nil;
			Lunar.Items.GetItemSpell = nil;
		end
	end

	local tempWeapon, tempArmor, tempConsume = LSAUCCLASSES1, LSAUCCLASSES2, LSAUCCLASSES3

	if (Lunar.API:IsVersionRetail()) then
		local _, tempReagent = C_AuctionHouse.GetAuctionItemSubClasses(12);
	else
		local _, tempReagent = GetAuctionItemSubClasses(12);
	end
	--	local tempWeapon,tempArmor,_,tempConsume;
	--	local _, tempReagent = C_AuctionHouse.GetAuctionItemSubClasses(10);

	-- This is the most retarded thing ever. GetItemInfo will return on the
	-- 12th value the classID and on the 13th the subclassID, both of which do
	-- _NOT_ change with the locale. Talk about reinventing the wheel.

	if (not searchData.weapon) or (searchData.weapon == "") then
		searchData.weapon = tempWeapon;
		if (not searchData.weapon) or (searchData.weapon == "") then
			_, _, _, _, _, searchData.weapon = GetItemInfo(2139); -- Dirk
		end
	end

	if (not searchData.armor) or (searchData.armor == "") then
		searchData.armor = tempArmor;
		if (not searchData.armor) or (searchData.armor == "") then
			_, _, _, _, _, searchData.armor = GetItemInfo(2960); -- Journeyman's Gloves
		end
	end

	if (not searchData.consume) or (searchData.consume == "") then
		searchData.consume = tempConsume;
		if (not searchData.consume) or (searchData.consume == "") then
			_, _, _, _, _, searchData.consume = GetItemInfo(159); -- Refreshing spring water
		end
	end

	if (not searchData.reagent) or (searchData.reagent == "") then
		searchData.reagent = tempReagent;
		if (not searchData.reagent) or (searchData.reagent == "") then
			_, _, _, _, _, _, searchData.reagent = GetItemInfo(4470); -- Simple Wood
		end
	end

	_, _, _, _, _, searchData.misc, searchData.junk, _ = GetItemInfo(6948); -- Item: Hearthstone

	-- Store the reagent string as part of the Item module table as well
	Lunar.Items.reagentString = searchData.reagent;

	-- Now, if any of our search data came up nil, let's check if the player has seen other varieties of those
	-- items types and populate our data that way.

	-- Save our searchData to the global variables
	if (not LunarSphereGlobal) then
		LunarSphereGlobal = {};
	end
	if (not LunarSphereGlobal.searchData) then
		LunarSphereGlobal.searchData = {};
	end
	if (not LunarSphereGlobal.searchData[GetLocale()]) then
		LunarSphereGlobal.searchData[GetLocale()] = {};
	end

	-- Save our standard data
	for index = 1, Lunar.Items.totalItemTypes - 2 do
		LunarSphereGlobal.searchData[GetLocale()][itemTableNames[index]] = searchData[itemTableNames[index]];
	end

	--	-- Now save our mana stone data
	--	LunarSphereGlobal.searchData[GetLocale()].manaStone = searchData.manaStone;
end

function Lunar.Items:GetItemSpell(itemCatagory)
	local index, itemSpell;

	for index = 1, (string.len(itemSpellID[itemCatagory]) / 6) do
		itemSpell = GetItemSpell(tonumber(string.sub(itemSpellID[itemCatagory], (index - 1) * 6 + 1, index * 6 - 1)));

		if (itemSpell) then
			break;
		end
	end

	return itemSpell;
end

-- /***********************************************
--  * BuildData
--  * ========================
--  *
--  * Stores localized item into the search database
--  *
--  * Accepts: None
--  * Returns: None
--  *********************
function Lunar.Items:BuildData()
	-- Safety code, to ensure that we have the search lookup data before we
	-- continue. This would only happen if the module was created improperly
	-- (i.e., not initialized)
	if (searchData.drink == nil) then
		Lunar.Items:BuildLookupStrings();
	end

	-- Now, turn off our debug print. Ew.
	Lunar.Items.debugItemPrint = nil;
end

-- /***********************************************
--  * UpdateItemCounts
--  * ========================
--  *
--  * Crawls through the item database and refreshes each item's count
--  *
--  * Accepts: None
--  * Returns: None
--  *********************
function Lunar.Items:UpdateItemCounts()
	-- Create our locals
	local nameIndex, index;

	-- Scan each name catagory
	for nameIndex = 1, Lunar.Items.totalItemTypes do
		if (itemTableNames[nameIndex] ~= "mount") then
			-- If there are items in this catagory ...
			if (itemData[itemTableNames[nameIndex]][1]) then
				-- Cycle through each item and assign its count.
				for index = 1, table.getn(itemData[itemTableNames[nameIndex]]) do
					itemData[itemTableNames[nameIndex]][index].count = GetItemCount(itemData[itemTableNames[nameIndex]]
						[index].name);
					itemData[itemTableNames[nameIndex]][index].count = GetItemCount(
						itemData[itemTableNames[nameIndex]][index].name, nil, true);
				end
			end
		end
	end
end

-- Returns the ID for a mount item
function Lunar.Items:getMountID(mount)
	local itemID

	if type(mount) == "number" then
		itemID = mount
	elseif mount.spellMount then
		-- This code is a fucking mess, mount.itemID doesn't holds the ID if
		-- it's a spellMount.
		itemID = tonumber(string.sub(mount.name, 3))
	else
		itemID = mount.itemID
	end

	return itemID
end

-- Global table used in ClassicIsMount
-- According to wowhead, the IDs seem to hold across all three clients.
tableMountsIDNonEpic = {
	2414, -- pinto-bridle
	5656, -- brown-horse-bridle
	5655, -- chestnut-mare-bridle
	2411, -- black-stallion-bridle
	5872, -- brown-ram
	5864, -- gray-ram
	5873, -- white-ram
	8632, -- reins-of-the-spotted-frostsaber
	8631, -- reins-of-the-striped-frostsaber
	8629, -- reins-of-the-striped-nightsaber
	8595, -- blue-mechanostrider
	13321, -- green-mechanostrider
	8563, -- red-mechanostrider
	13322, -- unpainted-mechanostrider
	28481, -- brown-elekk
	29744, -- gray-elekk
	29743, -- purple-elekk
	5665, -- horn-of-the-dire-wolf
	1132, -- horn-of-the-timber-wolf
	5668, -- horn-of-the-brown-wolf
	13332, -- blue-skeletal-horse
	13333, -- brown-skeletal-horse
	13331, -- red-skeletal-horse
	15290, -- brown-kodo
	15277, -- gray-kodo
	8588, -- whistle-of-the-emerald-raptor
	8591, -- whistle-of-the-turquoise-raptor
	8592, -- whistle-of-the-violet-raptor
	29221, -- black-hawkstrider
	29222, -- purple-hawkstrider
	28927, -- red-hawkstrider
	29220, -- blue-hawkstrider
	21218, -- blue-qiraji-resonating-crystal
	21323, -- green-qiraji-resonating-crystal
	21324, -- yellow-qiraji-resonating-crystal
	21321, -- red-qiraji-resonating-crystal
	33976, -- brewfest-ram
	37827, -- brewfest-kodo
	25472, -- snowy-gryphon
	25471, -- ebon-gryphon
	25470, -- golden-gryphon
	25475, -- blue-windrider
	25476, -- green-windrider
	25474, -- tawny-windrider
	34060 -- flying-machine-control
}

-- Global table used in ClassicIsMountEpic
-- According to wowhead, the IDs seem to hold across all three clients.
tableMountsIDEpic = {
	18777, -- swift-brown-steed
	18776, -- swift-palomino
	18778, -- swift-white-steed
	18241, -- black-war-steed-bridle
	18244, -- black-war-ram
	18786, -- swift-brown-ram
	18787, -- swift-gray-ram
	18785, -- swift-white-ram
	18766, -- reins-of-the-swift-frostsaber
	18767, -- reins-of-the-swift-mistsaber
	18902, -- reins-of-the-swift-stormsaber
	18772, -- swift-green-mechanostrider
	18773, -- swift-white-mechanostrider
	18774, -- swift-yellow-mechanostrider
	18242, -- reins-of-the-black-war-tiger
	18243, -- black-battlestrider
	19030, -- stormpike-battle-charger
	13086, -- reins-of-the-winterspring-frostsaber
	18796, -- horn-of-the-swift-brown-wolf
	18798, -- horn-of-the-swift-gray-wolf
	18797, -- horn-of-the-swift-timber-wolf
	13334, -- green-skeletal-warhorse
	18791, -- purple-skeletal-warhorse
	18794, -- great-brown-kodo
	18795, -- great-gray-kodo
	18793, -- great-white-kodo
	18788, -- swift-blue-raptor
	18789, -- swift-olive-raptor
	18790, -- swift-orange-raptor
	18245, -- horn-of-the-black-war-wolf
	18248, -- red-skeletal-warhorse
	18247, -- black-war-kodo
	18246, -- whistle-of-the-black-war-raptor
	19029, -- horn-of-the-frostwolf-howler
	13335, -- deathchargers-reins
	19872, -- swift-razzashi-raptor
	19902, -- swift-zulian-tiger
	21176, -- black-qiraji-resonating-crystal
	33809, -- amani-war-bear
	44157, -- turbo-charged-flying-machine
	29224, -- swift-purple-hawkstrider
	29223, -- swift-green-hawkstrider
	28936, -- swift-pink-hawkstrider
	29745, -- great-blue-elekk
	29747, -- great-purple-elekk
	29746, -- great-green-elekk
	25529, -- swift-purple-gryphon
	25473, -- swift-blue-gryphon
	25527, -- swift-red-gryphon
	25528, -- swift-green-gryphon
	25477, -- swift-red-windrider
	25531, -- swift-green-windrider
	25532, -- swift-yellow-windrider
	25533, -- swift-purple-windrider
	29471, -- reins-of-the-black-war-tiger
	29467, -- black-war-ram
	29465, -- black-battlestrider
	29466, -- black-war-kodo
	29472, -- whistle-of-the-black-war-raptor
	29469, -- horn-of-the-black-war-wolf
	29470, -- red-skeletal-warhorse
	34129, -- swift-warstrider
	28915, -- reins-of-the-dark-riding-talbuk
	29228, -- reins-of-the-dark-war-talbuk
	32768, -- reins-of-the-raven-lord
	35513, -- swift-white-hawkstrider
	30480, -- fiery-warhorses-reins
	33977, -- swift-brewfest-ram
	37828, -- great-brewfest-kodo
	37012, -- the-horsemans-reins
	33999, -- cenarion war hippogryph
	32858, -- reins of the azure netherwing drake
	32857, -- reins of the onyx netherwing drake
	32860, -- reins of the purple netherwing drake
	32859, -- reins of the cobalt netherwing drake
	32862, -- reins of the violet netherwing drake
	32861, -- reins of the veridian netherwing drake
	31830, -- reins-of-the-cobalt-riding-talbuk
	31835, -- reins-of-the-white-riding-talbuk
	31833, -- reins-of-the-tan-riding-talbuk
	31832, -- reins-of-the-silver-riding-talbuk
	29227, -- reins-of-the-cobalt-war-talbuk
	29103, -- reins-of-the-white-war-talbuk
	29105, -- reins-of-the-tan-war-talbuk
	29229, -- reins-of-the-silver-war-talbuk
	32316, -- purple riding nether ray
	32319, -- blue riding nether ray
	32317, -- red riding nether ray
	32314, -- green riding nether ray
	32318 -- silver riding nether ray
}

-- Returns true if the mount is a flying mount.
-- Sets the `isFlying` property in the mount.
--
-- By checking the ID, we avoid handling the localized mount names.
function Lunar.Items:BCCIsFlyingMount(mount)
	local itemID = Lunar.Items:getMountID(mount)

	local items = {
		25474, -- tawny windrider
		25477, -- swift red windrider
		25475, -- blue windrider
		25533, -- swift purple windrider
		25476, -- green windrider
		25532, -- swift yellow windrider
		25531, -- swift green windrider
		25473, -- swift blue gryphon
		25470, -- golden gryphon
		25472, -- snowy gryphon
		25471, -- ebon gryphon
		25529, -- swift purple gryphon
		25527, -- swift red gryphon
		25528, -- swift green gryphon
		33999, -- cenarion war hippogryph
		32858, -- reins of the azure netherwing drake
		32857, -- reins of the onyx netherwing drake
		32860, -- reins of the purple netherwing drake
		32859, -- reins of the cobalt netherwing drake
		32862, -- reins of the violet netherwing drake
		32861, -- reins of the veridian netherwing drake
		32316, -- purple riding nether ray
		32319, -- blue riding nether ray
		32317, -- red riding nether ray
		32314, -- green riding nether ray
		32318, -- silver riding nether ray
		32458, -- ashes of alar
		34060, -- flying-machine-control
		34061, -- turbo-charged-flying-machine-control
		30609, -- swift-nether-drake
		37676, -- vengeful-nether-drake
		34092, -- merciless-nether-drake
		43516 -- brutal-nether-drake

	}
	return tContains(items, itemID)
end

-- Returns true if the mount is a epic mount.
-- By checking the ID, we avoid handling the localized mount names.
function Lunar.Items:ClassicIsMountEpic(mount)
	local itemID = Lunar.Items:getMountID(mount)

	--	print("Lunar.Items:ClassicIsMountEpic 872 : ", itemID, tContains(tableMountsIDEpic, itemID))

	if (tContains(tableMountsIDEpic, itemID)) then
		return true
	end

	-- mount can be a spell mount
	local spell_mounts = {
		23214, -- summon-charger : Human,  Dwarf, Draenei
		34767, -- summon-charger : Blood Elf
		5784, -- summon-felsteed
	}

	--	print("Lunar.Items:ClassicIsMountEpic 891 : ", itemID, mount.spellMount, tContains(spell_mounts, itemID) )

	-- Mount was found in the table above, just return false
	if (type(mount) ~= "number" and mount.spellMount and tContains(spell_mounts, itemID)) then
		return true
	end

	-- Not an epic mount, return false
	return false
end

function Lunar.Items:WotLKIsMountEpic(mount)
	local itemID = Lunar.Items:getMountID(mount)
	local mounts = {
		579, -- Red Wolf
		15779, -- White Mechanostrider Mod B
		16055, -- Black Nightsaber
		16056, -- Ancient Frostsaber
		16080, -- Red Wolf
		16081, -- Arctic Wolf
		16082, -- Palomino
		16083, -- White Stallion
		16084, -- Mottled Red Raptor
		17229, -- Winterspring Frostsaber
		17450, -- Ivory Raptor
		17459, -- Icy Blue Mechanostrider Mod A
		17460, -- Frost Ram
		17461, -- Black Ram
		17465, -- Green Skeletal Warhorse
		17481, -- Rivendare's Deathcharger
		18991, -- Green Kodo
		18992, -- Teal Kodo
		22717, -- Black War Steed
		22718, -- Black War Kodo
		22719, -- Black Battlestrider
		22720, -- Black War Ram
		22721, -- Black War Raptor
		22722, -- Red Skeletal Warhorse
		22723, -- Black War Tiger
		22724, -- Black War Wolf
		23161, -- Dreadsteed
		23214, -- Charger
		23219, -- Swift Mistsaber
		23221, -- Swift Frostsaber
		23222, -- Swift Yellow Mechanostrider
		23223, -- Swift White Mechanostrider
		23225, -- Swift Green Mechanostrider
		23227, -- Swift Palomino
		23228, -- Swift White Steed
		23229, -- Swift Brown Steed
		23238, -- Swift Brown Ram
		23239, -- Swift Gray Ram
		23240, -- Swift White Ram
		23241, -- Swift Blue Raptor
		23242, -- Swift Olive Raptor
		23243, -- Swift Orange Raptor
		23246, -- Purple Skeletal Warhorse
		23247, -- Great White Kodo
		23248, -- Great Gray Kodo
		23249, -- Great Brown Kodo
		23250, -- Swift Brown Wolf
		23251, -- Swift Timber Wolf
		23252, -- Swift Gray Wolf
		23338, -- Swift Stormsaber
		23509, -- Frostwolf Howler
		23510, -- Stormpike Battle Charger
		24242, -- Swift Razzashi Raptor
		24252, -- Swift Zulian Tiger
		25863, -- Black Qiraji Battle Tank
		25953, -- Blue Qiraji Battle Tank
		26054, -- Red Qiraji Battle Tank
		26055, -- Yellow Qiraji Battle Tank
		26056, -- Green Qiraji Battle Tank
		26655, -- Black Qiraji Battle Tank
		26656, -- Black Qiraji Battle Tank
		28828, -- Nether Drake
		32242, -- Swift Blue Gryphon
		32246, -- Swift Red Wind Rider
		32289, -- Swift Red Gryphon
		32290, -- Swift Green Gryphon
		32292, -- Swift Purple Gryphon
		32295, -- Swift Green Wind Rider
		32296, -- Swift Yellow Wind Rider
		32297, -- Swift Purple Wind Rider
		33660, -- Swift Pink Hawkstrider
		34767, -- Thalassian Charger
		34790, -- Dark War Talbuk
		34896, -- Cobalt War Talbuk
		34897, -- White War Talbuk
		34898, -- Silver War Talbuk
		34899, -- Tan War Talbuk
		35025, -- Swift Green Hawkstrider
		35027, -- Swift Purple Hawkstrider
		35028, -- Swift Warstrider
		35712, -- Great Green Elekk
		35713, -- Great Blue Elekk
		35714, -- Great Purple Elekk
		36702, -- Fiery Warhorse
		37015, -- Swift Nether Drake
		39315, -- Cobalt Riding Talbuk
		39316, -- Dark Riding Talbuk
		39317, -- Silver Riding Talbuk
		39318, -- Tan Riding Talbuk
		39319, -- White Riding Talbuk
		39798, -- Green Riding Nether Ray
		39800, -- Red Riding Nether Ray
		39801, -- Purple Riding Nether Ray
		39802, -- Silver Riding Nether Ray
		39803, -- Blue Riding Nether Ray
		40192, -- Ashes of Al'ar
		41252, -- Raven Lord
		41513, -- Onyx Netherwing Drake
		41514, -- Azure Netherwing Drake
		41515, -- Cobalt Netherwing Drake
		41516, -- Purple Netherwing Drake
		41517, -- Veridian Netherwing Drake
		41518, -- Violet Netherwing Drake
		42777, -- Swift Spectral Tiger
		43688, -- Amani War Bear
		43900, -- Swift Brewfest Ram
		43927, -- Cenarion War Hippogryph
		44151, -- Turbo-Charged Flying Machine
		44317, -- Merciless Nether Drake
		44744, -- Merciless Nether Drake
		46199, -- X-51 Nether-Rocket X-TREME
		46628, -- Swift White Hawkstrider
		48027, -- Black War Elekk
		48778, -- Acherus Deathcharger
		48954, -- Swift Zhevra
		49193, -- Vengeful Nether Drake
		49322, -- Swift Zhevra
		49379, -- Great Brewfest Kodo
		51412, -- Big Battle Bear
		54753, -- White Polar Bear
		55164, -- Swift Spectral Gryphon
		55531, -- Mechano-Hog
		58615, -- Brutal Nether Drake
		59567, -- Azure Drake
		59568, -- Blue Drake
		59569, -- Bronze Drake
		59570, -- Red Drake
		59571, -- Twilight Drake
		59572, -- Black Polar Bear
		59650, -- Black Drake
		59785, -- Black War Mammoth
		59788, -- Black War Mammoth
		59791, -- Wooly Mammoth
		59793, -- Wooly Mammoth
		59797, -- Ice Mammoth
		59799, -- Ice Mammoth
		59961, -- Red Proto-Drake
		59976, -- Black Proto-Drake
		59996, -- Blue Proto-Drake
		60002, -- Time-Lost Proto-Drake
		60021, -- Plagued Proto-Drake
		60024, -- Violet Proto-Drake
		60025, -- Albino Drake
		60114, -- Armored Brown Bear
		60116, -- Armored Brown Bear
		60118, -- Black War Bear
		60119, -- Black War Bear
		60136, -- Grand Caravan Mammoth
		60140, -- Grand Caravan Mammoth
		60424, -- Mekgineer's Chopper
		61229, -- Armored Snowy Gryphon
		61230, -- Armored Blue Wind Rider
		61294, -- Green Proto-Drake
		61309, -- Magnificent Flying Carpet
		61425, -- Traveler's Tundra Mammoth
		61447, -- Traveler's Tundra Mammoth
		61465, -- Grand Black War Mammoth
		61467, -- Grand Black War Mammoth
		61469, -- Grand Ice Mammoth
		61470, -- Grand Ice Mammoth
		61996, -- Blue Dragonhawk
		61997, -- Red Dragonhawk
		62048, -- Illidari Doomhawk
		63232, -- Stormwind Steed
		63635, -- Darkspear Raptor
		63636, -- Ironforge Ram
		63637, -- Darnassian Nightsaber
		63638, -- Gnomeregan Mechanostrider
		63639, -- Exodar Elekk
		63640, -- Orgrimmar Wolf
		63641, -- Thunder Bluff Kodo
		63642, -- Silvermoon Hawkstrider
		63643, -- Forsaken Warhorse
		63796, -- Mimiron's Head
		63844, -- Argent Hippogryph
		63956, -- Ironbound Proto-Drake
		63963, -- Rusted Proto-Drake
		64656, -- Blue Skeletal Warhorse
		64659, -- Venomhide Ravasaur
		64927, -- Deadly Gladiator's Frost Wyrm
		65439, -- Furious Gladiator's Frost Wyrm
		65637, -- Great Red Elekk
		65638, -- Swift Moonsaber
		65639, -- Swift Red Hawkstrider
		65640, -- Swift Gray Steed
		65641, -- Great Golden Kodo
		65642, -- Turbostrider
		65643, -- Swift Violet Ram
		65644, -- Swift Purple Raptor
		65645, -- White Skeletal Warhorse
		65646, -- Swift Burgundy Wolf
		66087, -- Silver Covenant Hippogryph
		66088, -- Sunreaver Dragonhawk
		66090, -- Quel'dorei Steed
		66091, -- Sunreaver Hawkstrider
		66122, -- Magic Rooster
		66123, -- Magic Rooster
		66124, -- Magic Rooster
		66846, -- Ochre Skeletal Warhorse
		66906, -- Argent Charger
		67336, -- Relentless Gladiator's Frost Wyrm
		67466, -- Argent Warhorse
		68056, -- Swift Horde Wolf
		68057, -- Swift Alliance Steed
		68187, -- Crusader's White Warhorse
		68188, -- Crusader's Black Warhorse
		69395, -- Onyxian Drake
		71810, -- Wrathful Gladiator's Frost Wyrm
		72807, -- Icebound Frostbrood Vanquisher
		72808, -- Bloodbathed Frostbrood Vanquisher
		73313, -- Crimson Deathcharger
		74918, -- Wooly White Rhino
		75596, -- Frosty Flying Carpet
	}

	return tContains(mounts, itemID)
end

function Lunar.Items:IsMountEpic(mount)
	if (Lunar.API:IsVersionWotLK()) then
		return Lunar.Items:WotLKIsMountEpic(mount)
	end

	if (Lunar.API:IsVersionClassic()) then
		return Lunar.Items:ClassicIsMountEpic(mount)
	end

	return false
end

-- Returns true if the item is a mount.
--
-- The itemSubType from GetItemInfo() for mounts in Classic is 'Junk',
-- the itemSubType from GetItemInfo() for mounts in BCC is 'Mount'.
-- Thanks Blizzard!
-- By checking the ID, we avoid handling the localized mount names.
function Lunar.Items:ClassicIsMount(mount)
	local itemID = Lunar.Items:getMountID(mount)
	--print("Lunar.Items:ClassicIsMount 922 : ", itemID)

	-- If it's an epic mount, it's a mount
	if Lunar.Items:ClassicIsMountEpic(mount) then
		return true
	end

	-- If it's an AQ40 mount, it's a mount
	if Lunar.Items:IsMountAQ40(mount) then
		return true
	end

	-- Check for non-epic mounts
	if tContains(tableMountsIDNonEpic, itemID) then
		return true
	end

	if Lunar.Items:BCCIsFlyingMount(mount) then
		return true
	end

	-- Not an item mount, could be a spell mount.
	-- Epic spell mounts are handled in ClassicIsMountEpic, so we just check the
	-- regular mounts here.
	local spell_mounts = {
		13819, -- summon-warhorse
		34769, -- summon-warhorse (Blood Elf version)
		5784, -- summon-felsteed
	}

	--	print("Lunar.Items:ClassicIsMountEpic 849 : ", itemID, mount.spellMount, not_epic )

	-- Mount was found in the table above, just return true
	if (type(mount) ~= "number" and mount.spellMount and tContains(spell_mounts, itemID)) then
		return true
	end

	-- Not a mount
	return false
end

-- Returns true if the mount is an AQ40 mount.
-- By checking the ID, we avoid handling the localized mount names.
function Lunar.Items:IsMountAQ40(mount)
	local itemID = Lunar.Items:getMountID(mount)
	local _, _, _, t = GetBuildInfo();
	local mounts

	-- Retail or WotLK
	if (t >= 30000) then
		-- From https://wowpedia.fandom.com/wiki/MountID
		-- Mount : Spell ID
		-- Blue Qiraji Battle Tank : 25953
		-- Red Qiraji Battle Tank : 26054
		-- Yellow Qiraji Battle Tank : 26055
		-- Green Qiraji Battle Tank : 26056
		-- Black Qiraji Battle Tank : 26655
		-- Black Qiraji Battle Tank : 26656
		-- Black Qiraji Battle Tank : 25863
		-- https://www.wowhead.com/wotlk/spell=31700/black-qiraji-battle-tank

		mounts = {
			25953, -- Blue Qiraji Battle Tank
			26054, -- Red Qiraji Battle Tank
			26055, -- Yellow Qiraji Battle Tank
			26056, -- Green Qiraji Battle Tank
			26655, -- Black Qiraji Battle Tank
			26656, -- Black Qiraji Battle Tank
			25863, -- Black Qiraji Battle Tank
			31700 -- black-qiraji-battle-tank
		}
		-- SoM
	else
		mounts = {
			21218, -- blue-qiraji-resonating-crystal
			21323, -- green-qiraji-resonating-crystal
			21324, -- yellow-qiraji-resonating-crystal
			21321, -- red-qiraji-resonating-crystal
			21176 -- black-qiraji-resonating-crystal
		}
	end

	return tContains(mounts, itemID)
end

-- Returns true if the mount is an 310 % speed mount.
-- By checking the ID, we avoid handling the localized mount names.
function Lunar.Items:IsMountEpic310(mount)
	local itemID = Lunar.Items:getMountID(mount)
	local _, _, _, t = GetBuildInfo();
	local mounts


	-- Retail or WotLK
	if (t >= 30000) then
		-- From https://wowpedia.fandom.com/wiki/MountID
		-- Mount : Spell ID
		mounts = {
			37015, -- Swift Nether Drake
			40192, -- Ashes of Al'ar
			44317, -- Merciless Nether Drake
			44744, -- Merciless Nether Drake
			49193, -- Vengeful Nether Drake
			58615, -- Brutal Nether Drake
			59976, -- Black Proto-Drake
			60021, -- Plagued Proto-Drake
			60024, -- Violet Proto-Drake
			63796, -- Mimiron's Head
			63956, -- Ironbound Proto-Drake
			63963, -- Rusted Proto-Drake
			64927, -- Deadly Gladiator's Frost Wyrm
			65439, -- Furious Gladiator's Frost Wyrm
			67336, -- Relentless Gladiator's Frost Wyrm
			69395, -- Onyxian Drake
			71810, -- Wrathful Gladiator's Frost Wyrm
			72807, -- Icebound Frostbrood Vanquisher
			72808, -- Bloodbathed Frostbrood Vanquisher
		}

		-- SoM
	else
		mounts = {
			32458, -- ashes-of-alar
			30609, -- swift-nether-drake
			37676, -- vengeful-nether-drake
			34092, -- merciless-nether-drake
			43516 -- brutal-nether-drake
		}
	end

	return tContains(mounts, itemID)
end

-- /***********************************************
--  * UpdateLowHighItems
--  * ========================
--  *
--  * Crawls through the item database and updates the lowest and highest
--  * leveled item per catagory
--  *
--  * Accepts: None
--  * Returns: None
--  *********************
function Lunar.Items:UpdateLowHighItems()
	-- Create our locals
	local nameIndex, index, low, high, lowSpecial, highSpecial, lowCombo, highCombo, itemType
	local lowCooldown, highCooldown, lowNoCooldown, highNoCooldown, usableItem, bestRange;
	local cooldown, isFavourite, minLevel;
	local canFly = Lunar.API:IsFlyableArea()
	local inAQ = Lunar.API:IsInAQ();
	local Lunar_Seahorse = 0;
	local Lunar_AbyssalMount_Name = C_Spell.GetSpellInfo(75207).name

	local playerLevel = UnitLevel("player");

	-- Helps with selecting epic vs normal mounts
	local groundMountsEpic = {};
	local flyingMountsEpic = {};
	local flyingMountsEpic310 = {};

	bestRange = 100;
	if (playerLevel < 40) then
		bestRange = 1;
	end

	-- Wipe our ground and flying mounts table
	for index = 1, table.getn(favouriteMounts) do
		favouriteMounts[index] = nil;
	end
	for index = 1, table.getn(groundMounts) do
		groundMounts[index] = nil;
	end
	for index = 1, table.getn(striderMounts) do
		striderMounts[index] = nil;
	end
	for index = 1, table.getn(flyingMounts) do
		flyingMounts[index] = nil;
	end
	for index = 1, table.getn(swimmingMounts) do
		swimmingMounts[index] = nil;
	end
	for index = 1, table.getn(allMounts) do
		allMounts[index] = nil;
	end

	-- Scan each name catagory
	for nameIndex = 1, Lunar.Items.totalItemTypes do
		-- Reset our highest and lowest values
		lowCombo = nil;
		highCombo = nil;
		low = nil;
		high = nil;
		lowSpecial = nil;
		highSpecial = nil;
		lowNoCooldown = nil;
		highNoCooldown = nil;
		itemType = itemTableNames[nameIndex];

		--print("972 Lunar.Items:UpdateLowHighItems itemType : ", itemType)

		-- If there are items in this catagory ...
		if (itemType ~= "companion") and (itemType ~= "energyDrink") and (itemData[itemType][1]) then
			--print("977 Lunar.Items:UpdateLowHighItems getn : ", table.getn(itemData[itemType]))

			-- Cycle through each item and assign its count.
			for index = 1, table.getn(itemData[itemType]) do
				local _item = itemData[itemType][index]

				isFavourite = False;
				minLevel = (itemData[itemType][index].level)
				if (itemType == "mount" and minLevel > 500) then
					isFavourite = true;
					minLevel = minLevel - 500;
				end

				-- If the item is within level range and has a count, continue
				if ((minLevel <= playerLevel) and ((itemData[itemType][index].count > 0) or (itemData[itemType][index].spell))) then
					if Lunar.Items:CheckItemUseStatus(itemData[itemType][index].itemID, itemType) then
						-- If our lowest and highest haven't been set, set them to the current index
						if (low == nil) and (itemData[itemType][index].strength < 2000) then
							low = index;
							high = index;
							if (not lowCombo) then
								lowCombo = index;
								highCombo = index;
							end
						end

						-- If our lowest and highest specials don't exists, set them to the current index
						if (lowSpecial == nil) and (itemData[itemType][index].strength > 2000) then
							lowSpecial = index;
							highSpecial = index;
							if (not lowCombo) then
								lowCombo = index;
								highCombo = index;
							end
						end

						-- Mount Stuff is Here: only valid for the Retail client.
						-- Abyssal seahorse = 75207
						--mountType
						--    number - a number indicating the capabilities of the mount; known values include:
						--
						--        230 for most ground mounts
						--        231 for  [Riding Turtle] and Sea Turtle
						--        232 for  [Vashj'ir Seahorse] (was named Abyssal Seahorse prior to Warlords of Draenor)
						--        241 for Blue, Green, Red, and Yellow Qiraji Battle Tank (restricted to use inside Temple of Ahn'Qiraj)
						--        242 for Swift Spectral Gryphon (hidden in the mount journal, used while dead in certain zones)
						--        247 for Red Flying Cloud
						--        248 for most flying mounts, including those that change capability based on riding skill
						--        254 for Subdued Seahorse
						--        269 for Azure and Crimson Water Strider
						--        284 for Chauffeured Mekgineer's Chopper and Chauffeured Mechano-Hog



						if (itemType == "mount") then -- Sets up the various mount databases
							local _mount = itemData["mount"][index]
							local MountType = _mount.count;

							--print("1184 Lunar.Items:UpdateLowHighItems MountType : ", MountType)
							--print("    name: ", _mount.name, " (", index, ")")
							--print("    itemID: ", _mount.itemID)
							--print("    isFlying: ", _mount.isFlying)
							--print("    isEpic: ", _mount.isEpic)
							--print("    isEpic310: ", _mount.isEpic310)
							--print("    isAQ40: ", _mount.isAQ40)

							if (isFavourite) then
								table.insert(favouriteMounts, index);
							end

							-- Handle Classic and BCC mounts
							if (Lunar.API:IsVersionClassic() == true) then
								-- Check if we can use the ground mount
								if (inAQ == true) then
									-- AQ mounts can only be used in AQ
									if _mount.isAQ40 then
										table.insert(groundMounts, index);
									end
								else
									-- Regular mounts can not be used in AQ
									if not _mount.isAQ40 then
										if _mount.isFlying then
											table.insert(flyingMounts, index);
											if _mount.isEpic then
												table.insert(flyingMountsEpic, index);
											end
											if _mount.isEpic310 then
												table.insert(flyingMountsEpic310, index);
											end
										else
											--print("1216 UpdateLowHighItems insert groundMounts index", index)
											table.insert(groundMounts, index);
											if _mount.isEpic then
												--print("1219 UpdateLowHighItems insert groundMountsEpic index", index)
												table.insert(groundMountsEpic, index);
											end
										end
									end
								end
								-- Handle Retail and WotLK mounts
							elseif (MountType == 230 or MountType == 241 or MountType == 269 or MountType == 284) then -- Ground Mounts Only.
								if (inAQ == true) then
									-- AQ mounts can only be used in AQ
									if _mount.isAQ40 then
										table.insert(groundMounts, index);
									end
								else -- Not in AQ40
									if _mount.isAQ40 == false then
										table.insert(groundMounts, index);
										if _mount.isEpic then
											table.insert(groundMountsEpic, index);
										end
									end
								end
								table.insert(swimmingMounts, index);
							elseif ((MountType == 231) or (MountType == 232) or (MountType == 254)) then
								if (itemData[itemType][index].spell == Lunar_AbyssalMount_Name) then
									Lunar_Seahorse = index;
								else
									table.insert(swimmingMounts, index);
								end
							elseif (MountType == 247 or MountType == 248) then -- Only when CanFly
								-- flying and Ground Mounts only
								table.insert(flyingMounts, index);
								if _mount.isEpic then
									table.insert(flyingMountsEpic, index);
								end
								if _mount.isEpic310 then
									table.insert(flyingMountsEpic310, index);
								end

								table.insert(swimmingMounts, index);
							elseif (MountType == 269) then -- Only when Strider
								-- Strider Mounts only
								table.insert(striderMounts, index);
							end
						end

						-- If we have the high or low index already found, continue
						if (high) then
							-- If we found an item that's higher than or equal to the current highest, make it the new highest
							if (itemData[itemType][index].strength >= itemData[itemType][high].strength) and (itemData[itemType][index].strength < 2000) then
								high = index;
							end

							-- If we found an item that's lower than or equal to the current lowest, and this item is
							-- not already set as the highest item, make it the new lowest
							if (itemData[itemType][index].strength <= itemData[itemType][low].strength) and (itemData[itemType][index].strength < 2000) then
								if (high ~= index) then
									low = index;
								end
							end
						end

						-- If we have the high or low combos found, continue
						if (highCombo) then
							-- If we found an item that's higher than or equal to the current combo highest, make it the new highest
							if (itemData[itemType][index].strength >= itemData[itemType][highCombo].strength) then
								if ((select(2, Lunar.API:GetItemCooldown(itemData[itemType][index].name))) or (0)) <= 1 then
									highNoCooldown = index;
								end
								highCombo = index;
							end

							-- If we found an item that's lower than or equal to the current combo lowest, and this item is
							-- not already set as the highest item, make it the new lowest
							if (itemData[itemType][index].strength <= itemData[itemType][lowCombo].strength) then
								if (highCombo ~= index) then
									if ((select(2, Lunar.API:GetItemCooldown(itemData[itemType][index].name))) or (0)) <= 1 then
										lowNoCooldown = index;
									end
									lowCombo = index;
								end
							end
						end

						-- If we have the high or low special found, continue
						if (highSpecial) then
							-- If we found a special item that's higher than or equal to the current highest, make it the new highest
							if (highSpecial) then
								if (itemData[itemType][index].strength >= itemData[itemType][highSpecial].strength) and (itemData[itemType][index].strength > 2000) then
									highSpecial = index;
								end
							end

							-- If we found a special item that's lower than or equal to the current lowest, and this item is
							-- not already set as the highest item, make it the new lowest
							if (highSpecial) then
								if (itemData[itemType][index].strength <= itemData[itemType][lowSpecial].strength) and (itemData[itemType][index].strength > 2000) then
									if (highSpecial ~= index) then
										lowSpecial = index;
									end
								end
							end
						end
					end
				end
			end

			-- The energy drink section contains energy drinks and poisons, so I made this section a little odd...
		elseif (itemType == "energyDrink") then
			local itemStrength;

			-- Cycle through each item and assign its count.
			for index = 1, table.getn(itemData[itemType]) do
				-- If the item is within level range and has a count, continue
				if (itemData[itemType][index].level <= playerLevel) and (itemData[itemType][index].count > 0) then
					if Lunar.Items:CheckItemUseStatus(itemData[itemType][index].itemID, itemType) then
						itemStrength = itemData[itemType][index].strength;

						-- Deal with the energy drinks
						if (itemStrength < 1000) then
							-- Initialize our data
							if (low == nil) then
								low = index;
								high = index;

								-- Or work with existing data
							else
								-- If we found an item that's higher than or equal to the current highest, make it the new highest
								if (itemStrength >= itemData[itemType][high].strength) then
									high = index;
								end

								-- If we found an item that's lower than or equal to the current lowest, and this item is
								-- not already set as the highest item, make it the new lowest
								if (itemStrength <= itemData[itemType][low].strength) then
									if (high ~= index) then
										low = index;
									end
								end
							end
						end
					end
				end
			end
		end

		-- Mount Stuff is Here.
		-- Assign our new higher and lower values. We do things differently if it's
		-- the mount catagory though...
		if (itemType == "mount") then
			local Lunar_areaId = C_Map.GetBestMapForUnit("player");

			--print("Lunar_areaId : ", Lunar_areaId)

			RndGround = nil;
			RndFly = nil;
			RndSwim = nil;
			RndFavourite = nil;
			RndStrider = nil;
			RndMount = nil;

			if (table.getn(groundMountsEpic) > 0) then
				RndGround = groundMountsEpic[math.random(table.getn(groundMountsEpic))];
			end
			-- Choose a non-epic mount if we didn't select an epic
			if (RndGround == nil and table.getn(groundMounts) > 0) then
				RndGround = groundMounts[math.random(table.getn(groundMounts))];
			end

			if (table.getn(striderMounts) > 0) then
				RndStrider = striderMounts[math.random(table.getn(striderMounts))];
			end

			if (table.getn(favouriteMounts) > 0) then
				RndFavourite = favouriteMounts[math.random(table.getn(favouriteMounts))];
			end

			if (canFly) then
				if (table.getn(flyingMountsEpic310) > 0) then
					RndFly = flyingMountsEpic310[math.random(table.getn(flyingMountsEpic310))];
				end
				if (RndFly == nil and table.getn(flyingMountsEpic) > 0) then
					RndFly = flyingMountsEpic[math.random(table.getn(flyingMountsEpic))];
				end
				-- Choose a non-epic mount if we didn't select an epic
				if (RndFly == nil and table.getn(flyingMounts) > 0) then
					RndFly = flyingMounts[math.random(table.getn(flyingMounts))];
				end
			end

			if ((Lunar_areaId == 610) or (Lunar_areaId == 614) or (Lunar_areaId == 615)) then
				if (IsSubmerged() and Lunar_Seahorse ~= 0) then
					RndSwim = Lunar_Seahorse;
				else
					RndSwim = swimmingMounts[math.random(table.getn(swimmingMounts))];
				end
			elseif (table.getn(swimmingMounts) > 0) and (IsSwimming()) then
				RndSwim = swimmingMounts[math.random(table.getn(swimmingMounts))];
			end

			if (table.getn(allMounts) > 0) then
				RndMount = allMounts[math.random(table.getn(allMounts))];
			end

			if (IsSubmerged()) then
				itemStrength[itemType][0] = RndSwim; -- Or Swimming Mount
			elseif (canFly) then
				itemStrength[itemType][0] = RndFly; -- Random Flying Mount
			else
				itemStrength[itemType][0] = RndGround; -- Otherwise a Ground Mount
			end

			--print("itemType: 1424 ", itemType, ", ", itemStrength[itemType][0], "( ", type(itemStrength[itemType][0]), ")")
			--print("RndGround:     ", itemType, ", ", RndGround, "( ", type(RndGround), ")")
			--print("RndFly:        ", itemType, ", ", RndFly, "( ", type(RndFly), ")")
			--print("RndSwim        ", itemType, ", ", RndSwim, "( ", type(RndSwim), ")")
			--print("RndStrider     ", itemType, ", ", RndStrider, "( ", type(RndStrider), ")")
			--print("RndFavourite   ", itemType, ", ", RndFavourite, "( ", type(RndFavourite), ")")

			itemStrength[itemType][1] = RndGround; -- ground mounts
			itemStrength[itemType][2] = RndFly; -- flying mounts
			itemStrength[itemType][3] = RndSwim; -- Swimming mounts
			itemStrength[itemType][4] = RndStrider; -- Strider mounts
			itemStrength[itemType][5] = RndFavourite; -- Favourite mounts
		else
			-- Now, if the highCombo is different than the highNoCooldown, we use the item
			-- with no cooldown. The same for lowCombo/lowNoCooldown
			if (highCombo ~= highNoCooldown) and (highNoCooldown ~= nil) then
				highCombo = highNoCooldown
			end
			if (lowCombo ~= lowNoCooldown) and (lowNoCooldown ~= nil) then
				lowCombo = lowNoCooldown
			end

			itemStrength[itemType][0] = lowCombo;
			itemStrength[itemType][1] = highCombo;
			itemStrength[itemType][2] = low;
			itemStrength[itemType][3] = high;
			itemStrength[itemType][4] = lowSpecial;
			itemStrength[itemType][5] = highSpecial;
		end
	end

	-- Now, the healing and mana items need to be ordered some more, by type.
	-- The index ranges are as follows:
	-- 0 = lowest item
	-- 1 = highest item
	-- 2 = lowest potion
	-- 3 = highest potion
	-- 4 = lowest stone
	-- 5 = highest stone
	-- First, copy over the 0 and 1 strengths to the 2 and 3 (since these are just potions)
	-- Then, copy over the 0 and 1 strengths from the healthstones to this table
	-- Lastly, we check the strength of the potion against the healthstone. The strongest

	-- Now, update any button that needs updating
	if (Lunar.combatLockdown == true) then
		Lunar.Items.combatUpdate = true;
	else
		Lunar.Items:UpdateSpecialButtons();
	end
end

function Lunar.Items:CheckItemUseStatus(itemID, itemType)
	local usable = true;

	-- Specific location item check
	if string.find((specialUseID[itemType] or ("00000/")), itemID) then --and (itemID ~= "spellMount") then
		usable = nil;

		-- Set our tooltip up

		Lunar.Items.tooltip:ClearLines();
		Lunar.Items.tooltip:SetOwner(UIParent, "ANCHOR_NONE");
		Lunar.Items.tooltip:SetHyperlink("item:" .. itemID);

		-- Scan each line until all have been scanned or a match was found

		local searchText, textContainer, textLine;

		for textLine = 2, Lunar.Items.tooltip:NumLines() do
			searchText = nil;
			textContainer = _G[Lunar.Items.tooltip:GetName() .. "TextLeft" .. textLine];
			if (textContainer) then
				searchText = textContainer:GetText();
			end

			if (searchText) then
				if string.find(searchText, GetRealZoneText()) then
					usable = true;
					break;
				end
			end
		end
	end
	-- Generic PVP battleground item check

	if string.find(specialUseID.pvp, itemID) then
		usable = nil;
		if ((GetNumBattlefieldStats() or (0)) > 0) then
			usable = true;
		end
	end

	return usable;
end

function Lunar.Items:UpdateSpecialButtons()
	local index, clickType, buttonType, stance, button, lastUsedUpdate, objectTexture;
	local actionType, state

	-- Clear the cursor update information, since we don't need 'em.
	Lunar.Button.updateType, Lunar.Button.updateID, Lunar.Button.updateData = nil, nil, nil;

	-- Cycle through all buttons that have content
	for index = 0, 130 do
		if not (LunarSphereSettings.buttonData[index].empty) then
			if (index > 10) then
				button = _G["LunarSub" .. index .. "Button"]
			elseif (index == 0) then
				button = _G["LSmain"]
			else
				button = _G["LunarMenu" .. index .. "Button"]
			end

			editFound = nil;

			if (button) then
				-- Cycle through all stances we could use
				for stance = 0, GetNumShapeshiftForms() do
					for clickType = 1, 3 do
						buttonType = Lunar.Button:GetButtonType(index, stance, clickType) or (0);

						lastUsedUpdate = nil;
						if (buttonType == 3) and (button.subButtonType) then
							lastUsedUpdate = buttonType;
							buttonType = button.subButtonType;
						end

						if (buttonType >= 10) then
							if ((buttonType >= 10) and (buttonType < 90)) or ((buttonType >= 110) and (buttonType < 130)) or (buttonType == 132) then
								Lunar.Button:AssignByType(button, clickType, buttonType, stance, lastUsedUpdate);
								if (index > 10) then
									state = _G["LunarMenu" .. button.parentID .. "ButtonHeader"]:GetAttribute("state");
								elseif (index == 0) then
									state = _G["LunarSphereMainButtonHeader"]:GetAttribute("state");
								else
									state = _G["LunarMenu" .. index .. "ButtonHeader"]:GetAttribute("state");
								end

								if (tonumber(state) == stance) then
									actionType = button:GetAttribute("*type-S" .. state .. clickType);
									button:SetAttribute("*spell" .. clickType, "");
									button:SetAttribute("*action" .. clickType, "");
									button:SetAttribute("*item" .. clickType, "");
									button:SetAttribute("*macro" .. clickType, "");
									button:SetAttribute("*macrotext" .. clickType, "");
									if (LunarSphereSettings.buttonEditMode ~= true) and (actionType) and (actionType ~= "none") then
										actionName = button:GetAttribute("*" .. actionType .. "-S" .. state .. clickType);
										actionName2 = button:GetAttribute("*" ..
											actionType .. "2-S" .. state .. clickType);
										if (actionType == "macrotext") then
											button:SetAttribute("*type" .. clickType, "macro");
										else
											button:SetAttribute("*type" .. clickType, actionType);
										end
										if (actionName2) then
											button:SetAttribute("*" .. actionType .. clickType, actionName2);
										else
											button:SetAttribute("*" .. actionType .. clickType, actionName);
										end
									else
										button:SetAttribute("*type" .. clickType, "spell");
									end
								end


								-- Bag buttons!
							elseif (buttonType >= 90) and (buttonType <= 95) and (stance == button.currentStance) then
								objectTexture = Lunar.Button:GetBagTexture(buttonType);
								if (Lunar.Button:GetButtonSetting(index, stance, LUNAR_GET_SHOW_ICON) == clickType) then
									if (button.texture) then
										button.texture:SetTexture(objectTexture);
										SetPortraitToTexture(button.texture, objectTexture);
									elseif (index == 0) then
										Lunar.Sphere:SetSphereTexture();
									end
								end

								if (Lunar.Button:GetButtonSetting(index, stance, LUNAR_GET_SHOW_COUNT) == clickType) then
									Lunar.Button:UpdateBagDisplay(button, stance, clickType);
								end
							end
						end
					end
				end
			end -- end the  if (button) then
		end
	end

	if (Lunar.Button.currentMouseOverFrame ~= nil) then
		Lunar.Button.tooltipStance = nil;
		Lunar.Button:SetTooltip(Lunar.Button.currentMouseOverFrame);
	end
end

function Lunar.Items:GetItem(catagory, subIndex, onlyConjured)
	--print("Lunar.Items:GetItem 1244:", catagory, subIndex, onlyConjured)

	local returnedItem = "";
	local catagory1, catagory2, catagory3;

	if (catagory == "companion") then
		if (itemData[catagory][1]) then
			-- Pick a random companion
			returnedItem = itemData[catagory][math.random(1, table.getn(itemData[catagory]))].name
		end
	else
		if (itemStrength[catagory][subIndex]) then
			if (itemData[catagory][itemStrength[catagory][subIndex]]) then
				returnedItem = itemData[catagory][itemStrength[catagory][subIndex]].name;

				if (onlyConjured == true) and (itemData[catagory][itemStrength[catagory][subIndex]].strength < 1000) then
					returnedItem = "";
				end
			end
		end
	end

	-- Idea. If the itemStrength is a string, do a search for (1)::(2) where 1 will be the
	-- catagory to pull the data from, and 2 will be the index.


	return returnedItem;
end

function Lunar.Items:GetCatagoryName(index)
	return itemTableNames[index];
end

function Lunar.Items:GetItemType(index)
	return searchData[index];
end

function Lunar.Items:FindItemInCatagory(catagory, itemName)
	local index, found;

	if (catagory == "mount") then
		for index = 1, table.getn(allMounts) do
			if (itemName == itemData["mount"][allMounts[index]].spell) then
				found = true;
				break;
			end
		end
	elseif (catagory == "flyingMount") then
		for index = 1, table.getn(flyingMounts) do
			if (itemName == itemData["mount"][flyingMounts[index]].spell) then
				found = true;
				break;
			end
		end
	elseif (catagory == "swimmingMount") then
		for index = 1, table.getn(swimmingMounts) do
			if (itemName == itemData["mount"][swimmingMounts[index]].spell) then
				found = true;
				break;
			end
		end
	elseif (catagory == "groundMount") then
		for index = 1, table.getn(groundMounts) do
			if (itemName == itemData["mount"][groundMounts[index]].spell) then
				found = true;
				break;
			end
		end
	elseif (catagory == "striderMount") then
		for index = 1, table.getn(striderMounts) do
			if (itemName == itemData["mount"][striderMounts[index]].spell) then
				found = true;
				break;
			end
		end
	elseif (catagory == "favouriteMount") then
		for index = 1, table.getn(favouriteMounts) do
			if (itemName == itemData["mount"][favouriteMounts[index]].spell) then
				found = true;
				break;
			end
		end
	elseif (catagory == "companion") then
		for index = 1, table.getn(itemData["companion"]) do
			if (itemName == itemData["companion"][index].spell) then
				found = true;
				break;
			end
		end
	else
		for index = 1, table.getn(itemData[catagory]) do
			if (itemName == itemData[catagory][index].name) then
				found = true;
				break;
			end
		end
	end
	return found;
end

function Lunar.Items:CompareItemSpellCatagory(compareSpell, itemCatagory)
	-- Set our locals
	local index, itemSpell;
	itemSpell = nil;

	-- Search though all items of the item catagory and see if we found a match. If there is a match, return
	-- the spell name that was matched. Otherwise, it will be nil.
	for index = 1, (string.len(itemSpellID[itemCatagory]) / 6) do
		if (compareSpell == GetItemSpell(tonumber(string.sub(itemSpellID[itemCatagory], (index - 1) * 6 + 1, index * 6 - 1)))) then
			itemSpell = compareSpell;
			break;
		end
	end

	return itemSpell;
end

function Lunar.Items:BuildSpellMountData()
	local locale = string.sub(GetLocale(), 1, 2);
	local db = Lunar.Items;

	-- Translations from google and some comparisons of tooltips found
	-- on wowhead.com. Various google translations to try and fine the
	-- korean and chinese translations that will hopefully work...

	Lunar.Items.BuildSpellMountData = nil;
end

function Lunar.Items:RetailScanForSpellMounts()
	local index, spellID, textLine, searchText, textContainer, speed, itemLevel, mountType, spellName, spellTexture;

	--local locKalimdor, locEastern, locOutland, locNorthrend, locMaelstrom, locPandaren, locDreanor = GetMapContinents();

	local factionData = C_Reputation.GetFactionDataByID(1271)
	if factionData then
		local name = factionData.name
		local description = factionData.description
		local standingID = factionData.standingID
		-- Other processing as needed
	end
	local LunarProfValue = Lunar.API:UserGetProfession();
	local mountIDs;

	-- Mount Stuff is Here.
	--	for index = 1, C_MountJournal.GetNumMounts() do

	for index, id in pairs(C_MountJournal.GetMountIDs()) do
		local spellName, spellID, _, _, isUsable, _, isFavourite, _, _, charHidden, isOwned = C_MountJournal
			.GetMountInfoByID(id);

		local spellTexture, _, _, _, mountType = C_MountJournal.GetMountInfoExtraByID(id);

		speed = 60;
		itemLevel = 20;
		local playerLevel = UnitLevel("player");


		-- Abyssal seahorse = 75207

		--mountType
		--    number - a number indicating the capabilities of the mount; known values include:

		--        230 for most ground mounts
		--        231 for  [Riding Turtle] and Sea Turtle
		--        232 for  [Vashj'ir Seahorse] (was named Abyssal Seahorse prior to Warlords of Draenor)
		--        241 for Blue, Green, Red, and Yellow Qiraji Battle Tank (restricted to use inside Temple of Ahn'Qiraj)
		--        242 for Swift Spectral Gryphon (hidden in the mount journal, used while dead in certain zones)
		--        247 for Red Flying Cloud
		--        248 for most flying mounts, including those that change capability based on riding skill
		--        254 for Subdued Seahorse
		--        269 for Azure and Crimson Water Strider
		--        284 for Chauffeured Mekgineer's Chopper and Chauffeured Mechano-Hog

		-- Check for Favourite
		if (isFavourite) then
			itemLevel = 520
		end

		if (isUsable or spellID == 75207) then
			spellName = "**" .. spellID --.. "~" .. spellName .. "~" .. spellTexture;

			-- All mounts
			Lunar.Items:ModifyItemDataTable("mount", "exists", spellName, mountType, 1, itemLevel, "spellMount");
		end
	end
end

function Lunar.Items:ClassicScanForSpellMounts()
	local SpellMountsIDs = {
		23214, -- summon charger
		13819, -- summon warhorse
		34767, -- summon charger (Blood Elf)
		34769, -- summon warhorse (Blood Elf)
		5784, -- summon felsteed
		23161, -- summon dreadsteed
	}


	for _, spellID in ipairs(SpellMountsIDs)
	do
		local isUsable = IsSpellKnown(spellID)

		if (isUsable) then
			local spellName = "**" .. spellID --.. "~" .. spellName .. "~" .. spellTexture;

			local mountType = 248
			local itemLevel = UnitLevel("player")

			-- All mounts
			Lunar.Items:ModifyItemDataTable("mount", "exists", spellName, mountType, 1, itemLevel, "spellMount");
		end
	end
end

function Lunar.Items:ScanForSpellMounts()
	if (Lunar.API:IsVersionClassic() == true) then
		Lunar.Items:ClassicScanForSpellMounts()
	else
		Lunar.Items:RetailScanForSpellMounts()
	end
end

-- Returns the stone strength based on the item ID. Returns nil if the item Id
-- isn't a healthstone.
-- By checking the ID, we avoid handling the localized
-- stone names.
function Lunar.Items:GetHealthStoneStrength(itemId)
	if (Lunar.API:IsVersionRetail() == true) then
		return nil;
	end

	-- We have several healthstones with the same neame because of the
	-- Improved Healthstone talent.
	local items = {
		5512, -- minor healthstone (all clients)
		19004, -- minor healthstone (Classic & BCC)
		19005, -- minor healthstone (Classic & BCC)
		5509, -- healthstone (Classic & BCC)
		19008, -- healthstone (Classic & BCC)
		19009, -- healthstone (Classic & BCC)
		22103, -- master healthstone (only in BCC)
		22104, -- master healthstone (only in BCC)
		22105, -- master healthstone (only in BCC)
		36892, -- fel-healthstone : 0 points in Improved Healthstone (only in WotLK)
		36893, -- fel-healthstone : 1 points in Improved Healthstone (only in WotLK)
		36894 -- fel-healthstone : 2 points in Improved Healthstone (only in WotLK)
	}

	local str = {
		100, -- minor healthstone (all clients)
		110, -- minor healthstone (Classic & BCC)
		120, -- minor healthstone (Classic & BCC)
		500, -- healthstone (Classic & BCC)
		550, -- healthstone (Classic & BCC)
		600, -- healthstone (Classic & BCC)
		2080, -- master healthstone (only in BCC)
		2288, -- master healthstone (only in BCC)
		2496, -- master healthstone (only in BCC)
		4280, -- fel-healthstone : 0 points in Improved Healthstone (only in WotLK)
		4708, -- fel-healthstone : 1 points in Improved Healthstone (only in WotLK)
		5136 -- fel-healthstone : 2 points in Improved Healthstone (only in WotLK)
	}

	for index, id in ipairs(items) do
		if id == itemId then
			return str[index]
		end
	end

	return nil
end

-- Wrapper function to handle the different clients (Retail, Classic, and WotLK).
-- Classic got the C_Container API since patch 1.14.4. Keeping this function as
-- not have to refactor the callers.
function Lunar.Items:GetContainerNumSlots(bagID)
	return C_Container.GetContainerNumSlots(bagID);
end

-- Wrapper function to handle the different clients (Retail, Classic, and WotLK).
-- Classic got the C_Container API since patch 1.14.4. Keeping this function as
-- not have to refactor the callers.
function Lunar.Items:GetContainerItemLink(bagID, slot)
	return C_Container.GetContainerItemLink(bagID, slot);
end

-- Wrapper function to handle the different clients (Retail, Classic, and WotLK).
-- Classic got the C_Container API since patch 1.14.4. Keeping this function as
-- not have to refactor the callers.
function Lunar.Items:GetContainerItemInfo(bagID, slot)
	--if( Lunar.API:IsVersionClassic() ) then
	--	return GetContainerItemInfo(bagID, slot);
	--else
	-- Thanks Blizzard for fucking this up. GetContainerItemInfo returns
	-- an 11-tuple, but C_Container.GetContainerItemInfo returns _A TABLE_.
	-- I honestly hope the Micro$oft deal goes throught and 80 % of the
	-- developers get fired. unpack() returns nil, so do it manually.
	local _info = C_Container.GetContainerItemInfo(bagID, slot);
	return _info.iconFileID, _info.stackCount, _info.isLocked, _info.quality, _info.isReadable, _info.hasLoot,
		_info.hyperlink, _info.isFiltered, _info.hasNoValue, _info.itemID, _info.isBound
	--end
end

-- Wrapper function to handle the different clients (Retail, Classic, and WotLK).
-- Classic got the C_Container API since patch 1.14.4. Keeping this function as
-- not have to refactor the callers.
function Lunar.Items:GetContainerNumFreeSlots(bagID)
	return C_Container.GetContainerNumFreeSlots(bagID);
end

-- /***********************************************
--  * UpdateBagContents
--  * ========================
--  *
--  * Searches a bag and update the item data table with any new contents found
--  *
--  * Accepts: bagID, updateType ("add" or "exists")
--  * Returns: None
--  *********************
function Lunar.Items:UpdateBagContents(bagID, updateType)
	-- We only care about the bags of the player. If it's a bank bag, abort now
	if (bagID > 4) then
		return;
	end

	local userLocale = GetLocale();

	-- Create our local variables
	local slot, itemCount, itemSpell, spellRank, locIndex;
	local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemID;
	local searchText, textLine, textContainer, startLoc, endLoc, itemCharges;
	local key, value;
	local mountType, mountFound;

	local scanSize = 8;
	local startSlot = 1;
	local endSlot = Lunar.Items:GetContainerNumSlots(bagID);

	if (Lunar.Items["updateContainer" .. bagID .. "Slot"]) then
		startSlot = Lunar.Items["updateContainer" .. bagID .. "Slot"];
		if (startSlot > endSlot) then
			Lunar.Items["updateContainer" .. bagID .. "Slot"] = nil;
			return;
		end
	else
		Lunar.Items["updateContainer" .. bagID .. "Slot"] = startSlot + scanSize;
	end

	if ((startSlot + scanSize - 1) <= endSlot) then
		endSlot = startSlot + scanSize - 1;
		Lunar.Items["updateContainer" .. bagID .. "Slot"] = endSlot + 1;
	else
		Lunar.Items["updateContainer" .. bagID .. "Slot"] = nil;
	end

	-- If we're scanning slot #1, we run through our item charges database and if any data is stored
	-- for this particular bag, destory it. The counts will be rebuilt with these scans.
	if (startSlot == 1) then
		-- Next, check to see if we have item spells that need to be grabbed
		if (itemSpellScan) then
			-- Set our locals and our start and end positions
			local index, spellCount;
			index = 1;
			spellCount = table.getn(itemSpellScan)

			-- loop until we checked each table entry
			while (index <= spellCount) do
				-- Grab the spell data. If it exists, remove the current item from the search table and
				-- add the new data to the saved global settings. Otherwise, increase the index and try
				-- another item spell
				searchData[itemSpellScan[index]] = Lunar.Items:GetItemSpell(itemSpellScan[index]);
				if (searchData[itemSpellScan[index]] ~= nil) then
					LunarSphereGlobal.searchData[userLocale][itemSpellScan[index]] = searchData[itemSpellScan[index]];
					table.remove(itemSpellScan, index);
					spellCount = spellCount - 1;
				else
					index = index + 1;
				end
			end

			-- If there is nothing left for us to search for later on, destroy the search table
			-- and the item spell function
			if (table.getn(itemSpellScan) == 0) then
				itemSpellScan = nil;
				Lunar.Items.GetItemSpell = nil;
			end
		end
	end

	-- Start scanning the slots of the current container
	for slot = startSlot, endSlot do
		-- Grab the slot's item link
		itemLink = Lunar.Items:GetContainerItemLink(bagID, slot);

		-- If the slot was not empty, then we have an item link, which means
		-- we are currently looking at an item. Continue.
		if (itemLink) then
			--			Lunar.Items.bagSlots[bagID] = Lunar.Items.bagSlots[bagID] + 1;

			-- With our new link, grab all of the item's details
			itemName, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount = GetItemInfo(
				itemLink);

			-- Set our tooltip up
			Lunar.Items.tooltip:ClearLines();
			Lunar.Items.tooltip:SetOwner(UIParent, "ANCHOR_NONE");
			Lunar.Items.tooltip:SetBagItem(bagID, slot);

			-- Grab the item ID
			itemID = Lunar.API:GetItemID(itemLink);

			mountType = nil;
			mountFound = nil;

			-- In Here
			-- Now, if this item is a consumable item ... (or the broken Mana Agate which thinks
			-- it is ARMOR (wtf?!)
			if (itemType == searchData.consume) or (itemID == 5514) or (itemID == 32578) then
				-- Figure out what spell it casts, if any.
				itemSpell, spellRank = GetItemSpell(itemName);

				if (itemSpell) then
					-- Already done at the top
					--					itemID = Lunar.API:GetItemID(itemLink);

					-- If we found a spell, we'll grab how many of that item is in the slot.
					-- That way, we can populate the item database with a count of said item.
					_, itemCount = Lunar.Items:GetContainerItemInfo(bagID, slot);

					-- Item Spells for over 80's
					if (itemSpell) then
						-- Search through all of our search strings to see if we found a match
						-- for a type of item we search for.
						for nameIndex = 1, Lunar.Items.totalItemTypes do
							--print("1972 Lunar.Items:UpdateBagContents name : ", itemName, itemTableNames[nameIndex])

							-- If the item spell is the same as one of our search data types,
							-- we add the item to our item data table and stop our search.
							if (itemSpell == searchData[itemTableNames[nameIndex]]) then
								-- Bandage strength is based on bandage item number, so change the
								-- itemLevel to reflect that
								if (itemSpell == searchData.bandage) then
									itemLevel = itemID;

									-- Edible Fern item has an itemLevel and itemMinLevel of 0. Change them
									-- to something more suitible
								elseif (itemID == 24540) then
									itemLevel = 55;
									itemMinLevel = 45;

									-- Some level 55 food provide more health than others. Since they are
									-- more powerful, we need to raise the strength a little bit.
								elseif ((itemID >= 27657) and (itemID <= 27660)) or ((itemID >= 27664) and (itemID <= 27667)) or (itemID == 31672) or (itemID == 31673) or (itemID == 33935) or (itemID == 33934) then
									itemLevel = itemLevel + 1;

									-- Super Combat health and mana potions need to be taken down to the proper level (was 70, now 60)
								elseif ((itemID >= 31838) and (itemID <= 31841)) or ((itemID >= 31852) and (itemID <= 31855)) then
									itemLevel = 60;

									-- Endless healing/mana potions, requires level 80, but restore like a level 68, so smack it down to
									-- itemLevel 69 (so it is favored over all level 68 potions which restore the same, but this
									-- one is ENDLESS).
								elseif ((itemID == 43569) or (itemID == 43570)) then
									itemLevel = 69;

									-- If we haven't found a match yet, check if it is a healthstone. If so, add it to the health potions
									-- section
								elseif (itemID == 5512) or string.find(itemName, searchData.healthStone) then
									-- Calculate strength of stone, if it is improved  -- Healthstone Here
									--									local stoneStr = math.fmod(math.floor(string.find(itemSpellID.healthStone, itemID) /  6), 3);
									local stoneStr = string.match((spellRank or ""), "(%d+)") or (0);

									Lunar.Items:ModifyItemDataTable("potionHealing", updateType, itemLink, itemCount,
										itemLevel + 2000 + stoneStr, itemMinLevel, itemLink);
								end

								Lunar.Items:ModifyItemDataTable(itemTableNames[nameIndex], updateType, itemName,
									itemCount, itemLevel, itemMinLevel, itemLink);
								itemSpell = nil;
								break;
							end
						end

						-- The healthstone checking above fails for the
						-- Classic clients because `itemSpell` is not
						-- generic, i.e. `itemSpell` for a Minor Healthstone
						-- is 'Minor Healthstone', so the only match that
						-- will work is for item IDs 5512 (minor healthstone,
						-- all clients), 19004, and 19005. All the other
						-- healthstones won't match.

						-- If we didn't find a healthstone yet
						if stoneStr == nil and Lunar.Items:GetHealthStoneStrength(itemID) then
							local stoneStr = Lunar.Items:GetHealthStoneStrength(itemID)
							Lunar.Items:ModifyItemDataTable("potionHealing", updateType, itemLink, itemCount,
								itemLevel + 2000 + stoneStr, itemMinLevel, itemLink);
						end
					end

					if (itemSpell) then
						local updateMulti, itemStr1, itemStr2;

						-- Check for refreshment types. These go as food and drink
						if (itemSpell == searchData.refreshment) then
							Lunar.Items:ModifyItemDataTable("food", updateType, itemName, itemCount, itemLevel,
								itemMinLevel, itemLink);

							-- All refreshment spells have mana restoration, except for Succulent Orca Stew and Wyrm Delight
							if (itemID ~= 39691) and (itemID ~= 34750) then
								Lunar.Items:ModifyItemDataTable("drink", updateType, itemName, itemCount, itemLevel,
									itemMinLevel, itemLink);
							end

							-- Dreanor Healing Potions.  For some reason Blizzard slipped up.  Instead of Potion Healing for ItemSpell
							-- it's the itemName
							--
							-- Dreanor Potions
						elseif (itemID == 109223) or (itemID == 109226) or (itemID == 89640) then
							-- Healing Tonic, Dreonic Rejuvination Potion and Life Spirit

							Lunar.Items:ModifyItemDataTable("potionHealing", updateType, itemLink, itemCount, itemLevel,
								itemMinLevel, itemLink);

							-- Dreanor Potions- Mana
						elseif (itemID == 109222) or (itemID == 109221) or (itemID == 89641) then
							-- Healing Tonic, Dreonic Channel Mana Potion and Water Spirit

							Lunar.Items:ModifyItemDataTable("potionMana", updateType, itemLink, itemCount, itemLevel,
								itemMinLevel, itemLink);
							-- Okay, we're still going, so check if it is a rage potion of some kind
						elseif (itemSpell == Lunar.Items:CompareItemSpellCatagory(itemSpell, "ragePotion")) then
							Lunar.Items:ModifyItemDataTable("ragePotion", updateType, itemName, itemCount, itemLevel,
								itemMinLevel, itemLink);

							-- Underspore Pod can be used as a drink and a food item, so let's add that too. We artificially increase the
							-- strength so these are used first (as well as other summoned items), before real items :)
						elseif (itemID == 28112) then
							Lunar.Items:ModifyItemDataTable("drink", updateType, itemName, itemCount, 67, itemMinLevel,
								itemLink);
							Lunar.Items:ModifyItemDataTable("food", updateType, itemName, itemCount, 67, itemMinLevel,
								itemLink);

							-- Enriched Mana Biscuit can be used as a drink and a food item, so let's add that too.
						elseif (itemID == 13724) then
							Lunar.Items:ModifyItemDataTable("drink", updateType, itemName, itemCount, 66, itemMinLevel,
								itemLink);
							Lunar.Items:ModifyItemDataTable("food", updateType, itemName, itemCount, 56, itemMinLevel,
								itemLink);

							-- Conjured Manna Biscuit can be used as a drink and a food item, so let's add that too.
						elseif (itemID == 34062) then
							Lunar.Items:ModifyItemDataTable("drink", updateType, itemName, itemCount, 77, itemMinLevel,
								itemLink);
							Lunar.Items:ModifyItemDataTable("food", updateType, itemName, itemCount, 77, itemMinLevel,
								itemLink);

							--[[ Not fixed, need to do research on this, since it uses "refreshment" and might get caught before this part

						-- Conjured Mana Strudel can be used as a drink and a food item, so let's add that too.
						elseif (itemID == 43523) then
							Lunar.Items:ModifyItemDataTable("drink", updateType, itemName, itemCount, 86, itemMinLevel, itemLink);
							Lunar.Items:ModifyItemDataTable("food", updateType, itemName, itemCount, 86, itemMinLevel, itemLink);
--]]
							-- Naaru Ration can be used as a drink and a food item, so let's add that too.
						elseif (itemID == 34780) then
							Lunar.Items:ModifyItemDataTable("drink", updateType, itemName, itemCount, 76, itemMinLevel,
								itemLink);
							Lunar.Items:ModifyItemDataTable("food", updateType, itemName, itemCount, 76, itemMinLevel,
								itemLink);

							-- Noah's Special Brew support (tiny bit weaker than the level 55 equivalent health pot).
						elseif (itemID == 39327) then
							Lunar.Items:ModifyItemDataTable("potionHealing", updateType, itemName, itemCount, 64,
								itemMinLevel, itemLink);

							-- Runic and regular Healing Potion injectors
						elseif ((itemID == 41166) or (itemID == 33092)) then
							Lunar.Items:ModifyItemDataTable("potionHealing", updateType, itemName, itemCount, itemLevel +
								1, itemMinLevel, itemLink);

							-- Runic and regular Mana Potion injectors
						elseif ((itemID == 42545) or (itemID == 33093)) then
							Lunar.Items:ModifyItemDataTable("potionMana", updateType, itemName, itemCount, itemLevel + 1,
								itemMinLevel, itemLink);

							-- Rejuvenation and Alchemist's Potion checking

							-- Minor Rejuvenation Potion
						elseif (itemID == 2456) then
							updateMulti = true;
							itemLevel = 10
							-- Major Rejuvenation Potion
						elseif (itemID == 18253) then
							updateMulti = true;
							itemLevel = 61
							-- Super Rejuvenation Potion
						elseif (itemID == 22850) then
							updateMulti = true;
							itemLevel = 78
							-- Powerful Rejuvenation Potion
						elseif (itemID == 40087) then
							updateMulti = true;
							itemLevel = 79
							-- Mad Alchemist's Potion
						elseif (itemID == 34440) then
							updateMulti = true;
							itemLevel = 78
							-- Crazy Alchemist's Potion
						elseif (itemID == 40077) then
							updateMulti = true;
							itemLevel = 79

							-- Charged Crystal Focus (We want it in the same catagory of health stones, so we make its
							-- item level 2000. Since it's less powerful that the item level 70 Master Healthstone, but more
							-- powerful than the item level 58 Major Healthstone, we dump it in between, hence, level 2060).
						elseif (itemID == 32578) then
							Lunar.Items:ModifyItemDataTable("potionHealing", updateType, itemName, itemCount, 2060,
								itemMinLevel, itemLink);

							-- Whipper Root Tuber
						elseif (itemID == 11951) then
							Lunar.Items:ModifyItemDataTable("potionHealing", updateType, itemName, itemCount, 50,
								itemMinLevel, itemLink);
						end

						if (updateMulti) then
							Lunar.Items:ModifyItemDataTable("potionHealing", updateType, itemName, itemCount, itemLevel,
								itemMinLevel, itemLink);
							Lunar.Items:ModifyItemDataTable("potionMana", updateType, itemName, itemCount, itemLevel,
								itemMinLevel, itemLink);
						end
					end
				end

				-- Next on the search: Hearthstone.
			elseif (itemSpell == searchData.hearthstone) then
				Lunar.Items:ModifyItemDataTable("hearthstone", updateType, itemName, 1, itemLevel, itemMinLevel, itemLink);
				-- Classic and BCC mounts are items, handle them here
			elseif (Lunar.API:IsVersionClassic() == true and Lunar.Items:ClassicIsMount(itemID)) then
				-- I'm pretty sure all mounts are unique, but we'll count just in case
				_, itemCount = Lunar.Items:GetContainerItemInfo(bagID, slot);
				Lunar.Items:ModifyItemDataTable("mount", updateType, itemName, itemCount, itemLevel, itemMinLevel,
					itemLink);
			end
		end
	end
end

-- /***********************************************
--  * ModifyItemDataTable
--  * ========================
--  *
--  * Modifies the item table with a (Add|Remove|Wipe|Exists) command. Other arguments are used for
--  * the selected operation as well.
--  *
--  * Accepts:	tableName:	name of table to modify
--  *		modifyType:	type of modification ("add", "remove", "wipe", or "exists"). Anything else, does nothing
--  *		itemName:	name of item to (Add|Remove|Exists)
--  *		itemCount:	amount of said item to (Add|Remove|Exists)
--  *		itemLevel:	strength or potency of said item (higher number means stronger potion/food/etc)
--  *		itemMinLevel:	level said item needs in order to be used
--  *           itemLink:	itemLink of the item
--  *		
--  * Returns:	on modifyType "add":	true if the item existed, false if it had to be added
--  *		on modifyType "remove":	true if the player has more of said item, false if they have 0 left
--  *		on modifyType "wipe":	always returns true
--  *           on modifyType "exists": false if it was a new item (and added), true if it already exists (not added)
--  *********************
function Lunar.Items:ModifyItemDataTable(tableName, modifyType, itemName, itemCount, itemLevel, itemMinLevel, itemLink)
	-- Set our locals
	local index, dataDump, modified;
	modified = false;

	-- If the table name or modify type is not declared, end now.
	if (tableName == nil) or (modifyType == nil) then
		return false;
	end

	-- If we're adding, make sure we have the proper information, otherwise we exit.
	if (modifyType == "add") or (modifyType == "exists") then
		if (itemName == nil) or (itemCount == nil) or (itemLevel == nil) or (itemMinLevel == nil) or (itemLink == nil) then
			return false;
		end
	end

	-- If we're removing, make sure we have the proper information, otherwise we exit.
	if (modifyType == "remove") then
		if (itemName == nil) or (itemCount == nil) then
			return false;
		end
	end

	-- Okay, now make sure the table we're messing with exists. If so, we continue.
	if (itemData[tableName]) then
		-- If we're adding an existing item ("add") or adding a new item ("exists"), we go down path #1
		if (modifyType == "add") or (modifyType == "exists") then
			-- First, check all of the specified table and see if our item exists or is a mount favourite
			for index, dataDump in ipairs(itemData[tableName]) do
				-- If the name matches our table data, we have a match.
				if (dataDump.name == itemName) then
					modified = true;

					-- If we're adding, update the total count of that item by the specified
					-- itemCount, state that we found a match, and exit the loop
					if (modifyType == "add") then
						dataDump.count = dataDump.count + itemCount;
						break;
					end

					-- We don't do anything for "exists" because it was already
					-- in the table and the count was updated with an Update Count function
					-- before calling this function with "exists"
				end
			end

			-- If no match was found, we need to create a new entry and populate its data
			if not (modified) then
				-- Check the item to see if it is summoned. First, grab the item link. Then, clear
				-- our hidden tooltip and set the new data. Next, grab the second line of the tooltip
				-- (where it would say "Conjured Item" if it existed and check if the localized
				-- text exists. If it is, we need to increase the strength by 1000 (to use it first,
				-- if need be).

				--				_, itemLink = GetItemInfo(itemName);
				if (itemLink) and (itemLink ~= "spellMount") then
					Lunar.Items.tooltip:ClearLines();
					Lunar.Items.tooltip:SetOwner(UIParent, "ANCHOR_NONE");
					Lunar.Items.tooltip:SetHyperlink(itemLink);
					if (Lunar.API:IsVersionClassic() == false) then
						searchText = _G[Lunar.Items.tooltip:GetName() .. "TextLeft2"]:GetText();
					else
						searchText = nil
					end
					if (searchText) then
						if string.find(searchText, ITEM_CONJURED) then
							itemLevel = itemLevel + 1000;
						end
					end
				end

				-- Populate the data table
				table.insert(itemData[tableName], {
					name = itemName,
					count = itemCount,
					strength = itemLevel,
					level = itemMinLevel,
					itemID = Lunar.API:GetItemID(itemLink)
				});

				-- If a mount is being added, also save the spell name of the
				-- mount (the spell name is different than the mount name for
				-- some mounts).

				if (tableName == "mount") then
					local pos = table.getn(itemData[tableName])
					if (itemLink ~= "spellMount") then
						itemData[tableName][pos].spell = GetItemSpell(itemName);
					else
						-- Replace with appropriate function to get spell details using updated API
						local spellID = tonumber(string.sub(itemName, 3))
						if spellID then
							local spellInfo = C_Spell.GetSpellInfo(spellID)
							if spellInfo then
								itemData[tableName][pos].spell = spellInfo.name;
								itemData[tableName][pos].spellMount = true;
								itemData[tableName][pos].itemID = "spellMount";
							end
						end
					end
					itemData[tableName][pos].isEpic = Lunar.Items:IsMountEpic(itemData[tableName][pos])
					itemData[tableName][pos].isFlying = Lunar.Items:BCCIsFlyingMount(itemData[tableName][pos])
					itemData[tableName][pos].isAQ40 = Lunar.Items:IsMountAQ40(itemData[tableName][pos])
					itemData[tableName][pos].isEpic310 = Lunar.Items:IsMountEpic310(itemData[tableName][pos])
				end

				if (tableName == "companion") then
					local spellID = tonumber(string.sub(itemName, 3))
					if spellID then
						local spellInfo = C_Spell.GetSpellInfo(spellID)
						if spellInfo then
							itemData[tableName][table.getn(itemData[tableName])].spell = spellInfo.name;
							itemData[tableName][table.getn(itemData[tableName])].itemID = "spellMount";
						end
					end
				end


				-- If we're removing, we go down path #2
			elseif (modifyType == "remove") then
				-- First, check all of the specified table and see if our item exists
				for index, dataDump in ipairs(itemData[tableName]) do
					-- If the name matches our table data, we have a match. State that
					-- we found a match and update the total count of that item by
					-- removing the specified itemCount and then exit the loop.
					if (dataDump.name == itemName) then
						dataDump.count = dataDump.count - itemCount;
						modified = true;

						-- Prevent the possibility of going into the negatives...
						-- as well as state that there are no more items left
						if (dataDump.count <= 0) then
							dataDump.count = 0;
							modified = false;
						end
						break;
					end
				end

				-- If we're wiping, we need to go down path #3 and burn some bridges
			elseif (modifyType == "wipe") then
				-- Start at the first entry and cycle through n times, till
				-- we removed everything
				for index = 1, table.getn(itemData[tableName]) do
					table.remove(itemData[tableName]);
				end
			end
		end

		-- Return our results
		return modified;

		-- Take a nap
	end

	-- /***********************************************
	--  * WipeItemDataTable
	--  * ========================
	--  *
	--  * Wipes every entry in the item database
	--  *
	--  * Accepts: None
	--  * Returns: None
	--  *********************
	function Lunar.Items:WipeItemDataTable()
		-- Set a local
		local nameIndex;

		-- Run through each table name in the itemData tables and wipe it off the face of the planet!
		for nameIndex = 1, table.getn(itemTableNames) do
			Lunar.Items:ModifyItemDataTable(itemTableNames[nameIndex], "wipe");
		end
	end
end
