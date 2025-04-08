//------------------------------------------------------------------------------
// MyVectorSeek.fx - Combined Edge Detection with Polygon Interior and OSD Bypass
// Targeting all GPU vendors (NVIDIA, AMD, Intel)
//   Edge Detection Modes:
//     0 => Luminance: Fast, but may miss subtle color edges.
//     1 => Color: More accurate for color transitions, but heavier.
//     2 => Hybrid: Blends luminance and color detection for balanced quality.
//     3 => Depth-only: Uses the depth buffer for geometry edges; efficient on supported hardware,
//                     but may not capture texture-based edges.
//   Bypasses processing for polygon interiors (when edge mask is below threshold)
//   and for OSD elements (pixels with alpha below 0.99).
//   (Variance debug view removed; low-level GPU optimizations applied)
//------------------------------------------------------------------------------ 

#include "ReShade.fxh"

//------------------------------------------------------------------------------
// 1) User-Configurable Parameters
//------------------------------------------------------------------------------

// Device Preset: Adjust processing based on target device.
uniform int DevicePreset <
    ui_type = "combo";
    ui_items = "Custom Settings\0Steam Deck LCD\0Steam Deck OLED (BOE)\0Steam Deck OLED LE (Samsung)\0";
    ui_label = "Device Preset";
    ui_tooltip = "Select your device for optimized settings (faster if less correction is needed).";
> = 0;

uniform float FilterStrength <
    ui_type = "slider";
    ui_min = 0.1; ui_max = 10.0; ui_step = 0.1;
    ui_label = "Filter Strength";
    ui_tooltip = "Overall strength of the effect.";
> = 3.0;

uniform float EdgeDetectionThreshold <
    ui_type = "slider";
    ui_min = 0.01; ui_max = 0.30; ui_step = 0.01;
    ui_label = "Edge Detection Threshold";
    ui_tooltip = "Minimum edge strength required to trigger processing.";
> = 0.10;

uniform float MaxBlend <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Max Edge Blend";
    ui_tooltip = "Maximum allowed blend factor for edge processing.";
> = 0.7;

/*
    Edge Detection Modes and their trade-offs:
      0 => Luminance (Fast): Low compute cost; may miss subtleties.
      1 => Color (Accurate): Captures fine color differences at a moderate cost.
      2 => Hybrid (Balanced): Blends luminance and color for overall quality.
      3 => Depth-only (Efficient on Depth Buffers): Uses depth differences; very efficient but may miss texture edges.
*/
uniform int EdgeMode <
    ui_type = "combo";
    ui_items = "Luminance (Fast)\0Color (Accurate)\0Hybrid (Balanced)\0Depth-only (Efficient on Depth Buffers)\0";
    ui_label = "Edge Detection Mode";
    ui_tooltip = "Choose an edge detection mode. Luminance is fastest; Color is more accurate; Hybrid blends both; Depth-only uses the depth buffer for geometry edges.";
> = 1;

uniform bool DebugView <
    ui_type = "bool";
    ui_label = "Debug View";
    ui_tooltip = "Show debug output (either edge mask or blending factor).";
> = false;

/*
    DebugMode options (Variance removed):
      0 => Edge Mask
      2 => Blending Factor
*/
uniform int DebugMode <
    ui_type = "combo";
    ui_items = "Edge Mask\0Blending Factor\0";
    ui_label = "Debug Mode";
    ui_tooltip = "Select the debug information to display.";
> = 0;

// Bypass OSD elements: if enabled, pixels with low alpha (e.g., overlays) will bypass processing.
uniform bool BypassOSD <
    ui_type = "bool";
    ui_label = "Bypass OSD";
    ui_tooltip = "When enabled, pixels with alpha < 0.99 (typically OSD elements) will bypass processing.";
> = true;

// Depth clamping for depth-buffer normalization.
uniform float DepthMin <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Depth Min";
    ui_tooltip = "Minimum depth value for normalization.";
> = 0.0;

uniform float DepthMax <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Depth Max";
    ui_tooltip = "Maximum depth value for normalization.";
> = 1.0;

//------------------------------------------------------------------------------
// 2) Textures & Samplers
//------------------------------------------------------------------------------
// Sample the color buffer as float4 to check alpha.
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

// GetPixelColor4 returns a float4 (including alpha), facilitating OSD checks.
float4 GetPixelColor4(float2 uv)
{
    return tex2D(samplerColor, uv);
}

// GetPixelColor returns the RGB components only.
float3 GetPixelColor(float2 uv)
{
    return GetPixelColor4(uv).rgb;
}

// GetDepth samples and normalizes the depth value.
float GetDepth(float2 uv)
{
    float d = tex2D(samplerDepth, uv).r;
    return saturate((d - DepthMin) / (DepthMax - DepthMin));
}

// GetLuminance computes the luminance of a color.
float GetLuminance(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}

// ColorDifference computes maximum difference between two colors.
float ColorDifference(float3 c1, float3 c2)
{
    float3 diff = abs(c1 - c2);
    return max(max(diff.r, diff.g), diff.b);
}

//------------------------------------------------------------------------------
// 4) Edge Detection Functions
//------------------------------------------------------------------------------

// ComputeEdgeMaskFromSamples uses a cached 3x3 block to determine edge strength.
// Uses both the luminance-based Sobel operator and color differences.
float ComputeEdgeMaskFromSamples(
    float3 tl, float3 t, float3 tr,
    float3 l,  float3 c, float3 r,
    float3 bl, float3 b, float3 br)
{
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
    float lumMask = saturate(gradMag * 4.0);

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
    else if (EdgeMode == 2)
        return saturate(lumMask * 0.5 + colMask * 0.5);
    
    return 0.0;
}

// ComputeDepthEdgeMask performs edge detection using only depth values.
// It samples the center and four cardinal neighbors and compares differences.
float ComputeDepthEdgeMask(float2 uv, float2 pixelSize)
{
    float dC = GetDepth(uv);
    float dL = GetDepth(uv + float2(-pixelSize.x, 0));
    float dR = GetDepth(uv + float2(pixelSize.x, 0));
    float dT = GetDepth(uv + float2(0, -pixelSize.y));
    float dB = GetDepth(uv + float2(0, pixelSize.y));

    float diffHorizontal = abs(dR - dL);
    float diffVertical   = abs(dB - dT);
    float depthEdge = max(diffHorizontal, diffVertical);

    return saturate(depthEdge * 10.0);
}

//------------------------------------------------------------------------------
// 5) Box Blur Function
//------------------------------------------------------------------------------

// ApplyBoxBlur averages a 3x3 neighborhood. This function is kept for alternatives
// but is bypassed when not needed.
float3 ApplyBoxBlur(float2 uv, float2 pixelSize)
{
    float3 sum = float3(0.0, 0.0, 0.0);
    [unroll] for (int y = -1; y <= 1; y++)
    {
        [unroll] for (int x = -1; x <= 1; x++)
        {
            sum += GetPixelColor(uv + pixelSize * float2(x, y));
        }
    }
    return sum / 9.0;
}

//------------------------------------------------------------------------------
// 6) Device-Specific Processing
//------------------------------------------------------------------------------

// ApplyDeviceSpecificProcessing tweaks the final blending based on the selected device.
float3 ApplyDeviceSpecificProcessing(float3 original, float3 effectColor)
{
    float deviceFactor = 1.0;
    if (DevicePreset == 1)
        deviceFactor = 0.8;
    else if (DevicePreset == 2)
        deviceFactor = 1.2;
    else if (DevicePreset == 3)
        deviceFactor = 1.5;
    
    return lerp(original, effectColor, deviceFactor * 0.3);
}

//------------------------------------------------------------------------------
// 7) Main Pixel Shader
//------------------------------------------------------------------------------
float3 PS_VectorSeek(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 pixelSize = ReShade::PixelSize;

    // Sample the color buffer as float4 (needed for OSD alpha checking).
    float4 color4 = GetPixelColor4(uv);
    
    // Bypass OSD elements using a [branch] hint for efficiency.
    [branch]
    if (BypassOSD && color4.a < 0.99)
        return color4.rgb;
    
    float3 originalColor = color4.rgb;

    // Cache the 3x3 neighborhood once.
    float3 tl = GetPixelColor(uv + pixelSize * float2(-1, -1));
    float3 t  = GetPixelColor(uv + pixelSize * float2( 0, -1));
    float3 tr = GetPixelColor(uv + pixelSize * float2( 1, -1));
    float3 l  = GetPixelColor(uv + pixelSize * float2(-1,  0));
    float3 c  = originalColor;
    float3 r  = GetPixelColor(uv + pixelSize * float2( 1,  0));
    float3 bl = GetPixelColor(uv + pixelSize * float2(-1,  1));
    float3 b  = GetPixelColor(uv + pixelSize * float2( 0,  1));
    float3 br = GetPixelColor(uv + pixelSize * float2( 1,  1));

    float rawEdgeMask = 0.0;
    if (EdgeMode == 3)
    {
        rawEdgeMask = ComputeDepthEdgeMask(uv, pixelSize);
    }
    else
    {
        rawEdgeMask = ComputeEdgeMaskFromSamples(tl, t, tr, l, c, r, bl, b, br);
    }

    // Optional debug output.
    if (DebugView)
    {
        if (DebugMode == 0)
            return float3(rawEdgeMask, rawEdgeMask, rawEdgeMask);
        else if (DebugMode == 2)
        {
            float lower = EdgeDetectionThreshold;
            float upper = EdgeDetectionThreshold * 2.0;
            float tVal = smoothstep(lower, upper, rawEdgeMask);
            tVal = min(tVal, MaxBlend);
            return float3(tVal, tVal, tVal);
        }
    }

    // Bypass polygon interior pixels when edge strength is low.
    [branch]
    if (rawEdgeMask < EdgeDetectionThreshold)
        return originalColor;

    float3 finalColor = ApplyDeviceSpecificProcessing(originalColor, originalColor);
    return finalColor;
}

//------------------------------------------------------------------------------
// 8) Technique Declaration
//------------------------------------------------------------------------------
technique MyVectorSeek
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = PS_VectorSeek;
    }
}