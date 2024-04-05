/*
Objective:
using objects rendered using sdf in fragment shader,
demonstrate a working perceptron in 3d

Todo
- create spheres in 3d space using sdf, representing pixel data
- limit creation of spheres within a certain cube.

- perceptron?
-



- 

*/




//import * as T from 'three';
import * as T from "https://unpkg.com/three@v0.149.0/build/three.module.js"
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
//import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
//import { OBJLoader } from "three/addons/loaders/OBJLoader.js";
//import { c } from 'vite/dist/node/types.d-AKzkD8vd';
let vertexShader = await(await fetch('./shaders/a_vertex.glsl')).text();
let fragmentShader = await(await fetch('./shaders/a_fragment.glsl')).text();

let animateCheck = document.createElement("input");
animateCheck.type = "checkbox";
animateCheck.checked = false;
animateCheck.onchange = function() {
    if (animateCheck.checked) {
        window.requestAnimationFrame(animate);
    }
}

let trfCheck = document.createElement("input");
trfCheck.type = "checkbox";
trfCheck.checked = false;

let normColCheck = document.createElement("input");
normColCheck.type = "checkbox";
normColCheck.checked = true;

let renderer = new T.WebGLRenderer();
renderer.setSize(500, 500);
// put the canvas into the DOM
document.getElementById("div1").appendChild(renderer.domElement);
document.getElementById("div1").append(animateCheck);
document.getElementById("div1").append(new Text("Run"));
document.getElementById("div1").append(document.createElement('br'));
document.getElementById("div1").append(trfCheck);
document.getElementById("div1").append(new Text("Update cumulTime"));
document.getElementById("div1").append(document.createElement('br'));
document.getElementById("div1").append(normColCheck);
document.getElementById("div1").append(new Text("Normalize Color"));
document.getElementById("div1").append(document.createElement('br'));


let camera = new T.PerspectiveCamera(50, 1);

let scene = new T.Scene();
let plane = new T.Mesh(
    new T.PlaneGeometry(10, 10, 1, 1),
    new T.MeshStandardMaterial({ color: 'rgb(30,30,30)', side: T.DoubleSide })
);
plane.rotation.x = Math.PI / 2;
let light = new T.PointLight();
light.position.set(1,1,1);
scene.add(light);

//scene.add(plane);


camera.position.set(1,-1,4);
camera.lookAt(0,0,0);

let spherePos = new T.Vector3(0,0,0);

let sdfMat = new T.ShaderMaterial({
    uniforms: {
        time: { value: 0 },
        resolution: { value: new T.Vector2(500, 500) },
        normalColor : { value: true },
        cameraPos: { value: new T.Vector3() },
        spherePos: { value: new T.Vector3(0,0,0) },
    },
    vertexShader: vertexShader,
    fragmentShader: fragmentShader
});

// make plane have geometry of window resolution
const width = Math.tan(camera.fov * Math.PI / 360) * camera.position.z * 2;
const height = width / camera.aspect;
let sdfGeo = new T.PlaneGeometry(width,height);
let sdfMesh = new T.Mesh(sdfGeo, sdfMat);
updateTargets();
scene.add(sdfMesh);



function updateTargets() {
    let camDir = new T.Vector3();
    camera.getWorldDirection(camDir);
    let targetX = camera.position.x + 2 * camDir.x;
    let targetY = camera.position.y + 2 * camDir.y;
    let targetZ = camera.position.z + 2 * camDir.z;
    sdfMesh.position.set(targetX, targetY, targetZ);
    sdfMesh.lookAt(camera.position);
}

function sdfAnimate(t) {
    spherePos.x = Math.sin(t / 1000);
    sdfMat.uniforms.spherePos.value.copy(spherePos);
    sdfMat.uniforms.time.value = t;
    sdfMat.uniforms.normalColor.value = normColCheck.checked;
}

const controls = new OrbitControls( camera, renderer.domElement );
//const loader = new GLTFLoader();


let lastTimestamp; // undefined to start
let cumulTime = 0; // only increments when animateCheck is true
function animate(timestamp) {
    
    if (animateCheck.checked) {
        let timeDelta = 1 * (lastTimestamp ? timestamp - lastTimestamp : 0);
        lastTimestamp = timestamp;
        updateTargets();
        sdfMat.uniforms.cameraPos.value.copy(camera.position);
        if(trfCheck.checked) {
            cumulTime += timeDelta;
            sdfAnimate(cumulTime);
        }
        window.requestAnimationFrame(animate);
    }
    renderer.render(scene, camera);
    //camera.getWorldPosition(dir);   
}

window.requestAnimationFrame(animate);