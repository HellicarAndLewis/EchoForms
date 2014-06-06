##>VERTEX
{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}
{{ShaderLibrary.VertexTexCoord}}


void main(void) {
  gl_Position = vec4(aVertexPosition, 1.0);
}

##>FRAGMENT

precision highp float;

{{ShaderLibrary.VertexTexCoord}}

uniform float uNearPlane;
uniform float uFarPlane;
uniform float uFocalDistance;
uniform float uFocalRange;

uniform sampler2D uSampler;
uniform sampler2D uSamplerDepth;
uniform sampler2D uSamplerBlurred;

float unpack (vec4 colour) {
  const vec4 bitShifts = vec4(1.0 / (256.0 * 256.0 * 256.0),
                1.0 / (256.0 * 256.0),
                1.0 / 256.0,
                1.0);
  return dot(colour , bitShifts);
}


void main (void) {

  float zdepth = unpack(texture2D(uSamplerDepth, vTexCoord));
  float depth = -uFarPlane * uNearPlane / (zdepth * (uFarPlane - uNearPlane) - uFarPlane);
  vec4 blur = texture2D(uSamplerBlurred, vTexCoord);
  vec4 colour = texture2D(uSampler, vTexCoord);

  float blur_amount = clamp(abs(depth - uFocalDistance) / uFocalRange, 0.0, 1.0);
  
  gl_FragColor = colour + blur_amount * (blur - colour);


}