import AppKit
import SwiftUI

// 用法：swift scripts/make-app-icon.swift <源 1024 PNG> <输出目录> [源图圆角半径 px，默认 204]
//   swift scripts/make-app-icon.swift Tic/Resources/AppIcon-1024-opaque.png Tic/Assets.xcassets/AppIcon.appiconset
//
// macOS 不会给 App 图标自动裁圆角。源图是「圆角瓷砖铺满画布 + 四角白底」的不透明方图，
// 本脚本把整张图按 Apple 模板缩进 1024 画布中央 824×824 区域（不放大、不裁内容），
// 蒙版贴合源图自身的圆角（实测为普通圆角 r≈204px），仅去掉四角白底，保留外圈光影边，
// 再加一层轻微投影。
let args = CommandLine.arguments
let src = NSImage(contentsOfFile: args[1])!
let outDir = URL(fileURLWithPath: args[2])
let sourceCornerRadius = args.count > 3 ? CGFloat(Double(args[3])!) : 204
/// 蒙版向内收的源图像素，去掉圆角外缘与白底混合的毛边。
let sourceInset: CGFloat = 1

let canvas: CGFloat = 1024
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let scale = tile.width / canvas
let maskRect = tile.insetBy(dx: sourceInset * scale, dy: sourceInset * scale)
let path = MainActor.assumeIsolated {
    RoundedRectangle(cornerRadius: (sourceCornerRadius - sourceInset) * scale, style: .circular)
        .path(in: maskRect).cgPath
}

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

    // 投影（向下偏移、柔和）
    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -10), blur: 28, color: NSColor.black.withAlphaComponent(0.30).cgColor)
    cg.addPath(path); cg.setFillColor(NSColor.white.cgColor); cg.fillPath()
    cg.restoreGState()

    // 整张源图缩放进模板区域，按源图自身圆角裁掉四角白底
    cg.saveGState()
    cg.addPath(path); cg.clip()
    src.draw(in: tile, from: .zero, operation: .copy, fraction: 1)
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
