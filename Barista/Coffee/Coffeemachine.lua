-- script for all the machines 
local ServerStorage = game:GetService("ServerStorage")

-- find the Proximityprompt in its parent
local prompt = script.Parent:FindFirstChildWhichIsA("ProximityPrompt")

-- get the main event
local coffeeEvent = ServerStorage:WaitForChild("CoffeeEvents"):WaitForChild("CoffeeAction")

if prompt then
	prompt.Triggered:Connect(function(player)
		-- send the name of proxi to server
		coffeeEvent:Fire(player, prompt.Name)
	end)
else
	warn("cant find ProximityPrompt from: " .. script.Parent.Name)
end
