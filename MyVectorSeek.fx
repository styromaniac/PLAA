//------------------------------------------------------------------------------
// MyVectorSeek.fx - Single-Pass AA with Optimized Edge Detection
//   + Depth Min/Max Sliders
//   + Optimized memory access & conditional evaluation for latency reduction
//------------------------------------------------------------------------------

#include "ReShade.fxh"

//------------------------------------------------------------------------------
// 1) User-Configurable Parameters (unchanged)
//------------------------------------------------------------------------------
uniform int DevicePreset <
    ui_type = "combo";
    ui_items = "Custom Settings\0Steam Deck LCD\0Steam Deck OLED (BOE)\0Steam Deck OLED LE (Samsung)\0";
    ui_label = "Device Preset";
    ui_tooltip = "Select your device for optimized settings.";
> = 0;

uniform float FilterStrength <
    ui_type = "slider";
    ui_min = 0.1; ui_max = 10.0; ui_step = 0.1;
    ui_label = "Filter Strength";
    ui_tooltip = "Overall strength of the AA effect.";
> = 3.0;

uniform float EdgeDetectionThreshold <
    ui_type = "slider";
    ui_min = 0.01; ui_max = 0.30; ui_step = 0.01;
    ui_label = "Edge Detection Threshold";
    ui_tooltip = "Threshold for detecting edges.";
> = 0.10;

uniform float MaxBlend <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Max Edge Blend";
    ui_tooltip = "Clamp on how strongly edges get blended.";
> = 0.7;

uniform float GradientPreservationStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Gradient Preservation Strength";
    ui_tooltip = "Preserve smooth gradients (placeholder).";
> = 0.70;

/*
    Sampling Quality modes:
      0) Standard (3x3 - 9 taps)
      1) High Quality (5x5 - 25 taps)
      2) Ultra Quality (7x7 - 49 taps)
      3) Insane (9x9 - 81 taps)
      4) Ludicrous (13x13 - 169 taps)
*/
uniform int SamplingQuality <
    ui_type = "combo";
    ui_items =
        "Standard (3x3 - 9 taps)\0"
        "High Quality (5x5 - 25 taps)\0"
        "Ultra Quality (7x7 - 49 taps)\0"
        "Insane (9x9 - 81 taps)\0"
        "Ludicrous (13x13 - 169 taps)\0";
    ui_label = "Sampling Quality";
    ui_tooltip = "Choose the sampling quality.";
> = 0;

uniform float CurveDetectionStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Curve Detection Strength";
    ui_tooltip = "Strength of curved edge detection (placeholder).";
> = 0.50;

/*
    0 => Luminance only
    1 => Color only
    2 => Hybrid
*/
uniform int EdgeMode <
    ui_type = "combo";
    ui_items = "Luminance\0Color\0Hybrid\0";
    ui_label = "Edge Detection Mode";
    ui_tooltip = "Luminance, color, or hybrid edges.";
> = 1;

uniform bool DebugView <
    ui_type = "bool";
    ui_label = "Debug View";
    ui_tooltip = "Show debug output (edge mask, variance, or blend).";
> = false;

/*
    DebugMode:
    0 => Edge Mask
    1 => Variance
    2 => Blending Factor
*/
uniform int DebugMode <
    ui_type = "combo";
    ui_items = "Edge Mask\0Variance\0Blending Factor\0";
    ui_label = "Debug Mode";
    ui_tooltip = "Choose debug output.";
> = 0;

//------------------------------------------------------------------------------
// Depth Min/Max Sliders (unchanged)
//------------------------------------------------------------------------------
uniform float DepthMin <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Depth Min";
    ui_tooltip = "Clamp the minimum depth to this value.";
> = 0.0;

uniform float DepthMax <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Depth Max";
    ui_tooltip = "Clamp the maximum depth to this value.";
> = 1.0;

//------------------------------------------------------------------------------
// 2) Textures & Samplers (unchanged)
//------------------------------------------------------------------------------
texture texColorBuffer : COLOR;
sampler samplerColor
{
    Texture = texColorBuffer;
};

texture texDepth : DEPTH;
sampler samplerDepth
{
    Texture = texDepth;
};

//------------------------------------------------------------------------------
// 3) Helper Functions (unchanged)
//------------------------------------------------------------------------------
float3 GetPixelColor(float2 uv)
{
    return tex2D(samplerColor, uv).rgb;
}

float GetDepth(float2 uv)
{
    float d = tex2D(samplerDepth, uv).r;
    d = saturate((d - DepthMin) / (DepthMax - DepthMin));
    return d;
}

float GetLuminance(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}

float ColorDifference(float3 c1, float3 c2)
{
    float3 diff = abs(c1 - c2);
    return max(max(diff.r, diff.g), diff.b);
}

//------------------------------------------------------------------------------
// 4) Local Variance Functions (unchanged)
//------------------------------------------------------------------------------
float ComputeLocalVariance3x3(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 1; // 3x3

    [unroll]
    for (int y = -k; y <= k; y++)
    {
        [unroll]
        for (int x = -k; x <= k; x++)
        {
            float3 col = GetPixelColor(uv + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }
    float area   = 9.0;
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

float ComputeLocalVariance5x5(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 2;
    [unroll]
    for (int y = -k; y <= k; y++)
    {
        [unroll]
        for (int x = -k; x <= k; x++)
        {
            float3 col = GetPixelColor(uv + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }
    float area   = 25.0;
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

float ComputeLocalVariance7x7(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 3;
    [unroll]
    for (int y = -k; y <= k; y++)
    {
        [unroll]
        for (int x = -k; x <= k; x++)
        {
            float3 col = GetPixelColor(uv + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }
    float area   = 49.0;
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

float ComputeLocalVariance9x9(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 4;
    [unroll]
    for (int y = -k; y <= k; y++)
    {
        [unroll]
        for (int x = -k; x <= k; x++)
        {
            float3 col = GetPixelColor(uv + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }
    float area   = 81.0;
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

float ComputeLocalVariance13x13(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 6;
    [unroll]
    for (int y = -k; y <= k; y++)
    {
        [unroll]
        for (int x = -k; x <= k; x++)
        {
            float3 col = GetPixelColor(uv + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }
    float area   = 169.0;
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

//------------------------------------------------------------------------------
// 5) Optimized 3x3 Neighborhood-Based Edge Detection
//------------------------------------------------------------------------------
//
// This helper uses already-cached 3x3 samples to compute the edge mask.
// Depending on EdgeMode it computes:
// - Luminance Sobel (Luminance only)
// - Additional color difference (Color mode)
// - A 50:50 blend for Hybrid
//
float ComputeEdgeMaskFromSamples(
    float3 tl, float3 t, float3 tr,
    float3 l,  float3 c, float3 r,
    float3 bl, float3 b, float3 br)
{
    // Compute luminance for each sample
    float lumTL = GetLuminance(tl);
    float lumT  = GetLuminance(t);
    float lumTR = GetLuminance(tr);
    float lumL  = GetLuminance(l);
    float lumC  = GetLuminance(c);
    float lumR  = GetLuminance(r);
    float lumBL = GetLuminance(bl);
    float lumB  = GetLuminance(b);
    float lumBR = GetLuminance(br);

    // Luminance-based Sobel operator
    float gx = -lumTL - 2.0 * lumL - lumBL + lumTR + 2.0 * lumR + lumBR;
    float gy = -lumTL - 2.0 * lumT - lumTR + lumBL + 2.0 * lumB + lumBR;
    float gradMag = length(float2(gx, gy));

    float lumMask = saturate(gradMag * 4.0);

    // For color edge detection, accumulate maximum difference along cardinal directions
    float colorDiff = 0.0;
    colorDiff = max(colorDiff, ColorDifference(c, l));
    colorDiff = max(colorDiff, ColorDifference(c, r));
    colorDiff = max(colorDiff, ColorDifference(c, t));
    colorDiff = max(colorDiff, ColorDifference(c, b));
    float colMask = saturate(max(gradMag, colorDiff) * 4.0);

    if (EdgeMode == 0)
        return lumMask;
    else if (EdgeMode == 1)
        return colMask;
    else // Hybrid mode: blend 50:50
        return saturate(lumMask * 0.5 + colMask * 0.5);
}

//------------------------------------------------------------------------------
// 6) Anti-Aliasing Routine
//------------------------------------------------------------------------------
float3 ApplyAntiAliasing(float2 uv, float2 pixelSize, float2 edgeDir, float edgeMask)
{
    // Get perpendicular direction for edge smoothing
    float2 perp = float2(-edgeDir.y, edgeDir.x);
    float3 centerCol   = GetPixelColor(uv);
    float3 neighborCol = GetPixelColor(uv + perp * pixelSize);

    float lower = EdgeDetectionThreshold;
    float upper = EdgeDetectionThreshold * 2.0;
    float t = smoothstep(lower, upper, edgeMask);
    t = min(t, MaxBlend);
    float blendFactor = t * FilterStrength * 0.1;
    return lerp(centerCol, neighborCol, saturate(blendFactor));
}

//------------------------------------------------------------------------------
// 7) Device-Specific Processing (unchanged)
//------------------------------------------------------------------------------
float3 ApplyDeviceSpecificProcessing(float3 original, float3 aaColor)
{
    float deviceFactor = 1.0;
    if (DevicePreset == 1)      // Steam Deck LCD
        deviceFactor = 0.8;
    else if (DevicePreset == 2) // Steam Deck OLED (BOE)
        deviceFactor = 1.2;
    else if (DevicePreset == 3) // Steam Deck OLED LE
        deviceFactor = 1.5;

    return lerp(original, aaColor, deviceFactor * 0.3);
}

//------------------------------------------------------------------------------
// 8) Main Pixel Shader with Optimizations
//------------------------------------------------------------------------------
float3 PS_VectorSeek(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 pixelSize = ReShade::PixelSize;
    float3 originalColor = GetPixelColor(uv);

    // Cache the 3x3 neighborhood (one texture fetch per sample)
    float3 tl = GetPixelColor(uv + pixelSize * float2(-1, -1));
    float3 t  = GetPixelColor(uv + pixelSize * float2( 0, -1));
    float3 tr = GetPixelColor(uv + pixelSize * float2( 1, -1));
    float3 l  = GetPixelColor(uv + pixelSize * float2(-1,  0));
    float3 c  = originalColor;
    float3 r  = GetPixelColor(uv + pixelSize * float2( 1,  0));
    float3 bl = GetPixelColor(uv + pixelSize * float2(-1,  1));
    float3 b  = GetPixelColor(uv + pixelSize * float2( 0,  1));
    float3 br = GetPixelColor(uv + pixelSize * float2( 1,  1));

    // Compute the edge mask from cached samples
    float rawEdgeMask = ComputeEdgeMaskFromSamples(tl, t, tr, l, c, r, bl, b, br);

    // Early exit for weak edges (and skip heavy calculations if possible)
    if (rawEdgeMask < EdgeDetectionThreshold)
    {
        if (DebugView)
        {
            if (DebugMode == 1)
            {
                float localVariance = (SamplingQuality == 0) ? ComputeLocalVariance3x3(uv, pixelSize) :
                                        (SamplingQuality == 1) ? ComputeLocalVariance5x5(uv, pixelSize) :
                                        (SamplingQuality == 2) ? ComputeLocalVariance7x7(uv, pixelSize) :
                                        (SamplingQuality == 3) ? ComputeLocalVariance9x9(uv, pixelSize) :
                                                                 ComputeLocalVariance13x13(uv, pixelSize);
                float varVis = localVariance * 50.0;
                return float3(varVis, varVis, varVis);
            }
            else if (DebugMode == 0)
                return float3(rawEdgeMask, rawEdgeMask, rawEdgeMask);
            else if (DebugMode == 2)
                return float3(0.0, 0.0, 0.0);
        }
        return originalColor;
    }

    // Compute edge gradient using cached left/right and top/bottom samples
    float gx = GetLuminance(r) - GetLuminance(l);
    float gy = GetLuminance(b) - GetLuminance(t);
    float2 edgeDir = normalize(float2(gx, gy) + 1e-8);

    // Apply anti-aliasing using the optimized blending
    float3 aaColor = ApplyAntiAliasing(uv, pixelSize, edgeDir, rawEdgeMask);
    float3 finalColor = ApplyDeviceSpecificProcessing(originalColor, aaColor);

    // Debug output for non-weak edges
    if (DebugView)
    {
        if (DebugMode == 0)
            return float3(rawEdgeMask, rawEdgeMask, rawEdgeMask);
        else if (DebugMode == 1)
        {
            float localVariance = (SamplingQuality == 0) ? ComputeLocalVariance3x3(uv, pixelSize) :
                                    (SamplingQuality == 1) ? ComputeLocalVariance5x5(uv, pixelSize) :
                                    (SamplingQuality == 2) ? ComputeLocalVariance7x7(uv, pixelSize) :
                                    (SamplingQuality == 3) ? ComputeLocalVariance9x9(uv, pixelSize) :
                                                             ComputeLocalVariance13x13(uv, pixelSize);
            float varVis = localVariance * 50.0;
            return float3(varVis, varVis, varVis);
        }
        else if (DebugMode == 2)
        {
            float lower = EdgeDetectionThreshold;
            float upper = EdgeDetectionThreshold * 2.0;
            float tVal = smoothstep(lower, upper, rawEdgeMask);
            tVal = min(tVal, MaxBlend);
            float blendFactor = tVal * FilterStrength * 0.1;
            return float3(blendFactor, blendFactor, blendFactor);
        }
    }
    return finalColor;
}

//------------------------------------------------------------------------------
// 9) Technique Declaration (unchanged)
//------------------------------------------------------------------------------
technique MyVectorSeek
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_VectorSeek;
    }
}