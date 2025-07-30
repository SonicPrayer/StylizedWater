Shader "Custom/StylizedWater"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.3, 0.6, 0.8, 1)
        _Amplitude ("Wave Amplitude", Float) = 0.2
        _Frequency ("Wave Frequency", Float) = 1
        _Speed ("Wave Speed", Float) = 1
        _WaveDirection ("Wave Direction", Vector) = (1, 0, 0, 0)
        _Amplitude2 ("Wave Amplitude 2", Float) = 0.15
        _Frequency2 ("Wave Frequency 2", Float) = 1.5
        _Speed2 ("Wave Speed 2", Float) = 1.2
        _WaveDirection2 ("Wave Direction 2", Vector) = (0, 1, 0, 0)
        [Toggle] _TwoSided ("Two Sided", Float) = 1
        _CubeMap("Reflection Cubemap", Cube) = "" {}
        _ReflectionStrength("Reflection Strength", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue"="Transparent" }
        LOD 100

        Pass
        {
            Name "Unlit"
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 reflectDir: TEXCOORD1;
            };
            
            float4 _BaseColor;
            float _Amplitude;
            float _Frequency;
            float _Speed;
            float4 _WaveDirection;
            float _Amplitude2;
            float _Frequency2;
            float _Speed2;
            float4 _WaveDirection2;
            TEXTURECUBE(_CubeMap);
            SAMPLER(sampler_CubeMap);
            float _ReflectionStrength;
            

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 pos = IN.positionOS.xyz;
                
                float wave1 = sin(dot(pos.xz, _WaveDirection.xy) * _Frequency + _Time * _Speed);
                float offset1 = wave1 * _Amplitude;
                
                float wave2 = sin(dot(pos.xz, _WaveDirection2.xy) * _Frequency2 + _Time * _Speed2);
                float offset2 = wave2 * _Amplitude2;
                
                pos.y += offset1 + offset2;

                OUT.worldPos = TransformObjectToWorld(pos);
                OUT.positionHCS = TransformObjectToHClip(pos);
                
                float3 worldNormal = float3(0,1,0);
                float3 viewDir  = normalize(_WorldSpaceCameraPos - OUT.worldPos);
                OUT.reflectDir = reflect(-viewDir, worldNormal);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float4 baseColor = _BaseColor;
                float3 reflectionColor = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, IN.reflectDir).rgb;
                float3 finalColor = lerp(baseColor.rgb, reflectionColor, _ReflectionStrength);
                return float4(finalColor, baseColor.a);
            }
            ENDHLSL
        }
    }
}
