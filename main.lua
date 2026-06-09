local plants_data = require(game.ReplicatedStorage.Shared.Registry.Plants)
local pets_data = require(game.ReplicatedStorage.Shared.Registry.Pets)
local rarity_data = require(game.ReplicatedStorage.Shared.Registry.Rarities)

local function get_autoegg()
	local AutoEgg = {}

	AutoEgg.Enabled = false
	AutoEgg.Filter = {}

	local FarmIdCounter = 0
	AutoEgg.Logs = {}

	AutoEgg.BoughtEggSignal = {
		["Connections"] = {},
		["Connect"] = function(self, callback)
			table.insert(self.Connections, callback)
		end,
		["Fire"] = function(self, ...)
			for _, connection in pairs(self.Connections) do
				connection(...)
			end
		end
	}

	game.ReplicatedStorage.Remotes.RollEgg.OnClientEvent:Connect(function(...)
		if not AutoEgg.Enabled then return end

		local args = {...}

		AutoEgg.Logs[FarmIdCounter] = args
		AutoEgg.BoughtEggSignal:Fire(args)
	end)

	local podiums = {}

	local function buy_egg(index, egg)
		game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("EggShop"):WaitForChild("Transaction"):InvokeServer("BuyEgg", index)
		game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RollEgg"):FireServer(egg)
		game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RollEgg"):FireServer(egg, "ClaimRolledPet")
	end

	local function buy_eggs()
		for i,podium in pairs(podiums) do
			local value = podium.Value
			if value ~= "" and table.find(AutoEgg.Filter, value) then
				buy_egg(i, value)
			end
		end
	end

	local index = 1
	while task.wait() do
		local podium = game.ReplicatedStorage.EggStocks:WaitForChild(game.Players.LocalPlayer.Name):FindFirstChild("Podium"..tostring(index))
		if podium then
			local data = {}
			data.Instance = podium
			data.Index = index
			data.Connection = podium:GetPropertyChangedSignal("Value"):Connect(function()
				if not AutoEgg.Enabled then return end

				if podium.Value ~= "" and table.find(AutoEgg.Filter, podium.Value) then
					buy_egg(data.Index, podium.Value)
				end
			end)

			podiums[index] = podium
			index += 1
		else
			break
		end
	end

	function AutoEgg.SetFilter(filter)
		AutoEgg.Filter = filter
	end

	function AutoEgg.Enable(State)
		AutoEgg.Enabled = State

		FarmIdCounter += 1
		AutoEgg.Logs[FarmIdCounter] = {}

		if State then
			buy_eggs()
		end
	end

	return AutoEgg
end

local function get_autogear()
	local AutoGear = {}

	AutoGear.Enabled = false

	local FarmIdCounter = 0
	AutoGear.Logs = {}

	AutoGear.BoughtGearSignal = {
		["Connections"] = {},
		["Connect"] = function(self, callback)
			table.insert(self.Connections, callback)
		end,
		["Fire"] = function(self, ...)
			for _, connection in pairs(self.Connections) do
				connection(...)
			end
		end
	}

	local Stocks = game.ReplicatedStorage.GearStocks:WaitForChild(game.Players.LocalPlayer.Name)
	local function buy_gear(gear)
		local bought = game.ReplicatedStorage.Remotes.Gear.Transaction:InvokeServer(gear)

		if bought then
			table.insert(AutoGear.Logs[FarmIdCounter], gear)
			AutoGear.BoughtGearSignal:Fire(gear)
		end
	end

	local function buy_gears()
		for _,stock in pairs(Stocks:GetChildren()) do
			local name = stock.Name
			local amount = stock.Value
			if amount > 0 then
				for i = 1,amount do
					buy_gear(name)
				end
			end
		end
	end

	for _,stock in pairs(Stocks:GetChildren()) do
		stock:GetPropertyChangedSignal("Value"):Connect(function()
			if not AutoGear.Enabled then return end

			local amount = stock.Value
			if amount > 0 then
				for i = 1,amount do
					buy_gear(stock.Name)
				end
			end
		end)
	end

	function AutoGear.Enable(State)
		AutoGear.Enabled = State

		if State then
			buy_gears()
		end

		FarmIdCounter += 1
		AutoGear.Logs[FarmIdCounter] = {}
	end

	return AutoGear
end

local function get_autosell()
	local AutoSell = {}

	AutoSell.Enabled = false
	AutoSell.Sold = 0

	AutoSell.SoldSignal = {
		["Connections"] = {},
		["Connect"] = function(self, callback)
			table.insert(self.Connections, callback)
		end,
		["Fire"] = function(self, ...)
			for _, connection in pairs(self.Connections) do
				connection(...)
			end
		end
	}

	game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SellCrates").OnClientEvent:Connect(function(sold)
		if not AutoSell.Enabled then return end

		AutoSell.Sold += sold
		AutoSell.SoldSignal:Fire(sold, AutoSell.Sold)
	end)

	AutoSell.Interval = 5
	local SellThread = coroutine.create(function()
		while task.wait() do
			if not AutoSell.Enabled then coroutine.yield() end

			game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SellCrates"):FireServer()
			task.wait(AutoSell.Interval)
		end
	end)

	function AutoSell.Enable(State)
		AutoSell.Enabled = State

		if AutoSell.Enabled then
			coroutine.resume(SellThread)
		end
	end

	return AutoSell
end

local function get_autoroll()
	local AutoRoll = {}

	AutoRoll.Enabled = false
	AutoRoll.RarityFilter = {}
	AutoRoll.Logs = {}
	AutoRoll.BoughtSeedSignal = {
		["Connections"] = {},
		["Connect"] = function(self, callback)
			table.insert(self.Connections, callback)
		end,
		["Fire"] = function(self, ...)
			for _, connection in pairs(self.Connections) do
				connection(...)
			end
		end
	}

	local rollevent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RollSeeds")
	local data = require(game.ReplicatedStorage.Shared.Registry.Plants)

	local animation_connections = getconnections(rollevent.OnClientEvent)

	local connec = rollevent.OnClientEvent:Connect(function(got,animation)
		for i,plant in pairs(got) do
			local dt = data[plant]
			if table.find(AutoRoll.RarityFilter, dt.Rarity) then
				game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("BuySeed"):FireServer(i)
				table.insert(AutoRoll.Logs, dt)
				AutoRoll.BoughtSeedSignal:Fire(dt)
			end
		end
	end)

	local RollThread = coroutine.create(function()
		while task.wait() do
			if not AutoRoll.Enabled then coroutine.yield() end

			game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RollSeeds"):FireServer()
			task.wait(0.3)
		end
	end)

	function AutoRoll.SetRarityFilter(filter)
		AutoRoll.RarityFilter = filter
	end

	function AutoRoll.ToggleAnimations(State)
		for _,connec in pairs(animation_connections) do
			if State then
				connec:Enable()
			else
				connec:Disable()
			end
		end
	end

	function AutoRoll.Enable(State)
		AutoRoll.Enabled = State

		if State then
			coroutine.resume(RollThread)
		end
	end

	return AutoRoll
end

local function get_antiafk()
	local AntiAfk = {}

	AntiAfk.Enabled = false
	AntiAfk.Interval = 10

	local bb=game:GetService("VirtualUser")

	AntiAfk.MainLoop = coroutine.create(function()
		while task.wait() do
			if not AntiAfk.Enabled then coroutine.yield() end
			task.wait(AntiAfk.Interval)
			bb:CaptureController()
			bb:ClickButton2(Vector2.new())
			keypress(0x57)
			task.wait()
			keyrelease(0x57)
		end
	end)

	function AntiAfk.Toggle(status)
		AntiAfk.Enabled = status

		if AntiAfk.Enabled then
			coroutine.resume(AntiAfk.MainLoop)
		end
	end

	return AntiAfk
end

local function get_plot_tools()
	local PlotTools = {}

	local plants_data = require(game.ReplicatedStorage.Shared.Registry.Plants)
	local rarities_data = require(game.ReplicatedStorage.Shared.Registry.Rarities)

	function PlotTools.GetPlot(player)
		local playerId = player.UserId

		for _,plot in pairs(workspace.Map.Plots:GetChildren()) do
			if plot:GetAttribute("OwnerUserId") == playerId then
				return plot
			end
		end

		return false
	end

	function PlotTools.HarvestAllPlants(Floor)
		local plot = PlotTools.GetPlot(game.Players.LocalPlayer)
		if not plot then return end

		local farmPlot
		if Floor == 1 then
			farmPlot = plot.FarmPlot
		else
			local floor = plot:FindFirstChild("Floor"..tostring(Floor))
			if not floor then return end
			farmPlot = floor.FarmPlot
		end

		if not farmPlot then return end

		for _,plant in pairs(farmPlot:GetChildren()) do
			if plant:GetAttribute("PlotKey") == nil then continue end
			game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RemovePlant"):FireServer(plant.Dirt)
		end
	end

	function PlotTools.GetFloor(floor)
		local plot = PlotTools.GetPlot(game.Players.LocalPlayer)

		if floor == 1 then
			return plot.FarmPlot
		else
			return plot:FindFirstChild("Floor"..tostring(floor)).FarmPlot
		end
	end

	function PlotTools.GetFloors()
		local plot = PlotTools.GetPlot(game.Players.LocalPlayer)
		if not plot then return end

		local i = 1
		while task.wait() do
			if plot:FindFirstChild("Floor"..tostring(i+1)) then
				i += 1
			else
				break
			end
		end

		return i
	end

	function PlotTools.GetSeeds(SortByRarest)
		local seeds = {}

		for _,tool in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
			if tool:GetAttribute("InventoryCategory") == "Seeds" then
				table.insert(seeds, tool)
			end
		end

		if not SortByRarest then return seeds end

		table.sort(seeds, function(a,b)
			return rarities_data[plants_data[a:GetAttribute("Plant")].Rarity].Order > rarities_data[plants_data[b:GetAttribute("Plant")].Rarity].Order
		end)

		return seeds
	end

	function PlotTools.GetFloorEmptySlots(Floor, SortByBest)
		local plot = PlotTools.GetPlot(game.Players.LocalPlayer)
		if not plot then return end
		local farmPlot = PlotTools.GetFloor(Floor)
		if not farmPlot then return end

		local slots = {}

		for _,slot in pairs(farmPlot:GetChildren()) do
			if slot:GetAttribute("PlotKey") == nil then continue end
			if slot.Dirt:GetAttribute("PlantName") ~= nil then continue end

			table.insert(slots, slot)
		end

		if not SortByBest then return slots end

		table.sort(slots, function(a,b)
			return tonumber(a.Name:sub(#a.Name, #a.Name)) > tonumber(b.Name:sub(#b.Name, #b.Name))
		end)

		return slots
	end

	return PlotTools
end

local autoegg = get_autoegg()
local autogear = get_autogear()
local autosell = get_autosell()
local autoroll = get_autoroll()
local antiafk = get_antiafk()
local plot_tools = get_plot_tools()



local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
local Options = Fluent.Options

local Window = Fluent:CreateWindow({
	Title = "Build a ring farm",
	SubTitle = "V 1.0.0",
	TabWidth = 160,
	Size = UDim2.fromOffset(580, 460),
	Acrylic = true, -- The blur may be detectable, setting this to false disables blur entirely
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.Insert -- Used when theres no MinimizeKeybind
})


AutoFarmTab = Window:AddTab({ Title = "AutoFarm", Icon = "" })

local AutoSellToggle = AutoFarmTab:AddToggle("AutoSellToggle", {Title = "Auto Sell", Default = false })
AutoSellToggle:OnChanged(function()
	autosell.Enable(Options.AutoSellToggle.Value)
end)

local AutoSellInterval = AutoFarmTab:AddSlider("AutoSellInterval", {
	Title = "Auto Sell Interval",
	Description = "Interval for selling",
	Default = 5,
	Min = 1,
	Max = 10,
	Rounding = 1,
	Callback = function(Value)
		autosell.Interval = Value
	end
})


local AutoEggToggle = AutoFarmTab:AddToggle("AutoEggToggle", {Title = "Auto Buy Eggs", Default = false })
AutoEggToggle:OnChanged(function()
	autoegg.Enable(Options.AutoEggToggle.Value)
end)

local AutoEggSelector = AutoFarmTab:AddDropdown("AutoEggSelector", {
	Title = "Buying eggs",
	Description = "You can select a filter of wich egg to autobuy",
	Values = {"CommonEgg","RareEgg","EpicEgg"},
	Multi = true,
	Default = {},
})

AutoEggSelector:OnChanged(function(Value)
	local Values = {}
	for Value, State in next, Value do
		table.insert(Values, Value)
	end
	autoegg.SetFilter(Values)
end)

local AutoGearToggle = AutoFarmTab:AddToggle("AutoGearToggle", {Title = "Auto Buy Gears", Default = false })
AutoGearToggle:OnChanged(function()
	autogear.Enable(Options.AutoGearToggle.Value)
end)


local AutoRollToggle = AutoFarmTab:AddToggle("AutoRollToggle", {Title = "Auto Roll", Default = false })
AutoRollToggle:OnChanged(function()
	autoroll.Enable(Options.AutoRollToggle.Value)
end)

local plant_rarities = {}
for plant,data in pairs(plants_data) do
	if typeof(data) ~= "table" then continue end
	if not table.find(plant_rarities, data.Rarity) then
		table.insert(plant_rarities, data.Rarity)
	end
end

local AutoRollSelector = AutoFarmTab:AddDropdown("AutoRollSelector", {
	Title = "Rarity filter",
	Description = "You can select a filter of wich seed to autobuy",
	Values = plant_rarities,
	Multi = true,
	Default = {},
})

AutoRollSelector:OnChanged(function(Value)
	local Values = {}
	for Value, State in next, Value do
		table.insert(Values, Value)
	end
	autoroll.SetRarityFilter(Values)
end)


LogsTab = Window:AddTab({ Title = "Logs", Icon = "" })

local AutoSellLogs = LogsTab:AddParagraph({
	Title = "Auto sell",
	Content = "Sold <font color=\"rgb(0,170,0)\">0$</font>."
})
local label = AutoSellLogs.DescLabel
label.RichText = true

local function format_money(amount)
	local suffix = {"K", "M", "B", "T", "Qd", "Qn"}
	local k = math.floor(((#tostring(amount))-1)/3)
	local reaming = (#tostring(amount))-(k*3)
	local before = string.sub(tostring(amount), 0, reaming)

	return before..suffix[k]
end

autosell.SoldSignal:Connect(function(sold, totalsold)
	AutoSellLogs:SetDesc("Sold <font color=\"rgb(0,170,0)\">"..format_money(totalsold).."$</font>.")
end)


local AutoEggLogs = LogsTab:AddParagraph({
	Title = "Auto egg",
	Content = ""
})
local label = AutoSellLogs.DescLabel
label.RichText = true

local egg_stats = {}
autoegg.BoughtEggSignal:Connect(function(egg)
	local pet = egg[2]
	local sizestr = egg[6]
	local size = egg[7]
	
	local pet_data = pets_data[pet]
	local rarity = pet_data.Rarity
	
	if not egg_stats[pet] then
		egg_stats[pet] = {}
	end
	table.insert(egg_stats[pet], {sizestr, size, rarity})
	
	local text = ""
	for pet,list in pairs(egg_stats) do
		for i,stats in pairs(list) do
			text = text.."<font color=\"rgb(255,255,255)\">"..pet..": "..stats[1].."("..stats[2]..")".." ["..stats[3].."]</font><br>"
		end
	end
	AutoSellLogs:SetDesc(text)
end)


UtilityTab = Window:AddTab({ Title = "Utility", Icon = "" })

local floors = plot_tools.GetFloors()
local floor_list = {}
for i = 1,floors do
	table.insert(floor_list, i)
end

local HarvestFloorSection = UtilityTab:AddSection("Harvest Floor Plants")

local HarvestingFloors = {}
local FloorHarvestSelector = HarvestFloorSection:AddDropdown("FloorHarvestSelector", {
	Title = "Floors",
	Description = "You can select on wich floor to harvest",
	Values = floor_list,
	Multi = true,
	Default = {},
})

FloorHarvestSelector:OnChanged(function(Value)
	local Values = {}
	for Value, State in next, Value do
		table.insert(Values, Value)
	end
	HarvestingFloors = Values
end)

HarvestFloorSection:AddButton({
	Title = "Harvest",
	Description = "Collect all plants of the selected floors",
	Callback = function()
		for _,floor in pairs(HarvestingFloors) do
			plot_tools.HarvestAllPlants(floor)
		end
	end
})

local PlantSeedSection = UtilityTab:AddSection("Plant Best Seeds")
local SeedsToPlant = 1
local AmountPlantSlider = PlantSeedSection:AddSlider("AmountPlantSlider", {
	Title = "Seeds to plant",
	Description = "Choose how much seeds to plant",
	Default = 1,
	Min = 1,
	Max = 30,
	Rounding = 1,
	Callback = function(Value)
		SeedsToPlant = Value
	end
})

local FloorToPlant = 1
local FloorToPlantSelector = PlantSeedSection:AddDropdown("FloorToPlantSelector", {
	Title = "Floor",
	Description = "You can select on wich floor to harvest",
	Values = floors,
	Multi = false,
	Default = 1,
})

FloorToPlantSelector:OnChanged(function(Value)
	FloorToPlant = Value
end)

HarvestFloorSection:AddButton({
	Title = "Plant",
	Description = "Plant the selected seeds into the selected floor",
	Callback = function()
		local bestSeeds = plot_tools.GetSeeds(true)
		local bestPlots = plot_tools.GetFloorEmptySlots(FloorToPlant, true)
		
		for i,plot in pairs(bestPlots) do
			local seed = bestSeeds[i]
			
			game.ReplicatedStorage.Remotes.EquipTool:FireServer(seed)
			repeat task.wait() until seed.Parent ~= game.Players.LocalPlayer.Backpack
			
			game.ReplicatedStorage.Remotes.PlantSeed:FireServer(plot.Dirt)
			repeat task.wait() until seed == nil or (seed.Parent ~= game.Players.LocalPlayer.Backpack and seed.Parent ~= game.Players.LocalPlayer.Character)
		end
	end
})


AntiAfkTab = Window:AddTab({ Title = "AFK", Icon = "" })

local AntiAfkToggle = AntiAfkTab:AddToggle("AntiAfkToggle", {Title = "AntiAfk", Default = false })
AntiAfkToggle:OnChanged(function()
	antiafk.Toggle(Options.AntiAfkToggle.Value)
end)



SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

-- You can add indexes of elements the save manager should ignore
SaveManager:SetIgnoreIndexes({})

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
InterfaceManager:SetFolder("BuildARingFarm")
SaveManager:SetFolder("BuildARingFarm/Main")

local settingsTab = Window:AddTab({ Title = "Settings", Icon = "rbxassetid://9753762469" })
InterfaceManager:BuildInterfaceSection(settingsTab)
SaveManager:BuildConfigSection(settingsTab)


Window:SelectTab(1)

Fluent:Notify({
	Title = "Build a ring farm Script",
	Content = "The gui has been loaded.",
	Duration = 5
})

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
