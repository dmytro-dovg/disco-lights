
![Latest Version](https://img.shields.io/factorio-mod-portal/v/disco-lights) ![Last Updated](https://img.shields.io/factorio-mod-portal/last-updated/disco-lights) ![Downloads](https://img.shields.io/factorio-mod-portal/dt/disco-lights)
![License](https://img.shields.io/github/license/dmytro-dovg/disco-lights)

[planner-icon]: docs/planner_icon.png
[demo-shapes]: docs/shapes.png
[gui]: docs/gui.png
[demo-static]: docs/static.png
[demo-spectrum]: docs/spectrum.gif
[demo-radius]: docs/radii.png
[demo-ys-spectrum]: docs/ys-spectrum.gif

# Disco Lights

Placeable ambient light sources. Add some mood lighting to your factory or have a disco party with biters.

The lights are purely decorative and can be placed without any resources or research.

## Usage

Create ![planner-icon] $\color{#2cd23f}\textsf{[Item: Disco lights planner]}$ in the cursor by pressing $\color{#80cef0}\textsf{Alt}$ + $\color{#80cef0}\textsf{K}$ or clicking the dedicated button on the shortcut bar.

Then $\color{#80cef0}\textsf{Left-click}$ and drag to select an area to place a light.

![demo-shapes]

$\color{#80cef0}\textsf{Shift}$ + $\color{#80cef0}\textsf{Left-click}$ to open the light settings window. These settings will only apply to new light placements.

![gui]

## Customisation

Currently there are 2 modes of operation:

- Static - single colour light source.
- Spectrum - spectrum cycling with a configurable phase offset and duration.

![demo-static] ![demo-spectrum]

There is also a configurable glow radius which governs how far the light spreads from its source: 1, 2, 4, 8, 16 tiles.

![demo-radius]
![demo-ys-spectrum]

## Controls

While holding ![planner-icon] $\color{#2cd23f}\textsf{[Item: Disco lights planner]}$ the following controls are available.

| Control | Action |
|  ---    |  ---   |
| $\color{#80cef0}\textsf{Left-click}$ and drag | Add a light over the selected area |
| $\color{#80cef0}\textsf{Right-click}$ and drag | Remove selected lights |
| $\color{#80cef0}\textsf{Shift}$ + $\color{#80cef0}\textsf{Left-click}$ | Open light settings |
| $\color{#80cef0}\textsf{Alt}$ + $\color{#80cef0}\textsf{Mouse wheel up/down}$ | Cycle the radius |
| $\color{#80cef0}\textsf{Control}$ + $\color{#80cef0}\textsf{Alt}$ + $\color{#80cef0}\textsf{Mouse wheel up/down}$ | Cycle the mode |

## License

[MIT](LICENSE)
