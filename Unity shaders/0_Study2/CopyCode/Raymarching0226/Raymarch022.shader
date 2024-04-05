Shader "Unlit/Raymarch022"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Power ("Power", Float) = 1.0
        _ColourAMix ("Colour A Mix", Color) = (1,1,1,1)
        _ColourBMix ("Colour B Mix", Color) = (1,1,1,1)
        _Darkness ("Darkness", Float) = 70.0
        _BlackAndWhite ("Black and White", Range(0.0,1.0)) = 0.0
        _DebugVector ("Debug Vector", Vector) = (0,0,0,0)
        _DebugFloat ("Debug Float", Float) = 0.0
        _Radius ("Radius", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        ZWrite Off
        Cull Off
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
                UNITY_FOG_COORDS(1)
                float4 clipPos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                float4 vertexPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Power, _Darkness, _BlackAndWhite;
            float4 _ColourAMix, _ColourBMix;

            float _DebugFloat, _Radius;
            float4 _DebugVector;
            

            struct Ray{
                float3 origin;
                float3 direction;
            };

            float opUS(float d1, float d2, float k)
            {
                float h = clamp(0.5+0.5*(d2-d1)/k, 0.0, 1.0);
                return lerp(d2, d1, h) - k*h*(1.0-h);
            }
            

            Ray CreateRay(float3 origin, float3 direction) {
                Ray ray;
                ray.origin = origin;
                ray.direction = direction;
                return ray;
            }
            
            float2 SceneInfo(float3 position) {
                float3 z = position;
                float dr = 1.0;
                float r = 0.0;
                int iterations = 0;
                for (int i = 0; i < 15 ; i++) {
                    iterations = i;
                    r = length(z) - _Radius;

                    if (r>2) {
                        break;
                    }
                    
                    // convert to polar coordinates
                    float theta = acos(z.z/r);
                    float phi = atan2(z.y,z.x);
                    dr =  pow( r, _Power-1.0)*_Power*dr + 1.0;

                    // scale and rotate the point
                    float zr = pow( r,_Power);
                    theta = theta*_Power;
                    phi = phi*_Power;
                    
                    // convert back to cartesian coordinates
                    z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
                    z+=position;
                }
                float dst1 = (0.5*log(r)*r/dr);
                float dst2 = length(position + _DebugVector.xyz) - _DebugVector.w;
                float dst = opUS(dst1,dst2,_DebugFloat);
                return float2(iterations,dst*1);
            }

            float3 EstimateNormal(float3 p) {
                float x = SceneInfo(float3(p.x+0.001,p.y,p.z)).y - SceneInfo(float3(p.x-0.001,p.y,p.z)).y;
                float y = SceneInfo(float3(p.x,p.y+0.001,p.z)).y - SceneInfo(float3(p.x,p.y-0.001,p.z)).y;
                float z = SceneInfo(float3(p.x,p.y,p.z+0.001)).y - SceneInfo(float3(p.x,p.y,p.z-0.001)).y;
                return normalize(float3(x,y,z));
            }

            

            v2f vert (appdata v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.vertexPos = v.vertex;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 camPos = _WorldSpaceCameraPos;
                float3 camDir = -normalize(WorldSpaceViewDir(i.vertexPos));
                float4 result = lerp(float4(51,3,20,1),float4(16,6,28,1),i.vertexPos.y)/255.0;
                Ray ray = CreateRay(i.worldPos, camDir);
                float rayDst = 0;
                int marchSteps = 0;
                [unroll(50)]
                while (rayDst < 100 && marchSteps < 100) {
                    float3 pos = ray.origin + ray.direction * rayDst;
                    float2 sceneInfo = SceneInfo(pos);
                    float dst = sceneInfo.y;
                    
                    if (dst < 0.001) {
                        float3 escapeIterations = sceneInfo.x;
                        float3 normal = EstimateNormal(ray.origin-ray.direction*0.001*2);
                        float3 lightDir = dot(normal, _WorldSpaceLightPos0);
                        float colourA = saturate(dot(normal*.5+.5,-lightDir));
                        float colourB = saturate(escapeIterations/16.0);
                        float3 colourMix = saturate(colourA * _ColourAMix.xyz + colourB * _ColourBMix.xyz);
                        result = float4(colourMix.xyz,1);
                        break;
                    }
                    rayDst += dst;
                    marchSteps++;
                }
                float rim = marchSteps/_Darkness;
                float4 col = lerp(result, 1, _BlackAndWhite) * rim;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;

            }
            ENDCG
        }
    }
}
