local Players = game:GetService'Players'
local UserInputService = game:GetService'UserInputService'
local RunService = game:GetService'RunService'
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local DefaultSize = Vector3.new(1, 0.8, 4)
local Enabled = false

if shared.HBCon then
    shared.HBCon:Disconnect()
end
if shared.UISCon then
    shared.UISCon:Disconnect()
end
shared.HBCon = nil
shared.UISCon = nil

local function GetSword()
    if LocalPlayer.Character then
        local Sword = LocalPlayer.Character:FindFirstChildWhichIsA'Tool'
        if Sword then
            return Sword
        end
    end
end

local function SpoofSword(Sword)
    if Sword then
        local Handle = Sword:FindFirstChild'Handle'
        if Handle then
            if Sword:FindFirstChild'Deeznuts' then
                return Handle
            end
            local Clone = Handle:Clone()
            Clone.Name = 'Deeznuts'
            Clone.CFrame = Handle.CFrame
            local Weld = Instance.new'WeldConstraint'
            Weld.Part0 = Handle
            Weld.Part1 = Clone
            Weld.Parent = Clone
            Clone.Size = DefaultSize
            Clone.Parent = Sword
            Clone.Massless = true
            Handle.Massless = true
            local SelectionBox = Sword:FindFirstChildWhichIsA'SelectionBox' or Sword:WaitForChild('Hitbox', 1)
            if SelectionBox then
                SelectionBox.Adornee = Clone
            end
            warn'Spoofed Sword'
            return Handle
        end
    end
end

shared.UISCon = UserInputService.InputBegan:Connect(function(Input, GPE)
    if GPE then
        return
    end
    if Input.KeyCode==Enum.KeyCode.Q then
        Enabled = true
    elseif Input.KeyCode==Enum.KeyCode.E then
        Enabled = false
    end
end)

shared.HBCon = RunService.Heartbeat:Connect(function()
    local Sword = GetSword()
    if Sword then
        local RealHandle = SpoofSword(Sword)
        if RealHandle then
            if Enabled then
                RealHandle.Size = Vector3.new(DefaultSize.X, DefaultSize.Y, 5.6)
            else
                RealHandle.Size = DefaultSize
            end
        end
    end
end)
