-- Roblox.luau
-- Runs inside YOUR OWN Roblox experience (StarterPlayerScripts / LocalScript).
-- Uses only native Roblox APIs: Highlight, BillboardGui, Camera.FieldOfView.
-- No offsets, no external injection.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ============ CONFIG ============
local Config = {
    ESP = false,
    NAME = false,
    BOX = false,
    DISTANCE = false,
    FOV = false,
    FOVValue = 70,
}
-- ================================

local ESPObjects = {}

local function createHighlight(player)
    local char = player.Character
    if not char then return nil end
    local h = Instance.new("Highlight")
    h.FillColor = Color3.fromRGB(128, 0, 255)
    h.OutlineColor = Color3.fromRGB(200, 100, 255)
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
    return h
end

local function createBillboard(player)
    local char = player.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    if not head then return nil end

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.new(0, 200, 0, 50)
    gui.StudsOffset = Vector3.new(0, 2.5, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = head
    gui.Parent = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(200, 150, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Parent = gui

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistLabel"
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    distLabel.TextStrokeTransparency = 0
    distLabel.Parent = gui

    return gui
end

local function destroyFor(player)
    local obj = ESPObjects[player]
    if obj then
        obj:Destroy()
        ESPObjects[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
    -- FOV
    if Config.FOV then
        camera.FieldOfView = Config.FOVValue
    end

    -- ESP loop
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char = player.Character
        if not char then
            destroyFor(player)
            continue
        end

        if Config.ESP and not ESPObjects[player] then
            local h = Config.BOX and createHighlight(player) or nil
            local b = (Config.NAME or Config.DISTANCE) and createBillboard(player) or nil
            ESPObjects[player] = h or b
        end

        if Config.DISTANCE and ESPObjects[player] then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if hrp and myHrp then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                local label = ESPObjects[player]:FindFirstChild("DistLabel", true)
                if label then
                    label.Text = string.format("%d studs", math.floor(dist))
                end
            end
        end
    end
end)

return Config
