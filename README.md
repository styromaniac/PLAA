# MyVectorSeek

A **single-pass anti-aliasing** (AA) effect for ReShade that offers multiple kernel sizes, from a modest **3×3** to a **ridiculously** big **25×25** “God Mode.”  

## What It Does

MyVectorSeek tries to smooth out edges by:

1. Checking local **variance** in a small (or gigantic) neighborhood.  
2. Calculating a **Sobel-like** gradient and **color difference** to detect edges.  
3. Blending across those edges in a perpendicular direction.

**Disclaimer**: This is a fun, experimental approach. Don’t expect it to surpass advanced techniques like TAA or SMAA, especially in the extreme modes that can hammer performance without providing proportionally better image quality.

---

## Modes & Performance

- **Standard / High / Ultra** (Index 0,1,2)  
  - Use a **3×3** kernel. Fastest and simplest.  
- **Insane (96)** (Index 3)  
  - 5×5 kernel. Slightly bigger overhead.  
- **Ludicrous (192)** (Index 4)  
  - 9×9 kernel. May hit performance harder.  
- **Ridiculous (384)** (Index 5)  
  - 13×13 kernel. Guaranteed frame rate hit at higher resolutions.  
- **God Mode (768)** (Index 6)  
  - 25×25 kernel (625 taps). Absolutely destroys performance in many cases.

> ### Why the weird numbers (96, 192, 384, 768)?
> They’re mostly comedic references to indicate bigger leaps in sampling cost. The actual tap counts for each kernel differ (5×5=25, 9×9=81, 13×13=169, 25×25=625).  

---

## Installation

1. Install **[ReShade](https://reshade.me/)**.  
2. Place **MyVectorSeek.fx** in your ReShade `\Shaders\` folder.  
3. Launch your game, open ReShade, enable **MyVectorSeek** in the effect list.  

---

## Usage

1. In the ReShade overlay, look for the **MyVectorSeek** section.  
2. Pick a **Sampling Quality**. “God Mode” is purely for the daring (and those with GPUs to spare).  
3. Adjust:
   - **FilterStrength** for how strong the blend is.  
   - **EdgeDetectionThreshold** to catch more or fewer edges.  
   - **MaxBlend** if things look too smeared.  
   - **FlatnessThreshold** to skip uniform areas.  
4. (Optional) **DebugView** can display intermediate data (edge mask, variance, etc.).

---

## Known Limitations

- The large kernels might not meaningfully reduce aliasing in many real-world cases, but they will definitely reduce your frame rate.  
- This approach doesn’t track motion or rely on additional buffers, so it’s not temporal. Edges might still flicker in fast motion.  
- Some color banding or smearing may appear on high-contrast geometry, especially if `FilterStrength` is set very high.

---

## Credits & License

- **Original concept** by [Your Name], with thanks to the ReShade community for code snippets and feedback.  
- Provided **as-is**, free for personal or non-commercial use. Feel free to modify or adapt it to your needs. If you redistribute, a small credit is appreciated.

> **Have fun trying out “God Mode,” but don’t say we didn’t warn you about the performance meltdown!**
