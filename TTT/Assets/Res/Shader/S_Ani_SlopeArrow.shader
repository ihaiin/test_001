Shader "Custom/SlopeArrow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Base Color", Color) = (1, 1, 1, 1)
        _GlowColor ("Arrow Glow Color", Color) = (1, 0.9, 0.25, 1)
        _SequenceSpeed ("Sequence Speed", Float) = 1.6
        _ArrowCount ("Arrow Count", Float) = 3
        _GlowIntensity ("Glow Intensity", Range(0, 4)) = 1.5
        _MaskThreshold ("Arrow Mask Threshold", Range(0, 1)) = 0.45
        _MaskSoftness ("Arrow Mask Softness", Range(0.001, 0.5)) = 0.08
        _PulseWidth ("Pulse Width", Range(0.05, 1)) = 0.65
        _ReverseOrder ("Reverse Order", Range(0, 1)) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
        }

        LOD 100
        Cull Off
        Lighting Off
        ZWrite On

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed4 _GlowColor;
            float _SequenceSpeed;
            float _ArrowCount;
            float _GlowIntensity;
            float _MaskThreshold;
            float _MaskSoftness;
            float _PulseWidth;
            float _ReverseOrder;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 tex = tex2D(_MainTex, i.uv);
                fixed4 col = tex * _Color;

                float luminance = dot(tex.rgb, float3(0.299, 0.587, 0.114));
                float arrowMask = 1.0 - smoothstep(_MaskThreshold - _MaskSoftness, _MaskThreshold + _MaskSoftness, luminance);

                float arrowCount = max(1.0, round(_ArrowCount));
                float orderUv = lerp(i.uv.y, 1.0 - i.uv.y, step(0.5, _ReverseOrder));
                float arrowIndex = floor(saturate(orderUv) * arrowCount);
                arrowIndex = min(arrowIndex, arrowCount - 1.0);

                float sequence = frac(_Time.y * _SequenceSpeed) * arrowCount;
                float distanceToActive = abs(sequence - arrowIndex);
                distanceToActive = min(distanceToActive, arrowCount - distanceToActive);
                float sequencePulse = 1.0 - smoothstep(0.0, _PulseWidth, distanceToActive);

                float glow = arrowMask * sequencePulse;
                col.rgb = lerp(col.rgb, _GlowColor.rgb, glow);
                col.rgb += _GlowColor.rgb * glow * _GlowIntensity;
                col.a = 1.0;
                return col;
            }
            ENDCG
        }
    }
}
