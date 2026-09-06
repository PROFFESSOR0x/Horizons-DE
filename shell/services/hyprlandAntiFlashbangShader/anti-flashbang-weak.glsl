#version 300 es
precision highp float;

// Weak variant of anti-flashbang.glsl. Same average-brightness measurement,
// roughly half the dimming, so a bright screen is taken off the "flashbang"
// end without the strong variant's noticeable overall darkening.
//
// This file is not optional: HyprlandAntiFlashbangShader.qml's cycle() (the
// Anti-flashbang quick toggle's first press) points
// decoration:screen_shader straight at this path, and Hyprland answers a
// missing path with "Screen shader parser: Failed to check screen shader
// path: No such file or directory".

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

float overlayOpacityForBrightness(float x) {
    // Note: range 0 to 1. Half of the strong variant's 0.42 slope.
    float y = x * 0.21;
    return min(max(y, 0.001), 1.0);
}

void main() {
    // 1. Get the current pixel color
    vec4 pixColor = texture(tex, v_texcoord);

    // 2. Calculate average screen brightness over a 10x10 sample grid
    vec3 totalRGB = vec3(0.0);
    float samples = 0.0;

    for(float x = 0.05; x < 1.0; x += 0.1) {
        for(float y = 0.05; y < 1.0; y += 0.1) {
            totalRGB += texture(tex, vec2(x, y)).rgb;
            samples++;
        }
    }

    vec3 avgColor = totalRGB / samples;
    float globalBrightness = dot(avgColor, vec3(0.2126, 0.7152, 0.0722));

    // 3. Get the specific opacity for this brightness level
    float opacity = overlayOpacityForBrightness(globalBrightness);

    // 4. Apply the "black overlay" effect
    vec3 outColor = mix(pixColor.rgb, vec3(0.0), opacity);

    fragColor = vec4(outColor, pixColor.a);
}
