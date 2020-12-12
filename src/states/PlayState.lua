--[[
    GD50
    Angry Birds

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayState = Class{__includes = BaseState}

-- enter from LevelSelectState
function PlayState:enter(level_nr)
    -- instantiate the specified level with the corresponding level definitions
    self.level_nr = level_nr or 1
    self.level = Level(LEVEL_DEFS[self.level_nr])
    -- Timer that gets set at the start of every level and gets decremented to 0.
    -- Render the level number on the screen as long as show_level_text_timer > 0.
    self.show_level_text_timer = 3
    self.new_state = nil
    -- Event.dispatch() inside Level class. Start the next level or go back to StartState after the Timer.
    -- Display the victory or game over message in the meantime.
    Event.on('end-level', function()
        Timer.after(3, function()
            if self.level.state == 'victory' and self.level_nr < #LEVEL_DEFS then
                self.level_nr = self.level_nr + 1
                self.level = Level(LEVEL_DEFS[self.level_nr])
                self.show_level_text_timer = 3
            else
                self.new_state = 'start'
            end
        end)
    end)
end

function PlayState:update(dt)
    if keyboardWasPressed('escape') then
        self.new_state = 'start'
        gSounds['back']:play()
    end
    -- toggle pause
    if keyboardWasPressed(KEY_PAUSE) then
        if self.is_pause then
            gSounds['confirm']:play()
        else
            gSounds['back']:play()
        end
        self.level.is_pause = not self.level.is_pause
    end

    if self.new_state then
        gStateMachine:change(self.new_state)
        self.new_state = nil
        -- clear all timers (across all states)
        Timer.clear()
        -- remove all event handlers
        Event.handlers = {}
        return
    end

    if not self.level.is_pause then
        Timer.update(dt)
        self.show_level_text_timer = math.max(0, self.show_level_text_timer - dt)
    end

    self.level:update(dt)
end

function PlayState:render()
    self.level:render()
    -- render state text
    if self.level.is_pause then
        love.graphics.setFont(gFonts['huge'])
        love.graphics.setColor(0/255, 0/255, 0/255, 100/255)
        love.graphics.printf("PAUSE", 0, VIRTUAL_HEIGHT / 2 - 64, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    elseif self.level.state == 'victory' then
        love.graphics.setFont(gFonts['huge'])
        love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
        love.graphics.printf('VICTORY', 0, VIRTUAL_HEIGHT / 2 - 64, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    elseif self.level.state == 'defeat' then
        love.graphics.setFont(gFonts['huge'])
        love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
        love.graphics.printf('GAME OVER', 0, VIRTUAL_HEIGHT / 2 - 64, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    end
    -- render current level number
    if self.show_level_text_timer > 0 then
        love.graphics.setFont(gFonts['huge'])
        love.graphics.setColor(0/255, 0/255, 0/255, 255/255)
        love.graphics.printf('LEVEL ' .. tostring(self.level_nr), 0, 64, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    end
end
