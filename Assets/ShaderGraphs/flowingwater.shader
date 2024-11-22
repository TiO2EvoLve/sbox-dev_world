
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
	
	float4 g_vColorA < UiType( Color ); UiGroup( ",0/,0/0" ); Default4( 0.15, 0.00, 1.00, 1.00 ); >;
	float4 g_vColorB < UiType( Color ); UiGroup( ",0/,0/0" ); Default4( 0.00, 0.63, 0.85, 1.00 ); >;
	float g_flthickness < UiGroup( ",0/,0/0" ); Default1( 50 ); Range1( 0, 50 ); >;
	float g_flSpeed < UiGroup( ",0/,0/0" ); Default1( 1.3403363 ); Range1( 0, 10 ); >;
	float g_flmin < UiGroup( ",0/,0/0" ); Default1( -1.5623386 ); Range1( -2, 2 ); >;
	float g_flmax < UiGroup( ",0/,0/0" ); Default1( 1.167939 ); Range1( -2, 2 ); >;
	float g_flbrightness < UiGroup( ",0/,0/0" ); Default1( 2.9553432 ); Range1( 0, 10 ); >;
	
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
		
		float4 l_0 = g_vColorA;
		float4 l_1 = g_vColorB;
		float2 l_2 = i.vTextureCoords.xy * float2( 1, 1 );
		float l_3 = l_2.x;
		float l_4 = g_flthickness;
		float l_5 = l_3 * l_4;
		float l_6 = l_2.y;
		float4 l_7 = float4( l_5, l_6, 0, 0 );
		float l_8 = g_flSpeed;
		float l_9 = g_flTime * l_8;
		float4 l_10 = float4( 0, l_9, 0, 0 );
		float2 l_11 = TileAndOffsetUv( l_7.xy, float2( 1, 1 ), l_10.xy );
		float l_12 = 1.0f - VoronoiNoise( l_11, 6.28, 5.82 );
		float l_13 = l_2.x;
		float l_14 = 1 - l_13;
		float l_15 = g_flmin;
		float l_16 = g_flmax;
		float l_17 = saturate( ( l_14 - 0 ) / ( 1 - 0 ) ) * ( l_16 - l_15 ) + l_15;
		float l_18 = saturate( ( l_13 - 0 ) / ( 1 - 0 ) ) * ( l_16 - l_15 ) + l_15;
		float l_19 = l_17 * l_18;
		float l_20 = l_19 * 50;
		float l_21 = l_12 * l_20;
		float4 l_22 = saturate( lerp( l_0, l_1, l_21 ) );
		float l_23 = g_flbrightness;
		float4 l_24 = l_22 * float4( l_23, l_23, l_23, l_23 );
		float l_25 = 1 - l_21;
		
		m.Albedo = l_22.xyz;
		m.Emission = l_24.xyz;
		m.Opacity = l_21;
		m.Roughness = l_25;
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
