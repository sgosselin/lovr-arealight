local _areaLightStr = [[
    #define M_PI 3.14159265358979323846

    uniform vec3 in_lightPlaneColor; /* unused */
    uniform vec3 in_lightPlaneCenter;
    uniform vec3 in_lightPlaneRight;
    uniform vec3 in_lightPlaneUp;
    uniform vec3 in_lightPlaneNormal;
    uniform float in_lightPlaneW;
    uniform float in_lightPlaneH;
    uniform float in_lightPlaneRadius;
    uniform sampler2D in_lightPlaneTex;

    // Returns a basic approximation of the rectangular light color by
    // sampling nine points from its color texture.
    //
    // TODO: we should do this on the CPU instead; the color does not change during the
    // rendering of the scene so we can calculate it once instead of for every shaded
    // pixels.
    vec3 ApproximateLightColor()
    {
        vec4 res = vec4(0,0,0,0);

        res += texture(in_lightPlaneTex, vec2(0.2, 0.2));
        res += texture(in_lightPlaneTex, vec2(0.2, 0.5));
        res += texture(in_lightPlaneTex, vec2(0.2, 0.8));
        res += texture(in_lightPlaneTex, vec2(0.5, 0.2));
        res += texture(in_lightPlaneTex, vec2(0.5, 0.5));
        res += texture(in_lightPlaneTex, vec2(0.5, 0.8));
        res += texture(in_lightPlaneTex, vec2(0.8, 0.2));
        res += texture(in_lightPlaneTex, vec2(0.8, 0.5));
        res += texture(in_lightPlaneTex, vec2(0.8, 0.8));

        return res.xyz / 9.0;
    }

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

    vec3 RectLightShade(vec3 worldPos, vec3 worldNormal)
    {
        float check = dot(worldPos - in_lightPlaneCenter, in_lightPlaneNormal);
        if (check < 0.0f) {
            return vec3(0.0);
        }

        vec3 planeC = in_lightPlaneCenter;
        vec3 planeR = in_lightPlaneRight;
        vec3 planeU = in_lightPlaneUp;
        vec3 planeN = in_lightPlaneNormal;

        float planeHalfW = in_lightPlaneW / 2.0;
        float planeHalfH = in_lightPlaneH / 2.0;

        vec3 posTL = planeC + planeR * -planeHalfW + planeU *  planeHalfH;
        vec3 posTR = planeC + planeR *  planeHalfW + planeU *  planeHalfH;
        vec3 posBL = planeC + planeR * -planeHalfW + planeU * -planeHalfH;
        vec3 posBR = planeC + planeR *  planeHalfW + planeU * -planeHalfH;

        float solidAngle = RectangleSolidAngle(worldPos, posTL, posBL, posBR, posTR);
        float d = Saturate(dot(normalize(posTL - worldPos), worldNormal))
            + Saturate(dot(normalize(posBL - worldPos), worldNormal))
            + Saturate(dot(normalize(posBR - worldPos), worldNormal))
            + Saturate(dot(normalize(posTR - worldPos), worldNormal))
            + Saturate(dot(normalize(planeC - worldPos), worldNormal));

        // Calculate the falloff based on the light radius and distance from plane.
        vec3 proj = ClosestPointOnPlane(worldPos, planeC, planeN);
        float dist = distance(worldPos, proj);
        float falloff = 1.0 - Saturate(dist / in_lightPlaneRadius);

        // You can tune the "0.2" constant to find something that looks good enough.
        float illuminance = 0.2f * solidAngle * d;

        // Approximate the light color based on a few points from its color texture.
        vec3 lightColor = ApproximateLightColor();

        return illuminance * lightColor * falloff;
    }
]]

return function ()
    return lovr.graphics.newShader(_areaLightStr .. [[
        out vec3 v_worldPos;
        out vec3 v_worldNormal;

        vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
            v_worldPos = (lovrModel * vertex).xyz;
            v_worldNormal = normalize(lovrNormalMatrix * lovrNormal);

            return projection * transform * vertex;
        }
    ]], _areaLightStr .. [[
        in vec3 v_worldPos;
        in vec3 v_worldNormal;

        vec4 color(vec4 color, sampler2D image, vec2 uv) {
            vec3 lightColor = RectLightShade(v_worldPos, v_worldNormal);
            return vec4(lightColor, 1.0);
        }
    ]])
end

