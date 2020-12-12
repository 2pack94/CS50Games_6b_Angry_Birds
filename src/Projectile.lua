--[[
    The Projectile class inherits from Entity.
    It handles the different projectile types and passes their definitions to the Entity class.
    implemented projectile types: normal, heavy (higher density)
]]

Projectile = Class{__includes = Entity}

function Projectile:init(x, y, world, proj_type)
    local def = {world = world, x = x, y = y}
    -- the 'projectile' definition in GAME_ELEMENT_DEFS corresponds to the 'normal' projectile.
    -- To create other projectile types, this definition is modified.
    table.extend(def, deepcopy(GAME_ELEMENT_DEFS['projectile']))
    if proj_type == 'heavy' then
        def.bodies[1].frame_id = FRAME_ID_PROJECTILE_HEAVY
        def.bodies[1].density = 3
    end
    -- init parent
    Entity.init(self, def)
end
