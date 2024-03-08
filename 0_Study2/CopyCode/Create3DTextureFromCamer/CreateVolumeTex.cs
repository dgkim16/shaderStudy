using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

[ExecuteInEditMode]
public class CreateVolumeTex : EditorWindow
{
    public Camera cam;
    public string textureName = "Untitled";
    public RenderTexture rt;
    public string destination;
    public Texture2D read_write_tex;
    public Texture2DArray write_texAr;
    public Texture3D write_tex3D;
    private bool canRun = false;
    public bool canSave = true;

    [MenuItem("Window/Tools/CreateVolumeTexture")]
    public static void ShowWindow()
    {
        GetWindow<CreateVolumeTex>("CreateVolumeTexture");
    }

    void OnGUI() {
        cam = (Camera)EditorGUILayout.ObjectField("Camera", cam, typeof(Camera), true);
        textureName = EditorGUILayout.TextField("Name", textureName);
        if (GUILayout.Button("Check Validity (canRun : " + canRun + ")")) {
            canRun = checkValidity();
        }
        if (canRun) {
            if (GUILayout.Button("Run (canSave : " + canSave + ")"))
                run();
        }
        else
            if (GUILayout.Button("Create")) {
                create();
            }
        if (GUILayout.Button("Clear")) {
            cam = null;
            textureName = "untitled";
            rt = null;
            read_write_tex = null;
            write_texAr = null;
        }
    }

    bool checkValidity() {
        return false;
    }

    void run() {
        float cutOff = cam.farClipPlane;
        float start = cam.nearClipPlane;
        rt = cam.targetTexture;
        for (int i = 0; i < 64; i++)
        {
            cam.farClipPlane = cutOff / 64 * (i + 1);
            cam.nearClipPlane = cutOff / 64 * i;
            cam.Render();
            for (int x = 0; x < rt.width; x++)
            {
                for (int y = 0; y < rt.height; y++)
                    rwPixel(x, y, rt, read_write_tex);
            }
            write_texAr.SetPixels(read_write_tex.GetPixels(), i);
            write_texAr.Apply();
        }
        if(canSave)
            save();
    }

    void create() {
        //var frontDepth = RenderTexture.GetTemporary(5,5,0, RenderTextureFormat.ARGBFloat);
        float timeNow = Time.realtimeSinceStartup;
        float cutOff = cam.farClipPlane;
        float start = cam.nearClipPlane;
        rt = cam.targetTexture;
        read_write_tex = new Texture2D(64, 64, TextureFormat.RGBA32, false);
        write_texAr = new Texture2DArray(64, 64, 64, TextureFormat.RGBA32, false);

        for (int i = 0; i < 64; i++)
        {
            cam.farClipPlane = cutOff * (i+1) / 64;
            cam.nearClipPlane = cutOff  * i / 64 ;
            cam.Render();
            //rwPixel(0, 0, rt, read_write_tex);
            
            Graphics.CopyTexture(rt, read_write_tex);
            //Graphics.CopyTexture(read_write_tex,0, mip, 0, 0, rt.width, rt.height, write_texAr, i);
            
            // write me copy texture to ith array of texture array
            Graphics.CopyTexture(read_write_tex, 0, 0, write_texAr, i, 0);
        }
        if(canSave)
            save();
    }

    void rwPixel(int x, int y, RenderTexture rt, Texture2D tex) {
        tex.ReadPixels(new Rect(x, y, rt.width, rt.height), x, y);
        tex.Apply();
    }

    void save() {
        destination = "Assets/" + textureName + ".asset";
        AssetDatabase.CreateAsset(write_texAr, destination);
    }

    
}
