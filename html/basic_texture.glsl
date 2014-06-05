##>VERTEX
precision highp float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}
{{ShaderLibrary.VertexTexCoord}}
{{ShaderLibrary.VertexColour}}


attribute vec3 aVertexBarycentre;

varying vec3 vBarycentre;

void main(void) {

  /*vec4 actual_pos = uModelMatrix * vec4(aVertexPosition,1.0);
  vec3 dir = uMouseRay - actual_pos.xyz;
  dir = normalize(dir);
  dir = dir * 0.1;
  vec3 npos = aVertexPosition + dir;*/

  vBarycentre = aVertexBarycentre;
  vPosition = uModelMatrix * vec4(aVertexPosition, 1.0);
  gl_Position = uProjectionMatrix * uCameraMatrix * vPosition;
}


##>FRAGMENT
#extension GL_OES_standard_derivatives : enable
precision highp float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.VertexTexCoord}}
{{ShaderLibrary.VertexColour}}
{{ShaderLibrary.Noise}}


uniform sampler2D uSampler;

uniform vec3 uMousePos;
uniform float uClockTick;
uniform float uHighLight;

varying vec3 vBarycentre;

float edgeFactor(){
    float noize = snoise( vec3(uClockTick, vPosition.x, vPosition.y) * 0.01 );
    vec3 d = fwidth(vBarycentre * noize);
    
    noize = 1.0 + snoise( vec3(uClockTick, uMousePos.x, vPosition.y) * 0.01 );

    vec3 a3 = smoothstep(vec3(0.0), d * 1.5 * noize, vBarycentre);
    return min(min(a3.x, a3.y), a3.z);
}

float distFactor() {
  float dd = distance(vPosition.xyz, uMousePos);

  return length(vBarycentre) - pow(dd,3.0);
}
  
void main(void) {
  gl_FragColor = texture2D(uSampler, vTexCoord);
  vec3 tt = texture2D(uSampler, vTexCoord).rgb;

  vec3 tc = mix(vec3(0.0), vec3(1.0), distFactor() * uHighLight);

  gl_FragColor.rgb = mix(tc, tt, edgeFactor());
  gl_FragColor.a = 1.0;
}