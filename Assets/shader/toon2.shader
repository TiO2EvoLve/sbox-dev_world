HEADER
{
	Description = "A basic S&box Toon Shader - Created by Generalisk";
}

FEATURES
{
    #include "common/features.hlsl"

    Feature( F_ALPHA_TEST, 0..1, "Translucent" );
    Feature( F_TRANSLUCENT, 0..1, "Translucent" );
}

COMMON
{
	#define CUSTOM_MATERIAL_INPUTS
	#include "common/shared.hlsl"
}

struct VertexInput
{
	#include "common/vertexinput.hlsl"
};

struct PixelInput
{
	#include "common/pixelinput.hlsl"
};

VS
{
	#include "common/vertex.hlsl"

	PixelInput MainVs( VertexInput i )
	{
		PixelInput o = ProcessVertex( i );
		// Add your vertex manipulation functions here
		return FinalizeVertex( o );
	}
}

//=========================================================================================================================

PS
{
    #include "common/pixel.hlsl"
	#include "procedural.hlsl"
	
    StaticCombo(S_ALPHA_TEST, F_ALPHA_TEST, Sys(ALL));
    StaticCombo(S_TRANSLUCENT, F_TRANSLUCENT, Sys(ALL));

	SamplerState g_sSampler <Filter(BLINEAR); AddressU(WRAP); AddressV(WRAP);>;
	SamplerState g_sLightwarpSampler <Filter(NONE); AddressU(CLAMP); AddressV(CLAMP);>;

	CreateInputTexture2D(Albedo, Srgb, 8, "", "_color", "Material,10/10", Default3(1, 1, 1));
	CreateInputTexture2D(Normal, Linear, 8, "NormalizeNormals", "_normal", "Material,10/20", Default3(0.5, 0.5, 1));
	CreateInputTexture2D(Emission, Linear, 8, "", "_selfillum", "Material,10/30", Default3(0, 0, 0));
	CreateInputTexture2D(Opacity, Linear, 8, "", "_trans", "Material,10/40", Default(1));
	CreateInputTexture2D(TintMask, Linear, 8, "", "_tint", "Material,10/50", Default(1));
	CreateInputTexture2D(Lightwarp, Linear, 16, "", "_lightwarp", "Material,10/60", Default3(1, 1, 1));

	CreateTexture2DWithoutSampler(g_tColor) <Channel(RGB, Box(Albedo), Srgb); Channel(A, Box(Opacity), Linear); OutputFormat(DXT5); SrgbRead(true);>;
	CreateTexture2DWithoutSampler(g_tNormal) <Channel(RGB, Box(Normal), Linear); Channel(A, Box(TintMask), Linear); OutputFormat(DXT5); SrgbRead(true);>;
	CreateTexture2DWithoutSampler(g_tEmit) <Channel(RGB, Box(Emission), Linear); OutputFormat(DXT5); SrgbRead(true);>;
	CreateTexture2DWithoutSampler(g_tLightwarp) <Channel(RGB, Box(Lightwarp), Linear); OutputFormat(RGBA16161616F); SrgbRead(true);>;

	TextureAttribute(AlbedoTex, g_tColor);
	TextureAttribute(NormalTex, g_tNormal);
	TextureAttribute(EmitTex, g_tEmit);
	TextureAttribute(Lightwarp, g_tLightwarp);

	float3 g_flColorTint <UiType(Color); Default3(1, 1, 1); UiGroup("Material,10/70");>;

	FloatAttribute(ColorTint, g_flColorTint);

	float4 MainPs( PixelInput i ) : SV_Target0
	{
		float3 albedo = Tex2DS(g_tColor, g_sSampler, i.vTextureCoords).rgb;
		float3 normal = Tex2DS(g_tNormal, g_sSampler, i.vTextureCoords).rgb;
		float3 emission = Tex2DS(g_tEmit, g_sSampler, i.vTextureCoords).rgb;
		float opacity = Tex2DS(g_tColor, g_sSampler, i.vTextureCoords).a;
		float tintMask = Tex2DS(g_tNormal, g_sSampler, i.vTextureCoords).a;

		Material tmp = Material::Init();
		tmp.Roughness = 0.5;
		tmp.Normal = normal;

		float3 shading = ShadingModelStandard::Shade(i, tmp);

		float3 toonShading = float3(1, 1, 1);

		toonShading.x = Tex2DS(g_tLightwarp, g_sLightwarpSampler, TileAndOffsetUv(float2(shading.x * 2.1, 0), float2(1, 1), float2(0, 0))).x;
		toonShading.y = Tex2DS(g_tLightwarp, g_sLightwarpSampler, TileAndOffsetUv(float2(shading.y * 2.1, 0), float2(1, 1), float2(0, 0))).y;
		toonShading.z = Tex2DS(g_tLightwarp, g_sLightwarpSampler, TileAndOffsetUv(float2(shading.z * 2.1, 0), float2(1, 1), float2(0, 0))).z;

		//Placeholder
		/*if (shading.x >= 0.98) { toonShading.x = 1; }
		else if (shading.x >= 0.49) { toonShading.x = 0.5; }
		else { toonShading.x = 0; }

		if (shading.y >= 0.98) { toonShading.y = 1; }
		else if (shading.y >= 0.49) { toonShading.y = 0.5; }
		else { toonShading.y = 0; }

		if (shading.z >= 0.98) { toonShading.z = 1; }
		else if (shading.z >= 0.49) { toonShading.z = 0.5; }
		else { toonShading.z = 0; }*/

		float3 shadingOut = (lerp(albedo, (albedo * g_flColorTint), tintMask) * toonShading) + emission;

		return float4(shadingOut.x, shadingOut.y, shadingOut.z, opacity);
	}
}
