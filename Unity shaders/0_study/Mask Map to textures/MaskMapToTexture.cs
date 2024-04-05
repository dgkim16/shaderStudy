using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

[ExecuteInEditMode]
public class MaskMapToTexture : EditorWindow
{
    public Texture2D maskMap;
    public string textureName = "Untitled";
    public int width, height;

    public string path
    {
        get{
            string a = "";
            if (maskMap != null)
            {
                a = AssetDatabase.GetAssetPath((Object)maskMap);
                a= a.Substring(0, a.IndexOf(((Object)maskMap).name));
            }
            return a;
        }
    }
    [MenuItem("Window/Tools/Mask Map to Texture")]
    public static void ShowWindow()
    {
        GetWindow<MaskMapToTexture>("Mask Map to Texture");
    }

    public void OnGUI()
    {
        maskMap = ShowTexGUI("Mask Map", maskMap);
        textureName = EditorGUILayout.TextField("Name", textureName);
        width = EditorGUILayout.IntField("Width", width);
        height = EditorGUILayout.IntField("Height", height);

        if(GUILayout.Button("Unpack Texture"))
        {
            UnpackTexture();
        }
        if(GUILayout.Button("Clear"))
        {
            maskMap = null;
            textureName = "untitled";
            width = 0;
            height = 0;
        }

    }

    public void UnpackTexture()
    {
        List<Texture2D> textures = new List<Texture2D>();
        Texture2D metalic = new Texture2D(width, height);
        Texture2D ambientOcclusion = new Texture2D(width, height);
        Texture2D detailMask = new Texture2D(width, height);
        Texture2D smoothness = new Texture2D(width, height);
        Texture2D invSmoothness = new Texture2D(width, height);
        textures.Add(metalic);
        textures.Add(ambientOcclusion);
        textures.Add(detailMask);
        textures.Add(smoothness);
        textures.Add(invSmoothness);
        int temp = 0;
        string[] names = new string[] { "Metallic", "Ambient Occlusion", "Detail Mask", "Smoothness", "Inv Smoothness" };
        foreach (Texture2D t in textures)
        {
            t.SetPixels(ColorArray(temp));
            
            byte[] tex = t.EncodeToPNG();
            FileStream stream = new FileStream(path + textureName + "_" + names[temp] + ".png", FileMode.OpenOrCreate, FileAccess.ReadWrite);
            BinaryWriter writer = new BinaryWriter(stream);
            for(int j = 0; j < tex.Length; j++)
            {
                writer.Write(tex[j]);
            }
            stream.Close();
            writer.Close();

            AssetDatabase.ImportAsset(path + textureName + "_" + names[temp] + ".png", ImportAssetOptions.ForceUpdate);
            AssetDatabase.Refresh();
            temp++;
        }

    }

    private Color[] ColorArray(int channel)
    {
        Color[] cl = new Color[width * height];
        for(int j = 0 ; j < cl.Length; j++)
        {
            cl[j] = new Color();
            if(maskMap != null)
            {
                float colorVal = 0;
                if (channel == 0)
                   colorVal = maskMap.GetPixel(j % width, j / width).r;
                else if (channel == 1)
                    colorVal = maskMap.GetPixel(j % width, j / width).g;
                else if (channel == 2)
                    colorVal = maskMap.GetPixel(j % width, j / width).b;
                else if (channel == 3)
                    colorVal = maskMap.GetPixel(j % width, j / width).a;
                else if (channel == 4)
                    colorVal = 1- maskMap.GetPixel(j % width, j / width).a;
                cl[j].r = colorVal;
                cl[j].g = colorVal;
                cl[j].b = colorVal;
                if(channel == 0)
                    cl[j].a = maskMap.GetPixel(j % width, j / width).a;
                else
                    cl[j].a = colorVal;
            }
        }
        return cl;
    }

    public Texture2D ShowTexGUI(string fieldName, Texture texture)
    {
        return(Texture2D)EditorGUILayout.ObjectField(fieldName, texture, typeof(Texture2D), false);
    }
}
