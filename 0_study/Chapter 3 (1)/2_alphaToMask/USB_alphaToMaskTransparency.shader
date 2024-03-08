Shader "Unlit/USB_alphaToMaskTransparency"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Toggle] _Enable("Enable Mask", Float) = 0
        _MaskTex ("Mask", 2D) = "white" {}
        [Toggle] _EnableTint("Enable Tint", Float) = 0
        _Color ("Color", Color) = (1,1,1,1)
        [Enum(UnityEngine.Rendering.BlendMode)]
        _SrcBlend ("SrcFactor", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]
        _DstBlend ("DstFactor", Float) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType"="Transparent" }
        Blend [_SrcBlend] [_DstBlend]
        AlphaToMask On
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ENABLE_ON
            #pragma shader_feature _ENABLETINT_ON
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
            sampler2D _MaskTex;
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
                    fixed4 mask = tex2D(_MaskTex, i.uv);
                    //col.a = max(mask.a, 0.501);
                    col.a = mask.a;
                #endif
                #if _ENABLETINT_ON
                    col *= _Color;
                #endif
                return col;
            }
            ENDCG
        }
    }
         CustomEditor "USB_blendingCustomInspector"
}
