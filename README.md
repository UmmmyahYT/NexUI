# NexUI

A clean, loadstring-compatible Luau UI library for building script menus in Roblox. Comes with a full suite of components — tabs, toggles, sliders, dropdowns, color pickers, keybinds, and more — wrapped in a polished dark theme with smooth animations.

---

## Table of Contents

- [Loading NexUI](#loading-nexui)
- [Creating a Window](#creating-a-window)
- [Adding Tabs](#adding-tabs)
- [Components](#components)
  - [Section](#section)
  - [Toggle](#toggle)
  - [Button](#button)
  - [Input](#input)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [Keybind](#keybind)
  - [Color Picker](#color-picker)
  - [Label](#label)
  - [Divider](#divider)
- [Notifications](#notifications)
- [Element Methods](#element-methods)
- [Window Controls](#window-controls)
- [Full Example Script](#full-example-script)
- [Tips & Best Practices](#tips--best-practices)

---

## Loading NexUI

NexUI is designed to be loaded remotely with `loadstring` and `HttpGet`. Host the raw `NexUI.lua` file somewhere publicly accessible (GitHub raw, Pastebin raw, your own server, etc.) and replace the URL below with your own.

```lua
local NexUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/UmmmyahYT/NexUI/refs/heads/main/NexUI.lua"))()
```

> **Make sure** `Allow HTTP Requests` is enabled in your game's settings, or that you're running in an executor that handles this automatically.

Once loaded, `NexUI` is a table you call methods on to build your interface. Nothing is created until you call `CreateWindow`.

---

## Creating a Window

```lua
local Window = NexUI:CreateWindow({
    Title    = "My Script",   -- Main title shown in the header
    Subtitle = "v1.0",        -- Smaller right-aligned subtitle (optional)
    Size     = Vector2.new(560, 380),  -- Default window size in pixels (optional)
    Position = UDim2.new(0.5, -280, 0.5, -190),  -- Starting position (optional)
})
```

The window is draggable by its title bar and supports two built-in controls:

- **Minimize button (─)** — collapses the window to just the title bar and back
- **Close button (✕)** — fades out and destroys the window entirely

| Option     | Type         | Default                   | Description                        |
|------------|--------------|---------------------------|------------------------------------|
| `Title`    | `string`     | `"NexUI"`                 | Window header text                 |
| `Subtitle` | `string`     | `""`                      | Smaller label on the right side    |
| `Size`     | `Vector2`    | `Vector2.new(560, 380)`   | Width and height in pixels         |
| `Position` | `UDim2`      | Centered on screen        | Initial screen position            |

---

## Adding Tabs

Tabs appear in the sidebar on the left side of the window. You can add as many as you need. The first tab added is automatically selected.

```lua
local MainTab     = Window:AddTab({ Name = "Main" })
local SettingsTab = Window:AddTab({ Name = "Settings" })
local CreditsTab  = Window:AddTab({ Name = "Credits" })
```

Optionally pass an `Icon` with an asset ID to show an image next to the tab name:

```lua
local Tab = Window:AddTab({
    Name = "Combat",
    Icon = "rbxassetid://7733960981",
})
```

| Option | Type     | Description                                      |
|--------|----------|--------------------------------------------------|
| `Name` | `string` | Tab label shown in the sidebar                   |
| `Icon` | `string` | Optional `rbxassetid://` for a 16×16 tab icon   |

All components listed below are added to a tab by calling methods on the tab object returned by `AddTab`.

---

## Components

### Section

Adds a labeled category header to visually group related elements beneath it. Sections don't have any interactive behavior — they're purely organizational.

```lua
Tab:AddSection({ Name = "Movement" })
Tab:AddToggle({ Name = "Fly", ... })
Tab:AddToggle({ Name = "Speed Boost", ... })

Tab:AddSection({ Name = "Combat" })
Tab:AddToggle({ Name = "Auto Parry", ... })
```

| Option | Type     | Description              |
|--------|----------|--------------------------|
| `Name` | `string` | Section header label     |

---

### Toggle

An on/off switch. Fires `Callback` every time the state changes.

```lua
local FlyToggle = Tab:AddToggle({
    Name     = "Fly",
    Default  = false,
    Tooltip  = "Enables fly mode",   -- optional small hint text
    Callback = function(value)
        -- value is true or false
        print("Fly:", value)
    end,
})
```

| Option     | Type       | Default   | Description                                    |
|------------|------------|-----------|------------------------------------------------|
| `Name`     | `string`   | `"Toggle"`| Label shown on the row                         |
| `Default`  | `bool`     | `false`   | Initial on/off state                           |
| `Tooltip`  | `string`   | `""`      | Small dimmed hint shown beneath the label      |
| `Callback` | `function` | —         | Called with `(bool)` whenever state changes    |

**Methods:**

```lua
FlyToggle:Set(true)   -- Programmatically set state (does not fire Callback)
FlyToggle:Destroy()   -- Remove from UI
```

---

### Button

A clickable action row. Can be styled as default (accent), danger (red), or success (green).

```lua
local TpButton = Tab:AddButton({
    Name     = "Teleport to Spawn",
    Desc     = "Instantly moves you to the spawn point",  -- optional description
    Style    = "Default",   -- "Default", "Danger", or "Success"
    Callback = function()
        print("Button clicked!")
    end,
})
```

| Option     | Type       | Default      | Description                                      |
|------------|------------|--------------|--------------------------------------------------|
| `Name`     | `string`   | `"Button"`   | Button label and row title                       |
| `Desc`     | `string`   | `""`         | Optional description text shown below the name  |
| `Style`    | `string`   | `"Default"`  | `"Default"` (indigo), `"Danger"` (red), `"Success"` (green) |
| `Callback` | `function` | —            | Called with no arguments on click                |

**Methods:**

```lua
TpButton:Destroy()
```

---

### Input

A single-line text box. Fires `Callback` when the user finishes typing (focus lost).

```lua
local NameInput = Tab:AddInput({
    Name        = "Player Name",
    Placeholder = "Enter a username...",
    Default     = "",
    Numeric     = false,   -- if true, non-numeric input is cleared on submit
    Callback    = function(value, pressedEnter)
        -- value: the current text string
        -- pressedEnter: true if user pressed Enter, false if they clicked away
        print("Input:", value)
    end,
})
```

| Option        | Type       | Default              | Description                                      |
|---------------|------------|----------------------|--------------------------------------------------|
| `Name`        | `string`   | `"Input"`            | Label shown above the text box                  |
| `Placeholder` | `string`   | `"Enter value..."`   | Greyed-out hint text when empty                 |
| `Default`     | `string`   | `""`                 | Pre-filled value                                |
| `Numeric`     | `bool`     | `false`              | Clears non-numeric input on submit              |
| `Callback`    | `function` | —                    | Called with `(string, bool)` on focus lost      |

**Methods:**

```lua
NameInput:Get()          -- Returns current text string
NameInput:Set("admin")   -- Set value programmatically
NameInput:Destroy()
```

---

### Slider

A draggable slider for numeric values. Supports decimal precision and a display suffix.

```lua
local SpeedSlider = Tab:AddSlider({
    Name     = "Walk Speed",
    Min      = 16,
    Max      = 500,
    Default  = 16,
    Decimals = 0,       -- decimal places shown (0 = integers only)
    Suffix   = " studs",
    Callback = function(value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
    end,
})
```

| Option     | Type       | Default   | Description                                        |
|------------|------------|-----------|----------------------------------------------------|
| `Name`     | `string`   | `"Slider"`| Label shown above the track                        |
| `Min`      | `number`   | `0`       | Minimum value                                      |
| `Max`      | `number`   | `100`     | Maximum value                                      |
| `Default`  | `number`   | `Min`     | Starting value                                     |
| `Decimals` | `number`   | `0`       | Decimal places to round to (e.g. `2` → `1.25`)    |
| `Suffix`   | `string`   | `""`      | Text appended to the displayed value               |
| `Callback` | `function` | —         | Called with `(number)` as the slider is dragged    |

**Methods:**

```lua
SpeedSlider:Get()       -- Returns current number value
SpeedSlider:Set(100)    -- Jump to a value programmatically
SpeedSlider:Destroy()
```

---

### Dropdown

A compact select menu. Expands to show a list of options when clicked.

```lua
local TeamDrop = Tab:AddDropdown({
    Name     = "Team",
    Options  = { "Red", "Blue", "Green", "Spectator" },
    Default  = "Red",
    Callback = function(value)
        print("Selected:", value)
    end,
})
```

| Option     | Type       | Default        | Description                                      |
|------------|------------|----------------|--------------------------------------------------|
| `Name`     | `string`   | `"Dropdown"`   | Label on the row                                 |
| `Options`  | `table`    | `{}`           | Array of string options                          |
| `Default`  | `any`      | `Options[1]`   | Initially selected value                         |
| `Callback` | `function` | —              | Called with the selected value on change         |

**Methods:**

```lua
TeamDrop:Get()                          -- Returns current selection
TeamDrop:Set("Blue")                    -- Select an option programmatically
TeamDrop:Refresh({ "A", "B" }, false)   -- Replace options list; second arg = keep current selection
TeamDrop:Destroy()
```

---

### Keybind

Lets the user bind a keyboard key. Clicking the display button enters "listening" mode — the next key pressed becomes the new bind. The callback also fires each time the bound key is pressed in-game.

```lua
local AuraKey = Tab:AddKeybind({
    Name     = "Toggle Aura",
    Default  = Enum.KeyCode.E,
    Callback = function(key)
        -- Fires both when the bind is changed AND when the key is pressed
        print("Key event:", key.Name)
    end,
})
```

| Option     | Type           | Default                  | Description                                         |
|------------|----------------|--------------------------|-----------------------------------------------------|
| `Name`     | `string`       | `"Keybind"`              | Label on the row                                    |
| `Default`  | `Enum.KeyCode` | `Enum.KeyCode.Unknown`   | Starting keybind                                    |
| `Callback` | `function`     | —                        | Called with `(Enum.KeyCode)` on bind or press       |

**Methods:**

```lua
AuraKey:Get()                       -- Returns current Enum.KeyCode
AuraKey:Set(Enum.KeyCode.Q)         -- Change bind programmatically
AuraKey:Destroy()
```

---

### Color Picker

A swatch that expands into RGB channel sliders when clicked. Displays the hex code alongside the preview.

```lua
local EspColor = Tab:AddColorPicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(99, 102, 241),
    Callback = function(color)
        -- color is a Color3
        print("Hex:", string.format("#%02X%02X%02X",
            color.R * 255, color.G * 255, color.B * 255))
    end,
})
```

| Option     | Type       | Default                       | Description                            |
|------------|------------|-------------------------------|----------------------------------------|
| `Name`     | `string`   | `"Color"`                     | Label on the row                       |
| `Default`  | `Color3`   | `Color3.fromRGB(99, 102, 241)`| Starting color                         |
| `Callback` | `function` | —                             | Called with `(Color3)` on any change   |

**Methods:**

```lua
EspColor:Get()                            -- Returns current Color3
EspColor:Set(Color3.fromRGB(255, 0, 0))   -- Set color programmatically
EspColor:Destroy()
```

---

### Label

A static or dynamically updated text row. Useful for status readouts, version lines, or informational text.

```lua
local StatusLabel = Tab:AddLabel({ Text = "Status: Idle" })

-- Update it later
StatusLabel:Set("Status: Running")
```

| Option | Type     | Default   | Description           |
|--------|----------|-----------|-----------------------|
| `Text` | `string` | `"Label"` | Display text content  |

**Methods:**

```lua
StatusLabel:Set("New text here")
StatusLabel:Destroy()
```

---

### Divider

A thin horizontal line for visual separation. Takes no configuration.

```lua
Tab:AddDivider()
```

---

## Notifications

Sends a toast notification in the bottom-right corner of the screen. Notifications include a progress bar that drains over the duration, then fade out automatically.

```lua
NexUI:Notify({
    Title    = "Script Loaded",
    Content  = "NexUI initialized successfully.",
    Duration = 4,       -- seconds before auto-dismiss
    Type     = "Success",  -- "Info", "Success", "Warning", or "Error"
})
```

| Option     | Type     | Default    | Description                                        |
|------------|----------|------------|----------------------------------------------------|
| `Title`    | `string` | `"Notice"` | Bold title line                                    |
| `Content`  | `string` | `""`       | Optional body text below the title                 |
| `Duration` | `number` | `3`        | Seconds until the notification dismisses itself    |
| `Type`     | `string` | `"Info"`   | Controls accent color: `"Info"` (indigo), `"Success"` (green), `"Warning"` (yellow), `"Error"` (red) |

---

## Element Methods

Every component returned by an `Add*` call shares these two universal methods:

```lua
Element:Destroy()   -- Removes the element's frame from the UI entirely
```

Most elements also expose `:Get()` and `:Set()` — see each component's section for details.

---

## Window Controls

```lua
Window:Destroy()   -- Fades out and destroys the entire window and all its contents
```

The built-in title bar buttons handle minimizing and closing automatically. You don't need to wire those up yourself, but if you need to close the window from your script (e.g. when a game event fires), call `Window:Destroy()` directly.

---

## Full Example Script

```lua
-- ── Load NexUI ─────────────────────────────────────────────
local NexUI = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

-- ── Window ─────────────────────────────────────────────────
local Window = NexUI:CreateWindow({
    Title    = "Phantom",
    Subtitle = "v2.4",
})

-- ── Tab: Movement ──────────────────────────────────────────
local Movement = Window:AddTab({ Name = "Movement" })

Movement:AddSection({ Name = "Locomotion" })

local flyEnabled = false
Movement:AddToggle({
    Name     = "Fly",
    Default  = false,
    Tooltip  = "Hold Space to ascend, Shift to descend",
    Callback = function(v)
        flyEnabled = v
        -- your fly logic here
    end,
})

Movement:AddSlider({
    Name     = "Walk Speed",
    Min      = 16,
    Max      = 250,
    Default  = 16,
    Suffix   = " st/s",
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char then char.Humanoid.WalkSpeed = v end
    end,
})

Movement:AddSlider({
    Name     = "Jump Power",
    Min      = 7,
    Max      = 200,
    Default  = 7,
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char then char.Humanoid.JumpPower = v end
    end,
})

Movement:AddDivider()
Movement:AddSection({ Name = "Teleport" })

Movement:AddButton({
    Name     = "Teleport to Spawn",
    Desc     = "Moves you to the game spawn point",
    Callback = function()
        -- your teleport logic here
        NexUI:Notify({ Title = "Teleported", Type = "Success", Duration = 2 })
    end,
})

Movement:AddInput({
    Name        = "Jump to Player",
    Placeholder = "Enter username...",
    Callback    = function(name, entered)
        if entered then
            print("Jumping to:", name)
        end
    end,
})

-- ── Tab: Combat ────────────────────────────────────────────
local Combat = Window:AddTab({ Name = "Combat" })

Combat:AddSection({ Name = "Targeting" })

local targetMode = "Nearest"
Combat:AddDropdown({
    Name     = "Target Mode",
    Options  = { "Nearest", "Lowest HP", "Highest HP", "Random" },
    Default  = "Nearest",
    Callback = function(v)
        targetMode = v
    end,
})

Combat:AddToggle({
    Name     = "Auto Parry",
    Default  = false,
    Callback = function(v)
        print("Auto Parry:", v)
    end,
})

Combat:AddSlider({
    Name     = "Reach",
    Min      = 4,
    Max      = 60,
    Default  = 6,
    Suffix   = " studs",
    Callback = function(v)
        print("Reach:", v)
    end,
})

Combat:AddKeybind({
    Name     = "Activate Aura",
    Default  = Enum.KeyCode.E,
    Callback = function(key)
        print("Aura key:", key.Name)
    end,
})

-- ── Tab: Visuals ───────────────────────────────────────────
local Visuals = Window:AddTab({ Name = "Visuals" })

Visuals:AddSection({ Name = "ESP" })

Visuals:AddToggle({
    Name     = "Player ESP",
    Default  = false,
    Callback = function(v)
        print("ESP:", v)
    end,
})

Visuals:AddColorPicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(99, 102, 241),
    Callback = function(c)
        print("Color changed:", c)
    end,
})

Visuals:AddSlider({
    Name     = "ESP Opacity",
    Min      = 0,
    Max      = 1,
    Default  = 0.8,
    Decimals = 2,
    Callback = function(v)
        print("Opacity:", v)
    end,
})

-- ── Tab: Settings ──────────────────────────────────────────
local Settings = Window:AddTab({ Name = "Settings" })

Settings:AddLabel({ Text = "Changes apply immediately." })
Settings:AddDivider()

Settings:AddToggle({
    Name     = "Notifications",
    Default  = true,
    Callback = function(v)
        print("Notifs:", v)
    end,
})

Settings:AddButton({
    Name     = "Unload Script",
    Style    = "Danger",
    Callback = function()
        Window:Destroy()
    end,
})

-- ── Startup Notification ───────────────────────────────────
NexUI:Notify({
    Title    = "Phantom Loaded",
    Content  = "Press the keybinds or use the menu to get started.",
    Duration = 5,
    Type     = "Info",
})
```

---

## Tips & Best Practices

**Use Sections to group things clearly.** Players scan menus quickly. A section header every 3–5 elements keeps the layout readable and avoids a wall of controls with no context.

**Wire Callbacks directly to your logic.** Don't store the value in a variable and poll it — the Callback fires on every change, so just do the work inside it. For toggles, keep the function cheap since it fires on every click.

**Use `:Set()` for initialization.** If your script has saved settings (e.g. from `writefile`/`readfile`), load them after building the UI and call `:Set()` on each element. This updates the visual state without firing the Callback again, avoiding double-execution on startup.

**Reload-safe.** NexUI destroys any existing `NexUI_Root` ScreenGui before creating a new one. Re-running your script won't stack duplicate windows.

**Keybind Callbacks fire twice in different ways.** They fire once when a new key is bound (so you know the binding changed), and again each time that key is pressed in-game. Use a flag or check context if you only want to respond to presses, not binds.

**Keep Notify calls sparse.** One notification on load and one for significant actions (teleport success, toggle of a major feature) is enough. Showing a toast for every single toggle gets noisy fast.

**Dropdown `:Refresh()` is for dynamic lists.** If your options change at runtime (e.g. a list of players in the server), call `:Refresh(newOptions, true)` to update the list while keeping the current selection, or `false` to reset to the first item.
