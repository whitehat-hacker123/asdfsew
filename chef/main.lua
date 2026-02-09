-- ServerScriptService > AdvancedCookingSystem
local RECIPES = {
	["Beef Steak"] = {"Steak", "Asparagus"},
	["Salmon Meuniere"] = {"Salmon", "Lemon"},
	-- 추가 레시피들...
}

-- [설정: 경로를 직접 수정하세요]
local STOVE_PART = workspace.CookingStation.StovePart -- 팬이 위치할 파트
local START_PROMPT = STOVE_PART.StartCookPrompt -- 조리 시작 프롬프트

-------------------------------------------------------------
-- [1] 조리 시작 로직 (팬을 가스레인지에 놓기)
-------------------------------------------------------------
START_PROMPT.Triggered:Connect(function(player)
	local character = player.Character
	local tool = character and character:FindFirstChild("PortableGrill")

	if tool then
		-- 1. 모든 재료가 담겼는지 체크 (레시피 중 하나라도 만족하는지)
		local canCook = false
		for name, ingredients in pairs(RECIPES) do
			local hasAll = true
			for _, ing in pairs(ingredients) do
				if not tool:GetAttribute("Has_"..ing) then hasAll = false break end
			end
			if hasAll then canCook = true break end
		end

		if not canCook then
			warn("재료가 부족합니다! 모든 재료를 담아오세요.")
			return
		end

		-- 2. 팬을 가스레인지에 고정
		START_PROMPT.Enabled = false -- 다른 사람이 사용 못 하게 잠금
		tool.Parent = workspace -- 백팩에서 꺼내기
		
		-- 팬의 위치 설정 (PrimaryPart 기준)
		local handle = tool:FindFirstChild("Handle")
		if handle then
			handle.CFrame = STOVE_PART.CFrame * CFrame.new(0, 1, 0) -- 살짝 위에 배치
			handle.Anchored = true -- 물리 엔진에 의해 떨어지지 않게 고정
		end

		-- 3. 조리 시작 (이전 코드의 startCooking 함수와 연동)
		print("🔥 조리 시작...")
		task.delay(60, function()
			tool:SetAttribute("Status", "Cooked")
			print("✅ 요리 완료! 이제 팬을 집어갈 수 있습니다.")
			
			-- 조리가 끝나면 팬에 있는 PickupPrompt 활성화
			local pickup = tool:FindFirstChild("PickupPrompt", true)
			if pickup then
				pickup.Enabled = true
				pickup.ActionText = "요리된 팬 집기"
			end
		end)
	end
end)

-------------------------------------------------------------
-- [2] 조리 완료 후 팬 회수 로직
-------------------------------------------------------------
-- 이 부분은 팬 모델 안에 PickupPrompt를 미리 만들어두어야 합니다.
-- 모든 PortableGrill에 대해 작동하도록 구성:
workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "PickupPrompt" and descendant:IsA("ProximityPrompt") then
		descendant.Triggered:Connect(function(player)
			local tool = descendant.Parent.Parent -- Prompt -> Part -> Tool 구조 가정
			
			if tool:GetAttribute("Status") == "Cooked" then
				local handle = tool:FindFirstChild("Handle")
				if handle then handle.Anchored = false end -- 고정 해제
				
				tool.Parent = player.Backpack
				descendant.Enabled = false -- 다시 비활성화
				START_PROMPT.Enabled = true -- 가스레인지 사용 가능하게 해제
				print(player.Name .. "이(가) 요리를 회수했습니다.")
			end
		end)
	end
end)
