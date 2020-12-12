--[[
    The level definitions specify all elements that will be spawned for each level.
    The name of the elements correspond to a key in the GAME_ELEMENT_DEFS table.
]]

-- dimensions for each level
local LEVEL_1_WIDTH, LEVEL_1_HEIGHT = 1280, 720
local LEVEL_2_WIDTH, LEVEL_2_HEIGHT = 1600, 720

LEVEL_DEFS = {
    [1] = {
        width = LEVEL_1_WIDTH, height = LEVEL_1_HEIGHT,
        -- Position of the ProjectileLauncher object
        launcher_x = 120, launcher_y = LEVEL_1_HEIGHT - TILE_SIZE - 120,
        -- The projectiles and other elements will be added to the level entity list in this order.
        -- The player will be able to fire the specified projectile types in this order.
        projectiles = {'normal', 'normal'},
        elements = {
            {name = 'enemy', x = LEVEL_1_WIDTH - 300, y = LEVEL_1_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2},
            {name = 'enemy', x = LEVEL_1_WIDTH - 300, y = LEVEL_1_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2 - 255},
            {name = 'wood_hor', x = LEVEL_1_WIDTH - 360, y = LEVEL_1_HEIGHT - TILE_SIZE - 55, angle = 90},
            {name = 'wood_hor', x = LEVEL_1_WIDTH - 240, y = LEVEL_1_HEIGHT - TILE_SIZE - 55, angle = 90},
            {name = 'wood_hor', x = LEVEL_1_WIDTH - 300, y = LEVEL_1_HEIGHT - TILE_SIZE - 127.5},
            {name = 'wood_hor', x = LEVEL_1_WIDTH - 300, y = LEVEL_1_HEIGHT - TILE_SIZE - 200, angle = 90},
            {name = 'wood_hor', x = LEVEL_1_WIDTH - 412.5, y = LEVEL_1_HEIGHT - TILE_SIZE - 55, angle = 90},
            {name = 'wood_hor', x = LEVEL_1_WIDTH - 386.25, y = LEVEL_1_HEIGHT - TILE_SIZE - 165, angle = 90},
            {name = 'wood_triangle', x = LEVEL_1_WIDTH - 403.75 + 23 + 1/3, y = LEVEL_1_HEIGHT - TILE_SIZE - 220 - (11 + 2/3), angle = -90},
            {name = 'projectile-cage', x = 0, y = 0}
        }
    },
    [2] = {
        width = LEVEL_2_WIDTH, height = LEVEL_2_HEIGHT,
        launcher_x = 200, launcher_y = LEVEL_2_HEIGHT - TILE_SIZE - 100,
        projectiles = {'normal', 'normal', 'heavy', 'normal', 'heavy', 'heavy', 'normal'},
        elements = {
            {name = 'enemy', x = 685, y = LEVEL_2_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2},
            {name = 'enemy', x = 777.5, y = LEVEL_2_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2},
            {name = 'enemy', x = 1135, y = LEVEL_2_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2},
            {name = 'enemy', x = 1042.5, y = LEVEL_2_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2 - 180},
            {name = 'enemy', x = 1227.5, y = LEVEL_2_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2 - 180},
            {name = 'metal_hor', x = 570, y = LEVEL_2_HEIGHT - 400, angle = 15},
            {name = 'metal_hor', x = 900, y = LEVEL_2_HEIGHT - 400, angle = -15},
            {name = 'stone_hor', x = 700, y = LEVEL_2_HEIGHT - 415, angle = 15},
            {name = 'stone_hor', x = 810, y = LEVEL_2_HEIGHT - 425, angle = -15},
            -- the chain must be defined after the bodies that the chain shall be attached to
            {name = 'chain', num_elements = 8, anchor1 = {x = 620, y = 335}, anchor2 = {x = 850, y = 335}},
            {name = 'chain', num_elements = 6, anchor1 = {x = 520, y = 320}, anchor2 = {x = 520, y = 500}},
            {name = 'metal_hor', x = 640, y = LEVEL_2_HEIGHT - TILE_SIZE - 55, angle = 90},
            {name = 'wood_hor', x = 677.5, y = LEVEL_2_HEIGHT - TILE_SIZE - 127.5},
            {name = 'wood_hor', x = 732.5, y = LEVEL_2_HEIGHT - TILE_SIZE - 55, angle = 90},
            {name = 'wood_hor', x = 787.5, y = LEVEL_2_HEIGHT - TILE_SIZE - 127.5},
            {name = 'wood_hor', x = 825, y = LEVEL_2_HEIGHT - TILE_SIZE - 55, angle = 90},
            {name = 'wood_hor', x = 640, y = LEVEL_2_HEIGHT - TILE_SIZE - 200, angle = 90},
            {name = 'wood_hor', x = 825, y = LEVEL_2_HEIGHT - TILE_SIZE - 200, angle = 90},
            {name = 'stone_hor', x = 970, y = LEVEL_2_HEIGHT - TILE_SIZE - 17.5},
            {name = 'stone_hor', x = 1300, y = LEVEL_2_HEIGHT - TILE_SIZE - 17.5},
            {name = 'stone_hor', x = 970, y = LEVEL_2_HEIGHT - TILE_SIZE - 90, angle = 90},
            {name = 'stone_hor', x = 1080, y = LEVEL_2_HEIGHT - TILE_SIZE - 55, angle = 90},
            {name = 'stone_hor', x = 1190, y = LEVEL_2_HEIGHT - TILE_SIZE - 55, angle = 90},
            {name = 'stone_hor', x = 1300, y = LEVEL_2_HEIGHT - TILE_SIZE - 90, angle = 90},
            {name = 'stone_hor', x = 1080, y = LEVEL_2_HEIGHT - TILE_SIZE - 127.5},
            {name = 'stone_hor', x = 1190, y = LEVEL_2_HEIGHT - TILE_SIZE - 127.5},
            {name = 'wood_hor', x = 1025, y = LEVEL_2_HEIGHT - TILE_SIZE - 162.5},
            {name = 'wood_hor', x = 1245, y = LEVEL_2_HEIGHT - TILE_SIZE - 162.5},
            {name = 'wood_hor', x = 1097.5, y = LEVEL_2_HEIGHT - TILE_SIZE - 200, angle = 90},
            {name = 'wood_hor', x = 1172.5, y = LEVEL_2_HEIGHT - TILE_SIZE - 200, angle = 90},
            {name = 'wood_hor', x = 1135, y = LEVEL_2_HEIGHT - TILE_SIZE - 272.5},
            {name = 'wood_hor', x = 987.5, y = LEVEL_2_HEIGHT - TILE_SIZE - 235, angle = 90},
            {name = 'wood_hor', x = 1282.5, y = LEVEL_2_HEIGHT - TILE_SIZE - 235, angle = 90},
            {name = 'wood_hor', x = 1135, y = LEVEL_2_HEIGHT - TILE_SIZE - 345, angle = 90},
            {name = 'wood_triangle', x = 970 + 23 + 1/3, y = LEVEL_2_HEIGHT - TILE_SIZE - 290 - (11 + 2/3), angle = -90},
            {name = 'wood_triangle', x = 1265 + 11 + 2/3, y = LEVEL_2_HEIGHT - TILE_SIZE - 290 - (11 + 2/3)},
            {name = 'projectile-cage', x = 0, y = 0}
        }
    },
}
