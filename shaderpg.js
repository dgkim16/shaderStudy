import * as T from 'three';
import { OrbitControls } from "https://unpkg.com/three@v0.149.0/examples/jsm/controls/OrbitControls.js";
let vertexShader = await(await fetch("./shader/a_vertex.glsl")).text();
let fragmentShader = await(await fetch("./shader/a_fragment.glsl")).text();

const renderer = new T.WebGLRenderer();
document.body.appendChild(renderer.domElement);
let checkbox = document.createElement("input");
checkbox.type = "checkbox";
checkbox.id = "toggle";
checkbox.checked = true;
checkbox.addEventListener("change", (event) => {
  if(event.target.checked)
    requestAnimationFrame(animate);
});
document.body.appendChild(checkbox);


renderer.setSize(500,500);
const scene = new T.Scene();
const camera = new T.PerspectiveCamera(60,1,0.1,1000);
camera.position.set(0,0,5);

let cube = new T.Mesh(new T.BoxGeometry(1,1,1), new T.MeshBasicMaterial({color: 0x00ff00}));
let plane = new T.Mesh(new T.PlaneGeometry(5,5), new T.MeshBasicMaterial({color: 'gray'}));
plane.rotation.x = -Math.PI/2;
scene.add(cube);
scene.add(plane);


const uniforms = {
  u_time: { value: 0 },
  resolution: { value: new T.Vector2() },
  cameraPos: { value: camera.position },
  spherePos: { value: new T.Vector3(0,0,0) },
  normalColor: { value: false },
}

let material = new T.ShaderMaterial({
  uniforms: uniforms,
  vertexShader: vertexShader,
  fragmentShader: fragmentShader
});

const width = Math.tan(camera.fov * Math.PI / 360) * camera.position.z * 2;
const height = width / camera.aspect;
const geometry = new T.PlaneGeometry(width,height,100,100);
const mesh = new T.Mesh(geometry, material);
scene.add(mesh);
const controls = new OrbitControls(camera, renderer.domElement);
uniforms.resolution.value.copy(new T.Vector2(width, height));
const dist = mesh.position.distanceTo(camera.position);

let direction = new T.Vector3();
function animate() {
  uniforms.cameraPos.value = camera.position;
  camera.getWorldDirection(direction);
  mesh.position.set(camera.position.x + direction.x * dist, camera.position.y + direction.y * dist, camera.position.z + direction.z * dist);
  mesh.lookAt(camera.position);
  renderer.render(scene, camera);
  if(checkbox.checked)
    requestAnimationFrame(animate);
}

requestAnimationFrame(animate);