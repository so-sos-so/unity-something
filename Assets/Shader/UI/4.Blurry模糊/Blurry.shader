﻿Shader "Hidden/Blurry"
{
Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
        [MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
        Blurry ("模糊程度", Range(0,0.1)) = 0.01
    }

    SubShader
    {
        Tags
        { 
            "Queue"="Transparent" 
            "IgnoreProjector"="True" 
            "RenderType"="Transparent" 
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ PIXELSNAP_ON
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
            };

            fixed4 _Color;

            v2f vert(appdata_t IN)
            {
                v2f OUT;
                OUT.vertex = UnityObjectToClipPos(IN.vertex);
                OUT.texcoord = IN.texcoord;
                OUT.color = IN.color * _Color;
                #ifdef PIXELSNAP_ON
                OUT.vertex = UnityPixelSnap (OUT.vertex);
                #endif

                return OUT;
            }

            sampler2D _MainTex;
            sampler2D _AlphaTex;
            float _AlphaSplitEnabled;
            fixed Blurry;

            fixed4 SampleSpriteTexture (float2 uv)
            {
                fixed4 color = tex2D (_MainTex, uv);

                fixed4 leftColor = tex2D (_MainTex, fixed2(uv.x-Blurry,uv.y));
                fixed4 leftTopColor = tex2D(_MainTex, fixed2(uv.x - Blurry, uv.y + Blurry));
                fixed4 leftBottomColor = tex2D(_MainTex, fixed2(uv.x - Blurry, uv.y - Blurry));
                fixed4 rightColor = tex2D (_MainTex, fixed2(uv.x+Blurry,uv.y));
                fixed4 rightTopColor = tex2D(_MainTex, fixed2(uv.x + Blurry, uv.y + Blurry));
                fixed4 rightBottomColor = tex2D(_MainTex, fixed2(uv.x + Blurry, uv.y - Blurry));
                fixed4 topColor = tex2D(_MainTex, fixed2(uv.x, uv.y - Blurry));
                fixed4 bottomColor = tex2D(_MainTex, fixed2(uv.x, uv.y + Blurry));

                color = color * 0.147761 + leftColor * 0.118318 + 
                        rightColor * 0.118318 + topColor * 0.118318 + 
                        bottomColor * 0.118318 + leftTopColor * 0.09474416 +
                        leftBottomColor * 0.09474416 + rightTopColor * 0.09474416 +
                        rightBottomColor * 0.09474416;
                
                
#if UNITY_TEXTURE_ALPHASPLIT_ALLOWED
                if (_AlphaSplitEnabled)
                    color.a = tex2D (_AlphaTex, uv).r;
#endif //UNITY_TEXTURE_ALPHASPLIT_ALLOWED

                return color;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 c = SampleSpriteTexture (IN.texcoord) * IN.color;
                c.rgb *= c.a;
                return c;
            }
        ENDCG
        }
    }
}

