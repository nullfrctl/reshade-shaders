<!-- @format -->

[ACES]: https://acescentral.com
[ACEScg]: https://docs.acescentral.com/specifications/acescg/
[ACEScct]: https://docs.acescentral.com/specifications/acescct/
[CC]: https://github.com/nullfrctl/reshade-shaders/blob/main/Shaders/CC.fx

# reshade-shaders [<img alt="ReShade" align="right" src="https://github.com/nullfrctl/loathe/assets/99456326/34a349b7-9c7e-4621-a2a9-ca5661931d81" width="56px">](https://reshade.me/)

Loathesome shaders for ReShade. A successor to nullFX.

## [CC], Color Correction

[ACES]-based color correction shader.

The first<sup>[_citation needed_]</sup> ReShade color correction shader which uses [ACES] to its full extent, including:
- forward and inverse sRGB ODTs;
- forward and inverse RRTs;
- [ACEScct];
- [ACEScg];
- ACES 2065-1.

[CC] is also LUT-based, using a compute shader to generate a LUT on-the-fly which can accurately generate HDR data from LDR content using an inverse sRGB ODT and RRT.
All of this gives [CC] a varied feature-set, which is:
- HDR exposure (for real, using [ACEScg]);
- luminance-preserving RGB mixing;
- cinematic color response (due to RRT and ODT);
- log-based color correction/grading ([ACEScct]);
- [ASC CDL](https://en.wikipedia.org/wiki/ASC_CDL) (lift, gamma, gain, which are instead offset, power, slope; also saturation);
- linear contrast and levels (s-curves coming soon…).

### Images
_coming soon…_
