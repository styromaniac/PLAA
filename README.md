# MyVectorSeek

MyVectorSeek is a single-pass anti-aliasing (AA) shader for ReShade in combination with in-game FXAA/TAA that uses **depth-based** edge detection to smooth 3D geometry while preserving on-screen text (OSD) and UI overlays. By relying on the depth buffer, the shader minimizes AA on flat or uniform-depth elements (such as text) while smoothing out aliasing on actual 3D geometry.

## Features

- **Depth-Based Edge Detection**  
  The shader applies a Sobel operator to the depth buffer to detect edges. Since OSD text typically has a uniform depth, these regions receive minimal AA.

- **Depth Clamping and Scaling**  
  - **DepthMin/DepthMax:** Clamp the depth values to a desired range, ensuring they map properly to [0,1].  
  - **DepthEdgeScale:** Adjusts the sensitivity of the depth gradient edge detection.

- **Text(ure) Preservation**  
  **TextPreservationStrength** uses a basic curvature calculation (via second derivatives of depth) to reduce blending in smooth (low-curvature) areas, helping preserve text clarity.

- **Sampling Quality Modes**  
  Six modes determine the kernel size for local variance calculation (used to skip AA in uniform regions):
  - **Standard:** 3×3 (9 taps)
  - **High Quality:** 5×5 (25 taps)
  - **Ultra Quality:** 7×7 (49 taps)
  - **Insane:** 9×9 (81 taps)
  - **Ludicrous:** 13×13 (169 taps)
  - **God Mode:** 25×25 (625 taps)

- **Device Presets**  
  Adjust final color processing for various devices (e.g., Steam Deck LCD, OLED variants) to optimize the AA effect for your display.

- **Debug Mode**  
  One debug mode is available:
  - **Edge Mask:** Displays the computed depth edge mask.
  
  (The debug modes for Variance and Blending Factor have been removed because the final render inherently reflects the blending factor.)

- **Backward Compatibility**  
  Uses updated HLSL syntax (with `tex2D(...)` calls) for compatibility with ReShade 6.x.

## Installation

1. **Install ReShade:**  
   Download and run the latest ReShade installer from [reshade.me](https://reshade.me/). Select your game’s executable and the appropriate graphics API (usually DirectX).

2. **Copy the Shader:**  
   Place `MyVectorSeek.fx` into your ReShade `Shaders` folder (e.g., `...\reshade\Shaders\`).

3. **Configure ReShade:**  
   - Launch your game and open the ReShade overlay.
   - Ensure depth buffer access is enabled (check options such as “Copy depth buffer before clear”).
   - Verify that MyVectorSeek appears in the list of effects.

## Usage

- **Depth Edge Detection:**  
  The shader exclusively uses depth-based edge detection. Since OSD text is typically rendered at a uniform depth, it remains sharp.

- **Sampling Quality:**  
  Choose one of six modes (Standard, High Quality, Ultra Quality, Insane, Ludicrous, God Mode) to control the kernel size used for local variance calculations. Higher modes offer more refined detection at a performance cost.

- **Depth Clamping:**  
  Adjust `DepthMin` and `DepthMax` if your game’s depth range is not fully mapped to [0,1].

- **DepthEdgeScale:**  
  Change this value to alter the sensitivity of depth gradient detection. Increase it to enhance edge detection in 3D geometry.

- **Text(ure) Preservation:**  
  Use the `TextPreservationStrength` slider to reduce blending in smooth, low-curvature regions—helping to maintain OSD text clarity.

- **Device Preset:**  
  Select a preset to apply a subtle final color adjustment based on your display type.

- **Debug Mode:**  
  Enable `DebugView` and select **Edge Mask** to visualize the computed depth edge mask.

## Parameters

| Parameter                      | Description                                                                                                                         |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| **DevicePreset**               | Device-specific color processing preset (Custom Settings, Steam Deck LCD, OLED variants).                                           |
| **FilterStrength**             | Overall strength of the AA effect (higher values yield stronger blending).                                                         |
| **EdgeDetectionThreshold**     | Threshold for detecting depth edges; adjust to ignore subtle edges or capture more 3D geometry.                                       |
| **FlatnessThreshold**          | Depth variance threshold for skipping AA in nearly uniform areas.                                                                  |
| **MaxBlend**                   | Maximum blend factor used for edge smoothing.                                                                                      |
| **TextPreservationStrength**   | Reduces blending in smooth (low-curvature) areas to preserve text clarity.                                                         |
| **SamplingQuality**            | Determines the kernel size used for local variance calculations (affects how AA is applied in uniform regions).                      |
| **CurveDetectionStrength**     | Placeholder for further curvature-based adjustments (currently not used; see TextPreservationStrength for text preservation).         |
| **DepthMin / DepthMax**        | Clamp the depth values read from the depth buffer to a [0,1] range for optimal edge detection.                                       |
| **DepthEdgeScale**             | Scale factor for the depth gradient computed by the Sobel operator; adjust to better detect edges in your game’s 3D geometry.         |
| **DebugView / DebugMode**      | Enable and choose debug output (Edge Mask) to visualize intermediate edge detection stages.                                         |

## Troubleshooting

- **OSD Text Blurring:**  
  If text is still blurred, try lowering `FilterStrength` or `MaxBlend`, or increasing `TextPreservationStrength` to reduce blending in smooth areas.

- **Performance Issues:**  
  Higher sampling quality modes (especially God Mode) require more GPU resources. Choose a lower mode if you experience performance drops.

- **Depth Issues:**  
  If the depth buffer isn’t providing useful data, adjust `DepthMin` and `DepthMax` or verify that depth access is enabled in ReShade.

## License

This shader is released under the GNU Affero General Public License v3.0. You are free to use, modify, and distribute it as long as any derivative works are also released under the same license.

For full details, see the [GNU AGPL v3.0 license](https://www.gnu.org/licenses/agpl-3.0.html).

## Credits

- [ReShade](https://reshade.me/) for the post-processing framework.
- Community members for valuable feedback and contributions.

---

Enjoy improved anti-aliasing that preserves on-screen text clarity using depth-based edge detection and text(ure) preservation!
