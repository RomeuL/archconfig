import QtQuick
import QtQuick.Window

Window {
    id: window
    visible: true
    width: 1280
    height: 720
    title: "Prévia do bloqueio animado — não bloqueia a sessão"

    function argument(name: string, fallback: string): string {
        const index = Qt.application.arguments.indexOf(name);
        return index >= 0 ? Qt.application.arguments[index + 1] || fallback : fallback;
    }
    readonly property var themeData: {
        try { return JSON.parse(argument("--palette", "{}")); }
        catch (error) { return ({}); }
    }
    readonly property var colors: themeData.colors || ({})

    QtObject {
        id: demo
        property bool promptVisible: false
        property bool busy: false
        property bool effectsRunning: true
        property string themeName: window.argument("--theme", window.themeData.theme || "nord")
        property var palette: window.colors
        property string errorMessage: ""
        property color background: window.colors.darker_background || window.colors.dark_background || window.colors.background || "#191c23"
        property color foreground: window.colors.foreground || "#d8dee9"
        property color accent: window.colors.accent || "#81a1c1"
        property color secondary: window.colors.cyan || "#88c0d0"
        property color alert: window.colors.alert || window.colors.red || "#bf616a"
        property string fontFamily: window.themeData.font || window.argument("--font", "JetBrainsMono Nerd Font")
        property int framesPerSecond: 24
        signal clearInput()
        function activity(): void { promptVisible = true; }
        function hidePrompt(): void { promptVisible = false; clearInput(); }
        function submit(password: string): void {
            clearInput();
            errorMessage = "Esta é uma prévia. Nenhuma senha é verificada.";
        }
    }

    LockView {
        anchors.fill: parent
        controller: demo
        preview: true
    }
}
