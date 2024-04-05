Shader "Unlit/RT_3D_Renderer3"
{
    Properties
    {
        _Debug ("Debug", Range(0,1)) = 1
        _DebugSphere ("DebugSphere", Vector) = (0,0,0,0)
        _BlendFactor ("BlendFactorShape", Range(0,1)) = 0.5
        _BlendFactorStoL ("BlendFactorShapeToLine", Range(0,1)) = 0.5
        _BlendFactorColor ("BlendFactorColor", Range(0,1)) = 0.5

        _LineSphere1 ("LineSphere1", Vector) = (0,0,0,0)
        _BlendFactorLine1 ("BlendFactor1", Range(0,1)) = 0.5
        _LineSphere2 ("LineSphere2", Vector) = (0,0,0,0)
        _BlendFactorLine2 ("BlendFactor2", Range(0,1)) = 0.5
        _LineSphere3 ("LineSphere3", Vector) = (0,0,0,0)
        _BlendFactorLine3 ("BlendFactor3", Range(0,1)) = 0.5
        _LineSphere4 ("LineSphere4", Vector) = (0,0,0,0)

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
        _LightIntensity("LightIntensity", Float) = 0.5
        _LightCol("LightCol", Color) = (1, 1, 1, 1)
        _EdgeColor("EdgeColor", Color) = (0, 0, 0, 0)
        _OpacityFactor("OpacityFactor", Range(0, 1)) = 1.0
        _OpacityLimit("OpacityLimit", Float) = 1.0


        _VectorTest ("Vector", Vector) = (0,0,0,0)
        //_Box ("Box", Vector) = (0,0,0,0)
        _rayDistFactor ("rayDistFactor", Float) = 0.1
        _Threshold("Threshold", Range(0,1)) = 0.99
        _CloudThreshold("CloudThreshold", Range(0,1)) = 0.01
        _MaxDist("MaxDist", Float) = 100.0
        _MaxIter("MaxIter", Int) = 100
        
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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal_world : TEXCOORD1;
                float4 vert : TEXCOORD2;
            };
            

            sampler3D _VolumeTex;
            sampler3D _NoiseTex;
            float4 _VectorTest;
            float4 _Box;
            float _rayDistFactor;
            float _Debug;
            fixed4 _Color, _OutlineColor;
            float _Threshold, _EnableOutline;
            float _CloudScale, _ColorScale, _OutlineWidth, _NoiseScale, _CloudThreshold, _OpacityFactor, _OpacityLimit;
            float4 _VolumeTexRatio, _DebugSphere;

            uniform float _LightIntensity;
            uniform float3 _LightCol;
            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity;
            float _MaxDist, _MaxIter, _BlendFactor;
            float4 _EdgeColor;
            float4 _LineSphere1, _LineSphere2, _LineSphere3, _LineSphere4;
            float _BlendFactorLine1, _BlendFactorLine2, _BlendFactorLine3, _BlendFactorStoL, _BlendFactorColor;


            v2f vert (appdata v)
            {
                v2f o;
                o.vert = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
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

            float opUS(float d1, float d2, float k)
            {
                float h = clamp(0.5+0.5*(d2-d1)/k, 0.0, 1.0);
                return lerp(d2, d1, h) - k*h*(1.0-h);
            }

            float DELines(float3 p, float3 worldPos, float mulFac)
            {
                float line1 = mulFac * clamp((length(p - _LineSphere1.xyz) - _LineSphere1.w) / (length(worldPos - _LineSphere1.xyz) - _LineSphere1.w), 0, 1);
                float line2 = mulFac * clamp((length(p - _LineSphere2.xyz) - _LineSphere2.w) / (length(worldPos - _LineSphere2.xyz) - _LineSphere2.w), 0, 1);
                //float line3 = mulFac * clamp((length(p - _LineSphere3.xyz) - _LineSphere3.w) / (length(worldPos - _LineSphere3.xyz) - _LineSphere3.w), 0, 1);
                //float line4 = mulFac * clamp((length(p - _LineSphere4.xyz) - _LineSphere4.w) / (length(worldPos - _LineSphere4.xyz) - _LineSphere4.w), 0, 1);
                float lineOp = opUS(line1, line2, _BlendFactorLine1);
                //lineOp = opUS(lineOp, line3, _BlendFactorLine2);
                //lineOp = opUS(lineOp, line4, _BlendFactorLine3);
                return lineOp;
            }

            float DE(float3 p, float3 worldPos)
            {
                //float d = getTex3D(p);
                float d = getTex3D(p);
                float d2 = (length(p - _DebugSphere.xyz) - _DebugSphere.w) / (length(worldPos - _DebugSphere.xyz) - _DebugSphere.w);
                return opUS(d,d2, _BlendFactor);
                //return opUS(oped, DELines(p, worldPos, 1.0), _BlendFactorStoL);
            }

            

            float3 GetNormal(float3 p, float3 worldPos) {
                float2 e = float2(0.01, 0);
                //float3 n = DE(p) - float3(DE(p-e.xyy), DE(p-e.yxy), DE(p-e.yyx));
                float3 n = float3(
                    DE(p + e.xyy, worldPos) - DE(p - e.xyy, worldPos),
                    DE(p + e.yxy, worldPos) - DE(p - e.yxy, worldPos),
                    DE(p + e.yyx, worldPos) - DE(p - e.yyx, worldPos));
                return normalize(n);
            }

            float hardShadow(float3 ro, float3 rd, float mint, float maxt, float3 worldPos)
            {
                [unroll(3)]
                for(float t = mint; t < maxt;)
                {
                    float h = DE(ro+rd*t, worldPos);
                    if(h < 0.001) return 0;
                    t += h;
                }
                return 1.0;
            }

            float3 Shading(float3 p, float3 n, float3 worldPos)
            {
                //Directional Light
                float3 result = (_LightCol * dot(_WorldSpaceLightPos0, n) *0.5 + 0.5) * _LightIntensity;
                float shadow = hardShadow(p, _WorldSpaceLightPos0, _ShadowDistance.x, _ShadowDistance.y, worldPos) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _ShadowIntensity));
                result *= shadow;
                return result;
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
                for(int i = 0; i < _MaxIter; i++)
                {
                    pos = worldPos + rd * factorDist;
                    float noise = pow(clamp((tex3D(_NoiseTex, (pos * _NoiseScale) + _VectorTest.xyz)), 0,1.0),2);
                    tex3dval =  clamp((tex3D(_VolumeTex, (pos * _CloudScale) * float3(_VolumeTexRatio.xyz) + _VectorTest.xyz) * (1-noise)),0,1.0);
                    float sphere1 = (1-noise) * clamp((length(pos - _DebugSphere.xyz) - _DebugSphere.w) / (length(worldPos - _DebugSphere.xyz) - _DebugSphere.w), 0.01, 1);
                    //float lineOp = DELines(pos, worldPos, (1-noise));
                    tex3dval = opUS(tex3dval, sphere1, _BlendFactor);
                    //tex3dval = opUS(tex3dval, lineOp, _BlendFactorStoL);
                    hardLine = (1-tex3dval);
                    //float sphere1 = 1 - (length(pos - _DebugSphere.xyz) - _DebugSphere.w) / (length(worldPos - _DebugSphere.xyz) - _DebugSphere.w);

                    if(hardLine > _Threshold - _CloudThreshold) {
                        //retColor = fixed4(_Color.rgb * abs(frac(factorDist)), 1);
                        float distanceToCenter = length(pos);
                        retColor.rgb = float3(_Color.rgb * ((sin(distanceToCenter * _ColorScale) * 0.8) + 0.8) / 0.8 + 0.1);
                        float3 normal = GetNormal(pos, worldPos);
                        //retColor.rgb *= normal;
                        float3 shadow = Shading(pos,  normal, worldPos);
                        //float3 nebulaColor = step(shadow, float3(0.5,0.5,0.5)) * shadow;
                        retColor.rgb *= shadow;
                        if(hardLine < _Threshold - _CloudThreshold * 0.5)
                            retColor.a += abs(length(shadow)) * _OpacityFactor;
                        if (retColor.a > _OpacityLimit)
                        {
                            retColor.a += _EdgeColor.a + _EdgeColor.r + _EdgeColor.g + _EdgeColor.b ;
                            return retColor;
                        }
                        if(hardLine >= _Threshold - _CloudThreshold * 0.5)
                            return retColor;
                        if (tex3dval < 0.01)
                            break;
                        //if(hardLine == _Threshold + _CloudThreshold)
                        //    discard;
                    }
                    if(outLine == 1 && hardLine > _Threshold - _CloudThreshold - _OutlineWidth) {
                        retColor.rgb = _OutlineColor.rgb;
                        outLine = 0;
                    }
                    factorDist += tex3dval * _rayDistFactor;
                    if(factorDist > _MaxDist)
                        discard;
                }
                //if(abs(pos.x) > _Box.x || abs(pos.y) > -_Box.y || abs(pos.z) > -_Box.z)
                //    discard;
                if(retColor.a < 0.01 || length(retColor.rgb) < 0.01)
                    discard;
                return retColor;
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}
