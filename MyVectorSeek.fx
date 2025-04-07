//------------------------------------------------------------------------------
// MyVectorSeek.fx - A (Partly Comedic) Single-Pass AA Shader for ReShade
//------------------------------------------------------------------------------
//
// WARNING: The "Ridiculous," "God Mode," and beyond modes here use extremely
// large sample kernels that can absolutely murder your performance on any
// normal GPU at high resolutions. We did it mostly for fun. Use at your own risk!
//
// This effect attempts a simple single-pass anti-aliasing approach by:
//  1. Checking local variance to skip uniform areas.
//  2. Detecting edges via a Sobel-like gradient and color difference.
//  3. Blending across the perpendicular to those edges.
//
// The insane high-kernel modes are not guaranteed to look better than
// standard or existing advanced AA solutions (SMAA, FXAA, TAA, etc.),
// and in many cases, they'll eat your FPS for breakfast.
//
// Use "God Mode (768)" only if you want to have fun seeing how
// unreasonably big a 25x25 or similar kernel can be in practice.
//
//------------------------------------------------------------------------------

#include "ReShade.fxh"

//------------------------------------------------------------------------------
// 1) User-Configurable Parameters
//------------------------------------------------------------------------------
uniform int DevicePreset <
    ui_type = "combo";
    ui_items = "Custom Settings\0Steam Deck LCD\0Steam Deck OLED (BOE)\0Steam Deck OLED LE (Samsung)\0";
    ui_label = "Device Preset";
    ui_tooltip = "Select your device for color-tweak settings. Minimally tested.";
> = 0;

uniform float FilterStrength <
    ui_type = "slider";
    ui_min = 0.1; ui_max = 10.0; ui_step = 0.1;
    ui_label = "Filter Strength";
    ui_tooltip = "Overall strength of the AA effect. Too high = smudge.";
> = 3.0;

uniform float EdgeDetectionThreshold <
    ui_type = "slider";
    ui_min = 0.01; ui_max = 0.30; ui_step = 0.01;
    ui_label = "Edge Detection Threshold";
    ui_tooltip = "Threshold for detecting edges. Lower = more edges, more blur.";
> = 0.10;

uniform float FlatnessThreshold <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 0.02; ui_step = 0.001;
    ui_label = "Flatness Threshold";
    ui_tooltip = "Variance threshold for near-uniform areas. Low = more skipping.";
> = 0.005;

uniform float MaxBlend <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Max Edge Blend";
    ui_tooltip = "Clamp on how strongly edges get blended. 1.0 = no clamp.";
> = 0.7;

uniform float GradientPreservationStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Gradient Preservation Strength";
    ui_tooltip = "Preserve smoother gradients (placeholder, not very robust).";
> = 0.70;

/*
    The higher modes are basically comedic leaps in sampling, each
    ballooning the kernel size. Expect performance hits that scale
    up ridiculously. Tread carefully.
*/
uniform int SamplingQuality <
    ui_type = "combo";
    ui_items =
        "Standard\0"    // 0 => 3x3
        "High Quality\0"// 1 => 3x3
        "Ultra Quality\0"//2 => 3x3
        "Insane (96)\0" // 3 => 5x5
        "Ludicrous (192)\0" // 4 => 9x9
        "Ridiculous (384)\0" // 5 => 13x13
        "God Mode (768)\0";  // 6 => 25x25
    ui_label = "Sampling Quality";
    ui_tooltip = "Select your desired kernel size (and witness your GPU meltdown).";
> = 0;

uniform float CurveDetectionStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Curve Detection Strength";
    ui_tooltip = "Placeholder for improved curved edge detection. Not fully implemented.";
> = 0.50;

uniform bool DebugView <
    ui_type = "bool";
    ui_label = "Debug View";
    ui_tooltip = "Show debug output (edge mask, variance, etc.) instead of final color.";
> = false;

uniform int DebugMode <
    ui_type = "combo";
    ui_items = "Edge Mask\0Variance\0Blending Factor\0Final Color\0";
    ui_label = "Debug Mode";
    ui_tooltip = "Choose the debug output (if Debug View is on).";
> = 0;

//------------------------------------------------------------------------------
// 2) Texture & Sampler
//------------------------------------------------------------------------------
texture texColorBuffer : COLOR;
sampler samplerColor
{
    Texture = texColorBuffer;
};

//------------------------------------------------------------------------------
// 3) Helper Functions
//------------------------------------------------------------------------------
float GetLuminance(float3 color)
{
    return dot(color, float3(0.299, 0.587, 0.114));
}

float3 GetPixelColor(float2 texcoord)
{
    return tex2D(samplerColor, texcoord).rgb;
}

// A simple color difference measure (max of R/G/B differences).
float ColorDifference(float3 c1, float3 c2)
{
    float3 diff = abs(c1 - c2);
    return max(max(diff.r, diff.g), diff.b);
}

//------------------------------------------------------------------------------
// 4) Local Variance Checks
//------------------------------------------------------------------------------
float ComputeLocalVariance3x3(float2 texcoord, float2 pixelSize)
{
    float sumLum = 0.0;
    float sumLumSq = 0.0;
    const int kernelSize = 1; // => 3x3

    [unroll]
    for (int y = -kernelSize; y <= kernelSize; y++)
    {
        [unroll]
        for (int x = -kernelSize; x <= kernelSize; x++)
        {
            float3 col = GetPixelColor(texcoord + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }

    float area = (2 * kernelSize + 1) * (2 * kernelSize + 1);
    float mean = sumLum / area;
    float meanSq = sumLumSq / area;
    float variance = meanSq - (mean * mean);

    return variance;
}

// (5x5) ~Insane
float ComputeLocalVariance5x5(float2 texcoord, float2 pixelSize)
{
    float sumLum = 0.0;
    float sumLumSq = 0.0;
    const int kernelSize = 2; // => 5x5

    [unroll]
    for (int y = -kernelSize; y <= kernelSize; y++)
    {
        [unroll]
        for (int x = -kernelSize; x <= kernelSize; x++)
        {
            float3 col = GetPixelColor(texcoord + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }

    float area = (2 * kernelSize + 1) * (2 * kernelSize + 1);
    float mean = sumLum / area;
    float meanSq = sumLumSq / area;
    float variance = meanSq - (mean * mean);

    return variance;
}

// (9x9) ~Ludicrous
float ComputeLocalVariance9x9(float2 texcoord, float2 pixelSize)
{
    float sumLum = 0.0;
    float sumLumSq = 0.0;
    const int kernelSize = 4; // => 9x9

    [unroll]
    for (int y = -kernelSize; y <= kernelSize; y++)
    {
        [unroll]
        for (int x = -kernelSize; x <= kernelSize; x++)
        {
            float3 col = GetPixelColor(texcoord + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }

    float area = (2 * kernelSize + 1) * (2 * kernelSize + 1);
    float mean = sumLum / area;
    float meanSq = sumLumSq / area;
    float variance = meanSq - (mean * mean);

    return variance;
}

// (13x13) ~Ridiculous
float ComputeLocalVariance13x13(float2 texcoord, float2 pixelSize)
{
    float sumLum = 0.0;
    float sumLumSq = 0.0;
    const int kernelSize = 6; // => 13x13

    [unroll]
    for (int y = -kernelSize; y <= kernelSize; y++)
    {
        [unroll]
        for (int x = -kernelSize; x <= kernelSize; x++)
        {
            float3 col = GetPixelColor(texcoord + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }

    float area = (2 * kernelSize + 1) * (2 * kernelSize + 1);
    float mean = sumLum / area;
    float meanSq = sumLumSq / area;
    float variance = meanSq - (mean * mean);

    return variance;
}

// (25x25) ~God Mode
float ComputeLocalVariance25x25(float2 texcoord, float2 pixelSize)
{
    float sumLum = 0.0;
    float sumLumSq = 0.0;
    const int kernelSize = 12; // => 25x25

    [unroll]
    for (int y = -kernelSize; y <= kernelSize; y++)
    {
        [unroll]
        for (int x = -kernelSize; x <= kernelSize; x++)
        {
            float3 col = GetPixelColor(texcoord + pixelSize * float2(x, y));
            float lum  = GetLuminance(col);
            sumLum    += lum;
            sumLumSq  += lum * lum;
        }
    }

    float area = (2 * kernelSize + 1) * (2 * kernelSize + 1);
    float mean = sumLum / area;
    float meanSq = sumLumSq / area;
    float variance = meanSq - (mean * mean);

    return variance;
}

//------------------------------------------------------------------------------
// 5) Edge Mask (Combine Sobel + Color Diff)
//------------------------------------------------------------------------------
float ComputeEdgeMask(float2 texcoord, float2 pixelSize)
{
    float3 tl = GetPixelColor(texcoord + pixelSize * float2(-1, -1));
    float3 t  = GetPixelColor(texcoord + pixelSize * float2( 0, -1));
    float3 tr = GetPixelColor(texcoord + pixelSize * float2( 1, -1));
    float3 l  = GetPixelColor(texcoord + pixelSize * float2(-1,  0));
    float3 c  = GetPixelColor(texcoord);
    float3 r  = GetPixelColor(texcoord + pixelSize * float2( 1,  0));
    float3 bl = GetPixelColor(texcoord + pixelSize * float2(-1,  1));
    float3 b  = GetPixelColor(texcoord + pixelSize * float2( 0,  1));
    float3 br = GetPixelColor(texcoord + pixelSize * float2( 1,  1));

    float lumTL = GetLuminance(tl);
    float lumT  = GetLuminance(t);
    float lumTR = GetLuminance(tr);
    float lumL  = GetLuminance(l);
    float lumC  = GetLuminance(c);
    float lumR  = GetLuminance(r);
    float lumBL = GetLuminance(bl);
    float lumB  = GetLuminance(b);
    float lumBR = GetLuminance(br);

    // Sobel approximation
    float gx = -lumTL - 2.0*lumL - lumBL + lumTR + 2.0*lumR + lumBR;
    float gy = -lumTL - 2.0*lumT - lumTR + lumBL + 2.0*lumB + lumBR;
    float gradMag = length(float2(gx, gy));

    // Color difference
    float colorDiff = 0.0;
    colorDiff = max(colorDiff, ColorDifference(c, l));
    colorDiff = max(colorDiff, ColorDifference(c, r));
    colorDiff = max(colorDiff, ColorDifference(c, t));
    colorDiff = max(colorDiff, ColorDifference(c, b));

    // Combine
    float combinedEdge = max(gradMag, colorDiff);

    // Approximate scale
    float mask = saturate(combinedEdge * 4.0);
    return mask;
}

//------------------------------------------------------------------------------
// 6) Anti-Aliasing Routine
//------------------------------------------------------------------------------
float3 ApplyAntiAliasing(float2 texcoord, float2 pixelSize, float2 edgeDir, float edgeMask)
{
    // Perpendicular direction
    float2 perp = float2(-edgeDir.y, edgeDir.x);

    // Original color
    float3 centerCol = GetPixelColor(texcoord);

    // Single neighbor sample
    float3 neighborCol = GetPixelColor(texcoord + perp * pixelSize);

    // Non-linear blend factor
    float lower = EdgeDetectionThreshold;
    float upper = EdgeDetectionThreshold * 2.0;
    float t = smoothstep(lower, upper, edgeMask);

    // Clamp the maximum blend
    t = min(t, MaxBlend);

    // Scale by user’s FilterStrength
    float blendFactor = t * FilterStrength * 0.1;

    // Lerp
    return lerp(centerCol, neighborCol, saturate(blendFactor));
}

//------------------------------------------------------------------------------
// 7) Device-Specific Color Tweak
//------------------------------------------------------------------------------
float3 ApplyDeviceSpecificProcessing(float3 original, float3 aaColor)
{
    float deviceFactor = 1.0;
    if (DevicePreset == 1) // Steam Deck LCD
        deviceFactor = 0.8;
    else if (DevicePreset == 2) // Steam Deck OLED (BOE)
        deviceFactor = 1.2;
    else if (DevicePreset == 3) // Steam Deck OLED LE
        deviceFactor = 1.5;

    // Very simplistic final blend
    return lerp(original, aaColor, deviceFactor * 0.3);
}

//------------------------------------------------------------------------------
// 8) Main Pixel Shader
//------------------------------------------------------------------------------
float3 PS_VectorSeek(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float2 pixelSize = ReShade::PixelSize;
    float3 originalColor = GetPixelColor(texcoord);

    // Choose local variance function by sampling mode
    float localVariance = 0.0;
    [branch]
    switch (SamplingQuality)
    {
        case 6: // God Mode
            localVariance = ComputeLocalVariance25x25(texcoord, pixelSize);
            break;
        case 5: // Ridiculous
            localVariance = ComputeLocalVariance13x13(texcoord, pixelSize);
            break;
        case 4: // Ludicrous
            localVariance = ComputeLocalVariance9x9(texcoord, pixelSize);
            break;
        case 3: // Insane
            localVariance = ComputeLocalVariance5x5(texcoord, pixelSize);
            break;
        default: // 0,1,2 => 3x3
            localVariance = ComputeLocalVariance3x3(texcoord, pixelSize);
    }

    // Basic edge detection
    float rawEdgeMask = ComputeEdgeMask(texcoord, pixelSize);

    bool lowVariance = (localVariance < FlatnessThreshold);
    bool weakEdge    = (rawEdgeMask < EdgeDetectionThreshold);

    // If no strong edge, skip blending
    if (weakEdge || (lowVariance && rawEdgeMask < (EdgeDetectionThreshold * 2.0)))
    {
        // If debug, show fallback data
        if (DebugView)
        {
            if (DebugMode == 0)
                return float3(0.0, 0.0, 0.0); // Edge Mask debug => black
            if (DebugMode == 1)
            {
                float vis = localVariance * 50.0;
                return float3(vis, vis, vis); // Variance debug
            }
            if (DebugMode == 2)
                return float3(0.0, 0.0, 0.0); // Blending factor => zero
            // DebugMode == 3 => final color => original
        }
        return originalColor;
    }

    // Approx. edge direction
    float3 upCol = GetPixelColor(texcoord + pixelSize * float2( 0, -1));
    float3 dnCol = GetPixelColor(texcoord + pixelSize * float2( 0,  1));
    float3 lfCol = GetPixelColor(texcoord + pixelSize * float2(-1,  0));
    float3 rtCol = GetPixelColor(texcoord + pixelSize * float2( 1,  0));

    float gx = GetLuminance(rtCol) - GetLuminance(lfCol);
    float gy = GetLuminance(dnCol) - GetLuminance(upCol);
    float2 edgeDir = normalize(float2(gx, gy) + 1e-8);

    // Apply the AA blend
    float3 aaColor = ApplyAntiAliasing(texcoord, pixelSize, edgeDir, rawEdgeMask);

    // Minor device-based color tweak
    float3 finalColor = ApplyDeviceSpecificProcessing(originalColor, aaColor);

    // Debug view modes
    if (DebugView)
    {
        if (DebugMode == 0) // Edge Mask
        {
            return float3(rawEdgeMask, rawEdgeMask, rawEdgeMask);
        }
        else if (DebugMode == 1) // Variance
        {
            float varVis = localVariance * 50.0;
            return float3(varVis, varVis, varVis);
        }
        else if (DebugMode == 2) // Blending Factor
        {
            float lower = EdgeDetectionThreshold;
            float upper = EdgeDetectionThreshold * 2.0;
            float t = smoothstep(lower, upper, rawEdgeMask);
            t = min(t, MaxBlend);
            float blendFactor = t * FilterStrength * 0.1;
            return float3(blendFactor, blendFactor, blendFactor);
        }
        // 3 => final color
    }

    return finalColor;
}

//------------------------------------------------------------------------------
// 9) Technique Declaration
//------------------------------------------------------------------------------
technique MyVectorSeek
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_VectorSeek;
    }
}
