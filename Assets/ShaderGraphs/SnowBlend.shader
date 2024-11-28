
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
	#define S_ALPHA_TEST 0
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
	CreateInputTexture2D( ColorA, Srgb, 8, "None", "_color", "Texture A,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( ColorB, Srgb, 8, "None", "_color", "Texture B,1/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( NormalA, Srgb, 8, "None", "_normal", "Texture A,0/,0/1", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( NormalB, Srgb, 8, "None", "_normal", "Texture B,0/,0/1", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( RoughA, Srgb, 8, "None", "_rough", "Texture A,0/,0/2", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( RoughB, Srgb, 8, "None", "_rough", "Texture B,0/,0/2", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( MetalA, Srgb, 8, "None", "_metal", "Texture A,0/,0/4", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( MetalB, Srgb, 8, "None", "_metal", "Texture B,0/,0/4", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( AoA, Srgb, 8, "None", "_ao", "Texture A,0/,0/3", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( AoB, Srgb, 8, "None", "_ao", "Texture B,0/,0/3", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	Texture2D g_tColorA < Channel( RGBA, Box( ColorA ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tColorB < Channel( RGBA, Box( ColorB ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tNormalA < Channel( RGBA, Box( NormalA ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tNormalB < Channel( RGBA, Box( NormalB ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tRoughA < Channel( RGBA, Box( RoughA ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tRoughB < Channel( RGBA, Box( RoughB ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tMetalA < Channel( RGBA, Box( MetalA ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tMetalB < Channel( RGBA, Box( MetalB ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tAoA < Channel( RGBA, Box( AoA ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tAoB < Channel( RGBA, Box( AoB ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	float g_flSnowSize < UiType( Slider ); UiGroup( ",0/,0/1" ); Default1( 0.5 ); Range1( 0, 1 ); >;
	float g_flSnowDensity < UiType( Slider ); UiGroup( ",0/,0/1" ); Default1( 12.255959 ); Range1( 1, 100 ); >;
	
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
		float4 l_1 = Tex2DS( g_tColorA, g_sSampler0, l_0 );
		float4 l_2 = Tex2DS( g_tColorB, g_sSampler0, l_0 );
		float3 l_3 = float3( 0, 0, 1 );
		float l_4 = dot( l_3, i.vNormalWs );
		float l_5 = g_flSnowSize;
		float l_6 = l_4 - l_5;
		float l_7 = g_flSnowDensity;
		float l_8 = l_6 * l_7;
		float l_9 = saturate( l_8 );
		float4 l_10 = lerp( l_1, l_2, l_9 );
		float4 l_11 = Tex2DS( g_tNormalA, g_sSampler0, l_0 );
		float4 l_12 = Tex2DS( g_tNormalB, g_sSampler0, l_0 );
		float4 l_13 = lerp( l_11, l_12, l_9 );
		float4 l_14 = Tex2DS( g_tRoughA, g_sSampler0, l_0 );
		float4 l_15 = Tex2DS( g_tRoughB, g_sSampler0, l_0 );
		float4 l_16 = lerp( l_14, l_15, l_9 );
		float4 l_17 = Tex2DS( g_tMetalA, g_sSampler0, l_0 );
		float4 l_18 = Tex2DS( g_tMetalB, g_sSampler0, l_0 );
		float4 l_19 = lerp( l_17, l_18, l_9 );
		float4 l_20 = Tex2DS( g_tAoA, g_sSampler0, l_0 );
		float4 l_21 = Tex2DS( g_tAoB, g_sSampler0, l_0 );
		float4 l_22 = lerp( l_20, l_21, l_9 );
		
		m.Albedo = l_10.xyz;
		m.Opacity = 1;
		m.Normal = l_13.xyz;
		m.Roughness = l_16.x;
		m.Metalness = l_19.x;
		m.AmbientOcclusion = l_22.x;
		
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
