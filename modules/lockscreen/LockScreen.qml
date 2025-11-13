pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.components
import qs.modules.corners
import qs.modules.theme
import qs.modules.globals
import qs.modules.widgets.dashboard.widgets
import qs.config

PanelWindow {
    id: root

    property bool unlocking: false
    property bool authenticating: false
    property string errorMessage: ""
    property int failLockSecondsLeft: 0

    visible: GlobalStates.lockscreenVisible || unlocking
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    focusable: true
    mask: null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ambxst-lockscreen"

    // Screen capture background
    ScreencopyView {
        id: screencopyBackground
        anchors.fill: parent
        captureSource: root.screen
        live: false
        paintCursor: false
        visible: false
    }

    // Blur effect
    MultiEffect {
        id: blurEffect
        anchors.fill: parent
        source: screencopyBackground
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 0
        blurMax: 64
        visible: false
        opacity: (GlobalStates.lockscreenVisible && !unlocking) ? 1 : 0

        property real zoomScale: (GlobalStates.lockscreenVisible && !unlocking) ? 1.1 : 1.0

        transform: Scale {
            origin.x: blurEffect.width / 2
            origin.y: blurEffect.height / 2
            xScale: blurEffect.zoomScale
            yScale: blurEffect.zoomScale
        }

        Behavior on blur {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on zoomScale {
            NumberAnimation {
                duration: Config.animDuration * 1.5
                easing.type: Easing.OutCubic
            }
        }
    }

    // Overlay for dimming
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: (GlobalStates.lockscreenVisible && !unlocking) ? 0.25 : 0

        property real zoomScale: (GlobalStates.lockscreenVisible && !unlocking) ? 1.1 : 1.0

        transform: Scale {
            origin.x: parent.width / 2
            origin.y: parent.height / 2
            xScale: parent.zoomScale
            yScale: parent.zoomScale
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Config.animDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on zoomScale {
            NumberAnimation {
                duration: Config.animDuration * 1.5
                easing.type: Easing.OutCubic
            }
        }
    }

    // Music player (slides from left)
    Item {
        id: playerContainer
        anchors {
            left: parent.left
            leftMargin: 32
            bottom: parent.bottom
            bottomMargin: 32
        }
        width: 350
        height: playerContent.height

        transform: Translate {
            x: (GlobalStates.lockscreenVisible && !unlocking) ? 0 : -(playerContainer.width + 32)

            Behavior on x {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        LockPlayer {
            id: playerContent
            width: parent.width
        }
    }

    // Password input container (slides from bottom)
    Item {
        id: passwordContainer
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 32
        }
        width: 350
        height: 96

        transform: Translate {
            y: (GlobalStates.lockscreenVisible && !unlocking) ? 0 : passwordContainer.height + 32

            Behavior on y {
                NumberAnimation {
                    duration: Config.animDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Password input with avatar
        BgRect {
            id: passwordInputBox
            anchors.centerIn: parent
            width: parent.width
            height: 96
            radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0

            property real shakeOffset: 0
            property bool showError: false

            transform: Translate {
                x: passwordInputBox.shakeOffset
            }

            // Error overlay
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: Colors.error
                border.color: Colors.error
                border.width: Config.theme.borderSize
                opacity: passwordInputBox.showError ? 1 : 0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Config.animDuration / 2
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 24
                spacing: 12

                // Avatar (64x64)
                Rectangle {
                    id: avatarContainer
                    width: 64
                    height: 64
                    radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0
                    color: "transparent"
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: userAvatar
                        anchors.fill: parent
                        source: `file://${Quickshell.env("HOME")}/.face.icon`
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle {
                                    width: userAvatar.width
                                    height: userAvatar.height
                                    radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0
                                }
                            }
                        }
                    }

                    // Fallback icon if image not found
                    Text {
                        anchors.centerIn: parent
                        text: "👤"
                        font.pixelSize: 32
                        visible: userAvatar.status !== Image.Ready
                    }
                }

                // Password field
                Rectangle {
                    width: parent.width - avatarContainer.width - parent.spacing
                    height: 48
                    anchors.verticalCenter: parent.verticalCenter
                    color: passwordInputBox.showError ? Colors.errorContainer : Colors.surface
                    radius: Config.roundness > 0 ? (height / 2) * (Config.roundness / 16) : 0
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: Config.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 32
                        spacing: 8

                        // User icon / Spinner
                        Text {
                            id: userIcon
                            text: authenticating ? Icons.spinnerGap : Icons.user
                            font.family: Icons.font
                            font.pixelSize: 24
                            color: passwordInputBox.showError ? Colors.overErrorContainer : Colors.overBackground
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            Layout.alignment: Qt.AlignVCenter
                            z: 10
                            rotation: 0

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Timer {
                                id: spinnerTimer
                                interval: 100
                                repeat: true
                                running: authenticating
                                onTriggered: {
                                    userIcon.rotation = (userIcon.rotation + 45) % 360;
                                }
                            }

                            onTextChanged: {
                                if (text === Icons.user) {
                                    rotation = 0;
                                }
                            }
                        }

                        // Text field
                        TextField {
                            id: passwordInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            placeholderText: usernameCollector.text.trim()
                            placeholderTextColor: passwordInputBox.showError ? Qt.rgba(Colors.overErrorContainer.r, Colors.overErrorContainer.g, Colors.overErrorContainer.b, 0.5) : Colors.outline
                            font.family: Config.theme.font
                            font.pixelSize: Config.theme.fontSize
                            color: passwordInputBox.showError ? Colors.overErrorContainer : Colors.overBackground
                            background: null
                            echoMode: TextInput.Password
                            verticalAlignment: TextInput.AlignVCenter
                            enabled: !authenticating

                            Behavior on color {
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on placeholderTextColor {
                                ColorAnimation {
                                    duration: Config.animDuration
                                    easing.type: Easing.OutCubic
                                }
                            }

                            onAccepted: {
                                if (passwordInput.text.trim() === "") return;
                                
                                // Guardar contraseña y limpiar campo inmediatamente
                                authPasswordHolder.password = passwordInput.text;
                                passwordInput.text = "";
                                
                                authenticating = true;
                                errorMessage = "";
                                pamAuth.running = true;
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    unlocking = true;
                                    unlockResetTimer.start();
                                    GlobalStates.lockscreenVisible = false;
                                    passwordInput.text = "";
                                    errorMessage = "";
                                    event.accepted = true;
                                }
                            }

                            Component.onCompleted: {
                                if (GlobalStates.lockscreenVisible) {
                                    passwordInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }

            SequentialAnimation {
                id: wrongPasswordAnim
                ScriptAction {
                    script: {
                        passwordInputBox.showError = true;
                    }
                }
                NumberAnimation {
                    target: passwordInputBox
                    property: "shakeOffset"
                    to: 10
                    duration: 50
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: passwordInputBox
                    property: "shakeOffset"
                    to: -10
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: passwordInputBox
                    property: "shakeOffset"
                    to: 10
                    duration: 100
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: passwordInputBox
                    property: "shakeOffset"
                    to: 0
                    duration: 50
                    easing.type: Easing.InOutQuad
                }
                ScriptAction {
                    script: {
                        passwordInput.text = "";
                        authenticating = false;
                        passwordInputBox.showError = false;
                    }
                }
            }
        }


    }

    // Timer to animate blur after capture
    Timer {
        id: blurAnimTimer
        interval: 50
        onTriggered: {
            blurEffect.blur = 1;
        }
    }

    // Timer to reset unlocking state after animation starts
    Timer {
        id: unlockResetTimer
        interval: Config.animDuration
        onTriggered: {
            unlocking = false;
        }
    }

    // Focus the input when lockscreen becomes visible
    onVisibleChanged: {
        if (visible && GlobalStates.lockscreenVisible) {
            blurEffect.blur = 0;
            screencopyBackground.captureFrame();
            blurEffect.visible = true;
            blurAnimTimer.start();
            passwordInput.forceActiveFocus();
        } else if (!visible) {
            blurAnimTimer.stop();
            unlockResetTimer.stop();
            failLockCountdown.stop();
            blurEffect.visible = false;
            blurEffect.blur = 0;
            errorMessage = "";
            failLockSecondsLeft = 0;
        }
    }

    // Processes for user info
    Process {
        id: usernameProc
        command: ["whoami"]
        running: true

        stdout: StdioCollector {
            id: usernameCollector
            waitForEnd: true
        }
    }

    Process {
        id: hostnameProc
        command: ["hostname"]
        running: true

        stdout: StdioCollector {
            id: hostnameCollector
            waitForEnd: true
        }
    }

    // Holder temporal para la contraseña durante autenticación
    QtObject {
        id: authPasswordHolder
        property string password: ""
    }

    // Proceso para verificar tiempo de faillock
    Process {
        id: failLockCheck
        command: ["bash", "-c", `faillock --user '${usernameCollector.text.trim()}' 2>/dev/null | grep -oP 'left \\K[0-9]+' | head -1`]
        running: false

        stdout: StdioCollector {
            id: failLockCollector
            
            onStreamFinished: {
                const output = text.trim();
                const seconds = parseInt(output);
                
                if (!isNaN(seconds) && seconds > 0) {
                    failLockSecondsLeft = seconds;
                    failLockCountdown.start();
                } else {
                    failLockSecondsLeft = 0;
                }
            }
        }
    }

    // Timer para actualizar el countdown de faillock
    Timer {
        id: failLockCountdown
        interval: 1000
        repeat: true
        running: false

        onTriggered: {
            if (failLockSecondsLeft > 0) {
                failLockSecondsLeft--;
            } else {
                stop();
                errorMessage = "";
            }
        }
    }

    // PAM authentication process
    Process {
        id: pamAuth
        command: ["modules/lockscreen/pam-auth-stdin.sh"]
        running: false
        environment: {
            "PAM_USER": usernameCollector.text.trim(),
            "PAM_PASSWORD": authPasswordHolder.password
        }

        onExited: exitCode => {
            // Limpiar contraseña
            authPasswordHolder.password = "";

            if (exitCode === 0) {
                // Autenticación exitosa
                unlocking = true;
                unlockResetTimer.start();
                GlobalStates.lockscreenVisible = false;
                errorMessage = "";
                authenticating = false;
            } else {
                // Error de autenticación
                let msg = "";
                switch (exitCode) {
                    case 10:
                        msg = "Usuario no encontrado";
                        break;
                    case 11:
                        msg = "Contraseña incorrecta";
                        break;
                    case 12:
                        msg = "Error de autenticación";
                        break;
                    case 20:
                        msg = "Cuenta expirada";
                        break;
                    case 21:
                        msg = "Debe cambiar su contraseña";
                        break;
                    case 22:
                        msg = "Cuenta bloqueada";
                        break;
                    case 23:
                        msg = "Error de estado de cuenta";
                        break;
                    case 30:
                        // Faillock detectado - verificar tiempo restante
                        failLockCheck.running = true;
                        msg = "Cuenta bloqueada por intentos fallidos";
                        break;
                    case 100:
                        msg = "Error: parámetro inválido";
                        break;
                    case 101:
                        msg = "Error leyendo contraseña";
                        break;
                    case 102:
                        msg = "Error inicializando PAM";
                        break;
                    case 103:
                        msg = "Timeout esperando contraseña";
                        break;
                    case 104:
                        msg = "Error interno";
                        break;
                    default:
                        msg = `Error desconocido (${exitCode})`;
                }
                
                errorMessage = msg;
                console.warn("PAM auth failed:", exitCode, msg);
                wrongPasswordAnim.start();
            }
        }
    }

    // Screen corners
    RoundCorner {
        id: topLeft
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        anchors.left: parent.left
        anchors.top: parent.top
        corner: RoundCorner.CornerEnum.TopLeft
    }

    RoundCorner {
        id: topRight
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        anchors.right: parent.right
        anchors.top: parent.top
        corner: RoundCorner.CornerEnum.TopRight
    }

    RoundCorner {
        id: bottomLeft
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        corner: RoundCorner.CornerEnum.BottomLeft
    }

    RoundCorner {
        id: bottomRight
        size: Config.roundness > 0 ? Config.roundness + 4 : 0
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        corner: RoundCorner.CornerEnum.BottomRight
    }

    // Capture all keyboard input
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            unlocking = true;
            unlockResetTimer.start();
            GlobalStates.lockscreenVisible = false;
            passwordInput.text = "";
            event.accepted = true;
        }
    }
}
