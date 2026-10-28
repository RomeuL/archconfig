import QtQuick
import QtTest
import "../../home/.config/quickshell/arch-lock"

Item {
    width: 1280
    height: 720

    QtObject {
        id: demo
        property bool promptVisible: false
        property bool busy: false
        property bool effectsRunning: true
        property string themeName: "nord"
        property var palette: ({accent: "#81a1c1", cyan: "#88c0d0", foreground: "#d8dee9"})
        property string errorMessage: ""
        property string submitted: ""
        property color background: "#191c23"
        property color foreground: "#d8dee9"
        property color accent: "#81a1c1"
        property color secondary: "#88c0d0"
        property color alert: "#bf616a"
        property string fontFamily: "monospace"
        property int framesPerSecond: 24
        signal clearInput()
        function activity(): void { promptVisible = true; }
        function hidePrompt(): void { promptVisible = false; clearInput(); }
        function submit(value: string): void { submitted = value; }
    }

    LockView {
        id: view
        anchors.fill: parent
        controller: demo
        preview: true
    }

    TestCase {
        name: "AnimatedLockView"
        when: windowShown

        function init() {
            demo.busy = false;
            demo.submitted = "";
            demo.hidePrompt();
            view.forceActiveFocus();
        }

        function test_first_key_only_reveals_prompt() {
            keyClick(Qt.Key_A);
            compare(demo.promptVisible, true);
            compare(findChild(view, "password").text, "");
        }

        function test_password_is_masked_cleared_and_submitted() {
            demo.activity();
            const input = findChild(view, "password");
            input.forceActiveFocus();
            keyClick(Qt.Key_T);
            keyClick(Qt.Key_E);
            keyClick(Qt.Key_S);
            keyClick(Qt.Key_T);
            compare(input.echoMode, TextInput.Password);
            compare(input.passwordMaskDelay, 0);
            compare(input.text.toLowerCase(), "test");
            keyClick(Qt.Key_Return);
            compare(demo.submitted.toLowerCase(), "test");
            compare(input.text, "");
        }

        function test_escape_hides_prompt_and_clears_password() {
            demo.activity();
            const input = findChild(view, "password");
            input.text = "example";
            input.forceActiveFocus();
            keyClick(Qt.Key_Escape);
            compare(demo.promptVisible, false);
            compare(input.text, "");
        }

        function test_hidden_display_stops_animation_timer() {
            const art = findChild(view, "animation");
            demo.effectsRunning = false;
            const elapsed = art.elapsed;
            wait(150);
            compare(art.elapsed, elapsed);
            demo.effectsRunning = true;
            tryVerify(() => art.elapsed > elapsed);
        }

        function test_scenes_render_and_fit_small_screen() {
            const art = findChild(view, "animation");
            demo.effectsRunning = false;
            demo.themeName = "tron-arcade";
            art.elapsed = 10;
            art.requestPaint();
            wait(60);
            verify(grabImage(view).width > 0);
            demo.activity();
            wait(300);
            const promptImage = grabImage(view);
            promptImage.save("/tmp/arch-lock-prompt.png");
            view.anchors.fill = null;
            view.width = 640;
            view.height = 480;
            wait(60);
            const smallImage = grabImage(view);
            smallImage.save("/tmp/arch-lock-small.png");
            compare(smallImage.width, 640);
            compare(smallImage.height, 480);
            view.anchors.fill = view.parent;
            demo.effectsRunning = true;
        }
    }
}
