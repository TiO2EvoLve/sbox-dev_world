
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
	CreateInputTexture2D( BaseTexture, Srgb, 8, "None", "_color", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( MicroTilingBasetexture, Srgb, 8, "None", "_color", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( BaseNormal, Srgb, 8, "None", "_normal", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( MicroTilingNormal, Srgb, 8, "None", "_normal", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( BaseRougness, Srgb, 8, "None", "_rough", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( MicroTilingRougness, Srgb, 8, "None", "_rough", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( BaseAO, Srgb, 8, "None", "_ao", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( MicroTilingAO, Srgb, 8, "None", "_ao", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	Texture2D g_tBaseTexture < Channel( RGBA, Box( BaseTexture ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tMicroTilingBasetexture < Channel( RGBA, Box( MicroTilingBasetexture ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBaseNormal < Channel( RGBA, Box( BaseNormal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tMicroTilingNormal < Channel( RGBA, Box( MicroTilingNormal ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBaseRougness < Channel( RGBA, Box( BaseRougness ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tMicroTilingRougness < Channel( RGBA, Box( MicroTilingRougness ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tBaseAO < Channel( RGBA, Box( BaseAO ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	Texture2D g_tMicroTilingAO < Channel( RGBA, Box( MicroTilingAO ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	float g_flNoiseContrast < UiGroup( ",0/,0/0" ); Default1( 0.885253 ); Range1( 0, 1 ); >;
	float g_flNoiseParameter < UiGroup( ",0/,0/0" ); Default1( 19.76912 ); Range1( 0, 50 ); >;
	float g_flTilingamount < UiGroup( ",0/,0/0" ); Default1( 1 ); Range1( 0, 50 ); >;
	float4 g_vColorTint < UiType( Color ); UiGroup( ",0/,0/0" ); Default4( 1.00, 1.00, 1.00, 1.00 ); >;
	float g_flMicrotilingamount < UiGroup( ",0/,0/0" ); Default1( 1 ); Range1( 0, 50 ); >;
	float4 g_vMicroTilingTint < UiType( Color ); UiGroup( ",0/,0/0" ); Default4( 0.98, 1.00, 0.67, 1.00 ); >;
	float g_flMicrotilingmaskscale < UiGroup( ",0/,0/0" ); Default1( 15.431939 ); Range1( 0, 50 ); >;
	
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
		
		float l_0 = g_flNoiseContrast;
		float2 l_1 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_2 = g_flNoiseParameter;
		float2 l_3 = l_1 * float2( l_2, l_2 );
		float l_4 = ValueNoise( l_3 );
		float l_5 = l_4.x;
		float l_6 = l_5 + 0.5;
		float2 l_7 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_8 = g_flNoiseParameter;
		float2 l_9 = l_7 * float2( l_8, l_8 );
		float l_10 = ValueNoise( l_9 );
		float l_11 = l_10.x;
		float l_12 = l_11 + 0.5;
		float l_13 = l_6 * l_12;
		float l_14 = lerp( l_0, 1, l_13 );
		float2 l_15 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_16 = g_flTilingamount;
		float2 l_17 = l_15 * float2( l_16, l_16 );
		float4 l_18 = Tex2DS( g_tBaseTexture, g_sSampler0, l_17 );
		float4 l_19 = g_vColorTint;
		float4 l_20 = l_18 * l_19;
		float2 l_21 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_22 = g_flMicrotilingamount;
		float2 l_23 = l_21 * float2( l_22, l_22 );
		float l_24 = l_23.y;
		float l_25 = l_23.x;
		float l_26 = 0.0f;
		float4 l_27 = float4( l_24, l_25, l_26, 0 );
		float4 l_28 = Tex2DS( g_tMicroTilingBasetexture, g_sSampler0, l_27.xy );
		float4 l_29 = g_vMicroTilingTint;
		float4 l_30 = l_28 * l_29;
		float2 l_31 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_32 = g_flMicrotilingmaskscale;
		float2 l_33 = l_31 * float2( l_32, l_32 );
		float l_34 = ValueNoise( l_33 );
		float4 l_35 = lerp( l_20, l_30, l_34 );
		float4 l_36 = float4( l_14, l_14, l_14, l_14 ) * l_35;
		float2 l_37 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_38 = l_37 * float2( l_16, l_16 );
		float4 l_39 = Tex2DS( g_tBaseNormal, g_sSampler0, l_38 );
		float2 l_40 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_41 = l_40 * float2( l_22, l_22 );
		float l_42 = l_41.y;
		float l_43 = l_41.x;
		float l_44 = 0.0f;
		float4 l_45 = float4( l_42, l_43, l_44, 0 );
		float4 l_46 = Tex2DS( g_tMicroTilingNormal, g_sSampler0, l_45.xy );
		float4 l_47 = lerp( l_39, l_46, l_34 );
		float2 l_48 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_49 = l_48 * float2( l_16, l_16 );
		float4 l_50 = Tex2DS( g_tBaseRougness, g_sSampler0, l_49 );
		float2 l_51 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_52 = l_51 * float2( l_22, l_22 );
		float l_53 = l_52.y;
		float l_54 = l_52.x;
		float l_55 = 0.0f;
		float4 l_56 = float4( l_53, l_54, l_55, 0 );
		float4 l_57 = Tex2DS( g_tMicroTilingRougness, g_sSampler0, l_56.xy );
		float4 l_58 = lerp( l_50, l_57, l_34 );
		float2 l_59 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_60 = l_59 * float2( l_16, l_16 );
		float4 l_61 = Tex2DS( g_tBaseAO, g_sSampler0, l_60 );
		float2 l_62 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_63 = l_62 * float2( l_22, l_22 );
		float l_64 = l_63.y;
		float l_65 = l_63.x;
		float l_66 = 0.0f;
		float4 l_67 = float4( l_64, l_65, l_66, 0 );
		float4 l_68 = Tex2DS( g_tMicroTilingAO, g_sSampler0, l_67.xy );
		float4 l_69 = lerp( l_61, l_68, l_34 );
		
		m.Albedo = l_36.xyz;
		m.Opacity = 1;
		m.Normal = l_47.xyz;
		m.Roughness = l_58.x;
		m.Metalness = 0;
		m.AmbientOcclusion = l_69.x;
		
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
