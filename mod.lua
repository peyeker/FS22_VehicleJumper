-- ============================================================================
-- mod.lua
-- Konfigurasi MOD Vehicle Jumper untuk Farming Simulator 22
-- File ini dimuat oleh FS22 engine saat startup
-- ============================================================================

--- Tentukan lokasi root MOD
local modDirectory = g_currentModDirectory

--- Load utama MOD
local function loadMod(mission)
    print("[VehicleJumper] Memulai loading MOD...")
    
    -- Load main.lua
    local mainScript = io.open(modDirectory .. "src/main.lua", "r")
    if mainScript then
        mainScript:close()
        -- Main script akan di-load oleh FS22 engine
        print("[VehicleJumper] Main script found and ready")
    else
        print("[VehicleJumper] ERROR: main.lua not found!")
        return false
    end
    
    print("[VehicleJumper] MOD loaded successfully")
    return true
end

--- Unload MOD saat exit
local function unloadMod()
    print("[VehicleJumper] Unloading MOD...")
    -- Cleanup akan dilakukan oleh main.lua
    print("[VehicleJumper] MOD unloaded")
end

-- ============================================================================
-- MOD Initialization
-- ============================================================================

-- Export MOD functions
return {
    version = "1.0.0",
    author = "peyeker",
    title = "Vehicle Jumper",
    description = "Membuat kendaraan melompat, berputar, dan kembali ke posisi awal",
    
    -- Load function dipanggil saat MOD dimuat
    load = function(mission)
        return loadMod(mission)
    end,
    
    -- Unload function dipanggil saat MOD dibongkar
    unload = function()
        return unloadMod()
    end,
    
    -- Update function dipanggil setiap frame
    update = function(deltaTime)
        if g_currentMission and g_currentMission.controlledVehicle then
            -- Update logic dari main.lua
        end
    end
}
