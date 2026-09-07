-- ============================================================================
-- inputBindings.lua
-- Input actions configuration untuk Vehicle Jumper MOD
-- ============================================================================

local InputBindings = {}

-- Define default key bindings
InputBindings.defaultBindings = {
    -- Jump action
    VEHICLE_JUMPER_JUMP = {
        key1 = "n",
        key2 = nil,
        description = "Vehicle Jumper - Jump"
    },
    
    -- Menu actions
    VEHICLE_JUMPER_MENU = {
        key1 = "shift+n",
        key2 = nil,
        description = "Vehicle Jumper - Toggle Menu"
    },
    
    VEHICLE_JUMPER_MENU_UP = {
        key1 = "up",
        key2 = nil,
        description = "Vehicle Jumper - Menu Navigate Up"
    },
    
    VEHICLE_JUMPER_MENU_DOWN = {
        key1 = "down",
        key2 = nil,
        description = "Vehicle Jumper - Menu Navigate Down"
    },
    
    VEHICLE_JUMPER_MENU_LEFT = {
        key1 = "left",
        key2 = nil,
        description = "Vehicle Jumper - Menu Value Decrease"
    },
    
    VEHICLE_JUMPER_MENU_RIGHT = {
        key1 = "right",
        key2 = nil,
        description = "Vehicle Jumper - Menu Value Increase"
    },
    
    VEHICLE_JUMPER_MENU_RESET = {
        key1 = "r",
        key2 = nil,
        description = "Vehicle Jumper - Reset to Default"
    }
}

--- Load input bindings
function InputBindings:load()
    -- Bindings akan di-load dari modDesc.xml
    return true
end

--- Get binding untuk action
function InputBindings:getBinding(actionName)
    return self.defaultBindings[actionName]
end

--- List semua bindings
function InputBindings:listBindings()
    local bindings = {}
    for action, binding in pairs(self.defaultBindings) do
        table.insert(bindings, {action = action, binding = binding})
    end
    return bindings
end

return InputBindings
