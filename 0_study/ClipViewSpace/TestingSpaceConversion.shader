Shader "Unlit/TestingSpaceConversion"
{
    Properties
    {
        _Mode("Mode", Range(0.0,2.0)) = 0
        _LightMode("LightMode", Range(0.0,1.0)) = 0
        _MainTex ("Texture", 2D) = "white" {}
        _Smoother ("Smoother", Range(0.0, 1.0)) = 0.5
        _isModulo ("Modulo", Range(0.0, 1.0)) = 0.0
        _Steps("Steps", Range(1, 5000)) = 100
        [HideInInspector]_Sphere1 ("Sphere1", Vector) = (0,0,0,0.1)
        [HideInInspector]_Box ("Box", Vector) = (0,0,0,0.1)
        [HideInInspector]_BoxScale ("BoxScale", Vector) = (0,0,0,0.0)
        _ModFactor("ModFactor", Range(0, 10)) = 2
        _CloudMultiplierSurfDist("CloudMultiplierSurfDist", Range(0.0000001, 2.0)) = 0.01

        [space(40)]
        _Clipper ("Clipper", Range(-10,10)) = 0
        _CloudInOut ("Cloud InOut", Range(-1.0, 1.0)) = 1.0
        _CloudRayDist ("Cloud rayDist", Range(0.0, 0.5)) = 0.01
        _CloudMaxRayDist ("Cloud MaxRayDist", Range(0.0, 1000.0)) = 0.01
        _CloudMarchLoop ("Cloud MarchLoop", Range(0, 1000)) = 100
        _NoiseTex1 ("NoiseTex1", 2D) = "white" {}
        _NoiseTex2 ("NoiseTex2", 2D) = "white" {}
        _NoiseTex3D ("Noise Texture", 3D) = "white" {}
        _NoiseIntensity ("Noise Intensity", Range(0, 100)) = 0.5
        _NoiseIntensity2("NoiseIntensity2", Range(0, 100)) = 30
        _NoiseScale("NoiseScale1", float) = 0.0015
        _NoiseScale2("NoiseScale2", float) = 0.002
        _3DNoiseScale("3DNoiseScale", float) = 0.03
        _NoiseScroll("NoiseScroll1", Vector) = (2.0,0,0,0)
        _NoiseScroll2("NoiseScroll2", Vector) = (0.7,0,0,0)
        _3DNoiseScroll("3DNoiseScroll", Vector) = (0.1,0,0,0)

        [Space(10)]
        _Absorption("Absorption", Range(0, 1.0)) = 0.9
        _Opacity("Opacity", Range(0, 1.0)) = 0.9
        _CloudThreshold("CloudThreshold", Range(0.0,0.5)) = 0.1

        [Space(10)]
        _StepDist ("Step Distance", Range(0.01, 10)) = 1.2
        _StepEnhanceRate("StepEnhanceRate", Range(1.0, 2.0)) = 1.02
        _lightStepDist ("Light Step Distance", Range(0.01, 10)) = 3

        [Space(10)]
        [HDR]_BrightColor("Bright Color", Color) = (1.3,1.3,1.3,1.0)
        [HDR]_ShadeColor("ShadeColor", Color) = (0.19, 0.63, 1.0, 1.0)

        [Space(10)]
        _MaxDensity("MaxDensity", Range(0.0,10.0)) = 1.0
        _CloudCenter ("Cloud Center", float) = 0
        _CloudRange("CloudRange", float) = 35
        _rayStartOffset("rayStartOffset", Range(0,50)) = 12
        _ClipFar("ClipFar", Range(0, 1000)) = 1000
        

        [space(20)]
        _LightInt ("Light Intensity", Range(0.0, 2.0)) = 1.0
        [space(20)]
        _SpecularColor ("Specular Color", Color) = (1,1,1,1)
        _SpecularInt("Specular Intensity", Range(0, 1)) = 1
        _SpecularPow ("Specular Power", Range(1, 128)) = 64
        [space(20)]
        _FresnelPow ("Fresnel Power", Range(1,5)) = 1
        _FresnelInt ("Fresnel Intensity", Range(0,1)) = 1
        [space(20)]
        _ReflectionTex("Reflection Texture", Cube) = "white" {}
        _ReflectionInt ("Reflection Intensity", Range(0, 1)) = 1
        _ReflectionMet("Reflection Metallic", Range(0, 1)) = 0
        _ReflectionDet("Reflection Detail", Range(1, 9)) = 1
        _ReflectionExp("Reflection Exp", Range(1,3)) = 1
    }
    SubShader
    {
        Name "Color shader"
        Tags { "RenderType"="transparent" "LightMode"="ForwardBase" "Queue"="Transparent"}
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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                float3 ro : TEXCOORD3;
            };

            struct pout
            {
                fixed4 color : SV_Target;
                float depth : SV_Depth;
            };

            float _Mode;
            float _LightMode;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Smoother;
            float4 _Sphere1;
            float4 _Box;
            float4 _BoxScale;

            sampler2D _NoiseTex1, _NoiseTex2;
            sampler3D _NoiseTex3D;
            fixed4 _BrightColor, _ShadeColor;
            float4 _NoiseScroll, _NoiseScroll2, _3DNoiseScroll;
            float _NoiseIntensity, _NoiseIntensity2;
            float _NoiseScale, _NoiseScale2, _3DNoiseScale;
            float _MaxDensity;
            float _Absorption;
            float _Opacity;
            float _CloudThreshold;
            float _Clipper;
            float _StepDist;
            float _lightStepDist;
            float _CloudCenter;
            float _CloudRange;
            float _rayStartOffset;
            float _ClipFar;
            float _StepEnhanceRate;
            float _CloudRayDist;
            float _CloudMaxRayDist;
            float _CloudMarchLoop;
            float _CloudInOut;
            float _CloudMultiplierSurfDist;


            float4 _LightColor0;
            float _LightInt;
            float4 _SpecularColor;
            float _SpecularInt;
            float _SpecularPow;
            float _FresnelInt;
            float _FresnelPow;
            float3 AmbientReflection;
            samplerCUBE _ReflectionTex;
            float _ReflectionInt;
            float _ReflectionMet;
            half _ReflectionDet;
            float _ReflectionExp;
            float _isModulo;
            float _Steps;
            float _ModFactor;

            float getTex1(float3 p){
                return tex2D(_NoiseTex1, (p.xz+_Time.y*_NoiseScroll.xy)*_NoiseScale) * _NoiseIntensity;
            }

            float getTex2(float3 p){
                return tex2D(_NoiseTex2, (p.xz+_Time.y*_NoiseScroll2.xy)*_NoiseScale2) * _NoiseIntensity2;
            }

            float getTex3D(float3 p){
                return tex3D(_NoiseTex3D, frac(p * _3DNoiseScale + float3(_Time.y * _3DNoiseScroll.xyz)));
            }

            float densityFunction(float3 p)
            {
                // p 위치의 밀도값을 변환   
                return (_CloudRange - distance(p, _Sphere1) - getTex1(p) - getTex2(p)) * _MaxDensity * getTex3D(p) / _CloudRange;
                //return getTex3D(p);
            }

            void unity_FresnelEffect_float ( in float3 normal, in float3 viewDir, in float power, out float Out)
            {
                Out = pow((1 - saturate(dot(normal, viewDir))), power);
            }

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

            float3 LambertShading(float3 colorRefl, float lightInt, float3 normal, float3 lightDir)
            {
                return colorRefl * lightInt * max(0, dot(normal, lightDir));
            }

            float3 SpecularShading(float3 colorRefl, float specularInt, float3 normal, float3 lightDir, float3 viewDir, float specularPow)
            {
                float3 h = normalize(lightDir + viewDir);
                return colorRefl * specularInt * pow(max(0, dot(normal, h)), specularPow);
            }



            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            // Mod Position Axis
            float pMod (inout float p, float size)
            {
                float halfsize = size * 0.5;
                float c = floor((p+halfsize)/size);
                p = fmod(p+halfsize,size)-halfsize;
                p = fmod(-p+halfsize,size)-halfsize;
                return c;
            }

            //SMOOTH BOOLEAN OP
            float opUS(float d1, float d2, float k)
            {
                float h = clamp(0.5+0.5*(d2-d1)/k, 0.0, 1.0);
                return lerp(d2, d1, h) - k*h*(1.0-h);
            }

            float opSS( float d1, float d2, float k)
            {
                float h = clamp( 0.5 - 0.5 * ( d2 + d1 ) / k, 0.0, 1.0 );
                return lerp( d2, -d1, h ) + k * h * ( 1.0 - h );
            }

            float opIS(float d1, float d2, float k)
            {
                float h = clamp(0.5-0.5*(d2+d1)/k, 0.0, 1.0);
                return lerp(d2, d1, h) + k*h*(1.0-h);
            }

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
            }
            
            float sdSphere(float3 p, float s) {
                return length(p) - s;
            }

            float opDisplaceSphere(float3 p, float s)
            {
                float d1 = sdSphere(p - _Sphere1.xyz, s);
                float d2 = sin(20*p.x)*cos(20*p.y)*cos(20*p.z);
                return d1+d2;
            }
            

            // distance Estimator. Model here
            float DE(float3 p) {
                float3 modedP = p;
                float returnVal1;
                if(_isModulo >= 0.5 )
                    modedP = float3(pMod(p.x, _ModFactor), pMod(p.y, _ModFactor), p.z);
                    //modedP = float3(pMod(p.x, _ModFactor), pMod(p.y, _ModFactor), pMod(p.z, _ModFactor));
                float Sphere1 = sdSphere(p - _Sphere1.xyz, _Sphere1.w);
                if(_Mode > 1) 
                {
                    float Sphere2;
                    if(_Mode == 1.5)
                    {
                        float3 p2 = float3(-_Sphere1.x, -_Sphere1.y, _Sphere1.z);
                        float3 p3 = float3(_Sphere1.x, -_Sphere1.y, _Sphere1.z);
                        float3 p4 = float3(-_Sphere1.x, _Sphere1.y, _Sphere1.z);
                        Sphere2 = sdSphere(p - p2, _Sphere1.w);
                        float Sphere3 = sdSphere(p - p3, _Sphere1.w);
                        float Sphere4 = sdSphere(p - p4, _Sphere1.w);
                        float BoxM2 = sdBox(p - _Box.xyz, _BoxScale.xyz);

                        float Mod2 = opUS(Sphere2, Sphere3, _Smoother);
                        Mod2 = opUS(Mod2, Sphere4, _Smoother);
                        Mod2 = opUS(Sphere1, Mod2, _Smoother);
                        returnVal1 = min(Mod2, BoxM2);
                    }
                    else if (_Mode > 1.5)
                    {
                        Sphere2 = sdSphere(p + float3(0.1,0,0), 0.1);
                        if(_Mode >= 2)
                            Sphere1 = opDisplaceSphere(p, _Sphere1.w);
                        float Box = sdBox(p, float3(0.1,0.25,0.1));
                        float Box2 = sdBox(p + float3(0,0,-0.1), float3(0.06,0.25,0.1));
                        float Box3 = sdBox(p - _Box.xyz, _BoxScale.xyz);
                        float boxS = opSS(Box, Box2, _Smoother);
                        float boxSS = opUS(boxS, Box3, _Smoother);
                        returnVal1 = opUS(opUS(Sphere1, Sphere2, _Smoother), boxSS, _Smoother);
                    }
                }
                else
                    returnVal1 = Sphere1;
                return min(returnVal1, abs(p.y - 0));
            }

            float Raymarch(float3 ro, float3 rd) {
                float dO = 0;
                float dS;
                for(int i=0; i < _Steps; i++) {
                    float3 p = ro + rd * dO;
                    dS = DE(p);
                    dO += dS;
                    if(dS < 0.00001 || dO > 100.0) break;
                }
                return dO;
            }

            // gets normal at point p
            float3 GetNormal(float3 p) {
                float2 e = float2(0.001, 0);
                //float3 n = DE(p) - float3(DE(p-e.xyy), DE(p-e.yxy), DE(p-e.yyx));
                float3 n = float3(
                    DE(p + e.xyy) - DE(p - e.xyy),
                    DE(p + e.yxy) - DE(p - e.yxy),
                    DE(p + e.yyx) - DE(p - e.yyx));
                return normalize(n);
            }

            float2 sphericalMapping(float3 normal) {
                float2 uv;
                uv.x = 0.5 + atan2(normal.z, normal.x) / (2.0 * 3.14159265);
                uv.y = 0.5 - asin(normal.y) / 3.14159265;
                return uv;
            }

            float LightPower(float3 p, float3 lightRayDist, float d, float transmittance)
            {
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
                            {
                                transmittanceLight = 0.0;
                                break;
                            }
                    }
                    lightPos += lightRayDist;
                }
                return (_Opacity * d * transmittance * transmittanceLight);
            }

            float cloudMarch(inout float3 p, inout float lightPower, float3 n, float3 lightRayDist, float depthLength, inout fixed4 color, float3 worldPos) {
                float3 sPos = p;
                float transmittance = 10;
                float rayDist = _CloudRayDist;
                float total = 0; // distance from raymarched surface by direction of its normal
                [unroll]
                for(int i = 0; i < 100; i++)
                {
                    float density = 1;
                    density = densityFunction(p);
                    if(density < 0.0001) break;
                    float m_factor = clamp(2 * pow(2.718281828459045,-i * 0.1), 0, 1);
                    float d = density * rayDist * m_factor;
                    float dS = distance(p, sPos);
                    color.a += saturate(_Opacity * d * transmittance); // 투명도
                    //color.a *= dS * _CloudMultiplierSurfDist;

                    transmittance *= 1.0 - d * _Absorption;
                    if (transmittance < 0.01) break;
                    if (density > _CloudThreshold)
                        float lightP = LightPower(p, lightRayDist, d, transmittance);
                    rayDist *= _StepEnhanceRate;
                    total += rayDist;
                    //if (depthLength <= distance(_WorldSpaceCameraPos, p))
                    //{
                    //    if (depthLength == distance(_WorldSpaceCameraPos, p)) break;
                    //    total -= rayDist;
                    //    rayDist = depthLength - distance(_WorldSpaceCameraPos, p);
                    //    total += rayDist;
                    //}
                    if(_CloudInOut == -1)
                        p = sPos - n * total;
                    else
                        p = sPos + n * total;
                    if (total > _CloudMaxRayDist) break;
                }
                return distance(_WorldSpaceCameraPos, p);
            }

//            float MarchFromSurface(float3 ro, float3 n)
//            {
//                float dO = distance(_WorldSpaceCameraPos, ro);
//                float dS;
//                for(int i = 0; i < 100; i++)
//                {
//                    float3 p = ro + n * dS;
//                    dS = DE(p);
//                    dO += dS;
//                    if(dS > 2 || dO > 100.0) break;
//                }
//                return dO;
//            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.ro = mul(unity_WorldToObject , float4(_WorldSpaceCameraPos,1));
                return o;
            }



            pout frag (v2f i)
            {
                // 화면 pixel의 depth value 가져오고 linear화, sceneZ에 저장
                float _depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,  UNITY_PROJ_COORD(i.screenPos));
                float sceneZ = LinearEyeDepth(_depth);
                // 카메라가 보는 방향의 벡터 (카메라의 forward vector. 모든 vertex에 대해 동일)
                float3 cameraViewDir = UNITY_MATRIX_V._m20_m21_m22;
                // 현재 vertex의 월드 좌표
                float3 worldPos = i.worldPos;
                // 오브젝트 좌표계에서 카페라의 위치
                float3 ro = i.ro;
                // 월드 좌표계에서 카메라가 픽세를 보는 방향
                float3 worldDir = normalize(worldPos - _WorldSpaceCameraPos);
                // primitive shape과 카메라 사이의 월드상 거리
                float d = Raymarch(_WorldSpaceCameraPos, worldDir);
                // 카메라와 primitive shape 사이의 거리
                float depthLength = length(sceneZ * worldDir * (1.0 / dot(cameraViewDir, worldDir)));
                depthLength += _Clipper;
                fixed4 col = (0,0,0,0);   
                pout o;
                // primitive shape과의 거리가 100 이상이면 discard
                if(d >= 100 ) discard;

                // solidify화
                // primite shape의 월드 좌표, 노멀, uv
                float3 p = worldPos + worldDir * d ;
                float3 sPos = p;
                float3 n = GetNormal(p);
                float2 uv = sphericalMapping(n);
                
                float lightPower = 0;
                float3 lightDIr = normalize(_WorldSpaceLightPos0.xyz);

                // cloud화
                float3 lightRayDist = lightDIr * _lightStepDist;
                float dCloudy = cloudMarch(p, lightPower, n, lightRayDist, depthLength, col, worldPos);
                //if (col.a <= 0.0) discard;
                if(dCloudy >= 100)  discard;
                n = GetNormal(p);
                uv = sphericalMapping(n);
                if(_LightMode == 0)
                    col.rgb = lerp(_ShadeColor.rgb, _BrightColor.rgb, lightPower);
                else
                {
                    col = tex2D(_MainTex, uv);
                    col.rgb *= lerp(_ShadeColor.rgb, _BrightColor.rgb, lightPower);

                    fixed3 colorRefl = _LightColor0.rbg;
                    half3 diffuse = LambertShading(colorRefl, _LightInt, n, lightDIr);
                    fixed3 specCol = _SpecularColor.rgb;
                    half3 specular = SpecularShading(specCol, _SpecularInt, n, lightDIr, worldDir, _SpecularPow);
                    float fresnel = 0;
                    unity_FresnelEffect_float(n, worldDir, _FresnelPow, fresnel);
                    half3 reflection = AmbientReflection2(_ReflectionTex,_ReflectionInt,_ReflectionDet,n,-worldDir,_ReflectionExp);
                    //n = abs(n);
                    //n = clamp(n, 0.3, 1);
                    //col *= fixed4(n,0);

                    col.rgb *= diffuse;
                    col.rgb += specular;
                    col += fresnel * _FresnelInt;
                    col.rgb *= reflection + _ReflectionMet;
                }

                p = _WorldSpaceCameraPos + worldDir * dCloudy + mul(unity_ObjectToWorld, float4(0,0,0,1));
                float3 localPos = mul(unity_WorldToObject, float4(p,1));
                float4 projectionPos = UnityObjectToClipPos(float4(localPos, 1.0)); 
                o.depth = projectionPos.z / projectionPos.w;

                o.color = col;
                return o;
            }
            ENDCG
        }
    }
}
