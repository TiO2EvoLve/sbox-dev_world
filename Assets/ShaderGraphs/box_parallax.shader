
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
	CreateInputTexture2D( Color, Srgb, 8, "None", "_color", ",0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	Texture2D g_tColor < Channel( RGBA, Box( Color ), Srgb ); OutputFormat( DXT5 ); SrgbRead( True ); >;
	float g_flDepth < UiGroup( ",0/,0/0" ); Default1( 1.222812 ); Range1( 0, 10 ); >;
	
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
		
		float4 l_0 = float4( 1, 0, 0, 1 );
		float4 l_1 = float4( 0, 0, 1, 1 );
		float3 l_2 = CalculatePositionToCameraDirWs( i.vPositionWithOffsetWs.xyz + g_vHighPrecisionLightingOffsetWs.xyz );
		float3 l_3 = Vec3WsToTs( l_2, i.vNormalWs, i.vTangentUWs, i.vTangentVWs );
		float l_4 = l_3.y;
		float l_5 = l_3.x;
		float l_6 = l_3.z;
		float3 l_7 = float3( l_4, l_5, l_6 );
		float3 l_8 = l_7 * float3( -1, -1, -1 );
		float3 l_9 = float3( 1, 0, 0 );
		float l_10 = length( l_9 );
		float3 l_11 = float3( 0, 1, 0 );
		float l_12 = length( l_11 );
		float3 l_13 = float3( 0, 0, 1 );
		float l_14 = length( l_13 );
		float3 l_15 = float3( l_10, l_12, l_14 );
		float l_16 = g_flDepth;
		float3 l_17 = float3( 1, 1, l_16 );
		float3 l_18 = l_15 * l_17;
		float3 l_19 = l_8 / l_18;
		float3 l_20 = float3( 1, 1, 1 ) / l_19;
		float3 l_21 = abs( l_20 );
		float3 l_22 = l_21 * float3( 1, 1, 1 );
		float3 l_23 = l_22 - l_20;
		float3 l_24 = abs( l_23 );
		float l_25 = l_24.x;
		float l_26 = l_24.y;
		float l_27 = min( l_25, l_26 );
		float l_28 = l_24.z;
		float l_29 = step( l_27, l_28 );
		float l_30 = step( l_25, l_26 );
		float l_31 = 1 - l_30;
		float l_32 = l_29 - l_31;
		float4 l_33 = saturate( lerp( l_0, l_1, l_32 ) );
		float3 l_34 = l_33.xyz;
		float l_35 = min( l_27, l_28 );
		float3 l_36 = l_19 * float3( l_35, l_35, l_35 );
		float3 l_37 = l_36 + float3( 1, 1, 1 );
		float4 l_38 = float4( 1, 1, 1, 1 );
		float4 l_39 = lerp( float4( l_37, 0 ), l_38, 0.5 );
		float l_40 = dot( l_34, l_39.xyz );
		float l_41 = 1 - l_40;
		float l_42 = l_37.x;
		float l_43 = step( l_42, 0 );
		float l_44 = l_43 * l_32;
		float l_45 = saturate( l_44 );
		float l_46 = lerp( l_40, l_41, l_45 );
		float4 l_47 = float4( 0, 1, 0, 1 );
		float4 l_48 = float4( 0, 0, 1, 1 );
		float l_49 = l_29 - l_30;
		float4 l_50 = saturate( lerp( l_47, l_48, l_49 ) );
		float3 l_51 = l_50.xyz;
		float l_52 = dot( l_51, l_39.xyz );
		float l_53 = 1 - l_52;
		float l_54 = l_37.y;
		float l_55 = step( l_54, 0 );
		float l_56 = l_55 * l_49;
		float l_57 = saturate( l_56 );
		float l_58 = lerp( l_52, l_53, l_57 );
		float2 l_59 = float2( l_46, l_58);
		float2 l_60 = TileAndOffsetUv( l_59, float2( 0.333, 0.333 ), float2( 0.333, 0.333 ) );
		float2 l_61 = TileAndOffsetUv( l_59, float2( 0.333, 0.3333 ), float2( 0, 0.333 ) );
		float2 l_62 = TileAndOffsetUv( l_59, float2( 0.333, 0.333 ), float2( 0.666, 0.333 ) );
		float3 l_63 = float3( 0, 0, 0 );
		float4 l_64 = l_39 - float4( l_63, 0 );
		float l_65 = l_64.x;
		float2 l_66 = saturate( lerp( l_61, l_62, l_65 ) );
		float2 l_67 = TileAndOffsetUv( l_59, float2( 0.333, 0.333 ), float2( 0.333, 0 ) );
		float2 l_68 = TileAndOffsetUv( l_59, float2( 0.333, 0.333 ), float2( 0.333, 0.666 ) );
		float l_69 = l_64.y;
		float2 l_70 = saturate( lerp( l_67, l_68, l_69 ) );
		float l_71 = 1 - l_32;
		float l_72 = saturate( l_71 );
		float2 l_73 = saturate( lerp( l_66, l_70, l_72 ) );
		float2 l_74 = saturate( lerp( l_60, l_73, l_29 ) );
		float2 l_75 = frac( l_74 );
		float l_76 = l_75.y;
		float l_77 = l_75.x;
		float2 l_78 = float2( l_76, l_77);
		float4 l_79 = Tex2DS( g_tColor, g_sSampler0, l_78 );
		
		m.Albedo = l_79.xyz;
		m.Opacity = 1;
		m.Roughness = 1;
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
