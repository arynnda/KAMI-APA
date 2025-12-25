repeat task.wait() until game:IsLoaded()
print("KAMI•APA")

-- ================= SERVICES =================
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ================= CONFIG =================
local TARGET_LIST = getgenv().TARGET_UNITS or {}

getgenv().GRAB_RADIUS = getgenv().GRAB_RADIUS or 8
getgenv().WEBHOOK_URL = getgenv().WEBHOOK_URL or "https://discord.com/api/webhooks/1410612798735646802/3thPcm1wsW63a_Qi_mjLSav-WeqOEn7hDGxnW74f5pvJliwh4bSdHONr_kv_jvpQkNJG"

local SPIN_INTERVAL = 10

-- ================= BASIC =================
local function getChar()
	return player.Character
end

local function getHRP()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function sendWebhook(msg)
	if getgenv().WEBHOOK_URL == "" then return end
	pcall(function()
		HttpService:PostAsync(
			getgenv().WEBHOOK_URL,
			HttpService:JSONEncode({ content = msg }),
			Enum.HttpContentType.ApplicationJson
		)
	end)
end

-- ================= TARGET CHECK =================
local function isTarget(model)
	local idx = model:GetAttribute("Index")
	if not idx then return false end
	for _, name in ipairs(TARGET_LIST) do
		if idx == name then
			return true
		end
	end
	return false
end

-- ================= STATE =================
local currentTarget = nil
local pendingItem = nil
local lastMoney = nil
local bought = false

-- ================= MONEY DETECT =================
local MONEY_NAMES = { "Cash","Money","Coins","Coin","Gold","Credits" }

task.spawn(function()
	local stats = player:WaitForChild("leaderstats")
	for _, v in ipairs(stats:GetChildren()) do
		if v:IsA("IntValue") or v:IsA("NumberValue") then
			for _, n in ipairs(MONEY_NAMES) do
				if v.Name:lower() == n:lower() then
					lastMoney = v.Value
					v.Changed:Connect(function(nv)
						if nv < lastMoney and pendingItem then
							sendWebhook(
								"🛒 **ITEM DIBELI**\n" ..
								"📦 "..pendingItem.."\n" ..
								"💰 "..(lastMoney - nv)
							)
							bought = true
							currentTarget = nil
							pendingItem = nil
						end
						lastMoney = nv
					end)
					return
				end
			end
		end
	end
end)

-- ================= TARGET SPAWN DETECT =================
workspace.DescendantAdded:Connect(function(obj)
	if currentTarget then return end
	if obj:IsA("Model") and isTarget(obj) then
		currentTarget = obj
		pendingItem = obj:GetAttribute("Index") or obj.Name
		bought = false
	end
end)

-- ================= PROMPT AUTO FIRE =================
ProximityPromptService.PromptShown:Connect(function(prompt)
	if currentTarget and prompt:IsDescendantOf(currentTarget) then
		fireproximityprompt(prompt)
	end
end)

-- ================= MOVE LOOP =================
task.spawn(function()
	while true do
		if currentTarget and currentTarget.Parent and not bought then
			local part = currentTarget:FindFirstChildWhichIsA("BasePart")
			local hum = getHumanoid()
			local hrp = getHRP()
			if part and hum and hrp then
				if (hrp.Position - part.Position).Magnitude > getgenv().GRAB_RADIUS then
					hum:MoveTo(part.Position)
				end
			end
		end
		task.wait(0.6) -- ultra ringan CPU
	end
end)

-- ================= ANTI AFK =================
player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
end)

-- ================= AUTO SPIN =================
task.spawn(function()
	local Packages = ReplicatedStorage:WaitForChild("Packages")
	local Net = require(Packages:WaitForChild("Net"))
	local SpinEvent = Net:RemoteEvent("ChristmasEventService/Spin")
	assert(SpinEvent, "SpinEvent tidak ditemukan")

	local lastSpin = 0
	while true do
		if tick() - lastSpin >= SPIN_INTERVAL then
			pcall(function()
				SpinEvent:FireServer()
			end)
			lastSpin = tick()
		end
		task.wait(0.5)
	end
end)

sendWebhook("✅ Auto-Grab ULTRA LITE Aktif")
print("Auto Grab + Auto Spin Aktif")
