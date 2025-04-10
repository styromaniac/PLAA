//=====================================================================
// PLAA Optimized - Low Latency Anti-Aliasing with Simplified Reconstruction
//=====================================================================

//-----------------------------
// Uniforms & UI Controls
//-----------------------------
uniform int SamplingMode <
    ui_type = "combo";
    ui_items = "Standard (5 samples)\0High Quality (7 samples)\0Ultra Quality (9 samples)\0";
    ui_label = "Sampling Mode";
    ui_tooltip = "Lower sample counts for performance at high resolutions.";
> = 0;

uniform float EdgeDetectionThreshold <
    ui_type = "slider";
    ui_min = 0.05; ui_max = 0.30; ui_step = 0.01;
    ui_label = "Edge Detection Threshold";
    ui_tooltip = "Higher values focus only on the strongest edges.";
    ui_category = "Edge Detection";
> = 0.15; // Lowered default for better edge detection

uniform float FilterStrength <
    ui_type = "slider";
    ui_min = 0.5; ui_max = 15.0; ui_step = 0.1;
    ui_label = "Filter Strength";
    ui_tooltip = "Overall strength of the anti-aliasing effect.";
    ui_category = "Effect Strength";
> = 8.0; // Increased default for more visible effect

uniform float GapDetectionThreshold <
    ui_type = "slider";
    ui_min = 0.05; ui_max = 0.50; ui_step = 0.01;
    ui_label = "Gap Detection Threshold";
    ui_tooltip = "Lower values detect smaller gaps.";
    ui_category = "Pattern Recognition";
> = 0.05;

uniform float CurveDetectionStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Curve Detection Strength";
    ui_tooltip = "Controls processing of curved edges (kept minimal here).";
    ui_category = "Pattern Recognition";
> = 0.50;

// Advanced Options (minimal)
uniform float AdaptiveThresholdStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Adaptive Threshold Strength";
    ui_tooltip = "Scales edge thresholds based on local contrast.";
    ui_category = "Advanced";
> = 0.50;

// 3D Scene Optimization
uniform bool EnablePerspectiveCompensation <
    ui_type = "bool";
    ui_label = "Enable Perspective Compensation";
    ui_tooltip = "Adjusts processing based on scene depth.";
    ui_category = "3D Scene Optimization";
> = true;

uniform bool FlipDepthDirection <
    ui_type = "bool";
    ui_label = "Flip Depth Direction";
    ui_tooltip = "Enable if closer objects have higher depth values.";
    ui_category = "3D Scene Optimization";
> = false;

uniform float DepthSensitivity <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.05;
    ui_label = "Depth Sensitivity";
    ui_tooltip = "Strength of depth-based adjustments.";
    ui_category = "3D Scene Optimization";
> = 1.0;

uniform float MinDepthRange <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Near Plane";
    ui_tooltip = "Objects closer than this distance get no anti-aliasing.";
    ui_category = "3D Scene Optimization";
> = 0.0;

uniform float MaxDepthRange <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Far Plane";
    ui_tooltip = "Objects farther than this distance get no anti-aliasing.";
    ui_category = "3D Scene Optimization";
> = 1.0;

// Special Cases
uniform bool PreservePixelArt <
    ui_type = "bool";
    ui_label = "Preserve Pixel Art";
    ui_tooltip = "Keep intentional pixel art intact.";
    ui_category = "Special Cases";
> = true;

uniform bool PreserveStars <
    ui_type = "bool";
    ui_label = "Preserve Stars";
    ui_tooltip = "Keep single-pixel stars unchanged.";
    ui_category = "Special Cases";
> = true;

// Temporal & Motion Controls
uniform float TemporalReinforcementStrength <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Temporal Reinforcement Strength";
    ui_tooltip = "Blend factor for history reinforcement.";
    ui_category = "Temporal";
> = 0.5;

uniform float MotionSensitivity <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 1.0; ui_step = 0.01;
    ui_label = "Motion Sensitivity";
    ui_tooltip = "Adjust processing based on motion speed.";
    ui_category = "Motion";
> = 0.5;

//-----------------------------
// Include Core ReShade Functionality
//-----------------------------
#include "ReShade.fxh"

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

// History texture for temporal reinforcement.
texture texHistory : HISTORY;
sampler samplerHistory { Texture = texHistory; };

//-----------------------------
// Helper Functions
//-----------------------------
float GetLuminance(float3 color) {
    return dot(color, float3(0.299, 0.587, 0.114));
}

float3 GetPixelColor(float2 texcoord) {
    return tex2D(samplerColor, saturate(texcoord)).rgb;
}

// Get properly adjusted depth based on user settings
float GetAdjustedDepth(float2 texcoord) {
    float depth = ReShade::GetLinearizedDepth(texcoord);

    // Flip depth if needed (some games have reversed depth buffers)
    if (FlipDepthDirection)
        depth = 1.0 - depth;

    return depth;
}

// Simple 3x3 local contrast for adaptive thresholding.
float4 GetLocalContrast(float2 texcoord, float2 pixelSize) {
    float3 center = GetPixelColor(texcoord);
    float centerLuma = GetLuminance(center);
    float minLuma = centerLuma, maxLuma = centerLuma;
    float sum = centerLuma;
    float totalWeight = 1.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            if (x == 0 && y == 0) {
                // Skip the center sample.
            } else {
                float3 smp = GetPixelColor(texcoord + float2(x, y) * pixelSize);
                float lum = GetLuminance(smp);
                minLuma = min(minLuma, lum);
                maxLuma = max(maxLuma, lum);
                float weight = (abs(x) + abs(y) == 2) ? 0.5 : 1.0;
                sum += lum * weight;
                totalWeight += weight;
            }
        }
    }
    float avgLuma = sum / totalWeight;
    return float4(maxLuma - minLuma, avgLuma, maxLuma, minLuma);
}

// Simple but effective edge detection using a 3x3 kernel
void SimpleEdgeDetection(float2 texcoord, float2 pixelSize, float depth,
                        out float edgeStrength, out float2 edgeDirection) {
    // Sample the 3x3 neighborhood
    float3 c00 = GetPixelColor(texcoord + float2(-1, -1) * pixelSize);
    float3 c10 = GetPixelColor(texcoord + float2( 0, -1) * pixelSize);
    float3 c20 = GetPixelColor(texcoord + float2( 1, -1) * pixelSize);
    float3 c01 = GetPixelColor(texcoord + float2(-1,  0) * pixelSize);
    float3 c11 = GetPixelColor(texcoord); // Center pixel
    float3 c21 = GetPixelColor(texcoord + float2( 1,  0) * pixelSize);
    float3 c02 = GetPixelColor(texcoord + float2(-1,  1) * pixelSize);
    float3 c12 = GetPixelColor(texcoord + float2( 0,  1) * pixelSize);
    float3 c22 = GetPixelColor(texcoord + float2( 1,  1) * pixelSize);

    // Simple Sobel operator
    float3 gx = c00 * -1.0 + c20 * 1.0 +
               c01 * -2.0 + c21 * 2.0 +
               c02 * -1.0 + c22 * 1.0;

    float3 gy = c00 * -1.0 + c02 * 1.0 +
               c10 * -2.0 + c12 * 2.0 +
               c20 * -1.0 + c22 * 1.0;

    // Calculate gradient magnitude for each channel
    float3 g = sqrt(gx * gx + gy * gy);

    // Use the maximum of the RGB channels for better edge detection
    float gMag = max(max(g.r, g.g), g.b);

    // Normalize by reasonable factor and apply user threshold
    edgeStrength = saturate(gMag / (EdgeDetectionThreshold * 8.0));

    // Calculate edge direction
    float2 dir = float2(0, 0);
    if (gMag > 0.01) {
        dir.x = dot(gx, float3(0.33, 0.33, 0.33));
        dir.y = dot(gy, float3(0.33, 0.33, 0.33));
        dir = normalize(dir);
    }
    edgeDirection = dir;

    // Apply perspective compensation if enabled
    if (EnablePerspectiveCompensation) {
        // Compute normalized depth factor
        float depthRange = max(0.001, MaxDepthRange - MinDepthRange);
        float perspectiveFactor = saturate((depth - MinDepthRange) / depthRange);
        perspectiveFactor = smoothstep(0, 1, perspectiveFactor);

        // Apply depth-based compensation
        float compensation = perspectiveFactor * DepthSensitivity;
        edgeStrength *= max(0.3, 1.0 - compensation * 0.7);
    }
}

float3 ApplyAdaptiveFiltering(float2 texcoord, float2 pixelSize, float edgeStrength, float2 edgeDirection) {
    float3 center = GetPixelColor(texcoord);

    // Perpendicular direction to the edge for sampling
    float2 perp = normalize(float2(-edgeDirection.y, edgeDirection.x));

    // Refined sample weights - using Gaussian-like distribution for smoother results
    const float w0 = 0.375; // Center weight
    const float w1 = 0.25;  // First neighbors
    const float w2 = 0.125; // Second neighbors
    const float w3 = 0.0625; // Third neighbors
    const float w4 = 0.0375; // Fourth neighbors

    float3 sum = center * w0;
    float totalWeight = w0;

    // Sample in perpendicular direction to the edge (odd number of samples)
    if (SamplingMode == 0) { // 5 samples
        // Fixed distance scaling for 5 samples
        const float scale5[2] = { 1.0, 2.0 };
        const float weight5[2] = { w1, w2 };

        [unroll]
        for (int i = 0; i < 2; i++) {
            float offset = scale5[i];
            float weight = weight5[i];

            // Sample in both positive and negative directions
            float2 pos1 = texcoord + perp * offset * pixelSize;
            float2 pos2 = texcoord - perp * offset * pixelSize;

            float3 color1 = GetPixelColor(pos1);
            float3 color2 = GetPixelColor(pos2);

            // Apply adaptive weight based on color similarity
            float similarity1 = 1.0 - saturate(length(color1 - center) * 2.0);
            float similarity2 = 1.0 - saturate(length(color2 - center) * 2.0);

            float adaptiveWeight1 = weight * similarity1;
            float adaptiveWeight2 = weight * similarity2;

            sum += color1 * adaptiveWeight1 + color2 * adaptiveWeight2;
            totalWeight += adaptiveWeight1 + adaptiveWeight2;
        }
    }
    else if (SamplingMode == 1) { // 7 samples
        // Fixed distance scaling for 7 samples - slightly wider pattern
        const float scale7[3] = { 1.0, 2.0, 3.0 };
        const float weight7[3] = { w1, w2, w3 };

        [unroll]
        for (int i = 0; i < 3; i++) {
            float offset = scale7[i];
            float weight = weight7[i];

            float2 pos1 = texcoord + perp * offset * pixelSize;
            float2 pos2 = texcoord - perp * offset * pixelSize;

            float3 color1 = GetPixelColor(pos1);
            float3 color2 = GetPixelColor(pos2);

            float similarity1 = 1.0 - saturate(length(color1 - center) * 1.75);
            float similarity2 = 1.0 - saturate(length(color2 - center) * 1.75);

            float adaptiveWeight1 = weight * similarity1;
            float adaptiveWeight2 = weight * similarity2;

            sum += color1 * adaptiveWeight1 + color2 * adaptiveWeight2;
            totalWeight += adaptiveWeight1 + adaptiveWeight2;
        }
    }
    else { // 9 samples
        // Fixed distance scaling for 9 samples - wider pattern with subtle far samples
        const float scale9[4] = { 1.0, 2.0, 3.0, 4.0 };
        const float weight9[4] = { w1, w2, w3, w4 };

        [unroll]
        for (int i = 0; i < 4; i++) {
            float offset = scale9[i];
            float weight = weight9[i];

            float2 pos1 = texcoord + perp * offset * pixelSize;
            float2 pos2 = texcoord - perp * offset * pixelSize;

            float3 color1 = GetPixelColor(pos1);
            float3 color2 = GetPixelColor(pos2);

            float similarity1 = 1.0 - saturate(length(color1 - center) * 1.5);
            float similarity2 = 1.0 - saturate(length(color2 - center) * 1.5);

            float adaptiveWeight1 = weight * similarity1;
            float adaptiveWeight2 = weight * similarity2;

            sum += color1 * adaptiveWeight1 + color2 * adaptiveWeight2;
            totalWeight += adaptiveWeight1 + adaptiveWeight2;
        }
    }

    // More accurate color reconstruction
    float3 blurred = sum / max(0.001, totalWeight);

    // Refine blend factor calculation
    // For edges with high strength, apply more filtering
    // For subtle edges, use gentler filtering
    float boost = pow(saturate(edgeStrength), 0.75); // Boost weak to mid-strength edges
    float blendFactor = saturate(boost * FilterStrength / 4.0);

    // Prevent over-blurring for near-perpendicular viewing angles
    if (EnablePerspectiveCompensation) {
        float depth = GetAdjustedDepth(texcoord);
        if (depth > 0.97) { // Very distant objects
            blendFactor *= 0.7; // Reduce blending for distant objects
        }
    }

    return lerp(center, blurred, blendFactor);
}

// Simplified temporal processing
float3 SimpleTemporalProcessing(float3 currentColor, float2 texcoord) {
    // Only apply if strength > 0
    if (TemporalReinforcementStrength <= 0.01)
        return currentColor;

    float3 historyColor = tex2D(samplerHistory, texcoord).rgb;

    // Simple luminance-based motion detection
    float currentLuma = dot(currentColor, float3(0.299, 0.587, 0.114));
    float historyLuma = dot(historyColor, float3(0.299, 0.587, 0.114));
    float lumaDiff = abs(currentLuma - historyLuma);

    // Reject history samples with large differences
    float motionMask = 1.0 - saturate(lumaDiff * 4.0);
    motionMask *= saturate(1.0 - MotionSensitivity * 2.0);

    // Calculate effective strength (eliminates gray/black pixelation)
    float adjustedStrength = TemporalReinforcementStrength * motionMask;

    // Only blend if the strength is meaningful
    if (adjustedStrength < 0.01)
        return currentColor;

    return lerp(currentColor, historyColor, adjustedStrength);
}

//-----------------------------
// Main Pixel Shader: PS_SHADE
//-----------------------------
float4 PS_SHADE(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target {
    float2 pixelSize = ReShade::PixelSize;
    float3 originalColor = GetPixelColor(texcoord);
    float depth = GetAdjustedDepth(texcoord);

    // Skip processing if outside depth range
    if (depth < MinDepthRange || depth > MaxDepthRange)
        return float4(originalColor, 1.0);

    // Run simplified edge detection
    float edgeStrength;
    float2 edgeDirection;
    SimpleEdgeDetection(texcoord, pixelSize, depth, edgeStrength, edgeDirection);

    // Skip if edge is too weak
    if (edgeStrength < 0.03)
        return float4(originalColor, 1.0);

    // Skip if this might be pixel art
    if (PreservePixelArt) {
        float4 localContrast = GetLocalContrast(texcoord, pixelSize);
        if (localContrast.x > 0.5 && localContrast.w < 0.1)
            return float4(originalColor, 1.0);
    }

    // Skip if this might be a star/bright point
    if (PreserveStars) {
        float centerLuma = GetLuminance(originalColor);
        float localMaxLuma = 0;

        [unroll]
        for (int y = -1; y <= 1; y++) {
            [unroll]
            for (int x = -1; x <= 1; x++) {
                if (x == 0 && y == 0) continue;
                float3 sampleColor = GetPixelColor(texcoord + float2(x, y) * pixelSize);
                localMaxLuma = max(localMaxLuma, GetLuminance(sampleColor));
            }
        }

        if (centerLuma > 0.7 && centerLuma > (localMaxLuma * 1.5))
            return float4(originalColor, 1.0);
    }

    // Apply directional blur for AA
    float3 aaColor = ApplyAdaptiveFiltering(texcoord, pixelSize, edgeStrength, edgeDirection);

    // Apply temporal stabilization
    float3 finalColor = SimpleTemporalProcessing(aaColor, texcoord);

    return float4(finalColor, 1.0);
}

technique PLAA
{
    pass MainPass
    {
        VertexShader = PostProcessVS;
        PixelShader = PS_SHADE;
    }
}
