Shader "Unlit/NewUnlitShader"
{
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _CloudNoise1 ("Cloud Noise1", 2D) = "white" {}
        _CloudNoise2 ("Cloud Noise2", 2D) = "white" {}
        _CloudColor ("Cloud Color", Color) = (1, 1, 1, 1)
        _Density ("Density", Range(0, 1)) = 0.5
        _Threshold ("Threshold", Range(0, 1)) = 0.5
        _BoxSize ("Box Size", Vector) = (1,1,1,1)
        _Marcher ("Marcher", Float) = 10
        _Scale1 ("Noise1 Size", Vector) = (1,1,1,1) 
        _Scale2 ("Noise2 Size", Vector) = (1,1,1,1) 
    }

    SubShader {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _CloudNoise1, _CloudNoise2;
            float4 _CloudColor, _BoxSize, _Scale1, _Scale2;
            float _Density, _Threshold, _Marcher;

            float sdBox(float3 p, float3 b)
            {
                float3 d = abs(p) - b;
                return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
            }

            float Raymarch (float3 ro, float3 rd) {
                float3 pos = ro;
                for(int i1 = 0; i1 < 10; i1++) {
                    float d1 = sdBox(pos, _BoxSize.xyz);
                    if(d1 < 0.0001) break;
                    if(d1 > 50) return 100;
                    pos += rd * d1;
                }
                //go far first
                float3 endPos = pos + rd * 20;
                for(int i2 = 0; i2 < 20; i2++) {
                    float d = sdBox(endPos, _BoxSize.xyz);
                    if(d < 0.0001) break;
                    if(d > 50) return 100;
                    endPos -= rd * d;
                }
                float dist = length(endPos - pos);
                float sumDensity = 0;
                for (int i = 0; i < 100; i++) {
                    if(sumDensity > 2) break;
                    float cosAngle = cos(i*0.01+ _Time.y * 0.1) ;
                    float sinAngle = sin(i*0.01+ _Time.y * 0.1);
                    float2 rotuv = float2(pos.x * cosAngle - pos.y * sinAngle, pos.x * sinAngle + pos.y * cosAngle);
                    float2 Scale1 = float2(pos.x/_Scale1.x, pos.y/_Scale1.y);
                    float2 Scale2 = float2(pos.x/_Scale2.x + _Time.y * 0.1, pos.y/_Scale2.y);
                    float density = ((tex2D(_CloudNoise1, (Scale1.xy+.5)).r * i/100) + (tex2D(_CloudNoise2, (Scale2+.5)) * (10-i) / 100)) / 2;
                    if(i<50)
                        sumDensity += density * i/50;
                    else 
                        sumDensity += density * (100-i)/50;
                    pos = ro + dist * i/_Marcher * rd;
                }
                return sumDensity;
            }

            float RaymarchBox (float3 ro, float3 rd) {
                float3 pos = ro;
                float dist = 0;
                for(int i4 = 0; i4 < 50; i4++) {
                    float d = sdBox(pos, _BoxSize.xyz);
                    pos += rd * d;
                    dist += d;
                    if (d < 0.0001) {
                        break;
                    }
                }
                return dist;
            }

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                // Sample the texture to get the base color

                
                
                float3 worldPos = i.worldPos;
                float3 pos = worldPos;
                float3 dir = normalize(pos - _WorldSpaceCameraPos);
                if(_BoxSize.w == 1) {
                    float dist = RaymarchBox(pos, dir);
                    if (dist < 20)
                        return float4(1,1,1,1);
                    else discard;
                }


                float4 col = tex2D(_MainTex, i.uv*10);
                float noiseDensity = Raymarch(pos, dir);
                if(noiseDensity == 100) discard;
                float4 result;
                float cloudDensity;
                if(noiseDensity > 1.5) {
                    noiseDensity *= 0.9;
                    cloudDensity = noiseDensity * _Density;
                    result = _CloudColor / cloudDensity;
                }
                else {
                    cloudDensity = noiseDensity * _Density;
                    result = _CloudColor * cloudDensity;
                    if (cloudDensity < _Threshold)
                        cloudDensity = 0;
                }
                result.a = cloudDensity;
                
                // Apply fog
                UNITY_APPLY_FOG(i.fogCoord, result);

                if(_BoxSize.w == 2) {
                    float dist = RaymarchBox(pos, dir);
                    if (dist < 20)
                        result += float4(1,0,0,0.5);
                }

                return result;
            }
            ENDCG
        }
    }
}
