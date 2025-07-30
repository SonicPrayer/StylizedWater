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

        _CubeMap ("Reflection Cubemap", Cube) = "" {}
        _ReflectionStrength ("Reflection Strength", Range(0, 1)) = 0.5

        _RippleNormal ("Ripple Normal Map", 2D) = "bump" {}
        _RippleSpeed ("Ripple Speed", Float) = 0.5
        _RippleStrength ("Ripple Strength", Float) = 0.5
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
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _Amplitude;
                float _Frequency;
                float _Speed;
                float4 _WaveDirection;

                float _Amplitude2;
                float _Frequency2;
                float _Speed2;
                float4 _WaveDirection2;

                float _RippleTiling;
                float _RippleSpeed;
                float _RippleStrength;
                float _ReflectionStrength;
                float4 _RippleNormal_ST;
            CBUFFER_END

            TEXTURECUBE(_CubeMap);
            SAMPLER(sampler_CubeMap);

            TEXTURE2D(_RippleNormal);
            SAMPLER(sampler_RippleNormal);

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float3 pos = IN.positionOS.xyz;

                // Первая волна
                float wave1 = sin(dot(pos.xz, _WaveDirection.xy) * _Frequency + _Time.y * _Speed);
                float offset1 = wave1 * _Amplitude;

                // Вторая волна
                float wave2 = sin(dot(pos.xz, _WaveDirection2.xy) * _Frequency2 + _Time.y * _Speed2);
                float offset2 = wave2 * _Amplitude2;

                // Суммарное смещение
                pos.y += offset1 + offset2;

                OUT.worldPos = TransformObjectToWorld(pos);
                OUT.positionHCS = TransformObjectToHClip(pos);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 viewDir = normalize(_WorldSpaceCameraPos - IN.worldPos);

                float2 rippleUV = IN.worldPos.xz * _RippleNormal_ST.xy + _RippleNormal_ST.zw;
                rippleUV += _Time.y * _RippleSpeed;
                float3 rippleNormal = UnpackNormal(SAMPLE_TEXTURE2D(_RippleNormal, sampler_RippleNormal, rippleUV));
                float3 baseNormal = float3(0, 1, 0);
                float3 finalNormal = normalize(lerp(baseNormal, rippleNormal, _RippleStrength));

                float3 reflectionDir = reflect(-viewDir, finalNormal);
                float3 reflectionColor = SAMPLE_TEXTURECUBE(_CubeMap, sampler_CubeMap, reflectionDir).rgb;

                float3 finalColor = lerp(_BaseColor.rgb, reflectionColor, _ReflectionStrength);
                return float4(finalColor, _BaseColor.a);
            }
            ENDHLSL
        }
    }
}
