//------------------------------------------------------------------------------
// MyVectorSeek_Combined_BypassInterior.fx - Combined Edge Detection with
// Polygon Interior Bypass
//   Edge Detection Modes: Luminance, Color, Hybrid, Depth-only.
//   Bypasses processing for polygon interior pixels (edge mask below threshold).
//------------------------------------------------------------------------------ 

#include "ReShade.fxh"

//------------------------------------------------------------------------------
// 1) User-Configurable Parameters
//------------------------------------------------------------------------------

// Device Preset determines device-specific processing factors.
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
    ui_tooltip = "Overall strength of the effect.";
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

/*
    Edge Detection Modes:
      0 => Luminance only  
      1 => Color only  
      2 => Hybrid (50:50 luminance & color)  
      3 => Depth-only
*/
uniform int EdgeMode <
    ui_type = "combo";
    ui_items = "Luminance\0Color\0Hybrid\0Depth\0";
    ui_label = "Edge Detection Mode";
    ui_tooltip = "Select edge detection mode.";
> = 1;

uniform bool DebugView <
    ui_type = "bool";
    ui_label = "Debug View";
    ui_tooltip = "Show debug output (edge mask or debug values).";
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

// Depth clamp sliders for normalizing the depth buffer values.
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

texture texDepth : DEPTH;
sampler samplerDepth
{
    Texture = texDepth;
};

//------------------------------------------------------------------------------
// 3) Helper Functions
//------------------------------------------------------------------------------

// Sample the color buffer.
float3 GetPixelColor(float2 uv)
{
    return tex2D(samplerColor, uv).rgb;
}

// Sample the depth buffer and normalize using DepthMin/DepthMax.
float GetDepth(float2 uv)
{
    float d = tex2D(samplerDepth, uv).r;
    return saturate((d - DepthMin) / (DepthMax - DepthMin));
}

// Compute luminance from a color.
float GetLuminance(float3 c)
{
    return dot(c, float3(0.299, 0.587, 0.114));
}

// Compute the maximum channel difference between two colors.
float ColorDifference(float3 c1, float3 c2)
{
    float3 diff = abs(c1 - c2);
    return max(max(diff.r, diff.g), diff.b);
}

//------------------------------------------------------------------------------
// 4) Edge Detection Functions
//------------------------------------------------------------------------------

// Computes edge mask from a cached 3x3 block using luminance and color differences.
float ComputeEdgeMaskFromSamples(
    float3 tl, float3 t, float3 tr,
    float3 l,  float3 c, float3 r,
    float3 bl, float3 b, float3 br)
{
    // Compute luminance for each sample.
    float lumTL = GetLuminance(tl);
    float lumT  = GetLuminance(t);
    float lumTR = GetLuminance(tr);
    float lumL  = GetLuminance(l);
    float lumC  = GetLuminance(c);
    float lumR  = GetLuminance(r);
    float lumBL = GetLuminance(bl);
    float lumB  = GetLuminance(b);
    float lumBR = GetLuminance(br);

    // Luminance Sobel operator.
    float gx = -lumTL - 2.0 * lumL - lumBL + lumTR + 2.0 * lumR + lumBR;
    float gy = -lumTL - 2.0 * lumT - lumTR + lumBL + 2.0 * lumB + lumBR;
    float gradMag = length(float2(gx, gy));
    float lumMask = saturate(gradMag * 4.0);

    // Color edge component using cardinal differences.
    float colorDiff = 0.0;
    colorDiff = max(colorDiff, ColorDifference(c, l));
    colorDiff = max(colorDiff, ColorDifference(c, r));
    colorDiff = max(colorDiff, ColorDifference(c, t));
    colorDiff = max(colorDiff, ColorDifference(c, b));
    float colMask = saturate(max(gradMag, colorDiff) * 4.0);

    if (EdgeMode == 0) // Luminance-only.
        return lumMask;
    else if (EdgeMode == 1) // Color-only.
        return colMask;
    else if (EdgeMode == 2) // Hybrid: 50:50 blend.
        return saturate(lumMask * 0.5 + colMask * 0.5);
    
    // Should not reach here if EdgeMode==3.
    return 0.0;
}

// Depth-only edge detection.
// Sample the depth at the center and four cardinal neighbors,
// then compute the maximum depth difference.
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

    // Multiplier adjusts sensitivity; tune as needed.
    return saturate(depthEdge * 10.0);
}

//------------------------------------------------------------------------------
// 5) Box Blur Function
//------------------------------------------------------------------------------

// Averages the color values of a 3x3 neighborhood.
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

// Adjusts the blended result based on a device-specific factor.
float3 ApplyDeviceSpecificProcessing(float3 original, float3 effectColor)
{
    float deviceFactor = 1.0;
    if (DevicePreset == 1)      // Steam Deck LCD.
        deviceFactor = 0.8;
    else if (DevicePreset == 2) // Steam Deck OLED (BOE).
        deviceFactor = 1.2;
    else if (DevicePreset == 3) // Steam Deck OLED LE.
        deviceFactor = 1.5;
    
    return lerp(original, effectColor, deviceFactor * 0.3);
}

//------------------------------------------------------------------------------
// 7) Main Pixel Shader
//------------------------------------------------------------------------------
float3 PS_VectorSeek(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float2 pixelSize = ReShade::PixelSize;
    float3 originalColor = GetPixelColor(uv);

    // Cache a 3x3 neighborhood for color-based edge methods.
    float3 tl = GetPixelColor(uv + pixelSize * float2(-1, -1));
    float3 t  = GetPixelColor(uv + pixelSize * float2( 0, -1));
    float3 tr = GetPixelColor(uv + pixelSize * float2( 1, -1));
    float3 l  = GetPixelColor(uv + pixelSize * float2(-1,  0));
    float3 c  = originalColor; // Already fetched.
    float3 r  = GetPixelColor(uv + pixelSize * float2( 1,  0));
    float3 bl = GetPixelColor(uv + pixelSize * float2(-1,  1));
    float3 b  = GetPixelColor(uv + pixelSize * float2( 0,  1));
    float3 br = GetPixelColor(uv + pixelSize * float2( 1,  1));

    float rawEdgeMask = 0.0;
    // Select edge detection method based on user setting.
    if (EdgeMode == 3)
    {
        // Depth-only edge detection.
        rawEdgeMask = ComputeDepthEdgeMask(uv, pixelSize);
    }
    else
    {
        // Use the cached 3x3 neighborhood for luminance/color/hybrid detection.
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
    if (rawEdgeMask < EdgeDetectionThreshold)
        return originalColor;

    // For strong edges, simply use the original color processed by device-specific adjustments.
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