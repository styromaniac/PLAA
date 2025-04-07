//------------------------------------------------------------------------------
// MyVectorSeek.fx - Single-Pass AA using Depth Gradients and Text(ure) Preservation
//
// Features:
// - Depth-based Sobel edge detection exclusively (to preserve flat OSD text).
// - Local variance computed from the depth buffer (5 quality modes).
// - DepthMin/DepthMax sliders clamp the depth values.
// - DepthEdgeScale scales the sensitivity of depth gradients.
// - TextPreservationStrength reduces blending in smooth (low-curvature) areas.
// - Device-specific color adjustments and debug modes (Edge Mask, Variance, Blending Factor).
// - License: GNU AGPL v3.0
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
    ui_tooltip = "Threshold for detecting depth edges.";
> = 0.10;

uniform float FlatnessThreshold <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 0.02; ui_step = 0.001;
    ui_label = "Flatness Threshold";
    ui_tooltip = "Depth variance threshold for near-uniform areas.";
> = 0.005;

uniform float MaxBlend <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Max Edge Blend";
    ui_tooltip = "Clamp on how strongly edges get blended.";
> = 0.7;

// Renamed for text preservation—reduces blending in smooth (low-curvature) areas.
uniform float TextPreservationStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Text(ure) Preservation Strength";
    ui_tooltip = "Controls how much blending is reduced in smooth areas to preserve text clarity.";
> = 0.70;

/*
    SamplingQuality: 5 modes for local variance (based on depth):
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

uniform bool DebugView <
    ui_type = "bool";
    ui_label = "Debug View";
    ui_tooltip = "Show debug output (Edge Mask, Variance, or Blending Factor).";
> = false;

/*
    DebugMode (Final Color debug mode removed):
      0 = Edge Mask
      1 = Variance
      2 = Blending Factor
*/
uniform int DebugMode <
    ui_type = "combo";
    ui_items = "Edge Mask\0Variance\0Blending Factor\0";
    ui_label = "Debug Mode";
    ui_tooltip = "Select debug output.";
> = 0;

// Depth clamping sliders
uniform float DepthMin <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Depth Min";
    ui_tooltip = "Clamp the minimum depth value.";
> = 0.0;

uniform float DepthMax <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Depth Max";
    ui_tooltip = "Clamp the maximum depth value.";
> = 1.0;

// Depth edge detection scale factor
uniform float DepthEdgeScale <
    ui_type = "slider";
    ui_min = 1.0; ui_max = 100.0; ui_step = 1.0;
    ui_label = "Depth Edge Scale";
    ui_tooltip = "Scale factor for depth gradient edge detection.";
> = 50.0;

//------------------------------------------------------------------------------
// 2) Textures & Samplers
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
// 3) Helper Functions
//------------------------------------------------------------------------------
float3 GetPixelColor(float2 uv)
{
    return tex2D(samplerColor, uv).rgb;
}

// Get depth from the depth texture, clamped to [0,1] using DepthMin/DepthMax.
float GetDepth(float2 uv)
{
    float d = tex2D(samplerDepth, uv).r;
    return saturate((d - DepthMin) / (DepthMax - DepthMin));
}

//------------------------------------------------------------------------------
// 4) Local Variance Functions (Depth-Based)
//------------------------------------------------------------------------------
float ComputeLocalVariance3x3(float2 uv, float2 pixelSize)
{
    float sumD = 0.0, sumDSq = 0.0;
    const int k = 1;
    [unroll] for (int y = -k; y <= k; y++)
        [unroll] for (int x = -k; x <= k; x++)
        {
            float d = GetDepth(uv + pixelSize * float2(x, y));
            sumD += d;
            sumDSq += d * d;
        }
    float area = (2 * k + 1) * (2 * k + 1);
    float mean = sumD / area;
    return (sumDSq / area) - (mean * mean);
}

float ComputeLocalVariance5x5(float2 uv, float2 pixelSize)
{
    float sumD = 0.0, sumDSq = 0.0;
    const int k = 2;
    [unroll] for (int y = -k; y <= k; y++)
        [unroll] for (int x = -k; x <= k; x++)
        {
            float d = GetDepth(uv + pixelSize * float2(x, y));
            sumD += d;
            sumDSq += d * d;
        }
    float area = (2 * k + 1) * (2 * k + 1);
    float mean = sumD / area;
    return (sumDSq / area) - (mean * mean);
}

float ComputeLocalVariance7x7(float2 uv, float2 pixelSize)
{
    float sumD = 0.0, sumDSq = 0.0;
    const int k = 3;
    [unroll] for (int y = -k; y <= k; y++)
        [unroll] for (int x = -k; x <= k; x++)
        {
            float d = GetDepth(uv + pixelSize * float2(x, y));
            sumD += d;
            sumDSq += d * d;
        }
    float area = (2 * k + 1) * (2 * k + 1);
    float mean = sumD / area;
    return (sumDSq / area) - (mean * mean);
}

float ComputeLocalVariance9x9(float2 uv, float2 pixelSize)
{
    float sumD = 0.0, sumDSq = 0.0;
    const int k = 4;
    [unroll] for (int y = -k; y <= k; y++)
        [unroll] for (int x = -k; x <= k; x++)
        {
            float d = GetDepth(uv + pixelSize * float2(x, y));
            sumD += d;
            sumDSq += d * d;
        }
    float area = (2 * k + 1) * (2 * k + 1);
    float mean = sumD / area;
    return (sumDSq / area) - (mean * mean);
}

float ComputeLocalVariance13x13(float2 uv, float2 pixelSize)
{
    float sumD = 0.0, sumDSq = 0.0;
    const int k = 6;
    [unroll] for (int y = -k; y <= k; y++)
        [unroll] for (int x = -k; x <= k; x++)
        {
            float d = GetDepth(uv + pixelSize * float2(x, y));
            sumD += d;
            sumDSq += d * d;
        }
    float area = (2 * k + 1) * (2 * k + 1);
    float mean = sumD / area;
    return (sumDSq / area) - (mean * mean);
}

//------------------------------------------------------------------------------
// 5) Depth-Based Edge Detection
//------------------------------------------------------------------------------
float ComputeEdgeMaskDepth(float2 uv, float2 pixelSize)
{
    float dTL = GetDepth(uv + pixelSize * float2(-1, -1));
    float dT  = GetDepth(uv + pixelSize * float2(0, -1));
    float dTR = GetDepth(uv + pixelSize * float2(1, -1));
    float dL  = GetDepth(uv + pixelSize * float2(-1, 0));
    float dC  = GetDepth(uv);
    float dR  = GetDepth(uv + pixelSize * float2(1, 0));
    float dBL = GetDepth(uv + pixelSize * float2(-1, 1));
    float dB  = GetDepth(uv + pixelSize * float2(0, 1));
    float dBR = GetDepth(uv + pixelSize * float2(1, 1));

    float gx = -dTL - 2.0 * dL - dBL + dTR + 2.0 * dR + dBR;
    float gy = -dTL - 2.0 * dT - dTR + dBL + 2.0 * dB + dBR;
    return saturate(length(float2(gx, gy)) * DepthEdgeScale);
}

//------------------------------------------------------------------------------
// 5a) Depth Curvature for Text Preservation
//    Uses second derivatives of depth to approximate curvature.
float ComputeDepthCurvature(float2 uv)
{
    float d = GetDepth(uv);
    float ddx_d = ddx(d);
    float ddy_d = ddy(d);
    float curvature = abs(ddx_d) + abs(ddy_d);
    return saturate(curvature * 10.0);
}

//------------------------------------------------------------------------------
// 6) Anti-Aliasing Routine with Text(ure) Preservation
//------------------------------------------------------------------------------
float3 ApplyAntiAliasing(float2 uv, float2 pixelSize, float2 edgeDir, float edgeMask)
{
    float2 perp = float2(-edgeDir.y, edgeDir.x);
    float3 centerCol = GetPixelColor(uv);
    float3 neighborCol = GetPixelColor(uv + perp * pixelSize);

    float lower = EdgeDetectionThreshold;
    float upper = EdgeDetectionThreshold * 2.0;
    float t = smoothstep(lower, upper, edgeMask);
    t = min(t, MaxBlend);
    float blendFactor = t * FilterStrength * 0.1;

    // Apply depth curvature for text preservation:
    float curvature = ComputeDepthCurvature(uv);
    float preservationFactor = lerp(1.0, 0.0, TextPreservationStrength * (1.0 - curvature));
    blendFactor *= preservationFactor;

    return lerp(centerCol, neighborCol, saturate(blendFactor));
}

//------------------------------------------------------------------------------
// 7) Device-Specific Processing
//------------------------------------------------------------------------------
float3 ApplyDeviceSpecificProcessing(float3 original, float3 aaColor)
{
    float deviceFactor = 1.0;
    if (DevicePreset == 1)
        deviceFactor = 0.8;
    else if (DevicePreset == 2)
        deviceFactor = 1.2;
    else if (DevicePreset == 3)
        deviceFactor = 1.5;
    return lerp(original, aaColor, deviceFactor * 0.3);
}

//------------------------------------------------------------------------------
// 8) Main Pixel Shader
//------------------------------------------------------------------------------
float3 PS_VectorSeek(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 pixelSize = ReShade::PixelSize;
    float3 originalColor = GetPixelColor(uv);

    float localVariance = 0.0;
    if      (SamplingQuality == 0) localVariance = ComputeLocalVariance3x3(uv, pixelSize);
    else if (SamplingQuality == 1) localVariance = ComputeLocalVariance5x5(uv, pixelSize);
    else if (SamplingQuality == 2) localVariance = ComputeLocalVariance7x7(uv, pixelSize);
    else if (SamplingQuality == 3) localVariance = ComputeLocalVariance9x9(uv, pixelSize);
    else                           localVariance = ComputeLocalVariance13x13(uv, pixelSize);

    float rawEdgeMask = ComputeEdgeMaskDepth(uv, pixelSize);

    bool lowVariance = (localVariance < FlatnessThreshold);
    bool weakEdge = (rawEdgeMask < EdgeDetectionThreshold);

    if (weakEdge || (lowVariance && rawEdgeMask < (EdgeDetectionThreshold * 2.0)))
    {
        if (DebugView)
        {
            if (DebugMode == 0)
                return float3(0.0, 0.0, 0.0);
            else if (DebugMode == 1)
            {
                float varVis = localVariance * 50.0;
                return float3(varVis, varVis, varVis);
            }
            else if (DebugMode == 2)
                return float3(0.0, 0.0, 0.0);
        }
        return originalColor;
    }

    // Approximate edge direction from depth differences
    float dLeft  = GetDepth(uv + pixelSize * float2(-1, 0));
    float dRight = GetDepth(uv + pixelSize * float2(1, 0));
    float dUp    = GetDepth(uv + pixelSize * float2(0, -1));
    float dDown  = GetDepth(uv + pixelSize * float2(0, 1));
    float2 edgeDir = normalize(float2(dRight - dLeft, dDown - dUp) + 1e-8);

    float3 aaColor = ApplyAntiAliasing(uv, pixelSize, edgeDir, rawEdgeMask);
    float3 finalColor = ApplyDeviceSpecificProcessing(originalColor, aaColor);

    if (DebugView)
    {
        if (DebugMode == 0)
            return float3(rawEdgeMask, rawEdgeMask, rawEdgeMask);
        else if (DebugMode == 1)
        {
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
// 9) Technique Declaration
//------------------------------------------------------------------------------
technique MyVectorSeek
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_VectorSeek;
    }
}
