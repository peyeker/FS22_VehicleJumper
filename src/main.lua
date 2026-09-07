-- ============================================================================
-- main.lua
-- Entry point utama untuk MOD Vehicle Jumper
-- Menghubungkan semua modules dan mengatur integration dengan FS22
-- ============================================================================

local VehicleJumper = require("src/vehicleJumper")
local ConfigManager = require("src/configManager")
local InputHandler = require("src/inputHandler")
local MenuUI = require("src/menuUI")

-- ============================================================================
-- MOD Entry Point
-- ============================================================================

--- Initialize MOD
local function initMod()
    print("[VehicleJumper] MOD initialization started...")
    
    -- Init ConfigManager (harus pertama)
    ConfigManager:init()
    local debugMode = ConfigManager:getValue("enableDebug")
    
    if debugMode then
        print("[VehicleJumper] Debug mode enabled")
    end
    
    -- Init VehicleJumper mechanics
    VehicleJumper:init()
    if debugMode then
        print("[VehicleJumper] Vehicle Jumper core initialized")
    end
    
    -- Init MenuUI
    MenuUI:init()
    if debugMode then
        print("[VehicleJumper] Menu UI initialized")
    end
    
    -- Init InputHandler (harus terakhir setelah semua module)
    InputHandler:init()
    if debugMode then
        print("[VehicleJumper] Input Handler initialized")
    end
    
    print("[VehicleJumper] MOD initialization completed successfully")
end

--- Update loop (dipanggil setiap frame)
local function updateMod(deltaTime)
    if g_currentMission == nil then
        return
    end
    
    -- Update jump mechanics
    VehicleJumper:update(deltaTime)
    
    -- Update UI menu
    if MenuUI:isVisible() then
        MenuUI:update(deltaTime)
    end
end

--- Cleanup MOD
local function cleanupMod()
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] MOD cleanup started...")
    end
    
    -- Reset states
    VehicleJumper:resetAll()
    InputHandler:reset()
    
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] MOD cleanup completed")
    end
end

-- ============================================================================
-- FS22 Integration - Vehicle Jumper Spec
-- ============================================================================

local VehicleJumperSpec = {}

--- Initiate MOD ketika game dimulai
function VehicleJumperSpec:load(vehicle, xmlFile, baseMissionDirectory, customEnvironment, vehicleType)
    -- MOD initialization happens once when game starts
    if not self.modInitialized then
        initMod()
        self.modInitialized = true
    end
end

--- Update MOD setiap frame
function VehicleJumperSpec:update(vehicle, superFunc, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    if superFunc then
        superFunc(self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
    end
    
    updateMod(dt)
end

--- Cleanup ketika vehicle dihapus
function VehicleJumperSpec:delete(vehicle, superFunc)
    if superFunc then
        superFunc(self)
    end
    
    cleanupMod()
end

-- ============================================================================
-- Register Event Listeners
-- ============================================================================

--- Event: Masuki kendaraan
local function onEnterVehicle()
    local vehicle = g_currentMission.controlledVehicle
    if vehicle and ConfigManager:getValue("enableDebug") then
        print(string.format("[VehicleJumper] Entered vehicle: %s", vehicle:getName()))
    end
end

--- Event: Keluar dari kendaraan
local function onExitVehicle()
    local vehicle = g_currentMission.lastControlledVehicle
    if vehicle then
        -- Stop jump jika sedang melompat
        VehicleJumper:stopJump(vehicle)
        
        -- Hide menu
        if MenuUI:isVisible() then
            MenuUI:hide()
            InputHandler:setMenuActive(false)
        end
        
        if ConfigManager:getValue("enableDebug") then
            print(string.format("[VehicleJumper] Exited vehicle: %s", vehicle:getName()))
        end
    end
end

--- Event: Pause game
local function onGamePaused()
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] Game paused")
    end
end

--- Event: Resume game
local function onGameResumed()
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] Game resumed")
    end
end

-- ============================================================================
-- Setup Global Hooks
-- ============================================================================

--- Setup MOD hooks dengan game engine
local function setupGameHooks()
    if g_currentMission == nil then
        print("[VehicleJumper] ERROR: g_currentMission not available")
        return false
    end
    
    -- Register event listeners
    g_messageCenter:subscribe(MessageType.VEHICLE_ENTER, onEnterVehicle)
    g_messageCenter:subscribe(MessageType.VEHICLE_EXIT, onExitVehicle)
    
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] Game hooks registered")
    end
    
    return true
end

-- ============================================================================
-- Main MOD Entry Point (dipanggil saat MOD dimuat)
-- ============================================================================

print("\n========================================")
print("Vehicle Jumper MOD v1.0.0")
print("Author: peyeker")
print("========================================\n")

-- Setup game hooks
setupGameHooks()

-- Initialize MOD
initMod()

-- Export functions untuk external use
return {
    VehicleJumper = VehicleJumper,
    ConfigManager = ConfigManager,
    InputHandler = InputHandler,
    MenuUI = MenuUI,
    initMod = initMod,
    updateMod = updateMod,
    cleanupMod = cleanupMod
}
