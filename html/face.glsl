##>VERTEX
precision highp float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}

{{ShaderLibrary.VertexColour}}

attribute vec3 aVertexBarycentre;

varying vec3 vBarycentre;

void main(void) {


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
  
  float dd = distFactor();

  vec3 tc = mix(vec3(0.0), vec3(1.0),  dd * uHighLight);

  //gl_FragColor.rgb = mix(tc, tt, edgeFactor());
  gl_FragColor.rgb = tc;

  gl_FragColor.a = 1.0 * dd;
}