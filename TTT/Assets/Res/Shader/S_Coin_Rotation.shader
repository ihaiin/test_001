Shader "Custom/Fx_Coin_Rotation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Speed ("Speed", Float) = 1
        _AddColor ("Add Color", Color) = (0,0,0,1)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "IgnoreProjector"="True"
            "PreviewType"="Plane"
        }

        LOD 50
        Cull Off
        ZWrite Off
        Blend SrcAlpha One

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Speed;
            fixed4 _AddColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                float angle = _Time.y * _Speed;
                float s;
                float c;
                sincos(angle, s, c);

                float2 uv = v.uv - 0.5;
                uv = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c) + 0.5;
                o.uv = TRANSFORM_TEX(uv, _MainTex);
                o.color = v.color;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed edgeFade = saturate(min(min(i.uv.x, 1.0 - i.uv.x), min(i.uv.y, 1.0 - i.uv.y)) * 20.0);
                fixed4 tex = tex2D(_MainTex, i.uv);
                fixed alpha = max(tex.r, max(tex.g, tex.b)) * tex.a * i.color.a * edgeFade;
                fixed3 color = (tex.rgb + _AddColor.rgb) * i.color.rgb;
                return fixed4(color, alpha);
            }
            ENDCG
        }
    }

    FallBack Off
}
