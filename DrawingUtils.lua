local Module = {}

function Module:CleanDrawingAssets(Tab)
    for i,v in pairs(Tab) do
        local Success,Return = pcall(function()
            if typeof(v)=='table' then
                v:Destroy()
            end
        end)
        table.remove(Tab, i)
    end
end

function Module:CleanConnections(Tab)
    for i,v in pairs(Tab) do
        pcall(v.Disconnect, v)
        table.remove(Tab, i)
    end
end

function Module:New()
    self.RainbowColor = Color3.new()
    self.RGBTime = 10
    self.LastUpdate = 0
    self.HRP = nil
    self.BoundFunctions = {}
    
    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
    local Camera = workspace.CurrentCamera

    RunService:UnbindFromRenderStep('TyUtilsV2RenderQueue')

    if not shared.TyUtilsV2DrawingAssets then
        shared.TyUtilsV2DrawingAssets = {}
    else
        self:CleanDrawingAssets(shared.TyUtilsV2DrawingAssets)
    end

    if not shared.TyUtilsConnections then
        shared.TyUtilsConnections = {}
    else
        self:CleanConnections(shared.TyUtilsConnections)
    end

    table.insert(shared.TyUtilsConnections, LocalPlayer.CharacterAdded:Connect(function(Char)
        HRP = Char:WaitForChild('HumanoidRootPart')
    end))

    if LocalPlayer.Character then
        HRP = LocalPlayer.Character:WaitForChild('HumanoidRootPart')
    end

    table.insert(shared.TyUtilsConnections, UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent) 
        if GameProcessedEvent then
            return
        end
        for i,v in ipairs(self.BoundFunctions) do
            if v.KeyCode==Input.KeyCode then
                task.spawn(v.Closure)
            end
        end
    end))

    function self:Bind(KeyCode, Closure)
        table.insert(self.BoundFunctions, {KeyCode=KeyCode, Closure=Closure})
    end
    
    function self:DrawObject(Object, Options)
        if not Object then
            rconsoleprint('Module:DrawObject(Object, Options) is missing the object arg\n')
            return
        end
        if not Options then
            Options = {}
        end
        local Tab = {}
        Tab.Enabled = true
        Tab.Object = Object
        Tab.HRP = self.HRP
        Tab.TypeId = (Options.TypeId or 'None')
        Tab.MaxDistance = Options.MaxDistance
        Tab.DrawingItem = Drawing.new'Text'
        Tab.DrawingItem.Text = (Options.Text or Object.Name)
        Tab.DrawingItem.Center = (Options.Center or true)
        Tab.DrawingItem.Outline = (Options.Outline or true)
        if Options.Color and Options.Color=='Rainbow' then
            Tab.DrawingItem.Color = self.RainbowColor
            Tab.RainbowColor = true
        else
            Tab.DrawingItem.Color = Options.Color or Color3.fromRGB(255,255,255)
            Tab.RainbowColor = false
        end
        if Options.OutlineColor and Options.OutlineColor=='Rainbow' then
            Tab.DrawingItem.OutlineColor = self.RainbowColor
            Tab.RainbowOutlineColor = true
        else
            Tab.DrawingItem.OutlineColor = Options.OutlineColor or Color3.fromRGB(0,0,0)
            Tab.RainbowOutlineColor = false
        end
        Tab.DrawingItem.Transparency = (Options.Transparency or 1)
        Tab.DrawingItem.Size = (Options.Size or 20)
        Tab.DrawingItem.Font = (Options.Font or 1)
        Tab.DrawingItem.Position = Vector2.new()
        Tab.Exists = true
        Tab.OrigText = (Options.Text or Object.Name)
        Tab.UpdateMag = Options.UpdateMag or false

        function Tab:SetText(Text)
            if self and self.Exists then
                self.OrigText = Text
                if self.UpdateMag and HRP and self.Object then
                    local Magnitude = math.round((self.Object.Position-HRP.Position).Magnitude)
                    self.DrawingItem.Text = string.format('%s\n[%d]', Text, Magnitude)
                else
                    self.DrawingItem.Text = Text
                end
            end
        end

        function Tab:SetEnabled(State)
            if self and self.Exists then
                self.Enabled = State
            end
        end
    
        function Tab:Destroy()
            self.Exists = false
            pcall(self.DrawingItem.Remove, self.DrawingItem)
            Tab = nil
        end

        table.insert(shared.TyUtilsV2DrawingAssets, Tab)
    
        return Tab
    end

    RunService:BindToRenderStep('TyUtilsV2RenderQueue', 100, function(DT)
        local Hue = tick() % self.RGBTime / self.RGBTime
        self.RainbowColor = Color3.fromHSV(Hue, 1, 1)
        for i,v in ipairs(shared.TyUtilsV2DrawingAssets) do
            if v and v.Object and v.Exists and v.Object:IsDescendantOf(workspace) then
                if not v.Enabled then
                    v.DrawingItem.Visible = false
                    continue
                end
                local Position, IsVisible = Camera:WorldToScreenPoint(v.Object.Position)
                if IsVisible then
                    v.DrawingItem.Position = Vector2.new(Position.X, Position.Y)
                    if v.RainbowColor then
                        v.DrawingItem.Color = self.RainbowColor 
                    end
                    if v.RainbowOutlineColor then
                        v.DrawingItem.OutlineColor = self.RainbowColor 
                    end
                    if HRP then
                        local Magnitude = math.round((v.Object.Position-HRP.Position).Magnitude)
                        if v.UpdateMag then
                            v.DrawingItem.Text = string.format('%s\n[%d]', v.OrigText, Magnitude)
                        end
                        if v.MaxDistance then
                            if Magnitude>v.MaxDistance then
                                v.DrawingItem.Visible = false
                            else
                                v.DrawingItem.Visible = true
                            end
                        else
                            v.DrawingItem.Visible = true
                        end
                    end
                else
                    v.DrawingItem.Visible = false
                end
            else        
                if v.Exists then
                    v:Destroy()
                end
                table.remove(shared.TyUtilsV2DrawingAssets, i)
            end
        end
    end)

    return Module
end

return Module