
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
	
	float4 g_vColorB < UiType( Color ); UiGroup( ",0/,0/0" ); Default4( 0.00, 1.00, 0.83, 1.00 ); >;
	float4 g_vColorA < UiType( Color ); UiGroup( ",0/,0/0" ); Default4( 0.00, 1.00, 0.68, 1.00 ); >;
	float2 g_vScale < UiGroup( ",0/,0/0" ); Default2( 0,9.363 ); Range2( 0,0, 20,20 ); >;
	float g_flSpeed < UiGroup( ",0/,0/0" ); Default1( 0.5888093 ); Range1( 0, 1 ); >;
	float2 g_vMix < UiGroup( ",0/,0/0" ); Default2( 0,1 ); Range2( 0,0, 1,1 ); >;
	
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
		
		float4 l_0 = g_vColorB;
		float4 l_1 = g_vColorA;
		float3 l_2 = pow( 1.0 - dot( normalize( i.vNormalWs ), normalize( CalculatePositionToCameraDirWs( i.vPositionWithOffsetWs.xyz + g_vHighPrecisionLightingOffsetWs.xyz ) ) ), 10 );
		float2 l_3 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_4 = g_vScale;
		float2 l_5 = float2( l_4.x, l_4.y);
		float l_6 = g_flSpeed;
		float l_7 = g_flTime * l_6;
		float2 l_8 = float2( l_7, 0);
		float2 l_9 = TileAndOffsetUv( l_3, l_5, l_8 );
		float l_10 = Simplex2D( l_9 );
		float3 l_11 = pow( 1.0 - dot( normalize( i.vNormalWs ), normalize( CalculatePositionToCameraDirWs( i.vPositionWithOffsetWs.xyz + g_vHighPrecisionLightingOffsetWs.xyz ) ) ), l_10 );
		float3 l_12 = lerp( l_2, l_11, 0.25323752 );
		float2 l_13 = g_vMix;
		float3 l_14 = saturate( ( l_12 - float3( 0, 0, 0 ) ) / ( float3( 1, 1, 1 ) - float3( 0, 0, 0 ) ) ) * ( float3( l_13.y, l_13.y, l_13.y ) - float3( l_13.x, l_13.x, l_13.x ) ) + float3( l_13.x, l_13.x, l_13.x );
		float4 l_15 = lerp( l_0, l_1, float4( l_14, 0 ) );
		
		m.Albedo = l_15.xyz;
		m.Opacity = l_14.x;
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
