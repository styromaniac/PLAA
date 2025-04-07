# MyVectorSeek

A **single-pass anti-aliasing (AA)** shader for ReShade, featuring **five** distinct sampling quality modes. This shader combines luminance-based edge detection and simple directional blending to achieve improved edge smoothing in a single pass.

---

## Features

1. **Device Preset** tweaks (Steam Deck LCD, OLED, etc.) to slightly adapt final color.  
2. **Edge Detection Thresholds** to selectively smooth only where needed.  
3. **Local Variance** checks to skip near-uniform areas.  
4. **Five** sampling modes, each with unique kernel sizes:

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
   - Download the latest ReShade from [reshade.me](https://reshade.me/).  
   - Follow the setup wizard for your game or application.  
   - Choose the appropriate rendering API (DirectX9, DirectX10/11/12, Vulkan, OpenGL, etc.).  

2. **Place the Shader File**  
   - Copy `MyVectorSeek.fx` into your ReShade `\Shaders\` folder.  
   - If you don’t know that folder location, open the ReShade menu in-game and check the *Settings* tab for the “Effect Search Paths.”

3. **Enable the Shader**  
   - Run your game/application with ReShade active.  
   - Press `Home` (or your configured hotkey) to open the ReShade overlay.  
   - In the *Home* or *Add-ons* tab, locate **MyVectorSeek**.  
   - Check its box to load and apply the effect.

---

## Usage

Open the ReShade overlay to adjust these parameters:

- **Sampling Quality**  
  Choose from Standard (3×3) to Ludicrous (13×13). Each mode increases the number of taps, improving AA at the cost of performance.

- **Filter Strength**  
  Controls how strongly edges are blended. Higher values mean more blurring.

- **Edge Detection Threshold**  
  Lower values detect more edges (potentially over-blurring). Higher values require stronger edges before applying AA.

- **Flatness Threshold**  
  Skips smoothing for near-uniform regions. Lower values allow smoothing everywhere; higher values reduce smoothing in plain areas.

- **Max Edge Blend**  
  Caps the maximum blend factor when smoothing edges.

- **Debug View**  
  Toggle to see intermediate masks (edge mask, variance, blend factor) or return to the final color output.

### Device Preset

**DevicePreset** lets you pick from “Custom Settings,” “Steam Deck LCD,” or “Steam Deck OLED” to slightly alter final color. This is optional and mostly a placeholder.

---

## Performance Considerations

1. **Resolution Impact**  
   - Higher kernel sizes (e.g., **Ludicrous** with a 13×13 kernel) can be expensive at higher resolutions like 1440p or 4K.  
   - Expect a noticeable FPS hit if you combine high resolution with the largest sampling modes.

2. **Tuning**  
   - If performance suffers, try a lower sampling mode (Standard or High).  
   - If you want even sharper edges, raise `FilterStrength`, but be mindful of potential over-blur on smaller details.

---

## Troubleshooting

- **Shader Not Visible or Not Loading**  
  - Ensure `MyVectorSeek.fx` is in a folder ReShade recognizes as a valid search path.  
  - Confirm in the ReShade overlay that the effect is checked/enabled.

- **Too Much Blur or Artifacts**  
  - Lower `FilterStrength` or use a smaller kernel mode.  
  - Increase `EdgeDetectionThreshold` so the effect only applies to stronger edges.

- **No Apparent Change**  
  - Turn on `DebugView` to see if edges are being detected.  
  - Reduce `FlatnessThreshold` to ensure the effect isn’t skipping large uniform areas.

---

## Contributing

Feel free to modify or fork the shader to improve performance or add new features (e.g., curved edge detection, multi-directional sampling, advanced color weighting, etc.).

---

## License

This shader is offered as-is, with no specific license. You may use, adapt, and redistribute it for personal or non-commercial purposes. If you redistribute it, please credit the original authors/contributors.

---

Enjoy your **MyVectorSeek** single-pass AA shader—whether you stick to **Standard** or push it to **Ludicrous**!
