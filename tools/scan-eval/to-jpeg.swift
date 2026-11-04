import AppKit
let src = CommandLine.arguments[1], dst = CommandLine.arguments[2]
struct C: Codable { let id: String; let file: String }
var manifest = try! JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: "\(src)/manifest.json"))) as! [[String: Any]]
var total = 0
for i in manifest.indices {
    let id = manifest[i]["id"] as! String, file = manifest[i]["file"] as! String
    guard let rep = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: "\(src)/\(file)"))), let cg = rep.cgImage else { continue }
    let scale = min(1, 1600 / CGFloat(max(cg.width, cg.height)))
    let w = Int(CGFloat(cg.width) * scale), h = Int(CGFloat(cg.height) * scale)
    let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    ctx.interpolationQuality = .high
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
    let out = NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .jpeg, properties: [.compressionFactor: 0.85])!
    let name = "scaneval_\(id).jpg"
    try! out.write(to: URL(fileURLWithPath: "\(dst)/\(name)"))
    manifest[i]["file"] = name
    total += out.count
}
try! JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted]).write(to: URL(fileURLWithPath: "\(dst)/scaneval_manifest.json"))
print("imágenes: \(manifest.count), total \(total / 1024) KB")
