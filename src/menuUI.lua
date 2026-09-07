-- ============================================================================
-- menuUI.lua
-- Sistem UI menu in-game untuk konfigurasi MOD Vehicle Jumper
-- ============================================================================

local MenuUI = {}

-- Reference ke modules
local ConfigManager = require("src/configManager")

-- State menu
local menuState = {
    isVisible = false,
    selectedIndex = 1,
    vehicle = nil,
    scrollOffset = 0
}

-- Konfigurasi menu items
local menuItems = {
    {key = "jumpHeight", label = "Ketinggian Loncat", min = 5, max = 50, step = 1},
    {key = "jumpForce", label = "Kekuatan Loncat", min = 10, max = 100, step = 5},
    {key = "jumpDuration", label = "Durasi Loncat (s)", min = 0.5, max = 5, step = 0.5},
    {key = "rotationSpeed", label = "Kecepatan Rotasi (°/s)", min = 90, max = 720, step = 30},
    {key = "rotationAxis", label = "Arah Rotasi", options = {"left", "right", "forward", "backward"}},
    {key = "rotationDegrees", label = "Total Rotasi (°)", min = 90, max = 720, step = 90},
    {key = "lateralDirection", label = "Gerakan Lateral", options = {"forward", "backward", "none"}},
    {key = "lateralForce", label = "Kekuatan Lateral", min = 0, max = 50, step = 5},
    {key = "rotationTiming", label = "Delay Rotasi (fraksi)", min = 0, max = 1, step = 0.1},
}

-- Dimensi UI
local UI_WIDTH = 0.4
local UI_HEIGHT = 0.7
local UI_X = 0.3
local UI_Y = 0.15
local ITEM_HEIGHT = 0.08
local ITEMS_PER_PAGE = 7

-- ============================================================================
-- Fungsi Rendering
-- ============================================================================

--- Render text dengan background
local function renderTextBox(x, y, width, height, text, fontSize, bgColor, textColor, alignment)
    bgColor = bgColor or {0, 0, 0, 0.8}
    textColor = textColor or {1, 1, 1, 1}
    alignment = alignment or RenderText.ALIGN_LEFT
    
    -- Background
    drawFilledRect(x, y, width, height, unpack(bgColor))
    
    -- Border
    drawRect(x, y, width, height, 0.002, 1, 1, 1, 1)
    
    -- Text
    setTextColor(unpack(textColor))
    setTextBold(false)
    setTextAlignment(alignment)
    renderText(x + width / 2, y + height / 2 - fontSize / 2, fontSize, text)
end

--- Render title menu
local function renderTitle()
    local title = "VEHICLE JUMPER CONFIGURATION"
    renderTextBox(UI_X, UI_Y, UI_WIDTH, 0.06, title, 0.025, {0, 0, 0, 0.9}, {1, 1, 0, 1}, RenderText.ALIGN_CENTER)
end

--- Render menu items
local function renderMenuItems()
    local visibleItems = math.min(ITEMS_PER_PAGE, #menuItems - menuState.scrollOffset)
    
    for i = 1, visibleItems do
        local itemIndex = i + menuState.scrollOffset
        local item = menuItems[itemIndex]
        
        local itemY = UI_Y + 0.06 + (i - 1) * ITEM_HEIGHT
        local isSelected = (menuState.selectedIndex == itemIndex)
        
        -- Item background
        local bgColor = isSelected and {0.2, 0.4, 0.8, 0.8} or {0, 0, 0, 0.6}
        drawFilledRect(UI_X, itemY, UI_WIDTH, ITEM_HEIGHT, unpack(bgColor))
        drawRect(UI_X, itemY, UI_WIDTH, ITEM_HEIGHT, 0.002, 1, 1, 1, 0.5)
        
        -- Label
        setTextColor(1, 1, 1, 1)
        setTextBold(false)
        setTextAlignment(RenderText.ALIGN_LEFT)
        renderText(UI_X + 0.01, itemY + ITEM_HEIGHT / 2 - 0.01, 0.018, item.label)
        
        -- Value
        local value = ConfigManager:getValue(item.key)
        local valueText = ""
        
        if item.options then
            valueText = tostring(value)
        else
            valueText = string.format("%.1f", value)
        end
        
        setTextColor(0.5, 1, 0.5, 1)
        setTextAlignment(RenderText.ALIGN_RIGHT)
        renderText(UI_X + UI_WIDTH - 0.01, itemY + ITEM_HEIGHT / 2 - 0.01, 0.018, valueText)
    end
end

--- Render instructions
local function renderInstructions()
    local instructY = UI_Y + 0.06 + ITEMS_PER_PAGE * ITEM_HEIGHT + 0.02
    
    setTextColor(1, 1, 1, 0.7)
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextFontSize(0.016)
    
    renderText(UI_X, instructY, 0.016, "UP/DOWN: Navigate")
    renderText(UI_X, instructY + 0.03, 0.016, "LEFT/RIGHT: Adjust value")
    renderText(UI_X, instructY + 0.06, 0.016, "R: Reset to default")
    renderText(UI_X, instructY + 0.09, 0.016, "SHIFT+N: Close menu")
end

--- Render info panel
local function renderInfoPanel()
    local infoY = UI_Y + UI_HEIGHT - 0.06
    
    local item = menuItems[menuState.selectedIndex]
    if item.options then
        local info = "Options: " .. table.concat(item.options, ", ")
        renderTextBox(UI_X, infoY, UI_WIDTH, 0.05, info, 0.016, {0, 0, 0, 0.8}, {1, 1, 0.5, 1})
    else
        local info = string.format("Range: %.1f - %.1f | Step: %.1f", item.min, item.max, item.step)
        renderTextBox(UI_X, infoY, UI_WIDTH, 0.05, info, 0.016, {0, 0, 0, 0.8}, {1, 1, 0.5, 1})
    end
end

-- ============================================================================
-- Fungsi Input Menu
-- ============================================================================

--- Navigate menu up
local function navigateUp()
    menuState.selectedIndex = menuState.selectedIndex - 1
    if menuState.selectedIndex < 1 then
        menuState.selectedIndex = #menuItems
    end
    
    -- Adjust scroll offset
    if menuState.selectedIndex <= menuState.scrollOffset then
        menuState.scrollOffset = math.max(0, menuState.selectedIndex - 1)
    end
end

--- Navigate menu down
local function navigateDown()
    menuState.selectedIndex = menuState.selectedIndex + 1
    if menuState.selectedIndex > #menuItems then
        menuState.selectedIndex = 1
    end
    
    -- Adjust scroll offset
    if menuState.selectedIndex > menuState.scrollOffset + ITEMS_PER_PAGE then
        menuState.scrollOffset = menuState.selectedIndex - ITEMS_PER_PAGE
    end
end

--- Adjust value ke kiri
local function adjustLeft()
    local item = menuItems[menuState.selectedIndex]
    local currentValue = ConfigManager:getValue(item.key)
    
    if item.options then
        -- Cycle ke pilihan sebelumnya
        local currentIndex = 1
        for i, opt in ipairs(item.options) do
            if opt == currentValue then
                currentIndex = i
                break
            end
        end
        currentIndex = currentIndex - 1
        if currentIndex < 1 then
            currentIndex = #item.options
        end
        ConfigManager:setValue(item.key, item.options[currentIndex])
    else
        -- Decrease numeric value
        local newValue = currentValue - item.step
        ConfigManager:setValueWithRange(item.key, newValue, item.min, item.max)
    end
end

--- Adjust value ke kanan
local function adjustRight()
    local item = menuItems[menuState.selectedIndex]
    local currentValue = ConfigManager:getValue(item.key)
    
    if item.options then
        -- Cycle ke pilihan berikutnya
        local currentIndex = 1
        for i, opt in ipairs(item.options) do
            if opt == currentValue then
                currentIndex = i
                break
            end
        end
        currentIndex = currentIndex + 1
        if currentIndex > #item.options then
            currentIndex = 1
        end
        ConfigManager:setValue(item.key, item.options[currentIndex])
    else
        -- Increase numeric value
        local newValue = currentValue + item.step
        ConfigManager:setValueWithRange(item.key, newValue, item.min, item.max)
    end
end

--- Reset ke default
local function resetToDefault()
    ConfigManager:resetToDefault()
    menuState.selectedIndex = 1
    menuState.scrollOffset = 0
end

-- ============================================================================
-- Public Methods
-- ============================================================================

--- Inisialisasi Menu UI
function MenuUI:init()
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] Menu UI initialized")
    end
end

--- Tampilkan menu
function MenuUI:show(vehicle)
    menuState.isVisible = true
    menuState.vehicle = vehicle
    menuState.selectedIndex = 1
    menuState.scrollOffset = 0
    
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] Menu displayed")
    end
end

--- Sembunyikan menu
function MenuUI:hide()
    menuState.isVisible = false
    menuState.vehicle = nil
    
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] Menu hidden")
    end
end

--- Check apakah menu visible
function MenuUI:isVisible()
    return menuState.isVisible
end

--- Render menu (dipanggil dari update loop)
function MenuUI:render()
    if not menuState.isVisible then
        return
    end
    
    -- Set UI coordinate system
    local origScale = getUIScale()
    setUIScale(origScale)
    
    -- Render background overlay
    drawFilledRect(0, 0, 1, 1, 0, 0, 0, 0.3)
    
    -- Render menu container
    drawFilledRect(UI_X, UI_Y, UI_WIDTH, UI_HEIGHT, unpack({0, 0, 0, 0.95}))
    drawRect(UI_X, UI_Y, UI_WIDTH, UI_HEIGHT, 0.004, 1, 1, 0.5, 1)
    
    -- Render menu elements
    renderTitle()
    renderMenuItems()
    renderInstructions()
    renderInfoPanel()
    
    -- Reset text state
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_LEFT)
end

--- Handle input menu
function MenuUI:handleInput(action, keyStatus)
    if not menuState.isVisible then
        return false
    end
    
    if keyStatus ~= InputAction.STATE_PRESSED then
        return false
    end
    
    if action == "VEHICLE_JUMPER_MENU_UP" or action == "AXIS_LOOK_UP_DOWN" then
        navigateUp()
        return true
    elseif action == "VEHICLE_JUMPER_MENU_DOWN" or action == "AXIS_LOOK_DOWN" then
        navigateDown()
        return true
    elseif action == "VEHICLE_JUMPER_MENU_LEFT" then
        adjustLeft()
        return true
    elseif action == "VEHICLE_JUMPER_MENU_RIGHT" then
        adjustRight()
        return true
    elseif action == "VEHICLE_JUMPER_MENU_RESET" then
        resetToDefault()
        return true
    end
    
    return false
end

--- Update menu
function MenuUI:update(deltaTime)
    self:render()
end

return MenuUI
