Shader "Unlit/EnvReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ReflectionTex("Reflection Texture", Cube) = "white" {}
        _ReflectionInt ("Reflection Intensity", Range(0, 1)) = 1
        _ReflectionMet("Reflection Metallic", Range(0, 1)) = 0
        _ReflectionDet("Reflection Detail", Range(1, 9)) = 1
        _ReflectionExp("Reflection Exp", Range(1,3)) = 1
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal_world : TEXCOORD1;
                float3 vertex_world : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 AmbientReflection;
            samplerCUBE _ReflectionTex;
            float _ReflectionInt;
            float _ReflectionMet;
            half _ReflectionDet;
            float _ReflectionExp;

            float3 AmbientReflection2(
                samplerCUBE colorRefl,
                float reflectionInt,
                half reflectionDet, // reflection detail *texel density, 1~9
                float3 normal,
                float3 viewDir,
                float reflectionExp
            ) {
                float3 reflection_world = reflect(viewDir, normal);
                float4 cubemap = texCUBElod(colorRefl, float4(reflection_world, reflectionDet));
                return reflectionInt * cubemap.rgb * (cubemap.a * reflectionExp);
            }

            // float3 reflect 와 같음
            // i : incident vector; view direction
            // n : normal vector
            float3 reflect2(float3 i, float3 n) 
            {
                return i - 2.0 * n * dot(n,i);
            }
            //float3 reflection_world = reflect(viewDir, normal);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal_world = normalize(mul(unity_ObjectToWorld, float4(v.normal,0))).xyz;
                o.vertex_world = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                half3 normal = i.normal_world;
                half3 viewDir = normalize(UnityWorldSpaceViewDir(i.vertex_world));

                //half3 reflect_world = reflect(-viewDir, normal);
                //half3 reflectionData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, reflect_world);
                //half3 reflectionColor = DecodeHDR(reflectionData, unity_SpecCube0_HDR);
                //col.rgb = reflectionColor;
                //return col;
                half3 reflection = AmbientReflection2(_ReflectionTex,_ReflectionInt,_ReflectionDet,normal,-viewDir,_ReflectionExp);
                col.rgb *= reflection + _ReflectionMet;

                return col;
            }
            ENDCG
        }
    }
}
