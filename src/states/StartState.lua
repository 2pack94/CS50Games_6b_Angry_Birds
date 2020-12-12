--[[
    GD50
    Angry Birds

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

StartState = Class{__includes = BaseState}

function StartState:enter(params)
    if params then
        -- if entered from LevelSelectState, reuse the scene
        self.world = params.world
        self.entities = params.entities
        self.background = params.background
    else
        -- create a new scene with Entities in the background
        -- instantiate game elements defined in game_element_defs.lua
        self.world = love.physics.newWorld(0, GRAVITY)
        self.entities = {}
        self.background = Background(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
        local entity_names = {'projectile', 'enemy'}
        for _ = 1, 200 do
            local entity_name = entity_names[math.random(#entity_names)]
            local entity_def = deepcopy(GAME_ELEMENT_DEFS[entity_name])
            -- override mask, so the projectiles collide with each other
            -- override frame_id so projectiles can have all possible projectile textures
            entity_def.bodies[1].mask = 0xFF
            if entity_name == 'projectile' then
                entity_def.bodies[1].frame_id = FRAME_IDS_PROJECTILE
            end
            table.extend(entity_def, {world = self.world,
                x = math.random(ALIEN_SIZE / 2, VIRTUAL_WIDTH - ALIEN_SIZE / 2),
                y = math.random(ALIEN_SIZE / 2, VIRTUAL_HEIGHT - ALIEN_SIZE / 2)
            })
            local entity = Entity(entity_def)
            entity.is_invulnerable = true       -- so no entity gets destroyed in the scene
            table.insert(self.entities, entity)
        end
        -- boundary. No local reference needed.
        local boundary_body = love.physics.newBody(self.world, 0, 0, 'static')
        local boundary_shape = love.physics.newChainShape(false, 0, 0, 0, VIRTUAL_HEIGHT, VIRTUAL_WIDTH, VIRTUAL_HEIGHT, VIRTUAL_WIDTH, 0)
        love.physics.newFixture(boundary_body, boundary_shape)
    end
end

function StartState:update(dt)
    if keyboardWasPressed('escape') then
        love.event.quit()
    elseif getMouseClick()[1] or keyboardWasPressed({'return', 'space'}) then
        gSounds['confirm']:play()
        -- go the the level select screen and keep the current scene in the background
        gStateMachine:change('level-select', {
            world = self.world,
            entities = self.entities,
            background = self.background
        })
        return
    end

    self.world:update(dt)
end

function StartState:render()
    self.background:render()

    for _, entity in pairs(self.entities) do
        entity:render()
    end

    -- render title text
    love.graphics.setColor(64/255, 64/255, 64/255, 200/255)
    local title_rect_width, title_rect_height = 768, 432
    love.graphics.rectangle('fill', VIRTUAL_WIDTH / 2 - title_rect_width / 2, VIRTUAL_HEIGHT / 2 - title_rect_height / 2,
        title_rect_width, title_rect_height, 3)

    love.graphics.setColor(200/255, 200/255, 200/255, 255/255)
    love.graphics.setFont(gFonts['huge'])
    love.graphics.printf('Angry 50', 0, VIRTUAL_HEIGHT / 2 - 80, VIRTUAL_WIDTH, 'center')

    love.graphics.setColor(200/255, 200/255, 200/255, 255/255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Click to start!', 0, VIRTUAL_HEIGHT / 2 + 80, VIRTUAL_WIDTH, 'center')
end
