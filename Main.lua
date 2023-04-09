Drawing = getfenv().Drawing do
	if Drawing == nil then
		error("Executor not supported")
	end
end

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

	local GUIlocation = (game.CoreGui or LocalPlayer.PlayerGui)
	if GUIlocation:FindFirstChild("ESPholder") then
		self.Holder = GUIlocation:FindFirstChild("ESPholder")
	else
		self.Holder = Instance.new("ScreenGui", GUIlocation)
		self.Holder.ResetOnSpawn = false
		self.Holder.Name = "ESPholder"
	end

	self.HighlightEnabled = true do
		if highlightenabled ~= nil then
			self.HighlightEnabled = highlightenabled
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
	self.Label = Drawing.new("Text")

	local Line = Drawing.new("Line")
	Line.Thickness = 2
	Line.Transparency = 1
	Line.ZIndex = 1

	local Label = self.Label
	Label.Visible = true
	Label.Center = true
	Label.Outline = true
	Label.Size = 30
	Label.Font = 2
	Label.Text = ""
	Label.Color = self.Color

	if self.HighlightEnabled then
		self.Highlight = Instance.new("Highlight", self.Holder)
		self.Highlight.FillTransparency = 1
		self.Highlight.OutlineColor = self.Color
		self.Highlight.Adornee = self.Target
	else
		self.Highlight:Destroy()
	end

	function self:CleanUp()
		if not self.Disconnect then
			error("CleanUp can only be called once disconnected.")
			return
		end
		if self.HighlightEnabled then
			self.Highlight:Destroy()
		end
		Line:Remove()
		Label:Remove()
	end

	RunService:BindToRenderStep(self.TracerId, Enum.RenderPriority.First.Value, function()
		local CurrentCamera = workspace.CurrentCamera
		local To, OnScreen = CurrentCamera:WorldToViewportPoint(self.Target.Position)

		if self.Highlight then
			self.Highlight.OutlineColor = self.Color
		end

		if self.Label.Text ~= "" then
			Label.Position = Vector2.new(To.X, To.Y - 35)
			Label.Visible = OnScreen
			Label.Color = self.Color
		end

		Line.Color = self.Color
		Line.Visible = OnScreen
		Line.From = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
		Line.To = Vector2.new(To.X, To.Y)
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
	if self.Label then
		self.Label.Text = text
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
