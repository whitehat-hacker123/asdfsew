-- ServerScriptService > CoffeeManagerScript
local ServerStorage = game:GetService("ServerStorage")

-- 1. 통신용 이벤트 가져오기
local coffeeEvent = ServerStorage:WaitForChild("CoffeeEvents"):WaitForChild("CoffeeAction")

-- 2. 색상 팔레트 정의 (음료 색상)
local COLORS = {
	Espresso = Color3.fromRGB(60, 40, 20),   -- 진한 에스프레소 색
	Water    = Color3.fromRGB(135, 206, 250),-- 물
	Milk     = Color3.fromRGB(255, 253, 240),-- 우유
	Caramel  = Color3.fromRGB(210, 105, 30), -- 카라멜 색
	Vanilla  = Color3.fromRGB(243, 229, 171),-- 바닐라 색
	GreenTea = Color3.fromRGB(107, 140, 66), -- 녹차 색
	HotChoco = Color3.fromRGB(90, 50, 20),   -- 핫초코 색
	Foam     = Color3.fromRGB(255, 255, 255) -- 거품 색
}

-- 3. 컵 업데이트 함수 (핵심 로직)
local function processRecipe(cup, actionName)
	local liquid = cup:FindFirstChild("Handle"):FindFirstChild("Liquid")
	if not liquid then return end

	-- 액체 보이게 설정
	liquid.Transparency = 0 

	-- 현재 컵 상태 가져오기
	local currentBase = cup:GetAttribute("Base") -- Espresso, GreenTea, HotChoco 등

	-------------------------------------------------------
	-- [A] 베이스 음료 (빈 컵에 담는 메뉴)
	-------------------------------------------------------
	if actionName == "GetEspresso" then
		liquid.Color = COLORS.Espresso
		cup:SetAttribute("Base", "Espresso")      -- 베이스 재료 설정
		cup:SetAttribute("CoffeeType", "Espresso") -- 현재 메뉴 이름

	elseif actionName == "GetGreenTea" then
		liquid.Color = COLORS.GreenTea
		cup:SetAttribute("Base", "GreenTea")
		cup:SetAttribute("CoffeeType", "Green Tea")
	
		-------------------------------------------------------
		-- [B] 추가 재료 (에스프레소가 있어야만 동작)
		-------------------------------------------------------
	elseif currentBase == "Espresso" then

		-- 중복 방지: 이미 완성된 음료라면 더 이상 재료 추가 불가 (선택 사항)
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

		print("메뉴 업데이트: " .. cup:GetAttribute("CoffeeType"))

	else
		-- 에스프레소가 없는데 물이나 시럽을 넣으려 할 때
		print("경고: 먼저 에스프레소를 추출해야 합니다.")
	end
end

-- 4. 이벤트 연결
coffeeEvent.Event:Connect(function(player, actionName)
	-- 직업 체크
	if player.Team.Name ~= "Barista" then return end

	local character = player.Character
	if not character then return end

	-- 손에 컵을 들고 있는지 확인
	local tool = character:FindFirstChild("Cup") -- 도구 이름이 Cup이어야 함
	if tool then
		processRecipe(tool, actionName)
	else
		-- 컵을 안 들고 있으면 알림 (선택)
		-- print("컵이 필요합니다.")
	end
end)
