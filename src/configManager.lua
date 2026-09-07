-- ============================================================================
-- configManager.lua
-- Mengelola konfigurasi MOD Vehicle Jumper dengan persistensi data
-- ============================================================================

local ConfigManager = {}

-- Path untuk menyimpan file konfigurasi
local CONFIG_FILE = getUserProfileAppPath() .. "modSettings/FS22_VehicleJumper_config.json"

-- Konfigurasi default
local DEFAULT_CONFIG = {
    -- Mekanik Loncat
    jumpHeight = 15,              -- Ketinggian maksimal lompatan (meter)
    jumpForce = 50,               -- Kekuatan lompatan awal
    jumpDuration = 2,             -- Durasi lompatan (detik)
    
    -- Rotasi
    rotationSpeed = 180,          -- Kecepatan rotasi (derajat/detik)
    rotationAxis = "left",        -- Arah rotasi: "left" atau "right"
    rotationTiming = 0.5,         -- Delay sebelum rotasi dimulai (fraksi dari jumpDuration)
    rotationDegrees = 360,        -- Total derajat rotasi
    
    -- Gerakan Lateral
    lateralDirection = "forward",  -- Arah gerakan: "forward", "backward", atau "none"
    lateralForce = 20,            -- Kekuatan gerakan lateral
    
    -- UI
    showMenuOnStartup = false,    -- Tampilkan menu saat MOD dimuat
    enableDebug = false,          -- Debug mode untuk logging
}

-- Konfigurasi aktif (cache di memory)
ConfigManager.config = {}

-- ============================================================================
-- Fungsi Utilitas
-- ============================================================================

--- Memastikan direktori konfigurasi ada
local function ensureConfigDirectory()
    local configDir = getUserProfileAppPath() .. "modSettings"
    if not fileExists(configDir) then
        createDirectory(configDir)
    end
end

--- Membaca file JSON sederhana (fallback jika json library tidak tersedia)
local function parseSimpleJson(jsonString)
    local result = {}
    
    -- Parse key-value pairs
    for key, value in string.gmatch(jsonString, '"([^"]+)"%s*:%s*([^,}]+)') do
        -- Coba convert ke number
        local numValue = tonumber(value)
        if numValue then
            result[key] = numValue
        elseif value == "true" then
            result[key] = true
        elseif value == "false" then
            result[key] = false
        else
            -- String value (hapus quotes)
            result[key] = string.gsub(value, '"', '')
        end
    end
    
    return result
end

--- Membuat JSON string dari table
local function tableToJson(tbl)
    local json = "{"
    local first = true
    
    for key, value in pairs(tbl) do
        if not first then json = json .. "," end
        first = false
        
        json = json .. '"' .. key .. '":'
        
        if type(value) == "number" then
            json = json .. value
        elseif type(value) == "boolean" then
            json = json .. (value and "true" or "false")
        else
            json = json .. '"' .. tostring(value) .. '"'
        end
    end
    
    json = json .. "}"
    return json
end

-- ============================================================================
-- Public Methods
-- ============================================================================

--- Inisialisasi Config Manager
function ConfigManager:init()
    if self.config.initialized then
        return
    end
    
    self.config = {}
    
    -- Copy default config
    for key, value in pairs(DEFAULT_CONFIG) do
        self.config[key] = value
    end
    
    -- Baca konfigurasi dari file
    self:loadFromFile()
    
    self.config.initialized = true
    
    if DEFAULT_CONFIG.enableDebug then
        print("[VehicleJumper] Config Manager initialized")
        self:printConfig()
    end
end

--- Baca konfigurasi dari file
function ConfigManager:loadFromFile()
    ensureConfigDirectory()
    
    if fileExists(CONFIG_FILE) then
        local file = io.open(CONFIG_FILE, "r")
        if file then
            local content = file:read("*a")
            file:close()
            
            local loadedConfig = parseSimpleJson(content)
            
            -- Merge dengan default config (untuk backward compatibility)
            for key, value in pairs(loadedConfig) do
                if DEFAULT_CONFIG[key] ~= nil then
                    self.config[key] = value
                end
            end
            
            if self.config.enableDebug then
                print("[VehicleJumper] Config loaded from file")
            end
            
            return true
        end
    end
    
    if self.config.enableDebug then
        print("[VehicleJumper] No config file found, using defaults")
    end
    
    return false
end

--- Simpan konfigurasi ke file
function ConfigManager:saveToFile()
    ensureConfigDirectory()
    
    local jsonString = tableToJson(self.config)
    
    local file = io.open(CONFIG_FILE, "w")
    if file then
        file:write(jsonString)
        file:close()
        
        if self.config.enableDebug then
            print("[VehicleJumper] Config saved to file")
        end
        
        return true
    end
    
    print("[VehicleJumper] ERROR: Failed to save config file")
    return false
end

--- Ambil nilai konfigurasi
function ConfigManager:getValue(key)
    if self.config[key] == nil then
        print("[VehicleJumper] WARNING: Config key '" .. key .. "' not found")
        return DEFAULT_CONFIG[key]
    end
    return self.config[key]
end

--- Set nilai konfigurasi
function ConfigManager:setValue(key, value)
    if DEFAULT_CONFIG[key] == nil then
        print("[VehicleJumper] WARNING: Unknown config key '" .. key .. "'")
        return false
    end
    
    self.config[key] = value
    
    if self.config.enableDebug then
        print("[VehicleJumper] Config updated: " .. key .. " = " .. tostring(value))
    end
    
    return true
end

--- Ambil seluruh konfigurasi
function ConfigManager:getAll()
    return self.config
end

--- Reset ke default
function ConfigManager:resetToDefault()
    self.config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        self.config[key] = value
    end
    self:saveToFile()
    
    if self.config.enableDebug then
        print("[VehicleJumper] Config reset to defaults")
    end
end

--- Print konfigurasi (untuk debugging)
function ConfigManager:printConfig()
    print("[VehicleJumper] Current Configuration:")
    for key, value in pairs(self.config) do
        print(string.format("  %s = %s", key, tostring(value)))
    end
end

--- Validasi range nilai
function ConfigManager:setValueWithRange(key, value, minVal, maxVal)
    if DEFAULT_CONFIG[key] == nil then
        print("[VehicleJumper] WARNING: Unknown config key '" .. key .. "'")
        return false
    end
    
    -- Clamp value ke range
    local clampedValue = math.max(minVal, math.min(maxVal, value))
    
    if clampedValue ~= value and self.config.enableDebug then
        print("[VehicleJumper] Value clamped: " .. key .. " = " .. clampedValue .. 
              " (requested: " .. value .. ")")
    end
    
    self.config[key] = clampedValue
    return true
end

return ConfigManager
