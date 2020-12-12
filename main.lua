--[[
    GD50
    Angry Birds

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Released by Rovio in 2009, Angry Birds took the mobile gaming scene by storm back
    when it was still arguably in its infancy. Using the simple gameplay mechanic of
    slingshotting birds into fortresses of various materials housing targeted pigs,
    Angry Birds succeeded with its optimized formula for on-the-go gameplay. It's an
    excellent showcase of the ubiquitous Box2D physics library, the most widely used
    physics library of its kind, which is also open source.

    Music credit:
    https://freesound.org/people/tyops/sounds/348166/

    Artwork credit:
    https://opengameart.org/content/physics-assets
]]

require 'src/Dependencies'

local keys_pressed = {}
local buttons_pressed = {}
local buttons_released = {}
local wheel_movement = 0

function love.load()
    math.randomseed(os.time())
    -- Note: when using a linear filter or a zoom (scale factor),
    -- there is a bug where the pixel of adjacent quads can "bleed" into other quads.
    -- A 1 pixel transparent border between the textures in the spritesheet can fix this.
    love.graphics.setDefaultFilter('linear', 'linear')
    love.window.setTitle('Angry 50')

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        vsync = true,
        resizable = true
    })

    -- make the mouse cursor invisible (use a mouse cursor texture)
    -- grab the mouse so it cannot leave the game window
    love.mouse.setVisible(false)
    love.mouse.setGrabbed(true)

    love.physics.setMeter(PIXEL_PER_METER)

    gStateMachine = StateMachine {
        ['start'] = function() return StartState() end,
        ['level-select'] = function() return LevelSelectState() end,
        ['play'] = function() return PlayState() end
    }
    gStateMachine:change('start')

    gSounds['music']:setLooping(true)
    gSounds['music']:play()
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    if love.keyboard.isDown('lalt') and key == 'return' then
        push:switchFullscreen()
        return
    end
    keys_pressed[key] = true
end

function love.mousepressed(x, y, button)
    buttons_pressed[button] = true
    x, y = push:toGame(x, y)
    buttons_pressed['x'] = x
    buttons_pressed['y'] = y
end

function love.mousereleased(x, y, button)
    buttons_released[button] = true
    x, y = push:toGame(x, y)
    buttons_released['x'] = x
    buttons_released['y'] = y
end

function love.wheelmoved(x, y)
    -- y is the number of mouse wheel ticks. Positive values indicate upward movement.
    wheel_movement = y
end

function keyboardWasPressed(key)
    if type(key) == 'table' then
        for _, v in pairs(key) do
            if keys_pressed[v] then
                return true
            end
        end
    else
        return keys_pressed[key]
    end
    return false
end

function getKeysPressed()
    return keys_pressed
end

function getMouseClick()
    return buttons_pressed
end

function getMouseReleased()
    return buttons_released
end

function getWheelMovement()
    return wheel_movement
end

function love.update(dt)
    dt = math.min(dt, 0.07)

    gStateMachine:update(dt)

    keys_pressed = {}
    buttons_pressed = {}
    buttons_released = {}
    wheel_movement = 0
end

function love.draw()
    push:start()
    gStateMachine:render()
    -- render mouse cursor
    local mouse_x, mouse_y = push:toGame(love.mouse.getPosition())
    local mouse_texture_scale = 2
    love.graphics.draw(gTextures['ui-assets'], gFrames['ui-assets'][FRAME_ID_MOUSE_CURSOR],
        mouse_x, mouse_y, 0, mouse_texture_scale, mouse_texture_scale)
    push:finish()
end
