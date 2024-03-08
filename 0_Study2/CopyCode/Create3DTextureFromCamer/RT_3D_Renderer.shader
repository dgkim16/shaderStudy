Shader "Unlit/RT_3D_Renderer"
{
    Properties
    {
        _Debug ("Debug", Range(0,1)) = 1
        _Color ("Color", Color) = (1,1,1,1)
        _ColorScale ("Color Scale", Float) = 1.0
        _EnableOutline ("Enable Outline", Range(0,1)) = 0
        _OutlineColor ("Outline Color", Color) = (0,0,0,0)
        _OutlineWidth ("Outline Width", Float) = 0.001
        _VolumeTex ("Volume 3D Texture", 3D) = "white" {}
        _NoiseTex ("Noise 3D Texture", 3D) = "white" {}
        _CloudScale ("Cloud Scale", Float) = 1.0
        _NoiseScale ("Noise Scale", Float) = 1.0
        _VolumeTexRatio ("Volume Texture Ratio", Vector) = (1,1,1,1)

        _ShadowIntensity("ShadowIntensity", Range(0, 1)) = 0.5
        _ShadowDistance("ShadowDistance", Vector) = (0, 0,0,0)
        _LightIntensity("LightIntensity", Range(0, 1)) = 0.5
        _LightCol("LightCol", Color) = (1, 1, 1, 1)
        _OpacityFactor("OpacityFactor", Range(0, 1)) = 1.0
        _OpacityLimit("OpacityLimit", Range(0, 1)) = 1.0


        _MainTex ("MainTex", 2D) = "white" {}
        _VectorTest ("Vector", Vector) = (0,0,0,0)
        //_Box ("Box", Vector) = (0,0,0,0)
        _rayDistFactor ("rayDistFactor", Float) = 0.1
        _Threshold("Threshold", Range(0,1)) = 0.99
        _CloudThreshold("CloudThreshold", Range(0,1)) = 0.01
        _MaxDist("MaxDist", Float) = 100.0
        
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
            #pragma require 2darray
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
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float2 uv : TEXCOORD0;
                float4 vert : TEXCOORD3;
            };
            

            sampler2D _MainTex;
            sampler3D _VolumeTex;
            sampler3D _NoiseTex;
            float4 _MainTex_ST;
            float4 _VectorTest;
            float4 _Box;
            float _rayDistFactor;
            float _Debug;
            fixed4 _Color, _OutlineColor;
            float _Threshold, _EnableOutline;
            float _CloudScale, _ColorScale, _OutlineWidth, _NoiseScale, _CloudThreshold, _OpacityFactor, _OpacityLimit;
            float4 _VolumeTexRatio;

            uniform float _LightIntensity;
            uniform float3 _LightCol;
            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity;
            float _MaxDist;


            v2f vert (appdata v)
            {
                v2f o;
                o.vert = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.uv.z = (v.vertex.z + 0.5) * _SliceRange;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normal_world = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz);
                return o;
            }

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
            }


            float getTex3D(float3 pos){
                float volume = tex3D(_VolumeTex, (pos * _CloudScale) * float3(_VolumeTexRatio.xyz) + _VectorTest.xyz);
                return volume;
            }

            

            float DE(float3 p)
            {
                //float d = getTex3D(p);
                float d = getTex3D(p);
                return d;
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

            float Raymarch(float3 ro, float3 rd)
            {
                float dist = 0.01;
                float returnVal = 0;
                for(int i = 0; i < 100; i++)
                {
                    float pos = ro + rd * dist;
                    float d = DE(pos);
                    if(d < 0.01)
                        return 1-d;
                    dist += d;
                }
                return 100;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = i.worldPos.xyz;
                float3 rd = normalize(worldPos - _WorldSpaceCameraPos);
                float factorDist = 0;
                float tex3dval = 0;
                fixed4 retColor = fixed4(0,0,0,0);
                float3 pos;
                float hardLine = 0;
                float outLine = _EnableOutline;
                [unroll(100)]
                for(int i = 0; i < 100; i++)
                {
                    
                    if(_Debug == 0)
                    {
                        pos = worldPos + rd * factorDist;
                        float3 localPos = mul(unity_WorldToObject, float4(pos, 1)).xyz;
                        tex3dval = tex3D(_VolumeTex, frac(localPos));
                        hardLine = pow(1-tex3dval,32);
                        float targetColor = tex3dval + 0.4/factorDist;
                        if (hardLine > 0.5) {
                            retColor = fixed4(targetColor, targetColor,targetColor,1);
                            break;
                        }
                        factorDist += tex3dval * _rayDistFactor;
                    }
                    else
                    {
                        pos = worldPos + rd * factorDist;
                        float noise = pow(tex3D(_NoiseTex, (pos * _NoiseScale) + _VectorTest.xyz),2);
                        tex3dval = tex3D(_VolumeTex, (pos * _CloudScale) * float3(_VolumeTexRatio.xyz) + _VectorTest.xyz) * (1-noise);
                        hardLine = (1-tex3dval);
                        if(hardLine > _Threshold - _CloudThreshold) {
                            //retColor = fixed4(_Color.rgb * abs(frac(factorDist)), 1);
                            float distanceToCenter = length(mul(unity_WorldToObject, float4(pos, 1)).xyz);
                            retColor.rgb = float3(_Color.rgb * ((sin(distanceToCenter * _ColorScale) * 0.8) + 0.8) / 0.8 + 0.1);
                            float3 normal = GetNormal(pos);
                            //retColor.rgb *= normal;
                            float3 shadow = Shading(pos,  normal);
                            //float3 nebulaColor = step(shadow, float3(0.5,0.5,0.5)) * shadow;
                            retColor.rgb *= shadow;
                            
                            if(hardLine > _Threshold - _CloudThreshold * 0.5)
                                retColor.a = 0;
                            else {
                                if(retColor.a < 1)
                                    retColor.a += length(shadow) * _OpacityFactor;
                            }
                            if (retColor.a > _OpacityLimit)
                                break;
                            //if(hardLine == _Threshold + _CloudThreshold)
                            //    discard;
                        }
                        if(outLine == 1 && hardLine > _Threshold - _CloudThreshold - _OutlineWidth) {
                            retColor = _OutlineColor;
                            outLine = 0;
                        }
                        factorDist += tex3dval * _rayDistFactor;
                        if(factorDist > _MaxDist)
                            break;
                    }
                     
                    
                }
                //if(abs(pos.x) > _Box.x || abs(pos.y) > -_Box.y || abs(pos.z) > -_Box.z)
                //    discard;
                return retColor;
            }
            ENDCG
        }
    }
}
