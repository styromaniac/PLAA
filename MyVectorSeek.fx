//------------------------------------------------------------------------------
// MyVectorSeek.fx - Single-Pass AA Example (Fixed: Use semicolons in annotations)
//------------------------------------------------------------------------------
#include "ReShade.fxh"

//------------------------------------------------------------------------------
// 1) User-Configurable Parameters
//    ==> Use semicolons to separate ui_* attributes!
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

uniform float FlatnessThreshold <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 0.02; ui_step = 0.001;
    ui_label = "Flatness Threshold";
    ui_tooltip = "Variance threshold for near-uniform areas.";
> = 0.005;

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

uniform int SamplingQuality <
    ui_type = "combo";
    ui_items = "Standard\0High Quality\0Ultra Quality\0";
    ui_label = "Sampling Quality";
    ui_tooltip = "Choose the sampling quality.";
> = 1;

uniform float CurveDetectionStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Curve Detection Strength";
    ui_tooltip = "Strength of curved edge detection (placeholder).";
> = 0.50;

uniform bool DebugView <
    ui_type = "bool";
    ui_label = "Debug View";
    ui_tooltip = "Show debug output instead of final color.";
> = false;

uniform int DebugMode <
    ui_type = "combo";
    ui_items = "Edge Mask\0Variance\0Blending Factor\0Final Color\0";
    ui_label = "Debug Mode";
    ui_tooltip = "Choose debug output.";
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
// 4) Local Variance Check (Skip near-uniform areas)
//------------------------------------------------------------------------------
float ComputeLocalVariance(float2 texcoord, float2 pixelSize)
{
    // A small 3x3 region
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

    // variance = E(X^2) - [E(X)]^2
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

    // Color difference between center and neighbors
    float colorDiff = 0.0;
    colorDiff = max(colorDiff, ColorDifference(c, l));
    colorDiff = max(colorDiff, ColorDifference(c, r));
    colorDiff = max(colorDiff, ColorDifference(c, t));
    colorDiff = max(colorDiff, ColorDifference(c, b));
    // (Could add diagonal checks as well.)

    // Combine
    float combinedEdge = max(gradMag, colorDiff);

    // Scale to ~0..1 (adjust as needed)
    float mask = saturate(combinedEdge * 4.0);
    return mask;
}

//------------------------------------------------------------------------------
// 6) Anti-Aliasing Routine
//------------------------------------------------------------------------------
float3 ApplyAntiAliasing(float2 texcoord, float2 pixelSize, float2 edgeDir, float edgeMask)
{
    // Perp direction
    float2 perp = float2(-edgeDir.y, edgeDir.x);

    // Original color
    float3 centerCol = GetPixelColor(texcoord);

    // Single neighbor sample
    float3 neighborCol = GetPixelColor(texcoord + perp * pixelSize);

    // Non-linear blend factor (smoothstep around the threshold region)
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
// 7) Device-Specific Processing (optional)
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

    // Simple blend to show how you might adapt final color
    return lerp(original, aaColor, deviceFactor * 0.3);
}

//------------------------------------------------------------------------------
// 8) Main Pixel Shader
//------------------------------------------------------------------------------
float3 PS_VectorSeek(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
    float2 pixelSize = ReShade::PixelSize;
    float3 originalColor = GetPixelColor(texcoord);

    // Local variance => skip near-uniform regions
    float localVariance = ComputeLocalVariance(texcoord, pixelSize);

    // Basic edge mask
    float rawEdgeMask = ComputeEdgeMask(texcoord, pixelSize);

    bool lowVariance = (localVariance < FlatnessThreshold);
    bool weakEdge    = (rawEdgeMask < EdgeDetectionThreshold);

    // If no significant edge or it's interior => skip
    if (weakEdge || (lowVariance && rawEdgeMask < (EdgeDetectionThreshold * 2.0)))
    {
        // Debug outputs
        if (DebugView)
        {
            if (DebugMode == 0)      // Edge Mask
                return float3(0.0, 0.0, 0.0);
            else if (DebugMode == 1) // Variance
                return float3(localVariance * 50.0, localVariance * 50.0, localVariance * 50.0);
            else if (DebugMode == 2) // Blending Factor
                return float3(0.0, 0.0, 0.0);
            // DebugMode == 3 => Final Color
        }
        return originalColor;
    }

    // Compute approximate edge direction
    float3 upCol = GetPixelColor(texcoord + pixelSize * float2(0, -1));
    float3 dnCol = GetPixelColor(texcoord + pixelSize * float2(0,  1));
    float3 lfCol = GetPixelColor(texcoord + pixelSize * float2(-1, 0));
    float3 rtCol = GetPixelColor(texcoord + pixelSize * float2( 1, 0));

    float gx = GetLuminance(rtCol) - GetLuminance(lfCol);
    float gy = GetLuminance(dnCol) - GetLuminance(upCol);
    float2 edgeDir = normalize(float2(gx, gy) + 1e-8);

    // Apply AA
    float3 aaColor = ApplyAntiAliasing(texcoord, pixelSize, edgeDir, rawEdgeMask);

    // Device-specific color tweak
    float3 finalColor = ApplyDeviceSpecificProcessing(originalColor, aaColor);

    // Debug outputs
    if (DebugView)
    {
        if (DebugMode == 0) // Edge Mask
            return float3(rawEdgeMask, rawEdgeMask, rawEdgeMask);
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
        // DebugMode == 3 => show final color
    }

    return finalColor;
}

//------------------------------------------------------------------------------
// 9) Technique Declaration
//    Avoid naming it "VECTOR" or "vector" to prevent HLSL parser conflicts
//------------------------------------------------------------------------------
technique MyVectorSeek
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_VectorSeek;
    }
}
