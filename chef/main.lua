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

	if grillPart then
		-- colo change module
		local tweenInfo = TweenInfo.new(30, Enum.EasingStyle.Linear)
		local goal = {Color = Color3.fromRGB(255, 50, 0)} -- colo aftu 30 sec
		local tween = TweenService:Create(grillPart, tweenInfo, goal)
		tween:Play()
	end

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
			if grillPart then grillPart.Color = Color3.fromRGB(139, 69, 19) end -- nig u dun?
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
				print("🍽️ 완성된 요리: " .. foundRecipe)
				
				-- 기존 그릴 삭제 (요리 끝)
				tool:Destroy()
				
				-- 완성된 음식 툴 지급
				local foodTool = FoodStorage:FindFirstChild(foundRecipe)
				if foodTool then
					local clone = foodTool:Clone()
					clone.Parent = player.Backpack
					player.Character.Humanoid:EquipTool(clone) -- 바로 손에 들려줌
				else
					warn("서버 저장소에 해당 음식 도구가 없습니다: " .. foundRecipe)
				end
			else
				warn("재료 조합이 이상합니다. 맞는 레시피가 없습니다.")
			end
			
		else
			warn("완성된 그릴을 들고 접시를 클릭하세요.")
		end
	end)
	--whats yo lookin fo
end




