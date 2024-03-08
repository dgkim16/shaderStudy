// Made with Amplify Shader Editor v1.9.1.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TreeShader"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.81
		_EffectBlend("EffectBlend", Range( 0 , 1)) = 1
		_LeavesColor("LeavesColor", Color) = (0.2386044,0.5943396,0.2270826,1)
		_Smoothness("Smoothness", Float) = 0
		_FresnelCOlor("FresnelCOlor", Color) = (0.02358833,0.2830189,0,1)
		_BillboardSize("BillboardSize", Float) = 0
		_Inflate("Inflate", Float) = 0
		_NoiseScale("NoiseScale", Float) = 1.3
		_WindTime("WindTime", Float) = 0.1
		_Mask("Mask", 2D) = "white" {}
		_RotationScale("RotationScale", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout"  "Queue" = "AlphaTest+0" "IsEmissive" = "true"  }
		Cull Off
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#define ASE_USING_SAMPLING_MACROS 1
		#if defined(SHADER_API_D3D11) || defined(SHADER_API_XBOXONE) || defined(UNITY_COMPILER_HLSLCC) || defined(SHADER_API_PSSL) || (defined(SHADER_TARGET_SURFACE_ANALYSIS) && !defined(SHADER_TARGET_SURFACE_ANALYSIS_MOJOSHADER))//ASE Sampler Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex.Sample(samplerTex,coord)
		#else//ASE Sampling Macros
		#define SAMPLE_TEXTURE2D(tex,samplerTex,coord) tex2D(tex,coord)
		#endif//ASE Sampling Macros

		struct Input
		{
			float3 worldPos;
			float3 worldNormal;
			float2 uv_texcoord;
		};

		uniform float _WindTime;
		uniform float _NoiseScale;
		uniform float _BillboardSize;
		uniform float _Inflate;
		uniform float _EffectBlend;
		uniform float4 _LeavesColor;
		uniform float4 _FresnelCOlor;
		uniform float _Smoothness;
		UNITY_DECLARE_TEX2D_NOSAMPLER(_Mask);
		uniform float4 _Mask_ST;
		uniform float _RotationScale;
		SamplerState sampler_Mask;
		uniform float _Cutoff = 0.81;


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float2 appendResult81 = (float2(( v.texcoord.xy.x + ( ( _SinTime.w * 0.1 ) + 0.1 ) ) , v.texcoord.xy.y));
			float2 _Vector0 = float2(2,0);
			float temp_output_105_0 = ( ( _CosTime.w + _Vector0.x ) / 8.0 );
			float4 appendResult110 = (float4(( _Time.y * _WindTime ) , -0.49 , 0.0 , 0.0));
			float simplePerlin2D29 = snoise( ( appendResult110 + float4( v.texcoord.xy, 0.0 , 0.0 ) ).xy*_NoiseScale );
			simplePerlin2D29 = simplePerlin2D29*0.5 + 0.5;
			float2 appendResult102 = (float2(_Vector0.y , ( min( temp_output_105_0 , simplePerlin2D29 ) * max( simplePerlin2D29 , temp_output_105_0 ) )));
			float3 appendResult6 = (float3(( (float2( -1,-1 ) + (appendResult81 - float2( 0,0 )) * (float2( 1,1 ) - float2( -1,-1 )) / (float2( 1,1 ) - float2( 0,0 ))) + appendResult102 ) , 0.0));
			float3 normalizeResult9 = normalize( mul( float4( mul( float4( appendResult6 , 0.0 ), UNITY_MATRIX_V ).xyz , 0.0 ), unity_ObjectToWorld ).xyz );
			float3 ase_vertexNormal = v.normal.xyz;
			float3 lerpResult11 = lerp( float3( 0,0,0 ) , ( ( normalizeResult9 * _BillboardSize ) + ( ase_vertexNormal * _Inflate ) ) , _EffectBlend);
			v.vertex.xyz += lerpResult11;
			v.vertex.w = 1;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			o.Albedo = _LeavesColor.rgb;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = i.worldNormal;
			float fresnelNdotV16 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode16 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV16, 5.0 ) );
			float4 temp_output_18_0 = ( saturate( fresnelNode16 ) * _FresnelCOlor );
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			ase_vertexNormal = normalize( ase_vertexNormal );
			float3 objToWorldDir171 = mul( unity_ObjectToWorld, float4( mul( float4( ase_vertexNormal , 0.0 ), unity_ObjectToWorld ).xyz, 0 ) ).xyz;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult173 = dot( objToWorldDir171 , ase_worldlightDir );
			float4 ifLocalVar174 = 0;
			if( dotResult173 > 0.5 )
				ifLocalVar174 = ( temp_output_18_0 + 3.0 );
			o.Emission = ( temp_output_18_0 * ( ifLocalVar174 + 2.0 ) ).rgb;
			o.Smoothness = _Smoothness;
			o.Alpha = 1;
			float2 uv_Mask = i.uv_texcoord * _Mask_ST.xy + _Mask_ST.zw;
			float cos155 = cos( ( _SinTime.x * _RotationScale ) );
			float sin155 = sin( ( _SinTime.x * _RotationScale ) );
			float2 rotator155 = mul( uv_Mask - float2( 0.5,0.5 ) , float2x2( cos155 , -sin155 , sin155 , cos155 )) + float2( 0.5,0.5 );
			clip( SAMPLE_TEXTURE2D( _Mask, sampler_Mask, rotator155 ).r - _Cutoff );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows exclude_path:deferred vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=19103
Node;AmplifyShaderEditor.SaturateNode;17;-551.2871,-454.4373;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;10;-241.0367,-485.3752;Inherit;False;Property;_LeavesColor;LeavesColor;2;0;Create;True;0;0;0;False;0;False;0.2386044,0.5943396,0.2270826,1;0.5931529,0.8313726,0.2392157,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;19;-681.5871,-278.3374;Inherit;False;Property;_FresnelCOlor;FresnelCOlor;4;0;Create;True;0;0;0;False;0;False;0.02358833,0.2830189,0,1;0.38813,0.8784314,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ViewMatrixNode;4;-1194.431,280.3218;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.ObjectToWorldMatrixNode;7;-1251.735,385.1365;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;5;-1019.293,200.0584;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-1002.698,299.1731;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;9;-853.9979,256.028;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;21;-919.4263,420.9893;Inherit;False;Property;_BillboardSize;BillboardSize;5;0;Create;True;0;0;0;False;0;False;0;1.09;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-721.9425,334.6187;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;25;-571.974,328.2123;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;23;-707.1209,439.7657;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalVertexDataNode;22;-985.4121,505.1269;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;24;-774.5716,564.5038;Inherit;False;Property;_Inflate;Inflate;6;0;Create;True;0;0;0;False;0;False;0;0.24;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;16;-812.2872,-491.9281;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;6;-1124.076,52.39669;Inherit;False;FLOAT3;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-2184.321,-468.5502;Inherit;False;Constant;_Float2;Float 2;9;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;77;-2084.321,-400.5502;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;1;-2421.664,-211.799;Inherit;True;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;74;-2121.408,-212.5404;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;104;-1815.234,215.4546;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;99;-2003.234,367.4546;Inherit;False;Constant;_Vector0;Vector 0;9;0;Create;True;0;0;0;False;0;False;2,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;106;-1838.234,330.4546;Inherit;False;Constant;_Float0;Float 0;9;0;Create;True;0;0;0;False;0;False;8;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;-2011.721,-511.2501;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;78;-2250.321,-291.5502;Inherit;False;Constant;_Float3;Float 3;9;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;3;-1876.23,-76.17808;Inherit;True;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;-1,-1;False;4;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;101;-1469.513,-50.09843;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;111;-1608.39,-396.3697;Inherit;True;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;110;-1580.575,-574.4335;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SinTimeNode;28;-2251.219,-674.1844;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;123;-2111.559,-882.2797;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;115;-1743.104,-721.845;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;29;-1359.341,-374.8716;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosTime;95;-1973.253,186.4448;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;31;-1578.284,-143.9878;Inherit;False;Property;_NoiseScale;NoiseScale;7;0;Create;True;0;0;0;False;0;False;1.3;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;149;-2272.419,-829.8245;Inherit;False;Constant;_Float5;Float 5;9;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;105;-1664.687,202.9938;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;81;-2181.519,9.770348;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMinOpNode;151;-1445.934,174.8771;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;153;-1310.285,209.9554;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;152;-1451.943,281.3842;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;102;-1595.512,423.0889;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;109;-1812.428,-535.596;Inherit;False;Constant;_Float1;Float 1;9;0;Create;True;0;0;0;False;0;False;-0.49;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;148;-1917.911,-684.8052;Inherit;False;Property;_WindTime;WindTime;8;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;159;-1153.18,-207.0983;Inherit;True;Property;_Mask;Mask;9;0;Create;True;0;0;0;False;0;False;None;2dfd5d0bf54a3224e969bb84a5f187e7;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;14;-890.0929,-123.9253;Inherit;True;Property;_Vii_squareMaskInverted1;Vii_square Mask Inverted 1;3;0;Create;True;0;0;0;False;0;False;-1;2dfd5d0bf54a3224e969bb84a5f187e7;5f6d6227b115066459454e54096a0631;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;157;-932.1804,49.90167;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SinTimeNode;164;-709.4888,130.3532;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;160;-683.2803,2.90167;Inherit;False;Constant;_Vector1;Vector 1;10;0;Create;True;0;0;0;False;0;False;0.5,0.5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;18;-454.5872,-345.5373;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalVertexDataNode;168;-590.521,533.8129;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ObjectToWorldMatrixNode;169;-587.521,689.8129;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;170;-386.521,566.8129;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;747.6218,-122.8387;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;TreeShader;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;0;False;;0;False;;False;0;False;;0;False;;False;0;Masked;0.81;True;True;0;False;TransparentCutout;;AlphaTest;ForwardOnly;12;all;True;True;True;True;0;False;;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;2;15;10;25;False;0.5;True;0;0;False;;0;False;;0;0;False;;0;False;;0;False;;0;False;;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;0;-1;-1;-1;0;False;0;0;False;;-1;0;False;;0;0;0;False;0.1;False;;0;False;;True;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;179;450.6666,-91.69615;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;173;22.84261,188.2703;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;171;-269.6529,363.4257;Inherit;False;Object;World;False;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;12;-444.0067,250.9255;Inherit;False;Property;_EffectBlend;EffectBlend;1;0;Create;True;0;0;0;False;0;False;1;0.015;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;172;-188.1251,547.4902;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;175;-79.42348,-183.4209;Inherit;False;Constant;_Float4;Float 4;10;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;177;-245.9593,-37.5008;Inherit;False;Constant;_Float6;Float 6;10;0;Create;True;0;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ConditionalIfNode;174;96.94161,-156.4152;Inherit;False;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;180;148.579,44.08159;Inherit;False;Constant;_Float7;Float 7;10;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;181;286.817,-43.74718;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;176;-66.66072,-74.60019;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RotatorNode;155;-439.8491,-1.491605;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;183;-657.283,258.0222;Inherit;False;Property;_RotationScale;RotationScale;10;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;182;-553.283,129.0222;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;481.5634,107.809;Inherit;False;Property;_Smoothness;Smoothness;3;0;Create;True;0;0;0;False;0;False;0;1.79;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;11;299.6426,122.5186;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
WireConnection;17;0;16;0
WireConnection;5;0;6;0
WireConnection;5;1;4;0
WireConnection;8;0;5;0
WireConnection;8;1;7;0
WireConnection;9;0;8;0
WireConnection;20;0;9;0
WireConnection;20;1;21;0
WireConnection;25;0;20;0
WireConnection;25;1;23;0
WireConnection;23;0;22;0
WireConnection;23;1;24;0
WireConnection;6;0;101;0
WireConnection;77;0;75;0
WireConnection;77;1;78;0
WireConnection;74;0;1;1
WireConnection;74;1;77;0
WireConnection;104;0;95;4
WireConnection;104;1;99;1
WireConnection;75;0;28;4
WireConnection;75;1;76;0
WireConnection;3;0;81;0
WireConnection;101;0;3;0
WireConnection;101;1;102;0
WireConnection;111;0;110;0
WireConnection;111;1;1;0
WireConnection;110;0;115;0
WireConnection;110;1;109;0
WireConnection;115;0;123;0
WireConnection;115;1;148;0
WireConnection;29;0;111;0
WireConnection;29;1;31;0
WireConnection;105;0;104;0
WireConnection;105;1;106;0
WireConnection;81;0;74;0
WireConnection;81;1;1;2
WireConnection;151;0;105;0
WireConnection;151;1;29;0
WireConnection;153;0;151;0
WireConnection;153;1;152;0
WireConnection;152;0;29;0
WireConnection;152;1;105;0
WireConnection;102;0;99;2
WireConnection;102;1;153;0
WireConnection;14;0;159;0
WireConnection;14;1;155;0
WireConnection;157;2;159;0
WireConnection;18;0;17;0
WireConnection;18;1;19;0
WireConnection;170;0;168;0
WireConnection;170;1;169;0
WireConnection;0;0;10;0
WireConnection;0;2;179;0
WireConnection;0;4;15;0
WireConnection;0;10;14;1
WireConnection;0;11;11;0
WireConnection;0;14;11;0
WireConnection;179;0;18;0
WireConnection;179;1;181;0
WireConnection;173;0;171;0
WireConnection;173;1;172;0
WireConnection;171;0;170;0
WireConnection;174;0;173;0
WireConnection;174;1;175;0
WireConnection;174;2;176;0
WireConnection;181;0;174;0
WireConnection;181;1;180;0
WireConnection;176;0;18;0
WireConnection;176;1;177;0
WireConnection;155;0;157;0
WireConnection;155;1;160;0
WireConnection;155;2;182;0
WireConnection;182;0;164;1
WireConnection;182;1;183;0
WireConnection;11;1;25;0
WireConnection;11;2;12;0
ASEEND*/
//CHKSM=E0D6BC1DB69158A654E6BE923A32E34FFB1CF76E