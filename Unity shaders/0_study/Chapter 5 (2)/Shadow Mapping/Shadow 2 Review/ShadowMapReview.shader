Shader "Unlit/ShadowMapReview"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowMapT ("Shadow Map Texture", 2D) = "white" {}
        _Factor ("Far Clip", Float) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        // shadow caster pass
        Pass
        {
            Name "Shadow Caster"
            Tags
            {
                "RenderType"="Opaque"
                "LightMode"="ShadowCaster"
            }
            ZWrite On

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
                //float4 vertex : SV_POSITION;
            };

            v2f vert (appdata_full v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                //transforms vertex position coordinates to Clip-Space
                //calculates Normal Offset (so shadow can be included in Normal Maps)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
                // color output for shadow projection
            }

            ENDCG
        }

        // default color pass
        Pass
        {
            Name "Shadow Map Texture"
            Tags
            {
                "RenderType"="Opaque"
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                // declare UV coord for shadow map
                float4 shadowCoord : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ShadowMapT;
            // only exisits within the program, and should not be declared as a property in shader properties
            sampler2D _ShadowMapTexture;
            float _Factor;

            // UNITY_MATRIX_P defines the object vertex position in relation to the camera frustum
            // UnityObjectToClipPos( VRG )
            // Normalized Device Coordinates (NDC)      -1,1
            // clipPos = UnityObjectToClipPos( VRG )
            // [-1,1] to [0,1]
            // basically from ClipPos in your screen space to UV space of object
            float4 NDCToUV(float4 clipPos)
            {
                float4 o = clipPos * 0.5;
                // _ProjectionParams.x is 1.0 when OpenGL, -1 when DirectX
                // internal variable _ScreenParams.zw
                //    › Z equals 1.0f + 1.0f / width.
                //    › W equals 1.0f + 1.0f / height.
                #if defined(UNITY_HALF_TEXEL_OFFSET)
                    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w * _ScreenParams.zw;
                #else
                    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
                #endif
                o.zw = clipPos.zw;
                return o;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);               
                o.shadowCoord = NDCToUV(o.vertex); 
                //o.shadowCoord = MyNDCToUV(o.vertex); 
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 uv_shadow = i.shadowCoord.xy / i.shadowCoord.w;
                fixed shadow = tex2D(_ShadowMapTexture, uv_shadow).a;
                
                col.rgb *= shadow;
                return col;
            }
            ENDCG
        }
    
    
    }
}
