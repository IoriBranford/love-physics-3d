---@class Body3DData
---@field z number
---@field height number
---@field floorZ number
---@field ceilingZ number
---@field velZ number
---@field restitutionZ number
---@field gravity number

---@class Color
---@field red number
---@field green number
---@field blue number

---@class BodyUserData:Body3DData,Color

local world ---@type love.World
local player ---@type love.Body

local WorldBottom = 0
local WorldTop = 0x10000000

---@param a love.Fixture
---@param b love.Fixture
local function testCollisionZ(a, b)
    local aud, bud = a:getBody():getUserData(), b:getBody():getUserData()
    if not aud or not bud then return true end

    local az, bz = aud.z, bud.z
    local ah, bh = aud.height, bud.height
    if not az or not bz or not ah or not bh then return true end

    return az < bz + bh and bz < az + ah
end

---@param a love.Fixture
---@param b love.Fixture
---@param c love.Contact
local function preSolve3D(a, b, c)
    c:setEnabled(testCollisionZ(a, b))
end

---@param body1 love.Body
local function updateBodyFloorAndCeiling(body1)
    local ud1 = body1:getUserData() ---@type BodyUserData
    local bottom1 = ud1.z
    local top1 = bottom1 + ud1.height
    local floorZ = WorldBottom
    local ceilingZ = WorldTop
    for _, contact in pairs(body1:getContacts()) do
        ---@cast contact love.Contact
        if contact:isTouching() then
            local f1, f2 = contact:getFixtures()
            local body2 = f2:getBody() == body1 and f1:getBody() or f2:getBody()
            local ud2 = body2:getUserData() ---@type BodyUserData
            local bottom2 = ud2.z
            local top2 = bottom2 + ud2.height
            if top2 <= bottom1 then
                floorZ = math.max(floorZ, top2)
            end
            if bottom2 >= top1 then
                ceilingZ = math.min(ceilingZ, bottom2)
            end
        end
    end

    ud1.floorZ = floorZ
    ud1.ceilingZ = ceilingZ
    return floorZ, ceilingZ
end

---@param body love.Body
local function updateBodyZ(body, dt)
    local ud = body:getUserData() ---@type BodyUserData
    ud.velZ = ud.velZ + ud.gravity*dt
    ud.z = ud.z + ud.velZ*dt

    local floorZ, ceilingZ = ud.floorZ, ud.ceilingZ
    if ud.z >= ceilingZ - ud.height then
        ud.z = ceilingZ - ud.height
        ud.velZ = 0
    end
    if ud.z <= floorZ then
        ud.z = floorZ
        ud.velZ = 0
    end
end

function love.load()
    world = love.physics.newWorld(0, 0, false)
    world:setCallbacks(nil, nil, preSolve3D, nil)

    player = love.physics.newBody(world, 400, 300, "dynamic")
    love.physics.newFixture(player, love.physics.newCircleShape(16))
    ---@type BodyUserData
    local playerData = {
        z = 0,
        height = 64,
        floorZ = WorldBottom,
        ceilingZ = WorldTop,
        velZ = 0,
        restitutionZ = 0,
        gravity = -180,
        red = 1, green = .5, blue = .5
    }
    player:setUserData(playerData)

    local playerX, playerY = player:getPosition()
    local triangles = love.math.triangulate(
        32 * math.cos(math.pi*0/3), 32 * math.sin(math.pi*0/3),
        32 * math.cos(math.pi*1/3), 32 * math.sin(math.pi*1/3),
        32 * math.cos(math.pi*2/3), 32 * math.sin(math.pi*2/3),
        32 * math.cos(math.pi*3/3), 32 * math.sin(math.pi*3/3),
        32 * math.cos(math.pi*4/3), 32 * math.sin(math.pi*4/3),
        32 * math.cos(math.pi*5/3), 32 * math.sin(math.pi*5/3)
    )
    for i = 1, 6 do
        local platformX, platformY = playerX + 100*math.cos(math.pi*i/3), playerY + 100*math.sin(math.pi*i/3)
        local platform = love.physics.newBody(world, platformX, platformY, "static")
        for _, triangle in ipairs(triangles) do
            love.physics.newFixture(platform, love.physics.newPolygonShape(triangle))
        end
        ---@type BodyUserData
        local platformData = {
            z = 16*i,
            height = 32,
            floorZ = WorldBottom,
            ceilingZ = WorldTop,
            velZ = 0,
            restitutionZ = 0,
            gravity = 0,
            red = .5, green = .5, blue = 1
        }
        platform:setUserData(platformData)
    end
    love.graphics.setBackgroundColor(0, .5, 0)
end

function love.update(dt)
    world:update(dt)

    local ix, iy = 0, 0
    ix = ix + (love.keyboard.isDown("a") and -1 or 0)
    ix = ix + (love.keyboard.isDown("d") and 1 or 0)
    iy = iy + (love.keyboard.isDown("w") and -1 or 0)
    iy = iy + (love.keyboard.isDown("s") and 1 or 0)
    player:setLinearVelocity(180*ix, 180*iy)

    for _, body in pairs(world:getBodies()) do
        ---@cast body love.Body
        updateBodyFloorAndCeiling(body)
        updateBodyZ(body, dt)
    end

    local pud = player:getUserData() ---@type BodyUserData
    if pud.z == pud.floorZ and pud.z + pud.height < pud.ceilingZ then
        if love.keyboard.isDown("space") then
            pud.velZ = -pud.gravity
            pud.z = pud.z + pud.velZ*dt
        end
    end
end

function love.draw()
    local bodies = world:getBodies() ---@type love.Body[]

    table.sort(bodies,
    ---@param a love.Body
    ---@param b love.Body
    function(a, b)
        local ay, by = a:getY(), b:getY()
        if ay ~= by then return ay < by end

        local az, bz = a:getUserData().z, b:getUserData().z
        if az ~= bz then return az < bz end

        local ax, bx = a:getX(), b:getX()
        return ax < bx
    end)

    for _, body in ipairs(bodies) do
        local fixtures = body:getFixtures() ---@type love.Fixture[]
        local ud = body:getUserData() ---@type BodyUserData
        local x, y = body:getPosition()
        local z, height = ud.z, ud.height
        love.graphics.push()
        love.graphics.translate(x, y)
        local floorZ = ud.floorZ or WorldBottom
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

                love.graphics.line(-radius, -z, -radius, -z-height)
                love.graphics.line(radius, -z, radius, -z-height)

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