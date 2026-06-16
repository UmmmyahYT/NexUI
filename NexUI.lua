--[[
    ███╗   ██╗███████╗██╗  ██╗██╗   ██╗██╗
    ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██║
    ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║██║
    ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║██║
    ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝██║
    ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝

    NexUI v1.0 — Roblox Script Menu Framework
    A loadstring-compatible UI library for building clean, tabbed script menus.

    USAGE:
        local NexUI = loadstring(game:HttpGet("YOUR_RAW_URL"))()
        local Window = NexUI:CreateWindow({ Title = "My Script", Subtitle = "v1.0" })
        local Tab = Window:AddTab({ Name = "Main", Icon = "rbxassetid://..." })
        Tab:AddToggle({ Name = "God Mode", Default = false, Callback = function(v) end })

    COMPONENTS:
        Window:AddTab(config)           → Tab
        Tab:AddSection(config)          → Section
        Tab:AddToggle(config)           → Toggle
        Tab:AddButton(config)           → Button
        Tab:AddInput(config)            → Input
        Tab:AddSlider(config)           → Slider
        Tab:AddDropdown(config)         → Dropdown
        Tab:AddColorPicker(config)      → ColorPicker
        Tab:AddKeybind(config)          → Keybind
        Tab:AddLabel(config)            → Label
        Tab:AddDivider()                → Divider

    ELEMENT METHODS:
        Toggle:Set(bool)                Set toggle state
        Slider:Set(number)              Set slider value
        Dropdown:Set(value)             Set selected option
        Dropdown:Refresh(options, keep) Refresh options list
        ColorPicker:Set(Color3)         Set color
        Keybind:Set(Enum.KeyCode)       Set keybind
        Label:Set(text)                 Update label text
        Element:Destroy()               Remove element
        Window:Destroy()                Destroy entire window

    NexUI:Notify(config)               Sends a notification toast

    LICENSE: Free to use. No attribution required.
--]]

-- ============================================================
--  SERVICES & UTILITIES
-- ============================================================

local NexUI = {}

local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local RunService      = game:GetService("RunService")
local TextService     = game:GetService("TextService")
local CoreGui         = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- Tween helper
local function Tween(instance, properties, duration, style, direction)
    style     = style     or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.2, style, direction)
    local t    = TweenService:Create(instance, info, properties)
    t:Play()
    return t
end

-- Safe destroy
local function SafeDestroy(obj)
    if obj and obj.Parent then
        obj:Destroy()
    end
end

-- Clamp
local function Clamp(v, min, max)
    return math.max(min, math.min(max, v))
end

-- Round
local function Round(n, dec)
    dec = dec or 0
    local m = 10 ^ dec
    return math.floor(n * m + 0.5) / m
end

-- Color3 to Hex
local function ToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255),
        math.floor(c.G * 255),
        math.floor(c.B * 255))
end

-- ============================================================
--  THEME
-- ============================================================

local Theme = {
    -- Window
    Background    = Color3.fromRGB(10,  10,  16),
    Surface       = Color3.fromRGB(16,  16,  26),
    SurfaceHover  = Color3.fromRGB(24,  24,  38),
    Border        = Color3.fromRGB(38,  38,  58),
    BorderActive  = Color3.fromRGB(99, 102, 241),

    -- Accent
    Accent        = Color3.fromRGB(99,  102, 241),
    AccentHover   = Color3.fromRGB(129, 132, 255),
    AccentDim     = Color3.fromRGB(30,  32,  80),
    AccentGlow    = Color3.fromRGB(60,  63, 180),

    -- Text
    TextPrimary   = Color3.fromRGB(235, 235, 255),
    TextSecondary = Color3.fromRGB(130, 130, 165),
    TextMuted     = Color3.fromRGB(65,  65, 100),
    TextDanger    = Color3.fromRGB(248, 113, 113),

    -- Components
    ToggleOff     = Color3.fromRGB(40,  40,  62),
    ToggleOn      = Color3.fromRGB(99,  102, 241),
    InputBg       = Color3.fromRGB(8,   8,   14),
    SliderFill    = Color3.fromRGB(99,  102, 241),
    SliderTrack   = Color3.fromRGB(28,  28,  44),
    SectionBg     = Color3.fromRGB(14,  14,  22),
    SidebarBg     = Color3.fromRGB(13,  13,  20),

    -- Misc
    White         = Color3.fromRGB(255, 255, 255),
    Danger        = Color3.fromRGB(239, 68,  68),
    Success       = Color3.fromRGB(34,  197, 94),
    Warning       = Color3.fromRGB(251, 191, 36),
}

-- ============================================================
--  GUI ROOT
-- ============================================================

-- Remove existing NexUI if reloaded
if CoreGui:FindFirstChild("NexUI_Root") then
    CoreGui:FindFirstChild("NexUI_Root"):Destroy()
end

local Root = Instance.new("ScreenGui")
Root.Name            = "NexUI_Root"
Root.ZIndexBehavior  = Enum.ZIndexBehavior.Global
Root.ResetOnSpawn    = false
Root.DisplayOrder    = 999

-- Try to parent to CoreGui, fallback to PlayerGui
local success = pcall(function() Root.Parent = CoreGui end)
if not success then
    Root.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Notification container (top-right)
local NotifContainer = Instance.new("Frame")
NotifContainer.Name             = "NotifContainer"
NotifContainer.BackgroundTransparency = 1
NotifContainer.Size             = UDim2.new(0, 280, 1, 0)
NotifContainer.Position         = UDim2.new(1, -290, 0, 0)
NotifContainer.AnchorPoint      = Vector2.new(0, 0)
NotifContainer.Parent           = Root

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.SortOrder           = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment   = Enum.VerticalAlignment.Bottom
NotifLayout.Padding             = UDim.new(0, 8)
NotifLayout.Parent              = NotifContainer

local NotifPadding = Instance.new("UIPadding")
NotifPadding.PaddingBottom      = UDim.new(0, 16)
NotifPadding.Parent             = NotifContainer

-- ============================================================
--  DRAGGING UTILITY
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
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
--  MAKE ELEMENT (shared wrapper)
-- ============================================================

local function MakeContainer(parent)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.Size  = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Parent = parent
    return f
end

-- ============================================================
--  NOTIFICATION
-- ============================================================

function NexUI:Notify(config)
    config = config or {}
    local title    = config.Title    or "Notice"
    local desc     = config.Content  or ""
    local duration = config.Duration or 3
    local ntype    = config.Type     or "Info" -- "Info", "Success", "Warning", "Error"

    local accentColor = Theme.Accent
    if ntype == "Success" then accentColor = Theme.Success
    elseif ntype == "Warning" then accentColor = Theme.Warning
    elseif ntype == "Error"   then accentColor = Theme.Danger
    end

    -- Notification frame
    local notif = Instance.new("Frame")
    notif.Name                = "Notification"
    notif.Size                = UDim2.new(1, 0, 0, 0)
    notif.AutomaticSize       = Enum.AutomaticSize.Y
    notif.BackgroundColor3    = Theme.Surface
    notif.BorderSizePixel     = 0
    notif.ClipsDescendants    = true
    notif.Parent              = NotifContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notif

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = notif

    -- Left accent bar
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = accentColor
    bar.BorderSizePixel  = 0
    bar.Parent           = notif
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 3)
    barCorner.Parent = bar

    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.Size   = UDim2.new(1, -16, 0, 0)
    inner.Position = UDim2.new(0, 12, 0, 0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.Parent = notif

    local innerPad = Instance.new("UIPadding")
    innerPad.PaddingTop    = UDim.new(0, 10)
    innerPad.PaddingBottom = UDim.new(0, 10)
    innerPad.Parent        = inner

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text              = title
    titleLabel.Font              = Enum.Font.GothamBold
    titleLabel.TextSize          = 13
    titleLabel.TextColor3        = Theme.TextPrimary
    titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size              = UDim2.new(1, 0, 0, 16)
    titleLabel.Parent            = inner

    if desc ~= "" then
        local descLabel = Instance.new("TextLabel")
        descLabel.Text              = desc
        descLabel.Font              = Enum.Font.Gotham
        descLabel.TextSize          = 11
        descLabel.TextColor3        = Theme.TextSecondary
        descLabel.TextXAlignment    = Enum.TextXAlignment.Left
        descLabel.BackgroundTransparency = 1
        descLabel.Size              = UDim2.new(1, 0, 0, 0)
        descLabel.AutomaticSize     = Enum.AutomaticSize.Y
        descLabel.TextWrapped       = true
        descLabel.Position          = UDim2.new(0, 0, 0, 20)
        descLabel.Parent            = inner
    end

    -- Progress bar
    local progress = Instance.new("Frame")
    progress.Size            = UDim2.new(1, 0, 0, 2)
    progress.Position        = UDim2.new(0, 0, 1, -2)
    progress.BackgroundColor3 = accentColor
    progress.BorderSizePixel = 0
    progress.Parent          = notif

    -- Animate in
    notif.BackgroundTransparency = 1
    Tween(notif, { BackgroundTransparency = 0 }, 0.2)

    task.spawn(function()
        Tween(progress, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)
        task.wait(duration)
        Tween(notif, { BackgroundTransparency = 1 }, 0.3)
        task.wait(0.35)
        SafeDestroy(notif)
    end)

    return notif
end

-- ============================================================
--  CREATE WINDOW
-- ============================================================

function NexUI:CreateWindow(config)
    config = config or {}
    local windowTitle    = config.Title    or "NexUI"
    local windowSubtitle = config.Subtitle or ""
    local size           = config.Size     or Vector2.new(560, 380)
    local position       = config.Position or UDim2.new(0.5, -size.X/2, 0.5, -size.Y/2)
    local minSize        = config.MinSize  or Vector2.new(420, 300)

    -- ── Main Window Frame ──────────────────────────────────────
    -- Start hidden + shifted down for open animation
    local Window = Instance.new("Frame")
    Window.Name              = "NexUI_Window"
    Window.Size              = UDim2.new(0, size.X, 0, size.Y)
    Window.Position          = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + 18)
    Window.BackgroundColor3  = Theme.Background
    Window.BackgroundTransparency = 1
    Window.BorderSizePixel   = 0
    Window.ClipsDescendants  = false
    Window.Parent            = Root

    local WCorner = Instance.new("UICorner")
    WCorner.CornerRadius = UDim.new(0, 12)
    WCorner.Parent = Window

    -- Outer glow border
    local WStroke = Instance.new("UIStroke")
    WStroke.Color     = Theme.AccentGlow
    WStroke.Thickness = 1.5
    WStroke.Transparency = 0.6
    WStroke.Parent    = Window

    -- ── Thin accent gradient line across very top ──────────────
    local TopBar = Instance.new("Frame")
    TopBar.Name             = "TopBar"
    TopBar.Size             = UDim2.new(1, 0, 0, 2)
    TopBar.Position         = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundColor3 = Theme.Accent
    TopBar.BorderSizePixel  = 0
    TopBar.ZIndex           = 10
    TopBar.Parent           = Window

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 12)
    TopBarCorner.Parent = TopBar

    -- Cover the bottom rounded part of the top bar (it only rounds top)
    local TopBarFill = Instance.new("Frame")
    TopBarFill.Size             = UDim2.new(1, 0, 0, 8)
    TopBarFill.Position         = UDim2.new(0, 0, 1, -6)
    TopBarFill.BackgroundColor3 = Theme.Accent
    TopBarFill.BorderSizePixel  = 0
    TopBarFill.ZIndex           = 10
    TopBarFill.Parent           = TopBar

    -- Shimmer element that sweeps across the top bar on open
    local Shimmer = Instance.new("Frame")
    Shimmer.Name             = "Shimmer"
    Shimmer.Size             = UDim2.new(0, 60, 1, 0)
    Shimmer.Position         = UDim2.new(-0.15, 0, 0, 0)
    Shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Shimmer.BackgroundTransparency = 0.6
    Shimmer.BorderSizePixel  = 0
    Shimmer.ZIndex           = 11
    Shimmer.ClipsDescendants = false
    Shimmer.Parent           = TopBar

    local ShimGrad = Instance.new("UIGradient")
    ShimGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    ShimGrad.Rotation = 0
    ShimGrad.Parent   = Shimmer

    -- ── Title Bar ─────────────────────────────────────────────
    local TitleBar = Instance.new("Frame")
    TitleBar.Name             = "TitleBar"
    TitleBar.Size             = UDim2.new(1, 0, 0, 50)
    TitleBar.Position         = UDim2.new(0, 0, 0, 2) -- sits below the 2px accent line
    TitleBar.BackgroundColor3 = Theme.Surface
    TitleBar.BorderSizePixel  = 0
    TitleBar.ZIndex           = 2
    TitleBar.Parent           = Window

    -- Square off the bottom of the titlebar
    local TitleFill = Instance.new("Frame")
    TitleFill.Size             = UDim2.new(1, 0, 0, 12)
    TitleFill.Position         = UDim2.new(0, 0, 1, -12)
    TitleFill.BackgroundColor3 = Theme.Surface
    TitleFill.BorderSizePixel  = 0
    TitleFill.ZIndex           = 2
    TitleFill.Parent           = TitleBar

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent       = TitleBar

    -- Subtle bottom border on titlebar
    local TitleBorder = Instance.new("Frame")
    TitleBorder.Size             = UDim2.new(1, -24, 0, 1)
    TitleBorder.Position         = UDim2.new(0, 12, 1, -1)
    TitleBorder.BackgroundColor3 = Theme.Border
    TitleBorder.BorderSizePixel  = 0
    TitleBorder.ZIndex           = 3
    TitleBorder.Parent           = TitleBar

    -- Title icon (small accent square with rounded corners)
    local TitleIcon = Instance.new("Frame")
    TitleIcon.Size             = UDim2.new(0, 20, 0, 20)
    TitleIcon.Position         = UDim2.new(0, 14, 0.5, -10)
    TitleIcon.BackgroundColor3 = Theme.Accent
    TitleIcon.BorderSizePixel  = 0
    TitleIcon.ZIndex           = 3
    TitleIcon.Parent           = TitleBar
    local TIc = Instance.new("UICorner"); TIc.CornerRadius = UDim.new(0, 5); TIc.Parent = TitleIcon
    -- Inner check/line on the icon
    local TILine = Instance.new("Frame")
    TILine.Size             = UDim2.new(0, 8, 0, 2)
    TILine.Position         = UDim2.new(0.5, -4, 0.5, -1)
    TILine.BackgroundColor3 = Theme.White
    TILine.BorderSizePixel  = 0
    TILine.ZIndex           = 4
    TILine.Parent           = TitleIcon
    local TILine2 = Instance.new("Frame")
    TILine2.Size             = UDim2.new(0, 2, 0, 8)
    TILine2.Position         = UDim2.new(0.5, -1, 0.5, -4)
    TILine2.BackgroundColor3 = Theme.White
    TILine2.BorderSizePixel  = 0
    TILine2.ZIndex           = 4
    TILine2.Parent           = TitleIcon

    -- Title text
    local TitleText = Instance.new("TextLabel")
    TitleText.Text           = windowTitle
    TitleText.Font           = Enum.Font.GothamBold
    TitleText.TextSize       = 14
    TitleText.TextColor3     = Theme.TextPrimary
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.BackgroundTransparency = 1
    TitleText.Size           = UDim2.new(0, 200, 1, 0)
    TitleText.Position       = UDim2.new(0, 42, 0, 0)
    TitleText.ZIndex         = 3
    TitleText.Parent         = TitleBar

    -- Subtitle pill
    if windowSubtitle ~= "" then
        local SubPill = Instance.new("Frame")
        SubPill.BackgroundColor3 = Theme.AccentDim
        SubPill.BorderSizePixel  = 0
        SubPill.Size             = UDim2.new(0, 0, 0, 20)
        SubPill.AutomaticSize    = Enum.AutomaticSize.X
        SubPill.Position         = UDim2.new(0, 42, 0.5, -10)
        SubPill.AnchorPoint      = Vector2.new(0, 0)
        SubPill.ZIndex           = 3
        SubPill.Parent           = TitleBar

        -- Position it after the title text (approx)
        SubPill.Position = UDim2.new(0, 42 + string.len(windowTitle) * 9, 0.5, -10)

        local SubPillCorner = Instance.new("UICorner")
        SubPillCorner.CornerRadius = UDim.new(1, 0)
        SubPillCorner.Parent = SubPill

        local SubPillPad = Instance.new("UIPadding")
        SubPillPad.PaddingLeft  = UDim.new(0, 8)
        SubPillPad.PaddingRight = UDim.new(0, 8)
        SubPillPad.Parent       = SubPill

        local SubText = Instance.new("TextLabel")
        SubText.Text             = windowSubtitle
        SubText.Font             = Enum.Font.GothamBold
        SubText.TextSize         = 10
        SubText.TextColor3       = Theme.Accent
        SubText.BackgroundTransparency = 1
        SubText.Size             = UDim2.new(1, 0, 1, 0)
        SubText.TextXAlignment   = Enum.TextXAlignment.Center
        SubText.ZIndex           = 4
        SubText.Parent           = SubPill
    end

    -- Window control buttons (close + minimize) — right side
    local function MakeControlBtn(symbol, xOffset)
        local btn = Instance.new("TextButton")
        btn.Text             = symbol
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 11
        btn.TextColor3       = Theme.TextMuted
        btn.BackgroundColor3 = Theme.SurfaceHover
        btn.BorderSizePixel  = 0
        btn.AutoButtonColor  = false
        btn.Size             = UDim2.new(0, 26, 0, 26)
        btn.Position         = UDim2.new(1, xOffset, 0.5, -13)
        btn.ZIndex           = 5
        btn.Parent           = TitleBar
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = btn
        return btn
    end

    local CloseBtn = MakeControlBtn("✕", -36)
    local MinBtn   = MakeControlBtn("─", -66)

    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, { BackgroundColor3 = Theme.Danger, TextColor3 = Theme.White }, 0.12)
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, { BackgroundColor3 = Theme.SurfaceHover, TextColor3 = Theme.TextMuted }, 0.12)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        -- Close animation: shrink + fade
        Tween(Window, { Size = UDim2.new(0, size.X, 0, 0), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Quint)
        task.wait(0.28)
        SafeDestroy(Window)
    end)

    MinBtn.MouseEnter:Connect(function()
        Tween(MinBtn, { BackgroundColor3 = Theme.AccentDim, TextColor3 = Theme.Accent }, 0.12)
    end)
    MinBtn.MouseLeave:Connect(function()
        Tween(MinBtn, { BackgroundColor3 = Theme.SurfaceHover, TextColor3 = Theme.TextMuted }, 0.12)
    end)

    local minimized = false
    local prevSize  = Window.Size
    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            prevSize = Window.Size
            Tween(Window, { Size = UDim2.new(0, size.X, 0, 52) }, 0.3, Enum.EasingStyle.Quint)
        else
            Tween(Window, { Size = prevSize }, 0.3, Enum.EasingStyle.Quint)
        end
    end)

    MakeDraggable(TitleBar, Window)

    -- ── Sidebar ───────────────────────────────────────────────
    local SidebarW = 148

    local Sidebar = Instance.new("Frame")
    Sidebar.Name              = "Sidebar"
    Sidebar.Size              = UDim2.new(0, SidebarW, 1, -52)
    Sidebar.Position          = UDim2.new(0, 0, 0, 52)
    Sidebar.BackgroundColor3  = Theme.SidebarBg
    Sidebar.BorderSizePixel   = 0
    Sidebar.ClipsDescendants  = true
    Sidebar.ZIndex            = 2
    Sidebar.Parent            = Window

    -- Square off the top-left
    local SidebarTopFill = Instance.new("Frame")
    SidebarTopFill.Size             = UDim2.new(1, 0, 0, 10)
    SidebarTopFill.BackgroundColor3 = Theme.SidebarBg
    SidebarTopFill.BorderSizePixel  = 0
    SidebarTopFill.ZIndex           = 2
    SidebarTopFill.Parent           = Sidebar

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 12)
    SidebarCorner.Parent = Sidebar

    -- Right edge border line on sidebar
    local SidebarBorder = Instance.new("Frame")
    SidebarBorder.Size             = UDim2.new(0, 1, 1, -52)
    SidebarBorder.Position         = UDim2.new(0, SidebarW, 0, 52)
    SidebarBorder.BackgroundColor3 = Theme.Border
    SidebarBorder.BorderSizePixel  = 0
    SidebarBorder.Parent           = Window

    -- Tab list inside sidebar
    local TabBar = Instance.new("Frame")
    TabBar.Name                    = "TabBar"
    TabBar.Size                    = UDim2.new(1, 0, 1, -80) -- leave room for watermark at bottom
    TabBar.BackgroundTransparency  = 1
    TabBar.BorderSizePixel         = 0
    TabBar.ClipsDescendants        = false
    TabBar.Parent                  = Sidebar

    local TabList = Instance.new("UIListLayout")
    TabList.SortOrder              = Enum.SortOrder.LayoutOrder
    TabList.FillDirection          = Enum.FillDirection.Vertical
    TabList.HorizontalAlignment    = Enum.HorizontalAlignment.Left
    TabList.Padding                = UDim.new(0, 3)
    TabList.Parent                 = TabBar

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingTop          = UDim.new(0, 10)
    TabPadding.PaddingLeft         = UDim.new(0, 8)
    TabPadding.PaddingRight        = UDim.new(0, 8)
    TabPadding.Parent              = TabBar

    -- ── Watermark at bottom of sidebar ────────────────────────
    local WatermarkFrame = Instance.new("Frame")
    WatermarkFrame.Size             = UDim2.new(0, SidebarW, 0, 72)
    WatermarkFrame.Position         = UDim2.new(0, 0, 1, -72)
    WatermarkFrame.BackgroundTransparency = 1
    WatermarkFrame.BorderSizePixel  = 0
    WatermarkFrame.ClipsDescendants = false
    WatermarkFrame.ZIndex           = 20
    WatermarkFrame.Parent           = Window  -- parented to Window, NOT Sidebar, so it is never clipped

    -- Fade line above watermark
    local WatermarkLine = Instance.new("Frame")
    WatermarkLine.Size             = UDim2.new(1, -20, 0, 1)
    WatermarkLine.Position         = UDim2.new(0, 10, 0, 0)
    WatermarkLine.BackgroundColor3 = Theme.Border
    WatermarkLine.BorderSizePixel  = 0
    WatermarkLine.ZIndex           = 20
    WatermarkLine.Parent           = WatermarkFrame

    local PoweredByLabel = Instance.new("TextLabel")
    PoweredByLabel.Text             = "powered by"
    PoweredByLabel.Font             = Enum.Font.Gotham
    PoweredByLabel.TextSize         = 9
    PoweredByLabel.TextColor3       = Theme.TextMuted
    PoweredByLabel.BackgroundTransparency = 1
    PoweredByLabel.Size             = UDim2.new(1, 0, 0, 16)
    PoweredByLabel.Position         = UDim2.new(0, 0, 0, 10)
    PoweredByLabel.TextXAlignment   = Enum.TextXAlignment.Center
    PoweredByLabel.ZIndex           = 20
    PoweredByLabel.Parent           = WatermarkFrame

    local NexLogo = Instance.new("ImageLabel")
    NexLogo.Image                  = "rbxassetid://136931370495154"
    NexLogo.Size                   = UDim2.new(0, 36, 0, 36)
    NexLogo.Position               = UDim2.new(0.5, -18, 0, 28)
    NexLogo.BackgroundTransparency = 1
    NexLogo.ImageColor3            = Theme.White
    NexLogo.ScaleType              = Enum.ScaleType.Fit
    NexLogo.BorderSizePixel        = 0
    NexLogo.ZIndex                 = 20
    NexLogo.Parent                 = WatermarkFrame

    -- Resolve decal -> texture asynchronously
    task.spawn(function()
        local ok, result = pcall(function()
            return game:GetService("InsertService"):LoadAsset(136931370495154)
        end)
        if ok and result then
            local decal = result:FindFirstChildWhichIsA("Decal", true)
            if decal then
                NexLogo.Image = decal.Texture
            end
            result:Destroy()
        end
    end)

    -- ── Content Area ──────────────────────────────────────────
    local ContentArea = Instance.new("Frame")
    ContentArea.Name             = "ContentArea"
    ContentArea.Size             = UDim2.new(1, -(SidebarW + 1), 1, -52)
    ContentArea.Position         = UDim2.new(0, SidebarW + 1, 0, 52)
    ContentArea.BackgroundTransparency = 1
    ContentArea.ClipsDescendants = true
    ContentArea.Parent           = Window

    -- ── Opening Animation ─────────────────────────────────────
    task.spawn(function()
        -- 1. Fade + slide window in
        Tween(Window, {
            BackgroundTransparency = 0,
            Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset)
        }, 0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

        task.wait(0.2)

        -- 2. Shimmer sweep across the accent top bar
        Tween(Shimmer, { Position = UDim2.new(1.1, 0, 0, 0) }, 0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

        task.wait(0.5)

        -- Reset shimmer for next time (reuse on minimize/restore etc.)
        Shimmer.Position = UDim2.new(-0.15, 0, 0, 0)
    end)

    -- ── Window Object ─────────────────────────────────────────
    local WindowObj = {}
    WindowObj._window      = Window
    WindowObj._tabs        = {}
    WindowObj._activeTab   = nil
    WindowObj._tabButtons  = {}
    WindowObj._tabOrder    = 0

    function WindowObj:Destroy()
        SafeDestroy(Window)
    end

    -- ── Add Tab ───────────────────────────────────────────────
    function WindowObj:AddTab(tabConfig)
        tabConfig = tabConfig or {}
        local tabName = tabConfig.Name or ("Tab " .. (#self._tabs + 1))
        local tabIcon = tabConfig.Icon -- optional rbxassetid

        self._tabOrder = self._tabOrder + 1
        local order    = self._tabOrder

        -- Tab button
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name              = "Tab_" .. tabName
        TabBtn.Text              = tabName
        TabBtn.Font              = Enum.Font.Gotham
        TabBtn.TextSize          = 12
        TabBtn.TextColor3        = Theme.TextSecondary
        TabBtn.TextXAlignment    = Enum.TextXAlignment.Left
        TabBtn.TextTruncate      = Enum.TextTruncate.AtEnd
        TabBtn.BackgroundColor3  = Color3.fromRGB(32, 32, 45)
        TabBtn.BorderSizePixel   = 0
        TabBtn.Size              = UDim2.new(1, 0, 0, 34)
        TabBtn.AutoButtonColor   = false
        TabBtn.LayoutOrder       = order
        TabBtn.Parent            = TabBar

        local TBCorner = Instance.new("UICorner")
        TBCorner.CornerRadius = UDim.new(0, 7)
        TBCorner.Parent       = TabBtn

        local TBPad = Instance.new("UIPadding")
        TBPad.PaddingLeft  = UDim.new(0, 10)
        TBPad.PaddingRight = UDim.new(0, 6)
        TBPad.Parent       = TabBtn

        -- Tab Content Frame
        local TabFrame = Instance.new("ScrollingFrame")
        TabFrame.Name                = "TabFrame_" .. tabName
        TabFrame.Size                = UDim2.new(1, 0, 1, 0)
        TabFrame.BackgroundTransparency = 1
        TabFrame.BorderSizePixel     = 0
        TabFrame.ScrollBarThickness  = 3
        TabFrame.ScrollBarImageColor3 = Theme.Accent
        TabFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
        TabFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabFrame.Visible             = false
        TabFrame.Parent              = ContentArea

        local TFLayout = Instance.new("UIListLayout")
        TFLayout.SortOrder        = Enum.SortOrder.LayoutOrder
        TFLayout.FillDirection    = Enum.FillDirection.Vertical
        TFLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        TFLayout.Padding          = UDim.new(0, 6)
        TFLayout.Parent           = TabFrame

        local TFPad = Instance.new("UIPadding")
        TFPad.PaddingTop    = UDim.new(0, 10)
        TFPad.PaddingBottom = UDim.new(0, 10)
        TFPad.PaddingLeft   = UDim.new(0, 10)
        TFPad.PaddingRight  = UDim.new(0, 13)
        TFPad.Parent        = TabFrame

        -- Tab object
        local TabObj = {}
        TabObj._frame  = TabFrame
        TabObj._button = TabBtn
        TabObj._order  = 0
        TabObj._window = WindowObj

        table.insert(self._tabs, TabObj)
        self._tabButtons[TabObj] = TabBtn

        -- Activate
        local function activateTab(tab)
            for _, t in ipairs(WindowObj._tabs) do
                t._frame.Visible        = false
                t._button.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
                t._button.TextColor3    = Theme.TextSecondary
                t._button.Font          = Enum.Font.Gotham
            end
            tab._frame.Visible          = true
            tab._button.BackgroundColor3 = Theme.Accent
            tab._button.TextColor3      = Theme.White
            tab._button.Font            = Enum.Font.GothamBold
            WindowObj._activeTab        = tab
        end

        TabBtn.MouseButton1Click:Connect(function()
            activateTab(TabObj)
        end)

        TabBtn.MouseEnter:Connect(function()
            if WindowObj._activeTab ~= TabObj then
                TabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 62)
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if WindowObj._activeTab ~= TabObj then
                TabBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
            end
        end)

        -- Auto-activate first tab
        if #self._tabs == 1 then
            activateTab(TabObj)
        end

        -- ── Helper: next layout order ──
        local function nextOrder(tab)
            tab._order = tab._order + 1
            return tab._order
        end

        -- ── Add Section ───────────────────────────────────────
        function TabObj:AddSection(cfg)
            cfg = cfg or {}
            local sectionName = cfg.Name or "Section"

            local headerLabel = Instance.new("TextLabel")
            headerLabel.Text            = string.upper(sectionName)
            headerLabel.Font            = Enum.Font.GothamBold
            headerLabel.TextSize        = 9
            headerLabel.TextColor3      = Theme.TextMuted
            headerLabel.TextXAlignment  = Enum.TextXAlignment.Left
            headerLabel.BackgroundTransparency = 1
            headerLabel.Size            = UDim2.new(1, 0, 0, 20)
            headerLabel.LayoutOrder     = nextOrder(self)
            headerLabel.Parent          = TabFrame

            local SectionObj = {}
            function SectionObj:Destroy() SafeDestroy(headerLabel) end
            return SectionObj
        end

        -- ── Add Divider ───────────────────────────────────────
        function TabObj:AddDivider()
            local div = Instance.new("Frame")
            div.Size             = UDim2.new(1, 0, 0, 1)
            div.BackgroundColor3 = Theme.Border
            div.BorderSizePixel  = 0
            div.LayoutOrder      = nextOrder(self)
            div.Parent           = TabFrame
        end

        -- ── Add Label ─────────────────────────────────────────
        function TabObj:AddLabel(cfg)
            cfg = cfg or {}
            local text = cfg.Text or "Label"

            local lbl = Instance.new("TextLabel")
            lbl.Text            = text
            lbl.Font            = Enum.Font.Gotham
            lbl.TextSize        = 12
            lbl.TextColor3      = Theme.TextSecondary
            lbl.TextXAlignment  = Enum.TextXAlignment.Left
            lbl.BackgroundColor3 = Theme.SectionBg
            lbl.BorderSizePixel = 0
            lbl.Size            = UDim2.new(1, 0, 0, 32)
            lbl.TextWrapped     = true
            lbl.AutomaticSize   = Enum.AutomaticSize.Y
            lbl.LayoutOrder     = nextOrder(self)
            lbl.Parent          = TabFrame

            local lc = Instance.new("UICorner")
            lc.CornerRadius = UDim.new(0, 6)
            lc.Parent = lbl

            local lp = Instance.new("UIPadding")
            lp.PaddingLeft  = UDim.new(0, 10)
            lp.PaddingRight = UDim.new(0, 10)
            lp.PaddingTop   = UDim.new(0, 8)
            lp.PaddingBottom = UDim.new(0, 8)
            lp.Parent = lbl

            local LabelObj = { _label = lbl }

            function LabelObj:Set(newText)
                lbl.Text = tostring(newText)
            end

            function LabelObj:Destroy()
                SafeDestroy(lbl)
            end

            return LabelObj
        end

        -- ── Add Toggle ────────────────────────────────────────
        function TabObj:AddToggle(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Toggle"
            local default  = cfg.Default  or false
            local tooltip  = cfg.Tooltip  or ""
            local callback = cfg.Callback or function() end
            local state    = default

            -- Row
            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.SectionBg
            row.BorderSizePixel  = 0
            row.Size             = UDim2.new(1, 0, 0, 42)
            row.LayoutOrder      = nextOrder(self)
            row.Parent           = TabFrame

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 7)
            rowCorner.Parent = row

            -- Name
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text           = name
            nameLabel.Font           = Enum.Font.Gotham
            nameLabel.TextSize       = 13
            nameLabel.TextColor3     = Theme.TextPrimary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size           = UDim2.new(1, -70, 1, 0)
            nameLabel.Position       = UDim2.new(0, 12, 0, 0)
            nameLabel.Parent         = row

            -- Tooltip
            if tooltip ~= "" then
                local tipLabel = Instance.new("TextLabel")
                tipLabel.Text           = tooltip
                tipLabel.Font           = Enum.Font.Gotham
                tipLabel.TextSize       = 10
                tipLabel.TextColor3     = Theme.TextMuted
                tipLabel.TextXAlignment = Enum.TextXAlignment.Left
                tipLabel.BackgroundTransparency = 1
                tipLabel.Size           = UDim2.new(1, -70, 0, 14)
                tipLabel.Position       = UDim2.new(0, 12, 1, -18)
                tipLabel.Parent         = row
                nameLabel.Position      = UDim2.new(0, 12, 0, 6)
                nameLabel.Size          = UDim2.new(1, -70, 0, 18)
            end

            -- Toggle track
            local track = Instance.new("Frame")
            track.Size             = UDim2.new(0, 40, 0, 22)
            track.Position         = UDim2.new(1, -52, 0.5, -11)
            track.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
            track.BorderSizePixel  = 0
            track.Parent           = row

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = track

            -- Toggle knob
            local knob = Instance.new("Frame")
            knob.Size             = UDim2.new(0, 16, 0, 16)
            knob.Position         = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
            knob.BackgroundColor3 = Theme.White
            knob.BorderSizePixel  = 0
            knob.Parent           = track

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = knob

            local ToggleObj = { _value = state }

            local function applyState(val, silent)
                state          = val
                ToggleObj._value = state
                if state then
                    Tween(track, { BackgroundColor3 = Theme.ToggleOn }, 0.2)
                    Tween(knob,  { Position = UDim2.new(1, -19, 0.5, -8) }, 0.2)
                else
                    Tween(track, { BackgroundColor3 = Theme.ToggleOff }, 0.2)
                    Tween(knob,  { Position = UDim2.new(0, 3, 0.5, -8) }, 0.2)
                end
                if not silent then
                    pcall(callback, state)
                end
            end

            -- Clickable
            local hitbox = Instance.new("TextButton")
            hitbox.BackgroundTransparency = 1
            hitbox.Size               = UDim2.new(1, 0, 1, 0)
            hitbox.Text               = ""
            hitbox.AutoButtonColor    = false
            hitbox.Parent             = row

            hitbox.MouseEnter:Connect(function()
                Tween(row, { BackgroundColor3 = Theme.SurfaceHover }, 0.1)
            end)
            hitbox.MouseLeave:Connect(function()
                Tween(row, { BackgroundColor3 = Theme.SectionBg }, 0.1)
            end)
            hitbox.MouseButton1Click:Connect(function()
                applyState(not state)
            end)

            function ToggleObj:Set(val)
                applyState(val, true)
            end

            function ToggleObj:Destroy()
                SafeDestroy(row)
            end

            return ToggleObj
        end

        -- ── Add Button ────────────────────────────────────────
        function TabObj:AddButton(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Button"
            local desc     = cfg.Desc     or ""
            local style    = cfg.Style    or "Default" -- "Default", "Danger", "Success"
            local callback = cfg.Callback or function() end

            local btnColor = Theme.Accent
            if style == "Danger"  then btnColor = Theme.Danger  end
            if style == "Success" then btnColor = Theme.Success  end

            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.SectionBg
            row.BorderSizePixel  = 0
            row.Size             = UDim2.new(1, 0, 0, desc ~= "" and 48 or 38)
            row.LayoutOrder      = nextOrder(self)
            row.Parent           = TabFrame

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 7)
            rowCorner.Parent = row

            local btn = Instance.new("TextButton")
            btn.Text            = name
            btn.Font            = Enum.Font.GothamBold
            btn.TextSize        = 12
            btn.TextColor3      = Theme.White
            btn.BackgroundColor3 = btnColor
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Size            = UDim2.new(0, 90, 0, 28)
            btn.Position        = UDim2.new(1, -100, 0.5, -14)
            btn.Parent          = row

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn

            if desc ~= "" then
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Text           = name
                nameLabel.Font           = Enum.Font.GothamBold
                nameLabel.TextSize       = 13
                nameLabel.TextColor3     = Theme.TextPrimary
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.BackgroundTransparency = 1
                nameLabel.Size           = UDim2.new(1, -110, 0, 18)
                nameLabel.Position       = UDim2.new(0, 12, 0, 8)
                nameLabel.Parent         = row

                local descLabel = Instance.new("TextLabel")
                descLabel.Text           = desc
                descLabel.Font           = Enum.Font.Gotham
                descLabel.TextSize       = 10
                descLabel.TextColor3     = Theme.TextMuted
                descLabel.TextXAlignment = Enum.TextXAlignment.Left
                descLabel.BackgroundTransparency = 1
                descLabel.Size           = UDim2.new(1, -110, 0, 14)
                descLabel.Position       = UDim2.new(0, 12, 0, 28)
                descLabel.Parent         = row

                btn.Text = "Run"
            else
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Text           = name
                nameLabel.Font           = Enum.Font.Gotham
                nameLabel.TextSize       = 13
                nameLabel.TextColor3     = Theme.TextPrimary
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.BackgroundTransparency = 1
                nameLabel.Size           = UDim2.new(1, -110, 1, 0)
                nameLabel.Position       = UDim2.new(0, 12, 0, 0)
                nameLabel.Parent         = row

                btn.Text = "Run"
            end

            btn.MouseEnter:Connect(function()
                local hoverColor = btnColor
                if style == "Default" then hoverColor = Theme.AccentHover end
                Tween(btn, { BackgroundColor3 = hoverColor }, 0.12)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, { BackgroundColor3 = btnColor }, 0.12)
            end)
            btn.MouseButton1Down:Connect(function()
                Tween(btn, { Size = UDim2.new(0, 86, 0, 26) }, 0.08)
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(btn, { Size = UDim2.new(0, 90, 0, 28) }, 0.12)
            end)
            btn.MouseButton1Click:Connect(function()
                pcall(callback)
            end)

            local BtnObj = { _button = btn, _row = row }
            function BtnObj:Destroy()
                SafeDestroy(row)
            end
            return BtnObj
        end

        -- ── Add Input ─────────────────────────────────────────
        function TabObj:AddInput(cfg)
            cfg = cfg or {}
            local name        = cfg.Name        or "Input"
            local placeholder = cfg.Placeholder or "Enter value..."
            local default     = cfg.Default     or ""
            local numeric     = cfg.Numeric     or false
            local callback    = cfg.Callback    or function() end

            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.SectionBg
            row.BorderSizePixel  = 0
            row.Size             = UDim2.new(1, 0, 0, 58)
            row.LayoutOrder      = nextOrder(self)
            row.Parent           = TabFrame

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 7)
            rowCorner.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text           = name
            nameLabel.Font           = Enum.Font.Gotham
            nameLabel.TextSize       = 12
            nameLabel.TextColor3     = Theme.TextSecondary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size           = UDim2.new(1, -24, 0, 16)
            nameLabel.Position       = UDim2.new(0, 12, 0, 8)
            nameLabel.Parent         = row

            local inputBg = Instance.new("Frame")
            inputBg.BackgroundColor3 = Theme.InputBg
            inputBg.BorderSizePixel  = 0
            inputBg.Size             = UDim2.new(1, -24, 0, 26)
            inputBg.Position         = UDim2.new(0, 12, 0, 26)
            inputBg.Parent           = row

            local inputBgCorner = Instance.new("UICorner")
            inputBgCorner.CornerRadius = UDim.new(0, 5)
            inputBgCorner.Parent = inputBg

            local inputStroke = Instance.new("UIStroke")
            inputStroke.Color     = Theme.Border
            inputStroke.Thickness = 1
            inputStroke.Parent    = inputBg

            local textBox = Instance.new("TextBox")
            textBox.Text               = default
            textBox.PlaceholderText    = placeholder
            textBox.Font               = Enum.Font.Gotham
            textBox.TextSize           = 11
            textBox.TextColor3         = Theme.TextPrimary
            textBox.PlaceholderColor3  = Theme.TextMuted
            textBox.TextXAlignment     = Enum.TextXAlignment.Left
            textBox.BackgroundTransparency = 1
            textBox.BorderSizePixel    = 0
            textBox.ClearTextOnFocus   = false
            textBox.Size               = UDim2.new(1, -16, 1, 0)
            textBox.Position           = UDim2.new(0, 8, 0, 0)
            textBox.Parent             = inputBg

            textBox.Focused:Connect(function()
                Tween(inputStroke, { Color = Theme.Accent }, 0.15)
            end)
            textBox.FocusLost:Connect(function(enter)
                Tween(inputStroke, { Color = Theme.Border }, 0.15)
                if numeric then
                    local n = tonumber(textBox.Text)
                    textBox.Text = n and tostring(n) or default
                end
                pcall(callback, textBox.Text, enter)
            end)

            local InputObj = { _box = textBox }

            function InputObj:Get()
                return textBox.Text
            end

            function InputObj:Set(val)
                textBox.Text = tostring(val)
            end

            function InputObj:Destroy()
                SafeDestroy(row)
            end

            return InputObj
        end

        -- ── Add Slider ────────────────────────────────────────
        function TabObj:AddSlider(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Slider"
            local min      = cfg.Min      or 0
            local max      = cfg.Max      or 100
            local default  = cfg.Default  or min
            local decimals = cfg.Decimals or 0
            local suffix   = cfg.Suffix   or ""
            local callback = cfg.Callback or function() end

            local value = Clamp(default, min, max)

            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.SectionBg
            row.BorderSizePixel  = 0
            row.Size             = UDim2.new(1, 0, 0, 56)
            row.LayoutOrder      = nextOrder(self)
            row.ClipsDescendants = false
            row.Parent           = TabFrame

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 7)
            rowCorner.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text           = name
            nameLabel.Font           = Enum.Font.Gotham
            nameLabel.TextSize       = 13
            nameLabel.TextColor3     = Theme.TextPrimary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size           = UDim2.new(0.65, 0, 0, 18)
            nameLabel.Position       = UDim2.new(0, 12, 0, 8)
            nameLabel.Parent         = row

            local valLabel = Instance.new("TextLabel")
            valLabel.Text            = Round(value, decimals) .. suffix
            valLabel.Font            = Enum.Font.GothamBold
            valLabel.TextSize        = 12
            valLabel.TextColor3      = Theme.Accent
            valLabel.TextXAlignment  = Enum.TextXAlignment.Right
            valLabel.BackgroundTransparency = 1
            valLabel.Size            = UDim2.new(0.35, -12, 0, 18)
            valLabel.Position        = UDim2.new(0.65, 0, 0, 8)
            valLabel.Parent          = row

            -- Track
            local track = Instance.new("Frame")
            track.BackgroundColor3 = Theme.SliderTrack
            track.BorderSizePixel  = 0
            track.Size             = UDim2.new(1, -24, 0, 5)
            track.Position         = UDim2.new(0, 12, 0, 36)
            track.Parent           = row

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = track

            -- Fill
            local fill = Instance.new("Frame")
            fill.BackgroundColor3 = Theme.SliderFill
            fill.BorderSizePixel  = 0
            fill.Size             = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.Parent           = track

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = fill

            -- Thumb
            local thumb = Instance.new("Frame")
            thumb.Size             = UDim2.new(0, 14, 0, 14)
            thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
            thumb.Position         = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            thumb.BackgroundColor3 = Theme.White
            thumb.BorderSizePixel  = 0
            thumb.ZIndex           = 5
            thumb.Parent           = track

            local thumbCorner = Instance.new("UICorner")
            thumbCorner.CornerRadius = UDim.new(1, 0)
            thumbCorner.Parent = thumb

            local thumbStroke = Instance.new("UIStroke")
            thumbStroke.Color     = Theme.Accent
            thumbStroke.Thickness = 2
            thumbStroke.Parent    = thumb

            -- Drag logic
            local draggingSlider = false

            local function updateFromMouse()
                local trackPos    = track.AbsolutePosition
                local trackWidth  = track.AbsoluteSize.X
                local mouseX      = UserInputService:GetMouseLocation().X
                local relX        = Clamp((mouseX - trackPos.X) / trackWidth, 0, 1)
                local newValue    = min + relX * (max - min)
                newValue          = Round(newValue, decimals)
                newValue          = Clamp(newValue, min, max)
                value             = newValue
                local pct         = (value - min) / (max - min)
                fill.Size         = UDim2.new(pct, 0, 1, 0)
                thumb.Position    = UDim2.new(pct, 0, 0.5, 0)
                valLabel.Text     = Round(value, decimals) .. suffix
                pcall(callback, value)
            end

            local hitbox = Instance.new("TextButton")
            hitbox.BackgroundTransparency = 1
            hitbox.Size               = UDim2.new(1, 0, 0, 28)
            hitbox.Position           = UDim2.new(0, 0, 0, 24)
            hitbox.Text               = ""
            hitbox.AutoButtonColor    = false
            hitbox.ZIndex             = 10
            hitbox.Parent             = row

            hitbox.MouseButton1Down:Connect(function()
                draggingSlider = true
                updateFromMouse()
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                end
            end)

            RunService.Heartbeat:Connect(function()
                if draggingSlider then
                    updateFromMouse()
                end
            end)

            local SliderObj = { _value = value }

            function SliderObj:Set(val)
                val           = Round(Clamp(val, min, max), decimals)
                value         = val
                local pct     = (value - min) / (max - min)
                fill.Size     = UDim2.new(pct, 0, 1, 0)
                thumb.Position = UDim2.new(pct, 0, 0.5, 0)
                valLabel.Text = Round(value, decimals) .. suffix
            end

            function SliderObj:Get()
                return value
            end

            function SliderObj:Destroy()
                SafeDestroy(row)
            end

            return SliderObj
        end

        -- ── Add Dropdown ──────────────────────────────────────
        function TabObj:AddDropdown(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Dropdown"
            local options  = cfg.Options  or {}
            local default  = cfg.Default  or options[1]
            local callback = cfg.Callback or function() end

            local selected = default
            local open     = false

            local wrapper = Instance.new("Frame")
            wrapper.BackgroundTransparency = 1
            wrapper.Size             = UDim2.new(1, 0, 0, 0)
            wrapper.AutomaticSize    = Enum.AutomaticSize.Y
            wrapper.LayoutOrder      = nextOrder(self)
            wrapper.ZIndex           = 10
            wrapper.ClipsDescendants = false
            wrapper.Parent           = TabFrame

            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.SectionBg
            row.BorderSizePixel  = 0
            row.Size             = UDim2.new(1, 0, 0, 42)
            row.ClipsDescendants = false
            row.ZIndex           = 12
            row.Parent           = wrapper

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 7)
            rowCorner.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text           = name
            nameLabel.Font           = Enum.Font.Gotham
            nameLabel.TextSize       = 13
            nameLabel.TextColor3     = Theme.TextPrimary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size           = UDim2.new(0.55, 0, 1, 0)
            nameLabel.Position       = UDim2.new(0, 12, 0, 0)
            nameLabel.Parent         = row

            -- Selected display
            local selDisplay = Instance.new("Frame")
            selDisplay.BackgroundColor3 = Theme.InputBg
            selDisplay.BorderSizePixel  = 0
            selDisplay.Size             = UDim2.new(0, 140, 0, 28)
            selDisplay.Position         = UDim2.new(1, -152, 0.5, -14)
            selDisplay.Parent           = row

            local selDisplayCorner = Instance.new("UICorner")
            selDisplayCorner.CornerRadius = UDim.new(0, 5)
            selDisplayCorner.Parent = selDisplay

            local selStroke = Instance.new("UIStroke")
            selStroke.Color     = Theme.Border
            selStroke.Thickness = 1
            selStroke.Parent    = selDisplay

            local selLabel = Instance.new("TextLabel")
            selLabel.Text            = tostring(selected or "Select...")
            selLabel.Font            = Enum.Font.Gotham
            selLabel.TextSize        = 11
            selLabel.TextColor3      = selected and Theme.TextPrimary or Theme.TextMuted
            selLabel.TextXAlignment  = Enum.TextXAlignment.Left
            selLabel.BackgroundTransparency = 1
            selLabel.Size            = UDim2.new(1, -28, 1, 0)
            selLabel.Position        = UDim2.new(0, 8, 0, 0)
            selLabel.Parent          = selDisplay

            -- Arrow
            local arrow = Instance.new("TextLabel")
            arrow.Text            = "▾"
            arrow.Font            = Enum.Font.GothamBold
            arrow.TextSize        = 10
            arrow.TextColor3      = Theme.TextMuted
            arrow.BackgroundTransparency = 1
            arrow.Size            = UDim2.new(0, 20, 1, 0)
            arrow.Position        = UDim2.new(1, -22, 0, 0)
            arrow.TextXAlignment  = Enum.TextXAlignment.Center
            arrow.Parent          = selDisplay

            -- Dropdown menu
            local menu = Instance.new("Frame")
            menu.BackgroundColor3 = Theme.Surface
            menu.BorderSizePixel  = 0
            menu.Size             = UDim2.new(0, 140, 0, 0)
            menu.Position         = UDim2.new(1, -152, 1, 4)
            menu.Visible          = false
            menu.ClipsDescendants = true
            menu.ZIndex           = 50
            menu.Parent           = row

            local menuCorner = Instance.new("UICorner")
            menuCorner.CornerRadius = UDim.new(0, 7)
            menuCorner.Parent = menu

            local menuStroke = Instance.new("UIStroke")
            menuStroke.Color     = Theme.Border
            menuStroke.Thickness = 1
            menuStroke.Parent    = menu

            local menuLayout = Instance.new("UIListLayout")
            menuLayout.SortOrder  = Enum.SortOrder.LayoutOrder
            menuLayout.Padding    = UDim.new(0, 2)
            menuLayout.Parent     = menu

            local menuPad = Instance.new("UIPadding")
            menuPad.PaddingTop    = UDim.new(0, 4)
            menuPad.PaddingBottom = UDim.new(0, 4)
            menuPad.PaddingLeft   = UDim.new(0, 4)
            menuPad.PaddingRight  = UDim.new(0, 4)
            menuPad.Parent        = menu

            local DropObj = { _value = selected }

            local function buildOptions(opts)
                -- Clear old options
                for _, child in ipairs(menu:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for i, opt in ipairs(opts) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Text            = tostring(opt)
                    optBtn.Font            = Enum.Font.Gotham
                    optBtn.TextSize        = 11
                    optBtn.TextColor3      = opt == selected and Theme.Accent or Theme.TextPrimary
                    optBtn.TextXAlignment  = Enum.TextXAlignment.Left
                    optBtn.BackgroundColor3 = Theme.Surface
                    optBtn.BorderSizePixel = 0
                    optBtn.AutoButtonColor = false
                    optBtn.Size            = UDim2.new(1, 0, 0, 26)
                    optBtn.LayoutOrder     = i
                    optBtn.ZIndex          = 55
                    optBtn.Parent          = menu

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 5)
                    optCorner.Parent = optBtn

                    local optPad = Instance.new("UIPadding")
                    optPad.PaddingLeft = UDim.new(0, 8)
                    optPad.Parent = optBtn

                    optBtn.MouseEnter:Connect(function()
                        Tween(optBtn, { BackgroundColor3 = Theme.SurfaceHover }, 0.1)
                    end)
                    optBtn.MouseLeave:Connect(function()
                        Tween(optBtn, { BackgroundColor3 = Theme.Surface }, 0.1)
                    end)
                    optBtn.MouseButton1Click:Connect(function()
                        selected            = opt
                        DropObj._value      = opt
                        selLabel.Text       = tostring(opt)
                        selLabel.TextColor3 = Theme.TextPrimary
                        open = false
                        Tween(menu, { Size = UDim2.new(0, 140, 0, 0) }, 0.15)
                        task.wait(0.15)
                        menu.Visible = false
                        Tween(arrow, { Rotation = 0 }, 0.15)
                        -- Update option colors
                        for _, b in ipairs(menu:GetChildren()) do
                            if b:IsA("TextButton") then
                                b.TextColor3 = b.Text == tostring(opt) and Theme.Accent or Theme.TextPrimary
                            end
                        end
                        pcall(callback, opt)
                    end)
                end
            end

            buildOptions(options)

            -- Toggle open
            local hitbox = Instance.new("TextButton")
            hitbox.BackgroundTransparency = 1
            hitbox.Size               = UDim2.new(1, 0, 1, 0)
            hitbox.Text               = ""
            hitbox.AutoButtonColor    = false
            hitbox.ZIndex             = 15
            hitbox.Parent             = selDisplay

            hitbox.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    local count = 0
                    for _, child in ipairs(menu:GetChildren()) do
                        if child:IsA("TextButton") then count = count + 1 end
                    end
                    local targetH = math.min(count * 28 + 8, 150)
                    menu.Visible = true
                    Tween(menu, { Size = UDim2.new(0, 140, 0, targetH) }, 0.2)
                    Tween(arrow, { Rotation = 180 }, 0.2)
                else
                    Tween(menu, { Size = UDim2.new(0, 140, 0, 0) }, 0.15)
                    Tween(arrow, { Rotation = 0 }, 0.15)
                    task.delay(0.15, function() menu.Visible = false end)
                end
            end)

            function DropObj:Set(val)
                selected            = val
                DropObj._value      = val
                selLabel.Text       = tostring(val)
                selLabel.TextColor3 = Theme.TextPrimary
                pcall(callback, val)
            end

            function DropObj:Refresh(newOptions, keepSelection)
                options = newOptions
                if not keepSelection then
                    selected       = newOptions[1]
                    DropObj._value = selected
                    selLabel.Text  = tostring(selected or "Select...")
                end
                buildOptions(newOptions)
            end

            function DropObj:Get()
                return selected
            end

            function DropObj:Destroy()
                SafeDestroy(wrapper)
            end

            return DropObj
        end

        -- ── Add Keybind ───────────────────────────────────────
        function TabObj:AddKeybind(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Keybind"
            local default  = cfg.Default  or Enum.KeyCode.Unknown
            local callback = cfg.Callback or function() end

            local currentKey = default
            local binding    = false

            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.SectionBg
            row.BorderSizePixel  = 0
            row.Size             = UDim2.new(1, 0, 0, 42)
            row.LayoutOrder      = nextOrder(self)
            row.Parent           = TabFrame

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 7)
            rowCorner.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text           = name
            nameLabel.Font           = Enum.Font.Gotham
            nameLabel.TextSize       = 13
            nameLabel.TextColor3     = Theme.TextPrimary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size           = UDim2.new(0.65, 0, 1, 0)
            nameLabel.Position       = UDim2.new(0, 12, 0, 0)
            nameLabel.Parent         = row

            local keyBtn = Instance.new("TextButton")
            keyBtn.Text            = currentKey == Enum.KeyCode.Unknown and "None" or currentKey.Name
            keyBtn.Font            = Enum.Font.GothamBold
            keyBtn.TextSize        = 11
            keyBtn.TextColor3      = Theme.Accent
            keyBtn.BackgroundColor3 = Theme.AccentDim
            keyBtn.BorderSizePixel = 0
            keyBtn.AutoButtonColor = false
            keyBtn.Size            = UDim2.new(0, 80, 0, 26)
            keyBtn.Position        = UDim2.new(1, -92, 0.5, -13)
            keyBtn.Parent          = row

            local keyBtnCorner = Instance.new("UICorner")
            keyBtnCorner.CornerRadius = UDim.new(0, 5)
            keyBtnCorner.Parent = keyBtn

            keyBtn.MouseButton1Click:Connect(function()
                binding      = true
                keyBtn.Text  = "..."
                keyBtn.TextColor3 = Theme.TextMuted
            end)

            UserInputService.InputBegan:Connect(function(input, gameProc)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding      = false
                    currentKey   = input.KeyCode
                    keyBtn.Text  = currentKey.Name
                    keyBtn.TextColor3 = Theme.Accent
                    pcall(callback, currentKey)
                elseif not gameProc and input.KeyCode == currentKey then
                    pcall(callback, currentKey)
                end
            end)

            local KBObj = { _value = currentKey }

            function KBObj:Set(key)
                currentKey    = key
                KBObj._value  = key
                keyBtn.Text   = key.Name
            end

            function KBObj:Get()
                return currentKey
            end

            function KBObj:Destroy()
                SafeDestroy(row)
            end

            return KBObj
        end

        -- ── Add ColorPicker ───────────────────────────────────
        function TabObj:AddColorPicker(cfg)
            cfg = cfg or {}
            local name     = cfg.Name     or "Color"
            local default  = cfg.Default  or Color3.fromRGB(99, 102, 241)
            local callback = cfg.Callback or function() end

            local currentColor = default
            local open         = false

            local wrapper = Instance.new("Frame")
            wrapper.BackgroundTransparency = 1
            wrapper.Size             = UDim2.new(1, 0, 0, 0)
            wrapper.AutomaticSize    = Enum.AutomaticSize.Y
            wrapper.LayoutOrder      = nextOrder(self)
            wrapper.ClipsDescendants = false
            wrapper.Parent           = TabFrame

            local row = Instance.new("Frame")
            row.BackgroundColor3 = Theme.SectionBg
            row.BorderSizePixel  = 0
            row.Size             = UDim2.new(1, 0, 0, 42)
            row.ClipsDescendants = false
            row.Parent           = wrapper

            local rowCorner = Instance.new("UICorner")
            rowCorner.CornerRadius = UDim.new(0, 7)
            rowCorner.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text           = name
            nameLabel.Font           = Enum.Font.Gotham
            nameLabel.TextSize       = 13
            nameLabel.TextColor3     = Theme.TextPrimary
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.BackgroundTransparency = 1
            nameLabel.Size           = UDim2.new(0.6, 0, 1, 0)
            nameLabel.Position       = UDim2.new(0, 12, 0, 0)
            nameLabel.Parent         = row

            -- Hex display
            local hexLabel = Instance.new("TextLabel")
            hexLabel.Text            = ToHex(currentColor)
            hexLabel.Font            = Enum.Font.RobotoMono
            hexLabel.TextSize        = 11
            hexLabel.TextColor3      = Theme.TextSecondary
            hexLabel.TextXAlignment  = Enum.TextXAlignment.Right
            hexLabel.BackgroundTransparency = 1
            hexLabel.Size            = UDim2.new(0, 70, 1, 0)
            hexLabel.Position        = UDim2.new(1, -112, 0, 0)
            hexLabel.Parent          = row

            -- Preview swatch
            local swatch = Instance.new("TextButton")
            swatch.Text            = ""
            swatch.BackgroundColor3 = currentColor
            swatch.BorderSizePixel = 0
            swatch.AutoButtonColor = false
            swatch.Size            = UDim2.new(0, 28, 0, 28)
            swatch.Position        = UDim2.new(1, -40, 0.5, -14)
            swatch.Parent          = row

            local swatchCorner = Instance.new("UICorner")
            swatchCorner.CornerRadius = UDim.new(0, 6)
            swatchCorner.Parent = swatch

            local swatchStroke = Instance.new("UIStroke")
            swatchStroke.Color     = Theme.Border
            swatchStroke.Thickness = 1
            swatchStroke.Parent    = swatch

            -- Picker panel
            local panel = Instance.new("Frame")
            panel.BackgroundColor3 = Theme.Surface
            panel.BorderSizePixel  = 0
            panel.Size             = UDim2.new(1, 0, 0, 0)
            panel.Position         = UDim2.new(0, 0, 1, 4)
            panel.Visible          = false
            panel.ClipsDescendants = true
            panel.ZIndex           = 20
            panel.Parent           = row

            local panelCorner = Instance.new("UICorner")
            panelCorner.CornerRadius = UDim.new(0, 7)
            panelCorner.Parent = panel

            local panelStroke = Instance.new("UIStroke")
            panelStroke.Color     = Theme.Border
            panelStroke.Thickness = 1
            panelStroke.Parent    = panel

            -- RGB sliders
            local function makeRGBSlider(label, posY, colorComp)
                local trackBg = Instance.new("Frame")
                trackBg.BackgroundColor3 = Theme.SliderTrack
                trackBg.BorderSizePixel  = 0
                trackBg.Size             = UDim2.new(1, -80, 0, 5)
                trackBg.Position         = UDim2.new(0, 50, 0, posY + 5)
                trackBg.ZIndex           = 22
                trackBg.Parent           = panel

                local tcorner = Instance.new("UICorner")
                tcorner.CornerRadius = UDim.new(1, 0)
                tcorner.Parent = trackBg

                local tfill = Instance.new("Frame")
                tfill.BackgroundColor3 = Theme.Accent
                tfill.BorderSizePixel  = 0
                tfill.Size             = UDim2.new(colorComp, 0, 1, 0)
                tfill.ZIndex           = 23
                tfill.Parent           = trackBg

                local tfcorner = Instance.new("UICorner")
                tfcorner.CornerRadius = UDim.new(1, 0)
                tfcorner.Parent = tfill

                local lbl = Instance.new("TextLabel")
                lbl.Text            = label
                lbl.Font            = Enum.Font.GothamBold
                lbl.TextSize        = 10
                lbl.TextColor3      = Theme.TextMuted
                lbl.BackgroundTransparency = 1
                lbl.Size            = UDim2.new(0, 42, 0, 15)
                lbl.Position        = UDim2.new(0, 8, 0, posY - 1)
                lbl.TextXAlignment  = Enum.TextXAlignment.Left
                lbl.ZIndex          = 22
                lbl.Parent          = panel

                local valLbl = Instance.new("TextLabel")
                valLbl.Text            = tostring(math.floor(colorComp * 255))
                valLbl.Font            = Enum.Font.GothamBold
                valLbl.TextSize        = 10
                valLbl.TextColor3      = Theme.TextSecondary
                valLbl.BackgroundTransparency = 1
                valLbl.Size            = UDim2.new(0, 28, 0, 15)
                valLbl.Position        = UDim2.new(1, -36, 0, posY - 1)
                valLbl.TextXAlignment  = Enum.TextXAlignment.Right
                valLbl.ZIndex          = 22
                valLbl.Parent          = panel

                return trackBg, tfill, valLbl
            end

            local rTrack, rFill, rVal = makeRGBSlider("R", 8,  currentColor.R)
            local gTrack, gFill, gVal = makeRGBSlider("G", 26, currentColor.G)
            local bTrack, bFill, bVal = makeRGBSlider("B", 44, currentColor.B)

            local rComp = currentColor.R
            local gComp = currentColor.G
            local bComp = currentColor.B

            local function applyColor()
                currentColor = Color3.new(rComp, gComp, bComp)
                swatch.BackgroundColor3 = currentColor
                hexLabel.Text           = ToHex(currentColor)
                rFill.Size = UDim2.new(rComp, 0, 1, 0)
                gFill.Size = UDim2.new(gComp, 0, 1, 0)
                bFill.Size = UDim2.new(bComp, 0, 1, 0)
                rVal.Text  = tostring(math.floor(rComp * 255))
                gVal.Text  = tostring(math.floor(gComp * 255))
                bVal.Text  = tostring(math.floor(bComp * 255))
                pcall(callback, currentColor)
            end

            local function makeSliderDrag(track, component)
                local drag = false
                local hit = Instance.new("TextButton")
                hit.BackgroundTransparency = 1
                hit.Size = UDim2.new(1, 0, 0, 20)
                hit.Position = UDim2.new(0, 0, 0, -7)
                hit.Text = ""
                hit.ZIndex = 30
                hit.Parent = track

                hit.MouseButton1Down:Connect(function() drag = true end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
                end)
                RunService.Heartbeat:Connect(function()
                    if drag then
                        local mx    = UserInputService:GetMouseLocation().X
                        local tx    = track.AbsolutePosition.X
                        local tw    = track.AbsoluteSize.X
                        local relX  = Clamp((mx - tx) / tw, 0, 1)
                        if component == "r" then rComp = relX
                        elseif component == "g" then gComp = relX
                        else bComp = relX end
                        applyColor()
                    end
                end)
            end

            makeSliderDrag(rTrack, "r")
            makeSliderDrag(gTrack, "g")
            makeSliderDrag(bTrack, "b")

            -- Open/close
            swatch.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    panel.Visible = true
                    Tween(panel, { Size = UDim2.new(1, 0, 0, 76) }, 0.2)
                else
                    Tween(panel, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
                    task.delay(0.15, function() panel.Visible = false end)
                end
            end)

            local CPObj = { _value = currentColor }

            function CPObj:Set(c)
                currentColor = c
                rComp = c.R; gComp = c.G; bComp = c.B
                applyColor()
            end

            function CPObj:Get()
                return currentColor
            end

            function CPObj:Destroy()
                SafeDestroy(wrapper)
            end

            return CPObj
        end

        return TabObj
    end -- AddTab

    return WindowObj
end -- CreateWindow

-- ============================================================
--  RETURN
-- ============================================================

return NexUI
