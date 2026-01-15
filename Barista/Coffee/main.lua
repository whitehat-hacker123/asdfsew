-- ServerScriptService > CoffeeManagerScript
local ServerStorage = game:GetService("ServerStorage")

-- 1. remote event
local coffeeEvent = ServerStorage:WaitForChild("CoffeeEvents"):WaitForChild("CoffeeAction")

-- 2. color palette
local COLORS = {
	Espresso = Color3.fromRGB(60, 40, 20),   -- u can customize the palette 
	Water    = Color3.fromRGB(135, 206, 250),
	Milk     = Color3.fromRGB(255, 253, 240),
	Caramel  = Color3.fromRGB(210, 105, 30), 
	Vanilla  = Color3.fromRGB(243, 229, 171),
	GreenTea = Color3.fromRGB(107, 140, 66), 
	HotChoco = Color3.fromRGB(90, 50, 20),   
	Foam     = Color3.fromRGB(255, 255, 255) --as well as menu
}

-- cup update function
local function processRecipe(cup, actionName)
	local liquid = cup:FindFirstChild("Handle"):FindFirstChild("Liquid")
	if not liquid then return end

	liquid.Transparency = 0 

	-- get the current state of cup
	local currentBase = cup:GetAttribute("Base") -- Espresso, GreenTea, HotChoco etc

	-------------------------------------------------------
	-- [A] bases 
	-------------------------------------------------------
	if actionName == "GetEspresso" then
		liquid.Color = COLORS.Espresso
		cup:SetAttribute("Base", "Espresso")      
		cup:SetAttribute("CoffeeType", "Espresso") 

	elseif actionName == "GetGreenTea" then
		liquid.Color = COLORS.GreenTea
		cup:SetAttribute("Base", "GreenTea")
		cup:SetAttribute("CoffeeType", "Green Tea")
	
		-------------------------------------------------------
		-- [B] additional ingredient
		-------------------------------------------------------
	elseif currentBase == "Espresso" then

		-- if cup:GetAttribute("IsFinished") then return end

		if actionName == "AddWater" then
			liquid.Color = COLORS.Espresso:Lerp(COLORS.Water, 0.1) -- 색 섞기
			cup:SetAttribute("CoffeeType", "Americano")
			
		elseif actionName == "AddMilk" then
			liquid.Color = COLORS.Espresso:Lerp(COLORS.Milk, 0.6)
			cup:SetAttribute("CoffeeType", "Latte")
			
		elseif actionName == "AddFoam" then
			liquid.Color = COLORS.Espresso:Lerp(COLORS.Foam, 0.5)
			cup:SetAttribute("CoffeeType", "Cappuccino")
			
		elseif actionName == "AddCaramel" then
			liquid.Color = COLORS.Espresso:Lerp(COLORS.Caramel, 0.5)
			cup:SetAttribute("CoffeeType", "Caramel Latte")

		elseif actionName == "AddVanilla" then
			liquid.Color = COLORS.Espresso:Lerp(COLORS.Vanilla, 0.5)
			cup:SetAttribute("CoffeeType", "Vanilla Latte")
			
		end

		print("menu update: " .. cup:GetAttribute("CoffeeType"))

	else
		-- tryna put something with out Espresso
		print("get the Espresso first")
	end
end

-- 4. connect the event
coffeeEvent.Event:Connect(function(player, actionName)
	-- check the user
	if player.Team.Name ~= "Barista" then return end

	local character = player.Character
	if not character then return end

	-- check if player has a cup with 
	local tool = character:FindFirstChild("Cup") -- 도구 이름이 Cup이어야 함
	if tool then
		processRecipe(tool, actionName)
	else
			-- print("need cup")
	end
end)
