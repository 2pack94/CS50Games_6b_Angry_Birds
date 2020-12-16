--[[
    The PhysBody Class is a wrapper around a Box2D body.
    It adds a texture, particle system, sound effects, health and other information to the body
]]

PhysBody = Class{}

function PhysBody:init(def)
    -- ID to differentiate between bodies
    self.id = def.id
    -- reference to the Entity container class that can contain multiple PhysBody objects
    self.superior = def.superior

    -- texture and quad information
    -- In this class implementation, every body can only have 1 texture
    -- and not a separate texture for every fixture
    self.texture = def.texture
    self.frame_id = def.frame_id or 1
    if type(self.frame_id) == "table" then
        self.frame_id = self.frame_id[math.random(#self.frame_id)]
    end

    -- position of the render origin in local coordinates (render offset).
    -- rotation in love.graphics.draw() is applied about the render origin.
    -- for elements that can rotate, this must be at the center of mass of the shape,
    -- to rotate the sprite in the same way as the physical Box2D body is rotated.
    -- Even without rotation, the render origin must be set to to the center,
    -- because the Box2D body coordinates refer to the center of mass by default.
    -- The center of mass and the position of edge/ chain shape bodies
    -- will be at the top left (no render offset needed)
    self.render_offset_x, self.render_offset_y = 0, 0
    -- texture scaling factor for each axis
    self.texture_scale_x, self.texture_scale_y = def.texture_scale_x or 1, def.texture_scale_y or 1

    -- if is_remove = true, this object gets removed from the body table of the superior class
    self.is_remove = false
    -- if the body has health, takes damage and can be destroyed
    if def.health_stages then
        -- set after the body takes damage. This flag prevents the body from taking damage
        -- multiple times from the same collision impact.
        -- collision damage gets calculated inside the postSolve function which might get
        -- called many times for a collision with the same but also for other fixtures.
        self.is_invulnerable = false
        -- table that contains health values. The body gets damaged when the damage from the
        -- collision impact is so high that it reaches a lower health stage or zero health.
        self.health_stages = def.health_stages
        -- index in the health_stages table to indicate the current health
        self.health_stage = 1
        -- table of frame ID's that matches the health stages to render the damage visually.
        self.frame_id_stages = def.frame_id_stages
        if not self.frame_id_stages then
            self.frame_id_stages = {}
            for i = 1, #self.health_stages do
                self.frame_id_stages[i] = self.frame_id
            end
        end
    end

    -- sound played when the body takes damage or dies (gets removed)
    self.hit_sound = def.hit_sound
    -- sound played when the body collides with something at a sufficient speed
    self.bounce_sound = def.bounce_sound

    -- particle system that emits particles when the body takes damage or dies
    if def.psystem then
        local def_psystem = def.psystem
        -- used when a default particle system definition should be overridden with custom values
        if def.psystem_custom then
            def_psystem = deepcopy(def_psystem)
            table.extend(def_psystem, def.psystem_custom)
        end
        -- particle sprite, max number of particles at a time
        self.psystem = love.graphics.newParticleSystem(gTextures[def_psystem.init[1]], def_psystem.init[2])
        -- min, max particle lifetime
        self.psystem:setParticleLifetime(table.unpack(def_psystem.particle_lifetime))
        -- min, max particle speed
        self.psystem:setSpeed(table.unpack(def_psystem.speed or {0, 0}))
        -- xmin, ymin, xmax, ymax constant acceleration
        self.psystem:setLinearAcceleration(table.unpack(def_psystem.linear_acceleration))
        -- min, max constant deceleration
        self.psystem:setLinearDamping(table.unpack(def_psystem.linear_damping or {0, 0}))
        -- available opening angle for the direction of the particle speed
        self.psystem:setSpread(table.unpack(def_psystem.spread or {0}))
        -- scaling of the particle texture. interpolate between sizes over lifetime
        self.psystem:setSizes(table.unpack(def_psystem.sizes or {1}))
        -- amount of particle size variation between 0 and 1
        self.psystem:setSizeVariation(table.unpack(def_psystem.size_variation or {0}))
        -- 'uniform' or 'normal' particle spawn distribution, max x, y spawn distance from the emitter
        self.psystem:setEmissionArea(table.unpack(def_psystem.emission_area))
        -- one or multiple colors. Interpolate between each color evenly over the particle's lifetime.
        self.psystem:setColors(table.unpack(def_psystem.colors))
        -- number of particles to emit on hit
        self.psystem_emit = def_psystem.emit
    end

    -- create the Box2D body
    self.body = love.physics.newBody(def.world, def.x, def.y, def.type or 'dynamic')
    -- positive angles rotate the body clockwise
    self.body:setAngle(math.rad(def.angle or 0))
    -- defines the attenuation of the angular velocity
    self.body:setAngularDamping(def.angular_damping or 0)

    -- add fixtures and shapes
    for _, fixture_def in pairs(def.fixtures) do
        local shape
        if fixture_def.shape == 'rectangle' then
            shape = love.physics.newRectangleShape(fixture_def.width, fixture_def.height)
            self.render_offset_x, self.render_offset_y = fixture_def.width / 2, fixture_def.height / 2
            self:compensateSkin()
        elseif fixture_def.shape == 'polygon' then
            -- convert polygon coordinates relative to the top left to coordinates relative to the center of mass
            -- the render offset can only be correctly calculated if the input vertices are relative to the top left
            local vertices = deepcopy(fixture_def.vertices)
            local center_x, center_y = love.physics.newPolygonShape(vertices):computeMass(1)
            for i = 1, #vertices do
                -- table elements alternate between x and y coordinates
                vertices[i] = i % 2 == 1 and vertices[i] - center_x or vertices[i] - center_y
            end
            shape = love.physics.newPolygonShape(vertices)
            self.render_offset_x, self.render_offset_y = center_x, center_y
            self:compensateSkin()
        elseif fixture_def.shape == 'circle' then
            shape = love.physics.newCircleShape(fixture_def.radius)
            self.render_offset_x, self.render_offset_y = fixture_def.radius, fixture_def.radius
        elseif fixture_def.shape == 'chain' then
            -- if looping = true, the first vertex will be appended at the end to create a closed shape
            shape = love.physics.newChainShape(fixture_def.shape_looping or false, fixture_def.vertices)
        end

        local fixture = love.physics.newFixture(self.body, shape)
        if def.friction then
            -- default friction is about 0.2
            fixture:setFriction(def.friction)
        end
        fixture:setRestitution(def.restitution or 0)
        if def.density then
            fixture:setDensity(def.density)
            self.body:resetMassData()
        end

        -- user data is used in the collision callback functions to identify the fixture.
        -- set user data to a reference to this object.
        -- when the body or fixture gets destroyed, the user data reference gets removed
        -- and does not need be be cleaned up manually (unlike in C++ Box2D).
        fixture:setUserData(self)

        -- collision filtering to control which fixtures can collide with each other.
        -- available flags: categories (16 bit bitmask), mask (16 bit bitmask), group (integer from -32768 to 32767)
        -- If the category of fixture2 matches a set bit inside the mask of fixture1 and vice versa,
        -- both fixtures will collide.
        -- The group can override the category/ mask value check. If the group is zero or the groups do not match,
        -- check the category/ mask bits. If both groups are the same and positive they collide.
        -- If both groups are the same and negative they don't collide.
        -- set input- or default values
        fixture:setFilterData(def.category or 0x1, def.mask or 0xFFFF, 0)
    end

    -- function prototype that gets called in the postSolve collision callback function
    self.doBeginCollision = def.doBeginCollision or function(
        self, self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1) end

    -- table of fixtures that are currently overlapping with this body
    self.contact_fixtures = {}
end

-- scale the texture to cover up the polygon shape skin that creates a small gap between stacked polygons.
-- if quad_width and quad_height are not equal, the texture aspect ratio will change,
-- but if x and y don't get scaled independently, the skin compensation for one axis might not be accurate.
-- the texture scale factor is increased by the ratio 2 * SKIN_RADIUS / quad size.
-- 2 * SKIN_RADIUS is used, because the skin in both directions must be compensated for every axis.
-- alternatively the Box2D shape dimensions could be adjusted,
-- but this is only possible for the rectangle shape and not for any polygon shape
function PhysBody:compensateSkin()
    local _, _, quad_width, quad_height = gFrames[self.texture][self.frame_id]:getViewport()
    quad_width, quad_height = quad_width * self.texture_scale_x, quad_height * self.texture_scale_y
    self.texture_scale_x = self.texture_scale_x + 2 * SKIN_RADIUS / quad_width
    self.texture_scale_y = self.texture_scale_y + 2 * SKIN_RADIUS / quad_height
end

--[[
Take damage or destroy the body if the amount of the collision impulse is high enough.
The normal- and tangent impulse from the postSolve function can be used as an
accurate representation of the collision strength. The restitution influences the
normal impulse and the friction determines the tangent impulse.
Only the impulses for the first collision point are taken into account.

alternative solution 1:
-- get velocities of both bodies at the impact point (use first contact point)
local v1_x, v1_y = body1:getLinearVelocityFromWorldPoint(contact:getPositions())
local v2_x, v2_y = body2:getLinearVelocityFromWorldPoint(contact:getPositions())
-- get the total collision impulse
local imp_total_x = v1_x * body1:getMass() - v2_x * body2:getMass()
local imp_total_y = v1_y * body1:getMass() - v2_y * body2:getMass()
-- get the impulse component pointing along the normal vector with the dot product.
local imp_total = math.dot(imp_total_x, imp_total_y, contact:getNormal())
Because the fixtures have a restitution smaller 1 and friction greater 0, the collisions between them
are inelastic collisions, instead of perfectly elastic collisions. That means Energy gets lost on impact.
Friction and Restitution can be obtained from the Contact object. With a friction based scaling factor,
the velocity component orthogonal to the normal vector can be taken into account.
If a heavy body collides with a small particle that is resting, the calculated total impulse would
be the same as when the heavy body collides with a static wall. A scaling factor based on the
mass ratio could be used to minimize this effect.

alternative solution 2:
Calculate the force that is acting on the body. The impulse of a force that acts on a body
during a time interval is equal to the change in the momentum of the body during that interval.
To get the change of momentum, the velocity before and after the collision must be obtained, which may
not always be available, e.g. when the object does not move because it is stuck or has high inertia.
]]
function PhysBody:takeCollisionDamage(self_fixture, opponent_fixture, contact, normal_impulse1, tangent_impulse1)
    -- don't enter this section if *self just took damage or died
    if self.is_invulnerable or self.is_remove then return end

    -- get the total amount of normal- and tangent impulse (orthogonal vectors)
    local total_impulse = math.sqrt(normal_impulse1^2 + tangent_impulse1^2)

    -- the total impulse is the damage that gets subtracted from the current health
    local new_health = self.health_stages[self.health_stage] - total_impulse
    -- check if a lower health stage or 0 is reached.
    -- The stages are the threshold for the minimum required collision strength
    if new_health <= 0 then
        self:onDeath()
    else
        for i = #self.health_stages, self.health_stage + 1, -1 do
            if new_health <= self.health_stages[i] then
                self:onHit()
                self.health_stage = i
                self.frame_id = self.frame_id_stages[i]
                -- After a hit, set invulnerability for some time.
                -- The time should be not too high to not skip over collisions and
                -- not too low to not take damage from collisions that resulted from the same impact.
                self.is_invulnerable = true
                Timer.after(0.2, function()
                    self.is_invulnerable = false
                end)
                break
            end
        end
    end
end

-- called when the body gets damaged. play a hit sound and emit particles
function PhysBody:onHit()
    if self.hit_sound then
        local hit_sound = self.hit_sound
        if type(hit_sound) == "table" then
            hit_sound = hit_sound[math.random(#hit_sound)]
        end
        gSounds[hit_sound]:stop()
        gSounds[hit_sound]:play()
    end

    if self.psystem then
        -- match the position and angle of the particle system with the body before emitting
        self.psystem:setPosition(self.body:getPosition())
        local emission_area = {self.psystem:getEmissionArea()}
        emission_area[4] = self.body:getAngle()
        self.psystem:setEmissionArea(table.unpack(emission_area))
        self.psystem:emit(self.psystem_emit)
    end
end

-- called when the body should be removed.
function PhysBody:onDeath()
    self:onHit()
    self.is_remove = true
end

function PhysBody:update(dt) end

function PhysBody:render()
    -- draw a sprite that fits the bodies shape and follows its rotation/ movement
    -- scaling and rotation transform the texture relative to its origin
    -- (offsets are applied before rotation and scaling)
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.frame_id],
        self.body:getX(), self.body:getY(),
        self.body:getAngle(),
        self.texture_scale_x, self.texture_scale_y,
        self.render_offset_x, self.render_offset_y
    )

    if IS_DEBUG then
        -- draw the outline of all shapes
        for _, fixture in pairs(self.body:getFixtures()) do
            love.graphics.setColor(0/255, 255/255, 0/255, 255/255)
            local shape = fixture:getShape()
            if shape:getType() == 'circle' then
                -- get the center in world coordinates.
                local x, y = self.body:getWorldPoints(shape:getPoint())
                love.graphics.circle('line', x, y, shape:getRadius())
                -- draw a line from center outwards to see the rotation
                local radius_vec_x = math.cos(self.body:getAngle()) * shape:getRadius()
                local radius_vec_y = math.sin(self.body:getAngle()) * shape:getRadius()
                love.graphics.setColor(255/255, 255/255, 255/255, 100/255)
                love.graphics.line(x, y, x + radius_vec_x, y + radius_vec_y)
            elseif shape:getType() == 'edge' or shape:getType() == 'chain' then
                -- if the chain shape has more that 2 points (more than 4 return values), a polyline is drawn
                love.graphics.line(self.body:getWorldPoints(shape:getPoints()))
            else        -- polygon (includes rectangle)
                love.graphics.polygon('line', self.body:getWorldPoints(shape:getPoints()))
            end
            -- draw AABB
            love.graphics.setColor(255/255, 0/255, 255/255, 255/255)
            local bb_x, bb_y, bb_bottom_right_x, bb_bottom_right_y = fixture:getBoundingBox(1)
            local bb_width, bb_height = bb_bottom_right_x - bb_x, bb_bottom_right_y - bb_y
            love.graphics.rectangle('line', bb_x, bb_y, bb_width, bb_height)
        end

        -- draw collision points and normal vectors for every contact object
        local contacts = self.body:getContacts()
        for _, contact in pairs(contacts) do
            -- check if the fixtures are overlapping
            if contact:isTouching() then
                -- both colliding bodies have the same contact object. So every contact will be drawn 2 times
                -- on top of each other. This is necessary to always have the debug drawing in the foreground.
                -- The normal vector always points from fixture1 to fixture2.
                -- draw normal only from contact point 1.
                local contact_x1, contact_y1, contact_x2, contact_y2 = contact:getPositions()
                local contact_nx, contact_ny = contact:getNormal()
                love.graphics.setColor(0/255, 0/255, 255/255, 255/255)
                love.graphics.circle('fill', contact_x1, contact_y1, 3)
                if contact_x2 and contact_y2 then
                    love.graphics.circle('fill', contact_x2, contact_y2, 3)
                end
                love.graphics.setColor(255/255, 255/255, 0/255, 255/255)
                local contact_n_line_end_x = contact_x1 + contact_nx * 20
                local contact_n_line_end_y = contact_y1 + contact_ny * 20
                love.graphics.line(contact_x1, contact_y1, contact_n_line_end_x, contact_n_line_end_y)
            end
        end
        love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    end
end
