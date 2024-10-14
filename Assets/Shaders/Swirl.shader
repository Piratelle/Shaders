Shader "Unlit/Swirl"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AltTex ("Texture2", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _AltTex;
            float4 _AltTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv1 = TRANSFORM_TEX(v.uv1, _MainTex);
                o.uv2 = TRANSFORM_TEX(v.uv2, _AltTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            #ifndef POLAR_COORDS
            #define POLAR_COORDS

            // converts cartesian (x,y) to polar (angle, radius)
            fixed2 toPolar(fixed2 cartesian)
            {
                fixed radius = length(cartesian);
                float angle = atan2(cartesian.y, cartesian.x);
                return fixed2(angle / UNITY_TWO_PI, radius);
            }

            // converts polar (angle, radius) to cartesian (x,y)
            fixed2 toCartesian(fixed2 polar)
            {
                fixed2 cartesian;
                sincos(polar.x * UNITY_TWO_PI, cartesian.y, cartesian.x);
                return cartesian * polar.y;
            }

            #endif

            fixed4 frag (v2f i) : SV_Target
            {
                // get adjusted coordinates and convert to polar
                // adjustments: move (0,0) from bottom right to center, 
                //              scale up from (-.5,.5) to (1,1)
                fixed2 uv1 = toPolar(2 * (i.uv1 - 0.5));
                fixed2 uv2 = toPolar(2 * (i.uv2 - 0.5));

                // handle twisting based on time and radius
                fixed t = _SinTime.z;
                uv1.x += sin(t) * uv1.y;
                uv2.x += sin(t) * uv2.y;

                // convert back to cartesian and reverse adjustments
                uv1 = (toCartesian(uv1) * 0.5) + 0.5;
                uv2 = (toCartesian(uv2) * 0.5) + 0.5;
                
                // sample the textures
                t = abs(_SinTime.y);
                fixed4 col = (t * tex2D(_MainTex, uv1)) + ((1 -  t) * tex2D(_AltTex, uv2));

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
