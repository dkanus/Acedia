# Colors

The main, and possibly only, notable thing abotu **Acedia**'s colors is it's support for parsing their text representation. To be precise, **Acedia** understands:

1. Hex color definitions in format of `#ffc0cb`;
2. RGB color definitions that look like either `rgb(255,192,203)` or `rgb(r=255,g=192,b=203)`;
3. RGBA color definitions that look like either `rgb(255,192,203,13)` or `rgb(r=255,g=192,b=203,a=13)`;
4. Alias color definitions that **Acedia** looks up from color-specific alias source and look like any other alias reference: `$pink`.

You should be able to use any form you like while working with **Acedia**.

## [Technical] Color fixing

Killing floor's standard methods of rendering colored `string`s make use of inserting 4-byte sequence into them: first bytes denotes the start of the sequence, 3 following bytes denote rgb color components. Unfortunately these methods also have issues with rendering `string`s if you specify certain values (`0` and `10`) as red-green-blue color components.

You can freely use colors with these components, since **Acedia** automatically should fix them for you (by replacing them with indistinguishably close, but valid color) whenever it matters.
