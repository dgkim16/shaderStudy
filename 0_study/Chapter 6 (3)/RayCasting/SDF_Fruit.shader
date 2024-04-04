Shader "Unlit/SDF_Fruit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // plane texture
        _PlaneTex ("Plane Texture", 2D) = "white" {}
        // edge color projection
        _CircleCol ("Circle Color", Color) = (1,1,1,1)
        // edge radius projection
        _CircleRad ("Circle Radius", Range(0.0, 0.5)) = 0.45
        _Edge ("Edge", Range(-0.5, 0.5)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        LOD 100

        Pass
        {
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
                float3 hitPos : TEXCOORD1;      // define position of Mehs vertices & calculate spatial posiiton of plane
            };

            sampler2D _MainTex;
            sampler2D _PlaneTex;
            float4 _MainTex_ST;
            float4 _CircleCol;
            float _CircleRad;
            float _Edge;

            float planeSDF(float3 ray_position)
            {
                float plane = ray_position.y - _Edge; 
                //computing SDF for plane is useless
                //float plane = ray_position.y;
                return plane;
            }
            #define MAX_MARCHING_STEPS 50
            #define MAX_DISTANCE 10.0
            #define SURFACE_DISTANCE 0.001

            //ray_origin = camera position local space
            //ray_direction = position of mesh vertices
            //SDF plane position must equal the position of 3D object
            float sphereCasting(float3 ray_origin, float3 ray_direction)
            {
                float distance_origin = 0;
                for(int i = 0; i < MAX_MARCHING_STEPS; i++ )
                {
                    float3 ray_position = ray_origin + ray_direction * distance_origin;
                    float distance_scene = planeSDF(ray_position);
                    distance_origin += distance_scene;

                    if (distance_scene < SURFACE_DISTANCE || distance_origin > MAX_DISTANCE)
                    {
                        break;
                    }
                }
                return distance_origin;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.hitPos = v.vertex;
                return o;
            }

            fixed4 frag (v2f i, bool face : SV_isFrontFace) : SV_Target
            {
                if (i.hitPos.y > _Edge)
                    discard;
                fixed4 col = tex2D(_MainTex, i.uv);
                float4 col2 = float4(1,0,0,1);
                // rag_origin = camera position in local space (i.hitPos = 0,0,0 only for ray_origin)
                float3 ray_origin = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                float3 ray_direction = normalize(i.hitPos - ray_origin);
                float t = sphereCasting(ray_origin, ray_direction);
                // only using spherecasting for coloring the plane, and not for the actual raymarching
                float4 planeCol = 0;
                float4 circleCol = 0;
                if(t < MAX_DISTANCE)
                {
                    float3 p = ray_origin + ray_direction * t;
                    //p.xz = UV coordinates inside the maximum Sphere casting area
                    float2 uv_p = p.xz;
                    // maintain size when _Edge = 0; decrease when in range between 0.5f and -0.5f
                    float l = pow(-abs(_Edge), 2) + pow(-abs(_Edge) - 1, 2);
                    // generate a circle following the UV plane coordinates
                    float c = length(uv_p);
                    // apply the same scheme to the circle’s radius
                    // this way, you can modify its size
                    circleCol = (smoothstep(c - 0.01, c + 0.01, _CircleRad - abs(pow(_Edge * (l*0.5), 2))));
                    // planeCol = tex2D(_PlaneTex, uv_p - 0.5); Before adjusting plane texture to match size of circle
                    planeCol = tex2D(_PlaneTex, (uv_p*(1 + abs(pow(_Edge * l, 2)))) - 0.5);
                    // delete the texture borders
                    planeCol *= circleCol;
                    // add the circle and apply color
                    planeCol += (1 - circleCol) * _CircleCol;
                }
                return face ? col : planeCol;
            }
            ENDCG
        }
    }
}
