# MyVectorSeek

A **single-pass anti-aliasing (AA)** shader for ReShade that offers multiple sampling quality levels—from *Standard* to **God Mode (768)**. Originally inspired by the idea of combining luminance-based edge detection with a simple one-directional blur, this shader has been extended to feature:

- **Device Preset** tweaks (Steam Deck LCD, OLED, etc.)  
- Various **edge detection** thresholds and blending controls  
- **Local variance** checks to skip near-uniform areas  
- Multiple sampling modes:
  - Standard / High / Ultra
  - Insane (96)
  - Ludicrous (192)
  - Ridiculous (384)
  - God Mode (768)

> **Note:** The numerical labels (96, 192, 384, 768) do not precisely match the exact tap counts. They are humorous references for the size or complexity of the sampling kernel, which can be quite large in extreme modes.

---

## How to Install

1. **Install ReShade**  
   - Download and run the ReShade setup from [reshade.me](https://reshade.me/).  
   - Select the game or application you want to use with ReShade.  
   - Choose a graphics API (typically DirectX 9, 10/11/12, OpenGL, or Vulkan).  
   - Allow ReShade to install its default shaders or skip if you only want to use custom effects.

2. **Place the Shader File**  
   - Copy `MyVectorSeek.fx` into your ReShade `\Shaders\` folder (where ReShade looks for `.fx` files).  
   - If you’re not sure where that folder is, open the ReShade in-game menu, go to the *Settings* tab, and check the “Effect Search Paths.”

3. **Activate the Effect**  
   - Launch your game/application with ReShade.  
   - Press the configured ReShade hotkey (e.g., `Home`) to open the overlay.  
   - Under the *Home* or *Add-ons* tab, find **MyVectorSeek** or a similar named effect in the list.  
   - Check the box next to it to enable.

4. **Tweak Settings**  
   - Use the ReShade UI to adjust *FilterStrength*, *EdgeDetectionThreshold*, *SamplingQuality*, and other parameters.  
   - Toggle *Debug View* to see intermediate masks or variance data.

---

## Shader Parameters

| Name                          | Description                                                                                                       |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **DevicePreset**              | A preset combo box for certain device tweaks (e.g., Steam Deck LCD, Steam Deck OLED). Adjusts final color slightly. |
| **FilterStrength**            | Controls the intensity of the AA blending. Higher values = stronger blur.                                        |
| **EdgeDetectionThreshold**    | Luminance threshold for identifying edges.                                                                        |
| **FlatnessThreshold**         | Variance threshold to skip near-uniform areas (prevents overblurring).                                           |
| **MaxBlend**                  | Caps how much blending can be applied to each edge.                                                               |
| **GradientPreservationStrength** | Placeholder for additional gradient logic (not fully implemented).                                              |
| **SamplingQuality**           | Combo box ranging from Standard to God Mode. Higher modes use larger local variance kernels (3×3 → 25×25).        |
| **CurveDetectionStrength**    | Placeholder for future curved-edge logic (not fully implemented).                                                |
| **DebugView** and **DebugMode** | Visualize the edge mask, variance, or blending factor, instead of final color.                                    |

---

## Performance Considerations

- **Large Kernels**  
  The “Insane,” “Ludicrous,” “Ridiculous,” and especially “God Mode (768)” modes use big sampling kernels (5×5 → 25×25). This can heavily impact performance on higher resolutions.
- **Resolution Impact**  
  Using *Ridiculous* or *God Mode* at 4K or above may lead to significant FPS drops unless you have a very powerful GPU.  
  Consider using lower screen resolutions or dynamic resolution scaling when playing with these extreme modes.

---

## Troubleshooting

1. **Shader Not Showing Up**  
   - Confirm the `.fx` file is in a folder that ReShade is scanning for shaders (see *Settings* tab in ReShade).
   - Ensure the effect is not overshadowed by other post-processing or incorrectly sorted in the load order.

2. **No Visible AA Effect**  
   - Increase `FilterStrength`, lower `EdgeDetectionThreshold`, and disable other AA effects to clearly see MyVectorSeek’s impact.
   - Check if *DebugView* is turned on. If it’s in a debug mode, you won’t see final colors.

3. **Excessive Blur or Artifacts**  
   - Try reducing `FilterStrength` or `MaxBlend`.
   - Lower the sampling quality back to *Standard* or *High* for less aggressive sampling.

---

## Contributing

Feel free to fork this shader, submit pull requests, or tweak settings to improve performance or quality. Some ideas for future expansions include:

- Better **curve detection** logic using additional partial derivative checks.  
- Enhanced **temporal stability** or combining with a velocity buffer (though that typically goes beyond single-pass ReShade).  
- More sophisticated color-based methods in addition to the Sobel operator.

---

## License

This shader is provided as-is, with no specific license attached. You are free to use, modify, and redistribute it for personal or non-commercial purposes. If you republish or bundle it, please give credit to the original authors or contributors.

---

## Credits

- [ReShade](https://reshade.me/) for the post-processing framework.  
- All community members who tested or contributed ideas for advanced AA kernels and edge detection.

---

**Enjoy testing out the extremes from *Standard* all the way to *God Mode (768)*—but be mindful of your FPS!**
