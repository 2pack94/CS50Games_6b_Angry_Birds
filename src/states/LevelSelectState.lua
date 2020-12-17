LevelSelectState = Class{__includes = BaseState}

-- enter from StartState
function LevelSelectState:enter(params)
    -- reuse the scene from StartState
    self.world = params.world
    self.entities = params.entities
    self.background = params.background

    -- get set when the state shall be changed. either back to StartState or to PlayState
    self.new_state, self.new_state_params = nil, nil
    -- Levels can be selected by hovering over a level select box or by selecting it with the arrow keys.
    -- A level can be played by clicking on the box or pressing a confirm key.
    -- The selected level gets then passed to PlayState to instantiate the Level number.
    self.selected_level = 1
    self.bg_rect_margin = 20
    self.select_boxes = {}
    local select_boxes_margin = 20
    self.select_boxes_width = 320
    self.select_boxes_height = 180
    -- create a box for every level. All boxes are currently on one row, but this is sufficient for only a few levels.
    for i = 1, #LEVEL_DEFS do
        table.insert(self.select_boxes, {
            x = self.bg_rect_margin + select_boxes_margin + (i - 1) * (self.select_boxes_width + select_boxes_margin),
            y = 160 + self.bg_rect_margin + select_boxes_margin,
            text = tostring(i)
        })
    end
end

function LevelSelectState:update(dt)
    local selected_level_prev = self.selected_level

    if keyboardWasPressed('escape') then
        self.new_state = 'start'
        self.new_state_params = {
            world = self.world,
            entities = self.entities,
            background = self.background
        }
    elseif keyboardWasPressed({'return', 'space'}) then
        self.new_state = 'play'
        self.new_state_params = self.selected_level
    elseif keyboardWasPressed('left') then
        -- For modulo to work, selected_level must be shifted to a value range that starts from 0.
        -- Shift back after modulo operation.
        self.selected_level = (self.selected_level - 2) % #self.select_boxes + 1
    elseif keyboardWasPressed('right') then
        self.selected_level = self.selected_level % #self.select_boxes + 1
    end

    -- check if mouse is hovering above a box or if clicked a box
    local mouse_x, mouse_y = push:toGame(love.mouse.getPosition())
    for i = 1, #self.select_boxes do
        if rectContains(self.select_boxes[i].x, self.select_boxes[i].y,
            self.select_boxes_width, self.select_boxes_height, mouse_x, mouse_y)
        then
            self.selected_level = i
            if getMouseClick()[1] then
                self.new_state = 'play'
                self.new_state_params = self.selected_level
            end
            break
        end
    end

    if selected_level_prev ~= self.selected_level then
        gSounds['select']:stop()
        gSounds['select']:play()
    end

    if self.new_state then
        if self.new_state == 'play' then
            gSounds['confirm']:play()
        elseif self.new_state == 'start' then
            gSounds['back']:play()
        end
        gStateMachine:change(self.new_state, self.new_state_params)
        self.new_state, self.new_state_params = nil, nil
        return
    end

    self.world:update(dt)
end

function LevelSelectState:render()
    self.background:render()

    for _, entity in pairs(self.entities) do
        entity:render()
    end

    love.graphics.setColor(64/255, 64/255, 64/255, 150/255)
    love.graphics.rectangle('fill', self.bg_rect_margin, self.bg_rect_margin,
        VIRTUAL_WIDTH - self.bg_rect_margin * 2, VIRTUAL_HEIGHT - self.bg_rect_margin * 2, 3)

    love.graphics.setColor(200/255, 200/255, 200/255, 255/255)
    love.graphics.setFont(gFonts['huge'])
    love.graphics.printf('Level Selection', 0, 32 + self.bg_rect_margin, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(gFonts['large'])
    love.graphics.setLineWidth(3)
    for i = 1, #self.select_boxes do
        -- highlight currently selected level
        if self.selected_level == i then
            love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
        else
            love.graphics.setColor(200/255, 200/255, 200/255, 255/255)
        end
        love.graphics.printf(self.select_boxes[i].text,
            self.select_boxes[i].x + self.select_boxes_width / 2 - gFonts['large']:getWidth(self.select_boxes[i].text) / 2,
            self.select_boxes[i].y + self.select_boxes_height / 2 - gFonts['large']:getHeight() / 2,
            self.select_boxes_width)

        love.graphics.rectangle('line', self.select_boxes[i].x, self.select_boxes[i].y,
            self.select_boxes_width, self.select_boxes_height)
    end
    love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    love.graphics.setLineWidth(1)
end
