-- starting window size
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- resolution to emulate with push
VIRTUAL_WIDTH = 1920
VIRTUAL_HEIGHT = 1080

-- if true, show debug information on the screen (collision points, shape outlines, AABBs, ...)
-- IS_DEBUG = true
IS_DEBUG = false

PIXEL_PER_METER = 50                -- definition of 1 meter in Box2D
GRAVITY = 9.81 * PIXEL_PER_METER    -- in pixel / s^2

-- Polygon (a rectangle is also a polygon) shapes have a "skin" around them.
-- The skin is used in stacking scenarios to keep polygons slightly separated.
-- In this separation area the fixtures are touching, but not overlapping. So no correction of
-- continuous overlap caused by gravity needs to be made and the bodies can go into sleep state.
-- The skin radius can be obtained with Shape:getRadius(). All polygons have the same skin radius of 1 cm.
SKIN_RADIUS = PIXEL_PER_METER / 100

-- velocity of the camera when moved
CAMERA_SPEED = 300
-- how fast the background scrolls on the x axis
-- in proportion to the rest of the level when moving the camera
BACKGROUND_SCROLL_PROPORTION = 0.5

-- names of different background textures that can be used for the levels
BACKGROUND_TEXTURES = {
    'colored-land', 'blue-desert', 'blue-grass', 'blue-land',
    'blue-shroom', 'colored-desert', 'colored-grass', 'colored-shroom'
}
-- To fill the screen, there are textures needed that are drawn above the main background texture.
-- A solid blue texture fits above all main background textures.
EXTENDED_BACKGROUND_TEXTURE = 'blue'

KEY_SKIP = 'space'      -- immediately destroy the current projectile (after launched) to skip wait time
KEY_PAUSE = 'p'         -- pause/ unpause the game

-- Many tiles from the main sprite sheets are this size
TILE_SIZE = 35
-- An Alien can be a projectile (round) or enemy (square),
-- so the size is either the width or height or diameter
ALIEN_SIZE = TILE_SIZE

-- abbreviation for PROJECTILE_CAGE_TEXTURE_SCALE_FACTOR
PCTS = 2

-- collision filtering categories (see PhysBody class)
CATEGORY_DEFAULT = 1
CATEGORY_PROJECTILE = 2

-- ID's. Used to differentiate entities
ID_PROJECTILE = 1       -- round alien
ID_ENEMY = 2            -- square alien
ID_GROUND = 101
ID_WOOD_HOR = 102
ID_WOOD_CIRCLE = 103
ID_WOOD_TRIANGLE = 104
ID_STONE_HOR = 105
ID_METAL_HOR = 106
ID_PROJECTILE_CAGE = 151

-- frame ID's. Used as an index in a corresponding gFrames table to get the desired quad.
-- ground
FRAME_ID_GROUND_GRASS = 12
-- obstacles
FRAME_ID_WOOD_HOR = 1
FRAME_ID_WOOD_DMG_HOR = 2
FRAME_ID_WOOD_CIRCLE = 3
FRAME_ID_WOOD_DMG_CIRCLE = 4
FRAME_ID_WOOD_TRIANGLE = 5
FRAME_ID_WOOD_DMG_TRIANGLE = 6
FRAME_ID_STONE_HOR = 1
FRAME_ID_STONE_DMG_HOR = 2
FRAME_ID_METAL_HOR = 1
FRAME_ID_METAL_HOLLOW = 2
-- UI Elements
FRAME_ID_LAUNCH_ANCHOR = 686
FRAME_ID_MOUSE_CURSOR = 962
FRAME_ID_TRAJECTORY_POINT = 555
-- square aliens
FRAME_IDS_ENEMY = {1, 2, 3, 4, 5}
-- round aliens
FRAME_IDS_PROJECTILE = {6, 7, 8, 9, 10}
FRAME_ID_PROJECTILE_NORMAL = FRAME_IDS_PROJECTILE[4]
FRAME_ID_PROJECTILE_HEAVY = FRAME_IDS_PROJECTILE[1]
