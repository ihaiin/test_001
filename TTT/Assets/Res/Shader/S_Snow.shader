Shader "Custom/MobileSnow"
{
    Properties
    {
        _MainTex ("雪纹理", 2D) = "white" {}
        _BaseColor ("雪面颜色", Color) = (0.92, 0.98, 1.0, 1.0)
        _ShadowColor ("阴影蓝色", Color) = (0.45, 0.68, 0.9, 1.0)
        _SparkleColor ("冰晶高光颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimColor ("边缘冷光颜色", Color) = (0.72, 0.9, 1.0, 1.0)
        _TextureStrength ("纹理强度", Range(0.0, 1.0)) = 0.35
        _SparkleStrength ("冰晶闪光强度", Range(0.0, 1.5)) = 0.35
        _RimStrength ("边缘冷光强度", Range(0.0, 1.5)) = 0.35
        _TopLight ("顶部积雪亮度", Range(0.0, 1.0)) = 0.35
        _LightWrap ("柔光包裹", Range(0.0, 1.0)) = 0.45
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
        }

        LOD 100
        Cull Back
        ZWrite On

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _BaseColor;
            fixed4 _ShadowColor;
            fixed4 _SparkleColor;
            fixed4 _RimColor;
            half _TextureStrength;
            half _SparkleStrength;
            half _RimStrength;
            half _TopLight;
            half _LightWrap;

            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                half3 worldNormal : TEXCOORD0;
                half3 viewDir : TEXCOORD1;
                half3 worldPos : TEXCOORD2;
                float2 uv : TEXCOORD3;
                UNITY_FOG_COORDS(4)
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = UnityWorldSpaceViewDir(o.worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.pos);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                half3 n = normalize(i.worldNormal);
                half3 v = normalize(i.viewDir);
                half3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                half snowTex = tex2D(_MainTex, i.uv).r;
                half wrappedLight = saturate(dot(n, lightDir) * (1.0h - _LightWrap) + _LightWrap);
                half topMask = saturate(n.y * 0.5h + 0.5h);

                half3 color = lerp(_ShadowColor.rgb, _BaseColor.rgb, wrappedLight);
                color = lerp(color, color * (0.82h + snowTex * 0.28h), _TextureStrength);
                color += _BaseColor.rgb * topMask * _TopLight * 0.25h;

                half rim = smoothstep(0.55h, 0.95h, 1.0h - saturate(dot(n, v))) * _RimStrength;
                half sparkle = smoothstep(0.84h, 1.0h, snowTex) * smoothstep(0.35h, 0.95h, wrappedLight) * _SparkleStrength;

                color += _RimColor.rgb * rim;
                color += _SparkleColor.rgb * sparkle;

                fixed4 finalColor = fixed4(saturate(color), 1.0h);
                UNITY_APPLY_FOG(i.fogCoord, finalColor);
                return finalColor;
            }
            ENDCG
        }
    }

    FallBack "Mobile/Diffuse"
}
