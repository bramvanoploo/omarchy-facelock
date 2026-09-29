.pragma library

function emptyStatus() {
  return {
    installed: false,
    version: "",
    package: "",
    configured: false,
    enrolled: false,
    modelCount: 0,
    lastUpdated: null,
    daemonRunning: false,
    hyprlockIntegrated: false,
    requireIr: true,
    hasIrCamera: false,
    lockExplorerInstalled: false,
    lockExplorerEnabled: false,
    lockFacePamExists: false,
    lockExplorerDismissed: false
  }
}

function parseStatus(raw) {
  var base = emptyStatus()
  if (!raw || typeof raw !== "string") return base

  try {
    var parsed = JSON.parse(raw.trim())
    if (typeof parsed !== "object" || parsed === null) return base

    base.installed = Boolean(parsed.installed)
    base.version = String(parsed.version || "")
    base.package = String(parsed.package || "")
    base.configured = Boolean(parsed.configured)
    base.enrolled = Boolean(parsed.enrolled)
    var count = parseInt(parsed.modelCount, 10)
    base.modelCount = (!isNaN(count) && count >= 0) ? count : 0
    base.lastUpdated = parsed.lastUpdated || null
    base.daemonRunning = Boolean(parsed.daemonRunning)
    base.hyprlockIntegrated = Boolean(parsed.hyprlockIntegrated)
    base.requireIr = parsed.requireIr !== undefined ? Boolean(parsed.requireIr) : true
    base.hasIrCamera = parsed.hasIrCamera !== undefined ? Boolean(parsed.hasIrCamera) : false
    base.lockExplorerInstalled = Boolean(parsed.lockExplorerInstalled)
    base.lockExplorerEnabled = Boolean(parsed.lockExplorerEnabled)
    base.lockFacePamExists = Boolean(parsed.lockFacePamExists)
    base.lockExplorerDismissed = Boolean(parsed.lockExplorerDismissed)
    return base
  } catch (e) {
    return base
  }
}

function parseList(raw) {
  if (!raw || typeof raw !== "string") return []
  try {
    var parsed = JSON.parse(raw.trim())
    if (Array.isArray(parsed)) return parsed
    return []
  } catch (e) {
    return []
  }
}

function barIcon(status) {
  // Uses Material Design / Nerd Font face recognition / unlock glyph (󰱻 \uf0c7b) matching Lock Screen Explorer
  return "󰱻"
}

function badgeText(status) {
  if (!status || !status.installed) return "NOT INSTALLED"
  if (!status.configured) return "SETUP NEEDED"
  if (!status.enrolled) return "NOT ENROLLED"
  return "ENROLLED (" + status.modelCount + ")"
}

function tooltip(status) {
  if (!status || !status.installed) return "Facelock · Not installed (click to install)"
  if (!status.configured) return "Facelock · Setup needed"
  if (!status.enrolled) return "Facelock · No face enrolled"
  return "Facelock · Enrolled (" + status.modelCount + (status.modelCount === 1 ? " model)" : " models)")
}

function formatDate(ts) {
  if (!ts) return "Unknown"
  try {
    var d
    if (typeof ts === "number") {
      d = new Date(ts > 1e11 ? ts : ts * 1000)
    } else {
      d = new Date(ts)
    }
    if (isNaN(d.getTime())) return String(ts)
    return d.toLocaleDateString() + " " + d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
  } catch (e) {
    return String(ts)
  }
}
