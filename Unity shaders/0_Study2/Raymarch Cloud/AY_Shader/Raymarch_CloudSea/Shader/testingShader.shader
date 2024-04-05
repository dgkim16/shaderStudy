Shader "Unlit/testingShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float4 vert : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;


            float DE(float3 pos)
            {
                float d = length(pos) - 1;
                return d;
            }

            float Raymarch(float3 ro, float3 rd)
            {
                float t = 0;
                for(int i = 0 ; i < 100; i++)
                {
                    float3 pos = ro + rd * t;
                    float d = DE(pos);
                    if(d < 0.001)
                        return t;
                }
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vert = v.vertex;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 pos = mul(unity_WorldToObject, float4(0,0,0,1)); 
                pos = mul(unity_WorldToObject, i.worldPos);
                pos = mul(unity_ObjectToWorld, i.worldPos);
                pos = i.vert;
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}

