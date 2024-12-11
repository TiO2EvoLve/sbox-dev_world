
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
	#define S_TRANSLUCENT 1
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
	
	float2 g_vWaveTile < UiType( Slider ); UiGroup( "Wave,0/,0/0" ); Default2( 5,5 ); Range2( 1,1, 10,10 ); >;
	float g_flWaveSpeed < UiGroup( "Wave,2/,0/0" ); Default1( 1 ); Range1( 1, 10 ); >;
	float g_flWavePower < UiGroup( "Wave,2/,0/0" ); Default1( 0.5 ); Range1( 0, 10 ); >;
	
	PixelInput MainVs( VertexInput v )
	{
		PixelInput i = ProcessVertex( v );
		i.vPositionOs = v.vPositionOs.xyz;
		i.vColor = v.vColor;

		ExtraShaderData_t extraShaderData = GetExtraPerInstanceShaderData( v );
		i.vTintColor = extraShaderData.vTint;

		VS_DecodeObjectSpaceNormalAndTangent( v, i.vNormalOs, i.vTangentUOs_flTangentVSign );
		
		float2 l_0 = i.vTextureCoords.xy * float2( 1, 1 );
		float2 l_1 = g_vWaveTile;
		float l_2 = g_flWaveSpeed;
		float l_3 = l_2 * g_flTime;
		float2 l_4 = TileAndOffsetUv( l_0, l_1, float2( l_3, l_3 ) );
		float l_5 = Simplex2D( l_4 );
		float l_6 = g_flWavePower;
		float l_7 = saturate( ( l_5 - 0 ) / ( 1 - 0 ) ) * ( l_6 - 0 ) + 0;
		float3 l_8 = i.vNormalOs * float3( l_7, l_7, l_7 );
		float3 l_9 = i.vPositionOs;
		float3 l_10 = l_8 + l_9;
		i.vPositionWs.xyz += l_10;
		i.vPositionPs.xyzw = Position3WsToPs( i.vPositionWs.xyz );
		
		return FinalizeVertex( i );
	}
}

PS
{
	#include "common/pixel.hlsl"
	
	float4 g_vBaseColor < UiType( Color ); UiGroup( "Color,0/,0/0" ); Default4( 0.00, 0.20, 0.72, 1.00 ); >;
	float g_flWaveletSpeed < UiType( Slider ); UiStep( 1 ); UiGroup( "Wavelet,0/,0/0" ); Default1( 1 ); Range1( 1, 10 ); >;
	float g_flWaveletDensity < UiType( Slider ); UiStep( 1 ); UiGroup( "Wavelet,0/,0/0" ); Default1( 18.323002 ); Range1( 1, 20 ); >;
	float g_flWaveletDistance < UiType( Slider ); UiStep( 1 ); UiGroup( "Wavelet,0/,0/0" ); Default1( 4.9549303 ); Range1( 1, 10 ); >;
	float4 g_vWaveletColor < UiType( Color ); UiGroup( "Wavelet,0/,0/0" ); Default4( 0.53, 0.82, 0.99, 1.00 ); >;
	float g_flOpacity < UiType( Slider ); UiGroup( "PBR,0/,0/0" ); Default1( 0.46967936 ); Range1( 0, 1 ); >;
	float g_flRoughness < UiType( Slider ); UiGroup( "PBR,0/,0/0" ); Default1( 0.98332614 ); Range1( 0, 1 ); >;
	
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
		
		float4 l_0 = g_vBaseColor;
		float l_1 = g_flWaveletSpeed;
		float l_2 = g_flTime * l_1;
		float l_3 = g_flWaveletDensity;
		float l_4 = VoronoiNoise( i.vTextureCoords.xy, l_2, l_3 );
		float l_5 = g_flWaveletDistance;
		float l_6 = pow( l_4, l_5 );
		float4 l_7 = g_vWaveletColor;
		float4 l_8 = float4( l_6, l_6, l_6, l_6 ) * l_7;
		float4 l_9 = l_0 + l_8;
		float l_10 = g_flOpacity;
		float l_11 = g_flRoughness;
		
		m.Albedo = l_9.xyz;
		m.Emission = l_9.xyz;
		m.Opacity = l_10;
		m.Roughness = l_11;
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
