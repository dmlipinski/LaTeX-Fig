LaTeX-Fig
=========

A MATLAB script to export figures using a system installation of LaTeX to process text objects.

**Basic usage:**
Make sure the latex\_fig.m file is in your MATLAB path and type "help latex\_fig". Also see the "example.m" file for an example usage case.

**Known issues:**
 - Rasterized plot objects are placed in front of all text and vector objects. This is especially an issue for 3D plots with the plot box on since the front edges of the plot box will appear behind any rasterized plot objects.
 - There are many issues with multiple axes appearing on the same figure when the '-rasterize' option is used, especially if the axes overlap.
 - Relies on "print2array" function in the export_fig package. This function can also be very slow.

**Improvements coming soon:**
 - Add Windows support.
 - Move to a more complete layering system when the '-rasterize' option is present so that multiple axes, axis background colors, and the figure color can all be included in the correct order. This should be accomplished by first laying down the figure background color, then looping through the axes (direct children of the figure) from back to front. For each axis, there should be three layers: a background layer for axis color and the back of the plot box. A middle layer for rasterized plot objects, and a front layer for the remaining vector objects.
