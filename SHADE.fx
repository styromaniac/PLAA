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

uniform float DiagonalDetectionBias <
    ui_type = "slider";
    ui_min = 1.0; ui_max = 10.0; ui_step = 0.1;
    ui_label = "Diagonal Detection Bias";
    ui_tooltip = "Higher values enhance detection of diagonal edges.";
    ui_category = "Edge Detection";
> = 8.0;

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
    ui_items = "Edge Detection\0Pattern Recognition\0Curve Detection\0Filtering Intensity\0Depth Map\0Gradient Detection\0";
    ui_label = "Debug Mode";
    ui_tooltip = "What to display when Debug View is enabled.";
    ui_category = "Debug";
> = 0;

// Include core ReShade functionality
#include "ReShade.fxh"

// Preset application functions
//=====================================================================

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
    switch(DevicePreset) {
        case 1: // Steam Deck LCD
        case 2: // Steam Deck OLED (BOE)
        case 3: // Steam Deck OLED LE (Samsung)
            return 8.0;
        default: // Custom
            return DiagonalDetectionBias;
    }
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

// Helper functions
//=====================================================================

// Get luminance from RGB color
float GetLuminance(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}

// Safe texture sampling with bounds checking
float3 GetPixelColor(float2 texcoord) {
    if (texcoord.x < 0.0 || texcoord.x > 1.0 || texcoord.y < 0.0 || texcoord.y > 1.0)
        return tex2D(samplerColor, saturate(texcoord)).rgb;
    return tex2D(samplerColor, texcoord).rgb;
}

// Get linearized depth at specified coordinates
float GetDepth(float2 texcoord) {
    return ReShade::GetLinearizedDepth(texcoord);
}

float4 GetLocalContrast(float2 texcoord, float2 pixelSize) {
    float3 center = GetPixelColor(texcoord);
    float centerLuma = GetLuminance(center);

    float minLuma = centerLuma;
    float maxLuma = centerLuma;
    float avgLuma = centerLuma;
    float totalWeight = 1.0;

    // Sample 8 surrounding pixels
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            if (x == 0 && y == 0) continue; // Skip center

            float3 neighbor = GetPixelColor(texcoord + float2(x, y) * pixelSize);
            float neighborLuma = GetLuminance(neighbor);

            minLuma = min(minLuma, neighborLuma);
            maxLuma = max(maxLuma, neighborLuma);

            // Weight corners less for average
            float weight = (abs(x) + abs(y) == 2) ? 0.5 : 1.0;
            avgLuma += neighborLuma * weight;
            totalWeight += weight;
        }
    }

    avgLuma /= totalWeight;

    // Return contrast metrics as a struct-like float4
    // x = max-min range, y = avg luminance, z = max, w = min
    return float4(maxLuma - minLuma, avgLuma, maxLuma, minLuma);
}

// Function to detect if a pixel is part of a smooth gradient rather than an edge
bool IsGradient(float2 texcoord, float2 pixelSize, out float gradientStrength) {
    // Sample a 5x5 area to analyze gradient patterns
    float luma[25];
    int idx = 0;

    for (int y = -2; y <= 2; y++) {
        for (int x = -2; x <= 2; x++) {
            luma[idx++] = GetLuminance(GetPixelColor(texcoord + float2(x, y) * pixelSize));
        }
    }

    // Center pixel
    float centerLuma = luma[12];

    // Calculate average differences between adjacent pixels
    float horizDiff = 0;
    float vertDiff = 0;
    float diagDiff1 = 0;
    float diagDiff2 = 0;

    // Horizontal gradient check (middle row)
    for (int i = 0; i < 4; i++) {
        horizDiff += abs(luma[10 + i] - luma[10 + i + 1]);
    }
    horizDiff /= 4;

    // Vertical gradient check (middle column)
    for (int i = 0; i < 4; i++) {
        vertDiff += abs(luma[2 + i*5] - luma[2 + (i+1)*5]);
    }
    vertDiff /= 4;

    // Diagonal gradients
    for (int i = 0; i < 4; i++) {
        diagDiff1 += abs(luma[i*6] - luma[(i+1)*6]); // Top-left to bottom-right
        diagDiff2 += abs(luma[4 + i*4] - luma[4 + (i+1)*4]); // Top-right to bottom-left
    }
    diagDiff1 /= 4;
    diagDiff2 /= 4;

    // Calculate variance as a measure of how "noisy" the area is
    float mean = 0;
    for (int i = 0; i < 25; i++) {
        mean += luma[i];
    }
    mean /= 25;

    float variance = 0;
    for (int i = 0; i < 25; i++) {
        variance += pow(luma[i] - mean, 2);
    }
    variance /= 25;

    // Check for consistent gradient characteristics:
    // 1. Low variance overall (smooth transitions)
    // 2. Consistent and small differences between adjacent pixels
    // 3. Lack of sharp changes in any direction

    float maxDiff = max(max(horizDiff, vertDiff), max(diagDiff1, diagDiff2));
    float minDiff = min(min(horizDiff, vertDiff), min(diagDiff1, diagDiff2));

    // Consistent gradient will have similar differences in multiple directions
    float directionalConsistency = (maxDiff > 0.001) ? minDiff / maxDiff : 1.0;

    // Metrics for gradient detection:
    // - Low variance indicates smooth transitions
    // - Consistent small differences between adjacent pixels
    // - Direction consistency indicates uniform gradient rather than an edge

    // For a strong gradient:
    // - Variance should be low (< 0.01 for subtle gradients)
    // - Max difference should be small but non-zero (0.001 - 0.05 for most gradients)
    // - Directional consistency should be high (> 0.5 for uniform gradients)

    bool isSmooth = variance < 0.01;
    bool isConsistent = directionalConsistency > 0.5;
    bool hasGradient = maxDiff > 0.001 && maxDiff < 0.05;

    // Calculate overall gradient strength as a confidence value
    gradientStrength = saturate((1.0 - variance * 50.0) * directionalConsistency * saturate(maxDiff * 50.0));

    return isSmooth && hasGradient && isConsistent;
}

// Function to check if a pixel likely belongs to pixel art
bool IsPixelArt(float2 texcoord, float2 pixelSize) {
    // Check for sharp right-angle corners (characteristic of pixel art)
    float cornerCount = 0;

    // Sample a 3x3 grid
    float luma[9];
    int idx = 0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            luma[idx++] = GetLuminance(GetPixelColor(texcoord + float2(x, y) * pixelSize));
        }
    }

    // Center pixel
    float centerLuma = luma[4];

    // Check for right-angle corners by looking at adjacent pixels
    if (abs(luma[1] - centerLuma) < 0.05 && abs(luma[3] - centerLuma) < 0.05 && abs(luma[0] - centerLuma) > 0.2) cornerCount++;
    if (abs(luma[1] - centerLuma) < 0.05 && abs(luma[5] - centerLuma) < 0.05 && abs(luma[2] - centerLuma) > 0.2) cornerCount++;
    if (abs(luma[3] - centerLuma) < 0.05 && abs(luma[7] - centerLuma) < 0.05 && abs(luma[6] - centerLuma) > 0.2) cornerCount++;
    if (abs(luma[5] - centerLuma) < 0.05 && abs(luma[7] - centerLuma) < 0.05 && abs(luma[8] - centerLuma) > 0.2) cornerCount++;

    // Check for perfect horizontal/vertical lines (characteristic of pixel art)
    bool hasHorizontalLine = abs(luma[3] - luma[4]) < 0.05 && abs(luma[4] - luma[5]) < 0.05;
    bool hasVerticalLine = abs(luma[1] - luma[4]) < 0.05 && abs(luma[4] - luma[7]) < 0.05;

    // Combined criteria for pixel art detection
    return (cornerCount >= 2) || hasHorizontalLine || hasVerticalLine;
}

// Apply perspective compensation to filter parameters based on depth
void ApplyPerspectiveCompensation(inout float edgeThreshold, inout float gapThreshold,
                                 inout float filterStrength, float depth) {
    if (!GetPresetPerspectiveCompensation()) return;

    // Get preset values
    float presetMinDepth = GetPresetMinDepth();
    float presetMaxDepth = GetPresetMaxDepth();
    float presetDepthSensitivity = GetPresetDepthSensitivity();

    // Calculate perspective factor (0 = near, 1 = far)
    float perspectiveFactor = saturate((depth - presetMinDepth) / max(0.001, presetMaxDepth - presetMinDepth));
    perspectiveFactor = smoothstep(0, 1, perspectiveFactor); // Smooth transition

    // Calculate compensation amount
    float compensation = perspectiveFactor * presetDepthSensitivity;

    // Adjust thresholds based on distance - distant objects need more sensitive detection
    edgeThreshold *= max(0.3, 1.0 - compensation * 0.7);
    gapThreshold *= max(0.3, 1.0 - compensation * 0.7);

    // Adjust filter strength - distant objects need stronger filtering
    filterStrength *= (1.0 + compensation);
}

// Advanced edge detection with directional analysis using 24-factor multisampling
void AdvancedEdgeDetection(float2 texcoord, float2 pixelSize, float depth, out float edgeStrength,
                           out float2 edgeDirection, out float isDirectional, out bool isNW_SE, out bool isNE_SW, out float isCurved, out bool isGradient, out float gradientStrength) {
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
    float4 contrastInfo = GetLocalContrast(texcoord, pixelSize);
    float localContrast = contrastInfo.x; // max-min range

    // More aggressive threshold adjustment in high-contrast areas
    adjustedEdgeThreshold *= 1.0 - (GetPresetAdaptiveThreshold() * min(1.0, localContrast * 2.0));

    // Sample a 5x5 area for accurate gradient estimation (from REALISTIC.fx)
    float luma[25];
    float3 color[25];

    // Load the 5x5 neighborhood
    [unroll]
    for (int y = -2; y <= 2; y++) {
        [unroll]
        for (int x = -2; x <= 2; x++) {
            int idx = (y + 2) * 5 + (x + 2);
            color[idx] = GetPixelColor(texcoord + float2(x, y) * pixelSize);
            luma[idx] = GetLuminance(color[idx]);
        }
    }

    // Calculate gradients in eight directions using enhanced Sobel-like operators

    // Horizontal gradient (East-West)
    float gx = 0;
    gx += luma[10] * -1.0 + luma[11] * -3.0 + luma[13] * 3.0 + luma[14] * 1.0;
    gx += luma[5] * -1.0 + luma[6] * -3.0 + luma[8] * 3.0 + luma[9] * 1.0;
    gx += luma[15] * -1.0 + luma[16] * -3.0 + luma[18] * 3.0 + luma[19] * 1.0;

    // Vertical gradient (North-South)
    float gy = 0;
    gy += luma[2] * -1.0 + luma[7] * -3.0 + luma[17] * 3.0 + luma[22] * 1.0;
    gy += luma[1] * -1.0 + luma[6] * -3.0 + luma[16] * 3.0 + luma[21] * 1.0;
    gy += luma[3] * -1.0 + luma[8] * -3.0 + luma[18] * 3.0 + luma[23] * 1.0;

    // Diagonal gradients (Northeast-Southwest and Northwest-Southeast)
    float gNE_SW = 0;
    gNE_SW += luma[4] * 1.0 + luma[9] * 3.0 + luma[15] * -3.0 + luma[20] * -1.0;
    gNE_SW += luma[3] * 3.0 + luma[8] * 5.0 + luma[16] * -5.0 + luma[21] * -3.0;

    float gNW_SE = 0;
    gNW_SE += luma[0] * -1.0 + luma[5] * -3.0 + luma[19] * 3.0 + luma[24] * 1.0;
    gNW_SE += luma[1] * -3.0 + luma[6] * -5.0 + luma[18] * 5.0 + luma[23] * 3.0;

    // Secondary diagonal gradients (for better direction detection)
    float gNESW_alt = abs(luma[1] - luma[23]) + abs(luma[3] - luma[21]);
    float gNWSE_alt = abs(luma[3] - luma[23]) + abs(luma[1] - luma[21]);

    // Add additional gradient information
    gNE_SW += gNESW_alt * 0.5;
    gNW_SE += gNWSE_alt * 0.5;

    // Apply diagonal bias to enhance diagonal detection
    gNE_SW *= GetPresetDiagonalBias();
    gNW_SE *= GetPresetDiagonalBias();

    // Calculate overall gradient magnitude
    float gHV = sqrt(gx*gx + gy*gy);  // Horizontal/vertical magnitude
    float gDiag = sqrt(gNE_SW*gNE_SW + gNW_SE*gNW_SE); // Diagonal magnitude

    // Calculate edge strength and direction
    float maxGradient = max(gHV, gDiag);
    edgeStrength = maxGradient / (20.0 * adjustedEdgeThreshold); // Normalize with adjusted threshold - lower divisor for stronger effect

    // Set the diagonal direction flags directly
    isNW_SE = abs(gNW_SE) > abs(gNE_SW);
    isNE_SW = !isNW_SE;

    // Calculate edge direction (normalized)
    float2 direction;
    if (gHV >= gDiag) {
        // Horizontal or vertical edge
        direction = float2(gx, gy);
    } else {
        // Diagonal edge
        // Map NE-SW and NW-SE gradients to a 2D direction vector
        direction = float2(gNE_SW - gNW_SE, gNE_SW + gNW_SE);
    }

    // Normalize the direction vector
    float dirLength = length(direction);
    if (dirLength > 0.0) {
        edgeDirection = direction / dirLength;
    } else {
        edgeDirection = float2(0, 0);
    }

    // Determine if edge is strongly directional or curved
    float directionalStrength = 0.0;
    float curveStrength = 0.0;

    // Check for directional consistency
    if (gHV >= gDiag) {
        // Check horizontal/vertical direction consistency
        float hConsistency = abs(gx) / (abs(gx) + abs(gy) + 0.0001);
        float vConsistency = abs(gy) / (abs(gx) + abs(gy) + 0.0001);
        directionalStrength = max(hConsistency, vConsistency);
    } else {
        // Check diagonal direction consistency
        float neswConsistency = abs(gNE_SW) / (abs(gNE_SW) + abs(gNW_SE) + 0.0001);
        float nwseConsistency = abs(gNW_SE) / (abs(gNE_SW) + abs(gNW_SE) + 0.0001);
        directionalStrength = max(neswConsistency, nwseConsistency);
    }

    // Curve detection - inspired by REALISTIC.fx's approach
    // Check for pattern changes that indicate curves
    float xCurve = abs(sign(luma[6] - luma[7]) - sign(luma[7] - luma[8])) +
                  abs(sign(luma[11] - luma[12]) - sign(luma[12] - luma[13])) +
                  abs(sign(luma[16] - luma[17]) - sign(luma[17] - luma[18]));

    float yCurve = abs(sign(luma[6] - luma[11]) - sign(luma[11] - luma[16])) +
                  abs(sign(luma[7] - luma[12]) - sign(luma[12] - luma[17])) +
                  abs(sign(luma[8] - luma[13]) - sign(luma[13] - luma[18]));

    float diagCurve = abs(sign(luma[0] - luma[6]) - sign(luma[6] - luma[12])) +
                     abs(sign(luma[6] - luma[12]) - sign(luma[12] - luma[18])) +
                     abs(sign(luma[18] - luma[24]) - sign(luma[12] - luma[18]));

    // Detect isolated pixel anomalies (common in curves)
    float pixelContrast = abs(luma[12] - (luma[6] + luma[7] + luma[8] + luma[11] + luma[13] + luma[16] + luma[17] + luma[18]) / 8.0);

    // Calculate corner strength (from REALISTIC.fx)
    float cornerNW = abs(gx * gy) * ((luma[0] - luma[12]) > 0 ? 1.0 : -1.0);
    float cornerNE = abs(gx * gy) * ((luma[4] - luma[12]) > 0 ? 1.0 : -1.0);
    float cornerSW = abs(gx * gy) * ((luma[20] - luma[12]) > 0 ? 1.0 : -1.0);
    float cornerSE = abs(gx * gy) * ((luma[24] - luma[12]) > 0 ? 1.0 : -1.0);

    // Find which corner is strongest
    float maxCorner = max(max(abs(cornerNW), abs(cornerNE)), max(abs(cornerSW), abs(cornerSE)));

    // Calculate final curve strength
    curveStrength = (xCurve + yCurve + diagCurve) * 0.1 + pixelContrast * 2.0 + maxCorner * 0.5;
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

// Detect repeating patterns and gaps for better aliasing detection
bool DetectRepeatingPattern(float2 texcoord, float2 pixelSize, float2 direction, out int patternLength, out float patternStrength) {
    // Center pixel luminance
    float3 centerColor = GetPixelColor(texcoord);
    float centerLuma = GetLuminance(centerColor);

    // Calculate perpendicular direction for sampling
    float2 perpDirection = float2(-direction.y, direction.x); // Rotate 90 degrees

    // Normalize perpendicular direction
    float perpLength = length(perpDirection);
    if (perpLength > 0.0) {
        perpDirection /= perpLength;
    } else {
        perpDirection = float2(1.0, 0.0);
    }

    // Determine max search steps based on quality setting
    int presetSamplingQuality = GetPresetSamplingQuality();
    int maxSteps = presetSamplingQuality == 0 ? 16 : presetSamplingQuality == 1 ? 24 : 32;

    // Store luminance values along the search path
    float searchLuma[32]; // Supports up to 32 steps (Ultra quality)
    searchLuma[0] = centerLuma;

    // Search in positive direction
    [unroll]
    for (int i = 1; i < maxSteps / 2; i++) {
        float2 samplePos = texcoord + perpDirection * i * pixelSize;
        searchLuma[i] = GetLuminance(GetPixelColor(samplePos));
    }

    // Search in negative direction
    [unroll]
    for (int i = 1; i < maxSteps / 2; i++) {
        float2 samplePos = texcoord - perpDirection * i * pixelSize;
        searchLuma[i + maxSteps / 2] = GetLuminance(GetPixelColor(samplePos));
    }

    // Setup for detecting gaps (segments separated by color/luminance discontinuities)
    bool lastSimilar = true;
    int gapCount = 0;
    int segmentCount = 1; // Start with center pixel as a segment
    float totalSegmentStrength = 0.0;

    // Configure gap threshold with adaptive adjustment
    float adjustedGapThreshold = GetPresetGapThreshold();
    float4 contrastInfo = GetLocalContrast(texcoord, pixelSize);
    float localContrast = contrastInfo.x;
    adjustedGapThreshold *= 1.0 - (GetPresetAdaptiveThreshold() * min(1.0, localContrast * 2.0));

    // Analyze the pattern - look for gaps and segments
    [unroll]
    for (int i = 1; i < maxSteps; i++) {
        bool isSimilar = abs(searchLuma[i] - centerLuma) < adjustedGapThreshold;

        // Detect segment transitions (gap to segment or segment to gap)
        if (isSimilar && !lastSimilar) {
            // Found a new segment after a gap
            segmentCount++;
            totalSegmentStrength += abs(searchLuma[i] - searchLuma[i-1]);
        }
        else if (!isSimilar && lastSimilar) {
            // Found a gap after a segment
            gapCount++;
        }

        lastSimilar = isSimilar;
    }

    // Check for equidistant transitions (characteristic of aliasing)
    bool hasEquidistantPattern = false;
    int equidistantLength = 0;

    // Try different pattern lengths
    for (int testLength = 2; testLength <= 6; testLength++) {
        int matches = 0;
        float matchStrength = 0.0;

        // Check if luminance values repeat at this interval
        for (int i = 0; i < maxSteps - testLength; i++) {
            if (abs(searchLuma[i] - searchLuma[i + testLength]) < adjustedGapThreshold * 2.0) {
                matches++;
                matchStrength += 1.0 - abs(searchLuma[i] - searchLuma[i + testLength]);
            }
        }

        // If we have enough matches, consider it a pattern
        if (matches >= (maxSteps - testLength) / 3) {
            hasEquidistantPattern = true;
            equidistantLength = testLength;
            break;
        }
    }

    // Return results
    patternLength = hasEquidistantPattern ? equidistantLength : 0;
    patternStrength = (segmentCount > 1) ? totalSegmentStrength / segmentCount : 0;

    // Pattern is valid if we have multiple segments or an equidistant pattern
    return (segmentCount >= 2 && gapCount >= 1) || hasEquidistantPattern;
}

// Apply panel-specific subpixel processing
float3 ApplySubpixelProcessing(float3 originalColor, float3 processedColor, float2 edgeDirection, float edgeStrength, int panelType) {
    // Use preset values for subpixel strength and panel type
    float strength = GetPresetSubpixelStrength() * min(1.0, edgeStrength * 2.0);
    int presetPanelType = GetPresetPanelType();

    if (strength <= 0.0)
        return processedColor;

    float3 result = processedColor;

    // Calculate the angle of edge direction (0-180 degrees from horizontal)
    float angle = degrees(atan2(abs(edgeDirection.y), abs(edgeDirection.x)));

    // Scale effect based on edge angle (maximum at 45 degrees)
    float angleEffect = sin(radians(2.0 * angle));
    strength *= angleEffect;

    switch (presetPanelType) {
        case 0: // RGB panel
            // For vertical-ish edges, reduce color fringing
            if (angle > 45.0) {
                result.r = lerp(result.r, originalColor.r, strength * 0.5);
                result.g = lerp(result.g, originalColor.g, strength * 0.2); // Less adjustment for green
                result.b = lerp(result.b, originalColor.b, strength * 0.5);
            }
            // For horizontal-ish edges
            else {
                result.r = lerp(result.r, max(result.r, originalColor.r * 0.9), strength * 0.3);
                result.b = lerp(result.b, max(result.b, originalColor.b * 0.9), strength * 0.3);
            }
            break;

        case 1: // BGR panel
            // Reverse of RGB panel approach
            if (angle > 45.0) {
                result.b = lerp(result.b, originalColor.b, strength * 0.5);
                result.g = lerp(result.g, originalColor.g, strength * 0.2);
                result.r = lerp(result.r, originalColor.r, strength * 0.5);
            }
            else {
                result.b = lerp(result.b, max(result.b, originalColor.b * 0.9), strength * 0.3);
                result.r = lerp(result.r, max(result.r, originalColor.r * 0.9), strength * 0.3);
            }
            break;

        case 2: // RGBW panel
            // Reduce color fringing by preserving average and limiting differences
            float avgOriginal = (originalColor.r + originalColor.g + originalColor.b) / 3.0;
            float avgResult = (result.r + result.g + result.b) / 3.0;

            // Limit deviation from original colors
            result.r = lerp(result.r, avgResult + (originalColor.r - avgOriginal) * 0.7, strength * 0.4);
            result.g = lerp(result.g, avgResult + (originalColor.g - avgOriginal) * 0.7, strength * 0.4);
            result.b = lerp(result.b, avgResult + (originalColor.b - avgOriginal) * 0.7, strength * 0.4);
            break;

        case 3: // WRGB panel
            // Similar to RGBW but with slightly different treatment
            float avgOriginal2 = (originalColor.r + originalColor.g + originalColor.b) / 3.0;
            float avgResult2 = (result.r + result.g + result.b) / 3.0;

            // Keep color ratios more similar to original
            float maxChannel = max(max(originalColor.r, originalColor.g), originalColor.b);

            if (maxChannel > 0.0001) {
                result.r = lerp(result.r, (avgResult2 * 0.7 + result.r * 0.3) * (originalColor.r / maxChannel), strength * 0.5);
                result.g = lerp(result.g, (avgResult2 * 0.7 + result.g * 0.3) * (originalColor.g / maxChannel), strength * 0.5);
                result.b = lerp(result.b, (avgResult2 * 0.7 + result.b * 0.3) * (originalColor.b / maxChannel), strength * 0.5);
            }
            break;

        case 4: // Samsung OLED (Steam Deck)
            // Samsung panel has alternating blue pixels and a blue bias

            // Apply horizontal blue pixel shift (alternating blue pixels)
            float blueShiftStrength = strength * 0.4;

            // Sample in adjacent positions for blue channel adjustment
            float2 pixelSize = float2(1.0/BUFFER_WIDTH, 1.0/BUFFER_HEIGHT);
            float3 adjacentBlue1 = result * float3(0.98, 0.99, 1.02);
            float3 adjacentBlue2 = result * float3(0.99, 0.98, 1.01);

            // Blend blue channel to reduce alternating pattern
            result.b = lerp(result.b,
                         (result.b * 0.7) + (adjacentBlue1.b * 0.15) + (adjacentBlue2.b * 0.15),
                         blueShiftStrength);

            // Reduce blue bias that's common in Samsung OLED
            float blueBias = max(0.0, result.b - ((result.r + result.g) / 2.0)) * 0.3;
            result.b = max(0.0, result.b - blueBias * strength);

            // Add back some contrast if too flat
            float contrastBoost = lerp(1.0, 1.2, min(0.5, strength));
            result = (result - 0.5) * contrastBoost + 0.5;
            break;

        case 5: // BOE OLED (Steam Deck)
            // BOE panel has red-green fringing due to subpixel arrangement

            // For vertical edges, reduce green bias
            if (angle > 40.0) {
                // Sample in adjacent positions for horizontal blending
                float2 pixelSize = float2(1.0/BUFFER_WIDTH, 1.0/BUFFER_HEIGHT);
                float3 leftPixel = result * float3(1.02, 0.99, 0.98);
                float3 rightPixel = result * float3(0.98, 1.01, 0.99);

                // Average left and right pixels
                float3 horizAvg = (leftPixel + rightPixel) * 0.5;

                // Reduce red-green fringing at edges
                float redShift = 0.4 * strength;
                float greenShift = 0.2 * strength;

                result.r = lerp(result.r,
                             lerp(result.r, horizAvg.r, redShift),
                             min(1.0, angleEffect * 2.0));

                result.g = lerp(result.g,
                             lerp(result.g, horizAvg.g, greenShift),
                             min(1.0, angleEffect * 2.0));
            }

            // Compensate for red and green bias
            float rgBias = max(0.0, (result.r + result.g) / 2.0 - result.b) * 0.25;
            result.r = max(0.0, result.r - rgBias * strength);
            result.g = max(0.0, result.g - rgBias * strength);
            result.b = result.b + rgBias * strength * 0.5;
            break;
    }

    return saturate(result);
}

// Apply adaptive filtering based on edge type and pattern - using 24-factor multisampling
float3 ApplyAdaptiveFiltering(float2 texcoord, float2 pixelSize, float edgeStrength, float2 edgeDirection,
                              float isDirectional, float isCurved, bool hasPattern, int patternLength, bool isGradient, float gradientStrength) {
    float3 center = GetPixelColor(texcoord);

    // Early exit for non-edge pixels
    if (edgeStrength < 0.1) return center;

    // Calculate filter strength based on edge characteristics
    float filterMult = GetPresetFilterStrength();

    // Directional edges get stronger filtering
    if (isDirectional > 0.7) filterMult *= 1.2;

    // Curved edges get special treatment
    float curveFilterMult = 1.0;
    if (isCurved > 0.5) curveFilterMult = 1.5;

    // Pattern-based adjustment
    if (hasPattern) filterMult *= 1.3;

    // Calculate perpendicular direction for sampling
    float2 perpDirection = float2(-edgeDirection.y, edgeDirection.x);

    // Determine number of samples based on quality setting
    int presetSamplingQuality = GetPresetSamplingQuality();
    int sampleCount = presetSamplingQuality == 0 ? 6 : presetSamplingQuality == 1 ? 8 : 12;

    // If it's a curved edge, use circular sampling pattern with 24-factor optimization
    if (isCurved > 0.3) {
        float3 circularResult = float3(0, 0, 0);
        float circularWeight = 0;

        // Define circular sampling using 12 points (factor of 24)
        float3 circularSamples[12];
        float circularWeights[12];

        // Sample in a circle around the pixel at 30-degree intervals
        [unroll]
        for (int i = 0; i < 12; i++) {
            float angle = radians(i * 30.0);
            float2 dir = float2(cos(angle), sin(angle));

            // Adaptive sampling distance based on curve strength
            float sampleDist = 1.0 + isCurved * 0.5;

            // Take sample
            circularSamples[i] = GetPixelColor(texcoord + dir * pixelSize * sampleDist);

            // Calculate weight based on similarity to center
            float similarity = 1.0 - saturate(length(circularSamples[i] - center) * 2.0);
            circularWeights[i] = similarity * similarity; // Square for stronger effect on similar pixels

            // Add to weighted sum
            circularResult += circularSamples[i] * circularWeights[i];
            circularWeight += circularWeights[i];
        }

        // Add center pixel to circular result
        circularResult += center * 1.0;
        circularWeight += 1.0;

        // Normalize
        circularResult /= max(0.001, circularWeight);

        // Blend with original based on curve strength
        float blendFactor = saturate(edgeStrength * filterMult * curveFilterMult);
        return lerp(center, circularResult, blendFactor);
    }

    // For regular edges, use directional sampling perpendicular to edge
    // Using 24-factor optimization: 12 samples (6 pairs) gives excellent quality

    // Store samples and weights
    float3 samples[12];
    float weights[12];
    float totalWeight = 1.0; // Center weight

    // Center sample with highest weight
    float3 result = center * 1.0;

    // Use adaptive spacing based on detected pattern
    float spacing = (patternLength > 0) ? patternLength * 0.25 : 1.0;

    // Take samples along perpendicular direction
    [unroll]
    for (int i = 0; i < sampleCount; i++) {
        // Calculate sample position with progressive spacing
        float dist = spacing * (i + 1) / sampleCount;

        // Positive and negative direction samples
        samples[i] = GetPixelColor(texcoord + perpDirection * dist * pixelSize);
        samples[i + sampleCount] = GetPixelColor(texcoord - perpDirection * dist * pixelSize);

        // Calculate weights based on distance and similarity
        float distanceFactor = 1.0 - saturate(dist / 4.0);

        // Similarity weight calculation
        float similarity1 = 1.0 - saturate(length(samples[i] - center) * 2.0);
        float similarity2 = 1.0 - saturate(length(samples[i + sampleCount] - center) * 2.0);

        // Final weights combining distance and similarity
        weights[i] = distanceFactor * distanceFactor * similarity1 * similarity1;
        weights[i + sampleCount] = distanceFactor * distanceFactor * similarity2 * similarity2;

        // Add to weighted sum
        result += samples[i] * weights[i];
        result += samples[i + sampleCount] * weights[i + sampleCount];
        totalWeight += weights[i] + weights[i + sampleCount];
    }

    // Normalize result
    result /= totalWeight;

    // Calculate blend factor based on edge strength and filter multiplier
    float blendFactor = saturate(edgeStrength * filterMult / 5.0); // Reduced divisor for stronger blending effect

    // Return filtered result
    return lerp(center, result, blendFactor);
}

// Main processing pixel shader
float4 PS_SHADE(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float2 pixelSize = ReShade::PixelSize;
    float3 originalColor = GetPixelColor(texcoord);

    // Get depth for perspective-aware processing
    float depth = GetDepth(texcoord);

    // Skip processing if outside depth range
    if (depth < GetPresetMinDepth() || depth > GetPresetMaxDepth())
        return float4(originalColor, 1.0);

    // Variables for edge detection results
    float edgeStrength;
    float2 edgeDirection;
    float isDirectional;
    bool isNW_SE;
    bool isNE_SW;
    float isCurved;
    bool isGradient;
    float gradientStrength;

    // Perform advanced edge detection with depth compensation
    AdvancedEdgeDetection(texcoord, pixelSize, depth, edgeStrength, edgeDirection, isDirectional, isNW_SE, isNE_SW, isCurved, isGradient, gradientStrength);

    // Directly use REALISTIC.fx's approach - check if this is an edge at all
    if (edgeStrength < 0.05)
        return float4(originalColor, 1.0);

    // Pattern recognition
    int patternLength;
    float patternStrength;
    bool hasPattern = DetectRepeatingPattern(texcoord, pixelSize, edgeDirection, patternLength, patternStrength);

    // Using an approach similar to REALISTIC.fx's direct diagonal detection and smoothing
    float3 result = originalColor;

    // Calculate filter strength based on edge characteristics
    float filterMult = GetPresetFilterStrength();

    // Directional edges get stronger filtering
    if (isDirectional > 0.7) filterMult *= 1.5;

    // Curved edges get special treatment
    float curveFilterMult = 1.0;
    if (isCurved > 0.5) curveFilterMult = 1.5;

    // Pattern-based adjustment
    if (hasPattern) filterMult *= 1.5;

    // If it's a curved edge, use circular sampling
    if (isCurved > 0.3) {
        // For curves, use circular sampling with 12 directions (30 degree intervals)
        float3 circularSamples[12];

        circularSamples[0] = GetPixelColor(texcoord + float2(0, -1) * pixelSize);                    // N
        circularSamples[1] = GetPixelColor(texcoord + float2(0.5, -0.866) * pixelSize);              // NNE
        circularSamples[2] = GetPixelColor(texcoord + float2(0.866, -0.5) * pixelSize);              // ENE
        circularSamples[3] = GetPixelColor(texcoord + float2(1, 0) * pixelSize);                     // E
        circularSamples[4] = GetPixelColor(texcoord + float2(0.866, 0.5) * pixelSize);               // ESE
        circularSamples[5] = GetPixelColor(texcoord + float2(0.5, 0.866) * pixelSize);               // SSE
        circularSamples[6] = GetPixelColor(texcoord + float2(0, 1) * pixelSize);                     // S
        circularSamples[7] = GetPixelColor(texcoord + float2(-0.5, 0.866) * pixelSize);              // SSW
        circularSamples[8] = GetPixelColor(texcoord + float2(-0.866, 0.5) * pixelSize);              // WSW
        circularSamples[9] = GetPixelColor(texcoord + float2(-1, 0) * pixelSize);                    // W
        circularSamples[10] = GetPixelColor(texcoord + float2(-0.866, -0.5) * pixelSize);            // WNW
        circularSamples[11] = GetPixelColor(texcoord + float2(-0.5, -0.866) * pixelSize);            // NNW

        // Create a weighted blend that favors smooth curves
        float3 curveBlend = originalColor * 0.4;

        // Add circular samples with equal weights
        for (int i = 0; i < 12; i++) {
            curveBlend += circularSamples[i] * 0.05; // 12 samples * 0.05 = 0.6 total weight
        }

        // Apply curve rounding based on curve strength
        float blendFactor = saturate(edgeStrength * filterMult * curveFilterMult / 4.0);

        // Apply the curve rounding
        result = lerp(originalColor, curveBlend, blendFactor);
    }
    // Handle diagonal edges - this is where REALISTIC.fx's visible effect comes from
    else if (isNW_SE || isNE_SW) {
        // Direction perpendicular to the edge for sampling
        float2 blendDir;

        if (isNW_SE) {
            // Direction perpendicular to NW-SE is NE-SW
            blendDir = float2(-0.7071, 0.7071);
        }
        else { // isNE_SW
            // Direction perpendicular to NE-SW is NW-SE
            blendDir = float2(0.7071, 0.7071);
        }

        // Using REALISTIC.fx's sampling approach with 8 samples (4 on each side)
        float3 samples[8];

        // Sample at fixed positions for consistent results
        // Distance 0.5, 1.0, 2.0, 3.0 in each direction from center
        samples[0] = GetPixelColor(texcoord + blendDir * pixelSize * 0.5);
        samples[1] = GetPixelColor(texcoord - blendDir * pixelSize * 0.5);
        samples[2] = GetPixelColor(texcoord + blendDir * pixelSize * 1.0);
        samples[3] = GetPixelColor(texcoord - blendDir * pixelSize * 1.0);
        samples[4] = GetPixelColor(texcoord + blendDir * pixelSize * 2.0);
        samples[5] = GetPixelColor(texcoord - blendDir * pixelSize * 2.0);
        samples[6] = GetPixelColor(texcoord + blendDir * pixelSize * 3.0);
        samples[7] = GetPixelColor(texcoord - blendDir * pixelSize * 3.0);

        // Calculate weights for samples
        float lumaCenter = GetLuminance(originalColor);

        // Use more aggressive weighting to make the effect more visible
        float3 blendedColor = originalColor * 0.30; // Less weight on center pixel
        float totalWeight = 0.30;

        // Higher weights for close samples, but ensure total weights are higher
        // for a more visible effect
        float weight1 = 0.15 * saturate(1.0 - abs(GetLuminance(samples[0]) - lumaCenter) * 1.5);
        float weight2 = 0.15 * saturate(1.0 - abs(GetLuminance(samples[1]) - lumaCenter) * 1.5);
        float weight3 = 0.10 * saturate(1.0 - abs(GetLuminance(samples[2]) - lumaCenter) * 1.5);
        float weight4 = 0.10 * saturate(1.0 - abs(GetLuminance(samples[3]) - lumaCenter) * 1.5);
        float weight5 = 0.10 * saturate(1.0 - abs(GetLuminance(samples[4]) - lumaCenter) * 2.0);
        float weight6 = 0.10 * saturate(1.0 - abs(GetLuminance(samples[5]) - lumaCenter) * 2.0);
        float weight7 = 0.05 * saturate(1.0 - abs(GetLuminance(samples[6]) - lumaCenter) * 3.0);
        float weight8 = 0.05 * saturate(1.0 - abs(GetLuminance(samples[7]) - lumaCenter) * 3.0);

        // Add weighted samples to blended color
        blendedColor += samples[0] * weight1;
        blendedColor += samples[1] * weight2;
        blendedColor += samples[2] * weight3;
        blendedColor += samples[3] * weight4;
        blendedColor += samples[4] * weight5;
        blendedColor += samples[5] * weight6;
        blendedColor += samples[6] * weight7;
        blendedColor += samples[7] * weight8;

        totalWeight += weight1 + weight2 + weight3 + weight4 + weight5 + weight6 + weight7 + weight8;

        // Normalize
        blendedColor /= max(0.3, totalWeight);

        // Calculate blend factor - more aggressive for visible effect
        float blendFactor = saturate(edgeStrength * filterMult / 3.0);

        // Apply smoothing with higher intensity
        result = lerp(originalColor, blendedColor, blendFactor * 1.5);
    }
    // Fallback for other edge types
    else if (edgeStrength > 0.1) {
        // Calculate perpendicular direction for sampling
        float2 perpDir = float2(-edgeDirection.y, edgeDirection.x);

        // Ensure this is a unit vector
        float perpLength = length(perpDir);
        if (perpLength > 0.0) {
            perpDir /= perpLength;
        } else {
            perpDir = float2(1.0, 0.0);
        }

        // Use a similar approach to diagonal edges but with calculated perpendicular direction
        float3 samples[8];

        samples[0] = GetPixelColor(texcoord + perpDir * pixelSize * 0.5);
        samples[1] = GetPixelColor(texcoord - perpDir * pixelSize * 0.5);
        samples[2] = GetPixelColor(texcoord + perpDir * pixelSize * 1.0);
        samples[3] = GetPixelColor(texcoord - perpDir * pixelSize * 1.0);
        samples[4] = GetPixelColor(texcoord + perpDir * pixelSize * 2.0);
        samples[5] = GetPixelColor(texcoord - perpDir * pixelSize * 2.0);
        samples[6] = GetPixelColor(texcoord + perpDir * pixelSize * 3.0);
        samples[7] = GetPixelColor(texcoord - perpDir * pixelSize * 3.0);

        // Calculate weights
        float lumaCenter = GetLuminance(originalColor);

        float3 blendedColor = originalColor * 0.30; // Less weight on center pixel
        float totalWeight = 0.30;

        float weight1 = 0.15 * saturate(1.0 - abs(GetLuminance(samples[0]) - lumaCenter) * 1.5);
        float weight2 = 0.15 * saturate(1.0 - abs(GetLuminance(samples[1]) - lumaCenter) * 1.5);
        float weight3 = 0.10 * saturate(1.0 - abs(GetLuminance(samples[2]) - lumaCenter) * 1.5);
        float weight4 = 0.10 * saturate(1.0 - abs(GetLuminance(samples[3]) - lumaCenter) * 1.5);
        float weight5 = 0.10 * saturate(1.0 - abs(GetLuminance(samples[4]) - lumaCenter) * 2.0);
        float weight6 = 0.10 * saturate(1.0 - abs(GetLuminance(samples[5]) - lumaCenter) * 2.0);
        float weight7 = 0.05 * saturate(1.0 - abs(GetLuminance(samples[6]) - lumaCenter) * 3.0);
        float weight8 = 0.05 * saturate(1.0 - abs(GetLuminance(samples[7]) - lumaCenter) * 3.0);

        // Add weighted samples to blended color
        blendedColor += samples[0] * weight1;
        blendedColor += samples[1] * weight2;
        blendedColor += samples[2] * weight3;
        blendedColor += samples[3] * weight4;
        blendedColor += samples[4] * weight5;
        blendedColor += samples[5] * weight6;
        blendedColor += samples[6] * weight7;
        blendedColor += samples[7] * weight8;

        totalWeight += weight1 + weight2 + weight3 + weight4 + weight5 + weight6 + weight7 + weight8;

        // Normalize
        blendedColor /= max(0.3, totalWeight);

        // Less aggressive blending for non-diagonal edges
        float blendFactor = saturate(edgeStrength * filterMult / 4.0);

        result = lerp(originalColor, blendedColor, blendFactor);
    }

    // For gradients, we want to preserve more of the original color
    if (isGradient) {
        // Get gradient preservation strength from preset
        float gradientPreservation = GetPresetGradientPreservation();

        // Calculate blend factor based on gradient strength and preservation setting
        float gradientBlend = gradientStrength * gradientPreservation;

        // Blend more towards original color for strong gradients
        result = lerp(result, originalColor, gradientBlend);
    }

    // Apply panel-specific subpixel processing for the final output
    float3 finalColor = ApplySubpixelProcessing(originalColor, result, edgeDirection, edgeStrength, GetPresetPanelType());

    // Debug visualization if enabled
    if (DebugView) {
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
            default:
                return float4(edgeStrength, 0.0, 0.0, 1.0);
        }
    }

    return float4(finalColor, 1.0);
}

// Define techniques for ReShade
//=====================================================================

technique SHADE <ui_label="SHADE - Superior Hybrid AA";>
{
    pass MainPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SHADE;
    }
}
