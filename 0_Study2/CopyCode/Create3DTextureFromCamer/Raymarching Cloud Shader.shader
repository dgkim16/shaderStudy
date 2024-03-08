Shader "Unlit/Raymarching Cloud Shader"
{
    Properties
    {
        _Sphere1 ("Sphere 1", Vector) = (0,0,0,0.2)
        _Sphere2 ("Sphere 2", Vector) = (0,0,0,0.2)
        _Box1 ("Box 1 center", Vector) = (0,0,0,0.2)
        _Box1Scale ("Box 1 scale", Vector) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _MainTex3D ("3D Texture", 3D) = "white" {}
        _Gorani3D ("Gorani 3D Texture", 3D) = "white" {}
        _Steps ("Steps", Float) = 100
        _StepDistance("Step Distance", Float) = 0.1
        _CloudMove ("Cloud Move", Vector) = (0,0,0,0)
        _CloudThreshold ("Cloud Threshold", Float) = 0.99
        _DensityThreshold ("Density Threshold", Float) = 0.5
        _MaxDistance ("Max Distance", Float) = 100
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
            };

            sampler2D _MainTex;
            sampler3D _MainTex3D;
            sampler3D _Gorani3D;
            float4 _MainTex_ST;
            float4 _CloudMove;
            float _StepDistance;
            float _Steps;
            float _DensityThreshold;
            float _CloudThreshold;
            float _MaxDistance;
            float4 _Sphere1;
            float4 _Sphere2;
            float4 _Box1, _Box1Scale;

            float sdSphere(float3 p, float s)
            {
                return length(p) - s;
            }

            // Box
            // b: size of box in x/y/z
            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return min(max(d.x, max(d.y, d.z)), 0.0) +
                    length(max(d, 0.0));
            }

            // BOOLEAN OPERATORS //

            // Union
            float opU(float d1, float d2)
            {
                return min(d1, d2);
            }

            // Subtraction
            float opS(float d1, float d2)
            {
                return max(-d1, d2);
            }

            // Intersection
            float opI(float d1, float d2)
            {
                return max(d1, d2);
            }

            float4 opUS( float4 d1, float4 d2, float k ) 
            {
                float h = clamp( 0.5 + 0.5*(d2.w-d1.w)/k, 0.0, 1.0 );
            float3 color = lerp(d2.rgb, d1.rgb, h);
                float dist = lerp( d2.w, d1.w, h ) - k*h*(1.0-h); 
            return float4(color,dist);
            }

            float opSS( float d1, float d2, float k ) 
            {
                float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
                return lerp( d2, -d1, h ) + k*h*(1.0-h); 
            }

            float opIS( float d1, float d2, float k ) 
            {
                float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
                return lerp( d2, d1, h ) + k*h*(1.0-h); 
            }


            // Mod Position Axis
            float pMod1 (inout float p, float size)
            {
                float halfsize = size * 0.5;
                float c = floor((p+halfsize)/size);
                p = fmod(p+halfsize,size)-halfsize;
                p = fmod(-p+halfsize,size)-halfsize;
                return c;
            }

            float GoraniVolume(float3 pos) {
                return tex3D(_Gorani3D, pos).r;
            }

            float getVolume(float3 pos, float factor) {
                return tex3D(_MainTex3D, pos + _CloudMove.x * _Time.y).r * factor;
            }

            float DE(float3 pos) {
                float sphere1 = length(pos - _Sphere1.xyz) - _Sphere1.w;
                float sphere2 = length(pos - _Sphere2.xyz) - _Sphere2.w;
                float3 box = sdBox(pos - _Box1.xyz, _Box1Scale.xyz);
                float sphere = min(sphere1, sphere2);
                if(sphere < 0.1) sphere += getVolume(pos, 0.1);
                float maxed = opSS(sphere,box, 0.1);
                return maxed;
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(0.01, 0);
                //float3 n = DE(p) - float3(DE(p-e.xyy), DE(p-e.yxy), DE(p-e.yyx));
                float3 n = float3(
                    DE(p + e.xyy) - DE(p - e.xyy),
                    DE(p + e.yxy) - DE(p - e.yxy),
                    DE(p + e.yyx) - DE(p - e.yyx));
                return normalize(n);
            }

            float2 RaymarchVolume(float3 ro, float3 rd) {
                float p = ro;
                float density = 0.0;
                float3 pos = 0;
                float d = 0;
                [unroll (500)]
                for(int i = 0; i<_Steps; i++) {
                    pos = ro + rd * d;
                    float temp = 1-GoraniVolume(pos);
                    if(temp > _CloudThreshold)
                        density += temp*0.01;
                    d += _StepDistance;
                    if(d > 100.0 || density >= 1) {
                        break;
                    }
                }
                density -= getVolume(pos,0.1);
                float2 retVal = float2(d, density);
                return retVal;
            }

            float Raymarch(float3 ro, float3 rd) {
                float p = ro;
                float d = 0.0;
                float s = 0.0;
                float3 pos = 0;
                [unroll]
                for(int i = 0; i< 100; i++) {
                    pos = ro + rd * d;
                    s = DE(pos);
                    d += s;
                    if(d > 100.0 || s < 0.001) {
                        break;
                    }
                }
                return d;
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = fixed4(0,0,0,0);
                float3 ro = i.worldPos.xyz;
                float3 rd = normalize(ro - _WorldSpaceCameraPos);
                
                //float2 result = RaymarchVolume(ro, rd);
                //float d = result.x;
                //float density = result.y;
                //if(d > _MaxDistance || density < _DensityThreshold) discard;
                //col = fixed4(density,density,density,1);
                //return col;

                
                float d = Raymarch(ro, rd);
                if(d > _MaxDistance) discard;
                float3 n = GetNormal(ro + rd * d);
                float diffuse = dot(n, normalize(_WorldSpaceLightPos0.xyz - ro));
                col = fixed4(diffuse,diffuse,diffuse,1);
                return col;
            }
            ENDCG
        }
    }
}
