print("[TEST] Файл загружен!")
local gui = Instance.new("ScreenGui")
gui.Name = "TEST_GUI"
gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local f = Instance.new("Frame")
f.Size = UDim2.new(0, 300, 0, 100)
f.Position = UDim2.new(0.5, -150, 0.5, -50)
f.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
f.Parent = gui
local l = Instance.new("TextLabel")
l.Size = UDim2.new(1, 0, 1, 0)
l.BackgroundTransparency = 1
l.Text = "TEST OK"
l.TextColor3 = Color3.new(1,1,1)
l.Font = Enum.Font.GothamBold
l.TextSize = 24
l.Parent = f
print("[TEST] GUI создан")
