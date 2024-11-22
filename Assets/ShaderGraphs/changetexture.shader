
HEADER
{
	Description = "";
}

FEATURES
{
	#include "common/features.hlsl"
}

MODES
{
	VrForward();
	Depth(); 
	ToolsVis( S_MODE_TOOLS_VIS );
	ToolsWireframe( "vr_tools_wireframe.shader" );
	ToolsShadingComplexity( "tools_shading_complexity.shader" );
}

COMMON
{
	#ifndef S_ALPHA_TEST
	#define S_ALPHA_TEST 1
	#endif
	#ifndef S_TRANSLUCENT
	#define S_TRANSLUCENT 0
	#endif
	
	#include "common/shared.hlsl"
	#include "procedural.hlsl"

	#define S_UV2 1
	#define CUSTOM_MATERIAL_INPUTS
}

struct VertexInput
{
	#include "common/vertexinput.hlsl"
	float4 vColor : COLOR0 < Semantic( Color ); >;
};

struct PixelInput
{
	#include "common/pixelinput.hlsl"
	float3 vPositionOs : TEXCOORD14;
	float3 vNormalOs : TEXCOORD15;
	float4 vTangentUOs_flTangentVSign : TANGENT	< Semantic( TangentU_SignV ); >;
	float4 vColor : COLOR0;
	float4 vTintColor : COLOR1;
};

VS
{
	#include "common/vertex.hlsl"

	PixelInput MainVs( VertexInput v )
	{
		PixelInput i = ProcessVertex( v );
		i.vPositionOs = v.vPositionOs.xyz;
		i.vColor = v.vColor;

		ExtraShaderData_t extraShaderData = GetExtraPerInstanceShaderData( v );
		i.vTintColor = extraShaderData.vTint;

		VS_DecodeObjectSpaceNormalAndTangent( v, i.vNormalOs, i.vTangentUOs_flTangentVSign );

		return FinalizeVertex( i );
	}
}

PS
{
	#include "common/pixel.hlsl"
	
	SamplerState g_sSampler0 < Filter( ANISO ); AddressU( WRAP ); AddressV( WRAP ); >;
	CreateInputTexture2D( AColor, Srgb, 8, "None", "_color", "Color,0/,0/0", Default4( 1.00, 0.18, 0.18, 1.00 ) );
	CreateInputTexture2D( BColor, Srgb, 8, "None", "_color", "Color,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( AGlow, Srgb, 8, "None", "_selfillum", "Glow,0/,0/0", Default4( 1.00, 0.18, 0.18, 1.00 ) );
	CreateInputTexture2D( BGlow, Srgb, 8, "None", "_selfillum", "Glow,0/,0/0", Default4( 0.00, 1.00, 0.08, 1.00 ) );
	CreateInputTexture2D( ATransparency, Srgb, 8, "None", "_trans", "Transparency,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( BTransparency, Srgb, 8, "None", "_trans", "Transparency,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( ANormal, Srgb, 8, "None", "_normal", "Normal,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( BNormal, Srgb, 8, "None", "_normal", "Normal,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( ARougness, Srgb, 8, "None", "_rough", "Rougness,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( BRougness, Srgb, 8, "None", "_rough", "Rougness,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( AMetal, Srgb, 8, "None", "_metal", "Metal,0/,0/0", Default4( 1.00, 0.18, 0.18, 1.00 ) );
	CreateInputTexture2D( BMetal, Srgb, 8, "None", "_metal", "Metal,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	Texture2D g_tAColor < Channel( RGBA, Box( AColor ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBColor < Channel( RGBA, Box( BColor ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tAGlow < Channel( RGBA, Box( AGlow ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBGlow < Channel( RGBA, Box( BGlow ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tATransparency < Channel( RGBA, Box( ATransparency ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBTransparency < Channel( RGBA, Box( BTransparency ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tANormal < Channel( RGBA, Box( ANormal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBNormal < Channel( RGBA, Box( BNormal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tARougness < Channel( RGBA, Box( ARougness ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBRougness < Channel( RGBA, Box( BRougness ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tAMetal < Channel( RGBA, Box( AMetal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBMetal < Channel( RGBA, Box( BMetal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	float g_flCoords < UiStep( 1 ); UiGroup( "Color,0/,0/0" ); Default1( 1 ); Range1( 1, 10 ); >;
	float g_flTile < UiStep( 1 ); UiGroup( "Color,0/,0/0" ); Default1( 10 ); Range1( 1, 10 ); >;
	float g_flChangeSpeed < UiStep( 1 ); UiGroup( "Controller,0/,0/0" ); Default1( 3.56029 ); Range1( 1, 20 ); >;
	float g_flBrightness < UiStep( 1 ); UiGroup( "Glow,0/,0/0" ); Default1( 1 ); Range1( 1, 10 ); >;
	float4 g_vGlowColor < UiType( Color ); UiGroup( "Glow,0/,0/0" ); Default4( 1.00, 1.00, 1.00, 1.00 ); >;
	float g_flOpacityPower < UiStep( 1 ); UiGroup( "Transparency,0/,0/0" ); Default1( 1 ); Range1( 1, 10 ); >;
	
	float4 MainPs( PixelInput i ) : SV_Target0
	{
		Material m = Material::Init();
		m.Albedo = float3( 1, 1, 1 );
		m.Normal = float3( 0, 0, 1 );
		m.Roughness = 1;
		m.Metalness = 0;
		m.AmbientOcclusion = 1;
		m.TintMask = 1;
		m.Opacity = 1;
		m.Emission = float3( 0, 0, 0 );
		m.Transmission = 0;
		
		float2 l_0 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_1 = g_flCoords;
		float l_2 = g_flTile;
		float2 l_3 = TileAndOffsetUv( l_0, float2( l_1, l_1 ), float2( l_2, l_2 ) );
		float4 l_4 = Tex2DS( g_tAColor, g_sSampler0, l_3 );
		float4 l_5 = Tex2DS( g_tBColor, g_sSampler0, l_3 );
		float l_6 = g_flChangeSpeed;
		float l_7 = g_flTime * l_6;
		float l_8 = cos( l_7 );
		float l_9 = round( l_8 );
		float l_10 = saturate( l_9 );
		float4 l_11 = saturate( lerp( l_4, l_5, l_10 ) );
		float4 l_12 = Tex2DS( g_tAGlow, g_sSampler0, l_3 );
		float4 l_13 = Tex2DS( g_tBGlow, g_sSampler0, l_3 );
		float4 l_14 = saturate( lerp( l_12, l_13, l_10 ) );
		float l_15 = g_flBrightness;
		float4 l_16 = l_14 * float4( l_15, l_15, l_15, l_15 );
		float4 l_17 = g_vGlowColor;
		float4 l_18 = l_16 * l_17;
		float4 l_19 = Tex2DS( g_tATransparency, g_sSampler0, l_3 );
		float4 l_20 = Tex2DS( g_tBTransparency, g_sSampler0, l_3 );
		float4 l_21 = saturate( lerp( l_19, l_20, l_10 ) );
		float l_22 = g_flOpacityPower;
		float4 l_23 = l_21 * float4( l_22, l_22, l_22, l_22 );
		float4 l_24 = Tex2DS( g_tANormal, g_sSampler0, l_3 );
		float4 l_25 = Tex2DS( g_tBNormal, g_sSampler0, l_3 );
		float4 l_26 = saturate( lerp( l_24, l_25, l_10 ) );
		float4 l_27 = Tex2DS( g_tARougness, g_sSampler0, l_3 );
		float4 l_28 = Tex2DS( g_tBRougness, g_sSampler0, l_3 );
		float4 l_29 = saturate( lerp( l_27, l_28, l_10 ) );
		float4 l_30 = Tex2DS( g_tAMetal, g_sSampler0, l_3 );
		float4 l_31 = Tex2DS( g_tBMetal, g_sSampler0, l_3 );
		float4 l_32 = saturate( lerp( l_30, l_31, l_10 ) );
		
		m.Albedo = l_11.xyz;
		m.Emission = l_18.xyz;
		m.Opacity = l_23.x;
		m.Normal = l_26.xyz;
		m.Roughness = l_29.x;
		m.Metalness = l_32.x;
		m.AmbientOcclusion = 1;
		
		m.AmbientOcclusion = saturate( m.AmbientOcclusion );
		m.Roughness = saturate( m.Roughness );
		m.Metalness = saturate( m.Metalness );
		m.Opacity = saturate( m.Opacity );

		// Result node takes normal as tangent space, convert it to world space now
		m.Normal = TransformNormal( m.Normal, i.vNormalWs, i.vTangentUWs, i.vTangentVWs );

		// for some toolvis shit
		m.WorldTangentU = i.vTangentUWs;
		m.WorldTangentV = i.vTangentVWs;
        m.TextureCoords = i.vTextureCoords.xy;
		
		return ShadingModelStandard::Shade( i, m );
	}
}
