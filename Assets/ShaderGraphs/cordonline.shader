
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
	
	float4 g_vColorA < UiType( Color ); UiGroup( ",0/,0/0" ); Default4( 0.15, 0.08, 0.00, 1.00 ); >;
	float4 g_vColorB < UiType( Color ); UiGroup( ",0/,0/0" ); Default4( 0.86, 0.24, 0.00, 1.00 ); >;
	float g_flratio < UiGroup( ",0/,0/0" ); Default1( 0.5 ); Range1( 0, 1 ); >;
	float2 g_vController < UiGroup( ",0/,0/0" ); Default2( 11.7,10 ); Range2( 0,0, 100,100 ); >;
	float g_fldecal < UiGroup( ",0/,0/0" ); Default1( 0.7634363 ); Range1( 0, 10 ); >;
	float g_flMetal < UiGroup( ",0/,0/0" ); Default1( 0.7634363 ); Range1( 0, 1 ); >;
	
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
		float l_2 = g_flratio;
		float2 l_3 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_4 = g_vController;
		float l_5 = dot( l_3, l_4 );
		float l_6 = frac( l_5 );
		float l_7 = step( l_2, l_6 );
		float4 l_8 = lerp( l_0, l_1, l_7 );
		float l_9 = FuzzyNoise( i.vTextureCoords.xy );
		float l_10 = g_fldecal;
		float l_11 = l_9 * l_10;
		float l_12 = g_flMetal;
		
		m.Albedo = l_8.xyz;
		m.Opacity = 1;
		m.Roughness = l_11;
		m.Metalness = l_12;
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
