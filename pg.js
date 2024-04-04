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
import {TransformControls} from 'three/addons/controls/TransformControls.js';
//import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
//import { OBJLoader } from "three/addons/loaders/OBJLoader.js";
//import { c } from 'vite/dist/node/types.d-AKzkD8vd';
let vertexShader = await(await fetch("./shader/a_vertex.glsl")).text();
let fragmentShader = await(await fetch("./shader/a_fragment.glsl")).text();
/*
const fragImports = [
    './shader/functions/sdf_Operations.cginc',
    './shader/functions/sdf_Primitives.cginc',
    './shader/functions/noiseFunction.cginc',
    './shader/a_fragment.glsl'
];
const vertImports = [
    './shader/a_vertex.glsl'
];

async function fetchAndCocatenateFiles(fileUrls) {
    const fetchPromises = fileUrls.map(url => fetch(url).then(response => {return response.text();}));
    const fragFunctionContents = await Promise.all(fetchPromises);
    const concatFragFunctions = fragFunctionContents.join('\n');
    return concatFragFunctions;
}

const vertexShader = await fetchAndCocatenateFiles(vertImports);
const fragmentShader = await fetchAndCocatenateFiles(fragImports);
*/




let animateCheck = document.createElement("input");
animateCheck.type = "checkbox";
animateCheck.checked = false;


let trfCheck = document.createElement("input");
trfCheck.type = "checkbox";
trfCheck.checked = true;

let normColCheck = document.createElement("input");
normColCheck.type = "checkbox";
normColCheck.checked = false;

let cloudCheck = document.createElement("input");
cloudCheck.type = "checkbox";
cloudCheck.checked = true;

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
document.getElementById("div1").append(cloudCheck);
document.getElementById("div1").append(new Text("Cloud"));
document.getElementById("div1").append(document.createElement('br'));



let camera = new T.PerspectiveCamera(50, 1);

let scene = new T.Scene();
let planeGeom = new T.PlaneGeometry(10, 10, 1, 1);
let planeMat = new T.MeshStandardMaterial({ color: 'rgb(30,30,30)', side: T.DoubleSide});
let plane = new T.Mesh(planeGeom, planeMat);
let plane2 = new T.Mesh(planeGeom, planeMat);
plane.rotation.x = Math.PI / 2;
plane.position.y = -1;
plane2.position.z = -5;
plane2.position.y = 4;
//scene.add(plane2);


let transformControls = new TransformControls(camera, renderer.domElement);
let orbitControls = new OrbitControls( camera, renderer.domElement );
transformControls.enabled = false;
orbitControls.enabled = false;
transformControls.setMode("translate");
transformControls.addEventListener("dragging-changed", function (event) {
    orbitControls.enabled = !event.value;
});
scene.add(transformControls);


let lightIndicator = new T.Mesh(new T.SphereGeometry(0.1), new T.MeshBasicMaterial({color: 'rgb(255,255,255)'}));

let light = new T.PointLight('rgb(255,255,255)', 3);
lightIndicator.add(light);
lightIndicator.position.set(1.5,1.5,-1.5);
transformControls.attach(lightIndicator);
scene.add(lightIndicator);


scene.add(plane);


camera.position.set(1,-1,4);
camera.lookAt(0,0,0);

let spherePos = new T.Vector3(0,0,0);

let sdfMat = new T.ShaderMaterial({
    uniforms: {
        time: { value: 0 },
        resolution: { value: new T.Vector2(500, 500) },
        normalColor : { value: false },
        isCloud: { value: true },
        cameraPos: { value: new T.Vector3() },
        spherePos: { value: new T.Vector3(0,0,0) },
        lightPos : { value: lightIndicator.position }
    },
    vertexShader: vertexShader,
    fragmentShader: fragmentShader,
    transparent: true
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
    sdfMat.uniforms.isCloud.value = cloudCheck.checked;
    sdfMat.uniforms.lightPos.value = lightIndicator.position;
}

animateCheck.onchange = function() {
    orbitControls.enabled = animateCheck.checked;
    transformControls.enabled = animateCheck.checked;
    if (animateCheck.checked) {
        window.requestAnimationFrame(animate);
    }
}



//const loader = new GLTFLoader();


let lastTimestamp; // undefined to start
let cumulTime = 0; // only increments when animateCheck is true
function animate(timestamp) {
    
    if (animateCheck.checked || cumulTime < 1) {
        let timeDelta = 1 * (lastTimestamp ? timestamp - lastTimestamp : 0);
        lastTimestamp = timestamp;
        updateTargets();
        sdfMat.uniforms.cameraPos.value.copy(camera.position);
        if(trfCheck.checked || cumulTime < 1) {
            cumulTime += timeDelta;
            sdfAnimate(cumulTime);
        }
        window.requestAnimationFrame(animate);
    }
    renderer.render(scene, camera);
    //camera.getWorldPosition(dir);   
}

window.requestAnimationFrame(animate);