##>VERTEX
precision mediump float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.BasicCamera}}
{{ShaderLibrary.VertexTexCoord}}


void main(void) {
  gl_Position = vec4(aVertexPosition, 1.0);
}


##>FRAGMENT

precision mediump float;

{{ShaderLibrary.Basic}}
{{ShaderLibrary.VertexTexCoord}}

uniform sampler2D uSampler;

uniform float uResolution;
uniform float uRadius;
uniform vec2 uDir;


// https://github.com/mattdesl/lwjgl-basics/wiki/ShaderLesson5
  
void main(void) {

  //this will be our RGBA sum
  vec4 sum = vec4(0.0);
  
  //our original texcoord for this fragment
  vec2 tc = vTexCoord;
  
  //the amount to blur, i.e. how far off center to sample from 
  //1.0 -> blur by one pixel
  //2.0 -> blur by two pixels, etc.
  float blur = uRadius/uResolution; 
    
  //the direction of our blur
  //(1.0, 0.0) -> x-axis blur
  //(0.0, 1.0) -> y-axis blur
  float hstep = uDir.x;
  float vstep = uDir.y;
    
  //apply blurring, using a 9-tap filter with predefined gaussian weights
    
  sum += texture2D(uSampler, vec2(tc.x - 4.0*blur*hstep, tc.y - 4.0*blur*vstep)) * 0.0162162162;
  sum += texture2D(uSampler, vec2(tc.x - 3.0*blur*hstep, tc.y - 3.0*blur*vstep)) * 0.0540540541;
  sum += texture2D(uSampler, vec2(tc.x - 2.0*blur*hstep, tc.y - 2.0*blur*vstep)) * 0.1216216216;
  sum += texture2D(uSampler, vec2(tc.x - 1.0*blur*hstep, tc.y - 1.0*blur*vstep)) * 0.1945945946;
  
  sum += texture2D(uSampler, vec2(tc.x, tc.y)) * 0.2270270270;
  
  sum += texture2D(uSampler, vec2(tc.x + 1.0*blur*hstep, tc.y + 1.0*blur*vstep)) * 0.1945945946;
  sum += texture2D(uSampler, vec2(tc.x + 2.0*blur*hstep, tc.y + 2.0*blur*vstep)) * 0.1216216216;
  sum += texture2D(uSampler, vec2(tc.x + 3.0*blur*hstep, tc.y + 3.0*blur*vstep)) * 0.0540540541;
  sum += texture2D(uSampler, vec2(tc.x + 4.0*blur*hstep, tc.y + 4.0*blur*vstep)) * 0.0162162162;

  //discard alpha for our simple demo, multiply by vertex color and return
  gl_FragColor = vec4(sum.rgb, 1.0);

}