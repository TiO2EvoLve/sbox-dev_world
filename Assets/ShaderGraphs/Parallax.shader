
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
	CreateInputTexture2D( Color, Srgb, 8, "None", "_color", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( Emission, Srgb, 8, "None", "_selfillum", ",0/,0/6", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( Opacity, Srgb, 8, "None", "_trans", ",0/,0/5", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( Normal, Srgb, 8, "None", "_normal", ",0/,0/1", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( Rough, Srgb, 8, "None", "_rough", ",0/,0/2", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( Metal, Srgb, 8, "None", "_metal", ",0/,0/3", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( AO, Srgb, 8, "None", "_ao", ",0/,0/4", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	Texture2D g_tColor < Channel( RGBA, Box( Color ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tEmission < Channel( RGBA, Box( Emission ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tOpacity < Channel( RGBA, Box( Opacity ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tNormal < Channel( RGBA, Box( Normal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tRough < Channel( RGBA, Box( Rough ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tMetal < Channel( RGBA, Box( Metal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tAO < Channel( RGBA, Box( AO ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	float g_fldepth < UiGroup( ",0/,0/0" ); Default1( 3.496268 ); Range1( 0, 10 ); >;
	float2 g_vTile < UiGroup( ",0/,0/0" ); Default2( 1,1 ); Range2( 0,0, 10,10 ); >;
	float2 g_vOffset < UiGroup( ",0/,0/0" ); Default2( 0,0 ); Range2( 0,0, 10,10 ); >;
	
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
		
		float3 l_0 = Vec3WsToTs( i.vNormalOs, i.vNormalWs, i.vTangentUWs, i.vTangentVWs );
		float3 l_1 = CalculatePositionToCameraDirWs( i.vPositionWithOffsetWs.xyz + g_vHighPrecisionLightingOffsetWs.xyz );
		float3 l_2 = Vec3WsToTs( l_1, i.vNormalWs, i.vTangentUWs, i.vTangentVWs );
		float l_3 = g_fldepth;
		float l_4 = l_2.z;
		float l_5 = l_3 / l_4;
		float3 l_6 = l_2 * float3( l_5, l_5, l_5 );
		float3 l_7 = l_0 - l_6;
		float2 l_8 = g_vTile;
		float2 l_9 = g_vOffset;
		float2 l_10 = TileAndOffsetUv( l_7.xy, l_8, l_9 );
		float4 l_11 = Tex2DS( g_tColor, g_sSampler0, l_10 );
		float4 l_12 = Tex2DS( g_tEmission, g_sSampler0, l_10 );
		float4 l_13 = Tex2DS( g_tOpacity, g_sSampler0, l_10 );
		float4 l_14 = Tex2DS( g_tNormal, g_sSampler0, l_10 );
		float4 l_15 = Tex2DS( g_tRough, g_sSampler0, l_10 );
		float4 l_16 = Tex2DS( g_tMetal, g_sSampler0, l_10 );
		float4 l_17 = Tex2DS( g_tAO, g_sSampler0, l_10 );
		
		m.Albedo = l_11.xyz;
		m.Emission = l_12.xyz;
		m.Opacity = l_13.x;
		m.Normal = l_14.xyz;
		m.Roughness = l_15.x;
		m.Metalness = l_16.x;
		m.AmbientOcclusion = l_17.x;
		
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
