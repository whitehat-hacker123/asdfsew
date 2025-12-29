local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [config]
local JANITOR_TEAM_NAME = "Janitor" -- ur team name
local SPAWN_INTERVAL = 10 
local MAX_TRASH = 25
local CASH_REWARD = 10

local trashModel = ReplicatedStorage:WaitForChild("Trash") -- trash model located ReplicatedStorage
local spawnArea = game.Workspace:WaitForChild("SpawnArea") -- ur trash spawn part

-- trash folder
local trashFolder = game.Workspace:FindFirstChild("TrashFolder")
if not trashFolder then
	trashFolder = Instance.new("Folder")
	trashFolder.Name = "TrashFolder"
	trashFolder.Parent = game.Workspace
end

local function setupTrashFunction(trash)
	local prompt = trash:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then return end

	
	prompt.Triggered:Connect(function(player)
		local character = player.Character
		if character and character:FindFirstChild("Broom") then
			-- u could add ur own compensation system

			trash:Destroy() -- clean the trash
			
		else
			warn("Broom is requred")
		end
	end)
end

-- main loop random position
local function getRandomPosition()
	local size = spawnArea.Size
	local pos = spawnArea.Position
	local randomX = math.random(-size.X/2, size.X/2)
	local randomZ = math.random(-size.Z/2, size.Z/2)
	return Vector3.new(pos.X + randomX, pos.Y + (size.Y/2) + 0.5, pos.Z + randomZ)
end

-- main loop team check 
task.spawn(function()
	while true do
		local janitorTeam = Teams:FindFirstChild(JANITOR_TEAM_NAME)
		if not janitorTeam then 
			warn("check ur team : " .. JANITOR_TEAM_NAME)
			task.wait(5)
			continue 
		end

		local janitors = janitorTeam:GetPlayers()

		if #janitors > 0 then
			-- spawn trash when theres janitor
			if #trashFolder:GetChildren() < MAX_TRASH then
				local newTrash = trashModel:Clone()
				newTrash.Name = "Trash"
				newTrash.Position = getRandomPosition()
				newTrash.Parent = trashFolder

				
				setupTrashFunction(newTrash)
			end
		else
			-- remove everything when #janitor is 0 
			if #trashFolder:GetChildren() > 0 then
				trashFolder:ClearAllChildren()
				print("No janitors. Cleared all trash.")
			end
		end

		task.wait(SPAWN_INTERVAL)
	end
end)
