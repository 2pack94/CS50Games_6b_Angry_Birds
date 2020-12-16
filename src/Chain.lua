--[[
    The Chain Class inherits from Entity.
    The chain uses circular bodies with wood texture/ properties and
    concatenates them with revolute joints.
    Start and End can also be attached to other bodies.
]]

Chain = Class{__includes = Entity}

function Chain:init(def)
    -- required input parameters:
    -- def.anchor1.x, def.anchor1.y: start point used to spawn chain elements
    -- def.anchor2.x, def.anchor2.y: spawn chain element up to this point
    -- def.num_elements: Number of bodies that get chained together.
    -- def.world: Box2D World reference

    -- definition that gets generated to instantiate the Entity parent class
    local total_def = {}
    -- definition for the PhysBody objects (chain elements) of the Entity class
    local body_def = {}
    -- list of coordinates that defines the spawn position for every body (chain element)
    local x_list, y_list = {}, {}

    -- distribute the chain elements evenly between start and end point.
    -- the first/ last element will have an offset of (spawn step size / 2) to the start/ end point.
    -- The start and end point will also be used as joint anchor points (world coordinates) to
    -- attach the chain to other bodies. This will only be the case if the anchor body is already instantiated
    -- and the point is inside a fixture of that body.
    -- When the joint constraints between the bodies are employed, the bodies will automatically move
    -- to a position where the constraints are fulfilled. They will also automatically adjust their orientation,
    -- so it does not matter in which direction the chain is created or
    -- what the spawn distance between each element is (determined by start- and endpoint).
    local start_end_vec_x = def.anchor2.x - def.anchor1.x
    local start_end_vec_y = def.anchor2.y - def.anchor1.y
    local spawn_step_x = start_end_vec_x / def.num_elements
    local spawn_step_y = start_end_vec_y / def.num_elements
    local spawn_start_x = def.anchor1.x + spawn_step_x / 2
    local spawn_start_y = def.anchor1.y + spawn_step_y / 2
    for i = 1, def.num_elements do
        x_list[i] = spawn_start_x + spawn_step_x * (i - 1)
        y_list[i] = spawn_start_y + spawn_step_y * (i - 1)
        table.insert(body_def, GAME_ELEMENT_DEFS['wood_circle'].bodies[1])
    end

    -- give the chain a lower render_prio so it will be rendered behind the body it is attached to.
    total_def = {world = def.world, render_prio = 3, x = x_list, y = y_list, bodies = body_def}

    -- init parent
    Entity.init(self, total_def)

    -- create joints. The bodies must be already instantiated to create a joint between them.
    -- anchor point of the chain elements to the left and to the right in local coordinates.
    -- The right anchor of the current element gets connected with the left anchor of the next element.
    local joint_self_local_x1, joint_self_local_y1 = -TILE_SIZE / 2 + 2, 0
    local joint_self_local_x2, joint_self_local_y2 = TILE_SIZE / 2 - 2, 0
    -- body to that the start/ end of the chain potentially gets attached to
    local anchor_body
    -- First, the chain start point is the query point to find an anchor body
    local query_point_x, query_point_y = def.anchor1.x, def.anchor1.y

    -- callback function for the queryBoundingBox() call
    local callbackWorldQuery = function(fixture)
        -- check if query point is inside fixture
        if fixture:testPoint(query_point_x, query_point_y) then
            -- don't connect chain to a body of self
            for _, phys_body in pairs(self.bodies) do
                for _, loop_fixt in pairs(phys_body.body:getFixtures()) do
                    if fixture == loop_fixt then
                        return true
                    end
                end
            end
            anchor_body = fixture:getBody()
            return false
        end
        return true
    end

    -- check if a fixture's AABB intersects with the query AABB (only a point in this case)
    def.world:queryBoundingBox(query_point_x, query_point_y, query_point_x, query_point_y,
        callbackWorldQuery)

    -- if an anchor body was found, connect the first chain element to it.
    -- The left anchor point of the chain element will be connected to where the query point is on the anchor body.
    if anchor_body then
        local self_body = self.bodies[1].body
        local joint_self_x1, joint_self_y1 = self_body:getWorldPoints(joint_self_local_x1, joint_self_local_y1)
        table.insert(self.joints, love.physics.newRevoluteJoint(
            self_body, anchor_body, joint_self_x1, joint_self_y1, query_point_x, query_point_y))
    end

    -- connect chain elements
    for i = 1, #self.bodies - 1 do
        local joint_self_x1, joint_self_y1 = self.bodies[i + 1].body:getWorldPoints(joint_self_local_x1, joint_self_local_y1)
        local joint_self_x2, joint_self_y2 = self.bodies[i].body:getWorldPoints(joint_self_local_x2, joint_self_local_y2)
        table.insert(self.joints, love.physics.newRevoluteJoint(
            self.bodies[i].body, self.bodies[i + 1].body, joint_self_x2, joint_self_y2, joint_self_x1, joint_self_y1))
    end

    -- The chain end point is now the query point to find an anchor body
    anchor_body = nil
    query_point_x, query_point_y = def.anchor2.x, def.anchor2.y
    def.world:queryBoundingBox(query_point_x, query_point_y, query_point_x, query_point_y,
        callbackWorldQuery)

    -- if an anchor body was found, connect the last chain element to it.
    -- The right anchor point of the chain element will be connected to where the query point is on the anchor body.
    if anchor_body then
        local self_body = self.bodies[#self.bodies].body
        local joint_self_x2, joint_self_y2 = self_body:getWorldPoints(joint_self_local_x2, joint_self_local_y2)
        table.insert(self.joints, love.physics.newRevoluteJoint(
            self_body, anchor_body, joint_self_x2, joint_self_y2, query_point_x, query_point_y))
    end
end
