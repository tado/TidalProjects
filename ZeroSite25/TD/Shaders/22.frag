uniform float time;
uniform vec2 resolution;
out vec4 fragColor;

void main(void){
    vec2 st = gl_FragCoord.xy / resolution.xy;
    st -= 1.0;
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
    for(float i = 0.0; i < 12.0; i++){
        st.x += sin(st.y * 4.0 + time * 2.0 + i * 40.0) * 0.2 * cos(time + (i + 2.0) * 300.0);
        color += (1.0 - vec4(pow(abs(st.x), 0.03)));
    }
    color = vec4(color.r * 2.0, color.g * 0.9, color.b * 0.0, 1.0);
    fragColor = TDOutputSwizzle(color);
}
