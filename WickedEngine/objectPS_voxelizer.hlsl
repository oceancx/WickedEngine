#include "objectHF.hlsli"

RWTEXTURE3D(output_emission, float4, 0);
RWTEXTURE3D(output_normal, float4, 1);

void main(float4 pos : SV_POSITION, float3 N : NORMAL, float2 tex : TEXCOORD, float3 P : POSITION3D)
{
	float4 emission = DEGAMMA(xBaseColorMap.Sample(sampler_linear_wrap, tex));

	[branch]
	if (g_xFrame_SunLightArrayIndex >= 0)
	{
		LightArrayType light = LightArray[g_xFrame_SunLightArrayIndex];

		float3 L = light.directionWS;

		float3 diffuse = light.color.rgb * light.energy * max(dot(N, L), 0);

		[branch]
		if (light.shadowMap_index >= 0)
		{
			float4 ShPos = mul(float4(P, 1), light.shadowMat[0]);
			ShPos.xyz /= ShPos.w;
			float3 ShTex = ShPos.xyz*float3(1, -1, 1) / 2.0f + 0.5f; 
			
			[branch]if ((saturate(ShTex.x) == ShTex.x) && (saturate(ShTex.y) == ShTex.y) && (saturate(ShTex.z) == ShTex.z))
			{
				diffuse *= shadowCascade(ShPos, ShTex.xy, light.shadowKernel, light.shadowBias, light.shadowMap_index + 0);
			}
		}

		emission.rgb *= diffuse;
	}


	float3 diff = (P - g_xWorld_VoxelRadianceDataCenter) * g_xWorld_VoxelRadianceRemap;
	float3 uvw = diff * float3(0.5f, -0.5f, 0.5f) + 0.5f;
	uint res = floor(g_xWorld_VoxelRadianceDataRes);
	uint3 writecoord = floor(uvw * res);

	if (writecoord.x >= 0 && writecoord.x < res
		&& writecoord.y >= 0 && writecoord.y < res
		&& writecoord.z >= 0 && writecoord.z < res)
	{
		output_emission[writecoord] = emission;
		output_normal[writecoord] = float4(N * 0.5f + 0.5f, 1);
	}
}