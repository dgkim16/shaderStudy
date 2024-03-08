Shader "Unlit/Normal Implementation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "white" {}
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
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float2 uv_normal : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float4 tangent_world : TEXCOORD3;
                float3 binormal_world : TEXCOORD4;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;


            // DXT compression of normal map
            // We are only using Alpha and Green channel via DXT compression
            // So a new normalized vector based on AG coordinates needs to be calculated
            // Identical to : UnpackNormal(normal_map);
            float3 DXTCompression(float4 normalMap)
            {
                #if defined (UNITY_NO_DEX5nm)
                    return normalMap.rgb * 2 - 1;
                #else
                    float3 normalCol;  
                    // replace Red channel with Alpha channel (normalMap.a)
                    // Green channel is 2nd channel
                    // Third channel is discarded first, then calculated via pythagorean theorem
                    // Due to normalization, 1 = X^2 + Y^2 + Z^2 (Red^2 + Green^2 + Blue^2)
                    // Z = sqrt(1 - (X^2 + Y^2))
                    normalCol = float3(normalMap.a * 2 -1, normalMap.g *2 -1, 0);
                    // normal map have range between -1 and 1.
                    // 'texture' have range between 0 and 1.
                    // We are using texture to sample normal map from it,
                    // therefore we must normalize [0,1] of texture into [-1,1] by: 
                    // normalMap.rgb * 2 - 1
                    normalCol.b = sqrt(1 - (pow(normalCol.r, 2) + pow(normalCol.g, 2)));
                    return normalCol;
                #endif
            }

            // DXT compression divides texture into blocks of 4x4 pixels, then compress only using 2 channels (AG)
            // this optimizes the normal map to 1/4 resolution



            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                //tiling & offset to normal map
                o.uv_normal = TRANSFORM_TEX(v.uv, _NormalMap);
                //normal to world-space
                o.normal_world = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0)));
                //tangent to world-space
                o.tangent_world = normalize(mul(v.tangent, unity_ObjectToWorld));
                //cross product between normal and tangent to get binormal
                o.binormal_world = normalize(cross(o.normal_world, o.tangent_world) * v.tangent.w);
                //if(mul(o.normal_world, float3(0,1,0)) > 0 && mul(o.normal_world, float3(0,1,0)) <=  1)
                //    o.vertex.y -= 0.5*float4(mul(o.normal_world, float3(0,1,0)).rrrr) * abs(sin(_Time.y * 2));
                return o;
            }
            // generate the TBN array to transform the coordinates of the normal map from world-space to tangent-space.
            fixed4 frag (v2f i) : SV_Target
            {
                // DXT compression of normal map
                fixed4 normal_map = tex2D(_NormalMap, i.uv_normal);
                fixed3 normal_compressed = DXTCompression(normal_map);
                // UnpackNormal(normal_map);
                // tangent_world is float4, so use .xyz to get the float3
                float3x3 TBN_matrix = float3x3
                (
                    i.tangent_world.xyz,
                    i.binormal_world,
                    i.normal_world
                );
                fixed3 normal_color = normalize(mul(normal_compressed, TBN_matrix));
                if(mul(i.normal_world, float3(0,1,0)) > 0 && mul(i.normal_world, float3(0,1,0)) <=  1)
                {
                    //return fixed4 (normal_color,1) + 0.5*fixed4(mul(i.normal_world, float3(0,1,0)).rrrr);
                    //return fixed4 (0,0,0,1) + 0.5*fixed4(mul(i.normal_world, float3(0,1,0)).rrrr);
                    return fixed4(1,1,1,1);
                }
                return fixed4(0,0,0,1);
                //return fixed4 (normal_color, 1);
            }
            ENDCG
        }
    }
}
