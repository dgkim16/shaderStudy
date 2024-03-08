Shader "Unlit/USB_simple_color"
{
    Properties
    {
        //PropertyName ("display name", type) = defaultValue.
        
        _Specular("Specular", Range(0.0,1.1)) = 0.3
        _Factor ("Color Factor", Float) = 0.3
        _Cid ("Color id", Int) = 2

        _Color("Tint", Color) = (1,1,1,1)
        _VPos("Vertex Position", Vector) = (0,0,0,1)

        _MainTex ("Texture", 2D) = "white" {}
        _Reflection("Reflection", Cube) = "black" {}    //cubemap
        _3DTexture ("3D Texture", 3D) = "white" {}  //3d: volumetric, have additional coordinates for spatial calculation

        // [drawers]
        // another type of property of Shaderlab
        // facilitates programming of conditionals
        // allow dynamic effects without changing material at execution time
        // use together with the two shader variants:
        // #pragma multi_compile
        // #pragma shader_feature

        // Toggle       boolean type not usable in Shaderlab. 0 Off, 1 On
        // must use     #pragma shader_feature
        [Toggle] _Enable("Enable?", Float) = 0


        // Enum         "Drawer" that can define a "value/id" as argument, then pass property to shader
        //              allows functionality to change dynamically from inspector
        // [Enum(valor, id_00, vlaor, id_01, etc...)] _PropertyName ("Display Name", Float) = 0
        // DOes not use shader variants, but declared by command / function
        [Enum(Iff, 0, Front, 1, Back, 2)] _Face ("Face Culling", Float) = 0


        // KeywordEnum      "Drawer"
        //                  use with variant shader "multi_complie" and "shader_feature"
        //                  allowing transition from one state to another in runtime
        // [KeywordEnum(Default State<or state off>, State01, etc...)] _PropertyName ("Display Name", Float) = 0
        [KeywordEnum(Off, Red, Blue)] _Options ("Color Options", Float) = 0

        // PowerSlider
        [PowerSlider(3.0)] _Brightness ("Brightness", Range(0.01, 1.0)) = 0.08

        // IntRange
        [IntRange] _Samples ("Samples", Range(0, 255)) = 100

        // Header
        // Space
        [Header(Specular properties)]
        _Specularity2 ("Speculatrity", Range (0.01, 1)) = 0.08
        _Brightness2 ("Brightness", Range (0.01, 1)) = 0.08
        _SpecularColor2 ("Specular Color", Color) = (1, 1, 1 , 1)
        [Space(20)]
        [Header(Texture properties)]
        _MainTex2 ("Texture", 2D) = "white" {}
        


    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        // Cull [_Face]
        Pass
        {
            CGPROGRAM   //this indicates that until ENDCG, the code is in Cg language
            #pragma shader_feature _ENABLE_ON
            #pragma multi_compile _OPTIONS_OFF _OPTIONS RED _OPTIONS BLUE
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
            };

            // these are CONNECTION VARIABLES
            // they are declared globally using "uniform"l but program recog them as global var, so skippable
            // must be the same name as properties from ShaderLab
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float _Brightness;
            int _Samples;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                //#if _ENABLE_ON
                //    return col;
                //#else
                //    return col * _Color;
                //#endif

                #if _OPTIONS_OFF
                    return col;
                #elif _OPTIONS_RED
                    return col * float4(1,0,0,1);
                #elif _OPTIONS_BLUE
                    return col * float4(0,0,1,1);
                #endif
            }
            ENDCG
        }
    }
}
