#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D paletteTexture;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float paletteSize;
    float texWidth;
    float texHeight;
} ubuf;

void main() {
    vec4 tex = texture(source, qt_TexCoord0);
    vec3 color = tex.rgb;

    float dMin1 = 100.0;
    float dMin2 = 100.0;
    vec3 cMin1 = vec3(0.0);
    vec3 cMin2 = vec3(0.0);

    // Loop through palette
    int size = int(ubuf.paletteSize);
    
    // Iterate over the palette texture. Max 128 colors supported.
    for (int i = 0; i < 128; i++) {
        if (i >= size) break;
        
        // Calculate texture coordinate for the center of the i-th pixel
        float u = (float(i) + 0.5) / ubuf.paletteSize;
        
        vec3 pColor = texture(paletteTexture, vec2(u, 0.5)).rgb;
        
        vec3 diff = color - pColor;
        float d = dot(diff, diff);
        
        // Find the two nearest colors
        if (d < dMin1) {
            dMin2 = dMin1; cMin2 = cMin1;
            dMin1 = d; cMin1 = pColor;
        } else if (d < dMin2) {
            dMin2 = d; cMin2 = pColor;
        }
    }

    vec3 finalColor;
    float totalD = dMin1 + dMin2;

    if (totalD < 0.000001) {
        finalColor = cMin1;
    } else {
        // Interpolate based on distance.
        // Closer color (dMin1) gets more weight.
        // weight1 = dMin2 / totalD
        // weight2 = dMin1 / totalD
        // Formula: mix(cMin1, cMin2, dMin1 / totalD)
        // Check: if dMin1=0, factor=0 -> cMin1. Correct.
        // Check: if dMin1=dMin2, factor=0.5 -> average. Correct.
        finalColor = mix(cMin1, cMin2, dMin1 / totalD);
    }

    fragColor = vec4(finalColor, tex.a) * ubuf.qt_Opacity;
}
