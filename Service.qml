import QtQuick
import Quickshell
import Quickshell.Io

// Thin wrapper around the voyager-disco CLI. Device discovery goes through
// `voyager-disco list`; LED changes are fire-and-forget since the CLI exits
// immediately and the color lives in keyboard RAM.
Item {
  id: root

  property var settings: ({})

  property bool installed: true
  property bool refreshing: false
  // [{ serial, product, path }]
  property var devices: []

  property string _listOutput: ""

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function deviceArgs() {
    var serials = String(setting("device", "")).trim()
    return serials === "" ? [] : ["-d", serials]
  }

  function run(args) {
    Quickshell.execDetached(["voyager-disco"].concat(args).concat(deviceArgs()))
  }

  function setColor(hex) {
    run(["set-color", String(hex).replace("#", "")])
  }

  function setBrightness(percent) {
    run(["brightness", "set", String(Math.round(percent))])
  }

  function reset() {
    run(["reset"])
  }

  function matchTheme() {
    // match-theme reads the accent from the current Omarchy theme itself and
    // takes no device filter of its own beyond what the CLI applies.
    Quickshell.execDetached(["voyager-disco", "omarchy", "match-theme"])
  }

  function refresh() {
    if (listProcess.running) return
    _listOutput = ""
    refreshing = true
    listProcess.running = true
  }

  function applyList(raw) {
    var text = String(raw || "")
    if (text.indexOf("__NOT_INSTALLED__") !== -1) {
      installed = false
      devices = []
      return
    }
    installed = true
    var found = []
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (line === "") continue
      // `voyager-disco list` prints: <serial>  <product>  <hid path>
      var parts = line.split(/\s{2,}/)
      found.push({
        serial: parts[0] || "unknown",
        product: parts[1] || "ZSA Keyboard",
        path: parts[2] || ""
      })
    }
    devices = found
  }

  Process {
    id: listProcess
    running: false
    command: ["bash", "-lc",
      "command -v voyager-disco >/dev/null 2>&1 || { echo __NOT_INSTALLED__; exit 0; }; voyager-disco list 2>/dev/null || true"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root._listOutput = text }
    onExited: {
      root.refreshing = false
      root.applyList(root._listOutput)
    }
  }
}
