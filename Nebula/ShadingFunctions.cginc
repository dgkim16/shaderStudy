float hardShadow(float3 ro, float3 rd, float mint, float maxt, float3 worldPos)
{
	[unroll(3)]
	for(float t = mint; t < maxt;)
	{
		float h = DElight(ro+rd*t, worldPos);
		if(h < 0.001) return 0;
		t += h;
	}
	return 1.0;
}

float3 Shading(float3 p, float3 n, float3 worldPos)
{
	//Directional Light
	float3 result = (_LightCol * dot(_WorldSpaceLightPos0, n) *0.5 + 0.5) * _LightIntensity;
	float shadow = hardShadow(p, _WorldSpaceLightPos0, _ShadowDistance.x, _ShadowDistance.y, worldPos) * 0.5 + 0.5;
	shadow = max(0.0, pow(shadow, _ShadowIntensity));
	result *= shadow;
	return result;
}