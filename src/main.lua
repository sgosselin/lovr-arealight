ASSET_PATH = './asset/'

-- Definition of a Rectangular Area Light.
local gLight0 = {
    center = lovr.math.newVec3(0, 1, 0),
    origin_center = lovr.math.newVec3(0, 1, 0),
    dim = lovr.math.newVec3(1.5, 1.0, 0),
    vecRight  = lovr.math.newVec3(1, 0, 0),
    vecUp     = lovr.math.newVec3(0, 1, 0),
    vecNormal = lovr.math.newVec3(0, 0, 1),
    color = lovr.math.newVec3(0, 1, 0),
    radius = 3,
}

local gLight1 = {
    center = lovr.math.newVec3(0, 1, 1),
    dim = lovr.math.newVec3(1, 1, 0),
    vecRight  = lovr.math.newVec3(1, 0, 0),
    vecUp     = lovr.math.newVec3(0, 0, 1),
    vecNormal = lovr.math.newVec3(0, -1, 0),
    color = lovr.math.newVec3(0.4, 0, 0),
    radius = 3,
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
    --img = lovr.data.newImage(ASSET_PATH .. 'tv0.png')
    --gLight0.color = calc_light_color(img)
    --gLight0.tex = lovr.graphics.newTexture(img)
    --gLight0.mat = lovr.graphics.newMaterial(gLight0.tex)
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

    if light.mat then
        lovr.graphics.setColor(1, 1, 1)
        lovr.graphics.plane(light.mat,
            light.center.x, light.center.y, light.center.z,
            light.dim.x, light.dim.y)
    else
        lovr.graphics.setColor(light.color.x, light.color.y, light.color.z)
        lovr.graphics.plane('fill',
            light.center.x, light.center.y, light.center.z,
            light.dim.x, light.dim.y)
    end
end

function shader_send_light(shader, light, ind)

end

function draw_room(room_plane, light)
    lovr.graphics.setShader(room_plane.shader)

    s = room_plane.shader
    s:send('in_rectLightColor',     { gLight0.color, gLight1.color })
    s:send('in_rectLightCenter',    { gLight0.center, gLight1.center })
    s:send('in_rectLightRight',     { gLight0.vecRight, gLight1.vecRight })
    s:send('in_rectLightUp',        { gLight0.vecUp, gLight1.vecUp })
    s:send('in_rectLightNormal',    { gLight0.vecNormal, gLight1.vecNormal})
    s:send('in_rectLightDimension', { gLight0.dim, gLight1.dim })
    s:send('in_rectLightRadius',    { gLight0.radius, gLight1.radius})
    s:send('in_rectLightCount', 2)

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
    --angle = angle + 0.01
    --gLight1.center.y = gLight1.origin_center.y + math.cos(1.5*angle)/2
end

slideshow_ind=0
slideshow_max=4
function lovr.keypressed(key, scancode, r)
    if key == 'space' then
        slideshow_ind = (slideshow_ind + 1) % slideshow_max

        path = ASSET_PATH .. 'tv' .. slideshow_ind .. '.png'
        print('using texture: ' .. path)

        img = lovr.data.newImage(path)
        gLight0.color = calc_light_color(img)
        gLight0.tex = lovr.graphics.newTexture(img)
        gLight0.mat = lovr.graphics.newMaterial(gLight0.tex)
    end

    if key == 'z' then gLight0.radius = gLight0.radius + 1 end
    if key == 'x' then gLight0.radius = gLight0.radius - 1 end
end

function lovr.draw()
    lovr.graphics.setBackgroundColor(.05, .05, .05)

    draw_world_axes()
    draw_room(gRoomPlane)
    draw_rectlight(gLight0)
end

function lovr.conf(t)
  t.gammacorrect = true
end
