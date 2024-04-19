#pragma glsl4

// source: https://github.com/sleepokay/lichen/blob/master/lichen.pde

#define PI 3.1415926535897932384626433832795

// get angle between two vectors
float angle_between(vec2 v1, vec2 v2) {
    return acos(clamp(dot(normalize(v1), normalize(v2)), -1.0, 1.0));
}

// rotate vector
vec2 rotate(vec2 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c) * v;
}

// random
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float random(vec2 v, float offset)
{
    v.x += offset;
    v.y += offset;

    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0

    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
                      + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// ##

layout(rgba16f) uniform image2D image_in;
layout(rgba16f) uniform image2D image_out;

uniform int cell_size;
uniform int max_state;
uniform int max_growth;
uniform float time;

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

void computemain()
{
    ivec2 image_size = imageSize(image_in);
    float rng_offset = 13 * time;

    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    int width = image_size.x;
    int height = image_size.y;

    const float MAX_STATE = max_state;

    vec4 current = imageLoad(image_in, ivec2(x, y));
    imageStore(image_out, ivec2(x, y), current);  // pre-write to output image

    int n_excited_neighbors = 0;
    float max_angle = -1 * 1 / 0.; // negative infinity
    vec2 new_vector = vec2(0, 0);

    // config
    float excited_neighbors_threshold = 3;
    float growth_perturbation = 0.0;
    float max_angle_offset = 0.3;

    if (current.z == 0)
    {
        for (int xx = x - 1; xx <= x + 1; xx++) {
            for (int yy = y - 1; yy <= y + 1; yy++) {
                if (xx < 0 || xx >= width || yy < 0 || yy >= height)
                    continue;

                vec4 other = imageLoad(image_in, ivec2(xx, yy));
                if (other.z >= 1)
                    n_excited_neighbors += 1;

                // largest angle in local neighborhood
                for (int xxx = x - 1; xxx <= x + 1; xxx++) {
                    for (int yyy = y - 1; yyy <= y + 1; yyy++) {
                        if (xxx < 0 || xxx >= width || yyy < 0 || yyy >= height)
                            continue;

                        vec4 other_other = imageLoad(image_in, ivec2(xx, yy));
                        max_angle = max(max_angle, (angle_between(other.xy, other_other.xy) + PI) / (2 * PI));
                    }
                }

                // calculate vector
                if (other.z != 0) { // not empty
                    vec2 from = normalize(vec2(xx - x, yy - y));
                    new_vector += vec2(other.z / MAX_STATE) * ((other.xy + from.xy) / 2);
                }
            }
        }

        // excite empty cell if it has enough excited neighbors
        float n_neigbor_threshold = (1 + random(vec2(x, y), rng_offset)) * excited_neighbors_threshold;
        if (n_neigbor_threshold < n_excited_neighbors && max_angle > max_angle_offset) {
            vec4 to_store = imageLoad(image_in, ivec2(x, y));
            to_store.z = MAX_STATE;

            float angle_offset = random(vec2(x, y), rng_offset * 2) * PI / 8;
            to_store.xy = rotate(normalize(new_vector), angle_offset);
            imageStore(image_out, ivec2(x, y), to_store);
        }
    }
    else if (current.z > 0)
    {
        // advance living
        vec4 to_store = imageLoad(image_in, ivec2(x, y));

        // increase state
        to_store.z = clamp(to_store.z - 1, 1, MAX_STATE);

        // export
        imageStore(image_out, ivec2(x, y), to_store);
    }
}

/*
void computemain()
{
    ivec2 image_size = imageSize(image_in);
    ivec2 texel_coords = ivec2(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y);

    vec4 value = imageLoad(image_in, texel_coords);

    int x = texel_coords.x;
    int y = texel_coords.y;
    int width = image_size.x;
    int height = image_size.y;

    // config
    const bool no_death = true;
    const float constraining_angle = (50. / 360.) * 2. * PI;
    const float new_growth_perturbation = PI / 9.;
    const float growth_perturbation = PI / 58;
    const float excited_neighbors_parameter = 3;

    const int max_growth = max_growth;
    const int growth = 0;

    // states
    float MAXSTATE = max_state;
    const float ALIVE = 1;
    const float EMPTY = 0;

    float state = value.x;
    vec2 vector = value.yz;
    float age = value.w;

    float max_angle = -1 * 1 / 0.;  // negative infinity
    int excited_neighbors = 0;
    vec2 current_vector = vec2(0, 0);
    
    imageStore(image_out, ivec2(x, y), value);

    // update empty
    if (state == 0) {
        // https://github.com/sleepokay/lichen/blob/1e3837aa8396521e5b46cf97a122e74504520f0c/lichen.pde#L160
        for (int xx = x-1; xx <= x+1; xx++) {
            for (int yy = y - 1; yy <= y + 1; yy++) {
                if (xx < 0 || xx >= width / cell_size || yy < 0 || yy >= height / cell_size)
                    continue;

                if (imageLoad(image_in, ivec2(xx, yy)).x >= MAXSTATE * 0.97) {
                    excited_neighbors += 1;
                }

                for (int xxx = x - 1; xxx <= x + 1; xxx++) {
                    for (int yyy = y - 1; yyy < y + 1; yyy++) {
                        if (xxx < 0 || xxx >= width / cell_size || yyy < 0 || yyy >= height / cell_size)
                            continue;

                        vec2 a = imageLoad(image_in, ivec2(xx, yy)).yz;
                        vec2 b = imageLoad(image_in, ivec2(xxx, yyy)).yz;
                        max_angle = max(angle_between(a, b), max_angle);
                    }
                }

                vec4 cell = imageLoad(image_in, ivec2(xx, yy));
                if (cell.x != EMPTY) {
                    vec2 came_from = normalize(imageLoad(image_in, ivec2(xx - x, yy - y)).yz);
                    current_vector.x += cell.x / MAXSTATE * (cell.y + came_from.x) / 2;
                    current_vector.y += cell.x / MAXSTATE * (cell.z + came_from.y) / 2;
                }
            }
        }

        if (random(vec2(x, y) + vec2(time)) * excited_neighbors_parameter < excited_neighbors && max_angle < constraining_angle) {
            vec4 to_store = imageLoad(image_in, ivec2(x, y)).xyzw;
            to_store.x = MAXSTATE;
            current_vector = normalize(current_vector);
            current_vector = rotate(current_vector, random(vec2(x, y) + vec2(time)) * 2 * new_growth_perturbation - new_growth_perturbation);
            to_store.yz = current_vector;

            imageStore(image_out, ivec2(x, y), to_store);
        }
    }
    // update alive
    else if (state > 0) {
        vec4 current = imageLoad(image_in, ivec2(x, y));
        current.x -= 1;
        current.yz = rotate(current.yz, random(vec2(x, y) + vec2(time)) * 2 * new_growth_perturbation - new_growth_perturbation);
        current.x = clamp(current.x, ALIVE, MAXSTATE);
    }

    // export
    value = vec4(state, vector.x, vector.y, age);
    imageStore(image_out, texel_coords, value);
}
*/

