pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower

ShellRoot {
    id: root

    property bool promptVisible: false
    property bool paused: false
    property bool unlockedByPam: false
    readonly property string errorMessage: auth.errorMessage
    readonly property bool busy: auth.busy
    readonly property bool effectsRunning: !paused
    readonly property var preferences: readJson(settingsFile.text())
    readonly property var themeData: readJson(paletteFile.text())
    readonly property string themeName: themeData.theme || "nord"
    readonly property var palette: themeData.colors || ({})
    readonly property color background: palette.darker_background || "#191c23"
    readonly property color foreground: palette.foreground || "#d8dee9"
    readonly property color accent: palette.accent || "#81a1c1"
    readonly property color secondary: palette.cyan || "#88c0d0"
    readonly property color alert: palette.alert || palette.red || "#bf616a"
    readonly property string fontFamily: {
        const match = styleFile.text().match(/^\$font\s*=\s*(.+)$/m);
        return match ? match[1].trim() : "monospace";
    }
    readonly property int framesPerSecond: bounded(UPower.onBattery ? preferences.batteryFramesPerSecond : preferences.framesPerSecond, UPower.onBattery ? 12 : 24, 1, 30)

    signal clearInput()

    function readJson(text: string): var {
        try { return JSON.parse(text) || ({}); }
        catch (error) { return ({}); }
    }

    function bounded(value: var, fallback: int, low: int, high: int): int {
        return typeof value === "number" && isFinite(value)
            ? Math.max(low, Math.min(high, Math.round(value))) : fallback;
    }

    function activity(): void {
        paused = false;
        promptVisible = true;
        promptTimer.restart();
    }

    function hidePrompt(): void {
        if (busy)
            return;
        auth.clear();
        promptVisible = false;
    }

    function submit(password: string): void {
        auth.submit(password);
    }

    FileView {
        id: settingsFile
        path: Qt.resolvedUrl("settings.json")
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: paletteFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/theme/current/palette.json"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }
    FileView {
        id: styleFile
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/theme/current/hyprlock.conf"
        blockLoading: true
        printErrors: false
    }

    Timer {
        // Also follows theme-set's atomic replacement of the current/ directory.
        interval: 2000
        repeat: true
        running: root.effectsRunning
        onTriggered: { paletteFile.reload(); styleFile.reload(); }
    }

    AuthController {
        id: auth
        pam: pamTransport
        secure: sessionLock.secure
        onClearInput: root.clearInput()
        onAuthenticated: {
            root.unlockedByPam = true;
            sessionLock.locked = false;
            exitTimer.start();
        }
    }

    PamContext {
        id: pamTransport
        // Use exactly the same system PAM policy as the existing Hyprlock.
        config: "hyprlock"
        onPamMessage: auth.respondToPrompt(responseRequired, responseVisible)
        onCompleted: result => {
            if (!auth.complete(result === PamResult.Success, result === PamResult.Error))
                root.activity();
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: true

        WlSessionLockSurface {
            color: root.background
            LockView {
                anchors.fill: parent
                controller: root
            }
        }
    }

    Timer {
        id: promptTimer
        interval: root.bounded(root.preferences.promptSeconds, 20, 5, 120) * 1000
        onTriggered: {
            if (root.busy)
                restart();
            else
                root.hidePrompt();
        }
    }

    Timer {
        interval: 5000
        running: true
        // Do not silently remain open without acquiring the compositor lock.
        onTriggered: {
            if (!sessionLock.secure && !root.unlockedByPam)
                Qt.exit(1);
        }
    }

    Timer {
        id: exitTimer
        interval: 200
        // 42 is reserved for an authenticated unlock; every other exit falls back to Hyprlock.
        onTriggered: { if (root.unlockedByPam) Qt.exit(42); }
    }

    IpcHandler {
        target: "locker"
        function status(): string { return sessionLock.secure ? "locked" : "starting"; }
        function theme(): string { return root.themeName; }
        function pause(): void { root.paused = true; root.hidePrompt(); }
        function resume(): void { root.paused = false; }
        // Deliberately no unlock or quit IPC command.
    }

    Component.onCompleted: Quickshell.watchFiles = false
}
