-- particle system definitions. separate definition table to use them for multiple game elements.
PSYSTEM_DEFS = {
    [1] = {     -- used by projectile and enemy
        init = {'particle', 1000},
        particle_lifetime = {0.2, 0.5},
        speed = {0, 800},
        linear_acceleration = {0, 500, 0, 500},
        linear_damping = {5, 10},
        spread = {math.rad(360)},
        sizes = {1, 0.5},
        size_variation = {0.8},
        emission_area = {'uniform', ALIEN_SIZE / 2, ALIEN_SIZE / 2},
        colors = {
            255/255, 0/255, 0/255, 200/255,
            172/255, 50/255, 50/255, 200/255},
        emit = 200
    },
    [2] = {     -- used by several obstacles
        init = {'particle', 1000},
        particle_lifetime = {0.5, 1},
        linear_acceleration = {0, 100, 0, 100},
        sizes = {2},
        size_variation = {0.5},
        emission_area = {'uniform', TILE_SIZE / 2, TILE_SIZE / 2},
        colors = {
            160/255, 109/255, 61/255, 200/255},
        emit = 100
    }
}

-- Definitions used as input parameters for the Entity class instantiation.
-- More complex entities are handled by an additional child class that inherits from Entity.
-- This child class might handle the creation of the Entity definition by itself.
-- Information like spawn position and orientation are stored in level_defs.lua
GAME_ELEMENT_DEFS = {
    -- The ground tile uses a chain shape instead of a rectangle shape.
    -- Touching rectangle shapes introduce a bug where flat objects can collide with the edge of a rectangle
    -- when sliding over the invisible gap. This could push the object in a wrong direction (ghost collision).
    -- Neighboring edge shapes or chain shapes don't have that problem. Even though there is the concept
    -- of ghost vertices, they are not necessary to prevent ghost collisions from my experience.
    -- ghost vertices for edge shapes or chain shapes can be set via: setNextVertex(), setPreviousVertex()
    ['ground'] = {bodies = {{         -- ground tile
        id = ID_GROUND,
        texture = 'tiles', frame_id = FRAME_ID_GROUND_GRASS,
        type = 'static',
        fixtures = {{
            -- use a rectangular chain shape to have the possibility to place ground tiles anywhere
            shape = 'chain', shape_looping = true,
            vertices = {0, 0, TILE_SIZE, 0, TILE_SIZE, TILE_SIZE, 0, TILE_SIZE}
        }},
        friction = 0.5,
    }}},
    ['wood_hor'] = {bodies = {{     -- horizontal rectangular wood obstacle
        id = ID_WOOD_HOR,
        texture = 'wood', frame_id = FRAME_ID_WOOD_HOR,
        hit_sound = {'break_wood1', 'break_wood2', 'break_wood3', 'break_wood4', 'break_wood5'},
        health_stages = {250, 125},
        frame_id_stages = {FRAME_ID_WOOD_HOR, FRAME_ID_WOOD_DMG_HOR},
        psystem = PSYSTEM_DEFS[2],
        psystem_custom = {emission_area = {'uniform', 110 / 2, 35 / 2}},
        fixtures = {
            {shape = 'rectangle', width = 110, height = 35}
        },
        friction = 0.5,
        doBeginCollision = function(self, self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
            self:takeCollisionDamage(self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
        end
    }}},
    ['wood_circle'] = {bodies = {{      -- circular wood object used as element for the Chain class
        id = ID_WOOD_CIRCLE,
        texture = 'wood', frame_id = FRAME_ID_WOOD_CIRCLE,
        hit_sound = {'break_wood1', 'break_wood2', 'break_wood3', 'break_wood4', 'break_wood5'},
        health_stages = {250, 125},
        frame_id_stages = {FRAME_ID_WOOD_CIRCLE, FRAME_ID_WOOD_DMG_CIRCLE},
        psystem = PSYSTEM_DEFS[2],
        psystem_custom = {emit = 30},
        fixtures = {
            {shape = 'circle', radius = TILE_SIZE / 2}
        },
        friction = 0.5,
        angular_damping = 0.3,
        doBeginCollision = function(self, self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
            self:takeCollisionDamage(self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
        end
    }}},
    ['wood_triangle'] = {bodies = {{     -- triangular wood obstacle
        id = ID_WOOD_TRIANGLE,
        texture = 'wood', frame_id = FRAME_ID_WOOD_TRIANGLE,
        hit_sound = {'break_wood1', 'break_wood2', 'break_wood3', 'break_wood4', 'break_wood5'},
        health_stages = {250, 125},
        frame_id_stages = {FRAME_ID_WOOD_TRIANGLE, FRAME_ID_WOOD_DMG_TRIANGLE},
        psystem = PSYSTEM_DEFS[2],
        psystem_custom = {
            emission_area = {'uniform', 11, 11},
            emit = 20,
        },
        fixtures = {
            {shape = 'polygon', vertices = {
                -- center of mass from top left at (11 + 2/3, 23 + 1/3)
                0, 0,
                0, 35,
                35, 35
            }}
        },
        friction = 0.5,
        doBeginCollision = function(self, self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
            self:takeCollisionDamage(self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
        end
    }}},
    ['stone_hor'] = {bodies = {{     -- horizontal rectangular stone obstacle
        id = ID_STONE_HOR,
        texture = 'stone', frame_id = FRAME_ID_STONE_HOR,
        hit_sound = {'break_stone1', 'break_stone2', 'break_stone3', 'break_stone4'},
        health_stages = {500, 250},
        frame_id_stages = {FRAME_ID_STONE_HOR, FRAME_ID_STONE_DMG_HOR},
        psystem = PSYSTEM_DEFS[2],
        psystem_custom = {
            emission_area = {'uniform', 110 / 2, 35 / 2},
            colors = {151/255, 169/255, 170/255, 200/255},
        },
        fixtures = {
            {shape = 'rectangle', width = 110, height = 35}
        },
        density = 2,
        friction = 0.5,
        doBeginCollision = function(self, self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
            self:takeCollisionDamage(self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
        end
    }}},
    ['metal_hor'] = {bodies = {{     -- horizontal rectangular metal obstacle (indestructible)
        id = ID_METAL_HOR,
        texture = 'metal', frame_id = FRAME_ID_METAL_HOR,
        type = 'static',
        fixtures = {
            {shape = 'rectangle', width = 110, height = 35}
        },
        friction = 0.2,
    }}},
    ['projectile-cage'] = {bodies = {{ -- contains all projectiles that are yet to be fired. Can be only 1 per level.
        id = ID_PROJECTILE_CAGE,
        texture = 'metal', frame_id = FRAME_ID_METAL_HOLLOW,
        type = 'static',
        texture_scale_x = PCTS, texture_scale_y = PCTS,
        fixtures = {
            {   -- outer boundary
                shape = 'chain', shape_looping = true,
                vertices = {0, 0, 110 * PCTS, 0, 110 * PCTS, 70 * PCTS, 0, 70 * PCTS},
            },
            {   -- inner boundary
                shape = 'chain', shape_looping = true,
                vertices = {7 * PCTS, 8 * PCTS, (110 - 7) * PCTS, 8 * PCTS,
                    (110 - 7) * PCTS, (70 - 8) * PCTS, 7 * PCTS, (70 - 8) * PCTS},
            }
        },
    }}},
    ['projectile'] = {bodies = {{      -- round alien. definition for projectile type 'normal'.
        id = ID_PROJECTILE,
        texture = 'aliens',
        frame_id = FRAME_ID_PROJECTILE_NORMAL,
        hit_sound = 'projectile_death',
        bounce_sound = 'bounce',
        psystem = PSYSTEM_DEFS[1],
        fixtures = {
            {shape = 'circle', radius = ALIEN_SIZE / 2}
        },
        restitution = 0.4,
        angular_damping = 0.5,
        category = CATEGORY_PROJECTILE, mask = bit32.bxor(0xFF, CATEGORY_PROJECTILE),
    }}},
    ['enemy'] = {bodies = {{          -- square alien
        id = ID_ENEMY,
        texture = 'aliens',
        frame_id = FRAME_IDS_ENEMY,
        hit_sound = 'enemy_hit',
        health_stages = {150},
        psystem = PSYSTEM_DEFS[1],
        fixtures = {
            {shape = 'rectangle', width = ALIEN_SIZE, height = ALIEN_SIZE}
        },
        doBeginCollision = function(self, self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
            self:takeCollisionDamage(self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
        end
    }}},
    ['chain'] = {},     -- dummy definition. see Chain Class.
    -- UI Elements
    ['projectile-launch-marker'] = {
        render_offset_x = 8, render_offset_y = 8, texture = 'ui-assets', frame_id = FRAME_ID_LAUNCH_ANCHOR
    },
    ['projectile-trajectory-point'] = {
        render_offset_x = 8, render_offset_y = 8, texture = 'ui-assets', frame_id = FRAME_ID_TRAJECTORY_POINT
    }
}
