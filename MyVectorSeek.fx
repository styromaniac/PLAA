//------------------------------------------------------------------------------
// MyVectorSeek.fx - Single-Pass AA with (Luminance / Color / Hybrid) Edge Detection
//   + Depth Min/Max Sliders
//   + No "Final Color" debug mode
//------------------------------------------------------------------------------
#include "ReShade.fxh"

//------------------------------------------------------------------------------
// 1) User-Configurable Parameters
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
    Five Distinct Sampling Quality modes:
      0) Standard (3×3 => 9 taps)
      1) High Quality (5×5 => 25 taps)
      2) Ultra Quality (7×7 => 49 taps)
      3) Insane (9×9 => 81 taps)
      4) Ludicrous (13×13 => 169 taps)
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
    DebugMode now excludes "Final Color".
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
// Depth Min/Max Sliders
//   For clamping depth values from the built-in ReShade depth buffer
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
// 2) Textures & Samplers
//------------------------------------------------------------------------------
texture texColorBuffer : COLOR;
sampler samplerColor
{
    Texture = texColorBuffer;
};

// Depth texture + sampler for potential local variance or other logic
texture texDepth : DEPTH;
sampler samplerDepth
{
    Texture = texDepth;
};

//------------------------------------------------------------------------------
// 3) Helper Functions
//------------------------------------------------------------------------------
float3 GetPixelColor(float2 uv)
{
    // For color buffer
    return tex2D(samplerColor, uv).rgb;
}

// Depth sampling with user clamp
float GetDepth(float2 uv)
{
    float d = tex2D(samplerDepth, uv).r;
    // Scale/clamp to [0..1] based on DepthMin..DepthMax
    d = saturate( (d - DepthMin) / (DepthMax - DepthMin) );
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
// 4) Local Variance Functions
//------------------------------------------------------------------------------
float ComputeLocalVariance3x3(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 1; // => 3x3

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

    float area   = (2 * k + 1) * (2 * k + 1);
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

float ComputeLocalVariance5x5(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 2; // => 5x5

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

    float area   = (2 * k + 1) * (2 * k + 1);
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

float ComputeLocalVariance7x7(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 3; // => 7x7

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

    float area   = (2 * k + 1) * (2 * k + 1);
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

float ComputeLocalVariance9x9(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 4; // => 9x9

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

    float area   = (2 * k + 1) * (2 * k + 1);
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

float ComputeLocalVariance13x13(float2 uv, float2 pixelSize)
{
    float sumLum = 0.0, sumLumSq = 0.0;
    const int k = 6; // => 13x13

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

    float area   = (2 * k + 1) * (2 * k + 1);
    float mean   = sumLum / area;
    float meanSq = sumLumSq / area;
    return meanSq - (mean * mean);
}

//------------------------------------------------------------------------------
// 5) Luminance-Only Sobel
//------------------------------------------------------------------------------
float ComputeEdgeMaskLuminance(float2 uv, float2 pixelSize)
{
    float3 tl = GetPixelColor(uv + pixelSize * float2(-1, -1));
    float3 t  = GetPixelColor(uv + pixelSize * float2( 0, -1));
    float3 tr = GetPixelColor(uv + pixelSize * float2( 1, -1));
    float3 l  = GetPixelColor(uv + pixelSize * float2(-1,  0));
    float3 c  = GetPixelColor(uv);
    float3 r  = GetPixelColor(uv + pixelSize * float2( 1,  0));
    float3 bl = GetPixelColor(uv + pixelSize * float2(-1,  1));
    float3 b  = GetPixelColor(uv + pixelSize * float2( 0,  1));
    float3 br = GetPixelColor(uv + pixelSize * float2( 1,  1));

    float lumTL = GetLuminance(tl);
    float lumT  = GetLuminance(t);
    float lumTR = GetLuminance(tr);
    float lumL  = GetLuminance(l);
    float lumC  = GetLuminance(c);
    float lumR  = GetLuminance(r);
    float lumBL = GetLuminance(bl);
    float lumB  = GetLuminance(b);
    float lumBR = GetLuminance(br);

    float gx = -lumTL - 2.0 * lumL - lumBL + lumTR + 2.0 * lumR + lumBR;
    float gy = -lumTL - 2.0 * lumT - lumTR + lumBL + 2.0 * lumB + lumBR;
    float gradMag = length(float2(gx, gy));

    return saturate(gradMag * 4.0);
}

//------------------------------------------------------------------------------
// 6) Color + Luminance Sobel
//------------------------------------------------------------------------------
float ComputeEdgeMaskColor(float2 uv, float2 pixelSize)
{
    float3 tl = GetPixelColor(uv + pixelSize * float2(-1, -1));
    float3 t  = GetPixelColor(uv + pixelSize * float2( 0, -1));
    float3 tr = GetPixelColor(uv + pixelSize * float2( 1, -1));
    float3 l  = GetPixelColor(uv + pixelSize * float2(-1,  0));
    float3 c  = GetPixelColor(uv);
    float3 r  = GetPixelColor(uv + pixelSize * float2( 1,  0));
    float3 bl = GetPixelColor(uv + pixelSize * float2(-1,  1));
    float3 b  = GetPixelColor(uv + pixelSize * float2( 0,  1));
    float3 br = GetPixelColor(uv + pixelSize * float2( 1,  1));

    float lumTL = GetLuminance(tl);
    float lumT  = GetLuminance(t);
    float lumTR = GetLuminance(tr);
    float lumL  = GetLuminance(l);
    float lumC  = GetLuminance(c);
    float lumR  = GetLuminance(r);
    float lumBL = GetLuminance(bl);
    float lumB  = GetLuminance(b);
    float lumBR = GetLuminance(br);

    float gx = -lumTL - 2.0 * lumL - lumBL + lumTR + 2.0 * lumR + lumBR;
    float gy = -lumTL - 2.0 * lumT - lumTR + lumBL + 2.0 * lumB + lumBR;
    float gradMag = length(float2(gx, gy));

    float colorDiff = 0.0;
    colorDiff = max(colorDiff, ColorDifference(c, l));
    colorDiff = max(colorDiff, ColorDifference(c, r));
    colorDiff = max(colorDiff, ColorDifference(c, t));
    colorDiff = max(colorDiff, ColorDifference(c, b));

    float combined = max(gradMag, colorDiff);
    return saturate(combined * 4.0);
}

//------------------------------------------------------------------------------
// 7) Hybrid Edge Mask
//------------------------------------------------------------------------------
float ComputeEdgeMaskHybrid(float2 uv, float2 pixelSize)
{
    float lumMask   = ComputeEdgeMaskLuminance(uv, pixelSize);
    float colorMask = ComputeEdgeMaskColor(uv, pixelSize);
    return saturate(lumMask * 0.5 + colorMask * 0.5);
}

//------------------------------------------------------------------------------
// 8) Master Edge Mask
//------------------------------------------------------------------------------
float ComputeEdgeMask(float2 uv, float2 pixelSize)
{
    if (EdgeMode == 0)
        return ComputeEdgeMaskLuminance(uv, pixelSize);
    else if (EdgeMode == 1)
        return ComputeEdgeMaskColor(uv, pixelSize);
    else
        return ComputeEdgeMaskHybrid(uv, pixelSize);
}

//------------------------------------------------------------------------------
// 9) Anti-Aliasing Routine
//------------------------------------------------------------------------------
float3 ApplyAntiAliasing(float2 uv, float2 pixelSize, float2 edgeDir, float edgeMask)
{
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
// 10) Device-Specific Processing
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
// 11) Main Pixel Shader with Conditional Variance Computation
//------------------------------------------------------------------------------
float3 PS_VectorSeek(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 pixelSize = ReShade::PixelSize;
    float3 originalColor = GetPixelColor(uv);
    float rawEdgeMask = ComputeEdgeMask(uv, pixelSize);
    bool weakEdge = (rawEdgeMask < EdgeDetectionThreshold);

    // Early exit if the edge is weak.
    if (weakEdge)
    {
        if (DebugView)
        {
            if (DebugMode == 1)
            {
                // Compute local variance only when needed for debug.
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

    // Compute edge direction.
    float3 lfCol = GetPixelColor(uv + pixelSize * float2(-1, 0));
    float3 rtCol = GetPixelColor(uv + pixelSize * float2( 1, 0));
    float3 upCol = GetPixelColor(uv + pixelSize * float2( 0,-1));
    float3 dnCol = GetPixelColor(uv + pixelSize * float2( 0, 1));

    float gx = GetLuminance(rtCol) - GetLuminance(lfCol);
    float gy = GetLuminance(dnCol) - GetLuminance(upCol);
    float2 edgeDir = normalize(float2(gx, gy) + 1e-8);

    float3 aaColor = ApplyAntiAliasing(uv, pixelSize, edgeDir, rawEdgeMask);
    float3 finalColor = ApplyDeviceSpecificProcessing(originalColor, aaColor);

    // Debug output for non-weak edges.
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
            float t = smoothstep(lower, upper, rawEdgeMask);
            t = min(t, MaxBlend);
            float blendFactor = t * FilterStrength * 0.1;
            return float3(blendFactor, blendFactor, blendFactor);
        }
    }

    return finalColor;
}

//------------------------------------------------------------------------------
// 12) Technique Declaration
//------------------------------------------------------------------------------
technique MyVectorSeek
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_VectorSeek;
    }
}
