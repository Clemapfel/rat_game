#pragma language glsl4

#ifdef PIXEL

#define PI 3.1415926535897932384626433832795

// Light properties
const vec3 light_color = vec3(1);

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

const float min_density = 1;

float density_falloff(float x) {
    return (min_density + 1.0 + log(max(x, 0.0001)) / 2.0);
}

float light_falloff(float x) {
    const float ramp = 0.15;
    const float peak = 2;
    return (1 - exp(-2 * ramp * x * x)) * peak;
}

float gaussian(float x, float ramp)
{
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}

uniform vec3 red;

// Function to create a rotation matrix for the x-axis
mat3 rotation_x(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(
    1.0, 0.0, 0.0,
    0.0, c, -s,
    0.0, s, c
    );
}

// Function to create a rotation matrix for the y-axis
mat3 rotation_y(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(
    c, 0.0, s,
    0.0, 1.0, 0.0,
    -s, 0.0, c
    );
}

// Function to create a rotation matrix for the z-axis
mat3 rotation_z(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat3(
    c, -s, 0.0,
    s, c, 0.0,
    0.0, 0.0, 1.0
    );
}

vec4 effect(vec4 color, Image density_image, vec2 texture_coords, vec2 screen_coords) {
    vec4 data = texture(density_image, texture_coords);
    float density = smoothstep(0, 0.5, data.x);
    vec2 dxy = data.yz; // directional derivative of surface

    float light_strength = 0.5;
    vec3 diffuse_light_direction = normalize(vec3(0, -1.0, 1.0));
    vec3 normal = normalize(vec3(-dxy.x, -dxy.y, 1.0));
    float diffuse = dot(normal, diffuse_light_direction);

    // Specify rotation angles for x, y, and z axes
    float angle_x = radians(0);
    float angle_y = radians(0);
    float angle_z = radians(45 / 4.0);

    // Combine rotation matrices
    mat3 rotation_matrix = rotation_z(angle_z) * rotation_y(angle_y) * rotation_x(angle_x);
    vec3 specular_light_direction = normalize(rotation_matrix * vec3(0, -1, 1));

    float specular_intensity = 1.5;
    float shininess = 128.0;
    float specular = pow(max(dot(normal, specular_light_direction), 0), shininess);
    specular = specular * specular_intensity * smoothstep(0, 0.5, density);

    // Subsurface scattering effect
    float subsurface_scattering = 0.3 * (density) * max(dot(normal, specular_light_direction), 0.0);

    float value = (diffuse + subsurface_scattering) - light_falloff(density);

    const float water_surface_eps = 0.15;
    return vec4(mix(vec3(value) * red, vec3(1), specular), smoothstep(0.1, 0.1 + water_surface_eps, min(density_falloff(density), 1)));
}

#endif