//Element that use this shader will have triangle transformation on the geometry shaders pass.
//This shader support most Standard Forward Rendering functionality of Unity
Shader "Custom/LevelElementTriangulator"
{
	Properties
	{
		//Controller Power by Game
		_PlayerWorldPosition("PlayerWorldPosition", Vector) = (0,0,0,1)
		_HasWhistled("HasWhistled", Int) = 0 //Bool, 0 = false, 1 = true
		_WhistleTimeInfluence("WhistleTimeInfluence", Float) = 1
		_RadiusInfluence("RadiusInfluence", Float) = 4

		//TRIANGLE DISPLACEMENT - IMPULSE
		_DispFactorMax("DisplacementFactorMax", Float) = 0.35
		_DispFactorMin("DisplacementFactorMax", Float) = 0.05
		_EnableReprojectCasting("EnableReprojectCasting", Int) = 0 //Bool, 0 = false, 1 = true

		//VISUALS
		_Color("Color", Color) = (1,1,1,1)

		//STANDARD PROPERITIES BUILT-IN --- We Disable the possibility to adjust in editor
		[HideInInspector] _MainTex("Albedo", 2D) = "white" {}
		[HideInInspector] _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
		[HideInInspector] 
		[HideInInspector] _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		[HideInInspector] _GlossMapScale("Smoothness Factor", Range(0.0, 1.0)) = 1.0
		[HideInInspector] [Enum(Specular Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel("Smoothness texture channel", Float) = 0
		[HideInInspector] 
		[HideInInspector] _SpecColor("Specular", Color) = (0.2,0.2,0.2)
		[HideInInspector] _SpecGlossMap("Specular", 2D) = "white" {}
		[HideInInspector] [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[HideInInspector] [ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0
		[HideInInspector] 
		[HideInInspector] _BumpScale("Scale", Float) = 1.0
		[HideInInspector] _BumpMap("Normal Map", 2D) = "bump" {}
		[HideInInspector] 
		[HideInInspector] _Parallax("Height Scale", Range(0.005, 0.08)) = 0.02
		[HideInInspector] _ParallaxMap("Height Map", 2D) = "black" {}
		[HideInInspector] 
		[HideInInspector] _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _OcclusionMap("Occlusion", 2D) = "white" {}
		[HideInInspector] 
		[HideInInspector] _EmissionColor("Color", Color) = (0,0,0)
		[HideInInspector] _EmissionMap("Emission", 2D) = "white" {}
		[HideInInspector] 
		[HideInInspector] _DetailMask("Detail Mask", 2D) = "white" {}
		[HideInInspector] 
		[HideInInspector] _DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
		[HideInInspector] _DetailNormalMapScale("Scale", Float) = 1.0
		[HideInInspector] _DetailNormalMap("Normal Map", 2D) = "bump" {}
		[HideInInspector] 
		[HideInInspector] [Enum(UV0,0,UV1,1)] _UVSec("UV Set for secondary textures", Float) = 0
	}

	SubShader
	{
		Tags
		{
			"Queue" = "AlphaTest" "IgnoreProjector" = "True"
			"DisableBatching" = "True"
		}
		LOD 100

		Pass
		{
			Tags{ "LightMode" = "Always" }
			ZWrite On
		
			CGPROGRAM
			#pragma vertex vertBlack  
			#pragma fragment fragBlack
			#include "UnityCG.cginc"
		
			struct v2f 
			{
				float4 pos : SV_POSITION;
			};
		
			v2f vertBlack(appdata_base v)
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);
		
				float4 npos = v.vertex; 
				npos.xyz -= v.normal * 0.002f;
				o.pos = mul(UNITY_MATRIX_MVP, npos);
				return o;
			}
		
			half4 fragBlack(v2f i) : SV_TARGET
			{
				return half4(0, 0, 0, 1);
			}
		
			ENDCG
		}

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			Blend One Zero
			ZWrite On

			CGPROGRAM
			#pragma target 4.0
			#pragma vertex vertCustomBase        
			#pragma geometry geomCustomBase
			#pragma fragment fragCustomBase
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase //nolightmap nodirlightmap nodynlightmap novertexlight
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature ___ _DETAIL_MULX2

			#include "UnityStandardInput.cginc" //VertexInput
			#include "UnityStandardCore.cginc" //VertexGIForward

			#include "AutoLight.cginc"
			#include "UnityCG.cginc"				//for SHADOW macros
			#include "UnityLightingCommon.cginc"	//for _LightColor0
			#include "DAECustomCG.cginc"			//for Custom Functions
			
			//float4 _Color;
			float4 _PlayerWorldPosition;
			float _DispFactorMin;
			float _DispFactorMax;
			int _HasWhistled;
			float _WhistleTimeInfluence;
			float _RadiusInfluence;

			struct VertexOutputForwardBaseExtended
			{
				float4 pos							: SV_POSITION;
				float4 tex							: TEXCOORD0;
				half3 eyeVec 						: TEXCOORD1;
				half4 tangentToWorldAndParallax[3]	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:viewDirForParallax]
				half4 ambientOrLightmapUV			: TEXCOORD5;	// SH or Lightmap UV
				SHADOW_COORDS(6)
				UNITY_FOG_COORDS(7)

				// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
				#if UNITY_SPECCUBE_BOX_PROJECTION || UNITY_LIGHT_PROBE_PROXY_VOLUME
					float3 posWorld					: TEXCOORD8;
				#endif

				#if UNITY_OPTIMIZE_TEXCUBELOD
					#if UNITY_SPECCUBE_BOX_PROJECTION
						half3 reflUVW				: TEXCOORD9;
					#else
						half3 reflUVW				: TEXCOORD8;
					#endif
				#endif

				UNITY_VERTEX_OUTPUT_STEREO

				float4 originalPos				: TEXCOORD10;
				float4 color					: TEXCOORD11;
				float3 norm						: NORMAL;
			};
	
			#define UNIFORM_REFLECTIVITY JOIN(UNITY_SETUP_BRDF_INPUT, _Reflectivity)

			VertexOutputForwardBaseExtended vertCustomBase(VertexInput v)
			{
				UNITY_SETUP_INSTANCE_ID(v);
				VertexOutputForwardBaseExtended o;
				UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBaseExtended, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.originalPos = posWorld;

				//Standard Base Calculations - vertForwardBase
				#if UNITY_SPECCUBE_BOX_PROJECTION || UNITY_LIGHT_PROBE_PROXY_VOLUME
					o.posWorld = posWorld.xyz;
				#endif
					
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, posWorld));//mul(UNITY_MATRIX_MVP, mul(unity_WorldToObject, posWorld));
				o.tex = TexCoords(v);
				o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				o.norm = v.normal;

				#ifdef _TANGENT_TO_WORLD
					float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

					float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
					o.tangentToWorldAndParallax[0].xyz = tangentToWorld[0];
					o.tangentToWorldAndParallax[1].xyz = tangentToWorld[1];
					o.tangentToWorldAndParallax[2].xyz = tangentToWorld[2];
				#else
					o.tangentToWorldAndParallax[0].xyz = 0;
					o.tangentToWorldAndParallax[1].xyz = 0;
					o.tangentToWorldAndParallax[2].xyz = normalWorld;
				#endif
				//We need this for shadow receving
				TRANSFER_SHADOW(o);

				o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);

				#ifdef _PARALLAXMAP
					TANGENT_SPACE_ROTATION;
					half3 viewDirForParallax = mul(rotation, ObjSpaceViewDir(v.vertex));
					o.tangentToWorldAndParallax[0].w = viewDirForParallax.x;
					o.tangentToWorldAndParallax[1].w = viewDirForParallax.y;
					o.tangentToWorldAndParallax[2].w = viewDirForParallax.z;
				#endif

				#if UNITY_OPTIMIZE_TEXCUBELOD
					o.reflUVW = reflect(o.eyeVec, normalWorld);
				#endif

				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}

			[maxvertexcount(3)]
			void geomCustomBase(triangle VertexOutputForwardBaseExtended IN[3], inout TriangleStream<VertexOutputForwardBaseExtended> triStream)
			{
				//COLOR
				float4 p1 = IN[0].originalPos, p2 = IN[1].originalPos, p3 = IN[2].originalPos;
				float v1 = abs(p1.x + p1.z + p2.x);
				float v2 = abs(p2.z + p3.x + p3.z);
				uint s = WangHash(v1 * v2);
				float colorGrade = RedistributeUINTtoFLOAT(0.95f, 1.0f, s);

				VertexOutputForwardBaseExtended pIn;
				UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBaseExtended, pIn);
				pIn.color = float4(colorGrade, colorGrade, colorGrade, 1.0f);

				for (int i = 0; i < 3; ++i)
				{
					//DISP
					if(!_HasWhistled)
						pIn.pos = IN[i].pos;
					else
					{
						float currentDistance = distance(_PlayerWorldPosition, IN[i].originalPos);
						if (currentDistance <= _RadiusInfluence)
						{
							float totalInfluenceDistance = abs(currentDistance / _RadiusInfluence - 1);
							float rotSeed = Rand(v1 * v2) * 45.0f;
							//roll (z) * pitch (y) * yaw (x)
							float4x4 rollMat = CreateRotationMatrixFromAxisAndAngle(float3(0, 0, 1), radians(rotSeed));
							float4x4 pitchMat = CreateRotationMatrixFromAxisAndAngle(float3(0, 1, 0), radians(rotSeed));
							float4x4 yawMat = CreateRotationMatrixFromAxisAndAngle(float3(1, 0, 0), radians(rotSeed));
							float3 rotNorm = mul(rollMat * pitchMat * yawMat, IN[i].norm);
							float dispFactor = Rand(IN[i].originalPos);
							dispFactor = (_DispFactorMax - _DispFactorMin)*(dispFactor - 0.0f) / 1.0f + _DispFactorMin;
							float4 disp = IN[i].originalPos;
							disp.xyz += rotNorm * ((dispFactor * totalInfluenceDistance) * _WhistleTimeInfluence);
							pIn.pos = mul(UNITY_MATRIX_MVP, mul(unity_WorldToObject, disp));
						}
						else
							pIn.pos = IN[i].pos;
					}

					pIn.tex = IN[i].tex;
					pIn.eyeVec = IN[i].eyeVec;
					pIn.tangentToWorldAndParallax = IN[i].tangentToWorldAndParallax;
					pIn.ambientOrLightmapUV = IN[i].ambientOrLightmapUV;
					#if UNITY_SPECCUBE_BOX_PROJECTION || UNITY_LIGHT_PROBE_PROXY_VOLUME
						pIn.posWorld = IN[i].posWorld;
					#endif
					#if UNITY_OPTIMIZE_TEXCUBELOD
						pIn.reflUVW = IN[i].reflUVW;
					#endif
					TRANSFER_SHADOW(pIn);
					UNITY_TRANSFER_FOG(pIn, pIn.pos);
					triStream.Append(pIn);
				}
			}
	
			half4 fragCustomBase(VertexOutputForwardBaseExtended i) : SV_Target
			{
				FRAGMENT_SETUP(s)
				#if UNITY_OPTIMIZE_TEXCUBELOD
					s.reflUVW = i.reflUVW;
				#endif

				UnityLight mainLight = MainLight(s.normalWorld);
				half atten = SHADOW_ATTENUATION(i);


				half occlusion = Occlusion(i.tex.xy);
				UnityGI gi = FragmentGI(s, occlusion, i.ambientOrLightmapUV, atten, mainLight);

				half4 c = UNITY_BRDF_PBS(s.diffColor * i.color, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, gi.light, gi.indirect);
				c.rgb += UNITY_BRDF_GI(s.diffColor * i.color, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, occlusion, gi);
				c.rgb += Emission(i.tex.xy);

				UNITY_APPLY_FOG(i.fogCoord, c.rgb);
				return OutputForward(c, s.alpha);
			}
		
			ENDCG
		}
		Pass
		{
			Tags{ "LightMode" = "ForwardAdd" }
			Blend One One
			Fog{ Color(0,0,0,0) } // in additive pass fog should be black
			ZWrite Off
			ZTest LEqual
		
			CGPROGRAM
			#pragma target 4.0
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma shader_feature ___ _DETAIL_MULX2
			
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			
			#pragma vertex vertAddExtended
			#pragma geometry geomAddExtended
			#pragma fragment fragAddExtended
			#include "UnityCG.cginc"
			#include "UnityStandardCore.cginc"
			#include "UnityStandardInput.cginc" //VertexInput
			#include "DAECustomCG.cginc"		//for Custom Functions


			//Variables
			float4 _PlayerWorldPosition;
			float _DispFactorMin;
			float _DispFactorMax;
			int _HasWhistled;
			float _WhistleTimeInfluence;
			float _RadiusInfluence;
		
			struct VertexOutputForwardAddExtended //Based on VertexOutputForwardAddSimple
			{
				float4 pos							: SV_POSITION;
				float4 tex							: TEXCOORD0;
				half3 eyeVec 						: TEXCOORD1;
				half4 tangentToWorldAndLightDir[3]	: TEXCOORD2;	// [3x3:tangentToWorld | 1x3:lightDir]
				
				//--------------------------------------------
				// CODE BELOW == LIGHTING_COORDS(5, 6)
				//LightCoord type based on light type
				#if defined (POINT) || defined (POINT_COOKIE) 
					unityShadowCoord3 _LightCoord : TEXCOORD5;
					#define LIGHTCOORD_USED
				#elif defined (SPOT)
					unityShadowCoord4 _LightCoord : TEXCOORD5;
					#define LIGHTCOORD_USED
				#elif defined (DIRECTIONAL_COOKIE)
					unityShadowCoord2 _LightCoord : TEXCOORD5;
					#define LIGHTCOORD_USED
				#endif

				#if defined(DIRECTIONAL) 
					unityShadowCoord4 _ShadowCoord : TEXCOORD5;
				#define SHADOWCOORD_USED
				#else
					//ShadowCoord type based on light type
					#if defined (SHADOWS_DEPTH) && defined (SPOT)
						unityShadowCoord4 _ShadowCoord : TEXCOORD6;
						#define SHADOWCOORD_USED
					#elif defined (SHADOWS_CUBE)
						unityShadowCoord3 _ShadowCoord : TEXCOORD6; //unityShadowCoord3
						#define SHADOWCOORD_USED
					#elif !defined (SHADOWS_SCREEN) && !defined (SHADOWS_DEPTH) && !defined (SHADOWS_CUBE)
						unityShadowCoord4 _ShadowCoord : TEXCOORD6;
						#define SHADOWCOORD_USED
					#else
						unityShadowCoord4 _ShadowCoord : TEXCOORD6;
						#define SHADOWCOORD_USED
					#endif
				#endif
				//--------------------------------------------

				UNITY_FOG_COORDS(7)
				// next ones would not fit into SM2.0 limits, but they are always for SM3.0+
				#if defined(_PARALLAXMAP)
					half3 viewDirForParallax			: TEXCOORD8;
				#endif
				UNITY_VERTEX_OUTPUT_STEREO
		
				float4 originalPos					: TEXCOORD10;
				float3 norm							: NORMAL;
			};
		
			VertexOutputForwardAddExtended vertAddExtended(VertexInput v)
			{
				VertexOutputForwardAddExtended o;
				UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAddExtended, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		
				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.originalPos = posWorld;
		
				//Standard Calculations - vertForwardAdd
				o.pos = UnityObjectToClipPos(mul(unity_WorldToObject, posWorld));
				o.norm = v.normal;
				o.tex = TexCoords(v);
				o.eyeVec = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				#ifdef _TANGENT_TO_WORLD
					float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
		
					float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
					o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
					o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
					o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
				#else
					o.tangentToWorldAndLightDir[0].xyz = 0;
					o.tangentToWorldAndLightDir[1].xyz = 0;
					o.tangentToWorldAndLightDir[2].xyz = normalWorld;
				#endif

				//We need this for shadow receiving -- When geometry shader is being called the data is being passed for us from geo to frag
				TRANSFER_VERTEX_TO_FRAGMENT(o);
		
				float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
				#ifndef USING_DIRECTIONAL_LIGHT
					lightDir = NormalizePerVertexNormal(lightDir);
				#endif
				o.tangentToWorldAndLightDir[0].w = lightDir.x;
				o.tangentToWorldAndLightDir[1].w = lightDir.y;
				o.tangentToWorldAndLightDir[2].w = lightDir.z;
		
				#ifdef _PARALLAXMAP
					TANGENT_SPACE_ROTATION;
					o.viewDirForParallax = mul(rotation, ObjSpaceViewDir(v.vertex));
				#endif
		
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}
		
			[maxvertexcount(3)]
			void geomAddExtended(triangle VertexOutputForwardAddExtended IN[3], inout TriangleStream<VertexOutputForwardAddExtended> triStream)
			{
				float4 p1 = IN[0].originalPos, p2 = IN[1].originalPos, p3 = IN[2].originalPos;
				float v1 = abs(p1.x + p1.z + p2.x);
				float v2 = abs(p2.z + p3.x + p3.z);

				VertexOutputForwardAddExtended pIn;
				UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAddExtended, pIn);
				
				for (int i = 0; i < 3; ++i)
				{
					//DISP
					if (!_HasWhistled)
						pIn.pos = IN[i].pos;
					else
					{
						float currentDistance = distance(_PlayerWorldPosition, IN[i].originalPos);
						if (currentDistance <= _RadiusInfluence)
						{
							float totalInfluenceDistance = abs(currentDistance / _RadiusInfluence - 1);
							float rotSeed = Rand(v1 * v2) * 45.0f;
							//roll (z) * pitch (y) * yaw (x)
							float4x4 rollMat = CreateRotationMatrixFromAxisAndAngle(float3(0, 0, 1), radians(rotSeed));
							float4x4 pitchMat = CreateRotationMatrixFromAxisAndAngle(float3(0, 1, 0), radians(rotSeed));
							float4x4 yawMat = CreateRotationMatrixFromAxisAndAngle(float3(1, 0, 0), radians(rotSeed));
							float3 rotNorm = mul(rollMat * pitchMat * yawMat, IN[i].norm);
							float dispFactor = Rand(IN[i].originalPos);
							dispFactor = (_DispFactorMax - _DispFactorMin)*(dispFactor - 0.0f) / 1.0f + _DispFactorMin;
							float4 disp = IN[i].originalPos;
							disp.xyz += rotNorm * ((dispFactor * totalInfluenceDistance) * _WhistleTimeInfluence);
							pIn.pos = mul(UNITY_MATRIX_MVP, mul(unity_WorldToObject, disp));
						}
						else
							pIn.pos = IN[i].pos;
					}

					pIn.tex = IN[i].tex;
					pIn.eyeVec = IN[i].eyeVec;
					
					//Passing data from vertex to fragment because in vertex we called TRANSFER_VERTEX_TO_FRAGMENT
					#if defined (LIGHTCOORD_USED)
						pIn._LightCoord = IN[i]._LightCoord; 
					#endif
					#if defined (SHADOWCOORD_USED)
						pIn._ShadowCoord = IN[i]._ShadowCoord;
					#endif

					pIn.tangentToWorldAndLightDir = IN[i].tangentToWorldAndLightDir;

					UNITY_TRANSFER_FOG(pIn, pIn.pos);
					#if defined(_PARALLAXMAP)
						pIn.viewDirForParallax = IN[i].viewDirForParallax;
					#endif
					triStream.Append(pIn);
				}
			}
		
			half4 fragAddExtended(VertexOutputForwardAddExtended i) : SV_TARGET
			{
				FRAGMENT_SETUP_FWDADD(s)
		
				UnityLight light = AdditiveLight(s.normalWorld, IN_LIGHTDIR_FWDADD(i), LIGHT_ATTENUATION(i));
				UnityIndirect noIndirect = ZeroIndirect();
		
				half4 c = UNITY_BRDF_PBS(s.diffColor, s.specColor, s.oneMinusReflectivity, s.oneMinusRoughness, s.normalWorld, -s.eyeVec, light, noIndirect);
		
				UNITY_APPLY_FOG_COLOR(i.fogCoord, c.rgb, half4(0, 0, 0, 0)); // fog towards black in additive pass
				return OutputForward(c, s.alpha);
			}
		
			ENDCG
		}
		Pass
		{
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			ZTest LEqual

			CGPROGRAM
			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma skip_variants SHADOWS_SOFT
			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCasterExtended
			#pragma geometry geomShadowCasterExtended
			#pragma fragment fragShadowCasterExtended

			#include "UnityCG.cginc"
			#include "UnityStandardInput.cginc" //VertexInput
			#include "DAECustomCG.cginc"		//for Custom Functions

			//VARIABLES
			int _HasWhistled;
			float _WhistleTimeInfluence;
			float4 _PlayerWorldPosition;
			float _DispFactorMin;
			float _DispFactorMax;
			float _RadiusInfluence;
			int _EnableReprojectCasting;

			//INPUTS
			#define UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT 1
			
			#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
					struct VertexOutputShadowCaster
					{
						V2F_SHADOW_CASTER_NOPOS
						#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
							float2 tex : TEXCOORD1;
						#endif
						float4 opos			: SV_POSITION;
						float4 originalPos	: TEXCOORD2;
						float3 norm			: NORMAL;
					};
			#endif
			
			VertexOutputShadowCaster vertShadowCasterExtended(VertexInput v)
			{
				VertexOutputShadowCaster o;
				UNITY_INITIALIZE_OUTPUT(VertexOutputShadowCaster, o);

				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				v.vertex = mul(unity_WorldToObject, posWorld);
			
				o.originalPos = posWorld;
				o.norm = v.normal;

				UNITY_SETUP_INSTANCE_ID(v);
				TRANSFER_SHADOW_CASTER_NOPOS(o, o.opos)
				#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
					o.tex = TRANSFORM_TEX(v.uv0, _MainTex);
				#endif
				return o;
			}
			
			[maxvertexcount(3)]
			void geomShadowCasterExtended(triangle VertexOutputShadowCaster IN[3], inout TriangleStream<VertexOutputShadowCaster> triStream)
			{
				float4 p1 = IN[0].originalPos, p2 = IN[1].originalPos, p3 = IN[2].originalPos;
				float v1 = abs(p1.x + p1.z + p2.x);
				float v2 = abs(p2.z + p3.x + p3.z);

				VertexOutputShadowCaster pIn;
				UNITY_INITIALIZE_OUTPUT(VertexOutputShadowCaster, pIn);
			
				for (int i = 0; i < 3; ++i)
				{
					if (!_HasWhistled)
						pIn.opos = IN[i].opos;
					else
					{
						//DISP
						float currentDistance = distance(_PlayerWorldPosition, IN[i].originalPos);
						float4 disp;
						if (_EnableReprojectCasting)
						{
							if (currentDistance <= _RadiusInfluence)
							{
								//Distance Influence -> remap to [0-1], if influence is 3 units then distance 3 == 0 and 0 == 1
								float totalInfluenceDistance = abs(currentDistance / _RadiusInfluence - 1);

								float rotSeed = Rand(v1 * v2) * 45.0f;
								//roll (z) * pitch (y) * yaw (x)
								float4x4 rollMat = CreateRotationMatrixFromAxisAndAngle(float3(0, 0, 1), radians(rotSeed));
								float4x4 pitchMat = CreateRotationMatrixFromAxisAndAngle(float3(0, 1, 0), radians(rotSeed));
								float4x4 yawMat = CreateRotationMatrixFromAxisAndAngle(float3(1, 0, 0), radians(rotSeed));
								float3 rotNorm = mul(rollMat * pitchMat * yawMat, IN[i].norm);
								float dispFactor = Rand(IN[i].originalPos);
								dispFactor = (_DispFactorMax - _DispFactorMin)*(dispFactor - 0.0f) / 1.0f + _DispFactorMin;
								disp = IN[i].originalPos;
								disp.xyz += rotNorm * ((dispFactor * totalInfluenceDistance) * _WhistleTimeInfluence);
								pIn.opos = mul(UNITY_MATRIX_MVP, mul(unity_WorldToObject, disp));
							}
							else
							{
								pIn.opos = IN[i].opos;
								disp = IN[i].originalPos;
							}

							pIn.opos = UnityClipSpaceShadowCasterPos(mul(unity_WorldToObject, disp), IN[i].norm);
							pIn.opos = UnityApplyLinearShadowBias(pIn.opos);
						}
						else
							pIn.opos = IN[i].opos;
					}

					#ifdef SHADOWS_CUBE
						pIn.vec = IN[i].vec;
					#endif
					#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
						pIn.tex = IN[i].tex;
					#endif

					triStream.Append(pIn);
				}
			}
			
			half4 fragShadowCasterExtended(
				#ifdef UNITY_STANDARD_USE_SHADOW_OUTPUT_STRUCT
					VertexOutputShadowCaster i
				#endif
				#ifdef UNITY_STANDARD_USE_DITHER_MASK
					, UNITY_VPOS_TYPE vpos : VPOS
				#endif 
			) : SV_Target
			{
				#if defined(UNITY_STANDARD_USE_SHADOW_UVS)
					half alpha = tex2D(_MainTex, i.tex).a * _Color.a;
					#if defined(_ALPHATEST_ON)
						clip(alpha - _Cutoff);
					#endif
					#if defined(_ALPHABLEND_ON) || defined(_ALPHAPREMULTIPLY_ON)
						#if defined(UNITY_STANDARD_USE_DITHER_MASK)
							// Use dither mask for alpha blended shadows, based on pixel position xy
							// and alpha level. Our dither texture is 4x4x16.
							half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy*0.25,alpha*0.9375)).a;
							clip(alphaRef - 0.01);
						#else
							clip(alpha - _Cutoff);
						#endif
					#endif
				#endif // #if defined(UNITY_STANDARD_USE_SHADOW_UVS)
			
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}
		Pass
		{
			Tags{ "LightMode" = "Meta" }

			Cull Off

			CGPROGRAM
			#pragma vertex vert_meta
			#pragma fragment frag_meta
			
			#pragma shader_feature ___ _DETAIL_MULX2
			
			#include "UnityStandardMeta.cginc"
			ENDCG
		}
	}
}