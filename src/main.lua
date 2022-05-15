ASSET_PATH = './asset/'

-- Definition of a Rectangular Area Light.
local gLight = {
    -- plane's center coordinate
    center = lovr.math.newVec3(0, 1, 0),
    origin_center = lovr.math.newVec3(0, 1, 0),
    -- plane's size
    size = lovr.math.newVec2(1.5, 1.0),
    -- plane's vectors
    vecRight  = lovr.math.newVec3(1, 0, 0),
    vecUp     = lovr.math.newVec3(0, 1, 0),
    vecNormal = lovr.math.newVec3(0, 0, 1),
    -- light's color; not used right now since we get the light color
    -- from its texture.
    color = lovr.math.newVec3(1, 1, 1),
    -- light's radius
    radius = 2,
}

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
    gLight.tex = lovr.graphics.newTexture(ASSET_PATH .. 'tv0.png')
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
    lovr.graphics.scale(2, 0, 2)
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

        gLight.tex = lovr.graphics.newTexture(path)
        gLight.mat = lovr.graphics.newMaterial(gLight.tex)
    end
end

function lovr.draw()
    lovr.graphics.setBackgroundColor(.05, .05, .05)

    draw_world_axes()
    draw_room(gRoomPlane, gLight)
    draw_rectlight(gLight)
end
