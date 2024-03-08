using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class USBComputeBuffer : MonoBehaviour
{
    public ComputeShader m_shader;
    //for generating circle
    [Range(0.0f,0.5f)] public float m_radius = 0.5f;
    [Range(0.0f,0.5f)] public float m_center = 0.5f;
    [Range(0.0f,0.5f)] public float m_smooth = 0.01f;
    public Color m_mainColor = new Color();
    
    private RenderTexture m_mainTex;
    private int m_texSize = 128;
    private Renderer m_rend;

    // will later be sent to the compute shader
    struct Circle
    {
        public float radius;
        public float center;
        public float smooth;
    }

    Circle[] m_circle;

    ComputeBuffer m_buffer;

    void Start()
    {
        CreateShaderTex();
    }

    void CreateShaderTex()
    {
        m_mainTex = new RenderTexture(m_texSize, m_texSize, 0, RenderTextureFormat.ARGB32);
        m_mainTex.enableRandomWrite = true;
        m_mainTex.Create();
        
        m_rend = GetComponent<Renderer>();
        m_rend.enabled = true;
    }

    void Update()
    {
        SetShaderTex();
    }

    void SetShaderTex()
    {
        uint threadGroupSizeX;
        // GetKernelThreadGroupSizes(kernel, x, y, x)
        // x,y,z are from [numthreads(x,y,z)]
        m_shader.GetKernelThreadGroupSizes(0, out threadGroupSizeX, out _, out _);
        int size = (int)threadGroupSizeX;   // 128
        m_circle = new Circle[size];
 
        for (int i = 0; i< size; i++)
        {
            Circle circle = m_circle[i];
            circle.radius = m_radius;
            circle.center = m_center;
            circle.smooth = m_smooth;
            m_circle[i] = circle;
        }

        int stride = 12;
        // Compute buffer by default contains 3 arguments: 
        // num elements in buffer, size of each element, type of buffer created
        // ComputeBufferType.Default refers to the StructuredBuffer that is declared in Compute Shader
        m_buffer = new ComputeBuffer(m_circle.Length, stride, ComputeBufferType.Default);
        m_buffer.SetData(m_circle);
        m_shader.SetBuffer(0, "CircleBuffer", m_buffer);    // C#에서 만든 ComputeBuffer룰 ComputeShader의 StructuredBuffer에 연결
        m_shader.SetTexture(0, "Result", m_mainTex);
        m_shader.SetVector("MainColor", m_mainColor);
        m_rend.material.SetTexture("_MainTex", m_mainTex);

        m_shader.Dispatch(0,m_texSize, m_texSize, 1);   // 연산하시오
        m_buffer.Release(); // buffer에서 보관하고 있는 데이터를 해제
    }
}
