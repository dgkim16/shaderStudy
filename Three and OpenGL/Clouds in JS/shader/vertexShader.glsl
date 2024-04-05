//attribute vec3 position;
// array of positions
// vertex specific data we are storing in an array. So not supported in fragment shader, only vertex shader
uniform mat4 worldMatrix;
varying vec2 vUv;
varying vec3 wPos;
varying vec3 vPosition;
// provided by three.js
//  uniform mat4 projectionMatrix;
//  uniform mat4 modelViewMatrix;
// matrix mat2 = 2*2 matrix
// mat2*3, ...
// uniform = {value : 0}
// uniform is same across all fragments

/*

modelViewMatrix = viewMatrix * modelMatrix

//  Transform -> position, scale, rotation
//  modelMatrix -> position, scale, rotation of object
//  viewMatrix -> position, orientation of camera
//  projectionMatrix -> projects our object onto the screen (aspect ratio & perspective)

//  order of multiplication is important


MVP
modelViewMatrix = viewMatrix * modelMatrix
vec4 modelViewPosition = modelViewMatrix * vec4(position,1.0);
vec4 projectedPosition = projectionMatrix * modelViewPosition;
gl_Position = projectedPosition;


gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position,1.0);

*/

out vec4 FragPos;

void main() {
    FragPos = worldMatrix * vec4(position,1.0);
    vUv = uv;
    vPosition = position;
    wPos = (worldMatrix * vec4(position,1.0)).xyz;
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0);
}