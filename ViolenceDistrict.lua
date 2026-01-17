local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-----------------------------------------------ESPSYSTEM
-- CLEANUP
if game.CoreGui:FindFirstChild("systemESP") then
    game.CoreGui.systemESP:Destroy()
end

-- Cleanup Drawing Objects dari sesi sebelumnya
if _G.DrawingObjects then
    for _, obj in pairs(_G.DrawingObjects) do
        pcall(function() obj:Remove() end)
    end
end
_G.DrawingObjects = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local VirtualUser = game:GetService("VirtualUser")
local Camera = workspace.CurrentCamera
local LocalPlayer = game:GetService("Players").LocalPlayer
local Lighting = game:GetService("Lighting")
local Player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")



local ESPFolder = Instance.new("Folder", game.CoreGui)
ESPFolder.Name = "systemESP"

-- SETTINGS (Boolean Variable Baru)
_G.ESP_ENABLED = false
_G.ESP_TEAM = false
_G.ESP_ENEMY = false
_G.ESP_NAME = true
_G.ESP_BOX = true          -- GUI Box
_G.ESP_DRAWING_BOX = true  -- Drawing Box (Gaya script orang tadi)
_G.ESP_TRACERS = true     -- Tracer (Gaya script orang tadi)
_G.ESP_DISTANCE = true
_G.ESP_HIGHLIGHT = true
_G.ESP_HEALTHBAR = true

-- CONFIG WARNA
local function GetPlayerColor(player)
    if player.Team ~= LocalPlayer.Team then
        return Color3.fromRGB(255, 0, 0) -- Merah (Musuh)
    else
        return Color3.fromRGB(9, 0, 219) -- Biru (Teman)
    end
end

local function CreateESP(player)
    if player == LocalPlayer then return end

    -- Objek Drawing (Tracer & Box Drawing)
    local Tracer = Drawing.new("Line")
    local DBox = Drawing.new("Square")
    
    table.insert(_G.DrawingObjects, Tracer)
    table.insert(_G.DrawingObjects, DBox)

    local function SetupESP()
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart", 10)
        local hum = char:WaitForChild("Humanoid", 10)

        if not hrp or not hum then return end

        -- 1. HIGHLIGHT (GUI)
        local hl = Instance.new("Highlight")
        hl.Name = "HighlightESP"
        hl.FillTransparency = 0.7
        hl.Parent = char

        -- 2. NAME & DISTANCE (GUI)
        local nameGUI = Instance.new("BillboardGui")
        nameGUI.Adornee = hrp
        nameGUI.AlwaysOnTop = true
        nameGUI.Size = UDim2.new(5, 0, 1.5, 0)
        nameGUI.Parent = char

        local nameLabel = Instance.new("TextLabel")
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextSize = 16
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.Parent = nameGUI

        -- 3. HEALTHBAR (GUI)
        local hbGUI = Instance.new("BillboardGui")
        hbGUI.Size = UDim2.new(0.5, 0, 4, 0)
        hbGUI.StudsOffset = Vector3.new(-2.5, 0, 0)
        hbGUI.AlwaysOnTop = true
        hbGUI.Adornee = hrp
        hbGUI.Parent = char

        local back = Instance.new("Frame", hbGUI)
        back.BackgroundColor3 = Color3.new(0, 0, 0)
        back.Size = UDim2.new(0.3, 0, 1, 0)

        local privateBar = Instance.new("Frame", back)
        privateBar.BackgroundColor3 = Color3.new(0, 1, 0)
        privateBar.BorderSizePixel = 0
        privateBar.Size = UDim2.new(1, 0, 1, 0)

        -- 4. UPDATE LOOP
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not player or not player.Parent or not char or not char.Parent then
                Tracer:Remove()
                DBox:Remove()
                connection:Disconnect()
                return
            end

            local isTeammate = (player.Team == LocalPlayer.Team)
            local isVisible = _G.ESP_ENABLED and ((isTeammate and _G.ESP_TEAM) or (not isTeammate and _G.ESP_ENEMY))
            local rootPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            local teamColor = GetPlayerColor(player)

            if not isVisible or not onScreen then
                hl.Enabled = false
                nameGUI.Enabled = false
                hbGUI.Enabled = false
                Tracer.Visible = false
                DBox.Visible = false
                return
            end

            -- UPDATE HIGHLIGHT & NAME
            hl.Enabled = _G.ESP_HIGHLIGHT
            hl.FillColor = teamColor
            hl.OutlineColor = teamColor

            nameGUI.Enabled = _G.ESP_NAME
            nameLabel.Text = player.Name .. (_G.ESP_DISTANCE and " ["..math.floor((Camera.CFrame.Position - hrp.Position).Magnitude).."m]" or "")
            nameLabel.TextColor3 = teamColor

            -- UPDATE HEALTHBAR
            hbGUI.Enabled = _G.ESP_HEALTHBAR
            local hpScale = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            privateBar.Size = UDim2.new(1, 0, hpScale, 0)
            privateBar.Position = UDim2.new(0, 0, 1 - hpScale, 0)
            privateBar.BackgroundColor3 = Color3.new(1, 0, 0):Lerp(Color3.new(0, 1, 0), hpScale)

            -- 5. UPDATE TRACER (Drawing System)
            if _G.ESP_TRACERS then
                Tracer.Visible = true
                Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Bottom Center
                Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                Tracer.Color = teamColor
                Tracer.Thickness = 1
                Tracer.Transparency = 0.8
            else
                Tracer.Visible = false
            end

            -- 6. UPDATE DRAWING BOX (Drawing System)
            if _G.ESP_DRAWING_BOX then
                local top = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 3, 0))
                local bottom = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3.5, 0))
                local h = math.abs(top.Y - bottom.Y)
                local w = h * 0.6

                DBox.Visible = true
                DBox.Size = Vector2.new(w, h)
                DBox.Position = Vector2.new(rootPos.X - w/2, rootPos.Y - h/2)
                DBox.Color = teamColor
                DBox.Thickness = 2
                DBox.Filled = false
            else
                DBox.Visible = false
            end
        end)
    end
    
    SetupESP()
    player.CharacterAdded:Connect(SetupESP)
end

-- INITIALIZE
for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(CreateESP, p)
end
Players.PlayerAdded:Connect(function(p)
    task.spawn(CreateESP, p)
end)
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
_G.SmoothSpeed = 1 -- Nilai 20-30 biasanya sudah sangat pas untuk "Smooth"
_G.SpeedEnabled = false

RunService.RenderStepped:Connect(function(deltaTime)
    local Character = Player.Character
    if not Character then return end
    
    local Root = Character:FindFirstChild("HumanoidRootPart")
    local Hum = Character:FindFirstChild("Humanoid")
    
    if Root and Hum and _G.SpeedEnabled then
        if Hum.MoveDirection.Magnitude > 0 then
            -- DeltaTime memastikan kecepatan SAMA di semua PC (60 FPS atau 144 FPS)
            -- Kita kalikan MoveDirection dengan Speed dan deltaTime
            local moveVector = Hum.MoveDirection * _G.SmoothSpeed * deltaTime
            
            -- Pindahkan CFrame secara halus
            Root.CFrame = Root.CFrame + moveVector
        end
    end
end)
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
local noclip = false

RunService.Stepped:Connect(function()
    if noclip then
        local char = Player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
    -- Tidak perlu pakai 'else', biarkan Roblox yang urus tabrakan normalnya
end)
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
local targetName = {}
local target = Players:FindFirstChild(targetName)
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
local AntiAFK_Enabled = true

-- Event 'Idled' akan terpanggil otomatis oleh Roblox jika kamu diam selama 2-5 menit
LocalPlayer.Idled:Connect(function()
    if AntiAFK_Enabled then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0)) -- Klik kanan
    else
    end
end)
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

-- // MASTER TOGGLE (Satu saklar untuk semua)
_G.Master_ObjectESP = false 

-- // CONFIGURATION TABLE (Pusat kendali tiap object)
local TargetConfigs = {
    ["Gate"] = {
        DisplayName = "Gate", 
        Color = Color3.fromRGB(255, 255, 255), -- Putih
        Enabled = false -- Bisa dimatikan khusus yang ini saja
    },
    ["Generator"] = {
        DisplayName = "Generator", 
        Color = Color3.fromRGB(255, 255, 255), -- Putih
        Enabled = false
    },
    ["Hook"] = {
        DisplayName = "Hook", 
        Color = Color3.fromRGB(255, 0, 0), -- Merah
        Enabled = false 
    },
    ["Palletwrong"] = {
        DisplayName = "Pallet", 
        Color = Color3.fromRGB(255, 251, 0), -- Kuning
        Enabled = false 
    },
    ["Window"] = {
        DisplayName = "Window", 
        Color = Color3.fromRGB(62, 228, 235), -- Blue Clay meybe xD.
        Enabled = false 
    },
    ["ChristmasTree"] = {
        DisplayName = "Tree", 
        Color = Color3.fromRGB(7, 255, 0), -- Green
        Enabled = false 
    },
    ["Gift"] = {
        DisplayName = "Gift", 
        Color = Color3.fromRGB(255, 251, 0), -- Blue Clay meybe xD.
        Enabled = false 
    },
}

-- Fungsi untuk membuat ESP
local function CreateObjectESP(obj)
    local config = TargetConfigs[obj.Name]
    if not config or obj:FindFirstChild("ESP_Added") then return end

    local root = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    Instance.new("BoolValue", obj).Name = "ESP_Added"

    -- 1. HIGHLIGHT
    local hl = Instance.new("Highlight")
    hl.FillColor = config.Color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.5
    hl.Parent = obj

    -- 2. BILLBOARD GUI
    local gui = Instance.new("BillboardGui")
    gui.Adornee = root
    gui.Size = UDim2.new(5, 0, 1.5, 0)
    gui.AlwaysOnTop = true
    gui.Parent = obj

    local nameLabel = Instance.new("TextLabel", gui)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = config.Color
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 16
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.Text = config.DisplayName

    local distLabel = Instance.new("TextLabel", gui)
    distLabel.BackgroundTransparency = 1
    distLabel.TextColor3 = config.Color
    distLabel.Font = Enum.Font.SourceSansBold
    distLabel.TextSize = 13
    distLabel.Position = UDim2.new(0, 0, 0.4, 0)
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)

    -- 3. UPDATE LOOP (Satu loop untuk cek Master & Sub-Toggle)
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not obj or not obj.Parent then
            connection:Disconnect()
            return
        end

        -- Logika: Harus Master ON DAN Sub-Config ON
        local isActuallyActive = _G.Master_ObjectESP and config.Enabled

        hl.Enabled = isActuallyActive
        gui.Enabled = isActuallyActive

        if isActuallyActive then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local dist = (char.HumanoidRootPart.Position - root.Position).Magnitude
                distLabel.Text = "[" .. math.floor(dist) .. "m]"
            end
        end
    end)
end

-- // INITIALIZE
for _, obj in ipairs(workspace:GetDescendants()) do CreateObjectESP(obj) end
workspace.DescendantAdded:Connect(CreateObjectESP)
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- // CONFIGURATION
_G.FullBright_Enabled = false
_G.NoFog_Enabled = false

-- // Simpan settingan asli game agar bisa dikembalikan saat OFF
local OriginalSettings = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient
}

RunService.RenderStepped:Connect(function()
    -- 1. FULLBRIGHT LOGIC
    if _G.FullBright_Enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14 -- Paksa jadi siang hari
        Lighting.GlobalShadows = false -- Matikan bayangan agar tidak gelap di sudut
        Lighting.Ambient = Color3.fromRGB(255, 255, 255) -- Terang sampai ke dalam ruangan
    else
        -- Jika dimatikan, kembalikan ke settingan asli map
        Lighting.Brightness = OriginalSettings.Brightness
        Lighting.ClockTime = OriginalSettings.ClockTime
        Lighting.GlobalShadows = OriginalSettings.GlobalShadows
        Lighting.Ambient = OriginalSettings.Ambient
    end

    -- 2. NOFOG LOGIC
    if _G.NoFog_Enabled then
        Lighting.FogEnd = 100000 -- Buat kabut jadi sangat jauh (tak terlihat)
        -- Jika game pakai 'Atmosphere' object (Teknologi baru Roblox)
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Density = 0 -- Buat kabut jadi transparan total
        end
    else
        Lighting.FogEnd = OriginalSettings.FogEnd
        local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            atmosphere.Density = 0.4 -- Standar density kabut game horror
        end
    end
end)
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- // CONFIGURATION
_G.BypassGate = false

-- // FUNCTION UNTUK UPDATE GATE
local function UpdateGate()
    -- Cari Folder Gate di Workspace (Sesuaikan jalurnya jika perlu)
    local GateFolder = workspace:FindFirstChild("Map")

    for _, obj in pairs(GateFolder:GetChildren()) do
        if obj.Name == "Gate" then
            local LeftGate = obj:FindFirstChild("LeftGate")
            local LeftGateEnd = obj:FindFirstChild("LeftGate-end")
            local Box = obj:FindFirstChild("Box")
            
            -- Kita cek RightGate juga sekalian biar sinkron
            local RightGate = obj:FindFirstChild("RightGate")
            local RightGateEnd = obj:FindFirstChild("RightGate-end")
    
            if _G.BypassGate then
                LeftGate.Transparency = 1
                RightGate.Transparency = 1
                LeftGateEnd.Transparency = 0
                RightGateEnd.Transparency = 0
                LeftGate.CanCollide = false
                RightGate.CanCollide = false
                RightGateEnd.CanCollide = true
                LeftGateEnd.CanCollide = true
                Box.CanCollide = false
            else
                LeftGate.Transparency = 0
                RightGate.Transparency = 0
                LeftGateEnd.Transparency = 1
                RightGateEnd.Transparency = 1
                LeftGate.CanCollide = true
                RightGate.CanCollide = true
                RightGateEnd.CanCollide = false
                LeftGateEnd.CanCollide = false
                Box.CanCollide = true
            end
        end
    end
end

-- // EKSEKUSI & LOOPING
task.spawn(function()
    while true do
        UpdateGate()
        task.wait(0.1)
    end
end)
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- // 1. BOOLEAN / VARIABLES (Taruh di bagian paling atas script)
_G.AutoGenerator = false
_G.AutoHealing = false

local function JalankanAutoSuccess(eventObject)
    -- Kita cek apakah fiturnya sedang dinyalakan (Boolean Check)
    if not (_G.AutoGenerator or _G.AutoHealing) then return end

    local folder = eventObject.Parent
    if not folder then return end
    
    local folderName = folder.Name:lower()
    local resultRemote = folder:FindFirstChild("SkillCheckResultEvent") 
    
    if resultRemote then
        -- Jeda sedikit agar tidak instan (menghindari deteksi server)
        task.wait(0.15) 

        -- Cek apakah ini Skillcheck Generator atau Healing
        if string.find(folderName, "generator") and _G.AutoGenerator then
            resultRemote:FireServer("success", 1) -- Mengirim sinyal sukses
            warn(">>> [NusantaBlox] Auto Success: Generator")
            
        elseif string.find(folderName, "healing") and _G.AutoHealing then
            resultRemote:FireServer("success", 1)
            warn(">>> [NusantaBlox] Auto Success: Healing")
        end
    end
end

-- // 3. LISTENER (Mendeteksi munculnya Skillcheck)
-- Loop ini akan otomatis jalan di background
for _, subFolder in pairs(RemotesFolder:GetChildren()) do
    local startEvent = subFolder:FindFirstChild("SkillCheckEvent")
    if startEvent then
        startEvent.OnClientEvent:Connect(function()
            JalankanAutoSuccess(startEvent)
        end)
    end
end
---------------------------------------------------------------------------
---------------------------------------------------------------------------
local hitbox_Enable = false
local transparency_hitbox = 0.95
local hitbox_size = 10

RunService.RenderStepped:Connect(function()
    -- Loop ke semua pemain di dalam game
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        -- Pastikan kita tidak memperbesar badan sendiri dan karakter target ada
        if targetPlayer ~= LocalPlayer and targetPlayer.Character then
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                if hitbox_Enable then
                    -- LIVE UPDATE: Otomatis berubah saat slider/toggle digeser
                    hrp.Size = Vector3.new(hitbox_size, hitbox_size, hitbox_size)
                    hrp.Transparency = transparency_hitbox
                    hrp.CanCollide = false -- Agar tidak tabrakan saat kita dekat musuh
                    hrp.Color = Color3.fromRGB(255, 0, 0) -- Opsional: Ubah warna jadi merah
                else
                    -- RESET: Kembalikan ke ukuran asli jika OFF
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1 -- Default HRP biasanya transparan total
                    hrp.CanCollide = true
                end
            end
        end
    end
end)
---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------
local Window = WindUI:CreateWindow({
    Title = "Violence Distric",
    Icon = "globe", -- lucide icon
    Author = "NusantaBlox",
    Folder = "Nusantablox",
    
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,

    User = {
        Enabled = true,
        Anonymous = false,
    },
})


Window:EditOpenButton({
    Title = "Open/Close Menu",
    Icon = "minimize-2",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("FFFFFF"), 
        Color3.fromHex("000000")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

Window:Tag({
    Title = "v1.0.0",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13, -- from 0 to 13
})
Window:Tag({
    Title = "IN DEV",
    Color = Color3.fromHex("#ff0000"),
    Radius = 13, -- from 0 to 13
})

WindUI:Notify({
    Title = "Connection Info!",
    Content = "Script Succesfuly Loaded!",
    Duration = 3.8, -- 3 seconds
    Icon = "cloud-check",
})

-- Tabs
local AboutTab = Window:Tab({
    Title = "About",
    Icon = "info", -- optional
    Locked = false,
})
Window:Divider()
local SurvivorTab = Window:Tab({
    Title = "Survivor",
    Icon = "user-check", -- optional
    Locked = false,
})
local KillerTab = Window:Tab({
    Title = "Killer",
    Icon = "sword", -- optional
    Locked = false,
})
Window:Divider()
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "crown", -- optional
    Locked = false,
})
local EspTab = Window:Tab({
    Title = "ESP",
    Icon = "eye", -- optional
    Locked = false,
})
local PlayerTab = Window:Tab({
    Title = "Player",
    Icon = "user", -- optional
    Locked = false,
})
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map-pin", -- optional
    Locked = false,
})

--
AboutTab:Paragraph({
    Title = "NusantaBlox | 🇮🇩",
    Desc = "Main Founder: @ibrahimovick77",
    Image = "https://i.ibb.co.com/XrCRJ16f/Nusantablox.jpg",
    ImageSize = 30,
    Thumbnail = "https://cdn.discordapp.com/attachments/1436182349988630528/1459525069553532989/WhatsApp_Image_2026-01-09_at_18.23.21.jpeg?ex=696b8125&is=696a2fa5&hm=5f7f44392c2482dad1c548cd367643aebdc110fd3ffbf57efc609cd4a65d63eb",
    ThumbnailSize = 80,
})
AboutTab:Button({
    Title = "Youtube | Support Youtube Channel",
    IconAlign = "Left", -- Left or Right of the text
    Icon = "youtube", -- removing icon
    Callback = function()
        syn.open_url("https://www.youtube.com/@ibrahimk2709")
    end
})
AboutTab:Button({
    Title = "Instagram | Support Instagram",
    IconAlign = "Left", -- Left or Right of the text
    Icon = "instagram", -- removing icon
    Callback = function()
        syn.open_url("https://instagram.com")
    end
})
AboutTab:Button({
    Title = "Join Discord Now!! for new Update Info",
    IconAlign = "Left", -- Left or Right of the text
    Icon = "bot", -- removing icon
    Callback = function()
        
    end
})

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------SURVIVOR
SurvivorTab:Section({ 
    Title = "Features Generator",
    Icon = "heater",
    TextSize = 17,
})
SurvivorTab:Toggle({
    Title = "Auto SkillCheck (Perfect)",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.AutoGenerator = state
    end
})
SurvivorTab:Section({ 
    Title = "Features Heal",
    Icon = "briefcase-medical",
    TextSize = 17,
})
SurvivorTab:Toggle({
    Title = "Auto SkillCheck (Perfect)",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.AutoHealing = state
    end
})
SurvivorTab:Section({ 
    Title = "Features Cheat",
    Icon = "biohazard",
    TextSize = 17,
})
SurvivorTab:Button({
    Title = "Fling Killer",
    Desc = "",
    Locked = false,
    Callback = function()
        -- ...
    end
})
SurvivorTab:Button({
    Title = "Self UnHook (Not 100% but next time i try 100%)",
    Desc = "",
    Locked = false,
    Callback = function()
        -- ...
    end
})
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------KILLER
KillerTab:Section({ 
    Title = "Features Killer",
    Icon = "swords",
    TextSize = 17,
})
KillerTab:Toggle({
    Title = "Kill All",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        
    end
})
KillerTab:Toggle({
    Title = "Auto Attack (No Animation)",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        
    end
})
KillerTab:Section({ 
    Title = "Features Cheat",
    Icon = "biohazard",
    TextSize = 17,
})
KillerTab:Toggle({
    Title = "No Flashlight",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        
    end
})
KillerTab:Toggle({
    Title = "Remove All Pallet/Window",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        
    end
})
KillerTab:Button({
    Title = "Third Person Camera for Killer",
    Desc = "",
    Locked = false,
    Callback = function()
        -- ...
    end
})
KillerTab:Section({ 
    Title = "Features Hitbox",
    Icon = "box",
    TextSize = 17,
})
KillerTab:Input({
    Title = "Set Transparency",
    Desc = "",
    Value = "0.95",
    InputIcon = "",
    Type = "Input", -- or "Textarea"
    Placeholder = "..",
    Callback = function(input) 
        transparency_hitbox = input
    end
})
KillerTab:Input({
    Title = "Set Size",
    Desc = "",
    Value = "10",
    InputIcon = "",
    Type = "Input", -- or "Textarea"
    Placeholder = "..",
    Callback = function(input) 
        hitbox_size = input
    end
})
KillerTab:Toggle({
    Title = "Enable Hitbox",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        hitbox_Enable = state
    end
})
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------MAIN
MainTab:Section({ 
    Title = "Features Bypass",
    Icon = "lock-open",
    TextSize = 17,
})
MainTab:Toggle({
    Title = "Bypass Gate (Open Gate before Game End)",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.BypassGate = state
    end
})
MainTab:Section({ 
    Title = "Features Visual",
    Icon = "cloud",
    TextSize = 17,
})
MainTab:Toggle({
    Title = "Full Bright",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.FullBright_Enabled = state
    end
})
MainTab:Toggle({
    Title = "No Fog",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.NoFog_Enabled = state
    end
})
MainTab:Section({ 
    Title = "Misc",
    Icon = "settings",
    TextSize = 17,
})
MainTab:Toggle({
    Title = "Anti-AFK",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = true, -- default value
    Callback = function(state) 
        AntiAFK_Enabled = state
    end
})
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------ESP
EspTab:Section({ 
    Title = "Features ESP",
    Icon = "eye",
    TextSize = 17,
})
EspTab:Toggle({
    Title = "Enable ESP",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.ESP_ENABLED = state
        _G.Master_ObjectESP = state
    end
})
EspTab:Section({ 
    Title = "Role",
    Icon = "user",
    TextSize = 17,
})
EspTab:Toggle({
    Title = "ESP Survivor",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.ESP_TEAM = state
    end
})
EspTab:Toggle({
    Title = "ESP Killer",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.ESP_ENEMY = state
    end
})
EspTab:Section({ 
    Title = "Engine",
    Icon = "zap",
    TextSize = 17,
})
EspTab:Toggle({
    Title = "ESP Generator",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        TargetConfigs["Generator"].Enabled = state
    end
})
EspTab:Toggle({
    Title = "ESP Gate",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        TargetConfigs["Gate"].Enabled = state
    end
})
EspTab:Section({ 
    Title = "Object",
    Icon = "cuboid",
    TextSize = 17,
})
EspTab:Toggle({
    Title = "ESP Pallet",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        TargetConfigs["Palletwrong"].Enabled = state
    end
})
EspTab:Toggle({
    Title = "ESP Hook",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        TargetConfigs["Hook"].Enabled = state
    end
})
EspTab:Toggle({
    Title = "ESP Window",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        TargetConfigs["Window"].Enabled = state
    end
})
EspTab:Section({ 
    Title = "Xmas",
    Icon = "tree-pine",
    TextSize = 17,
})
EspTab:Toggle({
    Title = "ESP Tree Xmas",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        TargetConfigs["ChristmasTree"].Enabled = state
    end
})
EspTab:Toggle({
    Title = "ESP Gift",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state)   -- Tracer (Gaya script orang tadi)
        TargetConfigs["Gift"].Enabled = state
    end
})
EspTab:Divider()
EspTab:Section({ 
    Title = "ESP Settings",
    Icon = "settings",
    TextSize = 17,
})
EspTab:Toggle({
    Title = "ESP Name",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.ESP_NAME = state
    end
})
EspTab:Toggle({
    Title = "ESP Distance",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state)   -- Tracer (Gaya script orang tadi)
        _G.ESP_DISTANCE = state
    end
})
EspTab:Toggle({
    Title = "ESP HealthBar",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.ESP_HEALTHBAR = state
    end
})
EspTab:Toggle({
    Title = "ESP Highlight",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.ESP_HIGHLIGHT = state
    end
})
EspTab:Toggle({
    Title = "ESP Box",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.ESP_DRAWING_BOX = state
    end
})
EspTab:Toggle({
    Title = "ESP Tracers",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.ESP_TRACERS = state     
    end
})
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------PLAYER
PlayerTab:Section({ 
    Title = "Features Player",
    Icon = "rabbit",
    TextSize = 17,
})
PlayerTab:Slider({
    Title = "Set Speed",
    Desc = "",
    
    -- To make float number supported, 
    -- make the Step a float number.
    -- example: Step = 0.1
    Step = 1,
    Value = {
        Min = 1,
        Max = 125,
        Default = 1,
    },
    Callback = function(value)
        _G.SmoothSpeed = value
    end
})
PlayerTab:Toggle({
    Title = "Enable Speed",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        _G.SpeedEnabled = state
    end
})
PlayerTab:Section({ 
    Title = "Features Power",
    Icon = "battery-charging",
    TextSize = 17,
})
PlayerTab:Toggle({
    Title = "No Clip",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        noclip = state
    end
})
PlayerTab:Toggle({
    Title = "No Fall",
    Desc = "",
    Icon = "",
    Type = "Toggle",
    Value = false, -- default value
    Callback = function(state) 
        
    end
})
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------TELEPORT
TeleportTab:Section({ 
    Title = "Features Teleport",
    Icon = "compass",
    TextSize = 17,
})
TeleportTab:Dropdown({
    Title = "Select Place: ",
    Desc = "",
    Values = { "Lobby", "Game" },
    Value = "Lobby",
    Callback = function(option) 
        
    end
})
