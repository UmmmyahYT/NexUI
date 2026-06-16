--[[
    ███╗   ██╗███████╗██╗  ██╗██╗   ██╗██╗
    ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██║
    ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║██║
    ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║██║
    ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝██║
    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝

    NexUI v1.1 — Roblox Script Menu Framework

    USAGE:
        local NexUI = loadstring(game:HttpGet("YOUR_RAW_URL"))()
        local Window = NexUI.CreateWindow({ Title = "My Script", Subtitle = "v1.0" })
        local Tab    = Window.AddTab({ Name = "Main" })
        Tab.AddToggle({ Name = "God Mode", Default = false, Callback = function(v) end })

    NOTE: All methods use DOT syntax, not colon syntax.
          NexUI.CreateWindow(...)  ✓
          NexUI:CreateWindow(...)  ✗
]]

-- ============================================================
--  SERVICES
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  UTILITIES
-- ============================================================

local function Tween(inst, props, t, style, dir)
    local info = TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw   = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

local function SafeDestroy(obj)
    if obj and obj.Parent then obj:Destroy() end
end

local function Clamp(v, mn, mx)
    return math.max(mn, math.min(mx, v))
end

local function Round(n, dec)
    local m = 10 ^ (dec or 0)
    return math.floor(n * m + 0.5) / m
end

local function ToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

-- ============================================================
--  THEME
-- ============================================================

local T = {
    Background    = Color3.fromRGB(15,  15,  20),
    Surface       = Color3.fromRGB(22,  22,  30),
    SurfaceHover  = Color3.fromRGB(30,  30,  42),
    Border        = Color3.fromRGB(45,  45,  60),
    Accent        = Color3.fromRGB(99,  102, 241),
    AccentHover   = Color3.fromRGB(129, 132, 255),
    AccentDim     = Color3.fromRGB(40,  42,  100),
    TextPrimary   = Color3.fromRGB(240, 240, 255),
    TextSecondary = Color3.fromRGB(140, 140, 170),
    TextMuted     = Color3.fromRGB(80,  80,  110),
    ToggleOff     = Color3.fromRGB(50,  50,  70),
    ToggleOn      = Color3.fromRGB(99,  102, 241),
    SliderTrack   = Color3.fromRGB(35,  35,  50),
    InputBg       = Color3.fromRGB(12,  12,  18),
    SectionBg     = Color3.fromRGB(20,  20,  28),
    White         = Color3.fromRGB(255, 255, 255),
    Danger        = Color3.fromRGB(239, 68,  68),
    Success       = Color3.fromRGB(34,  197, 94),
    Warning       = Color3.fromRGB(251, 191, 36),
}

-- ============================================================
--  GUI ROOT
-- ============================================================

if CoreGui:FindFirstChild("NexUI_Root") then
    CoreGui:FindFirstChild("NexUI_Root"):Destroy()
end

local Root = Instance.new("ScreenGui")
Root.Name           = "NexUI_Root"
Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Root.ResetOnSpawn   = false
Root.DisplayOrder   = 999
pcall(function() Root.Parent = CoreGui end)
if not Root.Parent then Root.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Notification container
local NotifContainer = Instance.new("Frame")
NotifContainer.BackgroundTransparency = 1
NotifContainer.Size     = UDim2.new(0, 280, 1, 0)
NotifContainer.Position = UDim2.new(1, -290, 0, 0)
NotifContainer.Parent   = Root

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifLayout.Padding           = UDim.new(0, 8)
NotifLayout.Parent            = NotifContainer

local NotifPad = Instance.new("UIPadding")
NotifPad.PaddingBottom = UDim.new(0, 16)
NotifPad.Parent        = NotifContainer

-- ============================================================
--  DRAGGING
-- ============================================================

local function MakeDraggable(handle, frame)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
--  MODULE TABLE  (plain table, no metatable, dot-syntax only)
-- ============================================================

local NexUI = {}

-- ============================================================
--  NOTIFY
-- ============================================================

function NexUI.Notify(config)
    config = config or {}
    local title    = config.Title    or "Notice"
    local desc     = config.Content  or ""
    local duration = config.Duration or 3
    local ntype    = config.Type     or "Info"

    local accent = T.Accent
    if ntype == "Success" then accent = T.Success
    elseif ntype == "Warning" then accent = T.Warning
    elseif ntype == "Error"   then accent = T.Danger
    end

    local notif = Instance.new("Frame")
    notif.Size                = UDim2.new(1, 0, 0, 0)
    notif.AutomaticSize       = Enum.AutomaticSize.Y
    notif.BackgroundColor3    = T.Surface
    notif.BorderSizePixel     = 0
    notif.ClipsDescendants    = true
    notif.BackgroundTransparency = 1
    notif.Parent              = NotifContainer

    local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0,8); nc.Parent = notif
    local ns = Instance.new("UIStroke"); ns.Color = T.Border; ns.Thickness = 1; ns.Parent = notif

    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel  = 0
    bar.Parent           = notif
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,3); bc.Parent = bar

    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.Size        = UDim2.new(1, -16, 0, 0)
    inner.Position    = UDim2.new(0, 12, 0, 0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.Parent      = notif

    local ip = Instance.new("UIPadding")
    ip.PaddingTop = UDim.new(0,10); ip.PaddingBottom = UDim.new(0,10); ip.Parent = inner

    local tl = Instance.new("TextLabel")
    tl.Text = title; tl.Font = Enum.Font.GothamBold; tl.TextSize = 13
    tl.TextColor3 = T.TextPrimary; tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.BackgroundTransparency = 1; tl.Size = UDim2.new(1,0,0,16); tl.Parent = inner

    if desc ~= "" then
        local dl = Instance.new("TextLabel")
        dl.Text = desc; dl.Font = Enum.Font.Gotham; dl.TextSize = 11
        dl.TextColor3 = T.TextSecondary; dl.TextXAlignment = Enum.TextXAlignment.Left
        dl.BackgroundTransparency = 1; dl.Size = UDim2.new(1,0,0,0)
        dl.AutomaticSize = Enum.AutomaticSize.Y; dl.TextWrapped = true
        dl.Position = UDim2.new(0,0,0,20); dl.Parent = inner
    end

    local prog = Instance.new("Frame")
    prog.Size            = UDim2.new(1,0,0,2)
    prog.Position        = UDim2.new(0,0,1,-2)
    prog.BackgroundColor3 = accent
    prog.BorderSizePixel = 0
    prog.Parent          = notif

    Tween(notif, { BackgroundTransparency = 0 }, 0.2)
    task.spawn(function()
        Tween(prog, { Size = UDim2.new(0,0,0,2) }, duration, Enum.EasingStyle.Linear)
        task.wait(duration)
        Tween(notif, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.35)
        SafeDestroy(notif)
    end)
end

-- ============================================================
--  CREATE WINDOW
-- ============================================================

function NexUI.CreateWindow(config)
    config = config or {}
    local winTitle    = config.Title    or "NexUI"
    local winSubtitle = config.Subtitle or ""
    local winSize     = config.Size     or Vector2.new(560, 380)
    local winPos      = config.Position or UDim2.new(0.5, -winSize.X/2, 0.5, -winSize.Y/2)

    -- Main frame
    local Win = Instance.new("Frame")
    Win.Name             = "NexUI_Window"
    Win.Size             = UDim2.new(0, winSize.X, 0, winSize.Y)
    Win.Position         = winPos
    Win.BackgroundColor3 = T.Background
    Win.BorderSizePixel  = 0
    Win.Parent           = Root

    local wc = Instance.new("UICorner"); wc.CornerRadius = UDim.new(0,10); wc.Parent = Win
    local ws = Instance.new("UIStroke"); ws.Color = T.Border; ws.Thickness = 1; ws.Parent = Win

    -- Title bar
    local TBar = Instance.new("Frame")
    TBar.Name             = "TitleBar"
    TBar.Size             = UDim2.new(1, 0, 0, 48)
    TBar.BackgroundColor3 = T.Surface
    TBar.BorderSizePixel  = 0
    TBar.ZIndex           = 2
    TBar.Parent           = Win

    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,10); tc.Parent = TBar
    -- fill bottom rounded corners of titlebar
    local tf = Instance.new("Frame")
    tf.Size = UDim2.new(1,0,0,10); tf.Position = UDim2.new(0,0,1,-10)
    tf.BackgroundColor3 = T.Surface; tf.BorderSizePixel = 0; tf.Parent = TBar

    -- Accent dot
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0,8,0,8); dot.Position = UDim2.new(0,14,0.5,-4)
    dot.BackgroundColor3 = T.Accent; dot.BorderSizePixel = 0; dot.Parent = TBar
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1,0); dc.Parent = dot

    local TTitle = Instance.new("TextLabel")
    TTitle.Text = winTitle; TTitle.Font = Enum.Font.GothamBold; TTitle.TextSize = 14
    TTitle.TextColor3 = T.TextPrimary; TTitle.BackgroundTransparency = 1
    TTitle.TextXAlignment = Enum.TextXAlignment.Left
    TTitle.Size = UDim2.new(0,220,1,0); TTitle.Position = UDim2.new(0,28,0,0); TTitle.Parent = TBar

    if winSubtitle ~= "" then
        local TSub = Instance.new("TextLabel")
        TSub.Text = winSubtitle; TSub.Font = Enum.Font.Gotham; TSub.TextSize = 11
        TSub.TextColor3 = T.TextMuted; TSub.BackgroundTransparency = 1
        TSub.TextXAlignment = Enum.TextXAlignment.Right
        TSub.Size = UDim2.new(0,160,1,0); TSub.Position = UDim2.new(1,-220,0,0); TSub.Parent = TBar
    end

    -- Close button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "✕"; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 12
    CloseBtn.TextColor3 = T.TextMuted; CloseBtn.BackgroundColor3 = T.Background
    CloseBtn.BorderSizePixel = 0; CloseBtn.AutoButtonColor = false
    CloseBtn.Size = UDim2.new(0,28,0,28); CloseBtn.Position = UDim2.new(1,-38,0.5,-14)
    CloseBtn.ZIndex = 3; CloseBtn.Parent = TBar
    local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0,6); cbc.Parent = CloseBtn

    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn,{BackgroundColor3=T.Danger,TextColor3=T.White},0.15) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn,{BackgroundColor3=T.Background,TextColor3=T.TextMuted},0.15) end)
    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Win,{BackgroundTransparency=1},0.2)
        task.wait(0.25); SafeDestroy(Win)
    end)

    -- Minimize button
    local MinBtn = Instance.new("TextButton")
    MinBtn.Text = "─"; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 12
    MinBtn.TextColor3 = T.TextMuted; MinBtn.BackgroundColor3 = T.Background
    MinBtn.BorderSizePixel = 0; MinBtn.AutoButtonColor = false
    MinBtn.Size = UDim2.new(0,28,0,28); MinBtn.Position = UDim2.new(1,-70,0.5,-14)
    MinBtn.ZIndex = 3; MinBtn.Parent = TBar
    local mbc = Instance.new("UICorner"); mbc.CornerRadius = UDim.new(0,6); mbc.Parent = MinBtn

    MinBtn.MouseEnter:Connect(function() Tween(MinBtn,{BackgroundColor3=T.AccentDim},0.15) end)
    MinBtn.MouseLeave:Connect(function() Tween(MinBtn,{BackgroundColor3=T.Background},0.15) end)

    local minimized = false
    local prevSize  = Win.Size
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            prevSize = Win.Size
            Tween(Win,{Size=UDim2.new(0,winSize.X,0,48)},0.25,Enum.EasingStyle.Quint)
        else
            Tween(Win,{Size=prevSize},0.25,Enum.EasingStyle.Quint)
        end
    end)

    MakeDraggable(TBar, Win)

    -- Sidebar tab bar
    local TabBar = Instance.new("Frame")
    TabBar.Name             = "TabBar"
    TabBar.Size             = UDim2.new(0, 130, 1, -48)
    TabBar.Position         = UDim2.new(0, 0, 0, 48)
    TabBar.BackgroundColor3 = T.Surface
    TabBar.BorderSizePixel  = 0
    TabBar.ClipsDescendants = true
    TabBar.Parent           = Win

    local tbrc = Instance.new("UICorner"); tbrc.CornerRadius = UDim.new(0,10); tbrc.Parent = TabBar
    local tbrf = Instance.new("Frame") -- fill right rounded corners
    tbrf.Size = UDim2.new(0,10,1,0); tbrf.Position = UDim2.new(1,-10,0,0)
    tbrf.BackgroundColor3 = T.Surface; tbrf.BorderSizePixel = 0; tbrf.Parent = TabBar

    local TabList = Instance.new("UIListLayout")
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Padding   = UDim.new(0,4)
    TabList.Parent    = TabBar

    local TabPad = Instance.new("UIPadding")
    TabPad.PaddingTop = UDim.new(0,8); TabPad.PaddingLeft = UDim.new(0,6); TabPad.PaddingRight = UDim.new(0,6)
    TabPad.Parent = TabBar

    -- Divider
    local Div = Instance.new("Frame")
    Div.Size = UDim2.new(0,1,1,-48); Div.Position = UDim2.new(0,130,0,48)
    Div.BackgroundColor3 = T.Border; Div.BorderSizePixel = 0; Div.Parent = Win

    -- Content area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name   = "ContentArea"
    ContentArea.Size   = UDim2.new(1,-131,1,-48)
    ContentArea.Position = UDim2.new(0,131,0,48)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true
    ContentArea.Parent = Win

    -- ── Window object ────────────────────────────────────────
    local WindowObj  = {}
    local tabs       = {}
    local activeTab  = nil
    local tabOrder   = 0

    function WindowObj.Destroy()
        SafeDestroy(Win)
    end

    -- ── AddTab ───────────────────────────────────────────────
    function WindowObj.AddTab(tabConfig)
        tabConfig    = tabConfig or {}
        local tName  = tabConfig.Name or ("Tab " .. (#tabs + 1))
        local tIcon  = tabConfig.Icon

        tabOrder = tabOrder + 1
        local order = tabOrder

        -- Sidebar button
        local TBtn = Instance.new("TextButton")
        TBtn.Text            = ""
        TBtn.BackgroundColor3 = T.Surface
        TBtn.BorderSizePixel = 0
        TBtn.Size            = UDim2.new(1,0,0,34)
        TBtn.AutoButtonColor = false
        TBtn.LayoutOrder     = order
        TBtn.Parent          = TabBar

        local tbtnc = Instance.new("UICorner"); tbtnc.CornerRadius = UDim.new(0,7); tbtnc.Parent = TBtn
        local tbtnl = Instance.new("UIListLayout")
        tbtnl.FillDirection = Enum.FillDirection.Horizontal
        tbtnl.VerticalAlignment = Enum.VerticalAlignment.Center
        tbtnl.Padding = UDim.new(0,6); tbtnl.Parent = TBtn
        local tbtnp = Instance.new("UIPadding"); tbtnp.PaddingLeft = UDim.new(0,9); tbtnp.Parent = TBtn

        if tIcon then
            local ico = Instance.new("ImageLabel")
            ico.Size = UDim2.new(0,16,0,16); ico.BackgroundTransparency = 1
            ico.Image = tIcon; ico.ImageColor3 = T.TextMuted; ico.Parent = TBtn
        end

        local TBLabel = Instance.new("TextLabel")
        TBLabel.Text = tName; TBLabel.Font = Enum.Font.Gotham; TBLabel.TextSize = 12
        TBLabel.TextColor3 = T.TextMuted; TBLabel.BackgroundTransparency = 1
        TBLabel.Size = UDim2.new(1,-30,1,0); TBLabel.TextXAlignment = Enum.TextXAlignment.Left
        TBLabel.Parent = TBtn

        -- Scroll frame for content
        local TFrame = Instance.new("ScrollingFrame")
        TFrame.Name                = "TabFrame_" .. tName
        TFrame.Size                = UDim2.new(1,0,1,0)
        TFrame.BackgroundTransparency = 1
        TFrame.BorderSizePixel     = 0
        TFrame.ScrollBarThickness  = 3
        TFrame.ScrollBarImageColor3 = T.Accent
        TFrame.CanvasSize          = UDim2.new(0,0,0,0)
        TFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TFrame.Visible             = false
        TFrame.Parent              = ContentArea

        local tfl = Instance.new("UIListLayout")
        tfl.SortOrder  = Enum.SortOrder.LayoutOrder
        tfl.Padding    = UDim.new(0,6)
        tfl.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tfl.Parent     = TFrame

        local tfp = Instance.new("UIPadding")
        tfp.PaddingTop = UDim.new(0,10); tfp.PaddingBottom = UDim.new(0,10)
        tfp.PaddingLeft = UDim.new(0,10); tfp.PaddingRight = UDim.new(0,13)
        tfp.Parent = TFrame

        -- Tab object
        local TabObj   = {}
        local elemOrder = 0

        local function nextOrder()
            elemOrder = elemOrder + 1
            return elemOrder
        end

        -- Activate logic
        local function activateTab(tab)
            for _, t in ipairs(tabs) do
                t._frame.Visible    = false
                t._btn.BackgroundColor3 = T.Surface
                t._lbl.TextColor3   = T.TextMuted
                t._lbl.Font         = Enum.Font.Gotham
            end
            tab._frame.Visible      = true
            tab._btn.BackgroundColor3 = T.Accent
            tab._lbl.TextColor3     = T.White
            tab._lbl.Font           = Enum.Font.GothamBold
            activeTab               = tab
        end

        TabObj._frame = TFrame
        TabObj._btn   = TBtn
        TabObj._lbl   = TBLabel
        table.insert(tabs, TabObj)

        TBtn.MouseButton1Click:Connect(function() activateTab(TabObj) end)
        TBtn.MouseEnter:Connect(function()
            if activeTab ~= TabObj then Tween(TBtn,{BackgroundColor3=T.SurfaceHover},0.1) end
        end)
        TBtn.MouseLeave:Connect(function()
            if activeTab ~= TabObj then Tween(TBtn,{BackgroundColor3=T.Surface},0.1) end
        end)

        if #tabs == 1 then activateTab(TabObj) end

        -- ── AddSection ───────────────────────────────────────
        function TabObj.AddSection(cfg)
            cfg = cfg or {}
            local lbl = Instance.new("TextLabel")
            lbl.Text = string.upper(cfg.Name or "Section")
            lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 9
            lbl.TextColor3 = T.TextMuted; lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.BackgroundTransparency = 1
            lbl.Size = UDim2.new(1,0,0,18); lbl.LayoutOrder = nextOrder(); lbl.Parent = TFrame

            local ul = Instance.new("Frame")
            ul.Size = UDim2.new(1,0,0,1); ul.Position = UDim2.new(0,0,1,-1)
            ul.BackgroundColor3 = T.Border; ul.BorderSizePixel = 0; ul.Parent = lbl

            local S = {}
            function S.Destroy() SafeDestroy(lbl) end
            return S
        end

        -- ── AddDivider ───────────────────────────────────────
        function TabObj.AddDivider()
            local d = Instance.new("Frame")
            d.Size = UDim2.new(1,0,0,1); d.BackgroundColor3 = T.Border
            d.BorderSizePixel = 0; d.LayoutOrder = nextOrder(); d.Parent = TFrame
        end

        -- ── AddLabel ─────────────────────────────────────────
        function TabObj.AddLabel(cfg)
            cfg = cfg or {}
            local lbl = Instance.new("TextLabel")
            lbl.Text = cfg.Text or "Label"
            lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
            lbl.TextColor3 = T.TextSecondary; lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.BackgroundColor3 = T.SectionBg; lbl.BorderSizePixel = 0
            lbl.Size = UDim2.new(1,0,0,0); lbl.AutomaticSize = Enum.AutomaticSize.Y
            lbl.TextWrapped = true; lbl.LayoutOrder = nextOrder(); lbl.Parent = TFrame

            local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0,6); lc.Parent = lbl
            local lp = Instance.new("UIPadding")
            lp.PaddingLeft = UDim.new(0,10); lp.PaddingRight = UDim.new(0,10)
            lp.PaddingTop  = UDim.new(0,8);  lp.PaddingBottom = UDim.new(0,8); lp.Parent = lbl

            local L = { _lbl = lbl }
            function L.Set(t) lbl.Text = tostring(t) end
            function L.Destroy() SafeDestroy(lbl) end
            return L
        end

        -- ── AddToggle ────────────────────────────────────────
        function TabObj.AddToggle(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Toggle"
            local default  = cfg.Default  or false
            local tooltip  = cfg.Tooltip  or ""
            local callback = cfg.Callback or function() end
            local state    = default

            local row = Instance.new("Frame")
            row.BackgroundColor3 = T.SectionBg; row.BorderSizePixel = 0
            row.Size = UDim2.new(1,0,0,42); row.LayoutOrder = nextOrder(); row.Parent = TFrame
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,7); rc.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = name; nameLbl.Font = Enum.Font.Gotham; nameLbl.TextSize = 13
            nameLbl.TextColor3 = T.TextPrimary; nameLbl.BackgroundTransparency = 1
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Size = UDim2.new(1,-70,1,0); nameLbl.Position = UDim2.new(0,12,0,0)
            nameLbl.Parent = row

            if tooltip ~= "" then
                local tipLbl = Instance.new("TextLabel")
                tipLbl.Text = tooltip; tipLbl.Font = Enum.Font.Gotham; tipLbl.TextSize = 10
                tipLbl.TextColor3 = T.TextMuted; tipLbl.BackgroundTransparency = 1
                tipLbl.TextXAlignment = Enum.TextXAlignment.Left
                tipLbl.Size = UDim2.new(1,-70,0,14); tipLbl.Position = UDim2.new(0,12,1,-18)
                tipLbl.Parent = row
                nameLbl.Position = UDim2.new(0,12,0,6); nameLbl.Size = UDim2.new(1,-70,0,18)
            end

            -- Track
            local track = Instance.new("Frame")
            track.Size = UDim2.new(0,40,0,22); track.Position = UDim2.new(1,-52,0.5,-11)
            track.BackgroundColor3 = state and T.ToggleOn or T.ToggleOff
            track.BorderSizePixel = 0; track.Parent = row
            local trc = Instance.new("UICorner"); trc.CornerRadius = UDim.new(1,0); trc.Parent = track

            -- Knob
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0,16,0,16)
            knob.Position = state and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)
            knob.BackgroundColor3 = T.White; knob.BorderSizePixel = 0; knob.Parent = track
            local knc = Instance.new("UICorner"); knc.CornerRadius = UDim.new(1,0); knc.Parent = knob

            local TogObj = { _value = state }

            local function apply(val, silent)
                state = val; TogObj._value = val
                Tween(track, { BackgroundColor3 = val and T.ToggleOn or T.ToggleOff }, 0.2)
                Tween(knob,  { Position = val and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8) }, 0.2)
                if not silent then pcall(callback, val) end
            end

            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1; hit.Size = UDim2.new(1,0,1,0)
            hit.Text = ""; hit.AutoButtonColor = false; hit.Parent = row
            hit.MouseEnter:Connect(function() Tween(row,{BackgroundColor3=T.SurfaceHover},0.1) end)
            hit.MouseLeave:Connect(function() Tween(row,{BackgroundColor3=T.SectionBg},0.1) end)
            hit.MouseButton1Click:Connect(function() apply(not state) end)

            function TogObj.Set(v) apply(v, true) end
            function TogObj.Get() return state end
            function TogObj.Destroy() SafeDestroy(row) end
            return TogObj
        end

        -- ── AddButton ────────────────────────────────────────
        function TabObj.AddButton(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Button"
            local desc     = cfg.Desc     or ""
            local style    = cfg.Style    or "Default"
            local callback = cfg.Callback or function() end

            local btnColor = T.Accent
            if style == "Danger"  then btnColor = T.Danger  end
            if style == "Success" then btnColor = T.Success end

            local row = Instance.new("Frame")
            row.BackgroundColor3 = T.SectionBg; row.BorderSizePixel = 0
            row.Size = UDim2.new(1,0,0, desc ~= "" and 48 or 38)
            row.LayoutOrder = nextOrder(); row.Parent = TFrame
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,7); rc.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = name; nameLbl.Font = Enum.Font.Gotham; nameLbl.TextSize = 13
            nameLbl.TextColor3 = T.TextPrimary; nameLbl.BackgroundTransparency = 1
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Size = UDim2.new(1,-110,0,18)
            nameLbl.Position = desc ~= "" and UDim2.new(0,12,0,8) or UDim2.new(0,12,0,0)
            if desc == "" then nameLbl.Size = UDim2.new(1,-110,1,0) end
            nameLbl.Parent = row

            if desc ~= "" then
                local descLbl = Instance.new("TextLabel")
                descLbl.Text = desc; descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = 10
                descLbl.TextColor3 = T.TextMuted; descLbl.BackgroundTransparency = 1
                descLbl.TextXAlignment = Enum.TextXAlignment.Left
                descLbl.Size = UDim2.new(1,-110,0,14); descLbl.Position = UDim2.new(0,12,0,28)
                descLbl.Parent = row
            end

            local btn = Instance.new("TextButton")
            btn.Text = "Run"; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12
            btn.TextColor3 = T.White; btn.BackgroundColor3 = btnColor
            btn.BorderSizePixel = 0; btn.AutoButtonColor = false
            btn.Size = UDim2.new(0,90,0,28); btn.Position = UDim2.new(1,-100,0.5,-14)
            btn.Parent = row
            local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = btn

            local hoverC = style == "Default" and T.AccentHover or btnColor
            btn.MouseEnter:Connect(function() Tween(btn,{BackgroundColor3=hoverC},0.12) end)
            btn.MouseLeave:Connect(function() Tween(btn,{BackgroundColor3=btnColor},0.12) end)
            btn.MouseButton1Down:Connect(function() Tween(btn,{Size=UDim2.new(0,86,0,26)},0.08) end)
            btn.MouseButton1Up:Connect(function() Tween(btn,{Size=UDim2.new(0,90,0,28)},0.12) end)
            btn.MouseButton1Click:Connect(function() pcall(callback) end)

            local B = {}
            function B.Destroy() SafeDestroy(row) end
            return B
        end

        -- ── AddInput ─────────────────────────────────────────
        function TabObj.AddInput(cfg)
            cfg = cfg or {}
            local name     = cfg.Name        or "Input"
            local ph       = cfg.Placeholder or "Enter value..."
            local default  = cfg.Default     or ""
            local numeric  = cfg.Numeric     or false
            local callback = cfg.Callback    or function() end

            local row = Instance.new("Frame")
            row.BackgroundColor3 = T.SectionBg; row.BorderSizePixel = 0
            row.Size = UDim2.new(1,0,0,58); row.LayoutOrder = nextOrder(); row.Parent = TFrame
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,7); rc.Parent = row

            local nlbl = Instance.new("TextLabel")
            nlbl.Text = name; nlbl.Font = Enum.Font.Gotham; nlbl.TextSize = 12
            nlbl.TextColor3 = T.TextSecondary; nlbl.BackgroundTransparency = 1
            nlbl.TextXAlignment = Enum.TextXAlignment.Left
            nlbl.Size = UDim2.new(1,-24,0,16); nlbl.Position = UDim2.new(0,12,0,8)
            nlbl.Parent = row

            local ibg = Instance.new("Frame")
            ibg.BackgroundColor3 = T.InputBg; ibg.BorderSizePixel = 0
            ibg.Size = UDim2.new(1,-24,0,26); ibg.Position = UDim2.new(0,12,0,26); ibg.Parent = row
            local ibc = Instance.new("UICorner"); ibc.CornerRadius = UDim.new(0,5); ibc.Parent = ibg
            local ibs = Instance.new("UIStroke"); ibs.Color = T.Border; ibs.Thickness = 1; ibs.Parent = ibg

            local box = Instance.new("TextBox")
            box.Text = default; box.PlaceholderText = ph
            box.Font = Enum.Font.Gotham; box.TextSize = 11
            box.TextColor3 = T.TextPrimary; box.PlaceholderColor3 = T.TextMuted
            box.TextXAlignment = Enum.TextXAlignment.Left
            box.BackgroundTransparency = 1; box.ClearTextOnFocus = false
            box.Size = UDim2.new(1,-16,1,0); box.Position = UDim2.new(0,8,0,0)
            box.Parent = ibg

            box.Focused:Connect(function() Tween(ibs,{Color=T.Accent},0.15) end)
            box.FocusLost:Connect(function(enter)
                Tween(ibs,{Color=T.Border},0.15)
                if numeric then
                    local n = tonumber(box.Text)
                    box.Text = n and tostring(n) or default
                end
                pcall(callback, box.Text, enter)
            end)

            local I = { _box = box }
            function I.Get() return box.Text end
            function I.Set(v) box.Text = tostring(v) end
            function I.Destroy() SafeDestroy(row) end
            return I
        end

        -- ── AddSlider ────────────────────────────────────────
        function TabObj.AddSlider(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Slider"
            local min      = cfg.Min      or 0
            local max      = cfg.Max      or 100
            local default  = cfg.Default  or min
            local decimals = cfg.Decimals or 0
            local suffix   = cfg.Suffix   or ""
            local callback = cfg.Callback or function() end
            local value    = Clamp(default, min, max)

            local row = Instance.new("Frame")
            row.BackgroundColor3 = T.SectionBg; row.BorderSizePixel = 0
            row.Size = UDim2.new(1,0,0,56); row.LayoutOrder = nextOrder(); row.Parent = TFrame
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,7); rc.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = name; nameLbl.Font = Enum.Font.Gotham; nameLbl.TextSize = 13
            nameLbl.TextColor3 = T.TextPrimary; nameLbl.BackgroundTransparency = 1
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Size = UDim2.new(0.65,0,0,18); nameLbl.Position = UDim2.new(0,12,0,8)
            nameLbl.Parent = row

            local valLbl = Instance.new("TextLabel")
            valLbl.Text = Round(value,decimals)..suffix; valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 12
            valLbl.TextColor3 = T.Accent; valLbl.BackgroundTransparency = 1
            valLbl.TextXAlignment = Enum.TextXAlignment.Right
            valLbl.Size = UDim2.new(0.35,-12,0,18); valLbl.Position = UDim2.new(0.65,0,0,8)
            valLbl.Parent = row

            local track = Instance.new("Frame")
            track.BackgroundColor3 = T.SliderTrack; track.BorderSizePixel = 0
            track.Size = UDim2.new(1,-24,0,5); track.Position = UDim2.new(0,12,0,36)
            track.Parent = row
            local trc = Instance.new("UICorner"); trc.CornerRadius = UDim.new(1,0); trc.Parent = track

            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = T.Accent; fill.BorderSizePixel = 0
            fill.Size = UDim2.new((value-min)/(max-min),0,1,0); fill.Parent = track
            local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1,0); fc.Parent = fill

            local thumb = Instance.new("Frame")
            thumb.Size = UDim2.new(0,14,0,14); thumb.AnchorPoint = Vector2.new(0.5,0.5)
            thumb.Position = UDim2.new((value-min)/(max-min),0,0.5,0)
            thumb.BackgroundColor3 = T.White; thumb.BorderSizePixel = 0; thumb.ZIndex = 5
            thumb.Parent = track
            local thc = Instance.new("UICorner"); thc.CornerRadius = UDim.new(1,0); thc.Parent = thumb
            local ths = Instance.new("UIStroke"); ths.Color = T.Accent; ths.Thickness = 2; ths.Parent = thumb

            local dragging = false

            local function updateFromMouse()
                local tx    = track.AbsolutePosition.X
                local tw    = track.AbsoluteSize.X
                local mx    = UserInputService:GetMouseLocation().X
                local pct   = Clamp((mx-tx)/tw,0,1)
                value       = Round(min + pct*(max-min), decimals)
                local fpct  = (value-min)/(max-min)
                fill.Size   = UDim2.new(fpct,0,1,0)
                thumb.Position = UDim2.new(fpct,0,0.5,0)
                valLbl.Text = Round(value,decimals)..suffix
                pcall(callback, value)
            end

            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1; hit.Size = UDim2.new(1,0,0,28)
            hit.Position = UDim2.new(0,0,0,24); hit.Text = ""; hit.AutoButtonColor = false
            hit.ZIndex = 10; hit.Parent = row
            hit.MouseButton1Down:Connect(function() dragging = true; updateFromMouse() end)
            UserInputService.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            RunService.Heartbeat:Connect(function()
                if dragging then updateFromMouse() end
            end)

            local S = { _value = value }
            function S.Set(v)
                value = Round(Clamp(v,min,max),decimals)
                local p = (value-min)/(max-min)
                fill.Size = UDim2.new(p,0,1,0); thumb.Position = UDim2.new(p,0,0.5,0)
                valLbl.Text = Round(value,decimals)..suffix
            end
            function S.Get() return value end
            function S.Destroy() SafeDestroy(row) end
            return S
        end

        -- ── AddDropdown ──────────────────────────────────────
        function TabObj.AddDropdown(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Dropdown"
            local options  = cfg.Options  or {}
            local default  = cfg.Default  or options[1]
            local callback = cfg.Callback or function() end
            local selected = default
            local open     = false

            local row = Instance.new("Frame")
            row.BackgroundColor3 = T.SectionBg; row.BorderSizePixel = 0
            row.Size = UDim2.new(1,0,0,42); row.LayoutOrder = nextOrder()
            row.ClipsDescendants = false; row.ZIndex = 10; row.Parent = TFrame
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,7); rc.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = name; nameLbl.Font = Enum.Font.Gotham; nameLbl.TextSize = 13
            nameLbl.TextColor3 = T.TextPrimary; nameLbl.BackgroundTransparency = 1
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Size = UDim2.new(0.55,0,1,0); nameLbl.Position = UDim2.new(0,12,0,0)
            nameLbl.Parent = row

            local selBg = Instance.new("Frame")
            selBg.BackgroundColor3 = T.InputBg; selBg.BorderSizePixel = 0
            selBg.Size = UDim2.new(0,140,0,28); selBg.Position = UDim2.new(1,-152,0.5,-14)
            selBg.Parent = row
            local sbc = Instance.new("UICorner"); sbc.CornerRadius = UDim.new(0,5); sbc.Parent = selBg
            local sbs = Instance.new("UIStroke"); sbs.Color = T.Border; sbs.Thickness = 1; sbs.Parent = selBg

            local selLbl = Instance.new("TextLabel")
            selLbl.Text = tostring(selected or "Select...")
            selLbl.Font = Enum.Font.Gotham; selLbl.TextSize = 11
            selLbl.TextColor3 = selected and T.TextPrimary or T.TextMuted
            selLbl.BackgroundTransparency = 1; selLbl.TextXAlignment = Enum.TextXAlignment.Left
            selLbl.Size = UDim2.new(1,-28,1,0); selLbl.Position = UDim2.new(0,8,0,0)
            selLbl.Parent = selBg

            local arrow = Instance.new("TextLabel")
            arrow.Text = "▾"; arrow.Font = Enum.Font.GothamBold; arrow.TextSize = 10
            arrow.TextColor3 = T.TextMuted; arrow.BackgroundTransparency = 1
            arrow.Size = UDim2.new(0,20,1,0); arrow.Position = UDim2.new(1,-22,0,0)
            arrow.TextXAlignment = Enum.TextXAlignment.Center; arrow.Parent = selBg

            local menu = Instance.new("Frame")
            menu.BackgroundColor3 = T.Surface; menu.BorderSizePixel = 0
            menu.Size = UDim2.new(0,140,0,0); menu.Position = UDim2.new(1,-152,1,4)
            menu.Visible = false; menu.ClipsDescendants = true; menu.ZIndex = 50; menu.Parent = row
            local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0,7); mc.Parent = menu
            local ms = Instance.new("UIStroke"); ms.Color = T.Border; ms.Thickness = 1; ms.Parent = menu
            local ml = Instance.new("UIListLayout"); ml.SortOrder = Enum.SortOrder.LayoutOrder; ml.Padding = UDim.new(0,2); ml.Parent = menu
            local mp = Instance.new("UIPadding")
            mp.PaddingTop = UDim.new(0,4); mp.PaddingBottom = UDim.new(0,4)
            mp.PaddingLeft = UDim.new(0,4); mp.PaddingRight = UDim.new(0,4); mp.Parent = menu

            local DropObj = { _value = selected }

            local function buildOptions(opts)
                for _, c in ipairs(menu:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for i, opt in ipairs(opts) do
                    local ob = Instance.new("TextButton")
                    ob.Text = tostring(opt); ob.Font = Enum.Font.Gotham; ob.TextSize = 11
                    ob.TextColor3 = (opt == selected) and T.Accent or T.TextPrimary
                    ob.BackgroundColor3 = T.Surface; ob.BorderSizePixel = 0; ob.AutoButtonColor = false
                    ob.Size = UDim2.new(1,0,0,26); ob.LayoutOrder = i; ob.ZIndex = 55; ob.Parent = menu
                    local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0,5); oc.Parent = ob
                    local op = Instance.new("UIPadding"); op.PaddingLeft = UDim.new(0,8); op.Parent = ob

                    ob.MouseEnter:Connect(function() Tween(ob,{BackgroundColor3=T.SurfaceHover},0.1) end)
                    ob.MouseLeave:Connect(function() Tween(ob,{BackgroundColor3=T.Surface},0.1) end)
                    ob.MouseButton1Click:Connect(function()
                        selected = opt; DropObj._value = opt
                        selLbl.Text = tostring(opt); selLbl.TextColor3 = T.TextPrimary
                        open = false
                        Tween(menu,{Size=UDim2.new(0,140,0,0)},0.15); Tween(arrow,{Rotation=0},0.15)
                        task.wait(0.15); menu.Visible = false
                        for _, b in ipairs(menu:GetChildren()) do
                            if b:IsA("TextButton") then b.TextColor3 = b.Text == tostring(opt) and T.Accent or T.TextPrimary end
                        end
                        pcall(callback, opt)
                    end)
                end
            end

            buildOptions(options)

            local hit = Instance.new("TextButton")
            hit.BackgroundTransparency = 1; hit.Size = UDim2.new(1,0,1,0)
            hit.Text = ""; hit.AutoButtonColor = false; hit.ZIndex = 15; hit.Parent = selBg
            hit.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    local count = 0
                    for _, c in ipairs(menu:GetChildren()) do if c:IsA("TextButton") then count += 1 end end
                    menu.Visible = true
                    Tween(menu,{Size=UDim2.new(0,140,0,math.min(count*28+8,150))},0.2)
                    Tween(arrow,{Rotation=180},0.2)
                else
                    Tween(menu,{Size=UDim2.new(0,140,0,0)},0.15); Tween(arrow,{Rotation=0},0.15)
                    task.delay(0.15, function() menu.Visible = false end)
                end
            end)

            function DropObj.Set(v)
                selected = v; DropObj._value = v
                selLbl.Text = tostring(v); selLbl.TextColor3 = T.TextPrimary
                pcall(callback, v)
            end
            function DropObj.Refresh(newOpts, keep)
                options = newOpts
                if not keep then selected = newOpts[1]; DropObj._value = selected; selLbl.Text = tostring(selected or "Select...") end
                buildOptions(newOpts)
            end
            function DropObj.Get() return selected end
            function DropObj.Destroy() SafeDestroy(row) end
            return DropObj
        end

        -- ── AddKeybind ───────────────────────────────────────
        function TabObj.AddKeybind(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Keybind"
            local default  = cfg.Default  or Enum.KeyCode.Unknown
            local callback = cfg.Callback or function() end
            local curKey   = default
            local binding  = false

            local row = Instance.new("Frame")
            row.BackgroundColor3 = T.SectionBg; row.BorderSizePixel = 0
            row.Size = UDim2.new(1,0,0,42); row.LayoutOrder = nextOrder(); row.Parent = TFrame
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,7); rc.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = name; nameLbl.Font = Enum.Font.Gotham; nameLbl.TextSize = 13
            nameLbl.TextColor3 = T.TextPrimary; nameLbl.BackgroundTransparency = 1
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Size = UDim2.new(0.65,0,1,0); nameLbl.Position = UDim2.new(0,12,0,0)
            nameLbl.Parent = row

            local keyBtn = Instance.new("TextButton")
            keyBtn.Text = curKey == Enum.KeyCode.Unknown and "None" or curKey.Name
            keyBtn.Font = Enum.Font.GothamBold; keyBtn.TextSize = 11
            keyBtn.TextColor3 = T.Accent; keyBtn.BackgroundColor3 = T.AccentDim
            keyBtn.BorderSizePixel = 0; keyBtn.AutoButtonColor = false
            keyBtn.Size = UDim2.new(0,80,0,26); keyBtn.Position = UDim2.new(1,-92,0.5,-13)
            keyBtn.Parent = row
            local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(0,5); kc.Parent = keyBtn

            keyBtn.MouseButton1Click:Connect(function()
                binding = true; keyBtn.Text = "..."; keyBtn.TextColor3 = T.TextMuted
            end)
            UserInputService.InputBegan:Connect(function(input, gp)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding = false; curKey = input.KeyCode
                    keyBtn.Text = curKey.Name; keyBtn.TextColor3 = T.Accent
                    pcall(callback, curKey)
                elseif not gp and input.KeyCode == curKey then
                    pcall(callback, curKey)
                end
            end)

            local K = { _value = curKey }
            function K.Set(k) curKey = k; K._value = k; keyBtn.Text = k.Name end
            function K.Get() return curKey end
            function K.Destroy() SafeDestroy(row) end
            return K
        end

        -- ── AddColorPicker ───────────────────────────────────
        function TabObj.AddColorPicker(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Color"
            local default  = cfg.Default  or Color3.fromRGB(99, 102, 241)
            local callback = cfg.Callback or function() end
            local cur      = default
            local open     = false

            local row = Instance.new("Frame")
            row.BackgroundColor3 = T.SectionBg; row.BorderSizePixel = 0
            row.Size = UDim2.new(1,0,0,42); row.LayoutOrder = nextOrder()
            row.ClipsDescendants = false; row.Parent = TFrame
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,7); rc.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Text = name; nameLbl.Font = Enum.Font.Gotham; nameLbl.TextSize = 13
            nameLbl.TextColor3 = T.TextPrimary; nameLbl.BackgroundTransparency = 1
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Size = UDim2.new(0.6,0,1,0); nameLbl.Position = UDim2.new(0,12,0,0)
            nameLbl.Parent = row

            local hexLbl = Instance.new("TextLabel")
            hexLbl.Text = ToHex(cur); hexLbl.Font = Enum.Font.RobotoMono; hexLbl.TextSize = 11
            hexLbl.TextColor3 = T.TextSecondary; hexLbl.BackgroundTransparency = 1
            hexLbl.TextXAlignment = Enum.TextXAlignment.Right
            hexLbl.Size = UDim2.new(0,70,1,0); hexLbl.Position = UDim2.new(1,-112,0,0)
            hexLbl.Parent = row

            local swatch = Instance.new("TextButton")
            swatch.Text = ""; swatch.BackgroundColor3 = cur; swatch.BorderSizePixel = 0
            swatch.AutoButtonColor = false
            swatch.Size = UDim2.new(0,28,0,28); swatch.Position = UDim2.new(1,-40,0.5,-14)
            swatch.Parent = row
            local swc = Instance.new("UICorner"); swc.CornerRadius = UDim.new(0,6); swc.Parent = swatch
            local sws = Instance.new("UIStroke"); sws.Color = T.Border; sws.Thickness = 1; sws.Parent = swatch

            local panel = Instance.new("Frame")
            panel.BackgroundColor3 = T.Surface; panel.BorderSizePixel = 0
            panel.Size = UDim2.new(1,0,0,0); panel.Position = UDim2.new(0,0,1,4)
            panel.Visible = false; panel.ClipsDescendants = true; panel.ZIndex = 20; panel.Parent = row
            local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,7); pc.Parent = panel
            local ps = Instance.new("UIStroke"); ps.Color = T.Border; ps.Thickness = 1; ps.Parent = panel

            local rComp, gComp, bComp = cur.R, cur.G, cur.B

            local function applyColor()
                cur = Color3.new(rComp, gComp, bComp)
                swatch.BackgroundColor3 = cur; hexLbl.Text = ToHex(cur)
                pcall(callback, cur)
            end

            local function makeChannel(label, yPos, getComp, setComp)
                local lbl = Instance.new("TextLabel")
                lbl.Text = label; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
                lbl.TextColor3 = T.TextMuted; lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(0,42,0,15); lbl.Position = UDim2.new(0,8,0,yPos-1)
                lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 22; lbl.Parent = panel

                local trk = Instance.new("Frame")
                trk.BackgroundColor3 = T.SliderTrack; trk.BorderSizePixel = 0
                trk.Size = UDim2.new(1,-80,0,5); trk.Position = UDim2.new(0,50,0,yPos+5)
                trk.ZIndex = 22; trk.Parent = panel
                local tc2 = Instance.new("UICorner"); tc2.CornerRadius = UDim.new(1,0); tc2.Parent = trk

                local fil = Instance.new("Frame")
                fil.BackgroundColor3 = T.Accent; fil.BorderSizePixel = 0
                fil.Size = UDim2.new(getComp(),0,1,0); fil.ZIndex = 23; fil.Parent = trk
                local fc2 = Instance.new("UICorner"); fc2.CornerRadius = UDim.new(1,0); fc2.Parent = fil

                local vl = Instance.new("TextLabel")
                vl.Text = tostring(math.floor(getComp()*255)); vl.Font = Enum.Font.GothamBold; vl.TextSize = 10
                vl.TextColor3 = T.TextSecondary; vl.BackgroundTransparency = 1
                vl.Size = UDim2.new(0,28,0,15); vl.Position = UDim2.new(1,-36,0,yPos-1)
                vl.TextXAlignment = Enum.TextXAlignment.Right; vl.ZIndex = 22; vl.Parent = panel

                local drag = false
                local dHit = Instance.new("TextButton")
                dHit.BackgroundTransparency=1; dHit.Size=UDim2.new(1,0,0,20)
                dHit.Position=UDim2.new(0,0,0,-7); dHit.Text=""; dHit.ZIndex=30; dHit.Parent=trk
                dHit.MouseButton1Down:Connect(function() drag=true end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
                end)
                RunService.Heartbeat:Connect(function()
                    if drag then
                        local pct = Clamp((UserInputService:GetMouseLocation().X - trk.AbsolutePosition.X) / trk.AbsoluteSize.X, 0, 1)
                        setComp(pct)
                        fil.Size = UDim2.new(pct,0,1,0)
                        vl.Text  = tostring(math.floor(pct*255))
                        applyColor()
                    end
                end)
            end

            makeChannel("R", 8,  function() return rComp end, function(v) rComp = v end)
            makeChannel("G", 26, function() return gComp end, function(v) gComp = v end)
            makeChannel("B", 44, function() return bComp end, function(v) bComp = v end)

            swatch.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    panel.Visible = true
                    Tween(panel,{Size=UDim2.new(1,0,0,76)},0.2)
                else
                    Tween(panel,{Size=UDim2.new(1,0,0,0)},0.15)
                    task.delay(0.15, function() panel.Visible = false end)
                end
            end)

            local CP = { _value = cur }
            function CP.Set(c)
                cur = c; rComp = c.R; gComp = c.G; bComp = c.B; applyColor()
            end
            function CP.Get() return cur end
            function CP.Destroy() SafeDestroy(row) end
            return CP
        end

        return TabObj
    end -- AddTab

    return WindowObj
end -- CreateWindow

-- ============================================================
--  RETURN
-- ============================================================

return NexUI
