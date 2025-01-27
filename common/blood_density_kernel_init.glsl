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

const float peak = 0.3;

float tanh_kernel(float x) {
    const float n = 1.8;
    return ((tanh(n * (1.0 - x - 0.5)) / 2.0) + 0.5) * peak;
}

float gaussian_kernel(float x) {
    const float n = 1;
    return exp(-2 * n * x * x) * peak;
}

vec4 effect(vec4 vertex_color, Image _, vec2 texture_position, vec2 vertex_position) {
    float value = gaussian_kernel((distance(vertex_position / love_ScreenSize.xy, vec2(0.5)) * 2)); // aspect ratio is 1:1
    return vec4(value);
}

#endif