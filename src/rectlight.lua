local _areaLightStr = [[
    #define M_PI 3.14159265358979323846

    // Ambient Light
    uniform vec3 in_ambientLightColor;

    // Rect Area Lights
    #define MAX_LIGHT 2
    uniform vec3 in_rectLightColor[MAX_LIGHT];
    uniform vec3 in_rectLightCenter[MAX_LIGHT];
    uniform vec3 in_rectLightRight[MAX_LIGHT];
    uniform vec3 in_rectLightUp[MAX_LIGHT];
    uniform vec3 in_rectLightNormal[MAX_LIGHT];
    uniform vec3 in_rectLightDimension[MAX_LIGHT];
    uniform float in_rectLightRadius[MAX_LIGHT];
    uniform int in_rectLightCount;

    vec3 ClosestPointOnPlane(vec3 point, vec3 planeCenter, vec3 planeNormal)
    {
        float distance = dot(planeNormal, point - planeCenter);
        return point - distance * planeNormal;
    }

    float Saturate(float v) {
        return clamp(v, 0.0, 1.0);
    }

    float RectangleSolidAngle(vec3 worldPos, vec3 p0, vec3 p1, vec3 p2, vec3 p3)
    {
        vec3 v0 = p0 - worldPos;
        vec3 v1 = p1 - worldPos;
        vec3 v2 = p2 - worldPos;
        vec3 v3 = p3 - worldPos;

        vec3 n0 = normalize(cross(v0, v1));
        vec3 n1 = normalize(cross(v1, v2));
        vec3 n2 = normalize(cross(v2, v3));
        vec3 n3 = normalize(cross(v3, v0));

        float g0 = acos(dot(-n0, n1));
        float g1 = acos(dot(-n1, n2));
        float g2 = acos(dot(-n2, n3));
        float g3 = acos(dot(-n3, n0));

        return g0 + g1 + g2 + g3 - 2.0f * M_PI;
    }

    float PyramidSolidAngle(float dist, float halfW, float halfH)
    {
        float a = halfW;
        float b = halfH;
        float h = dist;
        return 4 * asin (a * b / sqrt (( a * a + h * h) * (b * b + h * h) ));
    }

    vec3 RectLightShade(vec3 worldPos, vec3 worldNormal, int ind)
    {
        vec3 planeC = in_rectLightCenter[ind];
        vec3 planeR = in_rectLightRight[ind];
        vec3 planeU = in_rectLightUp[ind];
        vec3 planeN = in_rectLightNormal[ind];
        float radius = in_rectLightRadius[ind];
        vec3 lightColor = in_rectLightColor[ind];

        float planeHalfW = in_rectLightDimension[ind].x / 2.0;
        float planeHalfH = in_rectLightDimension[ind].y / 2.0;

        // If the point is on the other side of the light, not shaded.
        float check = dot(worldPos - planeC, planeN);
        if (check < 0.0f)
            return vec3(0.0);

        vec3 posTL = planeC + planeR * -planeHalfW + planeU *  planeHalfH;
        vec3 posTR = planeC + planeR *  planeHalfW + planeU *  planeHalfH;
        vec3 posBL = planeC + planeR * -planeHalfW + planeU * -planeHalfH;
        vec3 posBR = planeC + planeR *  planeHalfW + planeU * -planeHalfH;

        // Calculate the distance from the plane.
        vec3 pointOnPlane = ClosestPointOnPlane(worldPos, planeC, planeN);
        float dist = distance(worldPos, pointOnPlane);

        float solidAngle = RectangleSolidAngle(worldPos, posTL, posBL,
            posBR, posTR);

        float d = Saturate(dot(normalize(posTL - worldPos), worldNormal))
            + Saturate(dot(normalize(posBL - worldPos), worldNormal))
            + Saturate(dot(normalize(posBR - worldPos), worldNormal))
            + Saturate(dot(normalize(posTR - worldPos), worldNormal))
            + Saturate(dot(normalize(planeC - worldPos), worldNormal));

        // Calculate the falloff based on the light radius and distance from
        // plane.
        float falloff = 1.0 - Saturate(dist / radius);

        // You can tune the "0.2" constant to find something that looks
        // good enough.
        float illuminance = 0.2f * solidAngle * d * falloff;

        return illuminance * lightColor;
    }
]]

return function ()
    return lovr.graphics.newShader([[
        out vec3 v_worldPos;
        out vec3 v_worldNormal;

        vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
            v_worldPos = (lovrModel * vertex).xyz;
            // FIXME: this does not work on Quest 2 for some reason. I
            // was only able to get it working by not touching the
            // lovrNormal vector.
            v_worldNormal = normalize(lovrNormalMatrix * lovrNormal);

            return projection * transform * vertex;
        }
    ]], _areaLightStr .. [[
        in vec3 v_worldPos;
        in vec3 v_worldNormal;

        vec4 color(vec4 color, sampler2D image, vec2 uv) {
            vec3 res = in_ambientLightColor;

            for (int i = 0; i < in_rectLightCount; i++) {
                res += RectLightShade(v_worldPos, v_worldNormal, i);
            }

            return vec4(res, 1);
        }
    ]], { flags = { highp = true } })
end

