local prompt = script.Parent
local fuseBoxPart = prompt.Parent

-- [config] --------------------------------------------------------
local BREAK_INTERVAL_MIN = 200   -- minimum fuse fail interval (sec)
local BREAK_INTERVAL_MAX = 450  -- mximum fuse fail interval (sec)
----------------------------------------------------------------

-- state varialbe
local isBroken = false

-- updating the state
local function updateVisual()
	if isBroken then

		prompt.Enabled = true
		prompt.ActionText = "Repair"
	else
		prompt.Enabled = false
	end
end

updateVisual()

-- random fail loop
spawn(function()
	while true do
		-- don't wiat for random loop if state = broken
		if not isBroken then
			local waitTime = math.random(BREAK_INTERVAL_MIN, BREAK_INTERVAL_MAX)
			wait(waitTime)

			if not isBroken then  -- if fuse isn't broken 
				isBroken = true
				print("fuse box is broken!")
				updateVisual()
			end
		else
			-- wait for player to fix this shit up
			wait(5)
		end
	end
end)

-- ProximityPrompt triger event 
prompt.Triggered:Connect(function(player)
	if not isBroken then return end  -- ignore the shit when the fusr is fucked up

	local character = player.Character
	if not character then return end

	-- check if player got fusr on his hand
	local fuseTool = character:FindFirstChild("Fuse")
	if fuseTool then
		local currentAmount = fuseTool:GetAttribute("amount")

		if currentAmount and currentAmount > 0 then
			print(player.Name .. ", this guy is fixin ...")

			-- u should add "amount" atribut to fuse tool 
			fuseTool:SetAttribute("amount", currentAmount - 1)

			
			isBroken = false
			updateVisual()

			-- <add the thing u want to do after player fix the fuse>
      
			-- remove the tool from player if amount atribute reach to 0 
			if currentAmount - 1 <= 0 then
				fuseTool:Destroy()
				print(player.Name .. "omg u just loose all of ur fuse")
			end
		else
			warn(player.Name .. "u got no fuse, get one")
		end
	else
		warn(player.Name .. "wsg dawg, btw u should fix it with fuse")
	end
end)
