Shader "AY_Shader/Raymarch/CloudSea"
{
    Properties
    {
        _NoiseTex1 ("NoiseTex1", 2D) = "white" {}
        _NoiseTex2 ("NoiseTex2", 2D) = "white" {}
        _NoiseTex3D("NoiseTex3D", 3D) = "white" {}
        _NoiseIntensity("NoiseIntensity1", Range(0, 100)) = 25
        _NoiseScale("NoiseScale1", float) = 0.0015
        _NoiseIntensity2("NoiseIntensity2", Range(0, 100)) = 30
        _NoiseScale2("NoiseScale2", float) = 0.002
        _3DNoiseScale("3DNoiseScale", float) = 0.03
        _NoiseScroll("NoiseScroll1", Vector) = (2.0,0,0,0)
        _NoiseScroll2("NoiseScroll2", Vector) = (0.7,0,0,0)
        _3DNoiseScroll("3DNoiseScroll", Vector) = (0.1,0,0,0)

        [Space(10)]
        _Absorption("Absorption", Range(0, 1.0)) = 0.9
        _Opacity("Opacity", Range(0, 1.0)) = 0.9
        _CloudThreshold("CloudThreshold", Range(0.0,0.5)) = 0.1

        [Space(10)]
        _StepDist("StepDist", Range(0.01,10)) = 1.2
        _StepEnhanceRate("StepEnhanceRate", Range(1.0, 2.0)) = 1.02
        _lightStepDist("lightStepDist", Range(0.01,10)) = 3

        [Space(10)]
        [HDR]_BrightColor("BrightColor", Color) = (1.3, 1.3, 1.3, 1.0)
        [HDR]_ShadeColor("ShadeColor", Color) = (0.19, 0.63, 1.0, 1.0)

        [Space(10)]
        _MaxDensity("MaxDensity", Range(0.0,10.0)) = 1.0
        _CloudCenter("CloudCenter", float) = 0
        _CloudRange("CloudRange", float) = 35
        _rayStartOffset("rayStartOffset", Range(0,50)) = 12
        _ClipFar("ClipFar", Range(100,10000)) = 2000

        //[Space(10)]
        //[Toggle(VLOOP)] _VisualizeLoop("VisualizeLoop[ループ回数の視覚化]", int) = 0
    }
    SubShader
    {
        Tags {"Queue" = "Transparent-50" "RenderType" = "Transparent" "LightMode" = "ForwardBase"}
        LOD 100
        Cull Front
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha 

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //#pragma shader_feature VLOOP

            #include "UnityCG.cginc"

            fixed4 _LightColor0;

            sampler2D _NoiseTex1, _NoiseTex2;
            sampler3D _NoiseTex3D;
            fixed4 _BrightColor, _ShadeColor;
            float4 _NoiseScroll, _NoiseScroll2, _3DNoiseScroll;
            float _Absorption, _Opacity, _CloudThreshold, _StepDist, _StepEnhanceRate, _lightStepDist, _ShadeColorBar, _MaxDensity,
            _CloudCenter, _CloudRange, _rayStartOffset, _ClipFar,
            _NoiseIntensity, _NoiseIntensity2,
            _NoiseScale, _NoiseScale2, _3DNoiseScale,
            _CellularResolution, _CellularIntensity, _SimplexResolution, _SimplexIntensity;
            int _VisualizeLoop;

            static const int _Loop = 80;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float4 projPos : TEXCOORD2;
            };

            struct pout
            {
                fixed4 color : SV_Target;
                float depth : SV_Depth;
            };

            float hash(float n)
            {
                return frac(sin(n) * 43758.5453);
            }

            float getTex1(float3 p){
                //return step(tex2D(_NoiseTex1, (p.xz+_Time.y*_NoiseScroll.xy)*_NoiseScale) * _NoiseIntensity, 0.5);
                return tex2D(_NoiseTex1, (p.xz+_Time.y*_NoiseScroll.xy)*_NoiseScale) * _NoiseIntensity;
                
            }

            float getTex2(float3 p){
                //return step(tex2D(_NoiseTex2, (p.xz+_Time.y*_NoiseScroll2.xy)*_NoiseScale2) * _NoiseIntensity2, 0.5);
                return tex2D(_NoiseTex2, (p.xz+_Time.y*_NoiseScroll2.xy)*_NoiseScale2) * _NoiseIntensity2;
            }

            float getTex3D(float3 p){
                //return step(tex3D(_NoiseTex3D, frac(p * _3DNoiseScale + float3(_Time.y * _3DNoiseScroll.xyz))),0.5);
                return tex3D(_NoiseTex3D, frac(p * _3DNoiseScale + float3(_Time.y * _3DNoiseScroll.xyz)));
            }

            float densityFunction(float3 p)
            {   
                //return step((_CloudRange - abs(p.y - _CloudCenter) - getTex1(p) - getTex2(p)) * _MaxDensity * getTex3D(p) / _CloudRange, 0.5);
                return (_CloudRange - abs(p.y - _CloudCenter) - getTex1(p) - getTex2(p))
                * _MaxDensity * getTex3D(p)
                / _CloudRange;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.projPos = ComputeScreenPos(o.vertex);
                return o;
            }

            //深度テクスチャ
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            pout frag (v2f i)
            {
                //背面オブジェクトのdepthを取得
                float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
                float3 cameraViewDir = -UNITY_MATRIX_V._m20_m21_m22;                
                
                float3 worldPos = i.worldPos;
                float3 worldDir = normalize(worldPos - _WorldSpaceCameraPos);

                //カメラから背面オブジェクトへの距離
                //厳密に背面オブジェクトの距離にするより10.0m程度手前にしてしまった方がZfightのような現象が起きない
                //（Depthの精度の問題）
                float depthLength = length(sceneZ * worldDir *(1.0 / dot(cameraViewDir, worldDir)));
                depthLength -= 10.0;

                //レイマーチング関連の宣言
                float4 color = 0.0;
                float transmittance = 1.0;
                float total = 0;

                //カメラ位置（レイの開始位置）
                //①②の両立のため、レイマーチングはワールド座標系で行うがオブジェクト原点座標を引く
                //①オブジェクト座標変換するとキューブのscaleを変更した際に雲海のスケール比も変更されてしまう
                //②ワールド座標系そのままだと雲海を自由に配置できない
                float3 p = _WorldSpaceCameraPos - mul(unity_ObjectToWorld, float4(0,0,0,1));
                //p = mul(unity_WorldToObject,_WorldSpaceCameraPos);
                float3 sPos = p;
                float rayDist = _StepDist;

                //ライティング関連の宣言
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightRayDist = lightDir * _lightStepDist;
                float densityOnLightPos = 1.0;
                float lightPower = 0.0;

                //雲海の開始平面の外にカメラがある場合、レイのベクトルと雲海の開始平面の交点座標を計算しレイの開始点を交点座標で上書きする
                //_rayStartOffsetはその開始平面を調整するパラメータ。
                //複数のノイズテクスチャで雲を押し下げているため、開始平面もこれで調整することでループ数を抑えることができる
                float signY = sign(p.y);//p.yが上と下どちらにあるか
                float rayStartY = _CloudCenter + (_CloudRange - _rayStartOffset);
                if (abs(p.y) > rayStartY){
                    //雲海の開始平面外かつレイが雲海の逆方向を向いている場合はdiscard
                    if (worldDir.y * signY > 0) discard;

                    float3 n = float3(0, 1, 0);//鉛直方向ベクトル
                    float3 x = float3(0, rayStartY * signY, 0);//開始平面
                    float3 h = dot(n, x);
                    p += worldDir * ((h - dot(n, p)) / (dot(n, worldDir)));
                    total = distance(p, sPos);
                }

                //この時点で背面オブジェクトより遠い場合はdiscardできる
                if (depthLength <= total) discard;

                //水平距離でClip
                float total2 = distance(p.xz, sPos.xz);
                if (total2 > _ClipFar) discard;
                
                //開始位置を記録
                float sTotal = total;

                //ジッターをかけてアーティファクトを軽減
                float jit = rayDist * hash(worldPos.x + worldPos.y * 10 + worldPos.z * 100 + _Time.x);
                total += jit;

                //[loop]
                [unroll]
                for (int i = 0; i < _Loop; ++i)
                {
                    float density = densityFunction(p);
                    //雲の内側でのみ処理
                    if (density > _CloudThreshold)
                    {
                        float d = density * rayDist; //今回の1ステップで乗算すべき雲の濃さ
                        color.a +=  saturate(_Opacity * d * transmittance);//今回分の不透明度を加算
                        transmittance *= 1.0 - d * _Absorption;//今回のステップ領域を抜けて次に残るレイの強さ
                        if (transmittance < 0.01) break;//一定以下で終了

                        float3 lightPos = p;
                        float transmittanceLight = 1.0;

                        [unroll]
                        for (int k = 0; k < 3; k++)
                        {
                            float densityLight = densityFunction(lightPos);
                            if (densityLight > 0.0)
                            {
                                float dl = densityLight * _lightStepDist;
                                transmittanceLight *= 1.0 - dl * _Absorption;
                                if(transmittanceLight < 0.01)
                                {
                                    transmittanceLight = 0.0;
                                    break;
                                }
                            }
                            lightPos += lightRayDist;
                        }
                        lightPower += (_Opacity * d * transmittance * transmittanceLight);
                    }

                    //step毎にstep距離を延ばすことで遠景もそれなりに描画
                    rayDist *= _StepEnhanceRate;
                    total += rayDist;

                    //背面オブジェクトを超えたときちょうどのステップ長で1回処理する
                    if (depthLength <= total)
                    {
                        //上のif文の内側に入れないとアーティファクトが出る
                        if (depthLength == total)break;
                        total -= rayDist;
                        rayDist = depthLength - total;
                        total += rayDist;
                    }

                    p = sPos + worldDir * total;

                    //雲海の上に出たらそれ以上のステップ不要
                    if (abs(p.y) > rayStartY) break;

                }

                //lightPowerでlerpして色を決める
                color.rgb = lerp(_ShadeColor.rgb,_BrightColor.rgb,lightPower);

                //alphaが0のときは深度も書き込む必要が無いのでdiscard
                if (color.a <= 0.0) discard;

                //ワールド座標系に戻す
                p = sPos + worldDir * total + mul(unity_ObjectToWorld, float4(0,0,0,1));

                pout o;
                //雲のdepth書き込み
                float3 localPos = mul(unity_WorldToObject, float4(p, 1.0));
                float4 projectionPos = UnityObjectToClipPos(float4(localPos,1.0));
                o.depth = projectionPos.z / projectionPos.w;

                //負荷確認用
                //#ifdef VLOOP
                //    color = float4(i*(1.0 / _Loop),0,0,1);
                //#endif

                o.color = color;

                return o;
            }
            ENDCG
        }
    }
}
