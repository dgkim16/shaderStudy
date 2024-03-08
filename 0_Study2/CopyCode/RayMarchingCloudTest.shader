Shader "Unlit/RayMarchingCloudTest"
{
    Properties
    {

        _isModulo ("Modulo", Range(0.0, 3.0)) = 0.0
        _ModFactor("ModFactor", Vector) = (0,0,0,0)
        
        _Color("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex1 ("NoiseTex xz", 2D) = "white" {}
        _NoiseTex2 ("NoiseTex xy", 2D) = "white" {}
        _NoiseTex3D ("Noise Texture", 3D) = "white" {}
        _Clipper ("Clipper", Range(-10, 10)) = -10
        _Smooth ("Smooth", Range(0, 1)) = 0.5

        [Space(10)]
        [HDR]_BrightColor("Bright Color", Color) = (1.3,1.3,1.3,1.0)
        [HDR]_ShadeColor("ShadeColor", Color) = (0.19, 0.63, 1.0, 1.0)

        [Space(40)]
        [HideInInspector]_Sphere1 ("Sphere1", Vector) = (0,0,0,1)
        [HideInInspector]_Sphere2 ("Sphere2", Vector) = (0,0,0,1)
        [HideInInspector]_Box1 ("Box", Vector) = (0,0,0,0.1)
        [HideInInspector]_Box1Scale ("Box", Vector) = (0,0,0,0.1)
        _NoiseScroll ("NoiseScroll", Vector) = (0,0,0,0)
        _NoiseScroll2 ("NoiseScroll2", Vector) = (0,0,0,0)
        _3DNoiseScroll("3DNoiseScroll", Vector) = (0.1,0,0,0)
        _NoiseScale ("NoiseScale", Range(0, 10)) = 1
        _NoiseScale2 ("NoiseScale2", Range(0, 10)) = 1
        _3DNoiseScale("3DNoiseScale", float) = 0.03
        _NoiseIntensity ("NoiseIntensity", Range(0, 10)) = 1
        _NoiseIntensity2 ("NoiseIntensity2", Range(0, 10)) = 1
        _CloudRange ("CloudRange", Range(0, 10)) = 1
        _CloudThreshold ("CloudThreshold", Range(0, 1)) = 0.5
        _MaxDensity ("MaxDensity", Range(0, 10)) = 1
        _Opacity ("Opacity", Range(0, 1)) = 0.9
        _lightStepDistance("lightStepDistance", Range(0, 1)) = 0.1
        _Absorption("Absorption", Range(0, 1)) = 0.1

        _ShadowIntensity("ShadowIntensity", Range(0, 1)) = 0.5
        _ShadowDistance("ShadowDistance", Vector) = (0, 0,0,0)
        _LightIntensity("LightIntensity", Range(0, 1)) = 0.5
        _LightDir("LightDir", Vector) = (0, 0, 0)
        _LightCol("LightCol", Color) = (1, 1, 1, 1)


    }
    SubShader
    {
        Tags { "RenderType"="transparent" "LightMode"="ForwardBase" "Queue"="Transparent"}
        Cull Back
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float4 screenPos : TEXCOORD1;
                float2 depth : TEXCOORD2;
            };

            struct pout
            {
                fixed4 color : SV_Target;
                float depth : SV_Depth;
            };

            sampler2D _MainTex;
            fixed4 _Color;
            float4 _MainTex_ST;
            float4 _Sphere1, _Sphere2, _Box1, _Box1Scale;
            fixed4 _BrightColor, _ShadeColor;
            sampler2D _NoiseTex1, _NoiseTex2;
            sampler3D _NoiseTex3D;
            float4 _NoiseScroll, _NoiseScroll2, _3DNoiseScroll;
            float _NoiseScale, _NoiseScale2, _3DNoiseScale;
            float _NoiseIntensity, _NoiseIntensity2;
            float _CloudRange, _MaxDensity;
            float _Clipper;
            float _Smooth, _CloudThreshold, _Opacity, _lightStepDist, _Absorption;
            float _Steps = 100;
            float _isModulo;
            float4 _ModFactor;

            uniform float _LightIntensity;
            uniform float3 _LightDir, _LightCol;
            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity;



            float getTex1(float3 p){
                return tex2D(_NoiseTex1, (p.xz+_Time.y*_NoiseScroll.xy)*_NoiseScale) * _NoiseIntensity;
            }

            float getTex2(float3 p){
                return tex2D(_NoiseTex2, (p.xz+_Time.y*_NoiseScroll2.xy)*_NoiseScale2) * _NoiseIntensity2;
            }

            float getTex3D(float3 p){
                return tex3D(_NoiseTex3D, frac(p * _3DNoiseScale + float3(_Time.y * _3DNoiseScroll.xyz)));

            }

            float pMod (inout float p, float size)
            {
                float halfsize = size * 0.5;
                float c = floor((p+halfsize)/size);
                p = fmod(p+halfsize,size)-halfsize;
                p = fmod(-p+halfsize,size)-halfsize;
                return c;
            }

            float sdSphere(float3 p, float s) {
                return length(p) - s;
            }

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
            }

            float opUS(float d1, float d2, float k)
            {
                float h = clamp(0.5+0.5*(d2-d1)/k, 0.0, 1.0);
                return lerp(d2, d1, h) - k*h*(1.0-h);
            }
            

            float DE(float3 p) {
                float3 modedP = p;
                //if(_isModulo >= 0.5 )
                //{
                //    if(_isModulo == 1)
                //        modedP = float3(pMod(p.x, _ModFactor.x), p.y, pMod(p.y, _ModFactor.z));
                //    if(_isModulo == 2)
                //        modedP = float3(pMod(p.x, _ModFactor.x), pMod(p.y, _ModFactor.y), pMod(p.y, _ModFactor.z));
                //    //modedP = float3(pMod(p.x, _ModFactor), pMod(p.y, _ModFactor), pMod(p.z, _ModFactor));
                //}
                float d1 = sdSphere(modedP - _Sphere1.xyz, _Sphere1.w);
                float d2 = sdBox(modedP - _Box1.xyz, _Box1Scale.xyz);
                float d3 = sdSphere(modedP - _Sphere2.xyz, _Sphere2.w);
                //return min(d1, d2);
                return opUS(opUS(d1, d2, _Smooth), d3, _Smooth);
                //return d1;
            }
            float densityFunction(float3 p)
            {
                // p 위치의 밀도값을 변환
                return (_CloudRange - DE(p) - getTex1(p) - getTex2(p))
                * _MaxDensity * getTex3D(p)
                / _CloudRange;
            }

            float hardShadow(float3 ro, float3 rd, float mint, float maxt)
            {
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
                float result = (_LightCol * dot(_WorldSpaceLightPos0, n) *0.5 + 0.5) * _LightIntensity;
                float shadow = hardShadow(p, _WorldSpaceLightPos0, _ShadowDistance.x, _ShadowDistance.y) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _ShadowIntensity));
                result *= shadow;
                return result;
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(0.001, 0);
                //float3 n = DE(p) - float3(DE(p-e.xyy), DE(p-e.yxy), DE(p-e.yyx));
                float3 n = float3(
                    DE(p + e.xyy) - DE(p - e.xyy),
                    DE(p + e.yxy) - DE(p - e.yxy),
                    DE(p + e.yyx) - DE(p - e.yyx));
                return normalize(n);
            }

            float3 Raymarch(float3 ro, float3 rd, float3 lightRayDist, inout float3 shadow) {
                float dO = 0;
                float dS;
                float density = 0;
                float alpha = 0;
                float transmittance = 1;
                float lightPower = 0.0;
                [unroll(112)]
                for(int i=0; i < 100; i++) {
                    float3 p = ro + rd * dO;
                    dS = DE(p);
                    float cDensity = densityFunction(p);
                    float temp = cDensity * pow(2.741592, -dS);
                    if(temp > alpha)
                    {
                        alpha = temp;
                        transmittance *= 1 - saturate(_Opacity * temp);
                        float3 lightPos = p;
                        float transmittanceLight = 1.0;
                        [unroll]
                        for(int k = 0; k < 3; k++) // 3번 까지만 
                        {
                            float densityLight = densityFunction(lightPos);
                            if(densityLight > 0.0)
                            {
                                float dl = densityLight * _lightStepDist;
                                transmittanceLight *= 1.0 - dl * _Absorption;
                                if(transmittanceLight < 0.01)
                                    break;
                            }
                            lightPos += lightRayDist;
                        }
                        lightPower += (_Opacity * temp * transmittance * transmittanceLight);
                        shadow = Shading(p, GetNormal(p));
                    }
                    dO += dS;
                    if(dS < 0.00001 || dO > 100.0)
                        break;
                }
                return float3(alpha, lightPower, dO);
            }

            

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.screenPos = mul(UNITY_MATRIX_VP, v.vertex);
                o.depth = -mul(UNITY_MATRIX_MV, v.vertex).z *_ProjectionParams.w;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float _depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,  UNITY_PROJ_COORD(i.screenPos));
                float sceneZ = LinearEyeDepth(_depth);

                float3 worldPos = i.worldPos;
                float3 camViewDir = -UNITY_MATRIX_V._m20_m21_m22;
                float3 worldDir = normalize(worldPos - _WorldSpaceCameraPos);
                float depthLength = length(sceneZ * worldDir * (1.0 / dot(camViewDir, worldDir)));
                depthLength += _Clipper;
                fixed4 col = _Color;
                float3 lightRayDist = normalize(_WorldSpaceLightPos0.xyz) * _lightStepDist;
                float3 shadow = float3(1,1,1);
                float3 densLight = Raymarch(worldPos, worldDir, lightRayDist, shadow);

                float density = densLight.x;
                float lightPower = densLight.y;
                //float shadow = densLight.z;
                if(density < _CloudThreshold)
                    discard;
                density = density - _CloudThreshold;
                density = density / (1.0 - _CloudThreshold);
                col.a = clamp(density,0,1);
                col.rgb *= lerp(_ShadeColor.rgb, _BrightColor.rgb, lightPower);
                col.rgb *= shadow;

                return col;
            }
            ENDCG
        }
    }
}
