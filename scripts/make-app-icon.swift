import AppKit
import SwiftUI

// 用法：swift scripts/make-app-icon.swift Tic/Resources/AppIcon-1024-opaque.png Tic/Assets.xcassets/AppIcon.appiconset 1.04
// macOS 不会给 App 图标自动裁圆角，源图为不透明方图时需用本脚本生成带透明四角的各尺寸 PNG。
// 按 Apple macOS 图标模板：1024 画布，824×824 连续圆角矩形（半径 185.4），四周透明 + 轻微投影。
let args = CommandLine.arguments
let src = NSImage(contentsOfFile: args[1])!
let outDir = URL(fileURLWithPath: args[2])
let bleed = args.count > 3 ? CGFloat(Double(args[3])!) : 1.0

let canvas: CGFloat = 1024
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let path = RoundedRectangle(cornerRadius: 185.4, style: .continuous).path(in: tile).cgPath

func render(size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    cg.interpolationQuality = .high
    let s = CGFloat(size) / canvas
    cg.scaleBy(x: s, y: s)

    // 投影（模板：向下偏移、柔和）
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: NSColor.black.withAlphaComponent(0.30).cgColor)
    cg.addPath(path); cg.setFillColor(NSColor.white.cgColor); cg.fillPath()
    cg.restoreGState()

    // 内容裁切到圆角矩形
    cg.saveGState()
    cg.addPath(path); cg.clip()
    let drawRect = tile.insetBy(dx: -tile.width * (bleed - 1) / 2, dy: -tile.height * (bleed - 1) / 2)
    src.draw(in: drawRect, from: .zero, operation: .copy, fraction: 1)
    cg.restoreGState()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let specs: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, size) in specs {
    try! render(size: size).write(to: outDir.appendingPathComponent(name))
}
print("ok")
