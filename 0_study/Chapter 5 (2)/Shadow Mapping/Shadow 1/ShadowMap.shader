Shader "Unlit/ShadowMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowColor ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        //shadow caster pass
        Pass
        {
            Name "Shadow Caster"
            Tags
            {
                "RenderType" = "Opaque"
                "LightMode" = "ShadowCaster"
            }
            ZWrite on
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_complie_shadowcaster
            #include "UnityCg.cginc"

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_full v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
                return 0;
            }
            ENDCG
        }
        //default color pass
        Pass
        {
            Name "Shadow Map Texture"
            Tags
            {
                "RenderType" = "Opaque"
                "LightMode" = "ForwardBase"
            }
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
                float4 shadowCoord : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ShadowMapTexture;
            fixed4 _ShadowColor;

            // transforms NDC (normalized device coordinates) to UV coordinates
            // clipPos = vertices positino Output (resulut of UnityObjectToClipPos)
            float4 NDCToUV (float4 clipPos)
            {
                float4 o = clipPos * 0.5;
                #if defined(UNITY_HALF_TEXEL_OFFSET)
                    o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w * _ScreenParams.zw;
                #else
                    o.xy = float2(o.x,o.y * _ProjectionParams.x) + o.w;
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
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 uv_shadow = i.shadowCoord.xy / i.shadowCoord.w;
                fixed shadow = tex2D(_ShadowMapTexture, i.shadowCoord).a;
                //fixed4 shad = tex2D(_ShadowMapTexture, i.shadowCoord);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //fixed4 shadowCol = (-shad + 1) * _ShadowColor + 2;
                //col.rgb *= shadowCol;
                //col.rgb /= 2;
                //return shadowCol;
                col.rgb *= shadow;
                return col;
            }
            ENDCG
        }
    }
}
