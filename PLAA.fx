//=====================================================================
// PLAA_AutoOptimized - Ultimate Auto-Optimized AA Shader
//=====================================================================

#include "ReShade.fxh"

//-----------------------------
// Vendor-specific definitions
//-----------------------------
#ifdef INTEL_GPU
    #define VENDOR_QUALITY_MODE 0
#elif defined AMD_GPU
    #define VENDOR_QUALITY_MODE 1
#elif defined NVIDIA_GPU
    #define VENDOR_QUALITY_MODE 1
#else
    // Default (assume mid-range hardware)
    #define VENDOR_QUALITY_MODE 1
#endif

// Use the vendor-specific sample count
#define SAMPLE_COUNT 7

//-----------------------------
// Hard-coded settings
//-----------------------------
#define EDGE_THRESHOLD 0.1  // Hard-coded to .1 for maximum edge detection without noise
#define EDGE_NORM (EDGE_THRESHOLD * 8.0)
#define K_BLEND_DIV 4.0

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

texture texHistory { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler samplerHistory { Texture = texHistory; };

//-----------------------------
// Baked-In Performance Settings
//-----------------------------
static const float BAKED_FilterStrength = 10.0;
static const float BAKED_TemporalReinforcementStrength = 0.0;
static const bool BAKED_FlipDepthDirection = true;

//-----------------------------
// Helper Functions
//-----------------------------
float GetLuminance(float3 color)
{
    return dot(color, float3(0.299, 0.587, 0.114));
}

float3 GetPixelColor(float2 texcoord)
{
    return tex2D(samplerColor, texcoord).rgb;
}

float GetAdjustedDepth(float2 texcoord)
{
    float depth = ReShade::GetLinearizedDepth(texcoord);
    return BAKED_FlipDepthDirection ? 1.0 - depth : depth;
}

// Fast pseudo-random function for dithering
float Rand(float2 coord)
{
    return frac(sin(dot(coord, float2(12.9898, 78.233))) * 43758.5453);
}

//-----------------------------
// Enhanced Edge Detection
//-----------------------------
void EnhancedEdgeDetection(float2 texcoord, float2 pixelSize, 
                          out float edgeStrength, out float2 edgeDirection, out float detailFactor)
{
    // 3x3 neighborhood offsets
    float2 offs[9] = {
        float2(-1,-1), float2(0,-1), float2(1,-1),
        float2(-1,0), float2(0,0), float2(1,0),
        float2(-1,1), float2(0,1), float2(1,1)
    };

    // Gather luminance samples
    float L[9];
    float sumL = 0.0;
    
    for (int i = 0; i < 9; i++)
    {
        float2 sampleTC = texcoord + offs[i] * pixelSize;
        L[i] = GetLuminance(GetPixelColor(sampleTC));
        sumL += L[i];
    }
    float avgL = sumL / 9.0;

    // Calculate local variance for detail detection
    float var = 0.0;
    for (int i = 0; i < 9; i++)
    {
        float diff = L[i] - avgL;
        var += diff * diff;
    }
    var /= 9.0;
    
    // detailFactor: 0 = smooth area, 1 = highly detailed
    detailFactor = saturate(var * 5.0);

    // Sobel operator for edge detection
    float gx = (-L[0] + L[2]) + (-2.0 * L[3] + 2.0 * L[5]) + (-L[6] + L[8]);
    float gy = (-L[0] + L[6]) + (-2.0 * L[1] + 2.0 * L[7]) + (-L[2] + L[8]);
    float gMag = sqrt(gx * gx + gy * gy);

    // Use the hard-coded edge threshold
    edgeStrength = saturate(gMag / EDGE_NORM);
    edgeDirection = (edgeStrength > EDGE_THRESHOLD) ? normalize(float2(gx, gy)) : float2(0.0, 0.0);

    // Depth compensation for distant pixels
    float depth = GetAdjustedDepth(texcoord);
    if (depth > 0.9)
        edgeStrength *= max(0.5, 1.0 - (depth - 0.9) * 5.0);
}

//-----------------------------
// Enhanced Filtering with 7-Sample Pattern
//-----------------------------
float3 EnhancedFiltering(float2 texcoord, float2 pixelSize, 
                        float edgeStrength, float2 edgeDirection, float detailFactor)
{
    float3 center = GetPixelColor(texcoord);
    float centerLum = GetLuminance(center);

    // Perpendicular vector for sampling
    float2 perp = float2(-edgeDirection.y, edgeDirection.x);

    // 7-sample optimized pattern
    float3 sum = center * 0.30;
    float totalWeight = 0.30;

    // Optimal sampling pattern with progressive distances
    float offsets[6] = { 0.5, 1.0, 1.5, 2.0, 3.0, 4.0 };
    float weights[6] = { 0.25, 0.20, 0.15, 0.10, 0.05, 0.025 };
    
    // Apply sampling pattern
    for (int i = 0; i < 6; i++)
    {
        float offset = offsets[i];
        float weight = weights[i];
        
        // Sample in both positive and negative directions
        float2 delta = perp * offset * pixelSize;
        
        float3 color1 = GetPixelColor(texcoord + delta);
        float3 color2 = GetPixelColor(texcoord - delta);
        
        // Adaptive weight based on luminance similarity
        float lum1 = GetLuminance(color1);
        float lum2 = GetLuminance(color2);
        
        float sim1 = exp(-abs(lum1 - centerLum) * 2.5);
        float sim2 = exp(-abs(lum2 - centerLum) * 2.5);
        
        float aw1 = weight * sim1;
        float aw2 = weight * sim2;
        
        sum += color1 * aw1 + color2 * aw2;
        totalWeight += aw1 + aw2;
    }

    // Normalize the sum
    float3 filtered = sum / max(totalWeight, 0.001);
    
    // Adaptive blend based on edge strength and detail
    float baseBlend = edgeStrength * BAKED_FilterStrength / K_BLEND_DIV;
    float adaptiveBlend = lerp(baseBlend, baseBlend * 0.85, saturate(detailFactor));
    float blendFactor = smoothstep(0.0, 1.0, adaptiveBlend);
    
    // Add dithering to reduce banding
    float dither = (Rand(texcoord) - 0.5) * 0.003;
    
    return lerp(center, filtered, blendFactor) + dither;
}

//-----------------------------
// Temporal Processing
//-----------------------------
float3 OptimizedTemporalProcessing(float3 currentColor, float2 texcoord)
{
    // Skip if temporal strength is too low
    if (BAKED_TemporalReinforcementStrength < 0.1)
        return currentColor;

    float3 historyColor = tex2D(samplerHistory, texcoord).rgb;
    float lumaDiff = abs(GetLuminance(currentColor) - GetLuminance(historyColor));
    float blendFactor = BAKED_TemporalReinforcementStrength * smoothstep(0.0, 1.0, 1.0 - lumaDiff * 4.0);
    
    // Depth-based modulation
    float2 ps = ReShade::PixelSize;
    float dCenter = GetAdjustedDepth(texcoord);
    float dUp = GetAdjustedDepth(texcoord + float2(0.0, -ps.y));
    float dDown = GetAdjustedDepth(texcoord + float2(0.0, ps.y));
    float dLeft = GetAdjustedDepth(texcoord + float2(-ps.x, 0.0));
    float dRight = GetAdjustedDepth(texcoord + float2(ps.x, 0.0));
    
    float depthDiff = (abs(dCenter - dUp) + abs(dCenter - dDown) + 
                      abs(dCenter - dLeft) + abs(dCenter - dRight)) * 0.25;
    
    float depthMod = saturate(1.0 - depthDiff * 10.0);
    blendFactor *= depthMod;

    return lerp(currentColor, historyColor, blendFactor);
}

//-----------------------------
// Main Pixel Shader
//-----------------------------
float4 PS_PLAA(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    // Early exit for dark pixels
    float3 originalColor = GetPixelColor(texcoord);
    if (originalColor.r + originalColor.g + originalColor.b < 0.01)
        return float4(originalColor, 1.0);

    float2 pixelSize = ReShade::PixelSize;

    // Detect edges
    float edgeStrength;
    float2 edgeDirection;
    float detailFactor;
    EnhancedEdgeDetection(texcoord, pixelSize, edgeStrength, edgeDirection, detailFactor);
    
    // Skip processing if edge is weak
    if (edgeStrength < EDGE_THRESHOLD)
        return float4(originalColor, 1.0);

    // Apply AA filtering
    float3 aaColor = EnhancedFiltering(texcoord, pixelSize, edgeStrength, edgeDirection, detailFactor);
    
    // Apply temporal stabilization
    float3 finalColor = OptimizedTemporalProcessing(aaColor, texcoord);

    return float4(finalColor, 1.0);
}

// Save current frame for temporal processing
float4 PS_SaveHistory(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    return float4(GetPixelColor(texcoord), 1.0);
}

//-----------------------------
// Techniques
//-----------------------------
technique PLAA
{
    pass MainPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_PLAA;
    }
    
    pass SaveHistory
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SaveHistory;
        RenderTarget = texHistory;
    }
}
