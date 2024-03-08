Shader "Unlit/SDFVolume"
{
    Properties
    {
        _isVR("is VR", Float) = 0
        _ModSize("Mod Size", Vector) = (0,0,0,0)
        _BooleanScale("Boolean Scale", Float) = 1

        
        _MainTex3D ("Volume Texture", 3D) = "white" {}
        _VolumeMin ("Volume Min", Float) = 0
        _VolumeCenterInBox("Volume Center In Box", Vector) = (-0.5,-0.5,-0.5,0)
        _VolumeDensityStep ("Volume Density Step", Float) = 0.1
        _VolumeDensityMaxDist ("Volume Density Max Distance", Float) = 100
        _VolumePos ("Volume Position", Vector) = (0,0,0,0)
        _VolumeSize ("Volume Size", Vector) = (0,0,0,0)
        [space(10)]
        _Noise3D ("Noise 3D Texture", 3D) = "white" {}
        _NoiseDensityStep ("Noise Density Step", Float) = 0.1
        _BGNoiseDensityStep ("BG Noise Density Step", Float) = 0.1
        _NoiseScale ("Noise Scale", Float) = 1
        _BGNoiseScale ("BGNoise Scale", Float) = 1
        _NoiseOffset ("Noise Offset", Vector) = (0,0,0,0)
        _NoiseSpeed ("Noise Speed", Vector) = (0,0,0,0)

        _BoxSize ("Box Size", Vector) = (0,0,0,0)
        _BoxPos ("Box Position", Vector) = (0,0,0,0)

        [space(10)]
        _MainColor("Main Color", Color) = (1,1,1,1)
        _OpacityFactor("Opacity Factor", Float) = 1
        _OpacityLimit("Opacity Limit", Float) = 0.1
        [HDR]_EdgeColor("Edge Color", Color) = (0,0,0)
        _EdgeAlpha("Edge Alpha", Float) = 1
        _LightCol("Light Color", Color) = (1,1,1,1)
        _LightIntensity("Light Intensity", Float) = 1
        
        _ShadowIntensity("Shadow Intensity", Float) = 0.5
        //shadow distance: x is minimum distance, y  is max distance
        _ShadowDistance("Shadow Distance", Vector) = (0,0,0,0)

        _ObjLightPosition1("Object Light Position 1", Vector) = (0,0,0,0)
        _ObjLightIntensity1("Object Light Intensity 1", Float) = 1
        _ObjLightRange1("Ob1ject Light Range 1", Float) = 0
        [HDR]_ObjLightColor1("Object Light Color 1", Color) = (1,1,1)

        _ObjLightPosition2("Object Light Position 2", Vector) = (0,0,0,0)
        _ObjLightIntensity2("Object Light Intensity 2", Float) = 1
        _ObjLightRange2("Object Light Range 2", Float) = 0
        [HDR]_ObjLightColor2("Object Light Color 2", Color) = (1,1,1)

        _ObjLightPosition3("Object Light Position 3", Vector) = (0,0,0,0)
        _ObjLightIntensity3("Object Light Intensity 3", Float) = 1
        _ObjLightRange3("Object Light Range 3", Float) = 0
        [HDR]_ObjLightColor3("Object Light Color 3", Color) = (1,1,1)


    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        //ZWrite Off
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
            #include "DistanceFunctions.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 worldPos : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_FOG_COORDS(1)
            };

            fixed4 _MainColor, _LightCol, _EdgeColor;
            float _isVR;
            float _BooleanScale;
            float _VolumeMin;
            float _OpacityLimit;
            float _ShadowIntensity;
            float4 _ShadowDistance;
            float _LightIntensity, _OpacityFactor;
            float4 _ModSize;
            sampler3D _MainTex3D;
            float4 _VolumeCenterInBox;
            float _VolumeDensityStep, _VolumeDensityMaxDist;
            sampler3D _Noise3D;
            float _NoiseScale, _NoiseDensityStep, _BGNoiseDensityStep, _BGNoiseScale;
            float4 _NoiseOffset, _NoiseSpeed;
            float4 _BoxSize, _BoxPos, _VolumePos, _VolumeSize;
            float _EdgeAlpha;
            float4 _ObjLightPosition1;
            float _ObjLightIntensity1, _ObjLightRange1;
            fixed4 _ObjLightColor1;
            float4 _ObjLightPosition2;
            float _ObjLightIntensity2, _ObjLightRange2;
            fixed4 _ObjLightColor2;
            float4 _ObjLightPosition3;
            float _ObjLightIntensity3, _ObjLightRange3;
            fixed4 _ObjLightColor3;


            float getDensity(float3 pos) {
                float3 localPos = mul(unity_ObjectToWorld, float4(_VolumeCenterInBox.x,_VolumeCenterInBox.y,_VolumeCenterInBox.z,1)).xyz;
                float3 texCoord = (pos - localPos - _VolumePos) / _VolumeSize.xyz;
                if(texCoord.x < 0 || texCoord.x > 1 || texCoord.y < 0 || texCoord.y > 1 || texCoord.z < 0 || texCoord.z > 1)
                    return 1;
                return tex3D(_MainTex3D, texCoord);
            }

            float getNoise(float3 pos, float scale) {
                float distance = (pos.x - _BGNoiseScale) / 100;
                float3 dist = float3(distance,distance,distance);
                float3 texCoord = (pos - _NoiseOffset.xyz) / scale + _NoiseSpeed.xyz * _Time.y;
                //texCoord.x /= _BGNoiseScale;
                return tex3D(_Noise3D, texCoord);
            }

            float DE(float3 pos) {
                float3 localPos = mul(unity_ObjectToWorld, float4(_VolumeCenterInBox.x,_VolumeCenterInBox.y,_VolumeCenterInBox.z,1)).xyz;
                float d = sdBox(pos - _BoxPos.xyz - localPos, _BoxSize.xyz);
                return d;
            }

            float DEVol(float3 pos) {
                float3 c = pos;
                if(_ModSize.w > 0) {
                    pMod1(c.x, _ModSize.x);
                    pMod1(c.y, _ModSize.y);
                    pMod1(c.z, _ModSize.z);
                }
                float d1 = getDensity(c) * _VolumeDensityStep;
                if(d1 < _VolumeMin) d1 = 1000;
                float d2 = getNoise(c, _NoiseScale) * _NoiseDensityStep;
                float d = d1 - d2;
                //return d;
                float d3 = opI(DE(c), getNoise(c, _BGNoiseScale) * _BGNoiseDensityStep);
                return opSS(d3, d, _BooleanScale);
            }

            float Raymarch(float3 ro, float3 rd) {
                float t = 0;
                [unroll(50)]
                for(int i = 0; i < 50; i++) {
                    float3 pos = ro + rd * t;
                    float d = DE(pos);
                    t += d;
                    if(d < 0.001 || t > 100) break;
                }
                return t;
            }

            float RaymarchDensity(float3 ro, float3 rd) {
                float t = 0;
                [unroll(50)]
                for(int i = 0; i<50; i++) {
                    float3 pos = ro + rd * t;
                    float d = DEVol(pos);
                    t += d;
                    if(d < 0.0001 || t > _VolumeDensityMaxDist) break;
                }
                return t;
            }

            float3 GetNormal(float3 p) {
                float2 e = float2(0.01, 0);
                //float3 n = DE(p) - float3(DE(p-e.xyy), DE(p-e.yxy), DE(p-e.yyx));
                float3 n = float3(
                    DEVol(p + e.xyy) - DEVol(p - e.xyy),
                    DEVol(p + e.yxy) - DEVol(p - e.yxy),
                    DEVol(p + e.yyx) - DEVol(p - e.yyx));
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

            float3 Shading(float3 p, float3 lightsrc)
            {
                float3 shadow = hardShadow(p, lightsrc, _ShadowDistance.x, _ShadowDistance.y) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _ShadowIntensity));
                return shadow;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = _MainColor;
                float3 ro = i.worldPos;
                float3 rd = normalize(ro - _WorldSpaceCameraPos);
                float d = RaymarchDensity(ro, rd);
                float3 pos = ro + rd * d;
                float3 normal = GetNormal(pos);
                float3 shadow;
                fixed4 edge = _EdgeColor;

                if(d > _VolumeDensityMaxDist) discard; 
                    //return fixed4(0,0,0,0.8);
                //if(d >= .9) col *= fixed4(0.1*d, 0.1*d, 0.1*d, 0.1*d);
                col /= d;
                if(_isVR < 1) {
                    col.a *= _OpacityFactor;
                }
                if(_isVR >= 1) {
                    float3 lightSource = _WorldSpaceLightPos0;
                    float lightInt = _LightIntensity;
                    float3 result = (_LightCol * dot(lightSource, normal) *0.5 + 0.5) * lightInt;
                    shadow = Shading(pos, lightSource);
                    result *= shadow;
                    col.rgb *= result;
                    col.a *= abs(length(result)) * _OpacityFactor;
                    col.a *= _OpacityFactor;
                    if (col.a > _OpacityLimit) {
                        col.a += _EdgeAlpha + (edge.r + edge.g + edge.b) ;
                        col.rgb += edge.rgb;
                    }
                    col.a /= length(shadow);

                    if(col.a > _MainColor.a)
                    {
                        if(length(shadow) < 0.5) {
                            col.a *= length(shadow);
                            col.rgb *= length(shadow);
                        }
                    }
                }

                float3 localPosLight = mul(unity_ObjectToWorld, float4(_ObjLightPosition1.x,_ObjLightPosition1.y,_ObjLightPosition1.z,1)).xyz;
                float distToLight = length(pos - localPosLight.xyz);
                if (_ObjLightRange1 > distToLight) {
                    col.rgb += _ObjLightColor1.rgb * _ObjLightIntensity1 * (1- distToLight/  _ObjLightRange1);
                }

                localPosLight = mul(unity_ObjectToWorld, float4(_ObjLightPosition2.x,_ObjLightPosition2.y,_ObjLightPosition2.z,1)).xyz;
                distToLight = length(pos - localPosLight.xyz);
                if (_ObjLightRange2 > distToLight) {
                    col.rgb += _ObjLightColor2.rgb * _ObjLightIntensity2 * (1- distToLight/  _ObjLightRange2);
                }

                localPosLight = mul(unity_ObjectToWorld, float4(_ObjLightPosition3.x,_ObjLightPosition3.y,_ObjLightPosition3.z,1)).xyz;
                distToLight = length(pos - localPosLight.xyz);
                if (_ObjLightRange3 > distToLight) {
                    col.rgb += _ObjLightColor3.rgb * _ObjLightIntensity3 * (1- distToLight/  _ObjLightRange3);
                }
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
