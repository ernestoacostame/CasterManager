pragma Singleton
import QtQuick

QtObject {
    readonly property color bgApp: "#121212"
    readonly property color bgSidebar: "#161616"
    readonly property color bgHeader: "#161616"
    readonly property color bgCard: "#1D1D1D"
    readonly property color bgCardHover: "#252525"
    readonly property color bgCardActive: "#2E2E2E"
    readonly property color bgInput: "#242424"

    readonly property color borderDim: "#2A2A2A"
    readonly property color borderBright: "#3D3D3D"

    readonly property color textPrimary: "#FFFFFF"
    readonly property color textSecondary: "#9A9A9A"
    readonly property color textMuted: "#666666"

    readonly property color rodeGold: "#CBA158"
    readonly property color rodeGoldLight: "#E5C27F"

    readonly property color padDarkBase: "#1C1C1E"
    readonly property color padDarkBorder: "#333336"

    readonly property var padColors: [
        "#FF3C3C", // 0: Red
        "#FF8C28", // 1: Orange
        "#FFDC28", // 2: Yellow
        "#8CE63C", // 3: LightGreen
        "#28C850", // 4: Green
        "#28D2AA", // 5: Mint
        "#28C8DC", // 6: Cyan
        "#3C96FF", // 7: LightBlue
        "#5050FF", // 8: Blue
        "#A050E6", // 9: Purple
        "#E650B4", // 10: Pink
        "#E63C78"  // 11: Magenta
    ]
}

