import QtQuick
import QtQuick.Window
import QtTest
import "../../home/.config/quickshell/arch-lock"
import "../../home/.config/quickshell/arch-lock/ThemeScenes.js" as Scenes

Item {
    id: host
    width: 1280
    height: 720

    AnimationCanvas {
        id: canvas
        anchors.fill: parent
        playing: false
        // One common palette proves that themes differ in geometry, not just color.
        themeColors: ({accent: "#00e5ff", foreground: "#e4e4e4", blue: "#81a1c1", cyan: "#88c0d0",
            green: "#a3be8c", yellow: "#ebcb8b", orange: "#d5967a", red: "#bf616a", magenta: "#b48ead"})
    }

    TestCase {
        name: "ThemeAnimations"
        when: windowShown
        property var rendered: []

        function cleanup() {
            canvas.anchors.fill = canvas.parent;
            host.Window.window.width = 1280;
            host.Window.window.height = 720;
        }

        function test_motion_and_unique_composition_data() {
            return Object.keys(Scenes.catalog).sort().map(theme => ({tag: theme, theme: theme}));
        }

        function test_motion_and_unique_composition(data) {
            canvas.themeName = data.theme;
            canvas.elapsed = 0;
            canvas.requestPaint();
            wait(70);
            const first = grabImage(canvas);
            for (let previous of rendered)
                verify(!first.equals(previous), "Dois temas desenharam a mesma composição: " + data.theme);
            rendered.push(first);
            canvas.elapsed = 3;
            canvas.requestPaint();
            wait(70);
            const moved = grabImage(canvas);
            verify(!first.equals(moved), "A cena não se moveu: " + data.theme);
            moved.save("/tmp/arch-lock-" + data.theme + ".png");
        }

        function test_unknown_theme_renders_fallback() {
            canvas.themeName = "custom-unknown-theme";
            canvas.requestPaint();
            wait(50);
            verify(grabImage(canvas).width > 0);
            compare(canvas.sceneTitle, "CONSTELAÇÕES");
        }

        function test_ultrawide_resolution_is_bounded() {
            canvas.anchors.fill = null;
            canvas.width = 5120;
            canvas.height = 2160;
            compare(canvas.rasterSize.height, 720);
            compare(canvas.rasterSize.width, 1707);
            canvas.anchors.fill = canvas.parent;
        }

        function test_large_surface_has_no_unpainted_borders_data() {
            return [
                {tag: "ultrawide-2560", width: 2560, height: 1080},
                {tag: "ultrawide-3440", width: 3440, height: 1440},
                {tag: "full-hd", width: 1920, height: 1080},
                {tag: "portrait", width: 1080, height: 1920}
            ];
        }

        function test_large_surface_has_no_unpainted_borders(data) {
            host.Window.window.width = data.width;
            host.Window.window.height = data.height;
            canvas.anchors.fill = null;
            canvas.width = data.width;
            canvas.height = data.height;
            canvas.themeName = "nord";
            canvas.elapsed = 7;
            canvas.requestPaint();
            wait(100);
            const image = grabImage(canvas);
            compare(image.width, data.width);
            compare(image.height, data.height);
            // Nord's mountain silhouettes fill the bottom across the whole screen.
            verify(image.pixel(Math.floor(data.width * .95), Math.floor(data.height * .95)).a > .1,
                "Animação não cobre a borda inferior direita");
            verify(image.pixel(Math.floor(data.width * .05), Math.floor(data.height * .95)).a > .1,
                "Animação não cobre a borda inferior esquerda");
            canvas.anchors.fill = canvas.parent;
        }
    }
}
