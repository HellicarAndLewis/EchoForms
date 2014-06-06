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

uniform vec3 uMousePos;
uniform float uClockTick;
uniform int   uChosenIndex;
uniform float uAlphaScalar;

varying vec3 vBarycentre;
  
void main(void) {
  
  gl_FragColor.rgb = vColour.rgb;
  gl_FragColor.a = vColour.a * uAlphaScalar;
}