using UnityEngine;
using UnityEditor;
using System;
public class USB_blendingCustomInspector : ShaderGUI 
{
    public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI (materialEditor, properties);
        Material targetMat = materialEditor.target as Material;

        float scrFactor = targetMat.GetFloat("_SrcBlend");
        float dstFactor = targetMat.GetFloat("_DstBlend");
        string blendState = "unkown";
        

        switch (scrFactor)
        {
            case 0: //zero
                if (dstFactor == 6)
                    blendState = "Negative Color Blending";
                break;
            case 1: //one
                if (dstFactor == 1)
                    blendState = "Additive blending color";
                break;
            case 2: //dstColor
                if (dstFactor == 0)
                    blendState = "Multiplicative blending color";
                break;
            case 3: //srcColor
                if (dstFactor == 2)
                    blendState = "Blending overlay";
                break;
            case 4: //oneMinusDstColor
                if (dstFactor == 1)
                    blendState = "Mild additive blending color";
                break;
            case 5: //srcAlpha
                if (dstFactor == 10)
                    blendState = "Common transparent blending";
                break;
            case 7: //oneMinusSrcColor
                if (dstFactor == 1)
                    blendState = "Soft light blending";
                break;
            default:
                break;
        }

        EditorGUILayout.HelpBox("Source Blend Factor: " + scrFactor + "\n\nDestination Blend Factor: " + dstFactor + "\n\n" +blendState, MessageType.Info);
        string instructions = "";
        instructions += "● Blend SrcAlpha OneMinusSrcAlpha \nCommon transparent blending";
        instructions += "\n\n● Blend One One \nAdditive blending color";
        instructions += "\n\n● Blend OneMinusDstColor One \nMild additive blending color";
        instructions += "\n\n● Blend DstColor Zero \nMultiplicative blending color";
        instructions += "\n\n● Blend DstColor SrcColor \nMultiplicative blending x2";
        instructions += "\n\n● Blend SrcColor One \nBlending overlay";
        instructions += "\n\n● Blend OneMinusSrcColor One \nSoft light blending";
        instructions += "\n\n● Blend Zero OneMinusSrcColor \nNegative color blending";
        EditorGUILayout.HelpBox(instructions, MessageType.Info);
        
    }
}