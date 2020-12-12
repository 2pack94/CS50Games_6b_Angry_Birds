--[[
    GD50
    Angry Birds

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Class = require 'lib/class'
push = require 'lib/push'
Timer = require 'lib/knife.timer'
Event = require 'lib/knife.event'
bit32 = require 'lib/bit32'
require 'lib/StateMachine'
require 'lib/TableUtil'

require 'src/constants'
require 'src/Util'
require 'src/ProjectileLauncher'
require 'src/Background'
require 'src/Level'
require 'src/PhysBody'
require 'src/Entity'
require 'src/Projectile'
require 'src/Chain'
require 'src/game_element_defs'
require 'src/level_defs'

require 'src/states/BaseState'
require 'src/states/StartState'
require 'src/states/LevelSelectState'
require 'src/states/PlayState'

gTextures = {
    -- backgrounds
    ['blue-desert'] = love.graphics.newImage('graphics/blue_desert.png'),
    ['blue-grass'] = love.graphics.newImage('graphics/blue_grass.png'),
    ['blue-land'] = love.graphics.newImage('graphics/blue_land.png'),
    ['blue-shroom'] = love.graphics.newImage('graphics/blue_shroom.png'),
    ['colored-land'] = love.graphics.newImage('graphics/colored_land.png'),
    ['colored-desert'] = love.graphics.newImage('graphics/colored_desert.png'),
    ['colored-grass'] = love.graphics.newImage('graphics/colored_grass.png'),
    ['colored-shroom'] = love.graphics.newImage('graphics/colored_shroom.png'),
    ['blue'] = love.graphics.newImage('graphics/blue.png'),

    ['aliens'] = love.graphics.newImage('graphics/aliens.png'),
    ['tiles'] = love.graphics.newImage('graphics/tiles.png'),
    -- obstacles
    ['wood'] = love.graphics.newImage('graphics/wood.png'),
    ['stone'] = love.graphics.newImage('graphics/stone.png'),
    ['metal'] = love.graphics.newImage('graphics/metal.png'),
    -- UI
    ['ui-assets'] = love.graphics.newImage('graphics/UIpack.png'),
    ['particle'] = love.graphics.newImage('graphics/particle.png')
}

gFrames = {
    ['aliens'] = GenerateQuads(gTextures['aliens'], TILE_SIZE + 1, TILE_SIZE + 1, 1),
    ['tiles'] = GenerateQuads(gTextures['tiles'], TILE_SIZE, TILE_SIZE),
    -- the layout of this spritesheet is random, so quads need to be extracted manually
    ['wood'] = {
        love.graphics.newQuad(0, 35, 110, 35, gTextures['wood']:getDimensions()),
        love.graphics.newQuad(0, 0, 110, 35, gTextures['wood']:getDimensions()),
        love.graphics.newQuad(355, 35, TILE_SIZE, TILE_SIZE, gTextures['wood']:getDimensions()),
        love.graphics.newQuad(355, 70, TILE_SIZE, TILE_SIZE, gTextures['wood']:getDimensions()),
        love.graphics.newQuad(355, 106, TILE_SIZE, TILE_SIZE, gTextures['wood']:getDimensions()),
        love.graphics.newQuad(355, 142, TILE_SIZE, TILE_SIZE, gTextures['wood']:getDimensions()),
    },
    ['stone'] = {
        love.graphics.newQuad(0, 35, 110, 35, gTextures['stone']:getDimensions()),
        love.graphics.newQuad(0, 0, 110, 35, gTextures['stone']:getDimensions()),
    },
    ['metal'] = {
        love.graphics.newQuad(0, 0, 110, 35, gTextures['metal']:getDimensions()),
        love.graphics.newQuad(0, 35, 110, 70, gTextures['metal']:getDimensions()),
    },
    ['ui-assets'] = GenerateQuads(gTextures['ui-assets'], 18, 18, 2),
}

gSounds = {
    ['break_wood1'] = love.audio.newSource('sounds/break_wood1.wav', 'static'),
    ['break_wood2'] = love.audio.newSource('sounds/break_wood2.wav', 'static'),
    ['break_wood3'] = love.audio.newSource('sounds/break_wood3.mp3', 'static'),
    ['break_wood4'] = love.audio.newSource('sounds/break_wood4.wav', 'static'),
    ['break_wood5'] = love.audio.newSource('sounds/break_wood5.wav', 'static'),
    ['break_stone1'] = love.audio.newSource('sounds/break_stone1.mp3', 'static'),
    ['break_stone2'] = love.audio.newSource('sounds/break_stone2.mp3', 'static'),
    ['break_stone3'] = love.audio.newSource('sounds/break_stone3.mp3', 'static'),
    ['break_stone4'] = love.audio.newSource('sounds/break_stone4.mp3', 'static'),
    ['bounce'] = love.audio.newSource('sounds/bounce.wav', 'static'),
    ['enemy_hit'] = love.audio.newSource('sounds/enemy_hit.wav', 'static'),
    ['projectile_death'] = love.audio.newSource('sounds/projectile_death.wav', 'static'),
    ['select'] = love.audio.newSource('sounds/select.wav', 'static'),
    ['confirm'] = love.audio.newSource('sounds/confirm.wav', 'static'),
    ['back'] = love.audio.newSource('sounds/back.wav', 'static'),
    ['music'] = love.audio.newSource('sounds/music.mp3', 'static')
}

gFonts = {
    ['small'] = love.graphics.newFont('fonts/font.ttf', 16),
    ['medium'] = love.graphics.newFont('fonts/font.ttf', 32),
    ['large'] = love.graphics.newFont('fonts/font.ttf', 64),
    ['huge'] = love.graphics.newFont('fonts/font.ttf', 128)
}
