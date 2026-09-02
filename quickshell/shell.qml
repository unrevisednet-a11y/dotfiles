import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

Scope {
    id: root

    // Font Definition
    property string mainFont: "JetBrainsMono Nerd Font"

    property string sysRam: "0%"
    property string sysCpu: "0%"
    property string sysTemp: "0°C"
    property string sysVol: "0%"
    property int sysVolNum: 0
    property bool isMuted: false
    property bool sliderPressed: false
    property date currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    // Native Pipewire binding
    property var pwSink: Pipewire.defaultAudioSink
    property var pwAudio: pwSink ? pwSink.audio : null
    property real pwVolVal: pwAudio ? pwAudio.volume : -1
    property bool pwMutedVal: pwAudio ? pwAudio.muted : false

    // Required: audio.volume / audio.muted are invalid until the node
    // is bound like this. Without it, the properties above never update.
    PwObjectTracker {
        objects: [root.pwSink]
    }

    onPwVolValChanged: updateFromPw()
    onPwMutedValChanged: updateFromPw()

    function updateFromPw() {
        if (!root.sliderPressed && pwVolVal >= 0) {
            var v = Math.round(pwVolVal * 100)
            root.sysVolNum = v
            root.isMuted = pwMutedVal
            root.sysVol = pwMutedVal ? "MUTED" : (v + "%")
        }
    }

    // Hardware stats timer (2 seconds)
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            ramProc.running = true
            cpuProc.running = true
            tempProc.running = true
        }
    }

    // Fast volume keypress polling (250ms) to ensure instant updates from keyboard keys
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            if (!root.sliderPressed) {
                volProc.running = true
            }
        }
    }

    // Process: RAM Usage
    Process {
        id: ramProc
        command: ["sh", "-c", "free -m | awk '/^Mem:/ {printf \"%d%%\", $3/$2 * 100}'"]
        stdout: StdioCollector { onStreamFinished: root.sysRam = this.text.trim() }
    }

    // Process: CPU Usage
    Process {
        id: cpuProc
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1\"%\"}'"]
        stdout: StdioCollector { onStreamFinished: root.sysCpu = this.text.trim() }
    }

    // Process: CPU Temp
    Process {
        id: tempProc
        command: ["sh", "-c", "awk '{print $1/1000\"°C\"}' /sys/class/thermal/thermal_zone0/temp"]
        stdout: StdioCollector { onStreamFinished: root.sysTemp = this.text.trim() }
    }

    // Process: Volume Poll CLI Fallback
    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{if ($3 == \"[MUTED]\") print \"MUTED\"; else print int($2 * 100)}'"]
        stdout: StdioCollector { 
            onStreamFinished: {
                var raw = this.text.trim()
                if (raw === "MUTED") {
                    root.sysVol = "MUTED"
                    root.sysVolNum = 0
                    root.isMuted = true
                } else {
                    var parsed = parseInt(raw)
                    root.sysVolNum = isNaN(parsed) ? 0 : parsed
                    root.isMuted = false
                    root.sysVol = root.sysVolNum + "%"
                }
            }
        }
    }

    // Process: Set Volume from Slider Drag
    Process {
        id: setVolProc
        property string targetVol: "50%"
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", targetVol]
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            height: 44
            color: "transparent"

            // Floating Bar Container
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 8
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: 0

                color: "#60000000" // Translucent pure black
                radius: 10
                border.color: "#ff5555" // Red Border
		border.width: 1.8 

                // CENTER: Clock
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Text {
                        text: "" // Clock Nerd Font icon
                        color: "#ff5555"
                        font.family: root.mainFont
                        font.pixelSize: 15
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Qt.formatDateTime(root.currentTime, "hh:mm")
                        color: "#e0e0e0"
                        font.family: root.mainFont
                        font.pixelSize: 13
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    // RIGHT: Tray, Metrics & Volume Slider with Icons
                    Row {
                        Layout.alignment: Qt.AlignRight
                        spacing: 16

                        // System Tray
                        Row {
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            Repeater {
                                model: SystemTray.items

                                Rectangle {
                                    required property var modelData
                                    width: 22
                                    height: 22
                                    color: "transparent"
                                    radius: 4

                                    Image {
                                        anchors.centerIn: parent
                                        width: 16
                                        height: 16
                                        source: modelData.icon
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: (mouse) => {
                                            if (mouse.button === Qt.LeftButton) {
                                                modelData.activate()
                                            } else if (mouse.button === Qt.RightButton) {
                                                modelData.displayMenu()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // CPU Icon & Text
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "" // CPU Nerd Font icon
                                color: "#ff5555"
                                font.family: root.mainFont
                                font.pixelSize: 16
                            }
                            Text {
                                text: root.sysCpu
                                color: "#e0e0e0"
                                font.family: root.mainFont
                                font.pixelSize: 14
                            }
                        }

                        // Temp Icon & Text
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "" // Temp Thermometer icon
                                color: "#ff5555"
                                font.family: root.mainFont
                                font.pixelSize: 16
                            }
                            Text {
                                text: root.sysTemp
                                color: "#e0e0e0"
                                font.family: root.mainFont
                                font.pixelSize: 14
                            }
                        }

                        // RAM Icon & Text
                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                text: "󰘚" // RAM Microchip Icon
                                color: "#ff5555"
                                font.family: root.mainFont
                                font.pixelSize: 17
                            }
                            Text {
                                text: root.sysRam
                                color: "#e0e0e0"
                                font.family: root.mainFont
                                font.pixelSize: 14
                            }
                        }

                        // Volume Control with Dynamic Icon & Slider
                        Row {
                            spacing: 8
                            Layout.alignment: Qt.AlignVCenter

                            // Dynamic Volume Icon
                            Text {
                                text: {
                                    if (root.isMuted || root.sysVolNum === 0) return "󰝟"
                                    if (root.sysVolNum > 60) return "󰕾"
                                    if (root.sysVolNum > 25) return "󰖀"
                                    return "󰕿"
                                }
                                color: "#ff5555"
                                font.family: root.mainFont
                                font.pixelSize: 17
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Slider Track
                            Rectangle {
                                id: sliderTrack
                                width: 70
                                height: 6
                                radius: 3
                                color: "#30ffffff"
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: Math.max(0, Math.min(parent.width, (parent.width * root.sysVolNum) / 100))
                                    height: parent.height
                                    radius: 3
                                    color: "#ff5555"
                                }

                                MouseArea {
                                    id: volSliderArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: true

                                    function updateVolume(mouse) {
                                        var percent = Math.max(0, Math.min(100, Math.round((mouse.x / width) * 100)))
                                        root.sysVolNum = percent
                                        root.sysVol = percent + "%"
                                        root.isMuted = false
                                        setVolProc.targetVol = percent + "%"
                                        setVolProc.running = true
                                    }

                                    onPressed: (mouse) => {
                                        root.sliderPressed = true
                                        updateVolume(mouse)
                                    }
                                    onPositionChanged: (mouse) => updateVolume(mouse)
                                    onReleased: root.sliderPressed = false
                                }
                            }

                            Text {
                                text: root.sysVol
                                color: "#e0e0e0"
                                font.family: root.mainFont
                                font.pixelSize: 13
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
