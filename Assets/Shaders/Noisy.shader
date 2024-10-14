Shader "Unlit/Noisy"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Speed ("Scroll Speed", Range(0,2)) = 1
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
                // calculate scroll offset based on time, restricted to [0,1) range
                float t = _Time.y * _Speed;
                t -= floor(t);

                // build new position
                fixed2 uv = i.uv;
                uv.y -= t;

                // sample the texture
                fixed4 col = tex2D(_MainTex, uv);

                // generate noise
                fixed noise = abs(sin(sin(dot(float3(i.uv.x, i.uv.y, _SinTime.x),float3(12.9898, 78.233, 37.719))) * 143758.5453));
                //fixed noise = frac(sin(dot(float3(i.uv.x, i.uv.y, _SinTime.x),float3(12.9898, 78.233, 37.719))) * 143758.5453);
                col *= noise;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
