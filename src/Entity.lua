--[[
    The Entity Class contains one or multiple PhysBody Objects.
    If bodies are connected together with a joint, the joint can optionally be stored in the joints list.
    Entity objects are the content of the level entity list.
]]

Entity = Class{}

function Entity:init(def)
    -- is_remove gets set to true, when all elements in the bodies table are removed.
    -- this object will then get removed from the level entity table.
    self.is_remove = false
    -- render order:
    --  primarily defined by render_prio
    --  secondarily defined by the order of the sub-tables inside the level entity table (inside renderListSync())
    --  thirdly defined by the order of entities in a level entity sub-table
    -- lower numbers mean a lower priority. The entity with the highest priority will be drawn last (over the others).
    self.render_prio = def.render_prio or 5
    -- position/ orientation definition formatting. each entry in these lists belongs to one body
    local x_list = type(def.x) == "table" and def.x or {def.x}
    local y_list = type(def.y) == "table" and def.y or {def.y}
    local angle_list = type(def.angle) == "table" and def.angle or {def.angle}
    -- list of bodies and joints between bodies. joints can only be created after the bodies have been instantiated.
    self.bodies = {}
    self.joints = {}
    -- create bodies from definitions
    for i = 1, #def.bodies do
        local body_def = {world = def.world, parent = self, x = x_list[i], y = y_list[i], angle = angle_list[i]}
        table.extend(body_def, def.bodies[i])
        table.insert(self.bodies, PhysBody(body_def))
    end
end

function Entity:update(dt)
    for i = #self.bodies, 1, -1 do
        self.bodies[i]:update()
        -- destroy() removes the body reference from the Box2D World and frees the memory.
        -- when destroying the body, all attached fixtures and joints get destroyed automatically.
        -- all other references to destroyed objects should be removed, to not allow dereferences any more.
        if self.bodies[i].is_remove then
            Event.dispatch('remove-body', self.bodies[i])

            -- remove attached joints from the joint list
            for _, joint in pairs(self.bodies[i].body:getJoints()) do
                local joint_k = table.findkey(self.joints, joint)
                if joint_k then table.remove(self.joints, joint_k) end
            end
            self.bodies[i].body:destroy()
            table.remove(self.bodies, i)

            if #self.bodies == 0 then
                self.is_remove = true
            end
        end
    end
end

function Entity:render()
    for _, body in pairs(self.bodies) do
        body:render()
    end
    if IS_DEBUG then
        -- render the anchor points of the joint (1 or 2, always 1 for revolute joint)
        love.graphics.setColor(255/255, 0/255, 0/255, 255/255)
        love.graphics.setPointSize(5)
        for  _, joint in pairs(self.joints) do
            love.graphics.points(joint:getAnchors())
        end
        love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
    end
end
