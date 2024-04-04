using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ShaderInfoSender : MonoBehaviour
{
    [SerializeField] public Material mat;
    [SerializeField] public Transform target;
    [SerializeField] public Transform target2;

    // Update is called once per frame
    void Update()
    {
        // set material's _Sphere1 vector4 property to have target's position
        mat.SetVector("_Sphere1", new Vector4(target.position.x, target.position.y, target.position.z, target.localScale.x));
        mat.SetVector("_Box", new Vector4(target2.position.x, target2.position.y, target2.position.z, target2.localScale.x));
        mat.SetVector("_BoxScale", new Vector4(target2.localScale.x, target2.localScale.y, target2.localScale.z, 0));
    }
}
