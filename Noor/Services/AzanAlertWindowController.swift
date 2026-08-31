import AppKit
import SwiftUI

/// Shows a dimmed full-screen overlay with the azan card centered on top,
/// above every Space/full-screen app.
@MainActor
final class AzanAlertWindowController: NSObject {
    static let shared = AzanAlertWindowController()

    private var panel: NSPanel?

    func show(prayerName: String) {
        let content = AzanAlertOverlayView(
            prayerName: prayerName,
            onStop: { [weak self] in
                AzanService.shared.stop()
                self?.close()
            }
        )
        let hosting = NSHostingController(rootView: content)

        // Cover the whole screen so the SwiftUI overlay can center the card
        // itself — avoids NSWindow.center() picking the wrong display.
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        let panel = NSPanel(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = hosting
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.level = .floating
        panel.setFrame(screenFrame, display: true)

        AzanService.shared.onFinishPlaying = { [weak self] in
            self?.close()
        }

        self.panel = panel
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.close()
        panel = nil
    }
}
