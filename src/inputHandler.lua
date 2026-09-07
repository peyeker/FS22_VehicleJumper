-- ============================================================================
-- inputHandler.lua
-- Menangani input keyboard untuk trigger jump dan menu konfigurasi
-- ============================================================================

local InputHandler = {}

-- Reference ke modules
local VehicleJumper = require("src/vehicleJumper")
local ConfigManager = require("src/configManager")
local MenuUI = require("src/menuUI")

-- State untuk menu
local menuActive = false
local selectedVehicle = nil

-- ============================================================================
-- Fungsi Utilitas
-- ============================================================================

--- Ambil kendaraan yang sedang dikontrol pemain
local function getControlledVehicle()
    if g_currentMission == nil or g_currentMission.controlledVehicle == nil then
        return nil
    end
    return g_currentMission.controlledVehicle
end

--- Validasi apakah kendaraan dapat melompat
local function isVehicleJumpable(vehicle)
    if vehicle == nil then
        return false
    end
    
    -- Pastikan kendaraan adalah wheeled atau tracked vehicle
    if vehicle.wheelObjects == nil and vehicle.tracks == nil then
        return false
    end
    
    -- Cegah lompatan berulang
    if VehicleJumper:isVehicleJumping(vehicle) then
        return false
    end
    
    return true
end

-- ============================================================================
-- Input Action Callbacks
-- ============================================================================

--- Callback untuk tombol Jump (N)
local function onVehicleJumperJumpPressed(actionName, keyStatus, arg3, arg4, arg5)
    if keyStatus ~= InputAction.STATE_PRESSED then
        return
    end
    
    selectedVehicle = getControlledVehicle()
    
    if selectedVehicle == nil then
        if ConfigManager:getValue("enableDebug") then
            print("[VehicleJumper] No vehicle controlled")
        end
        return
    end
    
    if not isVehicleJumpable(selectedVehicle) then
        if ConfigManager:getValue("enableDebug") then
            print("[VehicleJumper] Vehicle cannot jump at this time")
        end
        return
    end
    
    -- Trigger lompatan
    VehicleJumper:startJump(selectedVehicle)
end

--- Callback untuk tombol Menu (Shift + N)
local function onVehicleJumperMenuPressed(actionName, keyStatus, arg3, arg4, arg5)
    if keyStatus ~= InputAction.STATE_PRESSED then
        return
    end
    
    selectedVehicle = getControlledVehicle()
    
    if selectedVehicle == nil then
        if ConfigManager:getValue("enableDebug") then
            print("[VehicleJumper] No vehicle controlled")
        end
        return
    end
    
    -- Toggle menu
    menuActive = not menuActive
    
    if menuActive then
        MenuUI:show(selectedVehicle)
        if ConfigManager:getValue("enableDebug") then
            print("[VehicleJumper] Menu opened")
        end
    else
        MenuUI:hide()
        ConfigManager:saveToFile()
        if ConfigManager:getValue("enableDebug") then
            print("[VehicleJumper] Menu closed - Config saved")
        end
    end
end

-- ============================================================================
-- Public Methods
-- ============================================================================

--- Inisialisasi Input Handler
function InputHandler:init()
    if g_inputBinding == nil then
        print("[VehicleJumper] ERROR: g_inputBinding not available")
        return false
    end
    
    -- Register input actions
    g_inputBinding:registerActionEvent(
        "VEHICLE_JUMPER_JUMP",
        self,
        onVehicleJumperJumpPressed,
        false,
        true,
        false,
        true
    )
    
    g_inputBinding:registerActionEvent(
        "VEHICLE_JUMPER_MENU",
        self,
        onVehicleJumperMenuPressed,
        false,
        true,
        false,
        true
    )
    
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] Input Handler initialized")
        print("  - Jump Action: N")
        print("  - Menu Action: Shift + N")
    end
    
    return true
end

--- Update input handler (jika diperlukan untuk continuous input)
function InputHandler:update(deltaTime)
    -- Placeholder untuk future continuous input handling
end

--- Check apakah menu aktif
function InputHandler:isMenuActive()
    return menuActive
end

--- Set menu state
function InputHandler:setMenuActive(active)
    menuActive = active
end

--- Get selected vehicle
function InputHandler:getSelectedVehicle()
    return selectedVehicle
end

--- Set selected vehicle
function InputHandler:setSelectedVehicle(vehicle)
    selectedVehicle = vehicle
end

--- Reset input state
function InputHandler:reset()
    menuActive = false
    selectedVehicle = nil
    MenuUI:hide()
    
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] Input Handler reset")
    end
end

return InputHandler
