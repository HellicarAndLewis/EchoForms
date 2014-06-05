##>VERTEX
precision highp float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}
{{ShaderLibrary.VertexTexCoord}}

attribute vec3 aVertexBarycentre;

uniform vec3 uMouseRay;
varying vec3 vBarycentre;

void main(void) {

  /*vec4 actual_pos = uModelMatrix * vec4(aVertexPosition,1.0);
  vec3 dir = uMouseRay - actual_pos.xyz;
  dir = normalize(dir);
  dir = dir * 0.1;
  vec3 npos = aVertexPosition + dir;*/

  vBarycentre = aVertexBarycentre;

  gl_Position = uProjectionMatrix * uCameraMatrix * uModelMatrix * vec4(aVertexPosition, 1.0);
}


##>FRAGMENT
#extension GL_OES_standard_derivatives : enable
precision highp float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.VertexTexCoord}}

uniform sampler2D uSampler;

varying vec3 vBarycentre;

float edgeFactor(){
    vec3 d = fwidth(vBarycentre);
    vec3 a3 = smoothstep(vec3(0.0), d*1.5, vBarycentre);
    return min(min(a3.x, a3.y), a3.z);
}
  
void main(void) {
  //gl_FragColor = texture2D(uSampler, vTexCoord);
  vec3 tt = texture2D(uSampler, vTexCoord).rgb;
  gl_FragColor.rgb = mix(vec3(1.0), tt, edgeFactor());
  gl_FragColor.a = 1.0;
}