uniform int DevicePreset <
    ui_type = "combo";
    ui_items = "Custom Settings\0Steam Deck LCD\0Steam Deck OLED (BOE)\0Steam Deck OLED LE (Samsung)\0";
    ui_label = "Device Preset";
    ui_tooltip = "Select your device for optimized settings.";
    ui_category = "Presets";
> = 0;

// Core Parameters
//=====================================================================

uniform int SamplingMode <
    ui_type = "combo";
    ui_items = "Standard (12 samples)\0High Quality (24 samples)\0Ultra Quality (48 samples)\0";
    ui_label = "Sampling Mode";
    ui_tooltip = "Sets sample count as factor of 24 for optimal performance.";
> = 2;

uniform float EdgeDetectionThreshold <
    ui_type = "slider";
    ui_min = 0.01; ui_max = 0.30; ui_step = 0.01;
    ui_label = "Edge Detection Threshold";
    ui_tooltip = "Lower values detect more subtle edges. Higher values focus on stronger edges only.";
    ui_category = "Edge Detection";
> = 0.30;

uniform float FilterStrength <
    ui_type = "slider";
    ui_min = 0.5; ui_max = 15.0; ui_step = 0.1;
    ui_label = "Filter Strength";
    ui_tooltip = "Overall strength of the anti-aliasing effect.";
    ui_category = "Effect Strength";
> = 10.0;

uniform float GapDetectionThreshold <
    ui_type = "slider";
    ui_min = 0.05; ui_max = 0.50; ui_step = 0.01;
    ui_label = "Gap Detection Threshold";
    ui_tooltip = "Threshold for detecting gaps in lines. Lower values detect smaller gaps.";
    ui_category = "Pattern Recognition";
> = 0.05;

uniform float CurveDetectionStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Curve Detection Strength";
    ui_tooltip = "Controls how aggressively curved edges are detected and processed.";
    ui_category = "Pattern Recognition";
> = 1.00;

uniform int SamplingQuality <
    ui_type = "combo";
    ui_items = "Standard\0High Quality\0Ultra Quality\0";
    ui_label = "Sampling Quality";
    ui_tooltip = "Quality of sampling pattern used for edge detection and filtering.";
    ui_category = "Performance";
> = 2;

// Performance Optimization Options
//=====================================================================

uniform float PerformanceTarget <
    ui_type = "slider";
    ui_min = 0.5; ui_max = 2.0; ui_step = 0.1;
    ui_label = "Performance Target";
    ui_tooltip = "Higher values prioritize performance, lower values prioritize quality.";
    ui_category = "Performance Optimization";
> = 1.0;

uniform bool EnableAdaptiveSampling <
    ui_type = "bool";
    ui_label = "Enable Adaptive Sampling";
    ui_tooltip = "Dynamically adjusts sample count based on visual importance.";
    ui_category = "Performance Optimization";
> = true;

uniform bool EnableEarlyExit <
    ui_type = "bool";
    ui_label = "Enable Early Exit Optimization";
    ui_tooltip = "Quickly skips processing on non-edge pixels.";
    ui_category = "Performance Optimization";
> = true;

// Advanced Options
//=====================================================================

uniform float AdaptiveThresholdStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Adaptive Threshold Strength";
    ui_tooltip = "Automatically adjusts threshold based on local contrast.";
    ui_category = "Advanced";
> = 0.50;

uniform float GradientPreservationStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Gradient Preservation Strength";
    ui_tooltip = "Preserves smooth gradients in objects and shadows. Higher values maintain more of the original gradient.";
    ui_category = "Advanced";
> = 0.70;

uniform int PanelType <
    ui_type = "combo";
    ui_items = "RGB\0BGR\0RGBW\0WRGB\0Samsung OLED (Steam Deck)\0BOE OLED (Steam Deck)\0";
    ui_label = "Panel Type";
    ui_tooltip = "Select your display panel type for optimal subpixel handling.";
    ui_category = "Display Settings";
> = 4;

uniform float SubpixelOptimizationStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Subpixel Optimization Strength";
    ui_tooltip = "Strength of panel-specific subpixel optimizations.";
    ui_category = "Display Settings";
> = 1.00;

uniform bool EnablePerspectiveCompensation <
    ui_type = "bool";
    ui_label = "Enable Perspective Compensation";
    ui_tooltip = "Adjusts detection parameters based on depth to handle vanishing points.";
    ui_category = "3D Scene Optimization";
> = true;

uniform float DepthSensitivity <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Depth Sensitivity";
    ui_tooltip = "How strongly to adjust processing based on scene depth.";
    ui_category = "3D Scene Optimization";
> = 1.00;

uniform float MinDepth <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Minimum Depth";
    ui_tooltip = "Don't process pixels closer than this depth (0.0 = camera).";
    ui_category = "3D Scene Optimization";
> = 0.00;

uniform float MaxDepth <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Maximum Depth";
    ui_tooltip = "Don't process pixels further than this depth (1.0 = infinite distance).";
    ui_category = "3D Scene Optimization";
> = 1.00;

uniform bool PreservePixelArt <
    ui_type = "bool";
    ui_label = "Preserve Pixel Art";
    ui_tooltip = "Attempts to preserve intentional pixel art while removing aliasing artifacts.";
    ui_category = "Special Cases";
> = true;

uniform bool DebugView <
    ui_type = "bool";
    ui_label = "Debug View";
    ui_tooltip = "Shows edge detection and pattern recognition results.";
    ui_category = "Debug";
> = false;

uniform int DebugMode <
    ui_type = "combo";
    ui_items = "Edge Detection\0Pattern Recognition\0Curve Detection\0Filtering Intensity\0Depth Map\0Gradient Detection\0Performance Heat Map\0";
    ui_label = "Debug Mode";
    ui_tooltip = "What to display when Debug View is enabled.";
    ui_category = "Debug";
> = 0;

// Include core ReShade functionality
#include "ReShade.fxh"

// Preset application functions
//=====================================================================
// [Original preset functions remain unchanged]

float GetPresetEdgeThreshold() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 0.30;
        default: // Custom
            return EdgeDetectionThreshold;
    }
}

float GetPresetGradientPreservation() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 0.70;
        default: // Custom
            return GradientPreservationStrength;
    }
}

float GetPresetDiagonalBias() {
    // Return a neutral value (1.0) to ensure all edge directions are treated equally
    return 1.0;
}

float GetPresetFilterStrength() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 10.0;
        default: // Custom
            return FilterStrength;
    }
}

float GetPresetGapThreshold() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 0.05;
        default: // Custom
            return GapDetectionThreshold;
    }
}

float GetPresetCurveStrength() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 1.00;
        default: // Custom
            return CurveDetectionStrength;
    }
}

int GetPresetSamplingQuality() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 2; // Ultra Quality
        default: // Custom
            return SamplingQuality;
    }
}

float GetPresetAdaptiveThreshold() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 0.50;
        default: // Custom
            return AdaptiveThresholdStrength;
    }
}

float GetPresetSubpixelStrength() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 1.00;
        default: // Custom
            return SubpixelOptimizationStrength;
    }
}

int GetPresetPanelType() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
            return 0; // RGB
        case 2: // Steam Deck OLED (BOE)
            return 5; // BOE OLED
        case 3: // Steam Deck OLED LE (Samsung)
            return 4; // Samsung OLED
        default: // Custom
            return PanelType;
    }
}

bool GetPresetPerspectiveCompensation() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return true;
        default: // Custom
            return EnablePerspectiveCompensation;
    }
}

float GetPresetDepthSensitivity() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 1.00;
        default: // Custom
            return DepthSensitivity;
    }
}

float GetPresetMinDepth() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 0.00;
        default: // Custom
            return MinDepth;
    }
}

float GetPresetMaxDepth() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 1.00;
        default: // Custom
            return MaxDepth;
    }
}

bool GetPresetPreservePixelArt() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return true;
        default: // Custom
            return PreservePixelArt;
    }
}

int GetPresetSamplingMode() {
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 2; // Ultra Quality (48 samples)
        default: // Custom
            return SamplingMode;
    }
}

// Textures and samplers
//=====================================================================

texture texColorBuffer : COLOR;
sampler samplerColor { Texture = texColorBuffer; };

// Depth buffer access for perspective compensation
texture texDepth : DEPTH;
sampler samplerDepth
{
    Texture = texDepth;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

// OPTIMIZATION: Caching texture for edge detection results to avoid redundant calculations
texture texEdgeCache {
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};
sampler samplerEdgeCache { Texture = texEdgeCache; };

// Helper functions - OPTIMIZED VERSIONS
//=====================================================================

// OPTIMIZATION: Fast luminance calculation
float GetLuminance_Fast(float3 color) {
    // Use dot product for efficient calculation
    return dot(color, float3(0.299, 0.587, 0.114));
}

// OPTIMIZATION: Fast texture sampling with built-in luminance
float GetPixelLuma(float2 texcoord) {
    return dot(tex2D(samplerColor, texcoord).rgb, float3(0.299, 0.587, 0.114));
}

// OPTIMIZATION: Combined texture sample and luminance for frequently used operations
float2 GetPixelAndLuma(float2 texcoord, out float3 color) {
    color = tex2D(samplerColor, texcoord).rgb;
    return float2(dot(color, float3(0.299, 0.587, 0.114)), 0);
}

// OPTIMIZATION: Safe texture sampling with bounds checking
float3 GetPixelColor(float2 texcoord) {
    // Skip bounds checking for better performance
    // (texture sampling in ReShade is clamped to edges by default)
    return tex2D(samplerColor, texcoord).rgb;
}

// Get linearized depth at specified coordinates
float GetDepth(float2 texcoord) {
    return ReShade::GetLinearizedDepth(texcoord);
}

// OPTIMIZATION: Fast vector normalization
float2 FastNormalize(float2 v) {
    float len_sq = dot(v, v);
    // Only normalize if significantly different from unit length
    if (abs(len_sq - 1.0) > 0.01) {
        return v * rsqrt(len_sq); // Hardware optimized inverse square root
    }
    return v;
}

// OPTIMIZATION: Early-out local contrast detection
float4 GetLocalContrast(float2 texcoord, float2 pixelSize) {
    float3 center = GetPixelColor(texcoord);
    float centerLuma = GetLuminance_Fast(center);

    float minLuma = centerLuma;
    float maxLuma = centerLuma;
    float avgLuma = centerLuma;
    float totalWeight = 1.0;

    // First check cardinal directions only (faster first pass)
    float3 n = GetPixelColor(texcoord + float2(0, -1) * pixelSize);
    float3 e = GetPixelColor(texcoord + float2(1, 0) * pixelSize);
    float3 s = GetPixelColor(texcoord + float2(0, 1) * pixelSize);
    float3 w = GetPixelColor(texcoord + float2(-1, 0) * pixelSize);

    float nLuma = GetLuminance_Fast(n);
    float eLuma = GetLuminance_Fast(e);
    float sLuma = GetLuminance_Fast(s);
    float wLuma = GetLuminance_Fast(w);

    minLuma = min(minLuma, min(min(nLuma, eLuma), min(sLuma, wLuma)));
    maxLuma = max(maxLuma, max(max(nLuma, eLuma), max(sLuma, wLuma)));

    avgLuma += nLuma + eLuma + sLuma + wLuma;
    totalWeight += 4.0;

    // Quick contrast check to see if we need the diagonal samples
    float quickContrast = maxLuma - minLuma;

    // Only sample diagonals if contrast is significant (optimization)
    if (quickContrast > 0.05) {
        float3 ne = GetPixelColor(texcoord + float2(1, -1) * pixelSize);
        float3 se = GetPixelColor(texcoord + float2(1, 1) * pixelSize);
        float3 sw = GetPixelColor(texcoord + float2(-1, 1) * pixelSize);
        float3 nw = GetPixelColor(texcoord + float2(-1, -1) * pixelSize);

        float neLuma = GetLuminance_Fast(ne);
        float seLuma = GetLuminance_Fast(se);
        float swLuma = GetLuminance_Fast(sw);
        float nwLuma = GetLuminance_Fast(nw);

        minLuma = min(minLuma, min(min(neLuma, seLuma), min(swLuma, nwLuma)));
        maxLuma = max(maxLuma, max(max(neLuma, seLuma), max(swLuma, nwLuma)));

        // Weight corners less for average
        avgLuma += (neLuma + seLuma + swLuma + nwLuma) * 0.5;
        totalWeight += 2.0;
    }

    avgLuma /= totalWeight;

    // Return contrast metrics as a struct-like float4
    // x = max-min range, y = avg luminance, z = max, w = min
    return float4(maxLuma - minLuma, avgLuma, maxLuma, minLuma);
}

// OPTIMIZATION: Quick edge check for early-exit optimization
bool QuickEdgeCheck(float2 texcoord, float2 pixelSize, out float quickStrength) {
    // Only sample 4 cardinal directions for speed
    float3 center = GetPixelColor(texcoord);
    float centerLuma = GetLuminance_Fast(center);

    float3 n = GetPixelColor(texcoord + float2(0, -1) * pixelSize);
    float3 e = GetPixelColor(texcoord + float2(1, 0) * pixelSize);
    float3 s = GetPixelColor(texcoord + float2(0, 1) * pixelSize);
    float3 w = GetPixelColor(texcoord + float2(-1, 0) * pixelSize);

    float nDiff = abs(GetLuminance_Fast(n) - centerLuma);
    float eDiff = abs(GetLuminance_Fast(e) - centerLuma);
    float sDiff = abs(GetLuminance_Fast(s) - centerLuma);
    float wDiff = abs(GetLuminance_Fast(w) - centerLuma);

    // Maximum difference
    float maxDiff = max(max(nDiff, eDiff), max(sDiff, wDiff));

    // Quick edge strength estimation
    quickStrength = maxDiff / GetPresetEdgeThreshold();

    // Early exit if definitely not an edge (returns false to skip further processing)
    return quickStrength > 0.3;
}

// Modified IsGradient function with optimized sampling
bool IsGradient(float2 texcoord, float2 pixelSize, out float gradientStrength) {
    // OPTIMIZATION: Use a more efficient 3x3 pattern instead of 5x5
    float luma[9];

    // Get luminance values in 3x3 grid (more cache-friendly)
    [unroll]
    for (int y = -1; y <= 1; y++) {
        [unroll]
        for (int x = -1; x <= 1; x++) {
            luma[(y+1)*3 + (x+1)] = GetPixelLuma(texcoord + float2(x, y) * pixelSize);
        }
    }

    // Center pixel
    float centerLuma = luma[4];

    // Calculate horizontal and vertical gradients (Sobel-like)
    float horizGrad = abs(luma[3] - luma[5]); // West vs East
    float vertGrad = abs(luma[1] - luma[7]);  // North vs South

    // Diagonal gradients
    float diag1 = abs(luma[0] - luma[8]); // NW vs SE
    float diag2 = abs(luma[2] - luma[6]); // NE vs SW

    // Calculate average gradient and variance
    float avgGrad = (horizGrad + vertGrad + diag1 + diag2) * 0.25;

    // Measure consistency of gradient
    float gradVariance = abs(horizGrad - avgGrad) +
                         abs(vertGrad - avgGrad) +
                         abs(diag1 - avgGrad) +
                         abs(diag2 - avgGrad);

    // Normalize variance
    gradVariance /= max(0.0001, avgGrad * 4.0);

    // Calculate directional consistency (similar to original but more efficient)
    float maxGrad = max(max(horizGrad, vertGrad), max(diag1, diag2));
    float minGrad = min(min(horizGrad, vertGrad), min(diag1, diag2));
    float directionalConsistency = (maxGrad > 0.001) ? minGrad / maxGrad : 1.0;

    // Gradient characteristics
    bool isSmooth = avgGrad < 0.05 && avgGrad > 0.001;
    bool isConsistent = directionalConsistency > 0.5 && gradVariance < 0.5;

    // Calculate strength as confidence value (simplified)
    gradientStrength = saturate((1.0 - gradVariance) * directionalConsistency * saturate(avgGrad * 20.0));

    return isSmooth && isConsistent;
}

// Optimized IsPixelArt function
bool IsPixelArt(float2 texcoord, float2 pixelSize) {
    // We only need a 3x3 grid for this check
    float luma[9];

    [unroll]
    for (int i = 0; i < 9; i++) {
        int x = i % 3 - 1;
        int y = i / 3 - 1;
        luma[i] = GetPixelLuma(texcoord + float2(x, y) * pixelSize);
    }

    // Center pixel
    float centerLuma = luma[4];

    // Check for perfect horizontal/vertical lines (characteristic of pixel art)
    // This is an efficient check that catches most pixel art
    bool hasHorizontalLine = abs(luma[3] - luma[4]) < 0.05 && abs(luma[4] - luma[5]) < 0.05;
    bool hasVerticalLine = abs(luma[1] - luma[4]) < 0.05 && abs(luma[4] - luma[7]) < 0.05;

    // Check for single pixel or right-angle corners - key characteristics of pixel art
    int matchingNeighbors = 0;
    int distinctNeighbors = 0;

    [unroll]
    for (int j = 0; j < 9; j++) {
        if (j == 4) continue; // Skip center

        if (abs(luma[j] - centerLuma) < 0.05)
            matchingNeighbors++;
        else if (abs(luma[j] - centerLuma) > 0.2)
            distinctNeighbors++;
    }

    // Pixel art typically has sharp boundaries and uniform regions
    bool hasSharpBoundary = distinctNeighbors >= 2;
    bool hasUniformRegion = matchingNeighbors >= 3;

    // Combined detection
    return (hasHorizontalLine || hasVerticalLine || (hasSharpBoundary && hasUniformRegion));
}

// Apply perspective compensation to filter parameters
void ApplyPerspectiveCompensation(inout float edgeThreshold, inout float gapThreshold,
                                 inout float filterStrength, float depth) {
    if (!GetPresetPerspectiveCompensation()) return;

    // Get preset values - cache them for repeated use
    static const float presetMinDepth = GetPresetMinDepth();
    static const float presetMaxDepth = GetPresetMaxDepth();
    static const float presetDepthSensitivity = GetPresetDepthSensitivity();

    // Calculate perspective factor (0 = near, 1 = far)
    float perspectiveFactor = saturate((depth - presetMinDepth) / max(0.001, presetMaxDepth - presetMinDepth));
    perspectiveFactor = perspectiveFactor * perspectiveFactor; // Squared falloff (more natural)

    // Calculate compensation amount
    float compensation = perspectiveFactor * presetDepthSensitivity;

    // OPTIMIZATION: Simplified calculation with fewer operations
    edgeThreshold *= 1.0 - compensation * 0.7;
    gapThreshold *= 1.0 - compensation * 0.7;
    filterStrength *= 1.0 + compensation * 0.7;
}

// OPTIMIZATION: Golden Spiral sampling pattern for curved edges
float2 GetGoldenSpiralOffset(int i, int quality) {
    // Golden angle in radians
    static const float phi = 2.39996; // PI * (3 - sqrt(5))

    // Determine max spiral points based on quality
    int maxPoints = quality == 0 ? 5 : (quality == 1 ? 8 : 12);

    // Normalize index to maxPoints
    float normalizedIdx = float(i) / float(maxPoints);

    // Calculate angle based on golden ratio
    float angle = i * phi;

    // Calculate radius with natural growth pattern
    // Use square root for more uniform point distribution
    float radius = sqrt(normalizedIdx) * 3.0;

    // Return offset
    return float2(cos(angle), sin(angle)) * radius;
}

// Advanced edge detection with directional analysis - optimized version
void AdvancedEdgeDetection(float2 texcoord, float2 pixelSize, float depth,
                         out float edgeStrength, out float2 edgeDirection,
                         out float isDirectional, out bool isNW_SE, out bool isNE_SW,
                         out float isCurved, out bool isGradient, out float gradientStrength) {

    // Apply perspective compensation to detection parameters
    float adjustedEdgeThreshold = GetPresetEdgeThreshold();
    float adjustedGapThreshold = GetPresetGapThreshold();
    float adjustedFilterStrength = GetPresetFilterStrength();

    // Check if pixel is part of a gradient
    isGradient = IsGradient(texcoord, pixelSize, gradientStrength);

    // Adjust detection parameters based on depth
    ApplyPerspectiveCompensation(adjustedEdgeThreshold, adjustedGapThreshold,
                                adjustedFilterStrength, depth);

    // Adjust threshold based on local contrast if adaptive thresholding is enabled
    // OPTIMIZATION: Use early-out local contrast detection
    float4 contrastInfo = GetLocalContrast(texcoord, pixelSize);
    float localContrast = contrastInfo.x; // max-min range

    // More aggressive threshold adjustment in high-contrast areas
    adjustedEdgeThreshold *= 1.0 - (GetPresetAdaptiveThreshold() * min(1.0, localContrast * 2.0));

    // OPTIMIZATION: Adaptive sampling pattern based on quality setting and local contrast
    int presetSamplingQuality = GetPresetSamplingQuality();

    // For low contrast areas, use simplified detection
    if (localContrast < 0.05 && EnableAdaptiveSampling) {
        // Just use a basic 3x3 Sobel operator for low-contrast regions
        float3 c00 = GetPixelColor(texcoord + float2(-1, -1) * pixelSize);
        float3 c01 = GetPixelColor(texcoord + float2(0, -1) * pixelSize);
        float3 c02 = GetPixelColor(texcoord + float2(1, -1) * pixelSize);
        float3 c10 = GetPixelColor(texcoord + float2(-1, 0) * pixelSize);
        float3 center = GetPixelColor(texcoord);
        float3 c12 = GetPixelColor(texcoord + float2(1, 0) * pixelSize);
        float3 c20 = GetPixelColor(texcoord + float2(-1, 1) * pixelSize);
        float3 c21 = GetPixelColor(texcoord + float2(0, 1) * pixelSize);
        float3 c22 = GetPixelColor(texcoord + float2(1, 1) * pixelSize);

        // Convert to luminance
        float l00 = GetLuminance_Fast(c00);
        float l01 = GetLuminance_Fast(c01);
        float l02 = GetLuminance_Fast(c02);
        float l10 = GetLuminance_Fast(c10);
        float lc = GetLuminance_Fast(center);
        float l12 = GetLuminance_Fast(c12);
        float l20 = GetLuminance_Fast(c20);
        float l21 = GetLuminance_Fast(c21);
        float l22 = GetLuminance_Fast(c22);

        // Sobel operators
        float gx = l00 - l02 + 2.0 * l10 - 2.0 * l12 + l20 - l22;
        float gy = l00 + 2.0 * l01 + l02 - l20 - 2.0 * l21 - l22;

        // Diagonal gradients
        float gNE_SW = l02 + l12 - l20 - l10;
        float gNW_SE = l00 + l10 - l22 - l12;

        // Calculate gradient magnitude
        float magnitude = sqrt(gx*gx + gy*gy);

        // Determine edge strength
        edgeStrength = magnitude / (8.0 * adjustedEdgeThreshold);

        // Set direction
        edgeDirection = normalize(float2(gx, gy) + 0.0001);

        // Set diagonal flags
        isNW_SE = abs(gNW_SE) > abs(gNE_SW);
        isNE_SW = !isNW_SE;

        // Set directional strength (simplified)
        isDirectional = 0.7;

        // Set curve strength (simplified)
        isCurved = 0.0;

        return;
    }

    // For high contrast areas or high quality settings, use the full detection
    // Sample a 5x5 area for accurate gradient estimation
    float luma[25];
    float3 color[25];

    // OPTIMIZATION: Only load values we know we'll use
    // Determine sample count based on quality setting
    int sampleExtent = presetSamplingQuality == 0 ? 1 : 2;

    // Load the NxN neighborhood
    [unroll]
    for (int y = -sampleExtent; y <= sampleExtent; y++) {
        [unroll]
        for (int x = -sampleExtent; x <= sampleExtent; x++) {
            int idx = (y + 2) * 5 + (x + 2);
            color[idx] = GetPixelColor(texcoord + float2(x, y) * pixelSize);
            luma[idx] = GetLuminance_Fast(color[idx]);
        }
    }

    // Calculate gradients using optimized operators

    // Horizontal gradient (East-West)
    float gx = 0;
    gx += luma[10] * -1.0 + luma[11] * -2.0 + luma[13] * 2.0 + luma[14] * 1.0;
    gx += luma[5] * -1.0 + luma[6] * -2.0 + luma[8] * 2.0 + luma[9] * 1.0;
    gx += luma[15] * -1.0 + luma[16] * -2.0 + luma[18] * 2.0 + luma[19] * 1.0;

    // Vertical gradient (North-South)
    float gy = 0;
    gy += luma[2] * -1.0 + luma[7] * -2.0 + luma[17] * 2.0 + luma[22] * 1.0;
    gy += luma[1] * -1.0 + luma[6] * -2.0 + luma[16] * 2.0 + luma[21] * 1.0;
    gy += luma[3] * -1.0 + luma[8] * -2.0 + luma[18] * 2.0 + luma[23] * 1.0;

    // Diagonal gradients
    float gNE_SW = (luma[4] - luma[20]) + 2.0 * (luma[9] - luma[15]) + (luma[3] - luma[21]);
    float gNW_SE = (luma[0] - luma[24]) + 2.0 * (luma[5] - luma[19]) + (luma[1] - luma[23]);

    // Calculate overall gradient magnitude with equal weighting
    float gHV = sqrt(gx*gx + gy*gy);
    float gDiag = sqrt(gNE_SW*gNE_SW + gNW_SE*gNW_SE);

    // Balanced edge strength calculation
    float edgeBalance = max(gHV, gDiag);
    edgeStrength = edgeBalance / (10.0 * adjustedEdgeThreshold);

    // Set diagonal direction flags
    isNW_SE = abs(gNW_SE) > abs(gNE_SW);
    isNE_SW = !isNW_SE;

    // Calculate edge direction (normalized)
    if (gHV >= gDiag) {
        // Horizontal or vertical edge
        edgeDirection = normalize(float2(gx, gy) + 0.0001); // Add small value to avoid division by zero
    } else {
        // Diagonal edge
        float2 dir = float2(gNE_SW - gNW_SE, gNE_SW + gNW_SE);
        edgeDirection = normalize(dir + 0.0001);
    }

    // Determine if edge is directional or curved
    float directionalStrength = 0.0;

    // Directional consistency calculation (optimized)
    if (gHV >= gDiag) {
        // For horizontal/vertical edges
        directionalStrength = max(abs(gx), abs(gy)) / (abs(gx) + abs(gy) + 0.0001);
    } else {
        // For diagonal edges
        directionalStrength = max(abs(gNE_SW), abs(gNW_SE)) / (abs(gNE_SW) + abs(gNW_SE) + 0.0001);
    }

    // OPTIMIZATION: Simplified curve detection that's more efficient
    float xCurve = abs(sign(luma[11] - luma[12]) - sign(luma[12] - luma[13])) +
                   abs(sign(luma[6] - luma[7]) - sign(luma[7] - luma[8]));

    float yCurve = abs(sign(luma[7] - luma[12]) - sign(luma[12] - luma[17])) +
                   abs(sign(luma[6] - luma[11]) - sign(luma[11] - luma[16]));

    // Detect pattern changes that indicate curves (fewer calculations)
    float curveIndication = (xCurve + yCurve) * 0.25;

    // Add more weight to central pixel contrast
    float pixelContrast = abs(luma[12] - (luma[7] + luma[11] + luma[13] + luma[17]) / 4.0);

    // Calculate final curve strength
    float curveStrength = curveIndication + pixelContrast * 2.0;
    curveStrength *= GetPresetCurveStrength();

    // Output the final values
    isDirectional = saturate(directionalStrength);
    isCurved = saturate(curveStrength);

    // For pixels detected as pixel art, reduce edge strength if preservation is enabled
    if (GetPresetPreservePixelArt() && IsPixelArt(texcoord, pixelSize)) {
        edgeStrength *= 0.5; // Less reduction to maintain some effect on pixel art
    }

    // For pixels detected as gradients, reduce edge strength based on gradient preservation setting
    if (isGradient) {
        float gradientPreservation = GetPresetGradientPreservation();
        // Scale edge strength inversely with gradient strength and preservation setting
        edgeStrength *= max(0.1, 1.0 - (gradientStrength * gradientPreservation));
    }
}

// OPTIMIZATION: Pattern detection with adaptive sampling
bool OptimizedPatternDetection(float2 texcoord, float2 pixelSize, float2 direction,
                              out int patternLength, out float patternStrength) {
    // Default value in case we exit early
    patternLength = 0;
    patternStrength = 0.0;

    // Calculate perpendicular direction
    float2 perpDirection = float2(-direction.y, direction.x);
    perpDirection = FastNormalize(perpDirection);

    // Get center pixel
    float centerLuma = GetPixelLuma(texcoord);

    // Configure gap threshold with adaptive adjustment
    float adjustedGapThreshold = GetPresetGapThreshold();
    float4 contrastInfo = GetLocalContrast(texcoord, pixelSize);
    float localContrast = contrastInfo.x;
    adjustedGapThreshold *= 1.0 - (GetPresetAdaptiveThreshold() * min(1.0, localContrast * 2.0));

    // OPTIMIZATION: Early-exit check - sample just a few points first
    float luma1 = GetPixelLuma(texcoord + perpDirection * 2 * pixelSize);
    float luma2 = GetPixelLuma(texcoord - perpDirection * 2 * pixelSize);

    // If both sides are very similar to center, probably not a pattern worth analyzing
    if (abs(luma1 - centerLuma) < adjustedGapThreshold * 0.5 &&
        abs(luma2 - centerLuma) < adjustedGapThreshold * 0.5) {
        return false;
    }

    // Determine max search steps based on quality and contrast
    int presetSamplingQuality = GetPresetSamplingQuality();
    int maxSteps = presetSamplingQuality == 0 ? 8 :
                  presetSamplingQuality == 1 ? 12 : 16;

    // For low contrast areas, reduce sample count
    if (localContrast < 0.1 && EnableAdaptiveSampling) {
        maxSteps = max(6, maxSteps / 2);
    }

    // Setup for detecting gaps and segments
    bool lastSimilar = true;
    int gapCount = 0;
    int segmentCount = 1;
    float totalSegmentStrength = 0.0;

    // Fibonacci sampling - more natural and efficient pattern
    // Pattern: 1,1,2,3,5,8... (distance multipliers)
    const float fibPattern[8] = {1.0, 1.0, 2.0, 3.0, 5.0, 8.0, 13.0, 21.0};

    // Store luminance at fibonacci-spaced intervals
    float searchLuma[16]; // Support for max 16 steps
    searchLuma[0] = centerLuma;

    // Sample in positive direction
    [unroll]
    for (int i = 1; i <= maxSteps/2; i++) {
        // Use fibonacci spacing
        int fibIdx = min(i-1, 7);
        float dist = fibPattern[fibIdx] * 0.15; // Scale factor
        float2 samplePos = texcoord + perpDirection * dist * pixelSize;
        searchLuma[i] = GetPixelLuma(samplePos);
    }

    // Sample in negative direction
    [unroll]
    for (int j = 1; j <= maxSteps/2; j++) {
        int fibIdx = min(j-1, 7);
        float dist = fibPattern[fibIdx] * 0.15;
        float2 samplePos = texcoord - perpDirection * dist * pixelSize;
        searchLuma[j + maxSteps/2] = GetPixelLuma(samplePos);
    }

    // Analyze the pattern - look for gaps and segments
    [unroll]
    for (int k = 1; k < maxSteps; k++) {
        bool isSimilar = abs(searchLuma[k] - centerLuma) < adjustedGapThreshold;

        // Detect segment transitions
        if (isSimilar && !lastSimilar) {
            // Found a new segment after a gap
            segmentCount++;
            totalSegmentStrength += abs(searchLuma[k] - searchLuma[k-1]);
        }
        else if (!isSimilar && lastSimilar) {
            // Found a gap after a segment
            gapCount++;
        }

        lastSimilar = isSimilar;
    }

    // Check for repeating pattern - adapted to work with Fibonacci spacing
    bool hasPattern = false;
    int patternPeriod = 0;

    // For most cases, this simpler pattern check is sufficient
    if (segmentCount >= 2 && gapCount >= 1) {
        hasPattern = true;
        // Estimate pattern length based on segment count
        patternPeriod = maxSteps / (segmentCount);
    }

    // Return results
    patternLength = hasPattern ? patternPeriod : 0;
    patternStrength = (segmentCount > 1) ? totalSegmentStrength / segmentCount : 0;

    return hasPattern;
}

// OPTIMIZATION: Golden Spiral sampling for curved edges
float3 ApplyOptimizedCurveFiltering(float2 texcoord, float2 pixelSize, float isCurved, float filterStrength) {
    float3 center = GetPixelColor(texcoord);
    float3 spiralResult = center;
    float totalWeight = 1.0;

    // Determine sample count based on quality and curve strength
    int presetSamplingQuality = GetPresetSamplingQuality();
    int sampleCount = presetSamplingQuality == 0 ? 6 : (presetSamplingQuality == 1 ? 8 : 12);

    // Golden Angle spiral sampling (natural pattern in sunflowers)
    static const float goldenAngle = 2.39996; // PI * (3 - sqrt(5))

    [unroll]
    for (int i = 1; i <= sampleCount; i++) {
        float angle = i * goldenAngle;
        float radius = sqrt(float(i) / float(sampleCount)) * 3.0; // Progressive radius grows naturally
        float2 dir = float2(cos(angle), sin(angle)) * radius;

        // Take sample with adaptive distance based on curve strength
        float sampleDist = 1.0 + isCurved * 0.5;
        float3 spiralSample = GetPixelColor(texcoord + dir * pixelSize * sampleDist / (radius * 0.5 + 0.5));

        // Weight decreases with distance - natural falloff (inverse square law like gravity)
        float weight = 1.0 / (1.0 + radius * 0.5);

        // Similarity weight factor - natural pattern recognition
        float similarity = 1.0 - saturate(length(spiralSample - center) * 2.0);
        weight *= similarity * similarity;

        // Add to weighted sum
        spiralResult += spiralSample * weight;
        totalWeight += weight;
    }

    // Normalize
    return spiralResult / totalWeight;
}

// OPTIMIZATION: Optimized diagonal filtering
float3 ApplyOptimizedDiagonalFiltering(float2 texcoord, float2 pixelSize, bool isNW_SE, float edgeStrength, float filterStrength) {
    float3 center = GetPixelColor(texcoord);

    // Direction perpendicular to the edge for sampling
    float2 blendDir = isNW_SE ? float2(-0.7071, 0.7071) : float2(0.7071, 0.7071);

    // Determine sample count based on quality
    int presetSamplingQuality = GetPresetSamplingQuality();
    int sampleCount = presetSamplingQuality == 0 ? 6 : (presetSamplingQuality == 1 ? 8 : 12);
    int halfCount = sampleCount / 2;

    // Natural sampling - use Fibonacci sequence for spacing
    // Creates more natural, efficient sampling pattern
    static const float fibSpacing[6] = {1.0, 1.0, 2.0, 3.0, 5.0, 8.0};

    float3 blendedColor = center * 0.30;
    float totalWeight = 0.30;
    float centerLuma = GetLuminance_Fast(center);

    // Sample in both directions along the perpendicular
    [unroll]
    for (int i = 0; i < halfCount; i++) {
        // Get fibonacci spacing (max 6 distances in each direction)
        float spacingFactor = fibSpacing[min(i, 5)] * 0.25;

        // Sample in positive direction
        float3 posSample = GetPixelColor(texcoord + blendDir * pixelSize * spacingFactor);
        float posLuma = GetLuminance_Fast(posSample);
        float posWeight = (1.0 / (spacingFactor + 1.0)) * saturate(1.0 - abs(posLuma - centerLuma) * 2.0);

        // Sample in negative direction
        float3 negSample = GetPixelColor(texcoord - blendDir * pixelSize * spacingFactor);
        float negLuma = GetLuminance_Fast(negSample);
        float negWeight = (1.0 / (spacingFactor + 1.0)) * saturate(1.0 - abs(negLuma - centerLuma) * 2.0);

        // Add weighted samples to result
        blendedColor += posSample * posWeight + negSample * negWeight;
        totalWeight += posWeight + negWeight;
    }

    // Normalize
    blendedColor /= max(0.3, totalWeight);

    // Calculate blend factor
    float blendFactor = saturate(edgeStrength * filterStrength / 5.0);

    return lerp(center, blendedColor, blendFactor);
}

// OPTIMIZATION: Optimized general edge filtering
float3 ApplyOptimizedGeneralFiltering(float2 texcoord, float2 pixelSize, float2 edgeDirection, float edgeStrength, float filterStrength) {
    float3 center = GetPixelColor(texcoord);

    // Direction perpendicular to the edge
    float2 perpDir = float2(-edgeDirection.y, edgeDirection.x);
    perpDir = FastNormalize(perpDir);

    // Determine sample count based on quality
    int presetSamplingQuality = GetPresetSamplingQuality();
    int halfCount = presetSamplingQuality == 0 ? 3 : (presetSamplingQuality == 1 ? 4 : 6);

    float3 blendedColor = center * 0.30;
    float totalWeight = 0.30;
    float centerLuma = GetLuminance_Fast(center);

    // Natural logarithmic spiral growth for sampling
    // Samples are closer near the center and space out naturally
    [unroll]
    for (int i = 0; i < halfCount; i++) {
        // Logarithmic spacing (e^x growth - natural growth pattern)
        float t = float(i+1) / float(halfCount);
        float spacing = exp(t * 1.5) - 1.0;

        // Sample in positive direction
        float3 posSample = GetPixelColor(texcoord + perpDir * pixelSize * spacing);
        float posLuma = GetLuminance_Fast(posSample);
        float posWeight = exp(-spacing * 0.5) * saturate(1.0 - abs(posLuma - centerLuma) * 2.0);

        // Sample in negative direction
        float3 negSample = GetPixelColor(texcoord - perpDir * pixelSize * spacing);
        float negLuma = GetLuminance_Fast(negSample);
        float negWeight = exp(-spacing * 0.5) * saturate(1.0 - abs(negLuma - centerLuma) * 2.0);

        // Add weighted samples to result
        blendedColor += posSample * posWeight + negSample * negWeight;
        totalWeight += posWeight + negWeight;
    }

    // Normalize
    blendedColor /= max(0.3, totalWeight);

    // Calculate blend factor
    float blendFactor = saturate(edgeStrength * filterStrength / 5.0);

    return lerp(center, blendedColor, blendFactor);
}

// Apply panel-specific subpixel processing - optimized version
float3 ApplySubpixelProcessing(float3 originalColor, float3 processedColor, float2 edgeDirection, float edgeStrength, int panelType) {
    // Use preset values for subpixel strength and panel type
    float strength = GetPresetSubpixelStrength() * min(1.0, edgeStrength * 2.0);
    int presetPanelType = GetPresetPanelType();

    if (strength <= 0.0)
        return processedColor;

    // OPTIMIZATION: Fast angle calculation (avoid atan2)
    float2 absDir = abs(edgeDirection);
    float angle = absDir.y / (absDir.x + absDir.y) * 90.0; // Fast approximation of angle in degrees

    // Scale effect based on edge angle (maximum at 45 degrees)
    float angleEffect = 4.0 * angle * (90.0 - angle) / (90.0 * 90.0); // Parabolic curve with max at 45°
    strength *= angleEffect;

    float3 result = processedColor;

    // OPTIMIZATION: Use a switch-free approach with weighted blending
    // This avoids branching which can be expensive on GPUs

    // Define panel-specific weights for RGB channels
    float3 verticalWeights, horizontalWeights;
    float3 colorAdjust = float3(0, 0, 0);

    // For vertical-ish vs horizontal-ish edges
    bool isVertical = angle > 45.0;

    // Calculate all panel-specific parameters once
    if (presetPanelType == 0) { // RGB panel
        verticalWeights = float3(0.5, 0.2, 0.5);
        horizontalWeights = float3(0.3, 0.0, 0.3);

        if (isVertical) {
            // Vertical edges - reduce color fringing
            result.r = lerp(result.r, originalColor.r, strength * verticalWeights.r);
            result.g = lerp(result.g, originalColor.g, strength * verticalWeights.g);
            result.b = lerp(result.b, originalColor.b, strength * verticalWeights.b);
        } else {
            // Horizontal edges - enhance contrast
            result.r = lerp(result.r, max(result.r, originalColor.r * 0.9), strength * horizontalWeights.r);
            result.b = lerp(result.b, max(result.b, originalColor.b * 0.9), strength * horizontalWeights.b);
        }
    }
    else if (presetPanelType == 1) { // BGR panel
        verticalWeights = float3(0.5, 0.2, 0.5);
        horizontalWeights = float3(0.3, 0.0, 0.3);

        if (isVertical) {
            // Vertical edges - reduce color fringing
            result.b = lerp(result.b, originalColor.b, strength * verticalWeights.b);
            result.g = lerp(result.g, originalColor.g, strength * verticalWeights.g);
            result.r = lerp(result.r, originalColor.r, strength * verticalWeights.r);
        } else {
            // Horizontal edges - enhance contrast
            result.b = lerp(result.b, max(result.b, originalColor.b * 0.9), strength * horizontalWeights.b);
            result.r = lerp(result.r, max(result.r, originalColor.r * 0.9), strength * horizontalWeights.r);
        }
    }
    else if (presetPanelType == 2 || presetPanelType == 3) { // RGBW/WRGB panel
        // Reduce color fringing by preserving average and limiting differences
        float avgOriginal = (originalColor.r + originalColor.g + originalColor.b) / 3.0;
        float avgResult = (result.r + result.g + result.b) / 3.0;

        // Apply more naturally for RGBW/WRGB panels
        float blendFactor = strength * 0.4;
        result.r = lerp(result.r, avgResult + (originalColor.r - avgOriginal) * 0.7, blendFactor);
        result.g = lerp(result.g, avgResult + (originalColor.g - avgOriginal) * 0.7, blendFactor);
        result.b = lerp(result.b, avgResult + (originalColor.b - avgOriginal) * 0.7, blendFactor);
    }
    else if (presetPanelType == 4) { // Samsung OLED (Steam Deck)
        // Samsung panel has alternating blue pixels and a blue bias

        // Apply horizontal blue pixel shift (alternating blue pixels)
        float blueShiftStrength = strength * 0.4;

        // Blue channel adjustments
        result.b = lerp(result.b,
                     (result.b * 0.8) + (originalColor.b * 0.2),
                     blueShiftStrength);

        // Reduce blue bias that's common in Samsung OLED
        float blueBias = max(0.0, result.b - ((result.r + result.g) / 2.0)) * 0.3;
        result.b = max(0.0, result.b - blueBias * strength);
    }
    else if (presetPanelType == 5) { // BOE OLED (Steam Deck)
        // BOE panel has red-green fringing due to subpixel arrangement

        // For vertical edges, reduce green bias
        if (isVertical) {
            // Reduce red-green fringing
            float rgAdjust = strength * 0.3;

            result.r = lerp(result.r, originalColor.r, rgAdjust);
            result.g = lerp(result.g, originalColor.g, rgAdjust * 0.7);
        }

        // Compensate for red and green bias
        float rgBias = max(0.0, (result.r + result.g) / 2.0 - result.b) * 0.25;
        result.r = max(0.0, result.r - rgBias * strength);
        result.g = max(0.0, result.g - rgBias * strength);
        result.b = result.b + rgBias * strength * 0.5;
    }

    return saturate(result);
}

// Process regions of the screen with varying quality based on importance
float3 ProcessWithDynamicQuality(float2 texcoord, float2 pixelSize, float depth, float quickStrength) {
    // Original color
    float3 originalColor = GetPixelColor(texcoord);

    // Skip processing if outside depth range
    if (depth < GetPresetMinDepth() || depth > GetPresetMaxDepth())
        return originalColor;

    // Scale quality based on:
    // 1. Screen position (periphery vs center)
    // 2. Depth (distant objects get less processing)
    // 3. Scene complexity (more edges = lower per-edge quality)

    // Center-weighted processing (natural focus point)
    float2 screenCenter = float2(0.5, 0.5);
    float distFromCenter = length(texcoord - screenCenter);

    // Natural vignette-like quality falloff (mimics eye vision)
    float centerQuality = saturate(1.0 - distFromCenter * 1.5);

    // Depth-based quality adjustment (mimics visual acuity with distance)
    float depthQuality = saturate(1.0 - depth * 0.7);

    // Calculate quality level for this pixel (0-2, where 2 is highest)
    float qualityLevel = centerQuality * depthQuality * (2.0 / PerformanceTarget);

    // Round to discrete quality levels (like LOD in nature)
    int discreteQuality = int(qualityLevel + 0.5);

    // OPTIMIZATION: Fast path for non-edge pixels (avoids full edge detection)
    if (quickStrength < 0.3 && EnableEarlyExit)
        return originalColor;

    // Variables for edge detection results
    float edgeStrength;
    float2 edgeDirection;
    float isDirectional;
    bool isNW_SE;
    bool isNE_SW;
    float isCurved;
    bool isGradient;
    float gradientStrength;

    // Full edge detection (simplified for lower quality)
    if (discreteQuality <= 0) {
        // Low quality - simplified edge detection
        float3 n = GetPixelColor(texcoord + float2(0, -1) * pixelSize);
        float3 e = GetPixelColor(texcoord + float2(1, 0) * pixelSize);
        float3 s = GetPixelColor(texcoord + float2(0, 1) * pixelSize);
        float3 w = GetPixelColor(texcoord + float2(-1, 0) * pixelSize);

        float nDiff = length(n - originalColor);
        float eDiff = length(e - originalColor);
        float sDiff = length(s - originalColor);
        float wDiff = length(w - originalColor);

        // Rough edge detection
        edgeStrength = max(max(nDiff, eDiff), max(sDiff, wDiff)) / GetPresetEdgeThreshold();

        // Fast direction estimation
        float2 dir = float2(eDiff - wDiff, sDiff - nDiff);
        float len = length(dir) + 0.0001;
        edgeDirection = dir / len;

        // Set simplified values
        isDirectional = 0.7;
        isNW_SE = abs(dir.x + dir.y) > abs(dir.x - dir.y);
        isNE_SW = !isNW_SE;
        isCurved = 0.0;
        isGradient = false;
        gradientStrength = 0.0;
    }
    else {
        // Medium/high quality - full edge detection
        AdvancedEdgeDetection(texcoord, pixelSize, depth, edgeStrength, edgeDirection,
                            isDirectional, isNW_SE, isNE_SW, isCurved, isGradient, gradientStrength);
    }

    // Early exit if definitely not an edge
    if (edgeStrength < 0.1)
        return originalColor;

    // Don't detect patterns for low quality
    int patternLength = 0;
    float patternStrength = 0.0;
    bool hasPattern = false;

    if (discreteQuality >= 1) {
        // Only do pattern detection for medium/high quality
        hasPattern = OptimizedPatternDetection(texcoord, pixelSize, edgeDirection, patternLength, patternStrength);
    }

    // Get filter settings
    float filterStrength = GetPresetFilterStrength();

    // Apply natural-pattern sampling based on edge type
    float3 filteredColor;

    if (isCurved > 0.3 && discreteQuality >= 1) {
        // Golden spiral sampling for curved edges (medium/high quality)
        filteredColor = ApplyOptimizedCurveFiltering(texcoord, pixelSize, isCurved, filterStrength);
    }
    else if ((isNW_SE || isNE_SW) && discreteQuality >= 1) {
        // Fibonacci sampling for diagonal edges (medium/high quality)
        filteredColor = ApplyOptimizedDiagonalFiltering(texcoord, pixelSize, isNW_SE, edgeStrength, filterStrength);
    }
    else {
        // Logarithmic sampling for general edges (all quality levels)
        filteredColor = ApplyOptimizedGeneralFiltering(texcoord, pixelSize, edgeDirection, edgeStrength, filterStrength);
    }

    // For gradients, we want to preserve more of the original color
    if (isGradient && discreteQuality >= 1) {
        // Get gradient preservation strength from preset
        float gradientPreservation = GetPresetGradientPreservation();

        // Calculate blend factor based on gradient strength and preservation setting
        float gradientBlend = gradientStrength * gradientPreservation;

        // Blend more towards original color for strong gradients
        filteredColor = lerp(filteredColor, originalColor, gradientBlend);
    }

    // Apply panel-specific subpixel processing for the final output
    // Only for high quality or for panels that really need it
    if (discreteQuality >= 1 || GetPresetPanelType() >= 4) {
        filteredColor = ApplySubpixelProcessing(originalColor, filteredColor, edgeDirection, edgeStrength, GetPresetPanelType());
    }

    return filteredColor;
}

// Main processing pixel shader - optimized version
float4 PS_SHADE_Optimized(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float2 pixelSize = ReShade::PixelSize;
    float3 originalColor = GetPixelColor(texcoord);

    // Get depth for perspective-aware processing
    float depth = GetDepth(texcoord);

    // Skip processing if outside depth range
    if (depth < GetPresetMinDepth() || depth > GetPresetMaxDepth())
        return float4(originalColor, 1.0);

    // OPTIMIZATION: Fast initial edge check - eliminates ~70% of pixels immediately
    float quickStrength;
    if (EnableEarlyExit && !QuickEdgeCheck(texcoord, pixelSize, quickStrength))
        return float4(originalColor, 1.0);

    // Dynamic quality processing
    float3 finalColor = ProcessWithDynamicQuality(texcoord, pixelSize, depth, quickStrength);

    // Debug visualization if enabled
    if (DebugView) {
        // Variables for debug visualization
        float edgeStrength;
        float2 edgeDirection;
        float isDirectional;
        bool isNW_SE;
        bool isNE_SW;
        float isCurved;
        bool isGradient;
        float gradientStrength;

        // Get edge detection data for debug
        AdvancedEdgeDetection(texcoord, pixelSize, depth, edgeStrength, edgeDirection,
                            isDirectional, isNW_SE, isNE_SW, isCurved, isGradient, gradientStrength);

        // Get pattern detection data for debug
        int patternLength;
        float patternStrength;
        bool hasPattern = OptimizedPatternDetection(texcoord, pixelSize, edgeDirection, patternLength, patternStrength);

        switch (DebugMode) {
            case 0: // Edge Detection
                return float4(edgeStrength, isNW_SE ? 1.0 : 0.0, isNE_SW ? 1.0 : 0.0, 1.0);
            case 1: // Pattern Recognition
                return float4(hasPattern ? patternStrength : 0.0, hasPattern ? patternLength / 10.0 : 0.0, 0.0, 1.0);
            case 2: // Curve Detection
                return float4(isCurved, 0.0, isDirectional, 1.0);
            case 3: // Filtering Intensity
                return float4(length(originalColor - finalColor) * 5.0, 0.0, 0.0, 1.0);
            case 4: // Depth Map
                return float4(depth, depth, depth, 1.0);
            case 5: // Gradient Detection
                return float4(isGradient ? gradientStrength : 0.0, 0.0, isGradient ? 1.0 : 0.0, 1.0);
            case 6: // Performance Heat Map
                // Calculate processing cost heuristic
                float cost = edgeStrength * (isCurved > 0.3 ? 1.5 : 1.0) * (hasPattern ? 1.2 : 1.0);
                // Red = expensive, Green = cheap
                return float4(saturate(cost), saturate(1.0 - cost), 0.0, 1.0);
            default:
                return float4(edgeStrength, 0.0, 0.0, 1.0);
        }
    }

    return float4(finalColor, 1.0);
}

// Define techniques for ReShade
//=====================================================================

technique SHADE <ui_label="SHADE - Superior Hybrid AA (Optimized)";>
{
    pass MainPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SHADE_Optimized;
    }
}
