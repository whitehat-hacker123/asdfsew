-- ServerScriptService > ChefSystemScript
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- [1] recipe and ingredient
local RECIPES = {
	{ 
		Name = "Beef Steak", 
		Ingredients = {"Steak", "Asparagus"}, 
		Base = "Steak" -- base
	},
	{ 
		Name = "Salmon Meuniere", 
		Ingredients = {"Salmon", "Lemon"}, 
		Base = "Salmon" 
	},
	{ 
		Name = "Pasta Carbonara", 
		Ingredients = {"Pasta", "Bacon"}, 
		Base = "Bacon" -- what yo lookin at
	},
	{ 
		Name = "Tomato Soup", 
		Ingredients = {"Tomato", "Bread"}, 
		Base = "Tomato" -- stars
	}
}

-- 완성된 음식 저장소
local FoodStorage = ServerStorage:WaitForChild("FinishedFood")

-------------------------------------------------------------
-- [2] cooking logic (Cooking Process)
-------------------------------------------------------------
local function startCooking(tool)
	if tool:GetAttribute("IsCooking") then return end -- skip if its aredy cookin
	
	tool:SetAttribute("IsCooking", true)
	print("🔥🔥🔥🔥🔥🔥🔥🔥🔥 start cookin! (1 min)")

	local grillPart = tool:FindFirstChild("GrillPart") -- stove's heat plate(?)
	local smoke = grillPart and grillPart:FindFirstChild("Smoke")

	-- 2. 30sec after ->> enalbe particle effect
	task.delay(30, function()
		if tool and tool.Parent then -- if tool stil exist
			if smoke then smoke.Enabled = true end
			print("💨 alah!!💨💨 its smokin! ")
		end
	end)

	-- 3. after 60 secc 
	task.delay(60, function()
		if tool and tool.Parent then
			tool:SetAttribute("Status", "Cooked")
			print("✅ ice..")
			
			-- turn off fire 
			if smoke then smoke.Enabled = false end -- disable smoke
		end
	end)
end

-------------------------------------------------------------
-- [3] intertrecetion cyka
-------------------------------------------------------------

-- A. ingredient sus (ingredient box)
-- in Workspace find 'Ingredients' everything in folder
for _, dispenser in pairs(workspace.Ingredients:GetChildren()) do
	local prompt = dispenser:FindFirstChild("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			local character = player.Character
			local tool = character and character:FindFirstChild("PortableGrill") -- check the cooking tool 

			if tool then
				local ingredientName = dispenser.Name -- use part's name
				
				
				if tool:GetAttribute("Has_"..ingredientName) then return end
				
				-- add ingredient
				tool:SetAttribute("Has_"..ingredientName, true)
				print("재료 추가됨: " .. ingredientName)
				
				-- start the timer if event triggered
				for _, recipe in pairs(RECIPES) do
					if recipe.Base == ingredientName then
						startCooking(tool)
						break
					end
				end
			else
				warn("i need your grill on your hands")
			end
		end)
	end
end

-- B.plating
local plateStation = workspace:WaitForChild("PlatingStation")
local platePrompt = plateStation:FindFirstChild("ProximityPrompt")

if platePrompt then
	platePrompt.Triggered:Connect(function(player)
		local character = player.Character
		local tool = character and character:FindFirstChild("PortableGrill")

		if tool then
			-- 1. check if the food is cooked
			if tool:GetAttribute("Status") ~= "Cooked" then
				warn("it is not cooked")
				return
			end

			-- 2. check the resipe
			local foundRecipe = nil
			
			for _, recipe in pairs(RECIPES) do
				local match = true
				-- check if they have required ingerdient
				for _, ing in pairs(recipe.Ingredients) do
					if not tool:GetAttribute("Has_"..ing) then
						match = false
						break
					end
				end
				
				if match then
					foundRecipe = recipe.Name
					break
				end
			end

		-- 3. 
			if foundRecipe then
				print("🍽️: " .. foundRecipe)
				
				-- fini
				tool:Destroy()
				
				-- give fully cooked food to player 
				local foodTool = FoodStorage:FindFirstChild(foundRecipe)
				if foodTool then
					local clone = foodTool:Clone()
					clone.Parent = player.Backpack
					player.Character.Humanoid:EquipTool(clone) -- 바로 손에 들려줌
				else
					warn("add model to serverstorage " .. foundRecipe)
				end
			else
				warn("I need food that is in the recipe")
			end
			
		else
			warn("click the plate that is already finished ")
		end
	end)
	--whats yo lookin fo
end






