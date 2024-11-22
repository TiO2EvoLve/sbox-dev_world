
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
		float3 l_2 = float3( 1, 1, 1 );
		float3 l_3 = CalculatePositionToCameraDirWs( i.vPositionWithOffsetWs.xyz + g_vHighPrecisionLightingOffsetWs.xyz );
		float3 l_4 = Vec3WsToTs( l_3, i.vNormalWs, i.vTangentUWs, i.vTangentVWs );
		float l_5 = l_4.y;
		float l_6 = l_4.x;
		float l_7 = l_4.z;
		float4 l_8 = float4( l_5, l_6, l_7, 0 );
		float4 l_9 = l_8 * float4( -1, -1, -1, -1 );
		float3 l_10 = float3( 1, 0, 0 );
		float l_11 = length( l_10 );
		float3 l_12 = float3( 0, 1, 0 );
		float l_13 = length( l_12 );
		float3 l_14 = float3( 0, 0, 1 );
		float l_15 = length( l_14 );
		float4 l_16 = float4( l_11, l_13, l_15, 0 );
		float l_17 = g_flDepth;
		float4 l_18 = float4( 1, 1, l_17, 0 );
		float4 l_19 = l_16 * l_18;
		float4 l_20 = l_9 / l_19;
		float4 l_21 = float4( l_2, 0 ) / l_20;
		float4 l_22 = abs( l_21 );
		float2 l_23 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_24 = frac( l_23 );
		float2 l_25 = l_24 * float2( 2, 2 );
		float3 l_26 = float3( l_25, 0 );
		float3 l_27 = float3( -1, -1, 1 );
		float3 l_28 = l_26 + l_27;
		float l_29 = l_28.y;
		float l_30 = l_28.x;
		float l_31 = l_28.z;
		float4 l_32 = float4( l_29, l_30, l_31, 0 );
		float4 l_33 = l_22 * l_32;
		float4 l_34 = l_33 - l_21;
		float4 l_35 = abs( l_34 );
		float l_36 = l_35.x;
		float l_37 = l_35.y;
		float l_38 = min( l_36, l_37 );
		float l_39 = l_35.z;
		float l_40 = step( l_38, l_39 );
		float l_41 = step( l_36, l_37 );
		float l_42 = 1 - l_41;
		float l_43 = l_40 - l_42;
		float4 l_44 = saturate( lerp( l_0, l_1, l_43 ) );
		float3 l_45 = l_44.xyz;
		float l_46 = min( l_38, l_39 );
		float4 l_47 = l_20 * float4( l_46, l_46, l_46, l_46 );
		float4 l_48 = l_47 + l_32;
		float4 l_49 = float4( 1, 1, 1, 1 );
		float4 l_50 = lerp( l_48, l_49, 0.5 );
		float l_51 = dot( l_45, l_50.xyz );
		float l_52 = 1 - l_51;
		float l_53 = l_48.x;
		float l_54 = step( l_53, 0 );
		float l_55 = l_54 * l_43;
		float l_56 = saturate( l_55 );
		float l_57 = lerp( l_51, l_52, l_56 );
		float4 l_58 = float4( 0, 1, 0, 1 );
		float4 l_59 = float4( 0, 0, 1, 1 );
		float l_60 = l_40 - l_41;
		float4 l_61 = saturate( lerp( l_58, l_59, l_60 ) );
		float3 l_62 = l_61.xyz;
		float l_63 = dot( l_62, l_50.xyz );
		float l_64 = 1 - l_63;
		float l_65 = l_48.y;
		float l_66 = step( l_65, 0 );
		float l_67 = l_66 * l_60;
		float l_68 = saturate( l_67 );
		float l_69 = lerp( l_63, l_64, l_68 );
		float4 l_70 = float4( l_57, l_69, 0, 0 );
		float2 l_71 = TileAndOffsetUv( l_70.xy, float2( 0.333, 0.333 ), float2( 0.333, 0.333 ) );
		float2 l_72 = TileAndOffsetUv( l_70.xy, float2( 0.333, 0.3333 ), float2( 0, 0.333 ) );
		float2 l_73 = TileAndOffsetUv( l_70.xy, float2( 0.333, 0.333 ), float2( 0.666, 0.333 ) );
		float3 l_74 = float3( 0, 0, 0 );
		float4 l_75 = l_50 - float4( l_74, 0 );
		float l_76 = l_75.x;
		float2 l_77 = saturate( lerp( l_72, l_73, l_76 ) );
		float2 l_78 = TileAndOffsetUv( l_70.xy, float2( 0.333, 0.333 ), float2( 0.333, 0 ) );
		float2 l_79 = TileAndOffsetUv( l_70.xy, float2( 0.333, 0.333 ), float2( 0.333, 0.666 ) );
		float l_80 = l_75.y;
		float2 l_81 = saturate( lerp( l_78, l_79, l_80 ) );
		float l_82 = 1 - l_43;
		float l_83 = saturate( l_82 );
		float2 l_84 = saturate( lerp( l_77, l_81, l_83 ) );
		float2 l_85 = saturate( lerp( l_71, l_84, l_40 ) );
		float2 l_86 = frac( l_85 );
		float l_87 = l_86.y;
		float l_88 = l_86.x;
		float4 l_89 = float4( l_87, l_88, 0, 0 );
		float4 l_90 = Tex2DS( g_tColor, g_sSampler0, l_89.xy );
		
		m.Albedo = l_90.xyz;
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
