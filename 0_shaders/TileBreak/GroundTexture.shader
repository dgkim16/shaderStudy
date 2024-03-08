// Made with Amplify Shader Editor v1.9.1.3
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GroundTexture"
{
	Properties
	{
		_Tiling("Tiling", Range( 0 , 20)) = 0
		_Base("Base", 2D) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"

			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D _Base;
			uniform float _Tiling;
			void StochasticTiling( float2 UV, out float2 UV1, out float2 UV2, out float2 UV3, out float W1, out float W2, out float W3 )
			{
				float2 vertex1, vertex2, vertex3;
				// Scaling of the input
				float2 uv = UV * 3.464; // 2 * sqrt (3)
				// Skew input space into simplex triangle grid
				const float2x2 gridToSkewedGrid = float2x2( 1.0, 0.0, -0.57735027, 1.15470054 );
				float2 skewedCoord = mul( gridToSkewedGrid, uv );
				// Compute local triangle vertex IDs and local barycentric coordinates
				int2 baseId = int2( floor( skewedCoord ) );
				float3 temp = float3( frac( skewedCoord ), 0 );
				temp.z = 1.0 - temp.x - temp.y;
				if ( temp.z > 0.0 )
				{
					W1 = temp.z;
					W2 = temp.y;
					W3 = temp.x;
					vertex1 = baseId;
					vertex2 = baseId + int2( 0, 1 );
					vertex3 = baseId + int2( 1, 0 );
				}
				else
				{
					W1 = -temp.z;
					W2 = 1.0 - temp.y;
					W3 = 1.0 - temp.x;
					vertex1 = baseId + int2( 1, 1 );
					vertex2 = baseId + int2( 1, 0 );
					vertex3 = baseId + int2( 0, 1 );
				}
				UV1 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex1 ) ) * 43758.5453 );
				UV2 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex2 ) ) * 43758.5453 );
				UV3 = UV + frac( sin( mul( float2x2( 127.1, 311.7, 269.5, 183.3 ), vertex3 ) ) * 43758.5453 );
				return;
			}
			

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float localStochasticTiling2_g3 = ( 0.0 );
				float2 temp_cast_0 = (_Tiling).xx;
				float2 texCoord50 = i.ase_texcoord1.xy * temp_cast_0 + float2( 0,0 );
				float2 Input_UV145_g3 = texCoord50;
				float2 UV2_g3 = Input_UV145_g3;
				float2 UV12_g3 = float2( 0,0 );
				float2 UV22_g3 = float2( 0,0 );
				float2 UV32_g3 = float2( 0,0 );
				float W12_g3 = 0.0;
				float W22_g3 = 0.0;
				float W32_g3 = 0.0;
				StochasticTiling( UV2_g3 , UV12_g3 , UV22_g3 , UV32_g3 , W12_g3 , W22_g3 , W32_g3 );
				float2 temp_output_10_0_g3 = ddx( Input_UV145_g3 );
				float2 temp_output_12_0_g3 = ddy( Input_UV145_g3 );
				float4 Output_2D293_g3 = ( ( tex2D( _Base, UV12_g3, temp_output_10_0_g3, temp_output_12_0_g3 ) * W12_g3 ) + ( tex2D( _Base, UV22_g3, temp_output_10_0_g3, temp_output_12_0_g3 ) * W22_g3 ) + ( tex2D( _Base, UV32_g3, temp_output_10_0_g3, temp_output_12_0_g3 ) * W32_g3 ) );
				
				
				finalColor = Output_2D293_g3;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	Fallback Off
}
/*ASEBEGIN
Version=19103
Node;AmplifyShaderEditor.FunctionNode;46;-522.5776,-91.1795;Inherit;True;Procedural Sample;-1;;3;f5379ff72769e2b4495e5ce2f004d8d4;2,157,0,315,0;7;82;SAMPLER2D;0;False;158;SAMPLER2DARRAY;0;False;183;FLOAT;0;False;5;FLOAT2;0,0;False;80;FLOAT3;0,0,0;False;104;FLOAT2;1,1;False;74;SAMPLERSTATE;0;False;5;COLOR;0;FLOAT;32;FLOAT;33;FLOAT;34;FLOAT;35
Node;AmplifyShaderEditor.TextureCoordinatesNode;50;-969.6194,53.70435;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;51;-1433.619,-12.29565;Inherit;False;Property;_Tiling;Tiling;2;0;Create;True;0;0;0;False;0;False;0;20;0;20;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;59;-691.9402,911.0661;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DistanceOpNode;56;-513.1349,1015.794;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;65;-330.9402,938.0661;Inherit;False;dist;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;66;-722.9402,1346.066;Inherit;False;65;dist;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;68;-367.9402,1385.066;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;69;-662.9402,1466.066;Inherit;False;Property;_MaxTessDistance;MaxTessDistance;1;0;Create;True;0;0;0;False;0;False;0;10;10;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;67;-542.9402,1355.066;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;70;-364.9402,1263.066;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;64;-230.9403,1272.066;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.01;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;63;-70.94029,1179.066;Inherit;False;Property;_TessFactor;TessFactor;0;0;Create;True;0;0;0;False;0;False;0;6.36;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;-88.948,1013.556;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;73;-882.7488,514.9221;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;-500.7488,504.9221;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;78;-729.7488,591.9221;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;79;-870.7488,712.9221;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;80;-1298.749,813.9221;Inherit;True;Property;_SnowNoise;SnowNoise;6;0;Create;True;0;0;0;False;0;False;-1;None;65bcede0b8d983c469751cc197d6ac18;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;82;-519.9488,626.4221;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;83;-528.8416,719.9971;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;84;-678.8416,734.9971;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-903.7488,607.9221;Inherit;False;Property;_SnowHeight;SnowHeight;3;0;Create;True;0;0;0;False;0;False;0;120.21;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;85;-874.8416,821.9971;Inherit;False;Property;_SnowPathStrength;SnowPathStrength;7;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;77;-1102.749,713.9221;Inherit;False;Property;_NoiseWeight;NoiseWeight;4;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;72;-1138.749,569.9221;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;86;-855.8416,395.997;Inherit;False;Property;_DEBUG;DEBUG;8;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;55;-948.1349,1131.795;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ObjectToWorldMatrixNode;61;-921.9402,904.0661;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.PosVertexDataNode;57;-689.1349,1385.794;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;87;189,88;Float;False;True;-1;2;ASEMaterialInspector;100;5;GroundTexture;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;RenderType=Opaque=RenderType;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
Node;AmplifyShaderEditor.TexturePropertyNode;48;-900.9459,-205.7657;Inherit;True;Property;_Base;Base;5;0;Create;True;0;0;0;False;0;False;None;b39336e67b68db14aa4a8a7f883e5aff;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
WireConnection;46;82;48;0
WireConnection;46;5;50;0
WireConnection;50;0;51;0
WireConnection;59;0;61;0
WireConnection;59;1;57;0
WireConnection;56;0;59;0
WireConnection;56;1;55;0
WireConnection;65;0;56;0
WireConnection;68;0;67;0
WireConnection;68;1;69;0
WireConnection;67;0;66;0
WireConnection;70;1;68;0
WireConnection;64;0;70;0
WireConnection;62;0;64;0
WireConnection;62;1;63;0
WireConnection;73;0;72;0
WireConnection;74;0;73;0
WireConnection;74;1;78;0
WireConnection;74;2;82;0
WireConnection;78;0;75;0
WireConnection;78;1;79;0
WireConnection;79;0;77;0
WireConnection;79;1;80;1
WireConnection;82;0;83;0
WireConnection;83;1;84;0
WireConnection;84;0;86;0
WireConnection;84;1;85;0
WireConnection;87;0;46;0
ASEEND*/
//CHKSM=D07D4950E10F49E536F33B973F649E15662276A0