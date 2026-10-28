import QtQuick
import "ThemeScenes.js" as Scenes

Item {
    id: canvas
    property string themeName: "nord"
    property var themeColors: ({})
    property bool playing: true
    property int framesPerSecond: 24
    property real elapsed: 0
    readonly property string sceneTitle: Scenes.info(themeName).scene
    readonly property string themeTitle: Scenes.info(themeName).title

    // Keep a small drawing item, then scale that item to cover the output.
    // Canvas.canvasSize/canvasWindow describe virtual tiles, not an output-sized
    // backing store. Using them as a resolution cap can crop accelerated textures.
    readonly property real resolutionScale: Math.max(1, height / 720)
    readonly property size rasterSize: Qt.size(Math.max(1, Math.ceil(width / resolutionScale)), Math.max(1, Math.ceil(height / resolutionScale)))
    clip: true

    function requestPaint(): void {
        if (drawing)
            drawing.requestPaint();
    }

    Canvas {
        id: drawing
        width: canvas.rasterSize.width
        height: canvas.rasterSize.height
        scale: canvas.resolutionScale
        transformOrigin: Item.TopLeft
        smooth: false
        onPaint: Scenes.paint(getContext("2d"), width, height, canvas.elapsed, canvas.themeName, canvas.themeColors)
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Timer {
        interval: Math.round(1000 / Math.max(1, canvas.framesPerSecond))
        repeat: true
        running: canvas.playing && canvas.visible
        triggeredOnStart: true
        onTriggered: {
            canvas.elapsed += interval / 1000;
            canvas.requestPaint();
        }
    }
    onThemeNameChanged: { elapsed = 0; requestPaint(); }
    onThemeColorsChanged: requestPaint()
    onRasterSizeChanged: requestPaint()
}
