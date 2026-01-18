-- ServerScriptService > NPCSystemScript
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

-------------------------------------------------------------
-- [1] config 
-------------------------------------------------------------

-- path of npc model (in ServerStorage )
local NPC_STORAGE_PATH = ServerStorage:WaitForChild("NPCModel") 

-- team name of barista
local TEAM_NAME = "Barista" 

-- spawn locations of npc (Vector3)
local SPAWN_LOCATIONS = {
	[1] = Vector3.new(10, 5, 0),   -- 자리 1
	[2] = Vector3.new(20, 5, 0),   -- 자리 2
	[3] = Vector3.new(0, 5, 10),   -- 자리 3
}

-- menu list
local MENU_LIST = {
	"Americano", "Latte", "Cappuccino", 
	"Caramel Latte", "Vanilla Latte", "Green Tea", "Hot Chocolate"
}

-------------------------------------------------------------
-- [2] variables
-------------------------------------------------------------
local activeBaristas = 0     -- current number of baristas
local occupiedSpots = {}     -- check if the seat is occupied (true/false)

-------------------------------------------------------------
-- [3] interaction logic of NPC (core)
-------------------------------------------------------------
local function setupNPCInteraction(npc)
	-- set user defined path (modify according to the model structure)
	local prompt = npc:WaitForChild("ProximityPrompt") -- prompt location
	local head = npc:WaitForChild("Head")              -- head part
	local billboard = head:WaitForChild("OrderGui")    -- Billboard GUI location
	local orderLabel = billboard:WaitForChild("OrderLabel") -- Text Label

	-- initial state setting
	billboard.Enabled = false -- initially, the order is not visible
	prompt.ActionText = "Take Order"
	prompt.ObjectText = "Customer"
	prompt.Name = "OrderPrompt" -- script identifier

	-- NPC menu selection
	local chosenMenu = MENU_LIST[math.random(1, #MENU_LIST)]
	npc:SetAttribute("DesiredMenu", chosenMenu) -- correct answer data storage
	orderLabel.Text = chosenMenu -- GUI text pre-setting

	-- interaction event connection
	prompt.Triggered:Connect(function(player)
		
		-- [step 1] order receiving
		if prompt.Name == "OrderPrompt" then
			print(player.Name .. " has taken the order.")
			
			-- turn on GUI
			billboard.Enabled = true
			
			-- prompt state change (enter step 2)
			prompt.ActionText = "Deliver Drink"
			prompt.Name = "DeliverPrompt"
			
		-- [step 2] deliver and verify
		elseif prompt.Name == "DeliverPrompt" then
			local character = player.Character
			local tool = character and character:FindFirstChildWhichIsA("Tool")
			
			-- 1. tool is held, and the tool has attributes
			if tool and tool:GetAttribute("CoffeeType") then
				local drinkName = tool:GetAttribute("CoffeeType")
				local correctMenu = npc:GetAttribute("DesiredMenu")
				
				if drinkName == correctMenu then
					-- [success]
					print("serving success! customer is satisfied.")
					
					-- Reward Cash (leaderstats)
					local leaderstats = player:FindFirstChild("leaderstats")
					if leaderstats and leaderstats:FindFirstChild("Cash") then
						leaderstats.Cash.Value += 100
					end
					
					-- 		reward after NPC departure (clear the seat)
					local spotIndex = npc:GetAttribute("SpawnIndex")
					occupiedSpots[spotIndex] = nil -- seat clear
					tool:Destroy() -- coffee deletion
					npc:Destroy()  -- NPC deletion (for new customer)
					
					-- 		If barista still exists, try calling new guest immediately
					task.wait(2)
					checkAndSpawnNPCs()
				else
					-- [fail] menu mismatch
					warn("ALERT: Incorrect drink! (Order: " .. correctMenu .. " / Submitted: " .. drinkName .. ")")
					-- add RemoteEvent to show red warning window on screen
				end
			else
				warn("ALERT: No cup held or the cup is empty.")
			end
		end
	end)
end

-------------------------------------------------------------
-- [6] spawn management system
-------------------------------------------------------------
-- actually spawn the NPC
local function spawnNPCAt(index)
	if occupiedSpots[index] then return end -- already occupied, cancel
	
	occupiedSpots[index] = true -- seat occupied
	
	local newNPC = NPC_STORAGE_PATH:Clone()
	newNPC:SetAttribute("SpawnIndex", index) -- remember which seat it is
	
	-- set coordinates (model's PrimaryPart must be set. or use MoveTo)
	if newNPC.PrimaryPart then
		newNPC:SetPrimaryPartCFrame(CFrame.new(SPAWN_LOCATIONS[index]))
	else
		newNPC:MoveTo(SPAWN_LOCATIONS[index])
	end
	
	newNPC.Parent = workspace
	setupNPCInteraction(newNPC) -- interaction logic injection
	print("Guest appeared at spot " .. index)
end

-- determine how many NPCs to spawn based on the current situation
function checkAndSpawnNPCs() -- global (re-call)
	print("Current Barista count: " .. activeBaristas)
	
	if activeBaristas == 0 then
		-- no barista, stop logic (keep existing NPCs or delete)
		return
	end

	-- generation rule
	if activeBaristas == 1 then
		-- 1 barista, spawn at seat 1 (if empty)
		if not occupiedSpots[1] then
			spawnNPCAt(1)
		end
	elseif activeBaristas >= 2 then
		-- 2 baristas, spawn at seats 1, 2, 3 (if empty)
		for i = 1, 3 do
			if not occupiedSpots[i] then
				spawnNPCAt(i)
			end
		end
	end
end

-------------------------------------------------------------
-- [5] team and player detection (events)
-------------------------------------------------------------
local function updateBaristaCount()
	local count = 0
	for _, player in pairs(Players:GetPlayers()) do
		if player.Team and player.Team.Name == TEAM_NAME then
			count += 1
		end
	end
	
	activeBaristas = count
	checkAndSpawnNPCs() -- when player count changes, check spawn
end

-- detect when player joins or team changes
Players.PlayerAdded:Connect(function(player)
	player:GetPropertyChangedSignal("Team"):Connect(updateBaristaCount)
	updateBaristaCount() -- on join
end)

Players.PlayerRemoving:Connect(function(player)
	updateBaristaCount() -- on leave
end)
