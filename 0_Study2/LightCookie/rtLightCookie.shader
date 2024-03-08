Shader "Unlit/rtLightCookie"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Tex("InputTex", 2D) = "white" {}
        _Options ("Channel", Float) = 0
    }
 
        SubShader
    {
       Lighting Off
       Blend One Zero
 
       Pass
       {
            CGPROGRAM
            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader
            #pragma fragment frag
            #pragma target 3.0
    
            float4 _Color;
            sampler2D _Tex;
            float _Options;

            float4 frag(v2f_customrendertexture IN) : COLOR
            {
                    float4 color = tex2D(_Tex, IN.localTexcoord.xy);
                        return float4(color.rrrr);
           }
           ENDCG
        }
    }
}