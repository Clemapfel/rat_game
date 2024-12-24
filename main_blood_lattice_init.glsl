// Simplex noise implementation
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v) {
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

#define STATE_TEXTURE uniform layout(rgba32f) writeonly image2D

STATE_TEXTURE velocity_texture_top_in;    // r = top-left,    g = top,    b = top-right
STATE_TEXTURE velocity_texture_center_in; // r = left,        g = center, b = right
STATE_TEXTURE velocity_texture_bottom_in; // r = bottom-left, g = bottom, b = bottom-right

uniform vec2 lattice_size = vec2(512, 512);

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    vec2 position = vec2(gl_GlobalInvocationID.xy);
    vec2 center = vec2(lattice_size) / 2.0;

    // Gaussian distribution for density
    float distance = length(position - center);
    float radius = min(lattice_size.x, lattice_size.y) * 0.2;
    float density = 1.0 + 0.2 * exp(-distance * distance / (2.0 * radius * radius));

    // Add Simplex noise to the density
    float noise = snoise(position / lattice_size * 10.0);
    float noise_strength = 0.2;
    density += noise_strength * (noise - 0.5);

    // Introduce initial velocity variations
    vec2 velocity = vec2(snoise(position / lattice_size * 5.0), snoise(position / lattice_size * 5.0 + 100.0));
    velocity *= 0.1; // Scale the velocity

    // Initialize equilibrium distributions with velocity influence
    float w_center = 4.0 / 9.0;
    float w_cardinal = 1.0 / 9.0;
    float w_diagonal = 1.0 / 36.0;

    // Calculate equilibrium distribution based on velocity
    vec3 equilibrium_top = vec3(w_diagonal, w_cardinal, w_diagonal) * density + vec3(velocity.y, velocity.x, -velocity.y);
    vec3 equilibrium_center = vec3(w_cardinal, w_center, w_cardinal) * density + vec3(velocity.x, 0.0, velocity.x);
    vec3 equilibrium_bottom = vec3(w_diagonal, w_cardinal, w_diagonal) * density + vec3(-velocity.y, -velocity.x, velocity.y);

    // Store values in textures
    imageStore(velocity_texture_top_in,    ivec2(position.x, position.y), vec4(equilibrium_top, 1.0));
    imageStore(velocity_texture_center_in, ivec2(position.x, position.y), vec4(equilibrium_center, 1.0));
    imageStore(velocity_texture_bottom_in, ivec2(position.x, position.y), vec4(equilibrium_bottom, 1.0));
}