Shader "Hidden/OutlineImgEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        BoundsMin ("Bounds Min", Vector) = (0,0,0)
        BoundsMax ("Bounds Max", Vector) = (0,0,0)
        ShapeNoise ("Shape Noise", 3D) = "white" {}
        DetailNoise ("Detail Noise", 3D) = "white" {}
        

    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/Scenes/0_Study2/Volumetric Cloud/Assets/Scripts/Clouds/Shaders/CloudDebug.cginc"


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD1;

            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float3 BoundsMin;
            float3 BoundsMax;
            Texture3D<fixed4> ShapeNoise;
            Texture3D<fixed4> DetailNoise;

            SamplerState samplerShapeNoise;
            SamplerState samplerDetailNoise;
            float3 CloudOffset;
            float CloudScale;
            float DensityThreshold;
            float DensityMultiplier;
            int NumSteps;
            float sampleDensity(float3 position) {
                float3 uvw = position * CloudScale * 0.001 + CloudOffset * 0.01;
                fixed4 shape = ShapeNoise.SampleLevel(samplerShapeNoise, uvw, 0);
                float density = max(0, shape.r - DensityThreshold) * DensityMultiplier;
                return density;
            }

            float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDir) {
                float3 t0 = (boundsMin - rayOrigin) / rayDir;
                float3 t1 = (boundsMax - rayOrigin) / rayDir;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                
                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));


                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                return o;
            }

            

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                //fixed4 offsetCol = tex2D(_MainTex, i.uv - 0.002);
                //if (length(col - offsetCol) > 0.1)
                    //col = 0;
                
                float3 rayOrigin = _WorldSpaceCameraPos;
                //float3 rayDir = mul(unity_CameraInvProjection, fixed4(i.uv *2 -1, 0, -1));
                //rayDir = mul(_WorldSpaceCameraPos, fixed4(rayDir, 0));
                //rayDir = normalize(rayDir);
                float3 rayDir = normalize(i.viewVector);

                float nonLinearDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float depth = LinearEyeDepth(nonLinearDepth) * length(i.viewVector);

                float2 rayBoxInfo = rayBoxDst(BoundsMin, BoundsMax, rayOrigin, rayDir);
                float dstToBox = rayBoxInfo.x;
                float dstInsideBox = rayBoxInfo.y;

                float dstTravelled = 0;
                float stepSize = dstInsideBox / NumSteps;
                float dstLimit = min(depth - dstToBox, dstInsideBox);

                //March through volume
                float totalDensity = 0;
                while(dstTravelled < dstLimit) {
                    float3 rayPos = rayOrigin + rayDir * (dstToBox + dstTravelled);
                    totalDensity += sampleDensity(rayPos) * stepSize;
                    dstTravelled += stepSize;
                }

                float transmittance = exp(-totalDensity);
                return col * transmittance;



                bool rayHitBox = dstInsideBox > 0 && dstToBox < depth;
                if(rayHitBox)
                    col = 0;
                return col;
            }
            ENDCG
        }
    }
}
