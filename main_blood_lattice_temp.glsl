#pragma language glsl4
uniform usampler2D MainTex;
in vec4 VaryingTexCoord;
out vec4 FragColor;

#define INT_NORMALIZATION 32768

void pixelmain() {
   FragColor = vec4(texture(MainTex, VaryingTexCoord.xy).r / 255, 0, 0, 1);
}