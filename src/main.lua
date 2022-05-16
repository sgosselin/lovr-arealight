ASSET_PATH = './asset/'

-- Definition of a Rectangular Area Light.
local gLight = {
    center = lovr.math.newVec3(0, 1, 0),
    origin_center = lovr.math.newVec3(0, 1, 0),
    size = lovr.math.newVec2(1.5, 1.0),
    vecRight  = lovr.math.newVec3(1, 0, 0),
    vecUp     = lovr.math.newVec3(0, 1, 0),
    vecNormal = lovr.math.newVec3(0, 0, 1),
    color = lovr.math.newVec3(1, 1, 1),
    radius = 1,
}

function calc_light_color(image)
    local w, h = image:getDimensions()

    local res = lovr.math.newVec3(0, 0, 0)

    local r, g, b, _ = image:getPixel(math.floor(0.2 * w), math.floor(0.2 * h))
    res:add(lovr.math.newVec3(r, g, b))
    r, g, b, _ = image:getPixel(math.floor(0.2 * w), math.floor(0.5 * h))
    res:add(lovr.math.newVec3(r, g, b))
    r, g, b, _ = image:getPixel(math.floor(0.2 * w), math.floor(0.8 * h))
    res:add(lovr.math.newVec3(r, g, b))

    r, g, b, _ = image:getPixel(math.floor(0.5 * w), math.floor(0.2 * h))
    res:add(lovr.math.newVec3(r, g, b))
    r, g, b, _ = image:getPixel(math.floor(0.5 * w), math.floor(0.5 * h))
    res:add(lovr.math.newVec3(r, g, b))
    r, g, b, _ = image:getPixel(math.floor(0.5 * w), math.floor(0.8 * h))
    res:add(lovr.math.newVec3(r, g, b))


    r, g, b, _ = image:getPixel(math.floor(0.8 * w), math.floor(0.2 * h))
    res:add(lovr.math.newVec3(r, g, b))
    r, g, b, _ = image:getPixel(math.floor(0.8 * w), math.floor(0.5 * h))
    res:add(lovr.math.newVec3(r, g, b))
    r, g, b, _ = image:getPixel(math.floor(0.8 * w), math.floor(0.8 * h))
    res:add(lovr.math.newVec3(r, g, b))

    res:div(9)

    return res
end

function create_room_plane()
    local plane = {}

    plane.mesh = lovr.graphics.newMesh({
        { 'lovrPosition', 'float', 3 },
        { 'lovrNormal', 'float', 3 },
        { 'lovrTexCoord', 'float', 2}
    }, 6, 'triangles')

    plane.mesh:setVertices({
        {-1, 0, -1,     0, 1, 0,    0, 0},
        {-1, 0, 1,      0, 1, 0,    1, 0},
        {1, 0, 1,       0, 1, 0,    1, 1},
        {1, 0, 1,       0, 1, 0,    1, 1},
        {1, 0, -1,      0, 1, 0,    0, 1},
        {-1, 0, -1,     0, 1, 0,    0, 0},
    })

    plane.shader = require('rectlight')()

    return plane
end

function lovr.load()
    gRoomPlane = create_room_plane()

    -- select an initial texture for the light color.
    img = lovr.data.newImage(ASSET_PATH .. 'tv0.png')
    gLight.color = calc_light_color(img)
    gLight.tex = lovr.graphics.newTexture(img)
    gLight.mat = lovr.graphics.newMaterial(gLight.tex)
end

function draw_world_axes()
    lovr.graphics.setShader()
    lovr.graphics.setColor(1, 0, 0)
    lovr.graphics.line(0, 0, 0, 1, 0, 0)
    lovr.graphics.setColor(0, 1, 0)
    lovr.graphics.line(0, 0, 0, 0, 1, 0)
    lovr.graphics.setColor(0, 0, 1)
    lovr.graphics.line(0, 0, 0, 0, 0, 1)
end

function draw_rectlight(light)
    lovr.graphics.setShader()
    lovr.graphics.setColor(1, 1, 1)
    lovr.graphics.plane(light.mat,
        light.center.x, light.center.y, light.center.z,
        light.size.x, light.size.y)
end

function draw_room(room_plane, light)
    lovr.graphics.setShader(room_plane.shader)

    room_plane.shader:send('in_lightPlaneColor', light.color)
    room_plane.shader:send('in_lightPlaneCenter', light.center)
    room_plane.shader:send('in_lightPlaneRight', light.vecRight)
    room_plane.shader:send('in_lightPlaneUp', light.vecUp)
    room_plane.shader:send('in_lightPlaneNormal', light.vecNormal)
    room_plane.shader:send('in_lightPlaneW', light.size.x)
    room_plane.shader:send('in_lightPlaneH', light.size.y)
    room_plane.shader:send('in_lightPlaneRadius', light.radius)
    room_plane.shader:send('in_lightPlaneTex', light.tex)

    -- bottom
    lovr.graphics.push()
    lovr.graphics.scale(10, 0, 10)
    room_plane.mesh:draw()
    lovr.graphics.pop()
    -- back
    lovr.graphics.push()
    lovr.graphics.translate(0, 2, -2)
    lovr.graphics.rotate(math.pi/2, 1, 0, 0)
    lovr.graphics.scale(2, 0, 2)
    room_plane.mesh:draw()
    lovr.graphics.pop()
    -- left
    lovr.graphics.push()
    lovr.graphics.translate(-2, 2, 0)
    lovr.graphics.rotate(math.pi/2, 0, 0, 1)
    lovr.graphics.scale(2, 0, 2)
    room_plane.mesh:draw()
    lovr.graphics.pop()
    -- right
    lovr.graphics.push()
    lovr.graphics.translate(2, 2, 0)
    lovr.graphics.rotate(-math.pi/2, 0, 0, 1)
    lovr.graphics.scale(2, 0, 2)
    room_plane.mesh:draw()
    lovr.graphics.pop()
end

angle=0
function lovr.update(dt)
    angle = angle + 0.01
    gLight.center.y = gLight.origin_center.y + math.cos(1.5*angle)/2
end

slideshow_ind=0
slideshow_max=4
function lovr.keypressed(key, scancode, r)
    if key == 'space' then
        slideshow_ind = (slideshow_ind + 1) % slideshow_max

        path = ASSET_PATH .. 'tv' .. slideshow_ind .. '.png'
        print('using texture: ' .. path)

        img = lovr.data.newImage(path)
        gLight.color = calc_light_color(img)
        gLight.tex = lovr.graphics.newTexture(img)
        gLight.mat = lovr.graphics.newMaterial(gLight.tex)
    end

    if key == 'z' then gLight.radius = gLight.radius + 1 end
    if key == 'x' then gLight.radius = gLight.radius - 1 end
end

function lovr.draw()
    lovr.graphics.setBackgroundColor(.05, .05, .05)

    draw_world_axes()
    draw_room(gRoomPlane, gLight)
    draw_rectlight(gLight)
end
