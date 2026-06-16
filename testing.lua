-- MyLibrary.lua

local Library = {}

function Library:CreateWindow(title)
	local player = game.Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "SimpleLibrary"
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 300, 0, 250)
	frame.Position = UDim2.new(0.5, -150, 0.5, -125)
	frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
	frame.Parent = gui

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1,0,0,40)
	text.Text = title
	text.TextColor3 = Color3.new(1,1,1)
	text.BackgroundTransparency = 1
	text.Parent = frame

	local Window = {}

	function Window:CreateButton(name, callback)
		local button = Instance.new("TextButton")

		button.Size = UDim2.new(0.8,0,0,35)
		button.Position = UDim2.new(0.1,0,0,50 + (#frame:GetChildren()*40))
		button.Text = name
		button.Parent = frame

		button.MouseButton1Click:Connect(function()
			callback()
		end)
	end


	function Window:CreateLabel(text)
		local label = Instance.new("TextLabel")

		label.Size = UDim2.new(1,0,0,25)
		label.Text = text
		label.TextColor3 = Color3.new(1,1,1)
		label.BackgroundTransparency = 1
		label.Parent = frame
	end


	return Window
end


return Library
