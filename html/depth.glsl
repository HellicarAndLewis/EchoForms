##>VERTEX
{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}

precision highp float;

void main(void) {
  gl_Position = uProjectionMatrix * uCameraMatrix * uModelMatrix * vec4(aVertexPosition, 1.0);
}

##>FRAGMENT

precision highp float;

{{ShaderLibrary.DepthPack}}

void main (void) {
  gl_FragColor = pack(gl_FragCoord.z);
}
