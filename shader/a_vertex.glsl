uniform float u_time;

out vec4 t_fragPos;
void main() {
    t_fragPos = modelMatrix * vec4(position, 1.0);
    //fragPos = position * vec4(position, 1.0);
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);;
}