
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
	
	float3 g_vAxis < UiType( Slider ); UiStep( 1 ); UiGroup( ",0/,0/0" ); Default3( 1,1,1 ); Range3( 0,0,0, 10,10,10 ); >;
	float g_flAmplitude < UiGroup( ",0/,0/0" ); Default1( 1 ); Range1( 0, 10 ); >;
	float g_flSpeed < UiType( Slider ); UiStep( 1 ); UiGroup( ",0/,0/0" ); Default1( 1 ); Range1( 0, 10 ); >;
	float g_flFrequency < UiType( Slider ); UiStep( 1 ); UiGroup( ",0/,0/0" ); Default1( 10 ); Range1( 0, 20 ); >;
	
	PixelInput MainVs( VertexInput v )
	{
		PixelInput i = ProcessVertex( v );
		i.vPositionOs = v.vPositionOs.xyz;
		i.vColor = v.vColor;

		ExtraShaderData_t extraShaderData = GetExtraPerInstanceShaderData( v );
		i.vTintColor = extraShaderData.vTint;

		VS_DecodeObjectSpaceNormalAndTangent( v, i.vNormalOs, i.vTangentUOs_flTangentVSign );
		
		float3 l_0 = i.vPositionOs;
		float l_1 = l_0.x;
		float3 l_2 = g_vAxis;
		float l_3 = l_2.x;
		float l_4 = g_flAmplitude;
		float3 l_5 = i.vPositionOs;
		float l_6 = g_flSpeed;
		float l_7 = l_6 * g_flTime;
		float3 l_8 = l_5 + float3( l_7, l_7, l_7 );
		float l_9 = g_flFrequency;
		float3 l_10 = l_8 * float3( l_9, l_9, l_9 );
		float3 l_11 = sin( l_10 );
		float3 l_12 = float3( l_4, l_4, l_4 ) * l_11;
		float3 l_13 = float3( l_3, l_3, l_3 ) * l_12;
		float3 l_14 = float3( l_1, l_1, l_1 ) + l_13;
		float l_15 = l_0.y;
		float l_16 = l_2.y;
		float3 l_17 = float3( l_16, l_16, l_16 ) * l_12;
		float3 l_18 = float3( l_15, l_15, l_15 ) + l_17;
		float l_19 = l_0.z;
		float l_20 = l_2.z;
		float3 l_21 = float3( l_20, l_20, l_20 ) * l_12;
		float3 l_22 = float3( l_19, l_19, l_19 ) + l_21;
		float4 l_23 = float4( l_14.x, l_18.x, l_22.x, 1 );
		i.vPositionWs.xyz += l_23.xyz;
		i.vPositionPs.xyzw = Position3WsToPs( i.vPositionWs.xyz );
		
		return FinalizeVertex( i );
	}
}

PS
{
	#include "common/pixel.hlsl"
	
	float4 g_vColor < UiType( Color ); UiGroup( ",0/,0/0" ); Default4( 0.21, 1.00, 0.01, 1.00 ); >;
	
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
		
		float4 l_0 = g_vColor;
		
		m.Albedo = l_0.xyz;
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
