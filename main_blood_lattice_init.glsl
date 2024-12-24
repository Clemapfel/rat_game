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

#define PI 3.1415926535897932384626433832795
float gaussian(float x, float ramp)
{
    return exp(((-4 * PI) / 3) * (ramp * x) * (ramp * x));
}

uniform layout(rg32f) writeonly image2D cell_texture;

layout(local_size_x = 1, local_size_y = 1) in;
void computemain() {
    vec2 position = vec2(gl_GlobalInvocationID.xy);
    vec2 size = imageSize(cell_texture);
    const float scale = 5;

    vec2 center = 0.5 * size;
    float dist = distance(position, center) / min(size.x, size.y);
    dist = gaussian(dist, 2);
    dist *= snoise(position / size * 4);

    // Sobel kernels
    const mat3 sobelX = mat3(
        -1, 0, 1,
        -2, 0, 2,
        -1, 0, 1
    );

    const mat3 sobelY = mat3(
        -1, -2, -1,
        0,  0,  0,
        1,  2,  1
    );

    // Compute the gradient using the Sobel operator
    float gradient_x = 0.0;
    float gradient_y = 0.0;

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 offset = vec2(i, j);
            vec2 pos = position + offset;
            float sampleDist = distance(pos, center) / min(size.x, size.y);
            sampleDist = gaussian(sampleDist, 2);
            sampleDist *= snoise(pos / size * 4);

            gradient_x += sampleDist * sobelX[i + 1][j + 1];
            gradient_y += sampleDist * sobelY[i + 1][j + 1];
        }
    }

    vec2 gradient = normalize(vec2(gradient_x, gradient_y));
    imageStore(cell_texture, ivec2(position.x, position.y), vec4(
        1,
        gradient.x,
        gradient.y,
        1
    ));
}