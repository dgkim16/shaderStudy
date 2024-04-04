Shader "Custom/Nebula" {
      Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Density ("Density", Range(0,1)) = 0.1
        _Brightness ("Brightness", Range(0,10)) = 1
        _Speed ("Speed", Range(0,1)) = 0.1
    }
 
    SubShader {
        Tags { "Queue"="Transparent" "RenderType"="Opaque" }
        LOD 100
 
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
 
            struct appdata {
                float4 vertex : POSITION;
            };
 
            struct v2f {
                float4 pos : SV_POSITION;
            };
 
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _Density;
            float _Brightness;
            float _Speed;
 
            v2f vert (appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }
 
            float noise(float3 x) {
                float3 p = floor(x);
                float3 f = fract(x);
                f = f * f * (3.0 - 2.0 * f);
 
                float n = p.x + p.y * 157.0 + 113.0 * p.z;
                return mix(mix(mix(dot(f, float3(1.0, 1.0, 1.0)),
                                   dot(f - float3(1.0, 0.0, 0.0), float3(1.0, 1.0, 1.0))),
                               mix(dot(f - float3(0.0, 1.0, 0.0), float3(1.0, 1.0, 1.0)),
                                   dot(f - float3(1.0, 1.0, 0.0), float3(1.0, 1.0, 1.0)))),
                           mix(mix(dot(f - float3(0.0, 0.0, 1.0), float3(1.0, 1.0, 1.0)),
                                   dot(f - float3(1.0, 0.0, 1.0), float3(1.0, 1.0, 1.0))),
                               mix(dot(f - float3(0.0, 1.0, 1.0), float3(1.0, 1.0, 1.0)),
                                   dot(f - float3(1.0, 1.0, 1.0), float3(1.0, 1.0, 1.0)))));
            }
 
            float sphereSDF(float3 p, float3 c, float r) {
                return length(p - c) - r;
            }
 
            float boxSDF(float3 p, float3 b) {
                float3 d = abs(p) - b;
                return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
            }
 
            float nebulaSDF(float3 p) {
                float density = 0
                            for (int i = 0; i < 4; i++) {
                float3 center = float3(0.5, 0.5, 0.5) + float3(cos(i * 0.25 * 6.2831), sin(i * 0.25 * 6.2831), 0) * _Speed * _Time.y;
                float sphere = sphereSDF(p, center, 0.1);
                density += _Density * noise(p * 3.0) * smoothstep(0.1, 0.3, sphere);
            }
            return boxSDF(p, float3(0.5)) - density;
        }

        void main () {
            float2 uv = (gl_FragCoord.xy / _ScreenParams.zw);
            float3 ray = normalize(mul(UNITY_MATRIX_I_V, float4(uv, 1.0, 1.0)).xyz);
            float3 eye = mul(UNITY_MATRIX_I_V, float4(0.0, 0.0, 0.0, 1.0)).xyz;

            float t = 0.0;
            float maxDist = 100.0;
            float stepSize = 0.01;
            float3 p = eye;
            for (int i = 0; i < 100; i++) {
                float d = nebulaSDF(p);
                t += d;
                if (d < 0.001 || t > maxDist) {
                    break;
                }
                p = eye + t * ray;
            }

            if (t < maxDist) {
                fixed4 color = texture2D(_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw);
                color.rgb = mix(color.rgb, _Color.rgb, 0.5);
                color.rgb *= _Brightness;
                gl_FragColor = color;
            }
            else {
                discard;
            }
        }
        ENDCG
    }
}
FallBack "Diffuse"

}