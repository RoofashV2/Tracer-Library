local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Root = LocalPlayer.Character:WaitForChild("HumanoidRootPart")

local Module = {}
local Tracer = {}
Tracer.__index = Tracer
local TracerFunctions = {}
TracerFunctions.__index = TracerFunctions

function isInstance(object)
	return pcall(game.IsA, object, "Instance")
end

Module.new = function(highlightenabled)
	local self = setmetatable({}, Tracer)

	local UI = Instance.new("ScreenGui")
	UI.ResetOnSpawn = false
	
	if game.CoreGui then
		UI.Parent = game.CoreGui
	else
		UI.Parent = LocalPlayer.PlayerGui
	end

	local ViewportFrame = Instance.new("ViewportFrame", UI)
	ViewportFrame.Size = UDim2.new(1, 0, 1, 0)
	ViewportFrame.Transparency = 1
	ViewportFrame.CurrentCamera = workspace.CurrentCamera

	self["UI"] = UI
	self["ViewportFrame"] = ViewportFrame
	self.HighlightEnabled = highlightenabled do
		if highlightenabled == nil then
			self.HighlightEnabled = true
		end
	end

	return self
end

function Tracer:Bind(object, highlightobject)
	local self = setmetatable(self, TracerFunctions)
	self.__index = function(selfTable, index)
		assert(self.Disconnected, "Tracer:: Disconnected, cannot use functions.")
		return rawget(self, index)
	end
	
	self.Disconnected = false
	self.Running = true
	self.Target = object
	self.TracerId = HttpService:GenerateGUID(false)
	self.Color = Color3.fromRGB(255, 255, 255)
	
	local part = Instance.new("Part", self["ViewportFrame"])
	part.Color = self.Color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	
	if self.HighlightEnabled then
		self.Highlight = Instance.new("Highlight", (highlightobject or object))
		self.Highlight.FillTransparency = 1
		self.Highlight.OutlineColor = self.Color
	end

	self.TracerPart = part
	function self:CleanUp()
		if not self.Disconnect then
			error("CleanUp can only be called once disconnected.")
			return
		end
		self.Highlight:Destroy()
		part:Destroy()
		self.UI:Destroy()
	end
	
	RunService:BindToRenderStep(self.TracerId, Enum.RenderPriority.First.Value, function()
		if not self.Running or self.Disconnected then
			return
		end
		
		part.Color = self.Color
		if self.Highlight then
			self.Highlight.OutlineColor = self.Color
		end
		
		local target = self.Target
		local pos = (Root.Position - object.Position)
		local lookVector = pos.Unit
		local distance = pos.Magnitude
		part.CFrame = CFrame.new(Vector3.new(0, 0, 0), -lookVector)
		part.Position = target.Position + (lookVector * distance/2)
		part.Size = Vector3.new(0.05, 0.05, (Root.Position - target.Position).Magnitude)
	end)
	
	return self
end

function TracerFunctions:Start()
	self.Running = true
end

function TracerFunctions:Pause()
	self.Running = false
end

function TracerFunctions:SetText(text)
	if self.Target:FindFirstChild(self.TracerId) then
		local BillboardGui = self.Target:FindFirstChild(self.TracerId)
		BillboardGui.TextLabel.Text = text
	else
		local BillboardGui = Instance.new("BillboardGui")
		BillboardGui.Active = true
		BillboardGui.AlwaysOnTop = true
		BillboardGui.ClipsDescendants = true
		BillboardGui.LightInfluence = 1
		BillboardGui.Size = UDim2.new(5, 0, 1.3, 0)
		BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
		BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		BillboardGui.Parent = self.Target
		BillboardGui.Name = self.TracerId

		local TextLabel = Instance.new("TextLabel")
		TextLabel.BackgroundTransparency = 1
		TextLabel.Font = Enum.Font.SourceSans
		TextLabel.Size = UDim2.new(1, 0, 1, 0)
		TextLabel.Text = text
		TextLabel.TextColor3 = self.Color
		TextLabel.TextScaled = true
		TextLabel.TextSize = 14
		TextLabel.TextWrapped = true
		TextLabel.Parent = BillboardGui
	end
end

function TracerFunctions:Disconnect()
	self.Disconnect = true
	RunService:UnbindFromRenderStep(self.TracerId)
	self:CleanUp()
end

function TracerFunctions:DisconnectOnSignal(RBLXsignal)
	RBLXsignal:Connect(function()
		self:Disconnect()
	end)
end

function TracerFunctions:IsRunning()
	return self.Running
end

function TracerFunctions:SetColor(color)
	if type(color) == "userdata" then
		if color.R or color.G or color.B then
			self.Color = color
			if self.Target:FindFirstChild(self.TracerId) then
				local BillboardGui = self.Target:FindFirstChild(self.TracerId)
				BillboardGui.TextLabel.TextColor3 = self.Color
			end
			return
		end
	end
	
	error("Expected Color, got " .. type(color) .. ".")
end

return Module
