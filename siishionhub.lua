-- ==========================================
-- ANTI-SPAM / GLOBAL DEBOUNCE
-- ==========================================
if getgenv().siiShionHub_Executed then return end
getgenv().siiShionHub_Executed = true

print("Loading siiShion Hub...")

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local targetParent = (gethui and gethui()) or game:GetService("CoreGui") or player:FindFirstChild("PlayerGui")

local TARGET_PLACE_ID = 129954712878723
local FINAL_PLACE_ID = 126884695634066 
local queueTp = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local dataFile = "AutoRejoinData.txt"
local configFile = "siiShionConfig.txt"

-- ==========================================
-- LOGO SIISHION HUB
-- ==========================================
local LOGO_ASSET_ID = "rbxthumb://type=Asset&id=73039278067533&w=150&h=150"

-- ==========================================
-- FUNGSI SMART INVENTORY SCANNER
-- ==========================================
local function GetInventoryCounts()
    local counts = {}
    local p = game:GetService("Players").LocalPlayer
    local function checkItem(item)
        if item:IsA("Tool") then
            local rawName = item.Name
            local lname = string.lower(rawName)
            if string.find(lname, "egg") or string.find(lname, "pelican") or string.find(lname, "manta") then
                local cleanName = string.gsub(rawName, "%s*%[.-%]", "")
                local base, qtyStr = string.match(cleanName, "^(.-)%s*[xX](%d+)%s*$")
                local finalName = base or cleanName
                finalName = string.match(finalName, "^%s*(.-)%s*$")
                local qty = tonumber(qtyStr) or 1
                counts[finalName] = (counts[finalName] or 0) + qty
            end
        end
    end
    pcall(function()
        if p.Backpack then for _, v in pairs(p.Backpack:GetChildren()) do checkItem(v) end end
        if p.Character then for _, v in pairs(p.Character:GetChildren()) do checkItem(v) end end
    end)
    return counts
end

-- ==========================================
-- READ SAVED DATA & CONFIG
-- ==========================================
local savedWebhook = ""
local isLooping = false
local loopData = nil

pcall(function()
    if isfile and isfile(configFile) and readfile then
        local content = readfile(configFile)
        if content and content ~= "" then
            local config = HttpService:JSONDecode(content)
            if config and config.Webhook then savedWebhook = config.Webhook end
        end
    end
end)

pcall(function()
    if isfile and isfile(dataFile) and readfile then
        local content = readfile(dataFile)
        if content and content ~= "" then
            local data = HttpService:JSONDecode(content)
            if data then
                if data.Webhook and data.Webhook ~= "" then savedWebhook = data.Webhook end
                if data.Sisa and data.Sisa > 0 then
                    isLooping = true
                    loopData = data
                end
            end
        end
    end
end)

local function SaveWebhookConfig(url)
    pcall(function()
        if writefile then
            writefile(configFile, HttpService:JSONEncode({Webhook = url}))
        end
    end)
end

-- ==========================================
-- WORKER SCRIPT (RUNS ON ALL SERVERS)
-- ==========================================
local WorkerCode = [====[
    if getgenv().siiShionWorker_Executed then return end
    getgenv().siiShionWorker_Executed = true

    local loadTimeout = 0
    while not game:IsLoaded() and loadTimeout < 50 do
        task.wait(0.1)
        loadTimeout = loadTimeout + 1
    end

    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer
    local targetParent = (gethui and gethui()) or game:GetService("CoreGui") or player:FindFirstChild("PlayerGui")
    
    local queueTp = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    local TARGET_PLACE_ID = 129954712878723
    local FINAL_PLACE_ID = 126884695634066 
    local dataFile = "AutoRejoinData.txt"
    local LOGO_ASSET_ID = "rbxthumb://type=Asset&id=73039278067533&w=150&h=150"
    local isCancelled = false

    local function GetInventoryCounts()
        local counts = {}
        local p = game:GetService("Players").LocalPlayer
        local function checkItem(item)
            if item:IsA("Tool") then
                local rawName = item.Name
                local lname = string.lower(rawName)
                if string.find(lname, "egg") or string.find(lname, "pelican") or string.find(lname, "manta") then
                    local cleanName = string.gsub(rawName, "%s*%[.-%]", "")
                    local base, qtyStr = string.match(cleanName, "^(.-)%s*[xX](%d+)%s*$")
                    local finalName = base or cleanName
                    finalName = string.match(finalName, "^%s*(.-)%s*$")
                    local qty = tonumber(qtyStr) or 1
                    counts[finalName] = (counts[finalName] or 0) + qty
                end
            end
        end
        pcall(function()
            if p.Backpack then for _, v in pairs(p.Backpack:GetChildren()) do checkItem(v) end end
            if p.Character then for _, v in pairs(p.Character:GetChildren()) do checkItem(v) end end
        end)
        return counts
    end

    if isfile and isfile(dataFile) and readfile and writefile then
        local success, dataStr = pcall(readfile, dataFile)
        if success and dataStr ~= "" then
            local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(dataStr) end)
            
            if decodeSuccess and data then
                local now = os.time()
                local currentPlace = game.PlaceId
                
                -- GUI STATUS IN-GAME
                local StatusGui = Instance.new("ScreenGui")
                StatusGui.Name = "siiShionStatusGUI"
                StatusGui.Parent = targetParent
                
                local StatusFrame = Instance.new("Frame")
                StatusFrame.Size = UDim2.new(0, 300, 0, 135)
                StatusFrame.Position = UDim2.new(0.5, -150, 0.4, 0)
                StatusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                StatusFrame.Parent = StatusGui
                pcall(function() Instance.new("UICorner", StatusFrame).CornerRadius = UDim.new(0, 8) end)
                pcall(function() 
                    local Stroke = Instance.new("UIStroke", StatusFrame)
                    Stroke.Color = Color3.fromRGB(0, 170, 0)
                    Stroke.Thickness = 2
                end)
                
                local HeaderFrame = Instance.new("Frame")
                HeaderFrame.Size = UDim2.new(1, 0, 0, 35)
                HeaderFrame.BackgroundTransparency = 1
                HeaderFrame.Parent = StatusFrame
                
                local StatusLogo = Instance.new("ImageLabel")
                StatusLogo.Size = UDim2.new(0, 24, 0, 24)
                StatusLogo.Position = UDim2.new(0, 15, 0.5, -12)
                StatusLogo.BackgroundTransparency = 1
                StatusLogo.Image = LOGO_ASSET_ID
                StatusLogo.Parent = HeaderFrame
                
                local StatusTitle = Instance.new("TextLabel")
                StatusTitle.Size = UDim2.new(1, -50, 1, 0)
                StatusTitle.Position = UDim2.new(0, 45, 0, 0)
                StatusTitle.BackgroundTransparency = 1
                StatusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
                StatusTitle.TextSize = 15
                StatusTitle.Font = Enum.Font.GothamBold
                StatusTitle.Text = "siiShion Hub"
                StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
                StatusTitle.Parent = HeaderFrame
                
                local CancelBtn = Instance.new("TextButton")
                CancelBtn.Size = UDim2.new(0, 30, 0, 30)
                CancelBtn.Position = UDim2.new(1, -35, 0, 2)
                CancelBtn.BackgroundTransparency = 1
                CancelBtn.Text = "X"
                CancelBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
                CancelBtn.TextSize = 18
                CancelBtn.Font = Enum.Font.GothamBold
                CancelBtn.Parent = HeaderFrame
                
                local Divider = Instance.new("Frame")
                Divider.Size = UDim2.new(0.9, 0, 0, 1)
                Divider.Position = UDim2.new(0.05, 0, 0, 35)
                Divider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                Divider.BorderSizePixel = 0
                Divider.Parent = StatusFrame

                local StatusText = Instance.new("TextLabel")
                StatusText.Size = UDim2.new(1, 0, 1, -80)
                StatusText.Position = UDim2.new(0, 0, 0, 36)
                StatusText.BackgroundTransparency = 1
                StatusText.TextColor3 = Color3.fromRGB(210, 210, 210)
                StatusText.TextSize = 16
                StatusText.Font = Enum.Font.GothamBold
                StatusText.Parent = StatusFrame

                local StopBtn = Instance.new("TextButton")
                StopBtn.Size = UDim2.new(0.9, 0, 0, 35)
                StopBtn.Position = UDim2.new(0.05, 0, 1, -45)
                StopBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
                StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                StopBtn.TextSize = 14
                StopBtn.Font = Enum.Font.GothamBold
                StopBtn.Text = "⏹ Stop Loop"
                StopBtn.Parent = StatusFrame
                pcall(function() Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 6) end)

                local function triggerStop()
                    isCancelled = true
                    if delfile then pcall(delfile, dataFile) end
                    StatusText.Text = "Loop Stopped Manually!"
                    StopBtn.Text = "Stopping..."
                    StopBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                    getgenv().siiShionHub_Executed = false 
                    getgenv().siiShionWorker_Executed = false
                    task.delay(3, function() pcall(function() StatusGui:Destroy() end) end)
                end

                CancelBtn.MouseButton1Click:Connect(triggerStop)
                StopBtn.MouseButton1Click:Connect(triggerStop)

                -- ==========================================
                -- FASE 1: FARMING DI TARGET SERVER
                -- ==========================================
                if currentPlace == TARGET_PLACE_ID then
                    local currentLoop = data.Total - data.Sisa + 1
                    StatusText.Text = "Processing...\nRejoin: " .. currentLoop .. " of " .. data.Total .. (data.IsInfinite and " (∞)" or "")
                    
                    if data.Webhook and data.Webhook ~= "" and httprequest then
                        local stepElapsed = now - (data.LastStepTime or now)
                        local stepMins = math.floor(stepElapsed / 60)
                        local stepSecs = stepElapsed % 60
                        local stepTimeStr = (stepMins > 0 and (stepMins .. "m ") or "") .. stepSecs .. "s"
                        local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

                        local payload = HttpService:JSONEncode({
                            username = "siiShion Hub",
                            embeds = {{
                                title = "🔄 Auto Rejoin Progress" .. (data.IsInfinite and " [INFINITE]" or ""),
                                color = 3447003,
                                fields = {
                                    {name = "👾 Username", value = "||" .. player.Name .. "||", inline = true},
                                    {name = "📊 Progress", value = "```" .. currentLoop .. " / " .. data.Total .. "```", inline = true},
                                    {name = "⏱️ Step Time", value = "```" .. stepTimeStr .. "```", inline = true}
                                },
                                footer = {text = "siiShion Hub", icon_url = "https://i.imgur.com/7bQ6Lvb.png"},
                                timestamp = timestamp
                            }}
                        })
                        pcall(function() httprequest({Url = data.Webhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload}) end)
                    end

                    data.Sisa = data.Sisa - 1
                    data.LastStepTime = os.time()
                    pcall(function() writefile(dataFile, HttpService:JSONEncode(data)) end)
                    
                    if queueTp then
                        queueTp([[if getgenv().siiShionWorker_Executed then return end if readfile and isfile and isfile("siiShionWorker.lua") then local f = loadstring(readfile("siiShionWorker.lua")) if f then f() end end]])
                    end
                    
                    for i = 1, 50 do
                        if isCancelled then return end
                        task.wait(0.1)
                    end
                    
                    if not isCancelled then
                        if data.Sisa > 0 then
                            pcall(function() TeleportService:Teleport(TARGET_PLACE_ID, player) end)
                        else
                            pcall(function() TeleportService:Teleport(FINAL_PLACE_ID, player) end)
                        end
                    end
                
                -- ==========================================
                -- FASE 2: ISTIRAHAT & SCAN DI GARDEN WORLD
                -- ==========================================
                elseif currentPlace == FINAL_PLACE_ID and data.Sisa <= 0 then
                    StatusText.Text = "Resting for 30s...\nSyncing inventory data..."
                    
                    for i = 1, 150 do
                        if isCancelled then return end
                        task.wait(0.1)
                    end
                    
                    if isCancelled then return end
                    
                    StatusText.Text = "Scanning Eggs & Pets...\nSending Webhook..."
                    
                    local finalItems = GetInventoryCounts()
                    local initialItems = data.InitialItems or {}
                    local allKeys = {}
                    
                    for k in pairs(finalItems) do allKeys[k] = true end
                    for k in pairs(initialItems) do allKeys[k] = true end
                    
                    local itemString = ""
                    for k in pairs(allKeys) do
                        local initCount = initialItems[k] or 0
                        local finCount = finalItems[k] or 0
                        local gained = finCount - initCount
                        
                        if finCount > 0 or initCount > 0 then
                            local gainStr = ""
                            if gained > 0 then gainStr = " (+" .. gained .. ")" 
                            elseif gained < 0 then gainStr = " (" .. gained .. ")" end
                            itemString = itemString .. "• " .. k .. ": " .. finCount .. gainStr .. "\n"
                        end
                    end
                    
                    if itemString == "" then itemString = "❌ Belum ada item target yang didapatkan." end
                    
                    if data.Webhook and data.Webhook ~= "" and httprequest then
                        local totalElapsed = now - (data.StartTime or now)
                        local totalMins = math.floor(totalElapsed / 60)
                        local totalSecs = totalElapsed % 60
                        local totalTimeStr = (totalMins > 0 and (totalMins .. "m ") or "") .. totalSecs .. "s"

                        local stepElapsed = now - (data.LastStepTime or now)
                        local stepMins = math.floor(stepElapsed / 60)
                        local stepSecs = stepElapsed % 60
                        local stepTimeStr = (stepMins > 0 and (stepMins .. "m ") or "") .. stepSecs .. "s"
                        local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

                        local payload = HttpService:JSONEncode({
                            username = "siiShion Hub",
                            embeds = {{
                                title = "✅ Auto Rejoin Cycle Completed!",
                                color = 65280,
                                fields = {
                                    {name = "👾 Username", value = "||" .. player.Name .. "||", inline = true},
                                    {name = "📊 Progress", value = "```" .. data.Total .. " / " .. data.Total .. "```", inline = true},
                                    {name = "⏱️ Last Step", value = "```" .. stepTimeStr .. "```", inline = true},
                                    {name = "⏳ Total Time", value = "```" .. totalTimeStr .. "```", inline = true},
                                    {name = "🎒 Items Farmed", value = "```\n" .. itemString .. "```", inline = false}
                                },
                                footer = {text = "siiShion Hub", icon_url = "https://i.imgur.com/7bQ6Lvb.png"},
                                timestamp = timestamp
                            }}
                        })
                        pcall(function() httprequest({Url = data.Webhook, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload}) end)
                    end
                    
                    StatusText.Text = "Scan Completed!\nWaiting to " .. (data.IsInfinite and "resume..." or "finish...")
                    
                    for i = 1, 150 do
                        if isCancelled then return end
                        task.wait(0.1)
                    end
                    
                    if not isCancelled then
                        if data.IsInfinite then
                            data.Sisa = data.Total
                            data.InitialItems = GetInventoryCounts() 
                            data.StartTime = os.time()
                            data.LastStepTime = os.time()
                            pcall(function() writefile(dataFile, HttpService:JSONEncode(data)) end)
                            
                            if queueTp then
                                queueTp([[if getgenv().siiShionWorker_Executed then return end if readfile and isfile and isfile("siiShionWorker.lua") then local f = loadstring(readfile("siiShionWorker.lua")) if f then f() end end]])
                            end
                            
                            pcall(function() TeleportService:Teleport(TARGET_PLACE_ID, player) end)
                        else
                            if delfile then pcall(delfile, dataFile) end
                            getgenv().siiShionHub_Executed = false 
                            getgenv().siiShionWorker_Executed = false
                            StopBtn.Visible = false
                            StatusText.Text = "Finished Completely!"
                            task.wait(3)
                            pcall(function() StatusGui:Destroy() end)
                        end
                    end
                
                -- ==========================================
                -- FASE RECOVERY: JIKA TER-DISCONNECT SAAT FARMING
                -- ==========================================
                else
                    StatusText.Text = "Resuming Farm...\nTeleporting to target..."
                    task.wait(3)
                    if not isCancelled then
                        pcall(function() TeleportService:Teleport(TARGET_PLACE_ID, player) end)
                    end
                end
            end
        end
    end
]====]

-- ==========================================
-- AUTO-RESUME DETECTOR
-- ==========================================
if isLooping then
    local func = loadstring(WorkerCode)
    if func then func() end
    return 
end

-- ==========================================
-- MAIN GUI CREATION
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "siiShionHubGUI"
if targetParent:FindFirstChild("siiShionHubGUI") then
    targetParent.siiShionHubGUI:Destroy()
end
ScreenGui.Parent = targetParent

local MinimizeIcon = Instance.new("ImageButton")
MinimizeIcon.Size = UDim2.new(0, 50, 0, 50)
MinimizeIcon.Position = UDim2.new(0, 15, 0.15, 0) 
MinimizeIcon.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MinimizeIcon.Image = LOGO_ASSET_ID
MinimizeIcon.Active = true
MinimizeIcon.Draggable = true 
MinimizeIcon.Visible = false 
MinimizeIcon.Parent = ScreenGui
pcall(function() Instance.new("UICorner", MinimizeIcon).CornerRadius = UDim.new(1, 0) end)
local IconStroke = Instance.new("UIStroke", MinimizeIcon)
IconStroke.Color = Color3.fromRGB(80, 80, 80)
IconStroke.Thickness = 2

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 350, 0, 340) 
MainFrame.Position = UDim2.new(0.5, -175, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui
pcall(function() Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10) end)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBar.Parent = MainFrame
pcall(function() Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10) end)

local TopBarCover = Instance.new("Frame")
TopBarCover.Size = UDim2.new(1, 0, 0, 10)
TopBarCover.Position = UDim2.new(0, 0, 1, -10)
TopBarCover.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TopBarCover.BorderSizePixel = 0
TopBarCover.Parent = TopBar

local TitleLogo = Instance.new("ImageLabel")
TitleLogo.Size = UDim2.new(0, 24, 0, 24)
TitleLogo.Position = UDim2.new(0, 10, 0.5, -12)
TitleLogo.BackgroundTransparency = 1
TitleLogo.Image = LOGO_ASSET_ID
TitleLogo.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0, 42, 0, 0) 
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Text = "siiShion Hub - v1.5.9"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 1, 0)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 40, 1, 0)
MinBtn.Position = UDim2.new(1, -80, 0, 0)
MinBtn.BackgroundTransparency = 1
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.TextSize = 24
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Text = "-"
MinBtn.Parent = TopBar

local WebhookWrapper = Instance.new("Frame")
WebhookWrapper.Size = UDim2.new(0.9, 0, 0, 35)
WebhookWrapper.Position = UDim2.new(0.05, 0, 0.22, 0)
WebhookWrapper.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
pcall(function() WebhookWrapper.ClipsDescendants = true end) 
WebhookWrapper.Parent = MainFrame
pcall(function() Instance.new("UICorner", WebhookWrapper).CornerRadius = UDim.new(0, 5) end)

local WebhookInput = Instance.new("TextBox")
WebhookInput.Size = UDim2.new(1, -16, 1, 0) 
WebhookInput.Position = UDim2.new(0, 8, 0, 0)
WebhookInput.BackgroundTransparency = 1
WebhookInput.TextColor3 = Color3.fromRGB(255, 255, 255)
WebhookInput.TextSize = 13
WebhookInput.Font = Enum.Font.Gotham
WebhookInput.PlaceholderText = "Enter Discord Webhook URL"
WebhookInput.Text = savedWebhook
WebhookInput.TextXAlignment = Enum.TextXAlignment.Left
WebhookInput.ClearTextOnFocus = false
WebhookInput.Parent = WebhookWrapper

local TestWebButton = Instance.new("TextButton")
TestWebButton.Size = UDim2.new(0.9, 0, 0, 35)
TestWebButton.Position = UDim2.new(0.05, 0, 0, 115)
TestWebButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TestWebButton.TextColor3 = Color3.fromRGB(200, 200, 200)
TestWebButton.TextSize = 14
TestWebButton.Font = Enum.Font.GothamBold
TestWebButton.Text = "Test Webhook"
TestWebButton.Parent = MainFrame
pcall(function() Instance.new("UICorner", TestWebButton).CornerRadius = UDim.new(0, 5) end)
local StrokeBtn = Instance.new("UIStroke", TestWebButton)
StrokeBtn.Color = Color3.fromRGB(80, 80, 80)
StrokeBtn.Thickness = 1

local JumlahInput = Instance.new("TextBox")
JumlahInput.Size = UDim2.new(0.9, 0, 0, 35)
JumlahInput.Position = UDim2.new(0.05, 0, 0, 160)
JumlahInput.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
JumlahInput.TextColor3 = Color3.fromRGB(255, 255, 255)
JumlahInput.TextSize = 14
JumlahInput.Font = Enum.Font.Gotham
JumlahInput.PlaceholderText = "Enter Amount (e.g., 5)"
JumlahInput.Text = ""
JumlahInput.Parent = MainFrame
pcall(function() Instance.new("UICorner", JumlahInput).CornerRadius = UDim.new(0, 5) end)

local ExecuteButton = Instance.new("TextButton")
ExecuteButton.Size = UDim2.new(0.9, 0, 0, 45)
ExecuteButton.Position = UDim2.new(0.05, 0, 0, 205)
ExecuteButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
ExecuteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecuteButton.TextSize = 16
ExecuteButton.Font = Enum.Font.GothamBold
ExecuteButton.Text = "Execute Loop"
ExecuteButton.Parent = MainFrame
pcall(function() Instance.new("UICorner", ExecuteButton).CornerRadius = UDim.new(0, 8) end)

local InfiniteButton = Instance.new("TextButton")
InfiniteButton.Size = UDim2.new(0.9, 0, 0, 45)
InfiniteButton.Position = UDim2.new(0.05, 0, 0, 260)
InfiniteButton.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
InfiniteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
InfiniteButton.TextSize = 16
InfiniteButton.Font = Enum.Font.GothamBold
InfiniteButton.Text = "Infinite Loop"
InfiniteButton.Parent = MainFrame
pcall(function() Instance.new("UICorner", InfiniteButton).CornerRadius = UDim.new(0, 8) end)

-- LOGIC: MINIMIZE & CLOSE
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() getgenv().siiShionHub_Executed = false end)
MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false MinimizeIcon.Visible = true end)
MinimizeIcon.MouseButton1Click:Connect(function() MainFrame.Visible = true MinimizeIcon.Visible = false end)

CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Color3.fromRGB(255, 50, 50) end)
CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200) end)
MinBtn.MouseEnter:Connect(function() MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end)
MinBtn.MouseLeave:Connect(function() MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200) end)

-- LOGIC: TEST WEBHOOK
TestWebButton.MouseButton1Click:Connect(function()
    local url = WebhookInput.Text
    if url == "" or not string.match(url, "^https://discord.com/api/webhooks/") then
        TestWebButton.Text = "Invalid Webhook URL!"
        TestWebButton.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
        task.wait(2)
        TestWebButton.Text = "Test Webhook"
        TestWebButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        return
    end

    SaveWebhookConfig(url) 

    if httprequest then
        TestWebButton.Text = "Sending Test..."
        local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        local payload = HttpService:JSONEncode({
            username = "siiShion Hub",
            embeds = {{
                title = "🔔 Webhook Test Successful!", 
                color = 16776960,
                fields = {
                    {name = "👾 Username", value = "||" .. player.Name .. "||", inline = true},
                    {name = "📝 Status", value = "```Ready to use.```", inline = true}
                },
                footer = {text = "siiShion Hub", icon_url = "https://i.imgur.com/7bQ6Lvb.png"},
                timestamp = timestamp
            }}
        })
        pcall(function() httprequest({Url = url, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = payload}) end)
        TestWebButton.Text = "Successfully Sent!"
        TestWebButton.BackgroundColor3 = Color3.fromRGB(40, 150, 40)
    else
        TestWebButton.Text = "Executor Not Supported!"
        TestWebButton.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    end
    task.wait(2)
    TestWebButton.Text = "Test Webhook"
    TestWebButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
end)

local function StartLoop(isInfiniteMode)
    local jumlah = tonumber(JumlahInput.Text)
    local webhookUrl = WebhookInput.Text

    if not jumlah or jumlah <= 0 then
        ExecuteButton.Text = "Enter a Valid Number!"
        InfiniteButton.Text = "Enter a Valid Number!"
        task.wait(2)
        ExecuteButton.Text = "Execute Loop"
        InfiniteButton.Text = "Infinite Loop"
        return
    end
    
    SaveWebhookConfig(webhookUrl) 
    
    if isInfiniteMode then
        InfiniteButton.Text = "Starting Infinite Mode..."
        InfiniteButton.BackgroundColor3 = Color3.fromRGB(150, 150, 0)
    else
        ExecuteButton.Text = "Starting Rejoin..."
        ExecuteButton.BackgroundColor3 = Color3.fromRGB(150, 150, 0)
    end
    
    -- CATAT MODAL AWAL TAS SECARA INSTAN
    local startItems = GetInventoryCounts()
    local now = os.time()
    
    pcall(function()
        if writefile then
            local dataToSave = {
                Target = TARGET_PLACE_ID, 
                Sisa = jumlah, 
                Total = jumlah, 
                Webhook = webhookUrl,
                StartTime = now,
                LastStepTime = now,
                IsInfinite = isInfiniteMode,
                InitialItems = startItems
            }
            writefile("AutoRejoinData.txt", HttpService:JSONEncode(dataToSave))
            writefile("siiShionWorker.lua", WorkerCode)
        end
    end)
    
    if queueTp then
        pcall(function()
            queueTp('if getgenv().siiShionWorker_Executed then return end if readfile and isfile and isfile("siiShionWorker.lua") then local f = loadstring(readfile("siiShionWorker.lua")) if f then f() end end')
        end)
    end

    -- TELEPORT LANGSUNG TANPA TUNGGU 30 DETIK SAAT PERTAMA KALI KLIK START
    task.wait(0.5)
    ScreenGui:Destroy()

    local success, errorMessage = pcall(function()
        TeleportService:Teleport(TARGET_PLACE_ID, player)
    end)
    if not success then warn("Teleport failed: " .. errorMessage) end
end

ExecuteButton.MouseButton1Click:Connect(function() StartLoop(false) end)
InfiniteButton.MouseButton1Click:Connect(function() StartLoop(true) end)

print("siiShion Hub loaded successfully!")
