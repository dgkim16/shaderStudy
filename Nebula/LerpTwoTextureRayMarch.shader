Shader "Unlit/LerpTwoTextureRayMarch"
{
    Properties
    {
        _MainTex1 ("Texture", 2D) = "white" {}
        _MainTex2 ("Texture", 2D) = "white" {}
        _NoiseTex("Noise", 3D) = "white" {}
        _NoiseTexPos ("Noise Position", Vector) = (0,0,0,0)
        _VolumeSize ("Volume Size", Vector) = (1,1,1,1)
        _Debug ("Debug", Vector) = (0,0,0,0)
        _Radius ("Radius", Range(0,2)) = 0.5
        [HideInInspector] _StepSize ("Step size", Float) = 1
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex2;
            sampler2D _MainTex1;
            sampler3D _NoiseTex;
            float4 _MainTex_ST, _NoiseTexPos, _VolumeSize;
            float _Radius;
            float _StepSize;
            float4 _Debug;

            float noise(float3 pos) {
                return (tex3D(_NoiseTex, pos).r +1) * 0.5;
            }


            float Raymarch(float3 ro, float3 rd) {
                float t = 0;
                for(int i2 = 0; i2 < 100; i2++) {
                    float3 pos = ro + rd * t;
                    float d = length(pos) - _Radius;
                    t += d;
                    if(d < 0.001 || t > 100) break;
                }
                if(t>100) return 0;
                float3 startPos = ro + rd * t;

                float3 objCenter = mul(unity_ObjectToWorld, float4(0,0,0,0)).xyz;
                float3 centerDir = normalize(startPos - objCenter);
                float intersectDist = 2 * sin(acos(dot(centerDir, rd))) * _Radius;  // for sphere only
                float alpha = 0;
                float transparency = 1;
                float sigma_a = 0.5; // absorption coefficient
                float sigma_s = 0.5; // scattering coefficient
                float sigma_t = sigma_a + sigma_s; // extinction coefficient
                [loop]
                for(int i = 0; i < 20; i++) {
                    float3 pos = startPos + rd * intersectDist * i/20;
                    float3 localPos = mul(unity_ObjectToWorld, float4(_NoiseTexPos.xyz,1)).xyz;
                    float3 coord = (pos - localPos)/ _VolumeSize.xyz;
                    float density = 0;
                    if((coord.x > 1 || coord.x < 0 || coord.y > 1 || coord.y < 0 || coord.z > 1 || coord.z < 0) && i != 0)
                        break;
                    if(false) break;
                    float dist = min(_Debug.z, length(pos) / _Radius);
                    float falloff = smoothstep(_Debug.w, 1, dist);
                    density = max(0,noise(coord)) * (1-falloff);

                    float3 light_dir = normalize(_WorldSpaceLightPos0.xyz - pos);
                    float3 lightInPos = pos - light_dir * _Radius *2;
                    float t2 = 0;
                    for(int i3 = 0; i3 < 5; i++) {
                        lightInPos += light_dir * t;
                        t2 = length(lightInPos) - _Radius;
                        if(t2 < 0.001 || t2 > 100) break;
                    }
                    if(t2 > 100) break;
                    float isect_light_rayDist = length(lightInPos - pos);
                    float num_steps_light = ceil(isect_light_rayDist / _StepSize);
                    float stide_light = isect_light_rayDist / num_steps_light;
                    float tau = 0;
                    // [comment]
                    // Ray-march along the light ray. Store the density values in the tau variable.
                    // [/comment] float eval_density(const vec3& p)
                    [loop]
                    for (int nl = 0; nl < num_steps_light; ++nl) {
                        float t_light = stide_light * (nl + 0.5);
                        float3 light_sample_pos = pos + light_dir * t_light;
                        tau += max(0,noise(light_sample_pos)) * (1-falloff);
                    }
                    float light_ray_att = exp(-tau * stide_light * sigma_t);
                    //float density = lerp(tex2D(_MainTex1, localPos.xy -0.5).r, tex2D(_MainTex2, localPos.xy-0.5).r, i/ns);
                    float sample_attenuation = exp(-1/20 * density * sigma_t);
                    transparency *= sample_attenuation;
                    if(density > 0) {
                        alpha += density * transparency * sigma_s * light_ray_att * intersectDist/20;
                    }
                }
                return alpha;
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
                //float2 uv = i.uv;
                //float3 ro = i.worldPos.xyz;
                //float3 rd = normalize(ro - _WorldSpaceCameraPos);
                //float alpha = Raymarch(ro, rd);
                // sample the texture
                fixed4 col;
                float3 ro = i.worldPos.xyz;
                float3 rd = normalize(ro - _WorldSpaceCameraPos);
                float alpha = Raymarch(ro, rd);
                col.rgba = alpha;
                
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
