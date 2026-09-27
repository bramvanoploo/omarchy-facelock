import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "FacelockModel.js" as Model

Panel {
  id: root
  moduleName: "bramvanoploo.omarchy-facelock"
  ipcTarget: "bramvanoploo.omarchy-facelock"
  manageIpc: false

  property var status: Model.emptyStatus()
  property bool confirmOpen: false
  property string confirmMessage: ""
  property string confirmButtonText: "Confirm"
  property var confirmAction: null
  property bool toolsOverlayOpen: false
  property bool lockPamPromptShownThisOpen: false

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "")
  readonly property string helper: pluginDir + "/scripts/facelock-helper"

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function checkLockExplorerPam() {
    if (lockPamPromptShownThisOpen) return
    if (root.status.lockExplorerInstalled && !root.status.lockFacePamExists && !root.confirmOpen && !root.toolsOverlayOpen) {
      lockPamPromptShownThisOpen = true
      root.askConfirmation(
        "The \"Lock Screen Explorer\" plugin is installed, but /etc/pam.d/omarchy-lock-face does not exist.\n\nThis PAM file is needed to support face unlock from the lockscreen with the \"Lock Screen Explorer\" plugin.\n\nWould you like to create it now?",
        "Create",
        function() {
          root.runAction("install-lock-face-pam")
        }
      )
    }
  }

  function applyStatus(raw) {
    status = Model.parseStatus(raw)
    if (opened) {
      checkLockExplorerPam()
    }
  }

  function refresh() {
    if (statusProc.running) return
    statusProc.command = ["bash", helper, "status"]
    statusProc.running = true
  }

  function runAction(action, arg) {
    var cmd = ["bash", helper, action]
    if (arg !== undefined && arg !== "") cmd.push(arg)
    actionProc.command = cmd
    actionProc.running = true
    if (action !== "hyprlock-toggle" && action !== "require-ir-toggle") {
      toolsOverlayOpen = false
      root.close()
    }
  }

  function askConfirmation(msg, btnText, action) {
    confirmMessage = msg
    confirmButtonText = btnText
    confirmAction = action
    confirmOpen = true
  }

  function handleConfirmed() {
    confirmOpen = false
    if (confirmAction) {
      var act = confirmAction
      confirmAction = null
      act()
    }
  }

  function handleCanceled() {
    confirmOpen = false
    confirmAction = null
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: {
    if (opened) {
      lockPamPromptShownThisOpen = false
      refresh()
      checkLockExplorerPam()
    } else {
      toolsOverlayOpen = false
      handleCanceled()
    }
  }

  Component.onCompleted: refresh()

  Process {
    id: statusProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatus(text)
    }
  }

  Process {
    id: actionProc
    onExited: {
      // Re-query status shortly after an action exits
      refreshTimer.restart()
    }
  }

  Timer {
    id: refreshTimer
    interval: 800
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    interval: root.opened ? 3000 : 12000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.barIcon(root.status)
    tooltipText: Model.tooltip(root.status)
    onPressed: function(mouse) {
      root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(Math.max(column.implicitHeight, Style.space(380)))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: {
        if (root.confirmOpen) root.handleCanceled()
        else if (root.toolsOverlayOpen) root.toolsOverlayOpen = false
        else root.close()
      }
      Keys.onPressed: function(event) {
        if (root.confirmOpen) {
          if (confirmDialog.handleKey(event)) {
            event.accepted = true
          }
        } else if (root.toolsOverlayOpen && event.key === Qt.Key_Escape) {
          root.toolsOverlayOpen = false
          event.accepted = true
        }
      }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // Hero Card
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.height, heroLabels.implicitHeight, settingsButton.height)

          Item {
            id: heroIcon
            width: Style.font.display
            height: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            OpticalGlyph {
              anchors.fill: parent
              text: Model.barIcon(root.status)
              fontFamily: root.fontFamily
              fontSize: Style.font.display
              color: button.foreground
            }
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: settingsButton.visible ? settingsButton.left : parent.right
            anchors.rightMargin: settingsButton.visible ? Style.space(8) : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Row {
              width: parent.width
              spacing: Style.space(8)

              Text {
                text: "Omarchy Facelock"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }
            }

            Text {
              text: root.status.installed
                ? (root.status.enrolled
                    ? (root.status.modelCount + " face model(s) enrolled")
                    : "No face enrolled · Setup needed")
                : "Biometric authentication not installed"
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }
          }

          PanelActionButton {
            id: settingsButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.status.installed
            iconText: "󰒓"
            tooltipText: "Integration & tools"
            foreground: root.foreground
            fontFamily: root.fontFamily
            fontSize: Style.font.subtitle
            size: Style.space(28)
            onClicked: root.toolsOverlayOpen = true
          }
        }

        PanelSeparator { foreground: root.foreground }

        // STEP 1: Not Installed
        Column {
          width: parent.width
          spacing: Style.space(8)
          visible: !root.status.installed

          Text {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "Facelock is an open-source face authentication system for Linux. Click below to install it."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }

          Button {
            width: parent.width
            text: "Install Facelock"
            iconText: "󰇚"
            tooltipText: "Install facelock-bin"
            bordered: true
            accent: root.accent
            onClicked: root.runAction("install")
          }
        }

        // STEP 2 & FULL CLI CONTROLS: Installed
        Column {
          width: parent.width
          spacing: Style.space(12)
          visible: root.status.installed

          // Step 2 Button: Setup Wizard
          Button {
            width: parent.width
            text: "Run Setup Wizard"
            iconText: "󰒃"
            bordered: true
            accent: root.accent
            onClicked: root.runAction("setup")
          }

          PanelSectionHeader {
            text: "FACE AUTHENTICATION"
            fontFamily: root.fontFamily
            foreground: root.foreground
          }

          Row {
            width: parent.width
            spacing: Style.space(8)
            readonly property real cellWidth: (width - spacing) / 2

            Button {
              width: root.status.enrolled ? parent.cellWidth : parent.width
              text: "Enroll Face"
              iconText: "󰱻"
              tooltipText: "Capture and enroll face"
              bordered: true
              onClicked: root.runAction("enroll")
            }

            Button {
              visible: root.status.enrolled
              width: parent.cellWidth
              text: "Test Recognition"
              iconText: "󰄬"
              tooltipText: "Test camera face match"
              bordered: true
              onClicked: root.runAction("test")
            }
          }

          Row {
            visible: root.status.enrolled
            width: parent.width
            spacing: Style.space(8)
            readonly property real cellWidth: (width - spacing) / 2

            Button {
              width: parent.cellWidth
              text: "List Models"
              iconText: "󰒲"
              tooltipText: "View enrolled face models"
              bordered: true
              onClicked: root.runAction("models")
            }

            Button {
              width: parent.cellWidth
              text: "Clear Models"
              iconText: "󰆴"
              tooltipText: "Delete all enrolled faces"
              bordered: true
              onClicked: root.askConfirmation("Are you sure you want to clear all enrolled face models?", "Clear", function() { root.runAction("clear") })
            }
          }

          PanelSectionHeader {
            text: "CAMERA & PREVIEW"
            fontFamily: root.fontFamily
            foreground: root.foreground
          }

          Row {
            width: parent.width
            spacing: Style.space(8)
            readonly property real cellWidth: (width - spacing) / 2

            Button {
              width: parent.cellWidth
              text: "Live Preview"
              iconText: "󰄀"
              tooltipText: "Open live camera feed"
              bordered: true
              onClicked: root.runAction("preview")
            }

            Button {
              width: parent.cellWidth
              text: "List Cameras"
              iconText: "󰄀"
              tooltipText: "Show available video devices"
              bordered: true
              onClicked: root.runAction("devices")
            }
          }
        }
      }

        // Tools & Integration Modal Overlay
        Item {
          id: toolsOverlay
          anchors.fill: parent
          visible: root.toolsOverlayOpen
          z: 60

          Rectangle {
            anchors.fill: parent
            color: Util.alpha(Color.background, 0.75)

            MouseArea {
              anchors.fill: parent
              onClicked: root.toolsOverlayOpen = false
            }

            BorderSurface {
              id: toolsCard
              width: Math.min(parent.width - Style.space(24), Style.space(360))
              implicitHeight: toolsContent.implicitHeight + toolsCard.contentTopInset + toolsCard.contentBottomInset
              height: implicitHeight
              anchors.centerIn: parent
              color: Color.popups.background
              borderSpec: Border.flat(root.accent, Style.normalBorderWidth)
              padding: Style.space(16)
              radius: Style.cornerRadius

              MouseArea {
                anchors.fill: parent
                onClicked: {}
              }

              Column {
                id: toolsContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: toolsCard.contentTopInset
                anchors.leftMargin: toolsCard.contentLeftInset
                anchors.rightMargin: toolsCard.contentRightInset
                spacing: Style.space(12)

                // Header with Title and Close Button
                Item {
                  width: parent.width
                  implicitHeight: Math.max(toolsHeaderTitle.implicitHeight, closeButton.height)

                  Text {
                    id: toolsHeaderTitle
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "INTEGRATION & TOOLS"
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                    font.letterSpacing: 1.0
                  }

                  PanelActionButton {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    iconText: "󰅖"
                    tooltipText: "Close tools"
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    fontSize: Style.font.caption
                    size: Style.space(22)
                    onClicked: root.toolsOverlayOpen = false
                  }
                }

                PanelSeparator {
                  width: parent.width
                  foreground: root.foreground
                }

                Row {
                  width: parent.width
                  spacing: Style.space(8)
                  readonly property real cellWidth: (width - spacing) / 2

                  Button {
                    width: parent.cellWidth
                    text: root.status.hyprlockIntegrated ? "Disable Hyprlock" : "Enable Hyprlock"
                    iconText: "󰌾"
                    tooltipText: root.status.hyprlockIntegrated ? "Disable lock screen auth" : "Enable lock screen auth"
                    bordered: true
                    selected: root.status.hyprlockIntegrated
                    onClicked: {
                      if (root.status.hyprlockIntegrated) {
                        root.askConfirmation("Are you sure you want to disable Facelock for Hyprlock?", "Disable", function() { root.runAction("hyprlock-toggle") })
                      } else {
                        root.askConfirmation("Are you sure you want to enable Facelock for Hyprlock?", "Enable", function() { root.runAction("hyprlock-toggle") })
                      }
                    }
                  }

                  Button {
                    width: parent.cellWidth
                    text: "Restart Daemon"
                    iconText: "󰜉"
                    tooltipText: "Restart background daemon service"
                    bordered: true
                    onClicked: root.runAction("daemon-restart")
                  }
                }

                Row {
                  width: parent.width
                  spacing: Style.space(6)
                  readonly property real cellWidth: (width - spacing * 2) / 3

                  Button {
                    width: parent.cellWidth
                    text: "Status"
                    iconText: "󰋼"
                    tooltipText: "Check overall system status"
                    bordered: true
                    onClicked: root.runAction("run", "status")
                  }

                  Button {
                    width: parent.cellWidth
                    text: "TPM"
                    iconText: "󰌋"
                    tooltipText: "View TPM security status"
                    bordered: true
                    onClicked: root.runAction("run", "tpm")
                  }

                  Button {
                    width: parent.cellWidth
                    text: "Benchmark"
                    iconText: "󱑎"
                    tooltipText: "Run performance calibration benchmarks"
                    bordered: true
                    onClicked: root.runAction("run", "bench")
                  }
                }

                Button {
                  width: parent.width
                  text: "Require IR camera"
                  iconText: root.status.requireIr ? "󰄲" : "󰄱"
                  tooltipText: "Uncheck this option if you don't have an infrared camera but still want to face-unlock. This won't work well in darker environments!"
                  bordered: true
                  selected: root.status.requireIr
                  onClicked: {
                    root.status.requireIr = !root.status.requireIr
                    root.runAction("require-ir-toggle")
                  }
                }

                Button {
                  width: parent.width
                  text: root.status.lockFacePamExists ? "Reinstall omarchy-lock-face PAM" : "Install omarchy-lock-face PAM"
                  iconText: "󰌾"
                  tooltipText: "Install /etc/pam.d/omarchy-lock-face for Lock Screen Explorer"
                  bordered: true
                  onClicked: {
                    if (root.status.lockFacePamExists) {
                      root.askConfirmation(
                        "The PAM file /etc/pam.d/omarchy-lock-face is already present.\n\nDo you want to overwrite it with the recommended configuration?",
                        "Overwrite",
                        function() { root.runAction("install-lock-face-pam") }
                      )
                    } else {
                      root.askConfirmation(
                        "Install /etc/pam.d/omarchy-lock-face to enable face unlock with the \"Lock Screen Explorer\" plugin?",
                        "Install",
                        function() { root.runAction("install-lock-face-pam") }
                      )
                    }
                  }
                }

                Button {
                  visible: false
                  width: parent.width
                  text: "Edit Configuration"
                  iconText: "󰏫"
                  tooltipText: "Edit config.toml with sudo"
                  bordered: true
                  onClicked: root.runAction("edit-config")
                }

                PanelSeparator {
                  width: parent.width
                  foreground: root.foreground
                }

                Button {
                  width: parent.width
                  text: "Uninstall Facelock"
                  iconText: "󰆴"
                  tooltipText: "Uninstall Facelock"
                  bordered: true
                  accent: Color.urgent
                  onClicked: {
                    root.askConfirmation("Are you sure you want to uninstall Facelock?", "Uninstall", function() { root.runAction("uninstall") })
                  }
                }
              }
            }
          }
        }

      ConfirmDialog {
        id: confirmDialog
        anchors.fill: parent
        opened: root.confirmOpen
        z: 100
        message: root.confirmMessage
        confirmText: root.confirmButtonText
        cancelText: "Cancel"
        background: Color.popups.background
        foreground: root.foreground
        selectedText: root.accent
        fontFamily: root.fontFamily
        cornerRadius: Style.cornerRadius
        onCanceled: root.handleCanceled()
        onConfirmed: root.handleConfirmed()
      }
    }
  }
}
