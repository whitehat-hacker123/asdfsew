-- ServerScriptService > ChefSystemScript
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- [1] 레시피 및 재료 설정
local RECIPES = {
	{ 
		Name = "Beef Steak", 
		Ingredients = {"Steak", "Asparagus"}, 
		Base = "Steak" -- 굽기가 시작되는 핵심 재
	},
	{ 
		Name = "Salmon Meuniere", 
		Ingredients = {"Salmon", "Lemon"}, 
		Base = "Salmon" 
	},
	{ 
		Name = "Pasta Carbonara", 
		Ingredients = {"Pasta", "Bacon"}, 
		Base = "Bacon" -- 베이컨을 구우면 시작
	},
	{ 
		Name = "Tomato Soup", 
		Ingredients = {"Tomato", "Bread"}, 
		Base = "Tomato" -- 토마토를 끓이면 시작
	}
}

-- 완성된 음식 저장소
local FoodStorage = ServerStorage:WaitForChild("FinishedFood")

-------------------------------------------------------------
-- [2] 요리 로직 (Cooking Process)
-------------------------------------------------------------
local function startCooking(tool)
	if tool:GetAttribute("IsCooking") then return end -- 이미 요리 중이면 패스
	
	tool:SetAttribute("IsCooking", true)
	print("🔥 조리 시작! (1분 소요)")

	local grillPart = tool:FindFirstChild("GrillPart") -- 색이 변할 파트
	local smoke = grillPart and grillPart:FindFirstChild("Smoke")

	if grillPart then
		-- 1. 색상 변경 (30초 동안 천천히 빨갛게 달아오름)
		local tweenInfo = TweenInfo.new(30, Enum.EasingStyle.Linear)
		local goal = {Color = Color3.fromRGB(255, 50, 0)} -- 붉은색
		local tween = TweenService:Create(grillPart, tweenInfo, goal)
		tween:Play()
	end

	-- 2. 30초 후 연기 발생
	task.delay(30, function()
		if tool and tool.Parent then -- 도구가 여전히 존재할 때만
			if smoke then smoke.Enabled = true end
			print("💨 연기가 나기 시작합니다! (30초 경과)")
		end
	end)

	-- 3. 60초 후 조리 완료
	task.delay(60, function()
		if tool and tool.Parent then
			tool:SetAttribute("Status", "Cooked")
			print("✅ 요리 완료! 플레이팅 가능.")
			
			-- 시각적 피드백 (완료됨을 알리기 위해 초록빛 살짝 섞음 or 불 끄기)
			if grillPart then grillPart.Color = Color3.fromRGB(139, 69, 19) end -- 갈색(익음)
			if smoke then smoke.Enabled = false end -- 연기 끔
		end
	end)
end

-------------------------------------------------------------
-- [3] 상호작용 관리 (재료 담기 & 플레이팅)
-------------------------------------------------------------

-- A. 재료 디스펜서 로직 (재료 상자들)
-- Workspace 안의 'Ingredients' 폴더에 있는 모든 파트를 찾음
for _, dispenser in pairs(workspace.Ingredients:GetChildren()) do
	local prompt = dispenser:FindFirstChild("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			local character = player.Character
			local tool = character and character:FindFirstChild("PortableGrill") -- 셰프 도구 이름 확인

			if tool then
				local ingredientName = dispenser.Name -- 파트 이름을 재료 이름으로 사용 (예: Steak)
				
				-- 이미 있는 재료인지 확인
				if tool:GetAttribute("Has_"..ingredientName) then return end
				
				-- 재료 추가
				tool:SetAttribute("Has_"..ingredientName, true)
				print("재료 추가됨: " .. ingredientName)
				
				-- 만약 이 재료가 '굽기'를 시작하는 메인 재료라면 타이머 시작
				for _, recipe in pairs(RECIPES) do
					if recipe.Base == ingredientName then
						startCooking(tool)
						break
					end
				end
			else
				warn("그릴(PortableGrill)을 먼저 손에 들어주세요!")
			end
		end)
	end
end

-- B. 플레이팅 스테이션 로직 (접시)
local plateStation = workspace:WaitForChild("PlatingStation")
local platePrompt = plateStation:FindFirstChild("ProximityPrompt")

if platePrompt then
	platePrompt.Triggered:Connect(function(player)
		local character = player.Character
		local tool = character and character:FindFirstChild("PortableGrill")

		if tool then
			-- 1. 요리가 다 익었는지 확인
			if tool:GetAttribute("Status") ~= "Cooked" then
				warn("아직 요리가 완성되지 않았거나, 덜 익었습니다!")
				return
			end

			-- 2. 레시피 매칭 확인
			local foundRecipe = nil
			
			for _, recipe in pairs(RECIPES) do
				local match = true
				-- 필요한 모든 재료가 들어있는지 체크
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

			-- 3. 결과물 지급
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


