import QtQuick

FocusScope {
    id: view
    required property var controller
    property bool preview: false
    property date now: new Date()
    readonly property real margin: Math.max(24, Math.min(width, height) * 0.055)

    focus: true

    Rectangle {
        anchors.fill: parent
        color: view.controller.background
    }

    AnimationCanvas {
        id: art
        objectName: "animation"
        anchors.fill: parent
        themeName: view.controller.themeName
        themeColors: view.controller.palette
        playing: view.controller.effectsRunning
        framesPerSecond: view.controller.framesPerSecond
        opacity: view.controller.promptVisible ? 0.25 : 1
        Behavior on opacity { NumberAnimation { duration: 220 } }
    }

    Column {
        x: view.margin
        y: view.margin
        spacing: 4

        Text {
            text: Qt.formatDateTime(view.now, "hh:mm")
            color: view.controller.foreground
            font.family: view.controller.fontFamily
            font.pixelSize: Math.max(36, Math.min(72, view.height * 0.085))
            font.weight: Font.Light
        }
        Text {
            text: Qt.locale("pt_BR").toString(view.now, "dddd, d 'de' MMMM")
            color: view.controller.accent
            font.family: view.controller.fontFamily
            font.pixelSize: Math.max(12, Math.min(16, view.width / 70))
        }
    }

    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: view.margin
        text: view.preview ? "PRÉVIA · NÃO BLOQUEIA" : "SESSÃO BLOQUEADA"
        color: view.controller.accent
        font.family: view.controller.fontFamily
        font.pixelSize: 12
        font.letterSpacing: 2
    }

    Rectangle {
        id: prompt
        anchors.centerIn: parent
        width: Math.min(420, view.width - 2 * view.margin)
        height: content.implicitHeight + 56
        color: view.controller.background
        border.color: view.controller.accent
        border.width: 1
        radius: 4
        visible: view.controller.promptVisible

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 28
            spacing: 18

            Text {
                text: "Bem-vindo de volta"
                color: view.controller.foreground
                font.family: view.controller.fontFamily
                font.pixelSize: 21
            }

            Rectangle {
                width: parent.width
                height: 48
                color: Qt.rgba(view.controller.accent.r, view.controller.accent.g, view.controller.accent.b, 0.08)
                border.color: password.activeFocus ? view.controller.accent : view.controller.secondary
                radius: 2

                TextInput {
                    id: password
                    objectName: "password"
                    anchors.fill: parent
                    anchors.margins: 13
                    color: view.controller.foreground
                    selectionColor: view.controller.accent
                    font.family: view.controller.fontFamily
                    font.pixelSize: 17
                    echoMode: TextInput.Password
                    passwordMaskDelay: 0
                    clip: true
                    enabled: !view.controller.busy
                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhHiddenText
                    onAccepted: view.submit()
                    onTextEdited: view.controller.activity()
                    Keys.onEscapePressed: {
                        clear();
                        view.controller.hidePrompt();
                    }
                }
                Text {
                    anchors.fill: password
                    visible: password.text.length === 0 && !view.controller.busy
                    text: "Senha"
                    color: view.controller.secondary
                    font: password.font
                }
            }

            Text {
                width: parent.width
                height: Math.max(implicitHeight, 18)
                text: view.controller.busy ? "Verificando…" : view.controller.errorMessage
                color: view.controller.errorMessage ? view.controller.alert : view.controller.secondary
                font.family: view.controller.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width
                height: 42
                color: view.controller.accent
                radius: 2
                opacity: view.controller.busy ? 0.5 : 1
                Text {
                    anchors.centerIn: parent
                    text: "Desbloquear  →"
                    color: view.controller.background
                    font.family: view.controller.fontFamily
                    font.pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !view.controller.busy
                    onClicked: view.submit()
                }
            }
        }

        onVisibleChanged: {
            password.clear();
            if (visible)
                password.forceActiveFocus();
            else
                view.forceActiveFocus();
        }
    }

    Column {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: view.margin
        spacing: 8
        Text {
            text: art.themeTitle + "    /    " + art.sceneTitle
            color: view.controller.accent
            font.family: view.controller.fontFamily
            font.pixelSize: 11
            font.letterSpacing: 1.5
            width: view.width - 2 * view.margin
            wrapMode: Text.WordWrap
        }
        Text {
            text: "Mova o mouse ou pressione uma tecla para entrar"
            visible: !view.controller.promptVisible
            color: view.controller.foreground
            opacity: 0.65
            font.family: view.controller.fontFamily
            font.pixelSize: 12
            width: view.width - 2 * view.margin
            wrapMode: Text.WordWrap
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !view.controller.promptVisible
        hoverEnabled: true
        property real previousX: -1
        property real previousY: -1
        onClicked: view.controller.activity()
        onPositionChanged: mouse => {
            if (previousX >= 0 && Math.abs(mouse.x - previousX) + Math.abs(mouse.y - previousY) > 8)
                view.controller.activity();
            previousX = mouse.x;
            previousY = mouse.y;
        }
        onEnabledChanged: { previousX = -1; previousY = -1; }
    }

    // Consume the first key: it reveals the prompt without becoming part of the password.
    Keys.onPressed: event => {
        if (!view.controller.promptVisible) {
            view.controller.activity();
            event.accepted = true;
        }
    }

    function submit(): void {
        const value = password.text;
        password.clear();
        view.controller.submit(value);
    }

    Connections {
        target: view.controller
        function onClearInput(): void { password.clear(); }
        function onBusyChanged(): void {
            if (!view.controller.busy && view.controller.promptVisible)
                password.forceActiveFocus();
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: view.controller.effectsRunning
        onTriggered: view.now = new Date()
    }
}
