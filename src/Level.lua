--[[
    GD50
    Angry Birds

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The level contains all physics objects and the main game loop.
    The content of each level is defined in level_defs.lua.
    The available objects to build the level are defined in game_element_defs.lua
    The minimum required objects are a projectile cage, projectiles and enemies.
    The player must drag and release the active projectile to launch it and to kill the enemies.
    Obstacles are used as defensive structures to protect the enemies from the projectiles.
]]

--[[
collisions:
    Fixtures (from different bodies) collide with each other, not bodies.
    For every intersection between the axis aligned bounding boxes (AABB) of 2 fixtures,
    a contact object is created. It gets destroyed when the intersection stops.
    Contacts are objects created by Box2D to manage collision between two fixtures.
    Contact objects can be obtained with Body:getContacts(), World:getContacts() or
    by using the contact argument in the collision callback functions.
    If a fixture has children (e.g. a line segment of a chain shape), then a contact exists for each relevant child.
    To check if the fixtures are overlapping use Contact:isTouching().
    The contact also contains the 2 colliding fixtures, collision point(s), collision normal (unit) vector, ...
    There can be 0, 1 or 2 collision points (also called manifold). When resolving a collision, a normal impulse
    is applied for each fixture at the collision point(s) along the normal vector to push them apart.
    The collision point(s) are usually not exactly on the fixture surface.
    The normal vector points along the axis of the shortest separation (shortest distance to resolve overlap).

collision callback functions: beginContact, endContact, preSolve, postSolve
    Called inside World:update() when 2 fixtures are overlapping.
    Bodies must not be destroyed inside the world update function (e.g. in the collision callbacks).
    If a fixture has children, they will be called for each relevant child.
    The colliding fixtures and the contact object are passed as arguments,
    but the fixtures in the arguments as well as in the contact object don't have any particular ordering.
    Fixture user data has to be used to identify what collided.
    beginContact is called in the first frame of the overlap.
    After that, preSolve and postSolve are called every frame while the fixtures are overlapping.
    When 2 fixtures are stacked together, preSolve and postSolve will only stop to get called when the fixtures go to sleep.
    endContact is called when the fixtures are no longer overlapping.
    postSolve:
        The normal- and tangent impulse amounts for every collision point are passed as function arguments.
        The impulses are applied along the normal- and tangent vector.
        The tangent vector is orthogonal to the normal vector.
        The normal impulse is influenced by the restitution.
        The tangent impulse is applied to simulate friction between the two colliding fixtures.
    preSolve is called before the collision response is calculated and can be used to modify the contact object.
    Friction, Restitution and if the contact is enabled can be set.

bullet bodies:
    A body can be set to a bullet status with Body:setBullet(true)
    Bullet bodies will check collisions by using continuous collision detection (CCD), instead of only checking
    intersections when the world is updated. This prevents the body from 'tunneling' through fixtures
    from one time step to another when its velocity is high. The collision points will be the exact position
    of the collision. Bullet Bodies will require more CPU time however.

joints:
    A joint connects two bodies together. The joined bodies don't collide by default.
    There are several joint types that all have their own constructor.
    A revolute joint uses one anchor point for each of the 2 bodies in world coordinates, to join them.
    Both bodies are allowed to rotate about that point.
    If the bodies are not at the position that they will be joined in, the joint constraint will take effect
    after creating the joint and the bodies will move to their anchor point by applying the appropriate forces.
    Some joints (like the revolute joint) can be set as a motor with a controllable torque
    (or force for joints that allow the body to slide along an axis).
    Some joints can be given limits, to constrain how far they can rotate or slide.

bounding box querying:
    World:queryBoundingBox(topLeftX, topLeftY, bottomRightX, bottomRightY, callback)
    check if a fixture's AABB intersects with the query AABB defined by the 2 coordinates.
    For every found fixture, the registered callback function is called with the fixture as input parameter.
    If the callback returns true, it will continue to get called for every found fixture.
    If the callback returns false, it will not get called any more for the remaining fixtures.

ray casting:
    A ray can be cast against a Fixture with Fixture:rayCast(). see: https://love2d.org/wiki/Fixture:rayCast
    To invoke a callback function for every fixture that a ray intersects with, use World:rayCast().
    see: https://love2d.org/wiki/World:rayCast
]]

Level = Class{}

function Level:init(def)
    -- create a new world for every level
    -- when this level gets destroyed, also the Box2D World and all the bodies in it get destroyed
    self.world = love.physics.newWorld(0, GRAVITY)
    -- dimensions of the level. The camera and all bodies are not allowed to leave the level boundary
    self.width, self.height = def.width, def.height

    -- The zoom factor is the ratio of virtual resolution / view size
    -- Used for love.graphics.scale() (vertical and horizontal zoom is always the same)
    -- The player can zoom in and out with the mouse wheel
    self.zoom = 1
    -- initialize the view size (can never be bigger than the level)
    self.view_width = VIRTUAL_WIDTH
    self.view_height = VIRTUAL_HEIGHT
    self:constrainViewSize()
    -- camera coordinates. align camera at bottom left of level when starting. Used for love.graphics.translate()
    self.cam_x = 0
    self.cam_y = self.height - self.view_height
    -- instantiate a background that covers at least the level width and height
    -- (acceptable when levels are not that big)
    self.background = Background(self.width, self.height)

    -- valid states: 'playing', 'victory', 'defeat'
    self.state = 'playing'
    -- if game is paused, the camera can still be controlled
    self.is_pause = false
    -- start a timer when no projectiles are left before ending the level,
    -- to see if the remaining enemies die in this time so the player has still a chance to win.
    self.defeat_wait_timer = nil

    -- object that handles the shooting and reloading of projectiles
    self.projectile_launcher = ProjectileLauncher(def.launcher_x, def.launcher_y, self, self.world)

    -- Event.dispatch() inside Entity class immediately before a body is removed
    self.removeBodyHandler = Event.on('remove-body', function (body)
        -- active projectile needs to be set to nil to not reference it any more after it got destroyed
        if body == self.projectile_launcher.projectile then
            self.projectile_launcher.projectile = nil
        end
    end)

    -- contains all game entities subdivided into the categories objects, projectiles and enemies.
    -- the table elements are objects from the Entity class (or children of Entity).
    self.entities = {
        objects = {},
        projectiles = {},
        enemies = {},
    }

    -- table of the particle systems of all PhysBody objects. They need to be in this extra table,
    -- so they don't get removed when the object gets destroyed and so they can be rendered in the foreground
    self.psystems = {}

    -- instantiate all game elements defined in level_defs.lua for this level
    -- add them to the level entities table
    for i = 1, #def.elements do
        -- create full entity definition
        local element_def = {world = self.world}
        table.extend(element_def, GAME_ELEMENT_DEFS[def.elements[i].name])
        table.extend(element_def, def.elements[i])
        local element = nil
        -- identify entities handled by another class by their name
        if def.elements[i].name == 'chain' then
            element = Chain(element_def)
        else
            element = Entity(element_def)
        end
        if def.elements[i].name == 'enemy' then
            table.insert(self.entities.enemies, element)
        else
            table.insert(self.entities.objects, element)
        end
        -- spawn the specified number of projectiles in the projectile cage
        -- the projectile x coordinate inside the projectile cage indicates when it has its turn
        if def.elements[i].name == 'projectile-cage' then
            for proj_nr = 1, #def.projectiles do
                local proj_start_x = def.elements[i].x + 7 * PCTS + ALIEN_SIZE / 2
                local proj_end_x = def.elements[i].x + (110 - 7) * PCTS - ALIEN_SIZE / 2
                local proj_start_end_dist_x = proj_end_x - proj_start_x
                local proj_x = proj_start_x + (proj_nr - 1) * proj_start_end_dist_x / #def.projectiles
                local proj_y = math.random(def.elements[i].y + 8 * PCTS + ALIEN_SIZE / 2,
                    def.elements[i].y + (70 - 8) * PCTS - ALIEN_SIZE / 2)
                table.insert(self.entities.projectiles,
                    Projectile(proj_x, proj_y, self.world, def.projectiles[proj_nr]))
            end
        end
    end

    -- store the particle systems
    for _, entity_tbl in pairs(self.entities) do
        for _, entity in pairs(entity_tbl) do
            for _, entity_body in pairs(entity.bodies) do
                if entity_body.psystem then
                    table.insert(self.psystems, entity_body.psystem)
                end
            end
        end
    end

    -- create ground. use the same flat ground for every level.
    -- without a level editor, highly customizable levels are not feasible.
    for i = 1, math.ceil(self.width / TILE_SIZE) do
        local ground_def = {
            x = (i - 1) * TILE_SIZE, y = self.height - TILE_SIZE,
            world = self.world
        }
        table.extend(ground_def, GAME_ELEMENT_DEFS['ground'])
        table.insert(self.entities.objects, Entity(ground_def))
    end

    self:renderListSync()

    -- collision callback functions
    local function beginContact(fixture1, fixture2, contact)
        local fixtures = {fixture1, fixture2}
        for i = 1, #fixtures do
            local phys_body = fixtures[i]:getUserData()
            -- insert the other fixture into contact_fixtures
            -- don't insert the same fixture multiple times (can happen when a fixture has child shapes)
            if not table.contains(phys_body.contact_fixtures, fixtures[i == 1 and 2 or 1]) then
                table.insert(phys_body.contact_fixtures, fixtures[i == 1 and 2 or 1])
            end

            -- play bounce sound, if the body velocity is high enough.
            -- Only the velocity component along the collision normal is taken into account (ignore
            -- tangent/ friction component). This is approximately the component that points towards the surface.
            -- Use the dot product between velocity vector and normal (unit) vector to get a projection of the
            -- velocity on the normal vector.
            -- alpha: angle between v_vec and n_vec
            -- v_proj = cos(alpha) * abs(v_vec) = dot(v_vec, n_vec) / abs(n_vec) = dot(v_vec, n_vec)
            if phys_body.bounce_sound then
                -- use only velocity from first contact point.
                -- the velocity from world point includes also rotational velocity at that point
                local phys_body_v_x, phys_body_v_y =
                    phys_body.body:getLinearVelocityFromWorldPoint(contact:getPositions())
                local phys_body_v_proj = math.abs(math.dot(phys_body_v_x, phys_body_v_y, contact:getNormal()))
                if phys_body_v_proj > 100 then
                    gSounds[phys_body.bounce_sound]:stop()
                    gSounds[phys_body.bounce_sound]:play()
                end
            end
        end
    end
    local function preSolve(fixture1, fixture2, contact) end
    local function postSolve(fixture1, fixture2, contact,
        normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
        -- call the individual collision functions for the bodies
        local phys_body1 = fixture1:getUserData()
        local phys_body2 = fixture2:getUserData()
        phys_body1:doBeginCollision(fixture1, fixture2, contact, normal_impulse1, tangent_impulse1)
        phys_body2:doBeginCollision(fixture2, fixture1, contact, normal_impulse1, tangent_impulse1)
    end
    local function endContact(fixture1, fixture2, contact)
        -- remove fixture from contact_fixtures again
        local phys_body1 = fixture1:getUserData()
        local phys_body2 = fixture2:getUserData()
        local fixture_k = table.findkey(phys_body1.contact_fixtures, fixture2)
        if fixture_k then table.remove(phys_body1.contact_fixtures, fixture_k) end
        fixture_k = table.findkey(phys_body2.contact_fixtures, fixture1)
        if fixture_k then table.remove(phys_body2.contact_fixtures, fixture_k) end
    end

    -- register collision callback functions
    self.world:setCallbacks(beginContact, endContact, preSolve, postSolve)
end

-- convert screen coordinates to level coordinates (depend on where the camera is)
function Level:screenToLevelPos(x, y)
    return x / self.zoom + self.cam_x, y / self.zoom + self.cam_y
end

-- if the view size is bigger than the level dimensions, constrain the view.
-- adjust self.zoom to match the new constraint view size.
function Level:constrainViewSize()
    -- if view width too high
    local view_oversize_factor = self.view_width / self.width
    if view_oversize_factor > 1 then
        self.view_width = self.view_width / view_oversize_factor
        self.view_height = self.view_height / view_oversize_factor
        self.zoom = VIRTUAL_WIDTH / self.view_width
    end
     -- if view height too high
    view_oversize_factor = self.view_height / self.height
    if view_oversize_factor > 1 then
        self.view_width = self.view_width / view_oversize_factor
        self.view_height = self.view_height / view_oversize_factor
        self.zoom = VIRTUAL_HEIGHT / self.view_height
    end
end

-- camera can be zoomed or moved
function Level:updateCamera(dt)
    -- move the camera if pressed the arrow keys or if the mouse is at the screen border
    -- the mouse coordinates on the screen are not affected by the camera
    local mouse_x, mouse_y = push:toGame(love.mouse.getPosition())
    if love.keyboard.isDown('left') or mouse_x <= 2 then
        self.cam_x = self.cam_x - CAMERA_SPEED * dt
    elseif love.keyboard.isDown('right') or mouse_x >= VIRTUAL_WIDTH - 2 then
        self.cam_x = self.cam_x + CAMERA_SPEED * dt
    elseif love.keyboard.isDown('up') or mouse_y <= 2 then
        self.cam_y = self.cam_y - CAMERA_SPEED * dt
    elseif love.keyboard.isDown('down') or mouse_y >= VIRTUAL_HEIGHT - 2 then
        self.cam_y = self.cam_y + CAMERA_SPEED * dt
    end

    -- zoom in or out with the mouse wheel
    local wheel_movement = getWheelMovement()
    if math.abs(wheel_movement) > 0 then
        -- 10 mouse wheel ticks are needed to double/ half the zoom (exponential zoom)
        local zoom_base = 2^(1/10)
        self.zoom = self.zoom * (zoom_base ^ wheel_movement)
        -- limit min/ max zoom
        self.zoom = math.max(self.zoom, 0.5)
        self.zoom = math.min(self.zoom, 5)
        local view_width_prev = self.view_width
        local view_height_prev = self.view_height
        self.view_width = VIRTUAL_WIDTH / self.zoom
        self.view_height = VIRTUAL_HEIGHT / self.zoom
        self:constrainViewSize()
        -- always zoom to the center of the screen
        self.cam_x = self.cam_x + (view_width_prev - self.view_width) / 2
        self.cam_y = self.cam_y + (view_height_prev - self.view_height) / 2
    end

    -- constrain camera position
    self.cam_x = math.max(self.cam_x, 0)
    self.cam_x = math.min(self.cam_x, self.width - self.view_width)
    self.cam_y = math.max(self.cam_y, 0)
    self.cam_y = math.min(self.cam_y, self.height - self.view_height)
end

-- this function must be called every time there was a change to the render_prio of an entity
-- or an entity got removed or added.
-- create a sorted render list that is used to draw entities in the render function
function Level:renderListSync()
    -- list of entities that shall be rendered to the screen in this order.
    self.render_list = {}
    table.extend(self.render_list, self.entities.objects)
    table.extend(self.render_list, self.entities.projectiles)
    table.extend(self.render_list, self.entities.enemies)
    -- order self.render_list after the render_prio of each element.
    -- the element with the highest render_prio will be last in the list (drawn on top).
    -- the order of the elements with the same render_prio will not be changed (stable sorting algorithm necessary).
    self.render_prio_list = {}
    for _, elem in pairs(self.render_list) do
        table.insert(self.render_prio_list, elem.render_prio)
    end
    self.render_list, self.render_prio_list = sortStableWithHelperTbl(self.render_list, self.render_prio_list)
end

-- "destructor" of the Level. The dispatched Event and self.state indicate the end of the level to PlayState.
function Level:endLevel(state)
    -- if defeat_wait_timer was triggered, but all enemies were killed before it elapsed, it must be removed
    if self.defeat_wait_timer then
        self.defeat_wait_timer:remove()
    end
    self.state = state
    self.removeBodyHandler:remove()
    Event.dispatch('end-level')
end

function Level:update(dt)
    self:updateCamera(dt)

    self.background:SetPosWithCamera(math.floor(self.cam_x), math.floor(self.cam_y))

    if self.is_pause then return end    -- allow camera movement when paused

    for _, psystem in pairs(self.psystems) do
        psystem:update(dt)
    end

    for _, entity_tbl in pairs(self.entities) do
        for _, element in pairs(entity_tbl) do
            element:update(dt)
        end
    end

    self.projectile_launcher:update(dt)

    self.world:update(dt)

    local was_removal = false
    for _, entity_tbl in pairs(self.entities) do
        for i = #entity_tbl, 1, -1 do
            -- check if a body out of bounds
            for _, entity_body in pairs(entity_tbl[i].bodies) do
                if entity_body.body:getX() < 0 or entity_body.body:getX() > self.width or
                    entity_body.body:getY() > self.height
                then
                    entity_body:onDeath()
                end
            end
            -- remove entities that have their is_remove member set.
            if entity_tbl[i].is_remove then
                was_removal = true
                table.remove(entity_tbl, i)
                if #self.entities.enemies == 0 and self.state == 'playing' then
                    self:endLevel('victory')
                end
            end
        end
    end

    if was_removal then self:renderListSync() end

    if self.projectile_launcher.state == 'empty' and self.state == 'playing' then
        if self.projectile_launcher.projectile then
            -- Remove projectile if its below a velocity threshold (if it came to a standstill).
            -- The projectile should not be removed if its in the air (e.g. at turning point from rise to fall),
            -- so check if it collides with something. It can also be removed immediately by pressing KEY_SKIP.
            -- alternatively it could be checked if it was below the velocity threshold for a certain amount of time.
            local projectile_v_x, projectile_v_y = self.projectile_launcher.projectile.body:getLinearVelocity()
            local projectile_v = math.sqrt(projectile_v_x^2 + projectile_v_y^2)
            if (projectile_v < 10 and #self.projectile_launcher.projectile.contact_fixtures > 0) or
                keyboardWasPressed(KEY_SKIP)
            then
                self.projectile_launcher.projectile:onDeath()
            end
        else
            -- recharge self.projectile_launcher with the next projectile. (a projectile has only 1 body)
            if self.entities.projectiles[1] then
                self.projectile_launcher:recharge(self.entities.projectiles[1].bodies[1])
            elseif not self.defeat_wait_timer then
                -- end the level after the timer when no projectiles are available any more.
                self.defeat_wait_timer = Timer.after(5, function()
                    self:endLevel('defeat')
                end)
            end
        end
    end
end

function Level:render()
    love.graphics.push()

    love.graphics.scale(self.zoom, self.zoom)

    -- background implements its own translation
    self.background:render()

    love.graphics.translate(-math.floor(self.cam_x), -math.floor(self.cam_y))

    self.projectile_launcher:render()

    for _, elem in pairs(self.render_list) do
        elem:render()
    end

    for _, psystem in pairs(self.psystems) do
        love.graphics.draw(psystem)
    end

    love.graphics.pop()

    if IS_DEBUG then
        -- render mouse coordinates inside the level at the top left
        love.graphics.setFont(gFonts['medium'])
        local mouse_x, mouse_y = push:toGame(love.mouse.getPosition())
        mouse_x, mouse_y = self:screenToLevelPos(mouse_x, mouse_y)
        love.graphics.setColor(0/255, 0/255, 0/255, 150/255)
        love.graphics.printf('x: ' .. tostring(mouse_x), 10, 10, VIRTUAL_WIDTH)
        love.graphics.printf('y: ' .. tostring(mouse_y), 10, 50, VIRTUAL_WIDTH)
        love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    end
end
