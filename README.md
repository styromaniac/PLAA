# MyVectorSeek

MyVectorSeek is a single-pass anti-aliasing (AA) shader for ReShade that uses **depth-based** edge detection exclusively to smooth 3D geometry while preserving on-screen text (OSD) and UI overlays. By relying on the depth buffer, the shader avoids blurring elements rendered on a uniform depth plane (such as text), while still reducing aliasing on 3D edges. This is to be used in conjunction with in-game FXAA/TAA.

## Features

- **Depth-Based Edge Detection**  
  The shader uses a Sobel operator on the depth buffer to detect edges. Depth gradients tend to be low in 2D UI/text areas (which are typically rendered at a constant depth), so those regions remain sharp.

- **Depth Clamping and Scaling**  
  - **DepthMin/DepthMax:** Two sliders allow you to clamp the depth values to a desired range, ensuring that the shader correctly interprets your game's depth data.  
  - **DepthEdgeScale:** Adjusts the sensitivity of the depth-based edge detection.

- **Text(ure) Preservation**  
  The new **TextPreservationStrength** parameter uses a basic curvature (via second derivatives) computed from depth. In smooth (low-curvature) areas, the blend factor is reduced so that areas like OSD text aren’t overly blurred.

- **Sampling Quality Modes**  
  Five modes determine the kernel size for local variance computation (used to skip AA in uniform regions):  
  - **Standard:** 3×3 (9 taps)  
  - **High Quality:** 5×5 (25 taps)  
  - **Ultra Quality:** 7×7 (49 taps)  
  - **Insane:** 9×9 (81 taps)  
  - **Ludicrous:** 13×13 (169 taps)

- **Device Presets**  
  Adjust final color processing for various devices (e.g., Steam Deck LCD, OLED variants) to optimize the AA effect for your display.

- **Debug Modes**  
  Three debug output modes are available to visualize internal computations:  
  - **Edge Mask:** Displays the computed edge mask.  
  - **Variance:** Shows the local variance (depth-based) used to determine uniform regions.  
  - **Blending Factor:** Visualizes the final blend factor computed before the color lerp.

- **Backward Compatibility**  
  The shader uses updated HLSL syntax (with `tex2D(...)` calls) for compatibility with ReShade 6.x.

## Installation

1. **Install ReShade:**  
   Download and run the latest ReShade installer from [reshade.me](https://reshade.me/). Select your game’s executable and the appropriate graphics API (usually DirectX).

2. **Copy the Shader:**  
   Place `MyVectorSeek.fx` in your ReShade `Shaders` folder (e.g., `...\reshade\Shaders\`).

3. **Configure ReShade:**  
   - Open your game and bring up the ReShade overlay.
   - Ensure depth buffer access is enabled (check options such as “Copy depth buffer before clear”).
   - Verify that your shader is loaded in the ReShade menu.

## Usage

- **Depth Edge Detection:**  
  The shader uses depth-based edge detection exclusively. Since OSD text usually has uniform depth, the AA effect is minimized on text.

- **Sampling Quality:**  
  Choose one of five modes (Standard to Ludicrous) to control the kernel size for local variance calculation. Higher modes yield better edge detection in uniform areas at the cost of performance.

- **Depth Clamping:**  
  Adjust the `DepthMin` and `DepthMax` sliders if your game’s depth range isn’t fully mapped to [0,1].

- **DepthEdgeScale:**  
  Modify this value to change the sensitivity of depth gradient detection. Increasing the value will enhance the detection of edges in 3D geometry.

- **Text(ure) Preservation:**  
  Use the `TextPreservationStrength` slider to control how much blending is reduced in smooth (low-curvature) regions. Lower blending in these areas helps preserve the clarity of on-screen text.

- **Device Preset:**  
  Select a device preset to apply a subtle color tweak based on your display characteristics.

- **Debug Mode:**  
  Enable `DebugView` and choose a debug mode (Edge Mask, Variance, or Blending Factor) to visualize internal data and help tune your settings.

## Parameters

| Parameter                      | Description                                                                                                                               |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| **DevicePreset**               | Device-specific color processing preset (Custom Settings, Steam Deck LCD, OLED variants).                                                 |
| **FilterStrength**             | Overall strength of the AA effect (higher values yield stronger blending).                                                               |
| **EdgeDetectionThreshold**     | Threshold for detecting depth edges. Adjust to ignore subtle edges or catch more geometry.                                                |
| **FlatnessThreshold**          | Variance threshold for skipping AA in nearly uniform (flat) areas.                                                                       |
| **MaxBlend**                   | Maximum blend factor clamp for edge smoothing.                                                                                          |
| **TextPreservationStrength**   | Controls how much blending is reduced in low-curvature (smooth) areas to help preserve text clarity.                                        |
| **SamplingQuality**            | Determines the kernel size used for local variance calculations (affects how AA is applied in uniform areas).                              |
| **CurveDetectionStrength**     | Placeholder for additional curvature-based edge adjustments (currently not used; see TextPreservationStrength for text preservation).       |
| **DepthMin / DepthMax**        | Clamp the depth values read from the depth buffer to a [0,1] range for optimal edge detection.                                             |
| **DepthEdgeScale**             | Scale factor for the depth gradient computed by the Sobel operator. Adjust to better detect edges in your game’s 3D geometry.              |
| **DebugView / DebugMode**      | Enable and choose debug output (Edge Mask, Variance, or Blending Factor) to visualize intermediate processing stages.                      |

## Troubleshooting

- **OSD Text Blurring:**  
  If on-screen text is still blurred, try lowering the `FilterStrength` or `MaxBlend` values, or increasing the `TextPreservationStrength` so that blending is reduced more aggressively in smooth (text) regions.

- **Performance Issues:**  
  Higher sampling quality modes (e.g., Insane or Ludicrous) require more GPU resources. Use lower modes if you experience performance drops.

- **Depth Issues:**  
  If the depth buffer isn’t providing useful data, adjust the `DepthMin` and `DepthMax` sliders or verify that depth access is enabled in the ReShade settings.

## License

This shader is released under the GNU Affero General Public License v3.0. You are free to use, modify, and distribute it as long as any derivative works are also released under the same license.

For full details, see the [GNU AGPL v3.0 license](https://www.gnu.org/licenses/agpl-3.0.html).

## Credits

- [ReShade](https://reshade.me/) for the post-processing framework.
- Community members for valuable feedback and contributions to refining this shader.

---

Enjoy improved anti-aliasing that preserves on-screen text clarity using depth-based edge detection and text(ure) preservation!
