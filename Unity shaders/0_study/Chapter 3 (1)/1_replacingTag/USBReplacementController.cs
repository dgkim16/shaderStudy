using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class USBReplacementController : MonoBehaviour
{
    public Shader m_replacementShader;
    // Start is called before the first frame update
    private void OnEnable()
    {
        if(m_replacementShader != null)
        {
            GetComponent<Camera>().SetReplacementShader(m_replacementShader, "RenderType");
        }
    }
    private void OnDisable()
    {
        GetComponent<Camera>().ResetReplacementShader();
    }
}
