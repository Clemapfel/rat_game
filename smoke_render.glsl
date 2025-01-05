#pragma language glsl4

uniform usampler2D image;
out vec4 frag_color;

layout(std430) readonly buffer max_distance_buffer {
    uint max_distance[];
}; // size: 1

void pixelmain()
{
    uvec4 value = texture(image, love_PixelCoord.xy / love_ScreenSize.xy);
    float length = length(value.xy) / float(max_distance[0] / 256);
    frag_color = vec4(length);
}