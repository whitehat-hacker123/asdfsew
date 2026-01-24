-- ServerScriptService > ChefSystemScript
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- [1] Recipes and ingredient setup
local RECIPES = {
	{ 
		Name = "Beef Steak", 
		Ingredients = {"Steak", "Asparagus"}, 
		Base = "Steak" -- The key ingredient that starts the cooking process
	},
	{ 
		Name = "Salmon Meuniere", 
		Ingredients = {"Salmon", "Lemon"}, 
		Base = "Salmon" 
	},
	{ 
		Name = "Pasta Carbonara", 
		Ingredients = {"Pasta", "Bacon"}, 
		Base = "Bacon" -- Cooking starts when bacon is seared
	},
	{ 
		Name = "Tomato Soup", 
		Ingredients = {"Tomato", "Bread"}, 
		Base = "Tomato" -- Cooking starts when tomato is boiled
	}
}

-- Storage for finished food
local FoodStorage = ServerStorage:WaitForChild("FinishedFood")

-------------------------------------------------------------
-- [2] Cooking logic
-------------------------------------------------------------
local function startCooking(tool)
	if tool:GetAttribute("IsCooking") then return end -- skip if already cooking
	
	tool:SetAttribute("IsCooking", true)
	print("🔥 Cooking started! (1 minute)")

	local grillPart = tool:FindFirstChild("GrillPart") -- part whose color will change
	local smoke = grillPart and grillPart:FindFirstChild("Smoke")

	if grillPart then
		-- 1. Color change (gradually turn red over 30 seconds)
		local tweenInfo = TweenInfo.new(30, Enum.EasingStyle.Linear)
		local goal = {Color = Color3.fromRGB(255, 50, 0)} -- red
		local tween = TweenService:Create(grillPart, tweenInfo, goal)
		 tween:Play()
	end

	-- 2. After 30 seconds, start smoke
	task.delay(30, function()
		if tool and tool.Parent then -- only if the tool still exists
			if smoke then smoke.Enabled = true end
			print("💨 Smoke starting! (30s elapsed)")
		end
	end)

	-- 3. After 60 seconds, cooking complete
	task.delay(60, function()
		if tool and tool.Parent then
			tool:SetAttribute("Status", "Cooked")
			print("  Cooking complete! Ready for plating.")
			
			-- Visual feedback (indicate cooked state by adding brown or turning off flame)
			if grillPart then grillPart.Color = Color3.fromRGB(139, 69, 19) end -- brown (cooked)
			if smoke then smoke.Enabled = false end -- turn off smoke
		end
	end)
end

-------------------------------------------------------------
-- [3] Interaction management (Ingredient pickup & Plating)
-------------------------------------------------------------

-- A. Ingredient dispenser logic (ingredient boxes)
-- Find all parts inside the 'Ingredients' folder in Workspace
for _, dispenser in pairs(workspace.Ingredients:GetChildren()) do
	local prompt = dispenser:FindFirstChild("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			local character = player.Character
			local tool = character and character:FindFirstChild("PortableGrill") -- Chef tool name check

			if tool then
				local ingredientName = dispenser.Name -- Use the part's name as the ingredient name (e.g., Steak)
				
				-- Check if ingredient is already present
				if tool:GetAttribute("Has_"..ingredientName) then return end					
				-- Add ingredient
				tool:SetAttribute("Has_"..ingredientName, true)
				print("Ingredient added: " .. ingredientName)
				
				-- If this ingredient is the Base that starts cooking, start the timer
				for _, recipe in pairs(RECIPES) do
					if recipe.Base == ingredientName then
						startCooking(tool)
						break
					end
				end
			else
				warn("Please equip the grill (PortableGrill) first!")
			end
		end)
	end
end

-- B. Plating station logic (plates)
local plateStation = workspace:WaitForChild("PlatingStation")
local platePrompt = plateStation:FindFirstChild("ProximityPrompt")

if platePrompt then
	platePrompt.Triggered:Connect(function(player)
		local character = player.Character
		local tool = character and character:FindFirstChild("PortableGrill")

		if tool then
			-- 1. Check if the dish is fully cooked
			if tool:GetAttribute("Status") ~= "Cooked" then
				warn("The dish is not ready or is undercooked!")
				return
			end

			-- 2. Check recipe matching
			local foundRecipe = nil
			
			for _, recipe in pairs(RECIPES) do
				local match = true
				-- Check if all required ingredients are present
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

			-- 3. Dispense result
			if foundRecipe then
				print("Finished dish: " .. foundRecipe)
				
				-- Destroy the existing grill (cooking finished)
				tool:Destroy()
				
				-- Give the finished food tool
				local foodTool = FoodStorage:FindFirstChild(foundRecipe)
				if foodTool then
					local clone = foodTool:Clone()
					clone.Parent = player.Backpack
					-- Safely equip if humanoid exists
					if player.Character and player.Character:FindFirstChild("Humanoid") then
						player.Character.Humanoid:EquipTool(clone) -- equip immediately
					end
				else
					warn("No corresponding food tool in ServerStorage: " .. foundRecipe)
				end
			else
				warn("Ingredient combination mismatch. No matching recipe.")
			end
			
		else
			warn("Hold a finished grill and click the plating station.")
		end
	end
end
