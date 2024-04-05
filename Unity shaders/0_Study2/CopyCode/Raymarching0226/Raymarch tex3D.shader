Shader "Unlit/Raymarch tex3D"
{
    Properties
    {
        _MainTex ("Texture", 3D) = "white" {}
        _Factor ("Factor", Float) = 1.0
        _VectorTest ("VectorTest", Vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        ZWrite Off
        Cull Back
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
            };

            struct v2f
            {
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
            };

            sampler3D _MainTex;
            float _Factor;
            float4 _VectorTest;

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = i.worldPos;
                float3 pos = worldPos;
                float3 dir = normalize(pos - _WorldSpaceCameraPos);
                float dst = 0;
                float val = 0;
                float val2 = 0;
                float4 returnval = fixed4(0,0,0,0);
                [unroll(100)]
                for(int i = 0; i < 100; i++) {
                    pos = worldPos + dir * dst;
                    //float3 localPos = mul(unity_WorldToObject, float4(pos, 1)).xyz;
                    //val = 1-tex3D(_MainTex, frac(localPos) + _VectorTest);
                    val = tex3D(_MainTex, frac(pos) + _VectorTest);
                    val2 = 1-val;
                    dst += (val) * _Factor;
                    if(val2 > 0.8) {
                        returnval = fixed4(val2,val2,val2,val2) * frac(dst);
                    }
                    if(val2 == 1) {
                        break;
                    }
                    if(sdBox(pos, float3(0,0,0)) > 2)
                       discard;
                }
                return returnval;
            }
            ENDCG
        }
    }
}
