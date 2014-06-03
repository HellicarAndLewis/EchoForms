##>VERTEX

precision mediump float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}
{{ShaderLibrary.VertexTexCoord}}

attribute vec3 aVertexBarycentre;

uniform float uMultiply;
uniform vec2 uOffset;
varying vec2 vTexPosition;
varying vec3 vBarycentre;

void main() {          

    vBarycentre = aVertexBarycentre;
    gl_Position = uProjectionMatrix * uCameraMatrix * uModelMatrix * vec4(aVertexPosition, 1.0);
    vec2 tex = vec2(vTexCoord);

    vec2 p = tex.xy - 0.5;
    float r = length(p);
    float a = atan(p.y, p.x);
    float sides = uMultiply;
    float tau = 2.0 * 3.1416;
    a = mod(a, tau/sides);
    a = abs(a - tau/sides/2.0);
    vTexPosition = r * vec2(cos(a), sin(a)) + 0.5  + uOffset;
}

##>FRAGMENT

precision mediump float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.VertexTexCoord}}

uniform sampler2D uSampler;
varying vec2 vTexPosition;
varying vec3 vBarycentre;

#extension GL_OES_standard_derivatives : enable

float edgeFactor(){
    vec3 d = fwidth(vBarycentre);
    vec3 a3 = smoothstep(vec3(0.0), d*1.5, vBarycentre);
    return min(min(a3.x, a3.y), a3.z);
}

void main(void) {
    //gl_FragColor = texture2D(uSampler, vTexPosition);
    gl_FragColor.rgb = mix(vec3(0.0), vec3(0.5), edgeFactor());
    gl_FragColor.a = 1.0;
}