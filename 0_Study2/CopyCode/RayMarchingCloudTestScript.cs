using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RayMarchingCloudTestScript : MonoBehaviour
{
    public Material material;
    public Transform CloudSource;
    public Transform Sphere1;
    public Transform Box1;
    public Transform Box1Scale;

    // Update is called once per frame
    void Update()
    {
        material.SetVector("_Sphere1", new Vector4(Sphere1.position.x, Sphere1.position.y, Sphere1.position.z, Sphere1.localScale.x));
        material.SetVector("_Sphere2", new Vector4(CloudSource.position.x, CloudSource.position.y, CloudSource.position.z, CloudSource.localScale.x));
        material.SetVector("_Box1", new Vector4(Box1.position.x, Box1.position.y, Box1.position.z, 0));
        material.SetVector("_Box1Scale", new Vector4(Box1Scale.localScale.x, Box1Scale.localScale.y, Box1Scale.localScale.z, 0));
    }
}
