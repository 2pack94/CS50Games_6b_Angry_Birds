--[[
    GD50
    Angry Birds

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    If given the PhysBody object of a projectile it places it into the launching position.
    It then can be dragged with the mouse and when released, the projectile gets launched
    like in a slingshot.
]]

ProjectileLauncher = Class{}

function ProjectileLauncher:init(x, y, level, world)
    -- level and Box2D world references
    self.world = world
    self.level = level

    -- coordinates. projectiles are placed in this position and can be fired from here.
    self.x = x
    self.y = y

    -- use a sprite to mark the projectile launcher position.
    self.ui_elements = {}
    local projectile_launch_marker_def = {x = self.x, y = self.y}
    table.extend(projectile_launch_marker_def, GAME_ELEMENT_DEFS['projectile-launch-marker'])
    table.insert(self.ui_elements, projectile_launch_marker_def)

    -- valid states: 'recharging', 'idle', 'aiming', 'empty'
    self.state = 'empty'

    -- store mouse click information of the current frame when in 'idle' state
    self.mouse_click = nil


    -- PhysBody object of a projectile. gets set when recharging the launcher
    self.projectile = nil
    -- store a backup of collision filtering information for the projectile
    self.proj_category = nil
    self.proj_mask = nil
    self.proj_group = nil

    -- speed at which the projectile moves from its position to the launch position when recharging
    self.recharge_vel = 500

    -- maximum distance of the projectile to the launch center when aiming
    -- The distance determined the impulse that the projectile gets launched with
    self.charge_dist_max = 75
    -- impulse applied to the projectile body when releasing the mouse after aiming
    self.shoot_impulse_x, self.shoot_impulse_y = 0, 0
    -- when aiming, the predicted trajectory is drawn to the screen in realtime.
    -- The drawn trajectory ends at these coordinates, when there is an intersection with any fixture.
    self.trajectory_intersect_x, self.trajectory_intersect_y = nil, nil

    -- callback function for queryBoundingBox() that is called when pressed left mouse while in idle state
    self.callbackWorldQuery = function(fixture)
        -- check if mouse click was inside the projectile fixture
        if self.projectile == fixture:getUserData() and fixture:testPoint(self.mouse_click.x, self.mouse_click.y) then
            self.state = 'aiming'
            return false
        end
        return true
    end

    -- callback function for rayCast() that is called in the aiming state
    -- get the ray intersection for the fixture that is the nearest to the ray starting point by returning the
    -- fraction value. The fraction value is the ratio:
    -- ray length between start- and intersection point / ray length between original start- and end point
    -- The return value defines the ray length that is used to discover the next intersection.
    -- return 1 leaves the original ray length unchanged. return 0 cancels the ray.
    -- The ray intersection point is stored in member variables
    self.callbackRayCast = function(fixture, i_x, i_y, n_x, n_y, fraction)
        self.trajectory_intersect_x, self.trajectory_intersect_y = i_x, i_y
        return fraction
    end
end

-- projectile: PhysBody object of a projectile Entity
-- go into 'recharging' state. The projectile is moved to the launch point.
-- collision and gravity have to be turned off for the projectile
function ProjectileLauncher:recharge(projectile)
    self.state = 'recharging'
    self.projectile = projectile
    self.projectile.body:setGravityScale(0)
    self.proj_category, self.proj_mask, self.proj_group = self.projectile.body:getFixtures()[1]:getFilterData()
    self.projectile.body:getFixtures()[1]:setFilterData(self.proj_category, 0, self.proj_group)
end

function ProjectileLauncher:update(dt)
    if self.state == 'recharging' then
        -- move the projectile to the launch position (target position)
        local body_x, body_y = self.projectile.body:getPosition()
        local dist_to_target_x = self.x - body_x
        local dist_to_target_y = self.y - body_y
        local dist_to_target = math.sqrt(dist_to_target_x^2 + dist_to_target_y^2)
        -- velocity vector for the projectile.
        -- The unit vector pointing to the target is multiplied by recharge_vel
        local recharge_vel_x, recharge_vel_y = 0, 0
        if dist_to_target ~= 0 then     -- don't divide by 0
            recharge_vel_x = (dist_to_target_x / dist_to_target) * self.recharge_vel
            recharge_vel_y = (dist_to_target_y / dist_to_target) * self.recharge_vel
        end
        -- check if the next position of the projectile will overshoot the target point
        local next_pos_x = recharge_vel_x * dt
        local next_pos_y = recharge_vel_y * dt
        local next_pos = math.sqrt(next_pos_x^2 + next_pos_y^2)
        if dist_to_target < next_pos then
            -- the projectile will reach its target point in this frame, so the position can be set directly
            self.projectile.body:setPosition(self.x, self.y)
            self.projectile.body:setLinearVelocity(0, 0)
            self.state = 'idle'
        else
            -- the projectile has to still move to the target point
            self.projectile.body:setLinearVelocity(recharge_vel_x, recharge_vel_y)
        end
    elseif self.state == 'idle' then
        -- if left mouse button was pressed
        self.mouse_click = deepcopy(getMouseClick())
        if self.mouse_click[1] then
            -- check if the mouse click is inside the projectile's fixture. go to the 'aiming' state if yes.
            self.mouse_click.x, self.mouse_click.y = self.level:screenToLevelPos(self.mouse_click.x, self.mouse_click.y)
            self.world:queryBoundingBox(self.mouse_click.x, self.mouse_click.y, self.mouse_click.x, self.mouse_click.y,
                self.callbackWorldQuery)
        end
    elseif self.state == 'aiming' then
        -- move the projectile with the mouse as long as the left mouse button is hold.
        local mouse_x, mouse_y = push:toGame(love.mouse.getPosition())
        mouse_x, mouse_y = self.level:screenToLevelPos(mouse_x, mouse_y)
        -- distance from launch center to mouse. restrict to the maximum allowed distance.
        local charge_dist_x = mouse_x - self.x
        local charge_dist_y = mouse_y - self.y
        local charge_dist = math.sqrt(charge_dist_x^2 + charge_dist_y^2)
        if charge_dist > self.charge_dist_max then
            charge_dist_x = charge_dist_x * (self.charge_dist_max / charge_dist)
            charge_dist_y = charge_dist_y * (self.charge_dist_max / charge_dist)
        end
        self.projectile.body:setPosition(self.x + charge_dist_x, self.y + charge_dist_y)
        -- Use the distance between projectile position and launcher center multiplied with a scale factor
        -- as impulse vector (in kg * m / s). The impulse vector must have the opposite direction of the distance vector.
        -- Have the same velocity regardless of mass. Otherwise heavier projectiles would have no advantage.
        local dist_to_impulse_factor = 520 * self.projectile.body:getMass()
        self.shoot_impulse_x = - charge_dist_x * dist_to_impulse_factor / PIXEL_PER_METER
        self.shoot_impulse_y = - charge_dist_y * dist_to_impulse_factor / PIXEL_PER_METER
        if getMouseReleased()[1] then
            -- apply the impulse when the left mouse is released to shoot the projectile
            self.projectile.body:applyLinearImpulse(self.shoot_impulse_x, self.shoot_impulse_y)
            self.shoot_impulse_x, self.shoot_impulse_y = 0, 0
            -- restore gravity and mask of the projectile
            self.projectile.body:setGravityScale(1)
            self.projectile.body:getFixtures()[1]:setFilterData(self.proj_category, self.proj_mask, self.proj_group)
            self.proj_category, self.proj_mask, self.proj_group = nil, nil, nil
            self.state = 'empty'
        end
    end

    self.mouse_click = nil
end

function ProjectileLauncher:render()
    for _, ui_element in pairs(self.ui_elements) do
        love.graphics.draw(gTextures[ui_element.texture], gFrames[ui_element.texture][ui_element.frame_id],
            ui_element.x, ui_element.y, 0, 1, 1,
            ui_element.render_offset_x, ui_element.render_offset_y)
    end

    -- draw the projected trajectory. see: http://www.iforce2d.net/b2dtut/projected-trajectory
    if self.shoot_impulse_x ~= 0 or self.shoot_impulse_y ~= 0 then
        -- To calculate the projected trajectory, a formula must be derived
        -- that uses the same integration scheme as Box2D to compute future positions.
        -- Box2D uses semi-implicit Euler integration where the next position is calculated like this:
        -- v: velocity, v_0: velocity of the previous frame, a: acceleration,
        -- d: position, d_0: position of the previous frame
        -- d = v * t + d_0 = a * t^2 + v_0 * t + d_0
        -- A position d(n) cannot be obtained by just multiplying the frame time t by a number of frames n.
        -- Instead this formula should be used:
        -- d(n): position of the n-th frame, v(0): starting velocity, d(0): starting position
        -- d(n) = a * t^2 * (n^2 + n) / 2 + v(0) * t * n + d(0)
        -- (can be derived by finding a calculation rule from the series d(0), d(1), d(2), ...)

        -- Use a fixed frame time to always render the same trajectory. This frame time variable affects the
        -- trajectory point spacing. The actual frame time has no (major) impact on the real trajectory.
        local frame_time = 1 / 60
        local shoot_v_x = self.shoot_impulse_x / self.projectile.body:getMass()
        local shoot_v_y = self.shoot_impulse_y / self.projectile.body:getMass()
        local body_x, body_y = self.projectile.body:getPosition()
        local _, g_y = self.world:getGravity()

        -- current and previous trajectory point
        -- A point gets calculated for every frame_step (certain number of frames)
        local traj_x, traj_y
        local traj_prev_x, traj_prev_y
        local frame_step = 3
        for step_n = 0, 100, frame_step do
            traj_prev_x, traj_prev_y = traj_x, traj_y

            traj_x = body_x + step_n * frame_time * shoot_v_x
            traj_y = body_y + shoot_v_y * frame_time * step_n + g_y * frame_time^2 * (step_n^2 + step_n) / 2

            -- Do ray casts between points to see when the trajectory hits something.
            -- The ray cast intersection point will be the last point that is drawn.
            self.trajectory_intersect_x, self.trajectory_intersect_y = nil, nil
            if traj_prev_x then
                self.world:rayCast(traj_prev_x, traj_prev_y, traj_x, traj_y, self.callbackRayCast)
            end
            if self.trajectory_intersect_x then
                traj_x, traj_y = self.trajectory_intersect_x, self.trajectory_intersect_y
            end

            local traj_sprite = GAME_ELEMENT_DEFS['projectile-trajectory-point']
            love.graphics.draw(gTextures[traj_sprite.texture], gFrames[traj_sprite.texture][traj_sprite.frame_id],
                traj_x, traj_y, 0, 1, 1,
                traj_sprite.render_offset_x, traj_sprite.render_offset_y)

            if self.trajectory_intersect_x then
                break
            end
        end
    end
end
