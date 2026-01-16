-- Library
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles
local ImageManager = Library.ImageManager

-- Add Icon
ImageManager.AddAsset("Nusantablox", 133739520556173, "https://i.ibb.co.com/XrCRJ16f/Nusantablox.jpg")
local Nusantablox = ImageManager.GetAsset("Nusantablox")

-- Notify
Library:Notify({
     Title = "NusantaBlox",
     Description = "Press K to open menu",
     Time = 4,
})

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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = game.Players.LocalPlayer
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes") -- Menunggu folder Remotes muncul


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
_G.SmoothSpeed = 21 -- Nilai 20-30 biasanya sudah sangat pas untuk "Smooth"
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
-- Logic
local noclip = false
local player = game.Players.LocalPlayer
local character, humanoidRootPart

-- NoClip
game:GetService("RunService").Stepped:Connect(function()
	if noclip then
		character = player.Character
		if character then
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	else
		character = player.Character
		if character then
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
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
        -- Simulasi input agar server menganggap kita masih aktif
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0)) -- Klik kanan
        
        warn("Anti-AFK: Sinyal aktivitas dikirim! (Ceklis Aktif)")
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
-- TOGGLES (Hubungkan ke UI kamu)
_G.AutoGenerator = false 
_G.AutoHealing = false

-- // FUNGSI AUTO SUCCESS (Disesuaikan dengan Log Cobalt)
local function SolveSkillCheck(eventObject)
    local folder = eventObject.Parent
    if not folder then return end
    
    local folderName = folder.Name:lower()
    -- Gunakan nama sesuai temuan: SkillCheckResultEvent
    local resultRemote = folder:FindFirstChild("SkillCheckResultEvent") 
    
    if resultRemote then
        -- Berdasarkan Cobalt: Mengirim "success", 1, dan object target
        -- Kita tiru argumen tersebut agar server tidak curiga
        if string.find(folderName, "generator") and _G.AutoGenerator then
            resultRemote:FireServer("success", 1) 
            warn(">>> Cobalt Bypass: Generator Success Sent")
        elseif string.find(folderName, "healing") and _G.AutoHealing then
            resultRemote:FireServer("success", 1)
            warn(">>> Cobalt Bypass: Healing Success Sent")
        end
    end
end

-- // METATABLE HOOKING (Mencegat Gagal & Memperbaiki Nama)
local mt = getrawmetatable(game)
local (mt, false)
oldNamecall = mt.__namecall
setreadonly
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "FireServer" and _G.AutoGenerator then
        -- Blokir jika game mencoba mengirim sinyal gagal
        if self.Name == "SkillCheckFailEvent" then
            return nil
        end

        -- Jika player telat pencet, kita paksa argumennya sesuai data Cobalt
        if self.Name == "SkillCheckResultEvent" then
            args[1] = "success"
            args[2] = 100
            return oldNamecall(self, unpack(args))
        end
    end

    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- // LISTENER
for _, subFolder in pairs(RemotesFolder:GetChildren()) do
    local startEvent = subFolder:FindFirstChild("SkillCheckEvent")
    if startEvent then
        startEvent.OnClientEvent:Connect(function()
            SolveSkillCheck(startEvent)
        end)
    end
end
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- ========== Window Setting ==========
local Window = Library:CreateWindow({
    Title = "Nusantablox",
    Icon = 133739520556173,
    Footer = "Violence District | IN DEV",
    NotifySide = "Right",
    ShowCustomCursor = false,
    ToggleKeybind = Enum.KeyCode.K,
    AutoShow = true,
    DisableSearch = true,
})

-- ========== Tabs ==========
local DraggableLabel = Library:AddDraggableLabel("Obsidian demo")
DraggableLabel:SetVisible(true)
 
local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;
 
local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;
 
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;
 
    DraggableLabel:SetText(('NusatanBlox | %s fps | user'):format(
        math.floor(FPS)
    ));
end);

local Tabs = {
    Survivor = Window:AddTab("Survivor", "user-check"),
    Killer = Window:AddTab("Killer", "sword"),
    Main = Window:AddTab("Main", "crown"),
    ESP = Window:AddTab("ESP", "eye"),
    Player = Window:AddTab("Player", "user"),
    Teleport = Window:AddTab("Teleport", "box"),
    Client = Window:AddTab("Client", "settings"),
}

-------------------------SURVIVOR
local SurvivorTab = Tabs.Survivor

local GeneratorGroupBox = SurvivorTab:AddLeftGroupbox("Feature Generator")
local HealGroupBox = SurvivorTab:AddRightGroupbox("Feature Heal")
local SurvivalOtherGroupBox = SurvivorTab:AddLeftGroupbox("Other Feature")
---------------GENERATOR
GeneratorGroupBox:AddToggle("AutoSkillCheckPerfect", {
	Text = "Auto SkillCheck (Perfect)",
	Default = false,
})

Toggles.AutoSkillCheckPerfect:OnChanged(function(state)
    _G.AutoGenerator = state
end)
GeneratorGroupBox:AddToggle("AutoSkillCheckNotPerfect", {
	Text = "Auto SkillCheck (Not Perfect)",
	Default = false,
})
  
Toggles.AutoSkillCheckNotPerfect:OnChanged(function(state)
    
end)
-------------HEAL
HealGroupBox:AddToggle("AutoSkillCheckPerfectHEAL", {
	Text = "Auto SkillCheck (Perfect)",
	Default = false,
})
  
Toggles.AutoSkillCheckPerfectHEAL:OnChanged(function(state)
    _G.AutoHealing = state
end)
HealGroupBox:AddToggle("AutoSkillCheckNotPerfectHEAL", {
	Text = "Auto SkillCheck (Not Perfect)",
	Default = false,
})
  
Toggles.AutoSkillCheckNotPerfectHEAL:OnChanged(function(state)
    
end)
---------------OTHERSURVIVOR
SurvivalOtherGroupBox:AddButton({
    Text = "Fling Killer",
    Func = function()
        
    end
})
----------------------------------------------------------------------
----------------------------------------------------------------------

-------------------------KILLER
local KillerTab = Tabs.Killer

--------------------TAB
local KillerGroupBox = KillerTab:AddLeftGroupbox("Feature Killer")
local KillerOtherGroupBox = KillerTab:AddLeftGroupbox("Other Feature")
local KillerFunGroupBox = KillerTab:AddRightGroupbox("Feature Fun")
local KillerHitboxGroupBox = KillerTab:AddRightGroupbox("Feature Hitbox")

------------------------KILLER
KillerGroupBox:AddButton({
    Text = "Kill All",
    Func = function()
        
    end
})
------------------------FUN
KillerFunGroupBox:AddToggle("AutoAttack", {
	Text = "Auto Attack (No Animation)",
	Default = false,
})
  
Toggles.AutoAttack:OnChanged(function(state)
    
end)
------------------------KILLER OTHER
KillerOtherGroupBox:AddToggle("NoFlashlight", {
	Text = "No Flashlight",
	Default = false,
})
  
Toggles.NoFlashlight:OnChanged(function(state)
    
end)
KillerOtherGroupBox:AddToggle("RemovePalletAll", {
	Text = "Delete/Remove Pallet (All)",
	Default = false,
})
  
Toggles.RemovePalletAll:OnChanged(function(state)
    
end)
KillerOtherGroupBox:AddButton({
    Text = "Third Person Camera Killer",
    Func = function()
        print("Button clicked!")
    end
})
------------------------HITBOX
KillerHitboxGroupBox:AddInput("MyPseudoCodeInput", {
    Text = "Set Transparency Box",
    Default = "0.95",
    Placeholder = "...",
    Callback = function(value)
        
    end
})
KillerHitboxGroupBox:AddInput("MyPseudoCodeInput", {
    Text = "Set Size(box)",
    Default = "1.5",
    Placeholder = "...",
    Callback = function(value)
        
    end
})
KillerHitboxGroupBox:AddToggle("Hitbox", {
	Text = "Enable Hitbox",
	Default = false,
})
  
Toggles.Hitbox:OnChanged(function(state)
    
end)
-------------------------------------------------------------

------------------------MAIN
local MainTab = Tabs.Main

------------------TABS
local BypassGroupBox = MainTab:AddLeftGroupbox("Feature Bypass")
local VisualGroupBox = MainTab:AddRightGroupbox("Feature Visual")
local MiscGroupBox = MainTab:AddLeftGroupbox("Misc")

------------------BYPASS
BypassGroupBox:AddToggle("OpenGate", {
	Text = "Bypass Gate (Open Gate)",
	Default = false,
})
  
Toggles.OpenGate:OnChanged(function(state)
    _G.BypassGate = state
end)
------------------VISUAL
VisualGroupBox:AddToggle("FullBright", {
	Text = "Full Bright",
	Default = false,
})
  
Toggles.FullBright:OnChanged(function(state)
    _G.FullBright_Enabled = state
end)
VisualGroupBox:AddToggle("NoFog", {
	Text = "No Fog (Hapus Kabut)",
	Default = false,
})
  
Toggles.NoFog:OnChanged(function(state)
    _G.NoFog_Enabled = state
end)
------------------MISC
MiscGroupBox:AddToggle("AntiAfk", {
	Text = "Anti-AFK",
	Default = true,
})
  
Toggles.AntiAfk:OnChanged(function(state)
    AntiAFK_Enabled = state
end)
----------------------------------------------------

-------------------------ESP
local ESPTab = Tabs.ESP

------------------TABS
local ESPGroupBox = ESPTab:AddLeftGroupbox("Feature ESP")
local RoleGroupBox = ESPTab:AddLeftGroupbox("ESP Role")
local ESPEventGroupBox = ESPTab:AddLeftGroupbox("ESP Event")
local EngineGroupBox = ESPTab:AddRightGroupbox("ESP Engine")
local ObjectGroupBox = ESPTab:AddRightGroupbox("ESP Object")
local ESPSettingsGroupBox = ESPTab:AddRightGroupbox("ESP Settings")

------------------ESP
ESPGroupBox:AddToggle("EnableESP", {
	Text = "Enable ESP",
	Default = false,
})
  
Toggles.EnableESP:OnChanged(function(state)
    _G.ESP_ENABLED = state
    _G.Master_ObjectESP = state 
end)
------------------ROLE
RoleGroupBox:AddToggle("ESPSurvivor", {
	Text = "ESP Survivor",
	Default = false,
})
  
Toggles.ESPSurvivor:OnChanged(function(state)
    _G.ESP_TEAM = state
end)
RoleGroupBox:AddToggle("ESPKiller", {
	Text = "ESP Killer",
	Default = false,
})
  
Toggles.ESPKiller:OnChanged(function(state)
    _G.ESP_ENEMY = state
end)
------------------ENGINE
EngineGroupBox:AddToggle("ESPGenerator", {
	Text = "ESP Generator",
	Default = false,
})
  
Toggles.ESPGenerator:OnChanged(function(state)
    TargetConfigs["Generator"].Enabled = state
end)
EngineGroupBox:AddToggle("ESPGate", {
	Text = "ESP Gate",
	Default = false,
})
  
Toggles.ESPGate:OnChanged(function(state)
    TargetConfigs["Gate"].Enabled = state
end)
------------------OBJECT
ObjectGroupBox:AddToggle("ESPPallet", {
	Text = "ESP Pallet",
	Default = false,
})
  
Toggles.ESPPallet:OnChanged(function(state)
    TargetConfigs["Palletwrong"].Enabled = state
end)
ObjectGroupBox:AddToggle("ESPHook", {
	Text = "ESP Hook",
	Default = false,
})
  
Toggles.ESPHook:OnChanged(function(state)
    TargetConfigs["Hook"].Enabled = state
end)
ObjectGroupBox:AddToggle("ESPWindow", {
	Text = "ESP Window",
	Default = false,
})
  
Toggles.ESPWindow:OnChanged(function(state)
    TargetConfigs["Window"].Enabled = state
end)
------------------EVENT
ESPEventGroupBox:AddToggle("ESPEventTest1", {
	Text = "ESP Tree",
	Default = false,
})
  
Toggles.ESPEventTest1:OnChanged(function(state)
    TargetConfigs["ChristmasTree"].Enabled = state
end)
ESPEventGroupBox:AddToggle("ESPEventTest2", {
	Text = "ESP Gift",
	Default = false,
})
  
Toggles.ESPEventTest2:OnChanged(function(state)
    TargetConfigs["Gift"].Enabled = state
end)

------------------SETTINGS
ESPSettingsGroupBox:AddToggle("ESPName", {
	Text = "ESP Name",
	Default = true,
})
  
Toggles.ESPName:OnChanged(function(state)
    _G.ESP_NAME = state
end)
ESPSettingsGroupBox:AddToggle("ESPBox", {
	Text = "ESP Box",
	Default = true,
})
  
Toggles.ESPBox:OnChanged(function(state)
    _G.ESP_DRAWING_BOX = state
end)
ESPSettingsGroupBox:AddToggle("ESPTracers", {
	Text = "ESP Tracers",
	Default = true,
})
  
Toggles.ESPTracers:OnChanged(function(state)
    _G.ESP_TRACERS = state
end)
ESPSettingsGroupBox:AddToggle("ESPDistance", {
	Text = "ESP Distance",
	Default = true,
})

Toggles.ESPDistance:OnChanged(function(state)
    _G.ESP_DISTANCE = state
end)
ESPSettingsGroupBox:AddToggle("ESPHighlight", {
	Text = "ESP Highlight",
	Default = true,
})
  
Toggles.ESPHighlight:OnChanged(function(state)
    _G.ESP_HIGHLIGHT = state
end)
ESPSettingsGroupBox:AddToggle("ESPHealthBar", {
	Text = "ESP HealthBar",
	Default = true,
})
  
Toggles.ESPHealthBar:OnChanged(function(state)
    _G.ESP_HEALTHBAR = state
end)
-------------------------------------------------

-------------------------PLAYER
local PlayerTab = Tabs.Player

------------------TABS
local PlayerGroupBox = PlayerTab:AddLeftGroupbox("Feature Player")
local VisualGroupBox = PlayerTab:AddLeftGroupbox("Feature Visual")
local PowerGroupBox = PlayerTab:AddRightGroupbox("Feature Power")

------------------PLAYER
PlayerGroupBox:AddSlider("SpeedValue", {
    Text = "Set Speed",
    Default = 1,
    Min = 0,
    Max = 125,
    Rounding = 0,
})

Options.SpeedValue:OnChanged(function(value)
    _G.SmoothSpeed = value
end)
PlayerGroupBox:AddToggle("EnableSpeed", {
	Text = "Enable Speed",
	Default = false,
})
  
Toggles.EnableSpeed:OnChanged(function(state)
    _G.SpeedEnabled = state
end)
------------------POWER
PowerGroupBox:AddToggle("NoClip", {
	Text = "No Clip",
	Default = false,
})
  
Toggles.NoClip:OnChanged(function(state)
    noclip = state
end)
PowerGroupBox:AddToggle("NoFall", {
	Text = "No Fall",
	Default = false,
})
  
Toggles.NoFall:OnChanged(function(state)

end)
------------------VISUAL
VisualGroupBox:AddSlider("FieldoFView", {
    Text = "Set FOV Value",
    Default = 70,
    Min = 0,
    Max = 250,
    Rounding = 0,
})

Options.SpeedValue:OnChanged(function(value)
    FOV_Amount = value
end)
VisualGroupBox:AddToggle("SetFov", {
	Text = "Enable FieldOfView",
	Default = false,
})
  
Toggles.SetFov:OnChanged(function(state)
    FOV_Enabled = state
end)
--------------------------------------------

-------------------------TELEPORT
local TeleportTab = Tabs.Teleport

------------------TABS
local TeleportPlayerGroupBox = TeleportTab:AddLeftGroupbox("Feature Teleport Player")
local TeleportPlaceGroupBox = TeleportTab:AddRightGroupbox("Feature Teleport Place")

--------------------PLAYERTELEPORT
TeleportPlayerGroupBox:AddInput("TeleportPlayer", {
    Text = "Nickname Players",
    Default = "",
    Placeholder = "Nickname...",
    Callback = function(value)
        targetName = value
        target = Players:FindFirstChild(targetName)
    end
})
TeleportPlayerGroupBox:AddButton({
    Text = "Teleport to Player",
    Func = function()
        if not target then
            for i,v in pairs(Players:GetPlayers()) do if v.DisplayName==targetName then target=v break end end
        end
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0,5,0)
        end
    end
})
--------------------PLACETELEPORT
TeleportPlaceGroupBox:AddDropdown("MyDropdown", {
    Values = { "Game", "Lobby" },
    Default = "Game",
    Multi = false,
    Text = "Place:",
})
TeleportPlaceGroupBox:AddButton({
    Text = "Teleport to Place",
    Func = function()
        
    end
})
-------------------------------------------------------------------------------------------------------------------------

-- ========== Client Tab ==========
local ClientGroupLeft = Tabs.Client:AddLeftGroupbox("Menu", "wrench")

-- Notification
ClientGroupLeft:AddDropdown("NotificationSide", {
    Values = { "left", "right" },
    Default = "right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

-- DPI
ClientGroupLeft:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",

    Text = "DPI Scale",

    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)

        Library:SetDPIScale(DPI)
     end,
})

ClientGroupLeft:AddDivider() -- Divider

-- Keybind
ClientGroupLeft:AddLabel("Open/Close Menu"):AddKeyPicker("MenuKeybind", { Default = "K", NoUI = true, Text = "Open/Close Menu" })
Library.ToggleKeybind = Options.MenuKeybind

-- Unload/Self Destruct
ClientGroupLeft:AddButton("Self Destruct", function()
    print("Client has been destructed")
    _G.ESP_ENABLED = false
    _G.ESP_TEAM = false
    _G.ESP_ENEMY = false
    _G.ESP_NAME = false
    _G.ESP_BOX = false          -- GUI Box
    _G.ESP_DRAWING_BOX = false  -- Drawing Box (Gaya script orang tadi)
    _G.ESP_TRACERS = false     -- Tracer (Gaya script orang tadi)
    _G.ESP_DISTANCE = false
    _G.ESP_HIGHLIGHT = false
    _G.ESP_HEALTHBAR = false
    _G.Master_ObjectESP = false

    _G.AutoGenerator = false 
    _G.AutoHealing = false

    _G.BypassGate = false

    _G.FullBright_Enabled = false
    _G.NoFog_Enabled = false

    AntiAFK_Enabled = false
    noclip = false
    Library:Unload()
end)
