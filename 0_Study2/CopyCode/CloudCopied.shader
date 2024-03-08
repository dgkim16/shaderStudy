Shader "Unlit/CloudCopied"
{
    Properties
    {
        _Clipper ("Clipper", Range(-10,10)) = 0
        _MainTex ("Texture", 2D) = "white" {}
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
    }
    SubShader
    {
        Tags 
        { 
            "Queue"="Transparent-50"
            "RenderType"="Transparent" 
            "LightMode" = "ForwardBase" 
        }
        LOD 100
        Cull Front
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
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
            static const int _Loop = 100;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float4 projPos : TEXCOORD2;
                float4 locVert : TEXCOORD3;
            };

            struct pout
            {
                fixed4 color : SV_Target;
                float depth : SV_Depth;
            };




            float circle(float3 p, float r)
            {
                return length(p.xz) - r;
            }

            float hash(float n)
            {
                return frac(sin(n) * 43758.5453);   // fractional part 를 반환
            }
            
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
                return (_CloudRange - abs(p.y - _CloudCenter) - getTex1(p) - getTex2(p))
                * _MaxDensity * getTex3D(p)
                / _CloudRange;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.projPos = ComputeScreenPos(o.vertex);
                o.locVert = v.vertex;
                return o;
            }

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            pout frag (v2f i)
            {
                // 국밥 코드들. 카메라와의 거리값, 카메라 방향, 월드 좌표를 저장
                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,  UNITY_PROJ_COORD(i.projPos)));
                float3 cameraViewDir = -UNITY_MATRIX_V._m20_m21_m22;
                float3 worldPos = i.worldPos;
                float3 worldDir = normalize(worldPos - _WorldSpaceCameraPos);
                
                // 카메라와 후면 물체의 거리. 10m 정도 앞으로 해둬야 Z-fighting이 안 일어남.
                float depthLength = length(sceneZ * worldDir * (1.0 / dot(cameraViewDir, worldDir)));
                depthLength += _Clipper;

                // 레이마칭 initialize
                float4 color = 0.0;
                float transmittance = 1.0;
                float total = 0;

                // 좌표계는 오브젝트 기준
                // 오브젝트 기준 좌표를 써야 오브젝트 스케일을 늘려도 바다의 크기가 늘어나지 않음.
                // 월드 좌표를 쓴다면 구름의 위치 조절이 오브젝트의 transform으로 단순하게 변경하기 어려움
                // 0,0,0,1 월드 원점을 오브젝트 좌표계로 변환, 월드의 카메라 위치와 오브젝트 좌표의 차이
                float3 p = _WorldSpaceCameraPos - mul(unity_WorldToObject, float4(0,0,0,1));
                //p -= i.worldPos;    // 시작점
                //float3 p = _WorldSpaceCameraPos - i.worldPos; 
                //p = _WorldSpaceCameraPos - i.locVert;
                float3 sPos = p;    // 시작점
                float rayDist = _StepDist;

                // 빛 관련
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightRayDist = lightDir * _lightStepDist;
                float densityOnLightPos = 1.0;
                float lightPower = 0.0;

                // 카메라가 구름 생성되는 plane 내부에 위치하지 않으면, 카메라 레이저와 구름 생성되는 plane의 교점을 구하고 레이저 시작지점으로 설정
                // _rayStartOffset : 카메라 구름 생성되는 plane 위치 조절
                // _rayStartOffset 조절해서 내리면 loop 횟수 줄어들어서 성능 향상
                float signY = sign(p.y); // 카메라가 구름 생성되는 plane 위에 있는지 아래에 있는지
                //_CloudCenter = _CloudCenter + i.worldPos.y;
                float rayStartY = _CloudCenter + (_CloudRange - _rayStartOffset); // 구름 생성되는 plane의 y 좌표 (object space) 
                if (abs(p.y) > rayStartY) {
                    // ray가 starting plane 밖에 있거나 구름의 반대 방향을 바라볼 경우 discard
                    if (worldDir.y * signY > 0) discard;
                    float3 n  = float3(0,1,0); // vertical vector
                    float3 x = float3(0, rayStartY * signY, 0); // starting plane 위치 (object space)
                    float3 h = dot(n,x); // starting plane과 카메라 위치의 m높이와의 거리를 h.xyz에 넣음 (sphere)
                    // p 는 sphere의 현재 위치. dot(n,p)는 p와 starting plane 사이의 거리
                    // h - dot(n,p) 는 starting plane과 현 위치 사이의 거리 * -1
                    // dot(n,worldDir) 는 카메라 방향의 normalized y값. 작을수록 marching 거리가 늘어남. 카메라가 수평을 바라면 dot(n,worldDir) = 0
                    // dot(n,worldDir) 와 h-dot(n,p)는 discard되지 않았다면 부호가 같음.
                    // 카메라가 수평을 바라볼수록 더 큼
                    p += worldDir * ((h - dot(n,p)) / dot(n,worldDir)); // marching
                    total = distance(p, sPos); // 시작지점과 현재 지점 사이의 거리.
                    // 루핑 부분은 아님. 여러번의 구체 안만들고 하나의 구체로 충돌지점 계산
                }
                // 오브젝트의 뒷면보다 거리가 더 먼 경우, discard
                if (depthLength <= total) discard;
                
                // Horizontal distance 관련해서 clipping
                float total2 = distance(p.xz, sPos.xz);
                if (total2 > _ClipFar) discard;

                // 녹화 시작 지점
                float sTotal = total;

                // Jitter 넣어서 artifacts 줄이기. hash fxn
                float jit = rayDist * hash(worldPos.x + worldPos.y * 10 + worldPos.z * 100 + _Time.x);
                total += jit;

                // 루핑 부분
                [unroll]
                for (int i = 0; i < _Loop; i++)
                {
                    float density = 1;
                    density = densityFunction(p);
                    // 빛 관련
                    if (density > _CloudThreshold)
                    {
                        float d = density * rayDist;    // Cloud density to be multiplied in this step
                        color.a += saturate(_Opacity * d * transmittance); // 투명도
                        transmittance *= 1.0 - d * _Absorption; // 투과율, 점점 작아짐
                        if (transmittance < 0.01) break; // 투과율이 0.01보다 작으면 루핑 끝

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
                        lightPower += (_Opacity * d * transmittance * transmittanceLight);


                    }

                    // step 거리를 매 루프마다 늘림 (step 거리가 짧을수록 더 자세하게 구름을 그림)
                    //rayDist *= _StepEnhanceRate;
                    rayDist *= 1;
                    total += rayDist;
                    // 뒷 부분에 도착하면 끝내기
                    if (depthLength <= total)
                    {
                        if (depthLength == total) break;
                        // 리셋
                        total -= rayDist;
                        rayDist = depthLength - total;
                        total += rayDist;
                    }

                    p = sPos + worldDir * total;

                    // 구름 위에 있을 경우, 끝내시오
                    if (abs(p.y) > rayStartY) break;
                }

                // 빛 색을 기준으로 lerp하여 그림자색과 밝은색의 비율을 조절
                color.rgb = lerp(_ShadeColor.rgb, _BrightColor.rgb, lightPower);

                // 알파값이 0 이하면 depth write쓸 필요 없음. discard
                if (color.a <= 0.0) discard;

                // 월드 좌표로 변환
                p = sPos + worldDir * total + mul(unity_ObjectToWorld, float4(0,0,0,1));

                pout o;
                // 구름 depth write
                // 레이마칭으로 구한 공간의 좌표를 projection 좌표 (= clip좌표) 로 변환후 z/w값을 구하면 depth값이 나옴
                // world to clip바로 안되서 world > obj > clip 이렇게 해야함
                float3 localPos = mul(unity_WorldToObject, float4(p,1));
                float4 projectionPos = UnityObjectToClipPos(float4(localPos, 1.0)); 
                o.depth = projectionPos.z / projectionPos.w;

                o.color = color;
                return o;
            }
            ENDCG
        }
    }
}
