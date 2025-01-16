#ifdef PIXEL

const float h = 0.5;

// https://www.desmos.com/calculator/kdvvtte3vh

float spiky_kernel(float x) {
    if (abs(x) > h) return 0;
    return (h - x) * (h - x) * (h - x) / (h * h * h * h / 4);
}

float spiky_kernel_derivative(float x) {
    if (x > h) return 0;
    return -1 * (12 * (h - x) * (h - x)) / (h * h * h * h);
}

float spiky_kernel_peak() {
    return 4 / h;
}

float alt_kernel(float x) {
    if (abs(x) > h) return 0;
    return exp(-2 * (x - h)) / (exp(h) * sinh(h));
}

float alt_kernel_peak() {
    return exp(h) / sinh(h);
}

uniform sampler2D other;

vec4 effect(vec4 vertex_color, Image _, vec2 texture_coords, vec2 vertex_position) {
    //float value = alt_kernel(distance(texture_coords, vec2(0.5)) * 2) / alt_kernel_peak(); // aspect ratio is 1:1
    float value = 1 - distance(texture_coords, vec2(0.5)) * 2;
    vec4 other = texture(other, texture_coords);
    return vec4(vec3(1) * max(max(other.x, other.y), other.z), value);
}

#endif