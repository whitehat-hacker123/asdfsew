-- ServerScriptService > NPCSystemScript
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

-------------------------------------------------------------
-- [1] 설정 (경로 및 좌표 수정)
-------------------------------------------------------------

-- NPC 모델 위치 (ServerStorage 안)
local NPC_STORAGE_PATH = ServerStorage:WaitForChild("NPCModel") 

-- 바리스타 팀 이름
local TEAM_NAME = "Barista" 

-- NPC 스폰 좌표 (Vector3) - 원하는 좌표로 수정하세요
local SPAWN_LOCATIONS = {
	[1] = Vector3.new(10, 5, 0),   -- 자리 1
	[2] = Vector3.new(20, 5, 0),   -- 자리 2
	[3] = Vector3.new(0, 5, 10),   -- 자리 3
}

-- 메뉴 리스트
local MENU_LIST = {
	"Americano", "Latte", "Cappuccino", 
	"Caramel Latte", "Vanilla Latte", "Green Tea", "Hot Chocolate"
}

-------------------------------------------------------------
-- [2] 변수 선언
-------------------------------------------------------------
local activeBaristas = 0     -- 현재 바리스타 수
local occupiedSpots = {}     -- 자리가 차 있는지 확인용 (true/false)

-------------------------------------------------------------
-- [3] NPC 상호작용 로직 (핵심)
-------------------------------------------------------------
local function setupNPCInteraction(npc)
	-- 사용자 지정 경로 설정 (모델 내부 구조에 맞춰 수정하세요)
	local prompt = npc:WaitForChild("ProximityPrompt") -- 프롬프트 위치
	local head = npc:WaitForChild("Head")              -- 머리 파트
	local billboard = head:WaitForChild("OrderGui")    -- 빌보드 GUI 위치
	local orderLabel = billboard:WaitForChild("OrderLabel") -- 텍스트 라벨

	-- 초기 상태 설정
	billboard.Enabled = false -- 처음엔 주문 안 보임
	prompt.ActionText = "주문 받기"
	prompt.ObjectText = "손님"
	prompt.Name = "OrderPrompt" -- 스크립트 구분용 이름

	-- NPC 메뉴 결정
	local chosenMenu = MENU_LIST[math.random(1, #MENU_LIST)]
	npc:SetAttribute("DesiredMenu", chosenMenu) -- 정답 데이터 저장
	orderLabel.Text = chosenMenu -- GUI 텍스트 미리 설정

	-- 상호작용 이벤트 연결
	prompt.Triggered:Connect(function(player)
		
		-- [단계 1] 주문 받기
		if prompt.Name == "OrderPrompt" then
			print(player.Name .. "님이 주문을 받았습니다.")
			
			-- GUI 켜기
			billboard.Enabled = true
			
			-- 프롬프트 상태 변경 (2단계로 진입)
			prompt.ActionText = "음료 전달하기"
			prompt.Name = "DeliverPrompt"
			
		-- [단계 2] 음료 전달 및 검증
		elseif prompt.Name == "DeliverPrompt" then
			local character = player.Character
			local tool = character and character:FindFirstChildWhichIsA("Tool")
			
			-- 1. 도구를 들고 있는지, 그 도구에 속성이 있는지 확인
			if tool and tool:GetAttribute("CoffeeType") then
				local drinkName = tool:GetAttribute("CoffeeType")
				local correctMenu = npc:GetAttribute("DesiredMenu")
				
				if drinkName == correctMenu then
					-- [성공]
					print("서빙 성공! 손님이 만족합니다.")
					
					-- Cash 지급 (leaderstats)
					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats and leaderstats:FindFirstChild("Cash") then
						leaderstats.Cash.Value += 100
					end
					
					-- 보상 후 NPC 퇴장 (자리 비우기)
					local spotIndex = npc:GetAttribute("SpawnIndex")
					occupiedSpots[spotIndex] = nil -- 자리 비움 처리
					tool:Destroy() -- 커피 삭제
					npc:Destroy()  -- NPC 삭제 (새로운 손님을 위해)
					
					-- 바리스타가 여전히 있으면 즉시 새 손님 호출 시도
					task.wait(2)
					checkAndSpawnNPCs()
				else
					-- [실패] 메뉴 불일치
					warn("ALERT: 잘못된 음료입니다! (주문: " .. correctMenu .. " / 제출: " .. drinkName .. ")")
					-- 여기에 화면에 붉은 경고창 띄우는 RemoteEvent 추가 가능
				end
			else
				warn("ALERT: 컵을 들고 있지 않거나, 빈 컵입니다.")
			end
		end
	end)
end

-------------------------------------------------------------
-- [4] 스폰 관리 시스템
-------------------------------------------------------------
-- 실제로 NPC를 생성하는 함수
local function spawnNPCAt(index)
	if occupiedSpots[index] then return end -- 이미 자리에 누가 있으면 취소
	
	occupiedSpots[index] = true -- 자리 차지함 표시
	
	local newNPC = NPC_STORAGE_PATH:Clone()
	newNPC:SetAttribute("SpawnIndex", index) -- 자신이 몇 번 자리에 있는지 기억
	
	-- 좌표 설정 (모델의 PrimaryPart가 설정되어 있어야 함. 아니면 MoveTo 사용)
	if newNPC.PrimaryPart then
		newNPC:SetPrimaryPartCFrame(CFrame.new(SPAWN_LOCATIONS[index]))
	else
		newNPC:MoveTo(SPAWN_LOCATIONS[index])
	end
	
	newNPC.Parent = workspace
	setupNPCInteraction(newNPC) -- 상호작용 로직 주입
	print(index .. "번 자리에 손님 등장")
end

-- 현재 상황에 맞춰 NPC를 얼마나 뽑을지 결정하는 함수
function checkAndSpawnNPCs() -- local 빼고 전역으로 선언 (재호출 위해)
	print("현재 바리스타 수: " .. activeBaristas)
	
	if activeBaristas == 0 then
		-- 바리스타가 없으면 로직 정지 (기존 NPC는 유지하거나 삭제 선택 가능)
		return
	end

	-- 생성 규칙
	if activeBaristas == 1 then
		-- 1명이면 1번 자리에만 생성 (없을 경우에만)
		if not occupiedSpots[1] then
			spawnNPCAt(1)
		end
	elseif activeBaristas >= 2 then
		-- 2명 이상이면 1, 2, 3번 자리 모두 체크해서 비어있으면 생성
		for i = 1, 3 do
			if not occupiedSpots[i] then
				spawnNPCAt(i)
			end
		end
	end
end

-------------------------------------------------------------
-- [5] 팀 및 플레이어 감지 (이벤트)
-------------------------------------------------------------
local function updateBaristaCount()
	local count = 0
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == TEAM_NAME then
			count += 1
		end
	end
	
	activeBaristas = count
	checkAndSpawnNPCs() -- 인원 변동 시 스폰 체크
end

-- 플레이어가 들어오거나 팀이 바뀔 때 감지
Players.PlayerAdded:Connect(function(player)
	player:GetPropertyChangedSignal("Team"):Connect(updateBaristaCount)
	updateBaristaCount() -- 접속 시 체크
end)

Players.PlayerRemoving:Connect(function(player)
	updateBaristaCount() -- 나갈 때 체크
end)
