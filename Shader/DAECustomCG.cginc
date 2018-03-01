//--------------- CUSTOM DAE CG FUNCTIONALITY ------------------------//
#ifndef UNITY_DAE_INCLUDE
#define UNITY_DAE_INCLUDE

//HASHING
//Thomas Wang Hash - http://www.reedbeta.com/blog/2013/01/12/quick-and-easy-gpu-random-numbers-in-d3d11/
uint WangHash(uint seed)
{
	seed = (seed ^ 61) ^ (seed >> 16);
	seed *= 9;
	seed = seed ^ (seed >> 4);
	seed *= 0x27d4eb2d;
	seed = seed ^ (seed >> 15);
	return seed;
}

//Rerange
#define UINT_MAX 2147483647
float RedistributeUINTtoFLOAT(float min, float max, uint value)
{
	float maxOldValue = UINT_MAX;
	float minOldValue = 0;
	return (max - min)*(value - minOldValue) / maxOldValue + min;
}

//Random
float Rand(float3 co)
{
	return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
}

//Create Rotation Matrix - https://en.wikipedia.org/wiki/Rotation_matrix#In_three_dimensions
float4x4 CreateRotationMatrixFromAxisAndAngle(float3 axis, float angle)
{
	//m[Row][Column] - We can transpose later if necessary
	float4x4 rm;
	rm._m00 = cos(angle) + axis.x * axis.x * (1 - cos(angle));
	rm._m01 = axis.x * axis.y * (1 - cos(angle)) - axis.z * sin(angle);
	rm._m02 = axis.x * axis.z * (1 - cos(angle)) + axis.y * sin(angle);
	rm._m03 = 0;

	rm._m10 = axis.y * axis.x * (1 - cos(angle)) + axis.z * sin(angle);
	rm._m11 = cos(angle) + axis.y * axis.y * (1 - cos(angle));
	rm._m12 = axis.y * axis.z * (1 - cos(angle)) - axis.x * sin(angle);
	rm._m13 = 0;

	rm._m20 = axis.z * axis.x * (1 - cos(angle)) - axis.y * sin(angle);
	rm._m21 = axis.z * axis.y * (1 - cos(angle)) + axis.x * sin(angle);
	rm._m22 = cos(angle) + axis.z * axis.z * (1 - cos(angle));
	rm._m23 = 0;

	rm._m30 = 0;
	rm._m31 = 0;
	rm._m32 = 0;
	rm._m33 = 1;

	return rm;
}

#endif //UNITY_DAE_INCLUDE