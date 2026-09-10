import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Self-contained view of the Omarchy plugin registry for third-party widgets.
//
// The host shell only hands third-party plugins a capability-scoped registry
// (their own plugin at most), reserving the full PluginRegistry for first-party
// code. That host-injected object is simply not reachable from this widget, so
// this client reads the same public data every external tool reads:
//   - manifests are scanned from the on-disk plugin directories exactly like
//     the host shell scans them;
//   - enabled/active/first-party state comes from the authoritative
//     `omarchy-shell shell listPlugins` IPC endpoint;
//   - the effective shell config comes from `omarchy-shell shell
//     listShellConfig`;
//   - mutating operations reuse the host IPC (`enablePlugin`,
//     `setPluginEnabled`, `setBarWidget`) so every placement/clone/disable rule
//     stays in the shell instead of being duplicated here.
QtObject {
  id: registry

  property string home: Quickshell.env("HOME")
  readonly property string omarchyPath: String(Quickshell.env("OMARCHY_PATH") || "/usr/share/omarchy")
  readonly property string pluginsDir: home + "/.config/omarchy/plugins"
  readonly property string firstPartyDir: omarchyPath + "/shell/plugins"

  // { pluginId: manifest } — full on-disk manifests (description, version,
  // author, kinds, barWidget.schema/defaults), stamped with __sourceDir and
  // __isFirstParty exactly like the host registry does.
  property var installedPlugins: ({})
  // { pluginId: { enabled, active, inBar, firstParty, kinds, canDisable, clonedFrom } }
  // Merged from the authoritative `listPlugins` IPC snapshot and the effective
  // shell config. Installed ids that the IPC reports always appear here so the
  // panel can never under-report the system inventory.
  property var pluginState: ({})
  // Effective shell.json as resolved by the host (user file over defaults).
  property var shellConfig: ({})
  property string lastEnableError: ""
  property bool ready: false
  property bool scanning: false
  property bool busy: false

  signal scanFinished()

  function shellConfigProvider() {
    return registry.shellConfig
  }

  function isEnabled(id) {
    var s = registry.pluginState[String(id || "")]
    return s ? s.enabled === true : false
  }

  function inBar(id) {
    var s = registry.pluginState[String(id || "")]
    return s ? s.inBar === true : false
  }

  // ------------------------------------------------------------- scanning

  function canonicalId(value) {
    return String(value || "")
  }

  property var rescanPending: 0

  // Output format mirrors the host rescan script:
  //   ===<kind>::<absolute-source-dir>===
  //   ... raw manifest.json content ...
  //   === EOM ===
  // (repeating for every manifest found)
  function parseScanOutput(text) {
    var lines = String(text || "").split("\n")
    var out = {}
    var currentSource = null
    var currentKind = null
    var currentJson = []

    function flush() {
      if (!currentSource) return
      var raw = currentJson.join("\n").trim()
      try {
        var manifest = JSON.parse(raw)
        var required = ["id", "name", "version", "kinds", "entryPoints"]
        var ok = true
        for (var i = 0; i < required.length; i++) {
          if (manifest[required[i]] === undefined) { ok = false; break }
        }
        if (ok && Array.isArray(manifest.kinds)) {
          manifest.__sourceDir = currentSource
          manifest.__isFirstParty = currentKind === "firstparty"
          out[String(manifest.id)] = manifest
        }
      } catch (e) {
        console.warn("RegistryClient: bad manifest at " + currentSource + ": " + e)
      }
      currentSource = null
      currentKind = null
      currentJson = []
    }

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      var startMatch = line.match(/^===([a-z]+)::(.+)===$/)
      if (startMatch) {
        flush()
        currentKind = startMatch[1]
        currentSource = startMatch[2].replace(/\/$/, "")
        currentJson = []
        continue
      }
      if (line === "=== EOM ===") {
        flush()
        continue
      }
      if (currentSource) currentJson.push(line)
    }
    flush()
    return out
  }

  function rescan() {
    if (registry.scanning) return
    registry.scanning = true
    registry.rescanPending = 3
    scanProc.running = true
    pluginStateProc.running = true
    configProc.running = true
  }

  property Process scanProc: Process {
    command: {
      var script = registry.scanScript()
      return ["bash", "-c", script, registry.firstPartyDir, registry.pluginsDir]
    }
    stdout: StdioCollector { id: scanStdout; waitForEnd: true }
    onExited: function(code) {
      registry.installedPlugins = registry.parseScanOutput(scanStdout.text || "")
      registry.stepScanFinished()
    }
  }

  function scanScript() {
    return ""
      + "emit_manifest() { local kind=\"$1\"; local manifest=\"$2\"; local sub; "
      + "  if [[ ${manifest##*/} == \"manifest.json\" ]]; then sub=\"${manifest%/manifest.json}\"; else sub=\"$(dirname -- \"$manifest\")\"; fi; "
      + "  printf '===%s::%s===\\n' \"$kind\" \"$sub\"; "
      + "  cat \"$manifest\"; "
      + "  printf '\\n=== EOM ===\\n'; "
      + "}; "
      + "scan_firstparty() { local dir=\"$1\"; "
      + "  [[ -d \"$dir\" ]] || return 0; "
      + "  while IFS= read -r manifest; do emit_manifest firstparty \"$manifest\"; done < <(find \"$dir\" -mindepth 2 -maxdepth 3 -type f \\( -name manifest.json -o -name '*.manifest.json' \\) | sort); "
      + "}; "
      + "scan_thirdparty() { local dir=\"$1\"; "
      + "  [[ -d \"$dir\" ]] || return 0; "
      + "  for sub in \"$dir\"/*/; do "
      + "    [[ -f \"$sub/manifest.json\" ]] || continue; "
      + "    emit_manifest thirdparty \"$sub/manifest.json\"; "
      + "  done; "
      + "}; "
      + "scan_firstparty \"$0\"; "
      + "scan_thirdparty \"$1\""
  }

  property Process pluginStateProc: Process {
    command: ["omarchy-shell", "shell", "listPlugins"]
    stdout: StdioCollector { id: pluginStateStdout; waitForEnd: true }
    onExited: function(code) {
      registry.parsePluginState(pluginStateStdout.text || "")
      registry.stepScanFinished()
    }
  }

  function parsePluginState(text) {
    var next = {}
    try {
      var list = JSON.parse(String(text || ""))
      if (Array.isArray(list)) {
        for (var i = 0; i < list.length; i++) {
          var p = list[i]
          if (!p || !p.id) continue
          next[String(p.id)] = {
            enabled: p.enabled === true,
            active: p.active === true,
            firstParty: p.firstParty === true,
            kinds: Array.isArray(p.kinds) ? p.kinds.slice(0, 16) : [],
            canDisable: p.canDisable === true,
            clonedFrom: String(p.clonedFrom || "")
          }
        }
      }
    } catch (e) {
      console.warn("RegistryClient: bad listPlugins output: " + e)
    }
    registry.pluginState = next
  }

  property Process configProc: Process {
    command: ["omarchy-shell", "shell", "listShellConfig"]
    stdout: StdioCollector { id: configStdout; waitForEnd: true }
    onExited: function(code) {
      registry.parseShellConfig(configStdout.text || "")
      registry.stepScanFinished()
    }
  }

  function parseShellConfig(text) {
    try {
      var config = JSON.parse(String(text || ""))
      registry.shellConfig = Util.isPlainObject(config) ? config : ({})
    } catch (e) {
      console.warn("RegistryClient: bad listShellConfig output: " + e)
      registry.shellConfig = ({})
    }
  }

  function entryInBar(config, id) {
    if (!Util.isPlainObject(config) || !Util.isPlainObject(config.bar)
        || !Util.isPlainObject(config.bar.layout)) return false
    var key = registry.canonicalId(id)
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var entries = config.bar.layout[sections[s]]
      if (!Array.isArray(entries)) continue
      for (var i = 0; i < entries.length; i++) {
        if (registry.canonicalId(entries[i] && entries[i].id) === key) return true
      }
    }
    return false
  }

  function stepScanFinished() {
    if (!registry.scanning) return
    registry.rescanPending = registry.rescanPending - 1
    if (registry.rescanPending <= 0) {
      // Process exits are unordered, so derive bar placement now that the
      // effective config and the plugin state snapshot are both in.
      var state = registry.pluginState
      for (var id in state)
        state[id].inBar = registry.entryInBar(registry.shellConfig, id)
      registry.pluginState = state
      registry.mergeInstalledState()
      registry.scanning = false
      registry.ready = true
      registry.scanFinished()
    }
  }

  // Union manifests with IPC state so every id reported by the host shows up
  // in the inventory even when no on-disk manifest is visible to us.
  function mergeInstalledState() {
    var installed = registry.installedPlugins
    var state = registry.pluginState
    for (var id in state) {
      if (installed[id]) continue
      installed[id] = {
        id: id,
        name: id,
        version: "",
        description: "",
        author: "",
        kinds: state[id].kinds || [],
        barWidget: null
      }
    }
    registry.installedPlugins = installed
  }

  // ------------------------------------------------------------ mutations

  property var pendingMutation: null

  function setEnabled(id, value, placement, callback) {
    if (registry.busy || registry.scanning) return false
    registry.busy = true
    registry.lastEnableError = ""
    registry.pendingMutation = { kind: "setEnabled", callback: callback }
    mutProc.command = value
      ? ["omarchy-shell", "shell", "enablePlugin", String(id), JSON.stringify(Util.isPlainObject(placement) ? placement : {})]
      : ["omarchy-shell", "shell", "setPluginEnabled", String(id), "false"]
    mutProc.running = true
    return true
  }

  // Mirrors the host `PluginRegistry.setBarWidget(id, key, value, selector)`.
  // callback receives the host error string ("" on success).
  function setBarWidget(id, key, value, selector, callback) {
    if (registry.busy || registry.scanning) return false
    registry.busy = true
    registry.pendingMutation = { kind: "setBarWidget", callback: callback }
    mutProc.command = [
      "omarchy-shell", "shell", "setBarWidget",
      String(id), String(key),
      JSON.stringify(value === undefined ? null : value),
      JSON.stringify(Util.isPlainObject(selector) ? selector : {})
    ]
    mutProc.running = true
    return true
  }

  property Process mutProc: Process {
    stdout: StdioCollector { id: mutStdout; waitForEnd: true }
    onExited: function(code) {
      var text = String(mutStdout.text || "").trim()
      var mutation = registry.pendingMutation
      registry.pendingMutation = null
      registry.busy = false
      if (mutation && mutation.kind === "setEnabled") {
        var ok = code === 0 && text === "ok"
        if (!ok) registry.lastEnableError = text
        if (mutation.callback) mutation.callback(ok)
      } else if (mutation && mutation.kind === "setBarWidget") {
        var err = code === 0 && text === "ok" ? "" : (text || "unknown error")
        if (mutation.callback) mutation.callback(err)
      }
      registry.rescan()
    }
  }
}