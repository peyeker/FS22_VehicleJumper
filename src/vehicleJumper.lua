-- ============================================================================
-- vehicleJumper.lua
-- Logic inti untuk mekanik loncat, rotasi, dan gerakan kendaraan
-- ============================================================================

local VehicleJumper = {}

-- Reference ke ConfigManager
local ConfigManager = require("src/configManager")

-- State untuk setiap kendaraan yang sedang melompat
local jumpStates = {}

-- ============================================================================
-- Struktur Data Jump State
-- ============================================================================
-- jumpStates[vehicleId] = {
--     isJumping = boolean,
--     jumpStartTime = float,
--     jumpDuration = float,
--     initialPosition = {x, y, z},
--     initialRotation = {x, y, z},
--     jumpHeight = float,
--     jumpForce = float,
--     rotationSpeed = float,
--     rotationAxis = string ("left", "right", "forward", "backward"),
--     rotationDegrees = float,
--     rotationStartTime = float,
--     lateralDirection = string,
--     lateralForce = float
-- }

-- ============================================================================
-- Fungsi Utilitas
-- ============================================================================

--- Hitung posisi menggunakan parabolic trajectory
local function calculateParabolicPosition(startHeight, maxHeight, duration, elapsedTime)
    if elapsedTime >= duration then
        return startHeight, 0 -- Sudah kembali ke posisi awal
    end
    
    -- Normalized time (0 to 1)
    local t = elapsedTime / duration
    
    -- Parabolic equation: y = 4 * maxHeight * t * (1 - t)
    local height = startHeight + (maxHeight * 4 * t * (1 - t))
    
    -- Velocity pada saat ini (turunan dari height)
    local velocity = (maxHeight * 4 * (1 - 2 * t)) / duration
    
    return height, velocity
end

--- Hitung rotasi berdasarkan waktu
local function calculateRotation(startRotation, rotationAxis, rotationSpeed, elapsedTime, rotationDegrees)
    local rotation = {startRotation[1], startRotation[2], startRotation[3]}
    local totalRotation = (rotationSpeed * elapsedTime) * math.pi / 180 -- Convert ke radian
    
    -- Clamp rotasi ke total derajat yang diinginkan
    local maxRotation = rotationDegrees * math.pi / 180
    totalRotation = math.min(totalRotation, maxRotation)
    
    if rotationAxis == "left" or rotationAxis == "right" then
        -- Rotasi pada sumbu Y (vertical axis)
        rotation[2] = startRotation[2] + (rotationAxis == "left" and totalRotation or -totalRotation)
    elseif rotationAxis == "forward" or rotationAxis == "backward" then
        -- Rotasi pada sumbu X (front-back axis)
        rotation[1] = startRotation[1] + (rotationAxis == "forward" and totalRotation or -totalRotation)
    end
    
    return rotation
end

--- Hitung gerakan lateral (maju/mundur)
local function calculateLateralMovement(direction, force, elapsedTime, duration, vehicle)
    if direction == "none" then
        return {0, 0, 0}
    end
    
    -- Taper movement force dari 1 menjadi 0 selama jump
    local t = math.min(elapsedTime / duration, 1)
    local forceFactor = 1 - (t * t) -- Quadratic falloff
    
    local movement = {0, 0, 0}
    local velocity = force * forceFactor
    
    -- Dapatkan direktur kendaraan
    local dirX, dirY, dirZ = localDirectionToWorld(vehicle, 0, 0, 1)
    local rightX, rightY, rightZ = localDirectionToWorld(vehicle, 1, 0, 0)
    
    if direction == "forward" then
        movement[1] = dirX * velocity * elapsedTime
        movement[2] = dirY * velocity * elapsedTime
        movement[3] = dirZ * velocity * elapsedTime
    elseif direction == "backward" then
        movement[1] = -dirX * velocity * elapsedTime
        movement[2] = -dirY * velocity * elapsedTime
        movement[3] = -dirZ * velocity * elapsedTime
    end
    
    return movement
end

-- ============================================================================
-- Public Methods
-- ============================================================================

--- Inisialisasi Vehicle Jumper
function VehicleJumper:init()
    ConfigManager:init()
    
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] Vehicle Jumper initialized")
    end
end

--- Mulai lompatan untuk kendaraan
function VehicleJumper:startJump(vehicle)
    if vehicle == nil then
        print("[VehicleJumper] ERROR: Vehicle is nil")
        return false
    end
    
    local vehicleId = vehicle.id or tostring(vehicle)
    
    -- Cegah lompatan ganda
    if jumpStates[vehicleId] and jumpStates[vehicleId].isJumping then
        return false
    end
    
    -- Ambil konfigurasi
    local jumpHeight = ConfigManager:getValue("jumpHeight")
    local jumpForce = ConfigManager:getValue("jumpForce")
    local jumpDuration = ConfigManager:getValue("jumpDuration")
    local rotationSpeed = ConfigManager:getValue("rotationSpeed")
    local rotationAxis = ConfigManager:getValue("rotationAxis")
    local rotationTiming = ConfigManager:getValue("rotationTiming")
    local rotationDegrees = ConfigManager:getValue("rotationDegrees")
    local lateralDirection = ConfigManager:getValue("lateralDirection")
    local lateralForce = ConfigManager:getValue("lateralForce")
    
    -- Ambil posisi dan rotasi awal
    local x, y, z = getWorldTranslation(vehicle)
    local rx, ry, rz = getRotation(vehicle)
    
    -- Buat jump state baru
    jumpStates[vehicleId] = {
        isJumping = true,
        jumpStartTime = g_currentMission.time,
        jumpDuration = jumpDuration,
        initialPosition = {x, y, z},
        initialRotation = {rx, ry, rz},
        jumpHeight = jumpHeight,
        jumpForce = jumpForce,
        rotationSpeed = rotationSpeed,
        rotationAxis = rotationAxis,
        rotationDegrees = rotationDegrees,
        rotationStartTime = g_currentMission.time + (rotationTiming * jumpDuration),
        lateralDirection = lateralDirection,
        lateralForce = lateralForce,
        vehicle = vehicle
    }
    
    if ConfigManager:getValue("enableDebug") then
        print(string.format("[VehicleJumper] Jump started - Height: %.2f, Duration: %.2f", 
              jumpHeight, jumpDuration))
    end
    
    return true
end

--- Update jump state (dipanggil setiap frame)
function VehicleJumper:update(deltaTime)
    local currentTime = g_currentMission.time
    
    for vehicleId, jumpState in pairs(jumpStates) do
        if not jumpState.isJumping then
            jumpStates[vehicleId] = nil
            goto continue
        end
        
        local vehicle = jumpState.vehicle
        if vehicle == nil or vehicle:getStoreItem() == nil then
            jumpStates[vehicleId] = nil
            goto continue
        end
        
        local elapsedTime = (currentTime - jumpState.jumpStartTime) / 1000 -- Convert ms ke seconds
        
        -- Cek apakah jump sudah selesai
        if elapsedTime >= jumpState.jumpDuration then
            -- Reset ke posisi dan rotasi awal
            setWorldTranslation(vehicle, jumpState.initialPosition[1], 
                              jumpState.initialPosition[2], jumpState.initialPosition[3])
            setRotation(vehicle, jumpState.initialRotation[1], 
                       jumpState.initialRotation[2], jumpState.initialRotation[3])
            
            jumpState.isJumping = false
            jumpStates[vehicleId] = nil
            
            if ConfigManager:getValue("enableDebug") then
                print("[VehicleJumper] Jump completed")
            end
            
            goto continue
        end
        
        -- Hitung posisi vertikal (parabolic trajectory)
        local currentHeight, velocity = calculateParabolicPosition(
            jumpState.initialPosition[2],
            jumpState.jumpHeight,
            jumpState.jumpDuration,
            elapsedTime
        )
        
        -- Hitung rotasi (mulai setelah rotationTiming)
        local rotation = {jumpState.initialRotation[1], jumpState.initialRotation[2], 
                         jumpState.initialRotation[3]}
        if currentTime >= jumpState.rotationStartTime then
            local rotationElapsed = (currentTime - jumpState.rotationStartTime) / 1000
            rotation = calculateRotation(
                jumpState.initialRotation,
                jumpState.rotationAxis,
                jumpState.rotationSpeed,
                rotationElapsed,
                jumpState.rotationDegrees
            )
        end
        
        -- Hitung gerakan lateral
        local lateralMovement = calculateLateralMovement(
            jumpState.lateralDirection,
            jumpState.lateralForce,
            elapsedTime,
            jumpState.jumpDuration,
            vehicle
        )
        
        -- Aplikasikan posisi baru
        local newX = jumpState.initialPosition[1] + lateralMovement[1]
        local newY = currentHeight
        local newZ = jumpState.initialPosition[3] + lateralMovement[3]
        
        setWorldTranslation(vehicle, newX, newY, newZ)
        setRotation(vehicle, rotation[1], rotation[2], rotation[3])
        
        ::continue::
    end
end

--- Hentikan jump untuk kendaraan tertentu
function VehicleJumper:stopJump(vehicle)
    if vehicle == nil then
        return false
    end
    
    local vehicleId = vehicle.id or tostring(vehicle)
    
    if jumpStates[vehicleId] then
        jumpStates[vehicleId].isJumping = false
        jumpStates[vehicleId] = nil
        
        if ConfigManager:getValue("enableDebug") then
            print("[VehicleJumper] Jump stopped")
        end
        
        return true
    end
    
    return false
end

--- Cek apakah kendaraan sedang melompat
function VehicleJumper:isVehicleJumping(vehicle)
    if vehicle == nil then
        return false
    end
    
    local vehicleId = vehicle.id or tostring(vehicle)
    return jumpStates[vehicleId] ~= nil and jumpStates[vehicleId].isJumping
end

--- Dapatkan info jump state
function VehicleJumper:getJumpState(vehicle)
    if vehicle == nil then
        return nil
    end
    
    local vehicleId = vehicle.id or tostring(vehicle)
    return jumpStates[vehicleId]
end

--- Reset semua jump states
function VehicleJumper:resetAll()
    jumpStates = {}
    
    if ConfigManager:getValue("enableDebug") then
        print("[VehicleJumper] All jump states reset")
    end
end

return VehicleJumper
