local Module = {} 

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()
local Heartbeat = RunService.Heartbeat

Module.__index = Module
Module.ClassName = "SocketBot"

local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"

local Connections = {}
Connections.__index = Connections

local ActiveSignals = {}

function Signal.new(SignalName)
	assert(typeof(SignalName) == "string" or not SignalName,"Invalid value type for SignalName")
	local self = setmetatable({
		["functions"] = {};
		["LastSignaled"] = tick();
		["ID"] = "__" .. HttpService:GenerateGUID();
		["Active"] = true;

	},Signal)
	if SignalName then
		self["Name"] = SignalName
	end
	ActiveSignals[self.ID] = self
	return self
end

function Signal.Get(id)
	assert(typeof(id) == "string","Invalid value type for id")
	local self = ActiveSignals[id]
	if not self then
		for _,signal in pairs(ActiveSignals) do
			if signal["Name"] == id then
				self = signal
				break
			end
		end
	end
	return self
end

function Signal.WaitFor(id,length)
	assert(typeof(id) == "string","Invalid value type for id")
	assert(typeof(length) == "number" or not length,"Invalid value type for id")
	length = length or 5
	local signal
	local StartTime = tick()
	while (not signal) and tick()-StartTime <= length and Heartbeat:Wait() do
		local self = ActiveSignals[id]
		if not self then
			for _,signal in pairs(ActiveSignals) do
				if signal["Name"] == id then
					self = signal
					break
				end
			end
		end
		if self then
			return self
		end
	end
	warn("Infinite yield possible when waiting for signal: " .. id)
end

local function Connect(self,callback)
	assert(typeof(callback) == "function","Invalid argument type for callback")
	local ID = "__" .. HttpService:GenerateGUID()
	self.functions[ID] = callback
	local connection = setmetatable({["Signal"] = self.ID},Connections)
	connection.ID = ID
	return connection
end

function Signal:Connect(callback)
	return Connect(self,callback)
end

function Signal:connect(callback)
	return Connect(self,callback)
end

local function Fire(self,...)
	self.LastSignaled = tick()
	if ActiveSignals[self.ID].Active then
		for _,funct in pairs(self.functions) do
			task.spawn(funct, ...)
		end
	end
end

function Signal:Fire(...)
	Fire(self,...)
end

function Signal:fire(...)
	Fire(self,...)
end

local function WaitForSignal(self)
	local LastSignalTick = tonumber(self.LastSignaled)
	while true do
		Heartbeat:Wait()
		if LastSignalTick ~= self.LastSignaled then
			return LastSignalTick-self.LastSignaled
		end
	end
end

function Signal:Wait()
	WaitForSignal(self)
end

function Signal:wait()
	WaitForSignal(self)
end

local function Destroy(self)
	ActiveSignals[self.ID].Active = false
end

function Signal:Destroy()
	Destroy(self)
end

function Signal:destroy()
	Destroy(self)
end

local function Disconnect(self)
	ActiveSignals[self.Signal].functions[self.ID] = nil
end

function Connections:Disconnect()
	Disconnect(self)
end

function Connections:disconnect()
	Disconnect(self)
end

function Module:CleanConnections(Tab)
    for i,v in pairs(Tab) do
        pcall(v.Disconnect, v)
    end
end

function Module:Print(...)
    local Str = ''
    local Idx = 0
    for i,v in pairs({...}) do
        if Idx == 0 then
            Str = string.format('%s', tostring(v))
        else
            Str = string.format('%s   %s', Str, tostring(v))
        end
        Idx = Idx + 1
    end
    rconsoleprint(string.format('%s\n', Str))
end

function Module:VectorToString(PosVector)
    return HttpService:JSONEncode({X=PosVector.X, Y=PosVector.Y, Z=PosVector.Z})
end

function Module:TableToVector(PosVector)
    return Vector3.new(PosVector.X, PosVector.Y, PosVector.Z)
end

function Module:CFrameToString(PosVector)
    local LookVector = PosVector.LookVector
    return HttpService:JSONEncode({{X=PosVector.X, Y=PosVector.Y, Z=PosVector.Z}, {X1=LookVector.X, Y1=LookVector.Y, Z1=LookVector.Z}})
end

function Module:TableToCFrame(PosVector)
    return CFrame.new(Vector3.new(PosVector.X, PosVector.Y, PosVector.Z), Vector3.new(PosVector.X1, PosVector.Y1, PosVector.Z1))
end

function Module:GetSocket()
    local Success, Return = pcall(function()
        return syn.websocket.connect('ws://localhost:1673/CommunicationServer')
    end)
    if not Success then
        task.wait()
        return self:GetSocket()
    end
    return Return
end

function Module:FormulatePacket(Options)
    if not Options then
        Options = {}
    end
    local Packet = {}
    Packet.Username = LocalPlayer.Name
    Packet.Data = Options.Data or ''
    Packet.Status = Options.Status or 'COMMUNICATION'
    Packet.JobId = game.JobId
    Packet.PlaceId = tostring(game.PlaceId)
    return HttpService:JSONEncode(Packet)
end

function Module:Send(Options)
    if shared.SocketBotStream then
        local PacketData = self:FormulatePacket(Options)
        pcall(shared.SocketBotStream.Send, shared.SocketBotStream, PacketData)
    end
end

function Module:TweenTo(CF)
    if LocalPlayer.Character then
        local PrimaryPart = LocalPlayer.Character:FindFirstChild'HumanoidRootPart' or LocalPlayer.Character.PrimaryPart
        if PrimaryPart then
            local Mag = (PrimaryPart.Position - CF.Position).Magnitude
            local Info = TweenInfo.new(Mag/80,Enum.EasingStyle.Linear)
            local Tween = TweenService:Create(PrimaryPart, Info, {CFrame = CF})
            table.insert(shared.CurrentTweens, Tween)
            Tween:Play()
            return Tween
        end
    end
end

function Module:StopTweens(Tab)
    for i,v in pairs(Tab) do
        if v:IsA'Tween' then
            pcall(v.Cancel, v)
            Tab[i] = nil
        end
    end
end

function Module.new(Debug)
    if shared.SocketBotConnections then 
        Module:CleanConnections(shared.SocketBotConnections)
    end
    if shared.SocketBotReadLoop then 
        shared.SocketBotReadLoop = false
        Heartbeat:Wait()
    end
    if shared.CurrentTweens then
        Module:StopTweens(shared.CurrentTweens)
    end
    shared.SocketMaster = ''
    shared.SocketBotReadLoop = true
    shared.SocketBotConnections = {}
    shared.CurrentTweens = {}
    shared.SocketBotStream = Module:GetSocket()
    if Debug then
        rconsolename('SOCKETBOT')
        Module:Print('Connected to websocket server')
    end
    table.insert(shared.SocketBotConnections, shared.SocketBotStream.OnMessage:Connect(function(RawPacket)
        local DecodedPacket = HttpService:JSONDecode(RawPacket)
        if (not DecodedPacket) or (not DecodedPacket.Status) then
            if Debug then
                Module:Print('CaughtMalformedPacket: ', RawPacket)
                rconsoleprint('> ')
            end
            return
        end
        if DecodedPacket.Status=='MASTERUPDATE' then
            shared.SocketMaster = DecodedPacket.Username
            if Debug then
                Module:Print('MasterUpdated: ', DecodedPacket.Username)
            end
        elseif DecodedPacket.Status=='TPPOS' then
            if shared.SocketMaster == LocalPlayer.Name then
                return
            end
            local CF = CFrame.new(Module:TableToVector(HttpService:JSONDecode(DecodedPacket.Data)))
            for i = 1, 10 do
                LocalPlayer.Character:PivotTo(CF)
                task.wait()
            end
        elseif DecodedPacket.Status=='FOLLOW' then
            if shared.SocketMaster == LocalPlayer.Name then
                return
            end
            local Pos = Module:TableToVector(HttpService:JSONDecode(DecodedPacket.Data))
            local Hum = LocalPlayer.Character:FindFirstChildOfClass'Humanoid'
            if Hum then
                Hum:MoveTo(Pos)
            end
        elseif DecodedPacket.Status=='TWEENPOS' then
            if shared.SocketMaster == LocalPlayer.Name then
                return
            end
            Module:StopTweens(shared.CurrentTweens)
            local CF = CFrame.new(Module:TableToVector(HttpService:JSONDecode(DecodedPacket.Data)))
            Module:TweenTo(CF)
        elseif DecodedPacket.Status=='COMMUNICATION' then
            if DecodedPacket.Data=='TP' then
                local FoundMaster = Players:FindFirstChild(shared.SocketMaster)
                if FoundMaster and FoundMaster.Character and LocalPlayer.Character then
                    LocalPlayer.Character:PivotTo(FoundMaster.Character.PrimaryPart.CFrame)
                end
            end
        end
        if Debug then
            --Module:Print('GotDebugPacket: ', RawPacket)
            --rconsoleprint('> ')
        end
    end))
    table.insert(shared.SocketBotConnections, UserInputService.InputBegan:Connect(function(Input, GPE)
        if GPE then
            return
        end
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            if shared.SocketMaster ~= LocalPlayer.Name then
                return
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                if Mouse.Hit then
                    Module:Send({Status = 'TWEENTP', Data = Module:VectorToString(Mouse.Hit.Position)})
                end
            elseif UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                if Mouse.Hit then
                    Module:Send({Status = 'LINETP', Data = Module:VectorToString(Mouse.Hit.Position)})
                end
            end
        end
    end))
    Module:Send({Status = 'INIT'})
    task.spawn(function()
        while shared.SocketBotReadLoop do
            rconsoleprint'> '
            local Input = rconsoleinput()
            local LowerInput = string.lower(Input)
            local Args = string.split(LowerInput, ' ')
            if Args[1] then
                if Args[1]=='getmaster' or Args[1]=='fetchmaster' then
                    Module:Send({Status = 'FETCHMASTER'})
                elseif (Args[1]=='setmaster' or Args[1]=='master') and (Args[2]) then
                    Module:Send({Status = 'SETMASTER', Data = Args[2]})
                elseif (Args[1]=='cls' or Args[1]=='clear') then
                    rconsoleclear()
                elseif (Args[1]=='postest' or Args[1]=='test') then
                    Module:Send({Status = 'LINETP', Data = Module:VectorToString(LocalPlayer.Character.PrimaryPart.Position)})
                elseif (Args[1]=='follow' or Args[1]=='followme') then
                    task.spawn(function()
                        while LocalPlayer.Character do 
                            Module:Send({Status = 'FOLLOW', Data = Module:CFrameToString(LocalPlayer.Character.PrimaryPart.CFrame)})
                            task.wait()
                        end
                    end)
                else
                    Module:Send({Data = Input})
                end
            end
            task.wait()
        end
    end)
    return Module
end

if game.PlaceId~=2788229376 then
    return
end

Module.new(true)