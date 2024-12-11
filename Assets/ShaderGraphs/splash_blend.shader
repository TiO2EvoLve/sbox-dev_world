
HEADER
{
	Description = "a blend shader with rain";
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
	CreateInputTexture2D( Color, Srgb, 8, "None", "_color", "Color,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( Normal, Srgb, 8, "None", "_normal", "Color,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( ASprayNormal, Srgb, 8, "None", "_normal", "Rain,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( BSprayNormal, Srgb, 8, "None", "_normal", "Rain,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( flowingwaternormal, Srgb, 8, "None", "_normal", "flowing water,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	Texture2D g_tColor < Channel( RGBA, Box( Color ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tNormal < Channel( RGBA, Box( Normal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tASprayNormal < Channel( RGBA, Box( ASprayNormal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBSprayNormal < Channel( RGBA, Box( BSprayNormal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tflowingwaternormal < Channel( RGBA, Box( flowingwaternormal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	float4 g_vTint < UiType( Color ); UiGroup( "Color,0/,0/0" ); Default4( 1.00, 1.00, 1.00, 1.00 ); >;
	float g_flTiles < UiType( Slider ); UiStep( 1 ); UiGroup( "Color,0/Color,0/10" ); Default1( 1 ); Range1( 1, 10 ); >;
	float g_flASprayTiles < UiType( Slider ); UiStep( 0.2 ); UiGroup( "Rain,0/A Spray,0/0" ); Default1( 1 ); Range1( 1, 10 ); >;
	float g_flRow < UiType( Slider ); UiStep( 1 ); UiGroup( "Rain,0/Row And Column,0/0" ); Default1( 4 ); Range1( 1, 20 ); >;
	float g_flASpraySpeed < UiType( Slider ); UiStep( 1 ); UiGroup( "Rain,0/A Spray,0/0" ); Default1( 15 ); Range1( 1, 20 ); >;
	float g_flBSprayTiles < UiType( Slider ); UiStep( 0.2 ); UiGroup( "Rain,0/B Spray ,0/0" ); Default1( 1 ); Range1( 1, 10 ); >;
	float g_flBSpraySpeed < UiType( Slider ); UiStep( 1 ); UiGroup( "Rain,0/B Spray,0/0" ); Default1( 15 ); Range1( 1, 20 ); >;
	float g_flBOffset < UiGroup( ",0/,0/0" ); Default1( 0 ); Range1( 0, 10 ); >;
	float g_flRainSprayTile < UiGroup( ",0/,0/0" ); Default1( 2.3094501 ); Range1( 1, 10 ); >;
	float g_flflowingwaterspeed < UiGroup( "flowing water,0/,0/0" ); Default1( 1 ); Range1( 1, 10 ); >;
	
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
		
		float4 l_0 = g_vTint;
		float l_1 = g_flTiles;
		float2 l_2 = TileAndOffsetUv( i.vTextureCoords.xy, float2( l_1, l_1 ), float2( 0, 0 ) );
		float4 l_3 = Tex2DS( g_tColor, g_sSampler0, l_2 );
		float4 l_4 = l_0 * l_3;
		float4 l_5 = Tex2DS( g_tNormal, g_sSampler0, l_2 );
		float2 l_6 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_7 = g_flASprayTiles;
		float2 l_8 = l_6 * float2( l_7, l_7 );
		float l_9 = g_flRow;
		float2 l_10 = l_8 / float2( l_9, l_9 );
		float l_11 = 1 / l_9;
		float l_12 = g_flASpraySpeed;
		float l_13 = g_flTime * l_12;
		float l_14 = floor( l_13 );
		float l_15 = l_11 * l_14;
		float l_16 = l_14 / l_9;
		float l_17 = floor( l_16 );
		float l_18 = l_11 * l_17;
		float2 l_19 = float2( l_15, l_18 );
		float2 l_20 = l_10 + l_19;
		float4 l_21 = Tex2DS( g_tASprayNormal, g_sSampler0, l_20 );
		float2 l_22 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_23 = g_flBSprayTiles;
		float2 l_24 = l_22 * float2( l_23, l_23 );
		float2 l_25 = l_24 / float2( l_9, l_9 );
		float l_26 = 1 / l_9;
		float l_27 = g_flBSpraySpeed;
		float l_28 = g_flTime * l_27;
		float l_29 = floor( l_28 );
		float l_30 = l_26 * l_29;
		float l_31 = l_29 / l_9;
		float l_32 = floor( l_31 );
		float l_33 = l_26 * l_32;
		float2 l_34 = float2( l_30, l_33 );
		float2 l_35 = l_25 + l_34;
		float l_36 = g_flBOffset;
		float2 l_37 = TileAndOffsetUv( l_35, float2( 1, 1 ), float2( l_36, l_36 ) );
		float4 l_38 = Tex2DS( g_tBSprayNormal, g_sSampler0, l_37 );
		float4 l_39 = saturate( lerp( l_21, l_38, 0.5 ) );
		float2 l_40 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_41 = g_flRainSprayTile;
		float2 l_42 = TileAndOffsetUv( l_40, float2( l_41, l_41 ), float2( 0, 0 ) );
		float l_43 = Simplex2D( l_42 );
		float4 l_44 = saturate( lerp( l_5, l_39, l_43 ) );
		float l_45 = g_flflowingwaterspeed;
		float l_46 = g_flTime * l_45;
		float2 l_47 = TileAndOffsetUv( i.vTextureCoords.xy, float2( 1, 1 ), float2( l_46, l_46 ) );
		float4 l_48 = Tex2DS( g_tflowingwaternormal, g_sSampler0, l_47 );
		float4 l_49 = saturate( lerp( l_44, l_48, 0.07529209 ) );
		float4 l_50 = normalize( l_49 );
		
		m.Albedo = l_4.xyz;
		m.Opacity = 1;
		m.Normal = l_50.xyz;
		m.Roughness = 0.13811843;
		m.Metalness = 0;
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
