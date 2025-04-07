# MyVectorSeek

A **single-pass anti-aliasing (AA)** shader for ReShade, featuring **five** distinct sampling quality modes. This shader combines luminance-based edge detection with a simple directional blend to reduce jagged edges in a single pass.

---

## Features

1. **Device Preset** tweaks (Steam Deck LCD, OLED, etc.) to slightly adapt final color.  
2. **Edge Detection Thresholds** to selectively smooth only where needed.  
3. **Local Variance** checks to skip near-uniform areas.  
4. **Five** sampling modes, each with a **unique** kernel size:

   | Mode         | Kernel Size | Taps  |
   | ------------ | ----------- | ----- |
   | **Standard** | 3×3         | 9     |
   | **High**     | 5×5         | 25    |
   | **Ultra**    | 7×7         | 49    |
   | **Insane**   | 9×9         | 81    |
   | **Ludicrous**| 13×13       | 169   |

5. **Debug View** options to visualize the edge mask, variance, or blend factor.

---

## Installation

1. **Install ReShade**  
   - Download and run the ReShade setup from [reshade.me](https://reshade.me/).  
   - Select your game or application, choose the applicable rendering API (e.g., DX11, DX12, Vulkan, etc.), and finish the installer.

2. **Copy the Shader File**  
   - Place `MyVectorSeek.fx` into your ReShade `\Shaders\` folder.  
   - If you’re unsure of the location, open the ReShade overlay in-game and check the *Settings* tab for “Effect Search Paths.”

3. **Enable the Effect**  
   - Launch your game/app with ReShade active.  
   - Open the ReShade menu (commonly bound to the `Home` key).  
   - In the *Home* or *Add-ons* tab, locate **MyVectorSeek**.  
   - Check the box to load and apply the effect.

---

## Usage

Open the ReShade overlay to adjust these parameters:

- **Sampling Quality**  
  - **Standard (3×3)** → **Ludicrous (13×13)**.  
  - Larger kernels provide stronger AA at a higher performance cost.

- **Filter Strength**  
  Controls how aggressively edges are blended (0.1–10.0).

- **Edge Detection Threshold**  
  Determines how strong an edge must be before AA applies.

- **Flatness Threshold**  
  Skips smoothing for near-uniform regions above this variance level.

- **Max Edge Blend**  
  Caps the maximum blend factor to avoid excessive blur.

- **Debug View**  
  Toggle between final output and debug modes (e.g., edge mask, variance, blend factor).

### Device Preset

Pick from:
- **Custom Settings**  
- **Steam Deck LCD**  
- **Steam Deck OLED**  
- **Steam Deck OLED LE**

to slightly modify the final blended color. This is mostly a placeholder to demonstrate device-specific adjustments.

---

## Performance Considerations

- **Higher Kernels**  
  **Ludicrous (13×13)** can be quite expensive at higher resolutions.  
- **Balance**  
  If performance is an issue, switch to **Standard (3×3)** or **High (5×5)** for lighter GPU usage.

---

## Troubleshooting

- **Shader Not Appearing**  
  - Verify `MyVectorSeek.fx` is placed in a recognized shader folder (see ReShade’s *Settings* tab).  
  - Make sure the effect is checked and enabled in the ReShade UI.

- **Excessive Blur**  
  - Lower `FilterStrength`, or choose a smaller kernel (e.g., Standard or High).  
  - Increase `EdgeDetectionThreshold` to reduce how many edges are blended.

- **No Visual Difference**  
  - Check if *DebugView* is on – you might be seeing masks rather than the final AA result.  
  - Reduce `FlatnessThreshold` so it doesn’t skip too many areas.

---

## Contributing

Feel free to fork or modify the shader. Potential expansions include:
- More sophisticated **curved edge** logic.  
- **Temporal** methods for added stability.  
- Additional **color-based** weighting for edge detection.

---

## License

No specific license. You are free to use, adapt, and distribute this shader for personal or non-commercial purposes. If you redistribute it, please give credit to the original authors/contributors.

---

**Enjoy MyVectorSeek and choose the sampling mode that best fits your performance and visual quality needs!**
