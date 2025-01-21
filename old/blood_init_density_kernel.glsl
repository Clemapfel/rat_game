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


const float h = 0.5;
float kernel_shape(float x) {
    return exp(-2 * (x - h)) / (exp(h) * sinh(h));
}

float alt_kernel(float x) {
    if (abs(x) > h)
    return 0;

    if (x >= 0)
    return kernel_shape(x);
    else
    return kernel_shape(1 - x - 1);
}

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position) {
    float value = alt_kernel(distance(texture_coords, vec2(0.5))); // aspect ratio is 1:1
    return vec4(value);
}

#endif