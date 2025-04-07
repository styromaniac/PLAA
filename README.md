# MyVectorSeek

MyVectorSeek is a single-pass anti-aliasing (AA) shader for ReShade designed to provide flexible edge detection while minimizing unwanted blurring of UI text and overlays. The shader supports multiple edge detection modes and sampling quality settings, along with depth clamping options for improved compatibility with various games. It is backward‐compatible with ReShade 6.x, using updated HLSL syntax (with `tex2D(...)` calls).

## Features

- **Edge Detection Modes**  
  Choose between three edge detection strategies:
  - **Luminance:** Uses a Sobel operator on luminance (brightness) only. Ideal for sparing text that differs primarily in color.
  - **Color:** Uses a Sobel operator combined with a color difference metric to capture all visible edges.
  - **Hybrid:** Merges luminance and color-based methods for balanced edge detection in 3D scenes.

- **Sampling Quality Modes**  
  Five distinct local variance sampling modes determine how many neighboring pixels are sampled:
  - **Standard:** 3×3 kernel (9 taps)
  - **High Quality:** 5×5 kernel (25 taps)
  - **Ultra Quality:** 7×7 kernel (49 taps)
  - **Insane:** 9×9 kernel (81 taps)
  - **Ludicrous:** 13×13 kernel (169 taps)

- **Depth Min/Max Sliders**  
  Fine-tune how the shader interprets the depth buffer with customizable minimum and maximum depth values. This helps adapt the shader to games with unusual depth ranges or reversed depth.

- **Device Presets**  
  Adjust final color processing for various devices (e.g., Steam Deck LCD, OLED variants) to optimize the AA effect for your display type.

- **Debug Modes**  
  Three debug output modes are available to visualize internal computations:
  - **Edge Mask:** Displays the computed edge detection mask.
  - **Variance:** Shows the local variance used in sampling.
  - **Blending Factor:** Visualizes the blend factor used in the final AA step.

- **Backward Compatibility**  
  The shader uses updated HLSL syntax with `tex2D(...)` calls to ensure compatibility with ReShade 6.4.1 and newer.

## Installation

1. **Install ReShade:**  
   Download and run the latest ReShade installer from [reshade.me](https://reshade.me/). Select your game’s executable and the appropriate graphics API (usually DirectX).

2. **Copy the Shader:**  
   Place `MyVectorSeek.fx` in your ReShade `Shaders` folder (e.g., `...\reshade\Shaders\`).

3. **Configure ReShade:**  
   - Open your game and bring up the ReShade overlay.
   - Enable depth buffer access (check options such as “Copy depth buffer before clear”).
   - Verify that your shader is loaded via the ReShade menu.

## Usage

- **Edge Detection Mode:**  
  Use the `EdgeMode` dropdown to select:
  - **Luminance:** Best for sparing text that has similar brightness.
  - **Color:** Captures edges based on color differences (may blur text more).
  - **Hybrid:** A balanced approach that combines both methods.

- **Sampling Quality:**  
  Choose the desired sampling quality mode from Standard to Ludicrous. Higher-quality modes sample more taps, improving edge detection in uniform areas but requiring more GPU resources.

- **Depth Min/Max:**  
  Adjust the `DepthMin` and `DepthMax` sliders if your game’s depth values require clamping to a 0–1 range for optimal edge detection.

- **Device Preset:**  
  Select a preset to slightly adjust the final color blend based on your display characteristics.

- **Debug Mode:**  
  Enable `DebugView` and select a debug mode (Edge Mask, Variance, or Blending Factor) to visualize internal edge detection and sampling data.

## Parameters

| Parameter                      | Description                                                                                                                   |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| **DevicePreset**               | Device-specific color processing preset (Custom Settings, Steam Deck LCD, OLED variants).                                     |
| **FilterStrength**             | Overall strength of the AA effect (higher values yield stronger blending).                                                   |
| **EdgeDetectionThreshold**     | Threshold for detecting edges; higher values ignore subtle edges.                                                            |
| **FlatnessThreshold**          | Threshold for skipping AA in near-uniform areas.                                                                             |
| **MaxBlend**                   | Maximum blend factor applied to edges.                                                                                       |
| **GradientPreservationStrength** | (Placeholder) Intended to preserve smooth gradients.                                                                      |
| **SamplingQuality**            | Determines the kernel size for local variance calculations (affects the AA effect in uniform regions).                       |
| **CurveDetectionStrength**     | (Placeholder) For future curved edge detection improvements.                                                                |
| **EdgeMode**                   | Select between Luminance, Color, or Hybrid edge detection methods.                                                           |
| **DepthMin / DepthMax**        | Clamp depth values from the depth buffer to a 0–1 range for optimal edge detection.                                          |
| **DebugView / DebugMode**      | Enable and choose the debug output mode (Edge Mask, Variance, Blending Factor) to visualize intermediate processing stages. |

## Troubleshooting

- **Text Blurring:**  
  If text appears blurred, try switching to the **Luminance** edge mode, increasing the `EdgeDetectionThreshold`, or reducing `FilterStrength`/`MaxBlend`.

- **Performance Issues:**  
  Higher sampling quality modes (e.g., Insane, Ludicrous) require more GPU resources. Lower the mode if you experience performance drops.

- **Depth Issues:**  
  If the depth buffer isn’t providing useful data, adjust the `DepthMin` and `DepthMax` values or try a different edge mode.

## License

This shader is licensed under the GNU Affero General Public License v3.0. You are free to use, modify, and distribute it, but any modified versions must also be released under the same license.

For more details, see the [GNU AGPL v3.0 license](https://www.gnu.org/licenses/agpl-3.0.html).

## Credits

- [ReShade](https://reshade.me/) for the post-processing framework.
- Community members for feedback and contributions that helped refine this shader.

---

Enjoy the flexibility of three edge detection modes, fine-tuning options, and backward compatibility with modern ReShade versions!
