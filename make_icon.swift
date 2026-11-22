import Cocoa

func createIcon(symbolName: String, r: CGFloat, g: CGFloat, b: CGFloat, outPng: String) {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()

    // macOS風の角丸背景
    let rect = NSRect(x: 64, y: 64, width: 896, height: 896)
    let path = NSBezierPath(roundedRect: rect, xRadius: 200, yRadius: 200)
    NSColor(red: r, green: g, blue: b, alpha: 1.0).setFill()
    path.fill()

    // SF Symbolsで中央マークを描画
    let config = NSImage.SymbolConfiguration(pointSize: 420, weight: .bold)
    if let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let tinted = NSImage(size: symbol.size)
        tinted.lockFocus()
        NSColor.white.set()
        let symRect = NSRect(origin: .zero, size: symbol.size)
        symbol.draw(in: symRect)
        symRect.fill(using: .sourceAtop)
        tinted.unlockFocus()

        let drawRect = NSRect(
            x: (1024 - symbol.size.width) / 2,
            y: (1024 - symbol.size.height) / 2,
            width: symbol.size.width,
            height: symbol.size.height
        )
        tinted.draw(in: drawRect)
    }

    image.unlockFocus()

    if let tiff = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let png = bitmap.representation(using: .png, properties: [:]) {
        try? png.write(to: URL(fileURLWithPath: outPng))
    }
}

// 監視用：ダーク背景 ＋ 目のアイコン（eye.slash.fill などに変更可）
createIcon(symbolName: "eye.trianglebadge.exclamationmark.fill", r: 0.14, g: 0.15, b: 0.18, outPng: "watcher.png")

// 停止用：レッド背景 ＋ 電源/停止アイコン
createIcon(symbolName: "stop.circle.fill", r: 0.85, g: 0.22, b: 0.22, outPng: "stop.png")

// アンインストール用：オレンジ背景 ＋ ゴミ箱アイコン
createIcon(symbolName: "trash.circle.fill", r: 0.90, g: 0.45, b: 0.15, outPng: "uninstall.png")

// 設定用：ブルー背景 ＋ 歯車アイコン
createIcon(symbolName: "gearshape.fill", r: 0.20, g: 0.45, b: 0.85, outPng: "config.png")
