Shader "Unlit/Grid"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Split ("Splits Per Side", Int) = 5
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
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            int _Split;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // calculate block size and offset
                // apply frac to get [0,1) ranges
                float block = 1.0 / (1 + _Split);
                float t = _Time.y * 2 / UNITY_PI;
                t = frac(t) * block;

                // use block size, row, and col to calculate diagonal band (odds/evens)
                // odd blocks -> L D R U
                // even block -> R U L D (-1 * L D R U)
                bool odd = (floor(i.uv.x / block) + floor(i.uv.y / block)) % 2;
                int dir = odd ? 1 : -1;

                // determine phase using sin, cos (4 phases: s+c+/s+c-/s-c-/s-c+)
                fixed sin = _SinTime.w;
                fixed cos = _CosTime.w;
                int phase = 2 * (sin >= 0 ? 0 : 1); // sin +/-
                if (!((sin < 0 && cos < 0) || (sin >= 0 && cos >= 0))) {
                    phase += 1;
                } // signs match/not

                // shift based on phase and offset
                fixed2 uv = i.uv;
                t *= dir;
                block *= dir;
                switch(phase)
                {
                    case 0:
                        // phase 0 -> left (0 -> 1)
                        uv.x -= t;
                        break;
                    case 1:
                        // phase 1 -> left 1, down (0 -> 1)
                        uv.x -= block;
                        uv.y -= t;
                        break;
                    case 2:
                        // phase 2 -> down 1, left (1 -> 0)
                        uv.y -= block;
                        uv.x -= (block - t);
                        break;
                    default:
                        // phase 3 -> down (1 -> 0)
                        uv.y -= (block - t);
                        break;
                }
                
                // sample the texture
                fixed4 col = tex2D(_MainTex, uv);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
