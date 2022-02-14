local DrawingUtils = loadstring(game:HttpGet'https://raw.githubusercontent.com/Ty-Roblox/RBXPublic/main/DrawingUtils.lua')():New()
local GameKeeper = workspace:WaitForChild'GameKeeper'
local Map = GameKeeper:WaitForChild'Map'
local Puzzles = GameKeeper:WaitForChild'Puzzles'
local Items = Map:WaitForChild'Items'

for i,v in ipairs(Puzzles:GetChildren()) do 
    DrawingUtils:DrawObject(v:FindFirstChildWhichIsA('BasePart', true), {Color='Rainbow', UpdateMag=true, Text=v.Name, TypeId='Puzzle'})
end
for i,v in ipairs(Items:GetChildren()) do 
    DrawingUtils:DrawObject(v:FindFirstChildWhichIsA('BasePart', true), {Color='Rainbow', UpdateMag=true, Text=v.Name, TypeId='Item'})
end
--game:GetService("Workspace").GameKeeper.Puzzles.PicturePuzzle.Buttons
--game:GetService("Workspace").GameKeeper.Map.Items.CakePlate.Model.CakePlate.Root