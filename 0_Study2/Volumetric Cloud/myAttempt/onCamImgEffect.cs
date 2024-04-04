using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class onCamImgEffect : MonoBehaviour
{
    public Material EffectMaterial;
    public Shader shader;
    public Transform container;

    public Texture shapeNoise;
    public Texture detailNoise;

    public Vector3 CloudOffset;
    public float CloudScale;
    public float DensityThreshold;
    public float DensityMultiplier;
    public int NumSteps;
    public bool useNoise;

    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        
        if (EffectMaterial == null) {
            EffectMaterial = new Material (shader);
        }
        var noise = FindObjectOfType<NoiseGenerator> ();
        noise.UpdateNoise ();
        EffectMaterial.SetVector("BoundsMin", container.position - container.localScale/2);
        EffectMaterial.SetVector("BoundsMax", container.position + container.localScale/2);
        if(useNoise) {
           EffectMaterial.SetTexture("ShapeNoise", noise.shapeTexture);
            EffectMaterial.SetTexture("DetailNoise", noise.detailTexture);
        }
        else {
        EffectMaterial.SetTexture("ShapeNoise", shapeNoise);
        EffectMaterial.SetTexture("DetailNoise", detailNoise);
        }
        EffectMaterial.SetVector("CloudOffset", CloudOffset);
        EffectMaterial.SetFloat("CloudScale", CloudScale);
        EffectMaterial.SetFloat("DensityThreshold", DensityThreshold);
        EffectMaterial.SetFloat("DensityMultiplier", DensityMultiplier);
        EffectMaterial.SetInt("NumSteps", NumSteps);


        Graphics.Blit(src, dest, EffectMaterial);
    }

}
