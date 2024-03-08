Shader "Unlit/ShadowMapOptimization"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ShadowTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
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
        Pass
        {
            Name "Shadow Map Texture"
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM

            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma vertex vert
            #pragma fragment frag
            // SHADOW_COORDS
            // TRANSFER_SHADOW
            // SHADOW_ATTENUATION

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                SHADOW_COORDS(1)
                float4 pos : SV_POSITION;
            };

            sampler2D _ShadowTex;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _ShadowTex_ST;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                // calculate UV coord for shadow texture [TRANSFER_SHADOW(o)]
                TRANSFER_SHADOW(o)  // transfer shader uv coordinates to fragment shader. Same operation as NDCtoUV
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_ShadowTex, i.uv);
                fixed4 col2 = tex2D(_MainTex, i.uv);
                float shadow = SHADOW_ATTENUATION(i);
                //return shadow;
                if(shadow < 1) 
                {
                    col.rgb *= saturate((2-shadow)) * _Color.rgb;
                    //col.rgb = 1-shadow;
                }
                if(shadow >= 1)
                {
                    return col2.rgba;
                }
                
                //col = saturate(col);
                return col;
            }


            ENDCG
        }
    }
}
