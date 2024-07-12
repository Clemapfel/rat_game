uniform float sharpness = 5.0;

float sharpen(float pix_coord) {
    float norm = (fract(pix_coord) - 0.5) * 2.0;
    float norm2 = norm * norm;
    return floor(pix_coord) + norm * pow(norm2, sharpness) / 2.0 + 0.5;
}

uniform vec2 resolution;
vec4 effect(vec4 color, sampler2D tex, vec2 texCoord, vec2 scrCoord) {
    vec4 pixel = Texel(tex, vec2(
        sharpen(texCoord.x * resolution.x) / resolution.x,
        sharpen(texCoord.y * resolution.y) / resolution.y
    ));
    return pixel * color;
}