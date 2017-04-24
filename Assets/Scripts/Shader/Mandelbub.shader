Shader "Hidden/Mandelbub"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
    			float2 uv : TEXCOORD0;
    			float3 ray : TEXCOORD1;
			};

			uniform float4x4 _FrustumCornersES;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float3 _CameraWS;

			v2f vert (appdata v)
			{
				v2f o;

				// Index passed via custom blit function in RaymarchGeneric.cs
				half index = v.vertex.z;
				v.vertex.z = 0.1;

				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv.xy;

				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					o.uv.y = 1 - o.uv.y;
				#endif

				// Get the eyespace view ray (normalized)
				o.ray = _FrustumCornersES[(int)index].xyz;

				// Transform the ray from eyespace to worldspace
				// Note: _CameraInvViewMatrix was provided by the script
				o.ray = mul(_CameraInvViewMatrix, o.ray);
				return o;
			}

			float SdSphere(float3 pos, float r){
				return length(pos) - r;
			}

			float map(float3 pos){
				return SdSphere(pos, 1.0);
			}

			fixed4 raymarch(float3 ro, float3 rd){

				float t = 0;
				for(int i = 0; i < 64; i++){
					float d = map(ro + rd * t);
					if(d < 0.01)
					{
						return fixed4(1.0, 1.0, 1.0, 1.0);
					}
					t += d;
				}
				return fixed4(0.0,0.0,0.0,0.0);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float3 rd = normalize(i.ray.xyz);
    			// ray origin (camera position)
    			float3 ro = _CameraWS;

				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 add = raymarch(ro, rd);
				// fixed4 col = fixed4(i.ray, 1);
				return fixed4(col*(1.0 - add.w) + add.xyz * add.w,1.0);
			}
			ENDCG
		}
	}
}
