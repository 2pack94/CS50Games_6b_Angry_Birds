--[[
    GD50
    Angry Birds

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Background Class that handles scrolling background textures with the camera movement.
]]

Background = Class{}

function Background:init(fill_width, fill_height, texture)
    self.texture = texture or BACKGROUND_TEXTURES[math.random(#BACKGROUND_TEXTURES)]
    -- dimension of the background texture. They are periodic to self.width
    self.width = gTextures[self.texture]:getWidth()
    self.height = gTextures[self.texture]:getHeight()
    -- area that needs at least to be filled with the background
    self.fill_width, self.fill_height = fill_width, fill_height
    -- background position
    self.x, self.y = 0, 0
end

function Background:SetPosWithCamera(cam_x, cam_y)
    -- The game level uses a translation based on the camera position. Replicate this translation for the background,
    -- but have a slower x translation to create a parallax effect. The y background position will not move relative
    -- to the level. If background scrolled to a multiple of self.width, reset its position to 0.
    self.x = - ((cam_x * BACKGROUND_SCROLL_PROPORTION) % self.width)
    self.y = - cam_y
end

function Background:render()
    -- number of extended background textures that are needed to fill the screen vertically.
    local num_bg_extended = math.ceil((self.fill_height - self.height) / self.height)
    -- at minimum self.fill_width plus self.width has to be filled with a background texture
    for i = 1, math.ceil(self.fill_width / self.width) + 1 do
        -- draw extended background textures above the main texture
        for j = 1, num_bg_extended do
            love.graphics.draw(gTextures[EXTENDED_BACKGROUND_TEXTURE],
                math.floor(self.x + self.width * (i - 1)), self.y + self.fill_height - self.height * 2 - self.height * (j - 1))
        end
        -- draw main texture. y coordinate is aligned at the bottom of self.fill_height
        love.graphics.draw(gTextures[self.texture],
            math.floor(self.x + self.width * (i - 1)), self.y + self.fill_height - self.height)
    end
end
