using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class USBSimpleColorController : MonoBehaviour
{
    public ComputeShader m_shader;
    public Texture m_tex;
    public RenderTexture m_mainTex;

    int m_texSize = 256; // power of two 128, 256, 512, 1024, ...
    Renderer m_rend;
    // Start is called before the first frame update
    void Start()
    {
        // width, height, depth buffer, configuration (32bit rgba)
        m_mainTex = new RenderTexture(m_texSize, m_texSize, 0, RenderTextureFormat.ARGB32);
        m_mainTex.enableRandomWrite = true;
        m_mainTex.Create();
        m_rend = GetComponent<Renderer>();
        m_rend.enabled = true;
        // 0 = index numb of kernel function
        m_shader.SetTexture(0, "Result", m_mainTex);
        m_shader.SetTexture(0, "ColTex", m_tex);
        m_rend.material.SetTexture("_MainTex", m_mainTex);
        
        m_shader.Dispatch(0,m_texSize/8, m_texSize/8, 1);   // (kenel index, thread group x, thread group y, thread group z)

    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
