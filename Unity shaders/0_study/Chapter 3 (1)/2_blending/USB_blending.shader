Shader "Unlit/USB_blending"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle] _Enable("Enable Tint", Float) = 0
        _Color ("Color", Color) = (1,1,1,1)
        // dependency   “UnityEngine.Rendering.BlendMode”   allows changning blend mode in inspector
        // TO ALLOW CHANGING BLEND MODE IN INSPECTOR :
        // must add Toggle Enum to properteies, then declare SrcFactor and DstFactor :
        // [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Source Factor", Float) = 1
        // [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Destination Factor", Float) = 1

        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend ("SrcFactor", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend ("DstFactor", Float) = 1
        

    }
    SubShader
    {
        Cull Off
        Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
        // Blending option can be written within SubShader field or Pass field
        // Blend SrcAlpha OneMinusSrcAlpha
        Blend [_SrcBlend] [_DstBlend]
        // Format :     Blend [source factor] [destination factor]
        // ● Blend SrcAlpha OneMinusSrcAlpha        Common transparent blending
        // ● Blend One One                          Additive blending color
        // ● Blend OneMinusDstColor One             Mild additive blending color
        // ● Blend DstColor Zero                    Multiplicative blending color
        // ● Blend DstColor SrcColor                Multiplicative blending x2
        // ● Blend SrcColor One                     Blending overlay
        // ● Blend OneMinusSrcColor One             Soft light blending
        // ● Blend Zero OneMinusSrcColor            Negative color blending




        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ENABLE_ON
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                #if _ENABLE_ON
                    float alpha = col.a;
                    col *= _Color;
                    col.a = alpha;
                    return col;
                #endif
                return col;
            }
            ENDCG
        }
    }
     CustomEditor "USB_blendingCustomInspector"
}
