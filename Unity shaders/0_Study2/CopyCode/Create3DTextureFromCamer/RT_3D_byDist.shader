Shader "Unlit/RT_3D_byDist"
{
    Properties
    {
        _Box ("Box", Vector) = (0,0,0,0.1)
        _BoxPos ("BoxPos", Vector) = (0,0,0,0.1)
        _Sphere1 ("Sphere 1", Vector) = (0,0,0,0.1)
        _MainTex ("Texture", 2D) = "white" {}
        _Tex3D ("3D Texture", 3D) = "white" {}
        _Noise3D ("Noise 3D Texture", 3D) = "white" {}
        _CloudStart ("Cloud Start", Range(1, 10)) = 1
        _MaxIter ("Max Iterations", Range(1,100)) = 20
        _MinStep ("Min Step", Range(0.00001, 1)) = 0.00001
        _MaxDist ("Max Distance", Range(1,1000)) = 20
        _MaxEmi ("Max Emission", Range(0,10)) = 1
        _Scale ("Scale", Range(0.1, 10)) = 1
        _NoiseScale ("Noise Scale", Range(0.1, 10)) = 1
        _DensityMult ("Density Mult", Range(0.00001, 1)) = 1
        _DensityMult2 ("Density Mult2", Range(0.00001, 1)) = 1
        _DensityMax ("Density Max", Range(0.00001, 1)) = 1
        _MarchFactor ("March Factor", Range(0.00001, 1)) = 1


        _ShadowIntensity("ShadowIntensity", Range(0, 1)) = 0.5
        _ShadowDistance("ShadowDistance", Vector) = (0, 0,0,0)
        _LightIntensity("LightIntensity", Float) = 0.5
        _LightCol("LightCol", Color) = (1, 1, 1, 1) 
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
            float4 _MainTex_ST;

            sampler3D _Tex3D;
            sampler3D _Noise3D;
            float _MaxIter, _CloudStart, _Scale, _DensityMult, _NoiseScale, _DensityMult2, _MarchFactor, _MaxDist,
            _MaxEmi, _DensityMax, _MinStep;
            float4 _Sphere1, _Box, _BoxPos;            

            uniform float _LightIntensity;
            uniform float3 _LightCol;
            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity;

            float sdBox(float3 p, float3 b, float3 origin)
            {
                float3 d = abs(p) - b;
                return length(max(d,0.0)) + min(max(d.x,max(d.y,d.z)),0.0);
            }

            float DE(float3 pos) {
                float box = sdBox(pos, _Box.xyz, _BoxPos.xyz);
                float d = max(tex3D(_Tex3D, float3(0.5,0.5,0.5) + pos).r, box);
                float sphere = length(pos + _Sphere1.xyz) - _Sphere1.w;
                float toReturn = min(d, sphere);
                return toReturn;
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

            float hardShadow(float3 ro, float3 rd, float mint, float maxt)
            {
                [unroll(3)]
                for(float t = mint; t < maxt;)
                {
                    float h = DE(ro+rd*t);
                    if(h < 0.001) return 0;
                    t += h;
                }
                return 1.0;
            }

            float3 Shading(float3 p, float3 n)
            {
                //Directional Light
                float3 result = (_LightCol * dot(_WorldSpaceLightPos0, n) *0.5 + 0.5) * _LightIntensity;
                float shadow = hardShadow(p, _WorldSpaceLightPos0, _ShadowDistance.x, _ShadowDistance.y) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _ShadowIntensity));
                result *= shadow;
                return result;
            }

            float Density(float3 pos) {
                float d = tex3D(_Noise3D, pos * 1/_NoiseScale).r;
                return d;
            }

            float Raymarch(float3 ro, float3 rd, inout fixed4 col) {
                float3 pos = ro;
                float d = 0;
                float dist = 0;
                float origind2 = 0;
                float prevD = 0;
                [unroll(100)]
                for (int i = 0; i < _MaxIter; i++) {
                    pos += rd * d;
                    d = DE(pos / _CloudStart);
                    dist += d;
                    if(d < _MinStep || dist >= _MaxDist) break;
                }
                float3 normal = GetNormal(pos);
                float3 shadow = Shading(pos,  normal);
                [unroll(100)]
                for (int i2 = 0; i2 < _MaxIter; i2++) {
                    float density = abs(Density(pos / _NoiseScale));
                    if (i2==0) { origind2 = dist; prevD = density; }
                    dist += (1-density) * _MarchFactor;
                    pos += rd * (1-density) * _MarchFactor;
                    col.a += (density) * _DensityMult2 * abs(length(shadow));
                    
                    col.rgb *= shadow;
                    if (col.a >= _MaxEmi || dist >= _MaxDist || density >= _DensityMax) break;
                }
                return dist;
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
                fixed4 col = (1,1,1,0);
                float3 ro = i.worldPos.xyz;
                float3 rd = normalize(ro - _WorldSpaceCameraPos);
                //float dist = Raymarch(ro, rd, col);
                float dist2 = 0;
                float3 pos = ro + dist2 * rd;
                fixed4 newColor;
                float box2;
                [unroll(100)]
                for(int i = 0; i < 100 ; i++)
                {
                    box2 = sdBox(pos + _BoxPos.xyz, _Box.xyz, _BoxPos.xyz);
                    pos += rd * box2;
                    dist2 += box2;
                    if (box2 < 0.0001) break;
                }
                if (dist2 > _MaxDist) discard;
                return fixed4(frac(dist2),frac(dist2),frac(dist2),1);
            }
            ENDCG
        }
    }
}
