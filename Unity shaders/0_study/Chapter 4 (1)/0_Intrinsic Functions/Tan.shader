﻿Shader "Unlit/Tan"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Sections ("Sections", Range(2,100)) = 10
        _HologramMask ("Hologrm Mask", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100
        //Cull Off
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
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
            float _Sections;
            sampler2D _HologramMask;

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
                fixed4 mask = tex2D(_HologramMask, i.uv);
                // sample the texture
                float4 tanCol = clamp(0 , abs(tan((i.uv.y - _Time.x) * _Sections)), 1);
                tanCol *= _Color;
                fixed4 col = tex2D(_MainTex, i.uv);
                //col.a *= tanCol;
                //col.a += step(col.a, mask.a);
                
                col.a = tanCol;
                col.a += mask.a;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
