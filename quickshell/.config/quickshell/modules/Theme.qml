// AUTO-GENERATED — edit the template, not this file.
// Driver: themes/.config/themes/theme-processor.py
// Both palettes are inlined; the active one is selected at runtime by
// watching ~/.config/theme_mode so theme toggles reflow the shell via
// QML property binding without restarting `qs`.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    property string mode: "dark"

    readonly property var palettes: ({
        "light": {
            "bg":          "#FAF9F6",
            "bg_alt":      "#F2F1EE",
            "tertiary":    "#F0EFEC",
            "selection":   "#E7E5E1",
            "surface":     "#EDECE9",
            "overlay":     "#E0DFDC",
            "prompt":      "#E8EAED",
            "success_bg":  "#DDDBCC",
            "error_bg":    "#F9CFC1",
            "warning_bg":  "#F5DECE",
            "info_bg":     "#D2D9CF",
            "fg":          "#2D4A3D",
            "fg_secondary":"#575279",
            "fg_muted":    "#6B6E7A",
            "fg_subtle":   "#636463",
            "red":         "#7c3438",
            "orange":      "#e16511",
            "yellow":      "#df9001",
            "green":       "#5E7270",
            "cyan":        "#243560",
            "blue":        "#396171",
            "sky":         "#0284C7",
            "purple":      "#2a618d",
            "pink":        "#516088",
            "cursor":      "#FF570D",
            "hairlineAlpha": 0.5,
            "dimmedFgAlpha": 0.55
        },
        "dark": {
            "bg":          "#181818",
            "bg_alt":      "#1B1B1B",
            "tertiary":    "#1B1B1B",
            "selection":   "#282F38",
            "surface":     "#1B1B1B",
            "overlay":     "#292826",
            "prompt":      "#323A40",
            "success_bg":  "#313734",
            "error_bg":    "#462B2A",
            "warning_bg":  "#462415",
            "info_bg":     "#45474B",
            "fg":          "#EDEDED",
            "fg_secondary":"#C3C8C6",
            "fg_muted":    "#707B84",
            "fg_subtle":   "#707B84",
            "red":         "#FF7B72",
            "orange":      "#FF570D",
            "yellow":      "#ff8a31",
            "green":       "#97B5A6",
            "cyan":        "#8A9AA6",
            "blue":        "#CCD5E4",
            "sky":         "#7DD3FC",
            "purple":      "#8A92A7",
            "pink":        "#8A92A7",
            "cursor":      "#FF570D",
            "hairlineAlpha": 0.15,
            "dimmedFgAlpha": 0.7
        }
    })

    readonly property color bg:           palettes[mode].bg
    readonly property color bg_alt:       palettes[mode].bg_alt
    readonly property color tertiary:     palettes[mode].tertiary
    readonly property color selection:    palettes[mode].selection
    readonly property color surface:      palettes[mode].surface
    readonly property color overlay:      palettes[mode].overlay
    readonly property color prompt:       palettes[mode].prompt
    readonly property color success_bg:   palettes[mode].success_bg
    readonly property color error_bg:     palettes[mode].error_bg
    readonly property color warning_bg:   palettes[mode].warning_bg
    readonly property color info_bg:      palettes[mode].info_bg
    readonly property color fg:           palettes[mode].fg
    readonly property color fg_secondary: palettes[mode].fg_secondary
    readonly property color fg_muted:     palettes[mode].fg_muted
    readonly property color fg_subtle:    palettes[mode].fg_subtle
    readonly property color red:          palettes[mode].red
    readonly property color orange:       palettes[mode].orange
    readonly property color yellow:       palettes[mode].yellow
    readonly property color green:        palettes[mode].green
    readonly property color cyan:         palettes[mode].cyan
    readonly property color blue:         palettes[mode].blue
    readonly property color sky:          palettes[mode].sky
    readonly property color purple:       palettes[mode].purple
    readonly property color pink:         palettes[mode].pink
    readonly property color cursor:       palettes[mode].cursor

    readonly property real hairlineAlpha: palettes[mode].hairlineAlpha
    readonly property real dimmedFgAlpha: palettes[mode].dimmedFgAlpha
    readonly property color notch:    bg
    readonly property color pill:     Qt.rgba(bg.r, bg.g, bg.b, 0.85)
    readonly property color hairline: Qt.rgba(fg.r, fg.g, fg.b, hairlineAlpha)
    readonly property color dimmedFg: Qt.rgba(fg.r, fg.g, fg.b, dimmedFgAlpha)

    readonly property int barHeight:     44
    readonly property int notchMinWidth: 1200
    readonly property int notchRadius:   14
    readonly property int notchPadH:     10
    readonly property int notchInnerGap: 80
    readonly property int modulePadH:    5
    readonly property int modulePadV:    2
    readonly property int radius:        12
    readonly property int radiusSm:      6
    readonly property int padding:       12
    readonly property int paddingSm:     6
    readonly property int spacing:       0
    readonly property int fontSize:      14

    readonly property string fontFamily:     "JetBrainsMono Nerd Font"
    readonly property string iconFontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontWeight: 500

    // FileView.text is a function; onLoaded fires on initial read and every
    // watcher-triggered reload.
    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.config/theme_mode"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = (text() || "").trim()
            if (v === "light" || v === "dark") theme.mode = v
        }
    }
}
