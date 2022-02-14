local Players = game:GetService'Players'
local UserInputService = game:GetService'UserInputService'
local RunService = game:GetService'RunService'
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local DefaultSize = Vector3.new(1, 0.8, 4)
local Enabled = false

local function GetHandle()
    local Sword = Char:FindFirstChildWhichIsA'Tool'
    if Sword then
        local Handle = Sword:FindFirstChild'Handle'
        if Handle then
            return Handle
        end
    end
end

local function SpoofSword()
    local Handle = GetHandle() or Char:WaitForChild'MatSword'
    if Handle then
        if Handle.Parent:FindFirstChild'Deeznuts' then
            return
        end
        local Clone = Handle:Clone()
        Clone.Name = 'Deeznuts'
        Clone.CFrame = Handle.CFrame
        local Weld = Instance.new'WeldConstraint'
        Weld.Part0 = Handle
        Weld.Part1 = Clone
        Weld.Parent = Clone
        Clone.Parent = Handle.Parent
        Clone.Massless = true
        Handle.Massless = true
        local SelectionBox = Handle.Parent:FindFirstChildWhichIsA'SelectionBox' or Handle.Parent:WaitForChild'Hitbox'
        if SelectionBox then
            SelectionBox.Adornee = Clone
        end
    end
end

UserInputService.InputBegan:Connect(function(Input, GPE)
    if GPE then
        return
    end
    if Input.KeyCode==Enum.KeyCode.Q then
        Enabled = true
    elseif Input.KeyCode==Enum.KeyCode.E then
        Enabled = false
    end
end)

RunService.Heartbeat:Connect(function()
    local Handle = GetHandle()
    if Handle then
        if not Handle.Parent:FindFirstChild'Deeznuts' then
            SpoofSword()
        end
        if Enabled then
            Handle.Size = Vector3.new(DefaultSize.X, DefaultSize.Y, 6)
        else
            Handle.Size = DefaultSize
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(Char)
    Char.ChildAdded:Connect(function()
        task.wait()
        SpoofSword()
    end)
end)

Char.ChildAdded:Connect(function()
    task.wait()
    SpoofSword()
end)

SpoofSword()