import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "monorkin.voyager-disco"
  ipcTarget: "monorkin.voyager-disco"
  manageIpc: false

  property real hue: 200
  property real satPercent: 100
  property real valPercent: 100

  property string appliedMode: ""
  property int keyboardBrightness: 100
  property bool _restored: false
  property bool _dirty: false
  property int subtitleIndex: 0

  readonly property color currentColor: Qt.hsva(hue / 360, satPercent / 100, valPercent / 100, 1)
  readonly property string currentHex: hexOf(currentColor)

  readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/voyager-disco/widget.json"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property color ballColor: {
    if (appliedMode === "color") {
      return currentColor
    } else if (appliedMode === "theme") {
      return Color.accent
    } else {
      return Qt.darker(barForeground, 1.55)
    }
  }

  readonly property bool hasKeyboard: disco.devices.length > 0

  readonly property var attachedPhrases: [
    "Picking colors",
    "Stimulating optic nerve",
    "Lighting LEDs",
    "Spinning disco ball",
    "Theming keyboard",
    "Collecting moon dust",
    "Mixing pigments",
    "Choosing brushes",
    "Diluting colors",
    "Making happy little clouds"
  ]

  readonly property var detachedPhrases: [
    "Looking...",
    "Searching...",
    "Fetching...",
    "Digging...",
    "Inspecting...",
    "Scanning...",
    "Listening..."
  ]

  readonly property var activePhrases: {
    if (hasKeyboard) {
      return attachedPhrases
    } else {
      return detachedPhrases
    }
  }

  readonly property string statusText: {
    if (disco.installed) {
      return activePhrases[subtitleIndex % activePhrases.length]
    } else {
      return "voyager-disco CLI not installed"
    }
  }

  readonly property var swatches: [
    String(Color.accent),
    "#ffffff", "#8e8e93", "#a2845e", "#ff3b30", "#d70015",
    "#ff9500", "#ffb340", "#ffe135", "#34d158", "#00c7be",
    "#00e5d0", "#30b0c7", "#32ade6", "#0a84ff", "#5e5ce6",
    "#bf5af2", "#e040fb", "#ff2d92", "#ff6482"
  ]

  function applyColor() {
    disco.setColor(currentHex)
    appliedMode = "color"
    persist()
  }

  function queueApply() {
    applyTimer.restart()
  }

  function applySwatch(hex) {
    var h = String(hex)
    if (h.charAt(0) !== "#") h = "#" + h
    setFromColor(h)
    applyColor()
  }

  function matchTheme() {
    disco.matchTheme()
    setFromColor(Color.accent)
    appliedMode = "theme"
    persist()
  }

  function resetLighting() {
    disco.reset()
    appliedMode = ""
    persist()
  }

  function applyBrightness(percent) {
    keyboardBrightness = Math.round(Math.max(0, Math.min(100, percent)))
    disco.setBrightness(keyboardBrightness)
    persist()
  }

  function persist() {
    _dirty = true
    if (!persistTimer.running) {
      flushPersist()
      persistTimer.start()
    }
  }

  function flushPersist() {
    if (!_dirty) return

    _dirty = false
    var payload = JSON.stringify({
      lastColor: currentHex,
      lastMode: appliedMode,
      lastBrightness: keyboardBrightness
    })
    Quickshell.execDetached(["bash", "-c",
      "mkdir -p \"$(dirname \"$0\")\" && printf '%s\\n' \"$1\" > \"$0\"",
      statePath, payload])
  }

  function restoreFromState(raw) {
    if (_restored) return

    _restored = true
    var state = {}
    try {
      state = JSON.parse(String(raw || "{}"))
    } catch (error) {
      return
    }
    var saved = String(state.lastColor || "")
    if (saved.match(/^[0-9a-fA-F]{6}$/)) setFromColor("#" + saved)
    appliedMode = String(state.lastMode || "")
    var b = parseInt(String(state.lastBrightness), 10)
    if (isFinite(b)) keyboardBrightness = Math.max(0, Math.min(100, b))
  }

  function setFromColor(c) {
    var col = Qt.color(c)
    if (col.hsvHue < 0) {
      hue = 0
    } else {
      hue = col.hsvHue * 360
    }
    satPercent = col.hsvSaturation * 100
    valPercent = col.hsvValue * 100
  }

  function hexOf(c) {
    function pad(v) {
      var s = Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16)
      if (s.length === 1) {
        return "0" + s
      } else {
        return s
      }
    }
    return pad(c.r) + pad(c.g) + pad(c.b)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: disco.refresh()
  Component.onDestruction: flushPersist()
  onOpenedChanged: {
    if (opened) {
      disco.refresh()
      Qt.callLater(function() { keyCatcher.forceActiveFocus() })
    } else {
      flushPersist()
    }
  }

  Service {
    id: disco
    settings: root.settings
  }

  Timer {
    id: applyTimer
    interval: 140
    repeat: false
    onTriggered: root.applyColor()
  }

  Timer {
    id: persistTimer
    interval: 100
    repeat: false
    onTriggered: {
      if (root._dirty) {
        root.flushPersist()
        persistTimer.start()
      }
    }
  }

  FileView {
    path: root.statePath
    watchChanges: false
    printErrors: false
    onLoaded: root.restoreFromState(text())
  }

  Timer {
    id: phraseTimer
    interval: 2800
    repeat: true
    running: root.opened && disco.installed
    onTriggered: phraseSwap.restart()
  }

  SequentialAnimation {
    id: phraseSwap
    PropertyAnimation {
      target: hero; property: "metaOpacity"
      to: 0.0; duration: 180; easing.type: Easing.OutQuad
    }
    ScriptAction {
      script: root.subtitleIndex = (root.subtitleIndex + 1) % root.activePhrases.length
    }
    PropertyAnimation {
      target: hero; property: "metaOpacity"
      to: 1.0; duration: 260; easing.type: Easing.InQuad
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function setColor(hex: string): string { root.applySwatch(hex.replace("#", "")); return "ok" }
    function matchTheme(): string { root.matchTheme(); return "ok" }
    function reset(): string { root.resetLighting(); return "ok" }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Component {
      Item {
        Icon {
          anchors.centerIn: parent
          iconSize: Style.space(13)
          ballColor: root.ballColor
          planeColor: root.barForeground
        }
      }
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) root.matchTheme()
      else if (buttonCode === Qt.MiddleButton) root.resetLighting()
      else root.toggle()
    }
    onWheelMoved: function(delta) {
      if (delta > 0) {
        root.applyBrightness(root.keyboardBrightness + 5)
      } else {
        root.applyBrightness(root.keyboardBrightness - 5)
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(560))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "t" || t === "T") root.matchTheme()
        else if (t === "x" || t === "X") root.resetLighting()
        else if (t === "r" || t === "R") disco.refresh()
      }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          id: hero
          width: parent.width
          title: "Voyager Disco"
          meta: root.statusText
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Icon {
              iconSize: Style.font.display
              ballColor: {
                if (root.appliedMode !== "") {
                  return root.currentColor
                } else {
                  return root.dim
                }
              }
              planeColor: root.foreground
            }
          }
        }

        Text {
          visible: !disco.installed
          width: parent.width
          text: "Install it with: yay -S voyager-disco"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Column {
          visible: disco.installed && !root.hasKeyboard
          width: parent.width
          spacing: Style.space(6)
          topPadding: Style.space(20)
          bottomPadding: Style.space(20)

          Text {
            width: parent.width
            text: "󰌐"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.display
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            width: parent.width
            text: "No keyboard attached"
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            horizontalAlignment: Text.AlignHCenter
          }
        }

        Rectangle {
          visible: root.hasKeyboard
          width: parent.width
          height: Style.space(44)
          radius: Style.cornerRadius
          color: root.currentColor

          Text {
            anchors.centerIn: parent
            text: "#" + root.currentHex
            color: {
              if (root.valPercent > 60 && root.satPercent < 70) {
                return "#000000"
              } else {
                return "#ffffff"
              }
            }
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
        }

        SliderRow {
          label: "Hue"
          value: root.hue
          maximum: 360
          fill: Qt.hsva(root.hue / 360, 1, 1, 1)
          onChanged: function(v) { root.hue = v; root.queueApply() }
          onDone: function(v) { root.hue = v; root.applyColor() }
        }

        SliderRow {
          label: "Saturation"
          value: root.satPercent
          maximum: 100
          onChanged: function(v) { root.satPercent = v; root.queueApply() }
          onDone: function(v) { root.satPercent = v; root.applyColor() }
        }

        SliderRow {
          label: "Value"
          value: root.valPercent
          maximum: 100
          onChanged: function(v) { root.valPercent = v; root.queueApply() }
          onDone: function(v) { root.valPercent = v; root.applyColor() }
        }

        Flow {
          visible: root.hasKeyboard
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: root.swatches
            Rectangle {
              required property var modelData
              width: Style.space(24)
              height: Style.space(24)
              radius: Style.cornerRadius
              color: modelData
              border.width: 1
              border.color: Qt.alpha(root.foreground, 0.35)

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.applySwatch(parent.modelData)
              }
            }
          }
        }

        PanelSeparator {
          visible: root.hasKeyboard
          foreground: root.foreground
        }

        SliderRow {
          label: "Brightness"
          value: root.keyboardBrightness
          maximum: 100
          onChanged: function(v) {}
          onDone: function(v) { root.applyBrightness(v) }
        }

        RowLayout {
          visible: root.hasKeyboard
          width: parent.width
          spacing: Style.space(8)

          Button {
            Layout.fillWidth: true
            text: "Match theme"
            iconText: "󰏘"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.matchTheme()
          }

          Button {
            Layout.fillWidth: true
            text: "Reset to Oryx"
            iconText: "󰜉"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.resetLighting()
          }
        }

        PanelSeparator {
          visible: disco.devices.length > 0
          foreground: root.foreground
        }

        Column {
          visible: disco.devices.length > 0
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "KEYBOARDS"
            foreground: root.foreground
            fontFamily: root.fontFamily
          }

          Repeater {
            model: disco.devices
            RowLayout {
              required property var modelData
              width: parent.width
              spacing: Style.space(8)

              Text {
                text: "󰌌"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.icon
              }

              Text {
                Layout.fillWidth: true
                text: modelData.product
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
                elide: Text.ElideRight
              }

              Text {
                text: modelData.serial
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }
          }
        }
      }
    }
  }

  component SliderRow: Column {
    property string label: ""
    property real value: 0
    property real maximum: 100
    property color fill: root.foreground
    signal changed(real value)
    signal done(real value)

    visible: root.hasKeyboard
    width: parent.width
    spacing: Style.space(2)

    Text {
      text: label
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    PanelSlider {
      width: parent.width
      bar: root.bar
      minimum: 0
      maximum: parent.maximum
      value: parent.value
      step: {
        if (parent.maximum > 100) {
          return 6
        } else {
          return 2
        }
      }
      integer: true
      fillColor: parent.fill
      knobColor: parent.fill
      onMoved: function(v) { parent.changed(v) }
      onReleased: function(v) { parent.done(v) }
    }
  }
}
