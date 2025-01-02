local world ---@type love.World
local player ---@type love.Body
local cube ---@type love.Body

function love.load()
    world = love.physics.newWorld(0, 0, false)
    player = love.physics.newBody(world, 400, 300, "dynamic")
    love.physics.newFixture(player, love.physics.newCircleShape(16))
    player:setUserData({
        z = 0,
        height = 64,
        red = 1, green = .5, blue = .5
    })

    cube = love.physics.newBody(world, 600, 300, "static")
    local triangles = love.math.triangulate(
        32 * math.cos(math.pi*0/3), 32 * math.sin(math.pi*0/3),
        32 * math.cos(math.pi*1/3), 32 * math.sin(math.pi*1/3),
        32 * math.cos(math.pi*2/3), 32 * math.sin(math.pi*2/3),
        32 * math.cos(math.pi*3/3), 32 * math.sin(math.pi*3/3),
        32 * math.cos(math.pi*4/3), 32 * math.sin(math.pi*4/3),
        32 * math.cos(math.pi*5/3), 32 * math.sin(math.pi*5/3)
    )
    for _, triangle in ipairs(triangles) do
        love.physics.newFixture(cube, love.physics.newPolygonShape(triangle))
    end
    cube:setUserData({
        z = 32,
        height = 32,
        red = .5, green = .5, blue = 1
    })
    love.graphics.setBackgroundColor(0, .5, 0)
end

function love.update(dt)
    local ix, iy = 0, 0
    ix = ix + (love.keyboard.isDown("a") and -1 or 0)
    ix = ix + (love.keyboard.isDown("d") and 1 or 0)
    iy = iy + (love.keyboard.isDown("w") and -1 or 0)
    iy = iy + (love.keyboard.isDown("s") and 1 or 0)

    player:setLinearVelocity(180*ix, 180*iy)
    world:update(dt)
end

function love.draw()
    local bodies = world:getBodies() ---@type love.Body[]

    table.sort(bodies,
    ---@param a love.Body
    ---@param b love.Body
    function(a, b)
        local ay, by = a:getY(), b:getY()
        if ay < by then return true end

        local az, bz = a:getUserData().z, b:getUserData().z
        if az < bz then return true end

        local ax, bx = a:getX(), b:getX()
        return ax < bx
    end)

    for _, body in ipairs(bodies) do
        local fixtures = body:getFixtures() ---@type love.Fixture[]
        local ud = body:getUserData()
        local x, y = body:getPosition()
        local z, height = ud.z, ud.height
        love.graphics.push()
        love.graphics.translate(x, y)
        local floorZ = 0
        for _, fixture in ipairs(fixtures) do
            local shape = fixture:getShape() ---@type love.Shape
            local shapeType = shape:getType()
            if shapeType == "circle" then
                ---@cast shape love.CircleShape
                local radius = shape:getRadius()

                if z > floorZ then
                    love.graphics.setColor(0, 0, 0, .5)
                    love.graphics.circle("fill", 0, -floorZ, radius)
                end

                love.graphics.setColor(ud.red, ud.green, ud.blue, .5)
                love.graphics.circle("fill", 0, -z, radius)
                love.graphics.setColor(ud.red, ud.green, ud.blue)
                love.graphics.circle("line", 0, -z, radius)

                love.graphics.line(-radius, 0, -radius, -z-height)
                love.graphics.line(radius, 0, radius, -z-height)

                love.graphics.setColor(ud.red, ud.green, ud.blue, .5)
                love.graphics.circle("fill", 0, -z-height, radius)
                love.graphics.setColor(ud.red, ud.green, ud.blue)
                love.graphics.circle("line", 0, -z-height, radius)
            elseif shapeType == "polygon" then
                ---@cast shape love.PolygonShape
                local points = {shape:getPoints()}

                if z > floorZ then
                    love.graphics.push()
                    love.graphics.translate(0, -floorZ)
                    love.graphics.setColor(0, 0, 0, .5)
                    love.graphics.polygon("fill", points)
                    love.graphics.pop()
                end

                love.graphics.push()
                love.graphics.translate(0, -z)

                love.graphics.setColor(ud.red, ud.green, ud.blue, .5)
                love.graphics.polygon("fill", points)
                love.graphics.setColor(ud.red, ud.green, ud.blue)
                love.graphics.polygon("line", points)

                love.graphics.setColor(ud.red, ud.green, ud.blue, .5)
                local px1, py1 = points[#points-1], points[#points]
                for i = 2, #points, 2 do
                    local px, py = points[i-1], points[i]
                    love.graphics.polygon("fill", px1, py1 - height, px, py - height, px, py, px1, py1)
                    px1, py1 = px, py
                end
                love.graphics.setColor(ud.red, ud.green, ud.blue)
                for i = 2, #points, 2 do
                    local px, py = points[i-1], points[i]
                    love.graphics.line(px, py, px, py - height)
                end

                love.graphics.translate(0, -height)
                love.graphics.setColor(ud.red, ud.green, ud.blue, .5)
                love.graphics.polygon("fill", points)
                love.graphics.setColor(ud.red, ud.green, ud.blue)
                love.graphics.polygon("line", points)

                love.graphics.pop()
            end
        end
        love.graphics.pop()
    end
end