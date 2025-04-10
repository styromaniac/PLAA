//=====================================================================
// PLAA - Low Latency Anti-Aliasing with Performance Optimizations
// Most settings baked-in for maximum performance and minimal latency
// Flip Depth Direction is enabled by default
//=====================================================================

#include "ReShade.fxh"

//-----------------------------
// Customizable Setting
//-----------------------------
uniform float EdgeDetectionThreshold <
    ui_type = "slider";
    ui_min = 0.01; ui_max = 0.30; ui_step = 0.01;
    ui_label = "Edge Detection Threshold";
    ui_tooltip = "Lower values detect more edges. Higher values focus only on the strongest edges.";
> = 0.05; // Default from screenshot

//-----------------------------
// Textures and Samplers
//-----------------------------
texture texColorBuffer : COLOR;
sampler samplerColor { Texture = texColorBuffer; };

texture texDepth : DEPTH;
sampler samplerDepth {
    Texture = texDepth;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

texture texHistory : HISTORY;
sampler samplerHistory { Texture = texHistory; };

//-----------------------------
// Optimized Baked-in Settings
//-----------------------------
// Performance-optimized values based on screenshot settings
static const float BAKED_FilterStrength = 10.0;
static const float BAKED_DepthSensitivity = 1.0;
static const float BAKED_TemporalReinforcementStrength = 0.5;
static const float BAKED_MotionSensitivity = 1.0;
static const bool BAKED_FlipDepthDirection = true; // Baked in as enabled

// Note: EdgeDetectionThreshold is now customizable via UI

// Reduced sample count for better performance while maintaining quality
static const int SAMPLE_COUNT = 3; // Reduced from 4 (9 samples total) to 3 (7 samples total)

//-----------------------------
// Optimized Helper Functions
//-----------------------------
float GetLuminance(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}

float3 GetPixelColor(float2 texcoord) {
    return tex2D(samplerColor, texcoord).rgb;
}

float4 GetPixelColorWithAlpha(float2 texcoord) {
    return tex2D(samplerColor, texcoord);
}

float GetAdjustedDepth(float2 texcoord) {
    float depth = ReShade::GetLinearizedDepth(texcoord);
    // Flip depth is now baked in
    return BAKED_FlipDepthDirection ? 1.0 - depth : depth;
}

//-----------------------------
// Optimized Edge Detection
//-----------------------------
void OptimizedEdgeDetection(float2 texcoord, float2 pixelSize, out float edgeStrength, out float2 edgeDirection) {
    // Simplified 3x3 sampling - only sample the points we need for Sobel
    float3 c00 = GetPixelColor(texcoord + float2(-1, -1) * pixelSize);
    float3 c10 = GetPixelColor(texcoord + float2( 0, -1) * pixelSize);
    float3 c20 = GetPixelColor(texcoord + float2( 1, -1) * pixelSize);
    float3 c01 = GetPixelColor(texcoord + float2(-1,  0) * pixelSize);
    float3 c11 = GetPixelColor(texcoord); // Center pixel
    float3 c21 = GetPixelColor(texcoord + float2( 1,  0) * pixelSize);
    float3 c02 = GetPixelColor(texcoord + float2(-1,  1) * pixelSize);
    float3 c12 = GetPixelColor(texcoord + float2( 0,  1) * pixelSize);
    float3 c22 = GetPixelColor(texcoord + float2( 1,  1) * pixelSize);

    // Optimized Sobel operator using luminance for better performance
    float l00 = GetLuminance(c00), l20 = GetLuminance(c20);
    float l01 = GetLuminance(c01), l21 = GetLuminance(c21);
    float l02 = GetLuminance(c02), l22 = GetLuminance(c22);
    float l10 = GetLuminance(c10), l12 = GetLuminance(c12);

    // Calculate gradient for luminance only (faster than per-channel)
    float gx = l00 * -1.0 + l20 * 1.0 + l01 * -2.0 + l21 * 2.0 + l02 * -1.0 + l22 * 1.0;
    float gy = l00 * -1.0 + l02 * 1.0 + l10 * -2.0 + l12 * 2.0 + l20 * -1.0 + l22 * 1.0;

    // Calculate gradient magnitude
    float gMag = sqrt(gx * gx + gy * gy);

    // Calculate edge strength with user-defined threshold (no longer baked in)
    edgeStrength = saturate(gMag / (EdgeDetectionThreshold * 8.0));

    // Calculate edge direction only if edge is strong enough
    edgeDirection = float2(0, 0);
    if (edgeStrength > 0.05) {
        edgeDirection = normalize(float2(gx, gy));
    }

    // Quick perspective compensation based on depth
    float depth = GetAdjustedDepth(texcoord);
    if (depth > 0.9) {
        edgeStrength *= max(0.5, 1.0 - (depth - 0.9) * 5.0);
    }
}

//-----------------------------
// Optimized Filtering
//-----------------------------
float3 OptimizedFiltering(float2 texcoord, float2 pixelSize, float edgeStrength, float2 edgeDirection) {
    float3 center = GetPixelColor(texcoord);

    // Perpendicular direction to the edge for sampling
    float2 perp = float2(-edgeDirection.y, edgeDirection.x);

    // Optimized weights for fewer samples
    float3 sum = center * 0.4; // Increased center weight
    float totalWeight = 0.4;

    // Fixed distance scaling and weights - optimized for 7 samples total
    const float scale[3] = { 1.0, 2.0, 3.0 };
    const float weight[3] = { 0.25, 0.125, 0.0625 };

    // Unrolled loop for better performance
    [unroll]
    for (int i = 0; i < SAMPLE_COUNT; i++) {
        float offset = scale[i];
        float weight_i = weight[i];

        // Sample in both positive and negative directions
        float2 pos1 = texcoord + perp * offset * pixelSize;
        float2 pos2 = texcoord - perp * offset * pixelSize;

        float3 color1 = GetPixelColor(pos1);
        float3 color2 = GetPixelColor(pos2);

        // Simplified similarity - faster calculation
        float similarity1 = saturate(1.0 - length(color1 - center));
        float similarity2 = saturate(1.0 - length(color2 - center));

        float adaptiveWeight1 = weight_i * similarity1;
        float adaptiveWeight2 = weight_i * similarity2;

        sum += color1 * adaptiveWeight1 + color2 * adaptiveWeight2;
        totalWeight += adaptiveWeight1 + adaptiveWeight2;
    }

    // Fast color blend
    float3 filtered = sum / max(0.001, totalWeight);

    // Simplified blend factor calculation for performance
    float blendFactor = saturate(edgeStrength * BAKED_FilterStrength / 4.0);

    return lerp(center, filtered, blendFactor);
}

//-----------------------------
// Optimized Temporal Processing
//-----------------------------
float3 OptimizedTemporalProcessing(float3 currentColor, float2 texcoord) {
    // Skip temporal processing if strength is low
    if (BAKED_TemporalReinforcementStrength < 0.1)
        return currentColor;

    float3 historyColor = tex2D(samplerHistory, texcoord).rgb;

    // Fast luminance difference
    float lumaDiff = abs(GetLuminance(currentColor) - GetLuminance(historyColor));

    // Simplified motion rejection
    float blendFactor = BAKED_TemporalReinforcementStrength * saturate(1.0 - lumaDiff * 4.0);

    return lerp(currentColor, historyColor, blendFactor);
}

//-----------------------------
// Main Pixel Shader
//-----------------------------
float4 PS_SHADE(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    // Get pixel color with alpha
    float4 originalColorWithAlpha = GetPixelColorWithAlpha(texcoord);
    float3 originalColor = originalColorWithAlpha.rgb;

    // Early exit for transparent pixels (any alpha less than 1.0)
    if (originalColorWithAlpha.a < 1.0)
        return originalColorWithAlpha;

    // Early exit for near-black pixels
    if (originalColor.r + originalColor.g + originalColor.b < 0.01)
        return float4(originalColor, 1.0);

    float2 pixelSize = ReShade::PixelSize;

    // Detect edges
    float edgeStrength;
    float2 edgeDirection;
    OptimizedEdgeDetection(texcoord, pixelSize, edgeStrength, edgeDirection);

    // Skip processing if edge is weak
    if (edgeStrength < 0.05)
        return float4(originalColor, 1.0);

    // Apply AA filtering
    float3 aaColor = OptimizedFiltering(texcoord, pixelSize, edgeStrength, edgeDirection);

    // Apply temporal stabilization
    float3 finalColor = OptimizedTemporalProcessing(aaColor, texcoord);

    return float4(finalColor, 1.0);
}

technique PLAA
{
    pass MainPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SHADE;
    }
}
