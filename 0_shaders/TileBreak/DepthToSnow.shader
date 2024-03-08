Shader "Unlit/DepthToSnow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "LightMode"="ForwardBase" }
        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

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
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD2;
                float4 screenPos : TEXCOORD3;
                float2 depth : TEXCOORD4;
            };

            struct pout
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;



            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.screenPos = mul(UNITY_MATRIX_VP, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            

            fixed4 frag (v2f i) : SV_Target
            {
                float _depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,  UNITY_PROJ_COORD(i.screenPos));
                float sceneZ = LinearEyeDepth(_depth);
                // sample the texture
                fixed4 col = _Color;
                col.a *= sceneZ;
                // apply fog
                return col;
            }
            ENDCG
        }
    }
}
