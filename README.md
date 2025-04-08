# MyVectorSeek.fx

MyVectorSeek.fx is a single-pass anti-aliasing shader that optimizes latency by reducing redundant memory accesses and consolidating computations. Built for integration with ReShade, this shader is designed to work in tandem with FXAA while keeping full visual quality.

## Features

- **Optimized Edge Detection:**  
  Uses a consolidated 3×3 neighborhood sampling strategy to compute both luminance-based Sobel and color difference edge masks. Select between Luminance, Color, or Hybrid modes.

- **Latency Reduction Improvements:**  
  - **Minimized Memory Accesses:** Caches neighboring pixel data to avoid redundant texture fetches.  
  - **Conditional Evaluation:** Introduces early exits for weak edges to skip heavy computations.  
  - **Combined Computations:** Reuses cached samples for gradient and edge mask calculations.  
  - **Device-Specific Adjustments:** Automatically adjusts anti-aliasing parameters for different device presets (e.g., Steam Deck LCD, OLED).

- **Customizability:**  
  Multiple user-configurable parameters allow fine-tuning of filter strength, edge detection thresholds, blending factors, sampling quality, depth clamping, and debug output modes.

## File Structure

- **MyVectorSeek.fx:**  
  The primary shader file featuring all latency optimizations and performance improvements.

## Getting Started

1. **Installation:**  
   Place the `MyVectorSeek.fx` file in your ReShade shader directory.

2. **Configuration:**  
   Adjust user-configurable parameters via the ReShade UI. Key parameters include:
   - **Device Preset:** Select the appropriate device profile.
   - **Filter Strength and Edge Detection Threshold:** Control the intensity and sensitivity of the anti-aliasing.
   - **Max Blend and Sampling Quality:** Fine-tune the blending and sampling performance.
   - **Debug Modes:** Toggle visual output of edge masks, variance, or blending factors for troubleshooting.

3. **Usage with FXAA:**  
   The shader is designed to complement FXAA. Ensure FXAA is enabled in your ReShade configuration to achieve optimal visual quality.

## License

*Insert license information here as applicable.*

## Notes

This version of MyVectorSeek.fx maintains the original filename and integrates significant latency improvements. Further adjustments can be made based on performance profiling or device-specific requirements.