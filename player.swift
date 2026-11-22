import Cocoa
import AVFoundation

class UnconstrainedWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: UnconstrainedWindow!
    var player: AVQueuePlayer!
    var looper: AVPlayerLooper!

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard CommandLine.arguments.count > 1 else { exit(1) }
        let url = URL(fileURLWithPath: CommandLine.arguments[1])

        guard let screen = NSScreen.main else { exit(1) }
        let targetFrame = screen.frame
        var startFrame = targetFrame
        startFrame.origin.y -= targetFrame.height

        window = UnconstrainedWindow(
            contentRect: startFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.ignoresMouseEvents = false
        // 上昇中は見た目を透過しつつ、クリックが後ろのアプリに抜けないよう0.01だけ判定を持たせる
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.01)
        window.hasShadow = false
        window.makeKeyAndOrderFront(nil)

        let item = AVPlayerItem(url: url)
        player = AVQueuePlayer(playerItem: item)
        looper = AVPlayerLooper(player: player, templateItem: item)

        let layer = AVPlayerLayer(player: player)
        layer.frame = window.contentView!.bounds
        layer.videoGravity = .resizeAspect
        layer.backgroundColor = NSColor.clear.cgColor

        window.contentView!.wantsLayer = true
        window.contentView!.layer!.backgroundColor = NSColor.clear.cgColor
        window.contentView!.layer!.addSublayer(layer)

        NSCursor.hide()
        NSApp.activate(ignoringOtherApps: true)
        player.play()

        // 画面下からせり上がり、上がりきった瞬間に完全な黒背景へ切り替え
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.8
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(targetFrame, display: true)
        }, completionHandler: {
            self.window.isOpaque = true
            self.window.backgroundColor = .black
            self.window.contentView?.layer?.backgroundColor = NSColor.black.cgColor
        })

        // Shift + Esc で終了
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 && event.modifierFlags.contains(.shift) {
                NSApp.terminate(nil)
            }
            return event
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
