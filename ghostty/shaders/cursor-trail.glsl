// Subtle cursor trail for Ghostty.
// Uses Ghostty cursor shader uniforms introduced in 1.2.0.

float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
    return length(pa - ba * h);
}

float rectMask(vec2 p, vec4 rect, float feather) {
    vec2 center = rect.xy + rect.zw * 0.5;
    vec2 half_size = rect.zw * 0.5;
    vec2 d = abs(p - center) - half_size;
    float outside = length(max(d, 0.0));
    float inside = min(max(d.x, d.y), 0.0);
    float dist = outside + inside;
    return 1.0 - smoothstep(0.0, feather, dist);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 base = texture(iChannel0, uv);

    if (iCursorVisible.x <= 0.0) {
        fragColor = base;
        return;
    }

    float age = iTime - iTimeCursorChange;
    float duration = 0.32;
    if (age < 0.0 || age > duration) {
        fragColor = base;
        return;
    }

    vec2 current_center = iCurrentCursor.xy + iCurrentCursor.zw * 0.5;
    vec2 previous_center = iPreviousCursor.xy + iPreviousCursor.zw * 0.5;
    float travel = length(current_center - previous_center);

    if (travel < 0.5) {
        fragColor = base;
        return;
    }

    vec3 cursor_color = iCurrentCursorColor.rgb;
    float fade = 1.0 - smoothstep(0.0, duration, age);

    float radius = clamp(min(max(iCurrentCursor.z, iCurrentCursor.w) * 0.52, 22.0), 3.0, 22.0);
    float line = 1.0 - smoothstep(radius * 0.95, radius * 1.35, sdSegment(fragCoord, previous_center, current_center));
    float glow = 1.0 - smoothstep(radius * 2.2, radius * 5.2, sdSegment(fragCoord, previous_center, current_center));
    float bloom = 1.0 - smoothstep(radius * 4.0, radius * 8.0, sdSegment(fragCoord, previous_center, current_center));
    float head = rectMask(fragCoord, iCurrentCursor, 2.0) * 0.30;

    float alpha = line * 0.42 * fade + glow * 0.22 * fade + bloom * 0.08 * fade + head;
    vec3 color = mix(base.rgb, cursor_color, clamp(alpha, 0.0, 0.62));
    fragColor = vec4(color, base.a);
}
