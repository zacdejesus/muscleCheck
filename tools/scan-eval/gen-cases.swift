import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

let outDir = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let ci = CIContext()

// MARK: - Ground truth

struct Expected: Codable {
    let name: String
    let sets: Int?
    let reps: Int?
    var setsAny = false
    var repsAny = false
    let muscles: [String]          // acceptable muscles; empty = not scored (cardio, full body)
    var excluded = false           // crossed out on the sheet: should NOT be loaded
}
struct CaseInfo: Codable {
    let id: String
    let category: String
    let description: String
    let file: String
    var expectNothing = false
    var notation = "setsFirst"
    let expected: [Expected]
}
var manifest: [CaseInfo] = []

func e(_ name: String, _ sets: Int?, _ reps: Int?, _ muscles: [String], setsAny: Bool = false, repsAny: Bool = false, excluded: Bool = false) -> Expected {
    Expected(name: name, sets: sets, reps: reps, setsAny: setsAny, repsAny: repsAny, muscles: muscles, excluded: excluded)
}

// MARK: - Drawing helpers

struct RNG {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double((state >> 33) & 0xFFFFFF) / Double(0xFFFFFF)
    }
    mutating func range(_ a: Double, _ b: Double) -> CGFloat { CGFloat(a + (b - a) * next()) }
}

func family(_ name: String, _ size: CGFloat, bold: Bool = false) -> NSFont {
    NSFontManager.shared.font(withFamily: name, traits: bold ? .boldFontMask : [], weight: bold ? 9 : 5, size: size) ?? .systemFont(ofSize: size)
}
func sys(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont { .systemFont(ofSize: size, weight: weight) }
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: a) }

func canvas(_ w: CGFloat, _ h: CGFloat, _ draw: (CGContext) -> Void) -> CGImage {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w), pixelsHigh: Int(h), bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let g = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = g
    draw(g.cgContext)
    NSGraphicsContext.restoreGraphicsState()
    return rep.cgImage!
}

/// Text with its TOP at `top` (canvas height `H`), optionally rotated/struck through.
func text(_ ctx: CGContext, _ s: String, _ font: NSFont, _ color: NSColor, x: CGFloat, top: CGFloat, H: CGFloat,
          angle: CGFloat = 0, strike: Bool = false) {
    var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    if strike { attrs[.strikethroughStyle] = NSUnderlineStyle.thick.rawValue; attrs[.strikethroughColor] = color }
    let str = NSAttributedString(string: s, attributes: attrs)
    ctx.saveGState()
    ctx.translateBy(x: x, y: H - top - font.pointSize * 1.25)
    ctx.rotate(by: angle * .pi / 180)
    str.draw(at: .zero)
    ctx.restoreGState()
}

func fill(_ ctx: CGContext, _ c: NSColor, _ r: CGRect) { ctx.setFillColor(c.cgColor); ctx.fill(r) }
func round(_ ctx: CGContext, _ c: NSColor, _ r: CGRect, _ radius: CGFloat) {
    ctx.setFillColor(c.cgColor); ctx.addPath(CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)); ctx.fillPath()
}

func handwritten(_ lines: [String], font name: String, size: CGFloat, seed: UInt64, lined: Bool = true,
                 struck: Set<Int> = [], w: CGFloat = 1500, h: CGFloat = 2000,
                 ink: NSColor = rgb(0.10, 0.14, 0.42)) -> CGImage {
    var rng = RNG(state: seed)
    return canvas(w, h) { ctx in
        fill(ctx, rgb(0.99, 0.97, 0.92), CGRect(x: 0, y: 0, width: w, height: h))
        if lined {
            ctx.setStrokeColor(rgb(0.55, 0.72, 0.90, 0.55).cgColor); ctx.setLineWidth(2)
            var y: CGFloat = 110
            while y < h { ctx.move(to: CGPoint(x: 0, y: y)); ctx.addLine(to: CGPoint(x: w, y: y)); y += size * 1.55 }
            ctx.strokePath()
            ctx.setStrokeColor(rgb(0.90, 0.40, 0.40, 0.55).cgColor)
            ctx.move(to: CGPoint(x: 140, y: 0)); ctx.addLine(to: CGPoint(x: 140, y: h)); ctx.strokePath()
        }
        let font = family(name, size)
        var top: CGFloat = 150
        for (i, line) in lines.enumerated() {
            if line.isEmpty { top += size * 0.9; continue }
            text(ctx, line, font, ink, x: 175 + rng.range(-12, 28), top: top + rng.range(-8, 8), H: h,
                 angle: rng.range(-2.4, 2.4), strike: struck.contains(i))
            top += size * 1.55
        }
    }
}

struct Photo { var rotation = 0.0; var perspective = 0.0; var blur = 0.0; var noise = 0.03; var exposure = 0.0; var shadow = 0.0 }

func photograph(_ page: CGImage, _ p: Photo, seed: UInt64) -> CGImage {
    var rng = RNG(state: seed)
    var img = CIImage(cgImage: page)
    let w = img.extent.width, h = img.extent.height
    if p.perspective > 0 {
        let d = CGFloat(p.perspective) * w
        let f = CIFilter.perspectiveTransform()
        f.inputImage = img
        f.topLeft = CGPoint(x: d * rng.range(0.4, 1.0), y: h - d * 0.15)
        f.topRight = CGPoint(x: w - d * rng.range(0.2, 0.8), y: h)
        f.bottomLeft = CGPoint(x: 0, y: d * 0.25)
        f.bottomRight = CGPoint(x: w, y: 0)
        img = f.outputImage!
    }
    if p.rotation != 0 { img = img.transformed(by: CGAffineTransform(rotationAngle: CGFloat(p.rotation * .pi / 180))) }
    let bg = img.extent.insetBy(dx: -110, dy: -110)
    img = img.composited(over: CIImage(color: CIColor(red: 0.33, green: 0.26, blue: 0.20)).cropped(to: bg)).cropped(to: bg)
    if p.exposure != 0 { let f = CIFilter.exposureAdjust(); f.inputImage = img; f.ev = Float(p.exposure); img = f.outputImage!.cropped(to: bg) }
    if p.shadow > 0 {
        let g = CIFilter.linearGradient()
        g.point0 = CGPoint(x: bg.minX, y: bg.maxY); g.point1 = CGPoint(x: bg.maxX, y: bg.minY)
        g.color0 = CIColor(red: 0, green: 0, blue: 0, alpha: CGFloat(p.shadow)); g.color1 = CIColor(red: 0, green: 0, blue: 0, alpha: 0)
        img = g.outputImage!.cropped(to: bg).composited(over: img)
    }
    if p.blur > 0 { img = img.clampedToExtent().applyingGaussianBlur(sigma: p.blur).cropped(to: bg) }
    if p.noise > 0 {
        let m = CIFilter.colorMatrix(); m.inputImage = CIFilter.randomGenerator().outputImage!.cropped(to: bg)
        let a = CGFloat(p.noise)
        m.rVector = CIVector(x: a, y: 0, z: 0, w: 0); m.gVector = CIVector(x: 0, y: a, z: 0, w: 0)
        m.bVector = CIVector(x: 0, y: 0, z: a, w: 0); m.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        m.biasVector = CIVector(x: -a / 2, y: -a / 2, z: -a / 2, w: 0)
        let add = CIFilter.additionCompositing(); add.inputImage = m.outputImage!; add.backgroundImage = img
        img = add.outputImage!.cropped(to: bg)
    }
    return ci.createCGImage(img, from: bg)!
}

func rotated90(_ cg: CGImage) -> CGImage {
    let img = CIImage(cgImage: cg).oriented(.right)
    return ci.createCGImage(img, from: img.extent)!
}

func pdf(_ name: String, _ draw: (CGContext, CGFloat) -> Void) -> CGImage {
    let W: CGFloat = 595, H: CGFloat = 842
    let url = URL(fileURLWithPath: "\(outDir)/\(name).pdf")
    var box = CGRect(x: 0, y: 0, width: W, height: H)
    let ctx = CGContext(url as CFURL, mediaBox: &box, nil)!
    ctx.beginPDFPage(nil)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    fill(ctx, .white, box)
    draw(ctx, H)
    NSGraphicsContext.restoreGraphicsState()
    ctx.endPDFPage(); ctx.closePDF()
    let page = CGPDFDocument(url as CFURL)!.page(at: 1)!
    let scale: CGFloat = 2.5
    return canvas(W * scale, H * scale) { c in
        fill(c, .white, CGRect(x: 0, y: 0, width: W * scale, height: H * scale))
        c.scaleBy(x: scale, y: scale); c.drawPDFPage(page)
    }
}

func table(_ ctx: CGContext, H: CGFloat, x: CGFloat, top: CGFloat, cols: [CGFloat], rows: [[String]],
           size: CGFloat = 11, rowH: CGFloat = 24, header: NSColor = rgb(0.15, 0.35, 0.55), grid: NSColor = rgb(0.75, 0.78, 0.82)) {
    let width = cols.reduce(0, +)
    for (r, row) in rows.enumerated() {
        let y = H - top - rowH * CGFloat(r + 1)
        if r == 0 { fill(ctx, header, CGRect(x: x, y: y, width: width, height: rowH)) }
        else if r % 2 == 0 { fill(ctx, rgb(0.95, 0.96, 0.98), CGRect(x: x, y: y, width: width, height: rowH)) }
        var cx = x
        for (c, cell) in row.enumerated() {
            text(ctx, cell, r == 0 ? sys(size, .semibold) : sys(size), r == 0 ? .white : .black,
                 x: cx + 6, top: top + rowH * CGFloat(r) + (rowH - size * 1.25) / 2, H: H)
            cx += cols[c]
        }
    }
    ctx.setStrokeColor(grid.cgColor); ctx.setLineWidth(0.6)
    for r in 0...rows.count { let y = H - top - rowH * CGFloat(r); ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x + width, y: y)) }
    var cx = x
    for c in 0...cols.count {
        ctx.move(to: CGPoint(x: cx, y: H - top)); ctx.addLine(to: CGPoint(x: cx, y: H - top - rowH * CGFloat(rows.count)))
        if c < cols.count { cx += cols[c] }
    }
    ctx.strokePath()
}

let PW: CGFloat = 1179, PH: CGFloat = 2556
func phone(dark: Bool, bg: NSColor? = nil, _ draw: (CGContext) -> Void) -> CGImage {
    canvas(PW, PH) { ctx in
        fill(ctx, bg ?? (dark ? .black : .white), CGRect(x: 0, y: 0, width: PW, height: PH))
        let fg: NSColor = dark ? .white : .black
        text(ctx, "9:41", sys(52, .semibold), fg, x: 150, top: 55, H: PH)
        round(ctx, fg, CGRect(x: PW - 230, y: PH - 120, width: 100, height: 46), 12)
        text(ctx, "5G", sys(44, .semibold), fg, x: PW - 380, top: 60, H: PH)
        draw(ctx)
    }
}

func save(_ cg: CGImage, _ name: String, jpeg: Bool) -> String {
    let rep = NSBitmapImageRep(cgImage: cg)
    let data = jpeg ? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.72])!
                    : rep.representation(using: .png, properties: [:])!
    let file = name + (jpeg ? ".jpg" : ".png")
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(file)"))
    return file
}

func add(_ id: String, _ category: String, _ desc: String, _ image: CGImage, jpeg: Bool, _ expected: [Expected],
         nothing: Bool = false, notation: String = "setsFirst") {
    let file = save(image, id, jpeg: jpeg)
    manifest.append(CaseInfo(id: id, category: category, description: desc, file: file, expectNothing: nothing, notation: notation, expected: expected))
}

// MARK: - Handwritten

let h01Lines = ["Día 1 - Piernas", "", "Sentadilla 4x8", "Prensa 4x10-12", "Estocadas 3x12", "Gemelos de pie 4x15", "Hip thrust 4x10"]
let h01Exp = [e("Sentadilla", 4, 8, ["legs", "glutes"]), e("Prensa", 4, 10, ["legs"]), e("Estocadas", 3, 12, ["legs", "glutes"]),
              e("Gemelos de pie", 4, 15, ["calves"]), e("Hip thrust", 4, 10, ["glutes", "legs"])]
let h01Page = handwritten(h01Lines, font: "Bradley Hand", size: 72, seed: 1)
add("H01", "handwritten", "Cuaderno rayado, letra prolija, encabezado de día, foto buena", photograph(h01Page, Photo(rotation: 2, perspective: 0.03, blur: 0.6, shadow: 0.15), seed: 11), jpeg: true, h01Exp)

add("H02", "handwritten", "Como la hoja real del dueño: letra desprolija, sin encabezado, foto movida", photograph(handwritten(["Bulgares 3x12", "Prensa 4x8", "Sentadilla 4x10", "Extension cuadriceps 3x15"], font: "Marker Felt", size: 76, seed: 2), Photo(rotation: -3, perspective: 0.05, blur: 1.4, exposure: -0.3, shadow: 0.25), seed: 12), jpeg: true,
    [e("Bulgares", 3, 12, ["legs", "glutes"]), e("Prensa", 4, 8, ["legs"]), e("Sentadilla", 4, 10, ["legs", "glutes"]), e("Extension cuadriceps", 3, 15, ["legs"])])

add("H03", "handwritten", "Notación al revés (reps x series): 10x4, 12x3, 15x3", photograph(handwritten(["PECHO", "", "Press banca 10x4", "Aperturas 12x3", "Fondos 15x3", "Press inclinado 10x4"], font: "Noteworthy", size: 72, seed: 3), Photo(rotation: 1.5, perspective: 0.03, blur: 0.5, shadow: 0.1), seed: 13), jpeg: true,
    [e("Press banca", 4, 10, ["chest"]), e("Aperturas", 3, 12, ["chest"]), e("Fondos", 3, 15, ["chest", "triceps"]), e("Press inclinado", 4, 10, ["chest"])], notation: "repsFirst")

add("H04", "handwritten", "Con pesos al lado (80kg 4x8)", photograph(handwritten(["Martes", "", "Press banca 80kg 4x8", "Remo con barra 60 kg 4x10", "Press militar 40kg 3x10", "Curl biceps 15kg 3x12"], font: "Chalkboard SE", size: 62, seed: 4), Photo(rotation: -1.5, perspective: 0.04, blur: 0.7, shadow: 0.2), seed: 14), jpeg: true,
    [e("Press banca", 4, 8, ["chest"]), e("Remo con barra", 4, 10, ["back"]), e("Press militar", 3, 10, ["shoulders"]), e("Curl biceps", 3, 12, ["biceps"])])

add("H05", "handwritten", "Pirámides, AMRAP, tiempo y 'al fallo'", photograph(handwritten(["Dominadas 4 x AMRAP", "Press banca 4x 12-10-8-6", "Remo 3 x 12/10/8", "Plancha 3x30s", "Burpees al fallo"], font: "Bradley Hand", size: 68, seed: 5), Photo(rotation: 2.5, perspective: 0.04, blur: 0.8, shadow: 0.15), seed: 15), jpeg: true,
    [e("Dominadas", 4, nil, ["back"]), e("Press banca", 4, 6, ["chest"]), e("Remo", 3, 8, ["back"]), e("Plancha", 3, nil, ["core"], repsAny: true), e("Burpees", nil, nil, [], setsAny: true, repsAny: true)])

add("H06", "handwritten", "Dos días en una hoja, 10 ejercicios, letra más chica", photograph(handwritten(["LUNES - Pecho y Tríceps", "Press banca 4x8", "Press inclinado mancuernas 3x10", "Aperturas 3x12", "Fondos 3x10", "Extensión tríceps polea 3x12", "", "MIÉRCOLES - Espalda y Bíceps", "Dominadas 4x8", "Remo con barra 4x10", "Jalón al pecho 3x12", "Curl bíceps 3x12", "Curl martillo 3x10"], font: "Noteworthy", size: 50, seed: 6, h: 2300), Photo(rotation: -2, perspective: 0.05, blur: 0.9, shadow: 0.2), seed: 16), jpeg: true,
    [e("Press banca", 4, 8, ["chest"]), e("Press inclinado mancuernas", 3, 10, ["chest"]), e("Aperturas", 3, 12, ["chest"]), e("Fondos", 3, 10, ["chest", "triceps"]), e("Extensión tríceps polea", 3, 12, ["triceps"]),
     e("Dominadas", 4, 8, ["back"]), e("Remo con barra", 4, 10, ["back"]), e("Jalón al pecho", 3, 12, ["back"]), e("Curl bíceps", 3, 12, ["biceps"]), e("Curl martillo", 3, 10, ["biceps", "forearms"])])

add("H07", "handwritten", "La hoja de H01 fotografiada de costado (girada 90°, sin EXIF)", rotated90(photograph(h01Page, Photo(rotation: 2, perspective: 0.03, blur: 0.6, shadow: 0.15), seed: 17)), jpeg: true, h01Exp)

add("H08", "handwritten", "Poca luz, perspectiva fuerte y sombra", photograph(handwritten(["Hombros", "", "Peso muerto 4x6", "Press militar 4x8", "Elevaciones laterales 3x15", "Face pull 3x15"], font: "Bradley Hand", size: 70, seed: 8), Photo(rotation: 5, perspective: 0.12, blur: 1.0, noise: 0.06, exposure: -1.2, shadow: 0.45), seed: 18), jpeg: true,
    [e("Peso muerto", 4, 6, ["back", "legs"]), e("Press militar", 4, 8, ["shoulders"]), e("Elevaciones laterales", 3, 15, ["shoulders"]), e("Face pull", 3, 15, ["shoulders", "back"])])

add("H09", "handwritten", "Un ejercicio tachado y anotaciones sueltas", photograph(handwritten(["Sentadilla 4x8", "Prensa 4x10", "Zancadas 3x12 (c/ pierna)", "Gemelos 4x20 ✓", "subir peso!!"], font: "Marker Felt", size: 72, seed: 9, struck: [1]), Photo(rotation: -2, perspective: 0.04, blur: 0.7, shadow: 0.2), seed: 19), jpeg: true,
    [e("Sentadilla", 4, 8, ["legs", "glutes"]), e("Prensa", 4, 10, ["legs"], excluded: true), e("Zancadas", 3, 12, ["legs", "glutes"]), e("Gemelos", 4, 20, ["calves"])])

add("H10", "handwritten", "Rutina en inglés a mano", photograph(handwritten(["Push day", "", "Bench press 4x6-8", "Incline DB press 3x10", "Shoulder press 3x8", "Lateral raises 3x15", "Tricep pushdown 3x12"], font: "Marker Felt", size: 70, seed: 10), Photo(rotation: 1, perspective: 0.03, blur: 0.6, shadow: 0.15), seed: 20), jpeg: true,
    [e("Bench press", 4, 6, ["chest"]), e("Incline DB press", 3, 10, ["chest"]), e("Shoulder press", 3, 8, ["shoulders"]), e("Lateral raises", 3, 15, ["shoulders"]), e("Tricep pushdown", 3, 12, ["triceps"])])

add("H11", "handwritten", "Scheda en italiano a mano", photograph(handwritten(["Scheda A", "", "Panca piana 4x8", "Lat machine 4x10", "Squat 4x8", "Curl bilanciere 3x10"], font: "Chalkboard SE", size: 66, seed: 21), Photo(rotation: -1, perspective: 0.03, blur: 0.6, shadow: 0.1), seed: 22), jpeg: true,
    [e("Panca piana", 4, 8, ["chest"]), e("Lat machine", 4, 10, ["back"]), e("Squat", 4, 8, ["legs", "glutes"]), e("Curl bilanciere", 3, 10, ["biceps"])])

add("H12", "handwritten", "Cursiva difícil de leer (Snell Roundhand)", photograph(handwritten(["Sentadilla 4x10", "Press banca 4x8", "Remo 4x10"], font: "Snell Roundhand", size: 84, seed: 23), Photo(rotation: 1.5, perspective: 0.03, blur: 0.8, shadow: 0.15), seed: 24), jpeg: true,
    [e("Sentadilla", 4, 10, ["legs", "glutes"]), e("Press banca", 4, 8, ["chest"]), e("Remo", 4, 10, ["back"])])

add("H13", "handwritten", "Series y reps escritas en palabras ('4 series de 10')", photograph(handwritten(["Sentadilla: 4 series de 10 repeticiones", "Prensa: 3 series x 12 reps", "Gemelos - 4 sets / 15"], font: "Noteworthy", size: 58, seed: 25), Photo(rotation: -1, perspective: 0.03, blur: 0.6, shadow: 0.1), seed: 26), jpeg: true,
    [e("Sentadilla", 4, 10, ["legs", "glutes"]), e("Prensa", 3, 12, ["legs"]), e("Gemelos", 4, 15, ["calves"])])

// MARK: - Printed / PDF

let p01Rows = [["Ejercicio", "Series", "Reps", "Descanso"], ["Sentadilla", "4", "8-10", "90 s"], ["Press banca", "4", "8", "90 s"], ["Remo con mancuerna", "3", "12", "60 s"], ["Press militar", "3", "10", "60 s"], ["Curl bíceps", "3", "12", "45 s"], ["Plancha", "3", "30 s", "30 s"]]
let p01Exp = [e("Sentadilla", 4, 8, ["legs", "glutes"]), e("Press banca", 4, 8, ["chest"]), e("Remo con mancuerna", 3, 12, ["back"]), e("Press militar", 3, 10, ["shoulders"]), e("Curl bíceps", 3, 12, ["biceps"]), e("Plancha", 3, nil, ["core"], repsAny: true)]
let p01 = pdf("P01") { ctx, H in
    text(ctx, "Rutina Full Body — Semana 1", sys(22, .bold), .black, x: 50, top: 60, H: H)
    text(ctx, "Entrenador: Martín · 3 veces por semana", sys(11), .darkGray, x: 50, top: 92, H: H)
    table(ctx, H: H, x: 50, top: 130, cols: [210, 90, 90, 105], rows: p01Rows, size: 12, rowH: 30)
}
add("P01", "pdf", "PDF con tabla (Ejercicio | Series | Reps | Descanso)", p01, jpeg: false, p01Exp)

add("P02", "pdf", "PDF de gimnasio: encabezado, dos columnas Día A / Día B, notas al pie", pdf("P02") { ctx, H in
    round(ctx, rgb(0.08, 0.08, 0.1), CGRect(x: 30, y: H - 110, width: 535, height: 80), 8)
    text(ctx, "GYM IRON · Plan de entrenamiento", sys(20, .heavy), .white, x: 50, top: 50, H: H)
    text(ctx, "Alumno: ______________   Objetivo: hipertrofia", sys(11), .darkGray, x: 40, top: 130, H: H)
    let a = ["DÍA A", "Press banca 4x8", "Remo 4x10", "Press militar 3x10", "Curl bíceps 3x12"]
    let b = ["DÍA B", "Sentadilla 4x8", "Peso muerto rumano 3x10", "Prensa 3x12", "Gemelos 4x15"]
    for (i, l) in a.enumerated() { text(ctx, l, i == 0 ? sys(15, .bold) : sys(13), .black, x: 45, top: 180 + CGFloat(i) * 30, H: H) }
    for (i, l) in b.enumerated() { text(ctx, l, i == 0 ? sys(15, .bold) : sys(13), .black, x: 320, top: 180 + CGFloat(i) * 30, H: H) }
    text(ctx, "Hidratate. Calentá 10 minutos antes de empezar.", sys(10), .gray, x: 45, top: 780, H: H)
}, jpeg: false,
    [e("Press banca", 4, 8, ["chest"]), e("Remo", 4, 10, ["back"]), e("Press militar", 3, 10, ["shoulders"]), e("Curl bíceps", 3, 12, ["biceps"]),
     e("Sentadilla", 4, 8, ["legs", "glutes"]), e("Peso muerto rumano", 3, 10, ["legs", "glutes", "back"]), e("Prensa", 3, 12, ["legs"]), e("Gemelos", 4, 15, ["calves"])])

add("P03", "printed-photo", "La hoja de P01 impresa y fotografiada (perspectiva, sombra)", photograph(p01, Photo(rotation: -4, perspective: 0.08, blur: 0.8, noise: 0.04, shadow: 0.3), seed: 33), jpeg: true, p01Exp)

add("P04", "pdf", "Artículo de revista: párrafos + lista '4 series de 12 repeticiones'", pdf("P04") { ctx, H in
    text(ctx, "Rutina de glúteos en casa", family("Georgia", 26, bold: true), .black, x: 50, top: 60, H: H)
    let intro = ["Fortalecer los glúteos mejora la postura y protege la zona lumbar. Estos cuatro",
                 "ejercicios se pueden hacer con una banda elástica o con tu propio peso corporal."]
    for (i, l) in intro.enumerated() { text(ctx, l, family("Georgia", 11), .darkGray, x: 50, top: 110 + CGFloat(i) * 17, H: H) }
    let list = ["1. Hip thrust: 4 series de 12 repeticiones.", "2. Sentadilla búlgara: 3 series de 10 por pierna.", "3. Puente de glúteo: 3 series de 15.", "4. Patada de glúteo: 3 series de 20."]
    for (i, l) in list.enumerated() { text(ctx, l, family("Georgia", 13), .black, x: 60, top: 170 + CGFloat(i) * 26, H: H) }
    text(ctx, "Descansá 60 segundos entre series y aumentá la dificultad cada semana.", family("Georgia", 11), .darkGray, x: 50, top: 290, H: H)
}, jpeg: false,
    [e("Hip thrust", 4, 12, ["glutes"]), e("Sentadilla búlgara", 3, 10, ["glutes", "legs"]), e("Puente de glúteo", 3, 15, ["glutes"]), e("Patada de glúteo", 3, 20, ["glutes"])])

add("P05", "pdf", "Programa en francés", pdf("P05") { ctx, H in
    text(ctx, "Programme — Force", sys(22, .bold), .black, x: 50, top: 60, H: H)
    for (i, l) in ["Développé couché 4x8", "Tractions 4x6", "Squat 4x8", "Fentes 3x12", "Curl biceps 3x10"].enumerated() {
        text(ctx, "•  " + l, sys(14), .black, x: 60, top: 110 + CGFloat(i) * 30, H: H)
    }
}, jpeg: false,
    [e("Développé couché", 4, 8, ["chest"]), e("Tractions", 4, 6, ["back"]), e("Squat", 4, 8, ["legs", "glutes"]), e("Fentes", 3, 12, ["legs", "glutes"]), e("Curl biceps", 3, 10, ["biceps"])])

let p06A = [("Press banca", 4, 8, ["chest"]), ("Press inclinado", 3, 10, ["chest"]), ("Aperturas", 3, 12, ["chest"]), ("Press militar", 4, 8, ["shoulders"]), ("Elevaciones laterales", 3, 15, ["shoulders"]),
            ("Fondos", 3, 10, ["chest", "triceps"]), ("Extensión tríceps", 3, 12, ["triceps"]), ("Crunch", 3, 20, ["core"]), ("Elevación de piernas", 3, 15, ["core"]), ("Rueda abdominal", 3, 10, ["core"])]
let p06B = [("Sentadilla", 4, 8, ["legs", "glutes"]), ("Prensa", 4, 10, ["legs"]), ("Peso muerto", 4, 6, ["back", "legs"]), ("Curl femoral", 3, 12, ["legs"]), ("Extensión cuádriceps", 3, 15, ["legs"]),
            ("Hip thrust", 4, 10, ["glutes", "legs"]), ("Gemelos", 4, 15, ["calves"]), ("Dominadas", 4, 8, ["back"]), ("Remo con barra", 4, 10, ["back"]), ("Curl bíceps", 3, 12, ["biceps"])]
add("P06", "pdf", "Rutina larga: 20 ejercicios en dos tablas", pdf("P06") { ctx, H in
    text(ctx, "Plan 4 semanas — Torso / Pierna", sys(18, .bold), .black, x: 40, top: 40, H: H)
    text(ctx, "Día 1 · Torso", sys(13, .semibold), .black, x: 40, top: 75, H: H)
    table(ctx, H: H, x: 40, top: 95, cols: [260, 90, 90], rows: [["Ejercicio", "Series", "Reps"]] + p06A.map { [$0.0, "\($0.1)", "\($0.2)"] }, size: 10.5, rowH: 22)
    text(ctx, "Día 2 · Pierna y espalda", sys(13, .semibold), .black, x: 40, top: 360, H: H)
    table(ctx, H: H, x: 40, top: 380, cols: [260, 90, 90], rows: [["Ejercicio", "Series", "Reps"]] + p06B.map { [$0.0, "\($0.1)", "\($0.2)"] }, size: 10.5, rowH: 22)
}, jpeg: false, (p06A + p06B).map { e($0.0, $0.1, $0.2, $0.3) })

add("P07", "pdf", "Superseries (A1/A2) y circuito final sin series fijas", pdf("P07") { ctx, H in
    text(ctx, "Upper — Superseries", sys(20, .bold), .black, x: 50, top: 60, H: H)
    for (i, l) in ["A1. Press banca 4x8", "A2. Remo con barra 4x8", "B1. Curl bíceps 3x12", "B2. Extensión tríceps 3x12", "", "Circuito final x3 vueltas:", "   - Burpees 10", "   - Saltos al cajón 15", "   - Mountain climbers 30"].enumerated() {
        text(ctx, l, sys(14), .black, x: 55, top: 110 + CGFloat(i) * 28, H: H)
    }
}, jpeg: false,
    [e("Press banca", 4, 8, ["chest"]), e("Remo con barra", 4, 8, ["back"]), e("Curl bíceps", 3, 12, ["biceps"]), e("Extensión tríceps", 3, 12, ["triceps"]),
     e("Burpees", nil, 10, [], setsAny: true, repsAny: true), e("Saltos al cajón", nil, 15, [], setsAny: true, repsAny: true), e("Mountain climbers", nil, 30, ["core"], setsAny: true, repsAny: true)])

add("P08", "pdf", "Tabla de progresión por semana (Sem 1..4): ambigua a propósito", pdf("P08") { ctx, H in
    text(ctx, "Bloque de fuerza — progresión", sys(18, .bold), .black, x: 40, top: 50, H: H)
    table(ctx, H: H, x: 40, top: 90, cols: [170, 90, 90, 90, 90], rows: [["Ejercicio", "Sem 1", "Sem 2", "Sem 3", "Sem 4"], ["Sentadilla", "3x10", "3x8", "4x6", "4x5"], ["Press banca", "3x10", "3x8", "4x6", "4x5"], ["Remo", "3x12", "3x10", "4x8", "4x8"]], size: 12, rowH: 30)
}, jpeg: false,
    [e("Sentadilla", nil, nil, ["legs", "glutes"], setsAny: true, repsAny: true), e("Press banca", nil, nil, ["chest"], setsAny: true, repsAny: true), e("Remo", nil, nil, ["back"], setsAny: true, repsAny: true)], notation: "weekly")

// MARK: - Screenshots

func notes(dark: Bool, title: String, lines: [String]) -> CGImage {
    phone(dark: dark) { ctx in
        let fg: NSColor = dark ? .white : .black
        let accent = rgb(0.92, 0.70, 0.10)
        text(ctx, "‹ Notas", sys(54), accent, x: 40, top: 180, H: PH)
        text(ctx, title, sys(96, .bold), fg, x: 60, top: 320, H: PH)
        text(ctx, "14 de septiembre de 2026, 7:02", sys(40), .gray, x: 60, top: 460, H: PH)
        for (i, l) in lines.enumerated() { text(ctx, l, sys(58), fg, x: 60, top: 580 + CGFloat(i) * 105, H: PH) }
    }
}
add("S01", "screenshot", "Nota de iOS en modo claro con viñetas", notes(dark: false, title: "Rutina martes", lines: ["• Press banca 4x8", "• Press inclinado 3x10", "• Remo sentado 4x10", "• Jalón al pecho 3x12", "• Curl bíceps 3x12"]), jpeg: false,
    [e("Press banca", 4, 8, ["chest"]), e("Press inclinado", 3, 10, ["chest"]), e("Remo sentado", 4, 10, ["back"]), e("Jalón al pecho", 3, 12, ["back"]), e("Curl bíceps", 3, 12, ["biceps"])])
add("S02", "screenshot", "Nota en modo oscuro con emoji y 5x5", notes(dark: true, title: "Leg day 🦵", lines: ["Sentadilla 5x5", "Prensa 4x12", "Curl femoral 3x12", "Gemelos 5x20"]), jpeg: false,
    [e("Sentadilla", 5, 5, ["legs", "glutes"]), e("Prensa", 4, 12, ["legs"]), e("Curl femoral", 3, 12, ["legs"]), e("Gemelos", 5, 20, ["calves"])])

add("S03", "screenshot", "Chat de WhatsApp: el coach manda la rutina entre otros mensajes", phone(dark: false, bg: rgb(0.93, 0.90, 0.85)) { ctx in
    fill(ctx, rgb(0.97, 0.97, 0.97), CGRect(x: 0, y: PH - 330, width: PW, height: 190))
    text(ctx, "‹  Coach Martín", sys(56, .semibold), .black, x: 40, top: 200, H: PH)
    func bubble(_ lines: [String], top: CGFloat, outgoing: Bool) {
        let width: CGFloat = 820, height = CGFloat(lines.count) * 72 + 70
        let x: CGFloat = outgoing ? PW - width - 40 : 40
        round(ctx, outgoing ? rgb(0.86, 0.97, 0.78) : .white, CGRect(x: x, y: PH - top - height, width: width, height: height), 30)
        for (i, l) in lines.enumerated() { text(ctx, l, sys(50), .black, x: x + 35, top: top + 25 + CGFloat(i) * 72, H: PH) }
        text(ctx, "19:4\(lines.count)", sys(34), .gray, x: x + width - 130, top: top + height - 55, H: PH)
    }
    bubble(["Buenas! Te paso la rutina de mañana 💪"], top: 420, outgoing: false)
    bubble(["Hombros:", "Press militar 4x8", "Elevaciones laterales 4x15", "Pájaros 3x15", "Encogimientos 3x12"], top: 620, outgoing: false)
    bubble(["dale gracias!!"], top: 1120, outgoing: true)
}, jpeg: false,
    [e("Press militar", 4, 8, ["shoulders"]), e("Elevaciones laterales", 4, 15, ["shoulders"]), e("Pájaros", 3, 15, ["shoulders", "back"]), e("Encogimientos", 3, 12, ["shoulders", "back"])])

add("S04", "screenshot", "Planilla (Sheets) con columna de peso que no son reps", phone(dark: false) { ctx in
    text(ctx, "Rutina fuerza", sys(56, .semibold), .black, x: 40, top: 190, H: PH)
    let cols: [CGFloat] = [420, 220, 220, 240]
    let rows = [["Ejercicio", "Series", "Reps", "Peso (kg)"], ["Sentadilla", "4", "8", "100"], ["Press banca", "4", "8", "70"], ["Peso muerto", "3", "5", "120"], ["Dominadas", "3", "8", "—"]]
    let rowH: CGFloat = 120, x: CGFloat = 40, top: CGFloat = 330
    for (r, row) in rows.enumerated() {
        if r == 0 { fill(ctx, rgb(0.90, 0.95, 0.90), CGRect(x: x, y: PH - top - rowH, width: cols.reduce(0, +), height: rowH)) }
        var cx = x
        for (c, cell) in row.enumerated() { text(ctx, cell, sys(48, r == 0 ? .semibold : .regular), .black, x: cx + 20, top: top + CGFloat(r) * rowH + 30, H: PH); cx += cols[c] }
    }
    ctx.setStrokeColor(rgb(0.80, 0.80, 0.80).cgColor); ctx.setLineWidth(3)
    for r in 0...rows.count { let y = PH - top - CGFloat(r) * rowH; ctx.move(to: CGPoint(x: x, y: y)); ctx.addLine(to: CGPoint(x: x + cols.reduce(0, +), y: y)) }
    var cx = x
    for c in 0...cols.count { ctx.move(to: CGPoint(x: cx, y: PH - top)); ctx.addLine(to: CGPoint(x: cx, y: PH - top - CGFloat(rows.count) * rowH)); if c < cols.count { cx += cols[c] } }
    ctx.strokePath()
}, jpeg: false,
    [e("Sentadilla", 4, 8, ["legs", "glutes"]), e("Press banca", 4, 8, ["chest"]), e("Peso muerto", 3, 5, ["back", "legs"]), e("Dominadas", 3, 8, ["back"])])

add("S05", "screenshot", "Post de Instagram: texto grande en mayúsculas sobre degradé", phone(dark: true) { ctx in
    let rect = CGRect(x: 0, y: PH - 2000, width: PW, height: PW)
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [rgb(0.95, 0.35, 0.55).cgColor, rgb(0.98, 0.65, 0.25).cgColor] as CFArray, locations: [0, 1])!
    ctx.saveGState(); ctx.clip(to: rect); ctx.drawLinearGradient(grad, start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.minY), options: []); ctx.restoreGState()
    text(ctx, "fitcoach.ar", sys(44, .semibold), .white, x: 40, top: 230, H: PH)
    text(ctx, "RUTINA GLÚTEOS 🍑", sys(92, .black), .white, x: 70, top: 640, H: PH)
    for (i, l) in ["HIP THRUST 4X12", "PATADA 3X15", "ABDUCCIÓN 4X20", "SENTADILLA SUMO 4X10"].enumerated() {
        text(ctx, l, sys(74, .heavy), .white, x: 90, top: 820 + CGFloat(i) * 130, H: PH)
    }
    text(ctx, "♥ 2.341   💬 87", sys(48, .semibold), .white, x: 40, top: 2030, H: PH)
    text(ctx, "fitcoach.ar Guardala y probala esta semana 🔥", sys(44), .white, x: 40, top: 2120, H: PH)
}, jpeg: false,
    [e("Hip thrust", 4, 12, ["glutes"]), e("Patada", 3, 15, ["glutes"]), e("Abducción", 4, 20, ["glutes", "legs"]), e("Sentadilla sumo", 4, 10, ["legs", "glutes"])])

add("S06", "screenshot", "App de fitness en inglés con tarjetas '4 × 5 · 140 kg'", phone(dark: true) { ctx in
    text(ctx, "Pull Day", sys(100, .bold), .white, x: 60, top: 220, H: PH)
    let cards = [("Deadlift", "4 × 5 · 140 kg"), ("Pull-ups", "4 × 8"), ("Barbell row", "3 × 10 · 70 kg"), ("Hammer curl", "3 × 12")]
    for (i, c) in cards.enumerated() {
        let top = 420 + CGFloat(i) * 300
        round(ctx, rgb(0.13, 0.13, 0.15), CGRect(x: 40, y: PH - top - 250, width: PW - 80, height: 250), 40)
        text(ctx, c.0, sys(64, .semibold), .white, x: 90, top: top + 40, H: PH)
        text(ctx, c.1, sys(52), rgb(0.6, 0.8, 1.0), x: 90, top: top + 140, H: PH)
    }
}, jpeg: false,
    [e("Deadlift", 4, 5, ["back", "legs"]), e("Pull-ups", 4, 8, ["back"]), e("Barbell row", 3, 10, ["back"]), e("Hammer curl", 3, 12, ["biceps", "forearms"])])

add("S07", "screenshot", "Nota con cardio por tiempo y core ('Cinta 20 min', 'Plancha 3x45s')", notes(dark: false, title: "Cardio + core", lines: ["Cinta 20 min", "Bici 15 min", "Plancha 3x45s", "Abdominales 3x20", "Russian twist 3x30"]), jpeg: false,
    [e("Cinta", nil, nil, [], setsAny: true, repsAny: true), e("Bici", nil, nil, [], setsAny: true, repsAny: true), e("Plancha", 3, nil, ["core"], repsAny: true), e("Abdominales", 3, 20, ["core"]), e("Russian twist", 3, 30, ["core"])])

// MARK: - Negative / degraded

add("N01", "negative", "Lista del súper a mano (no es una rutina)", photograph(handwritten(["Súper", "", "Leche x2", "Huevos 12", "Pan", "Pollo 2kg", "Bananas 6"], font: "Bradley Hand", size: 72, seed: 41), Photo(rotation: 2, perspective: 0.03, blur: 0.6, shadow: 0.15), seed: 42), jpeg: true, [], nothing: true)
add("N02", "negative", "Hoja rayada en blanco", photograph(handwritten([], font: "Bradley Hand", size: 72, seed: 43), Photo(rotation: -2, perspective: 0.04, blur: 0.6, shadow: 0.2), seed: 44), jpeg: true, [], nothing: true)
add("N03", "negative", "La rutina de H01 ilegible (desenfoque extremo)", photograph(h01Page, Photo(rotation: 2, perspective: 0.03, blur: 14, noise: 0.05, shadow: 0.2), seed: 45), jpeg: true, h01Exp, notation: "unreadable")
add("N04", "negative", "Foto sin texto (formas y degradé)", canvas(1500, 2000) { ctx in
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [rgb(0.2, 0.25, 0.3).cgColor, rgb(0.55, 0.5, 0.45).cgColor] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 1500, y: 2000), options: [])
    for i in 0..<9 { round(ctx, rgb(0.8, 0.8, 0.82, 0.5), CGRect(x: 150 + CGFloat(i % 3) * 420, y: 300 + CGFloat(i / 3) * 520, width: 300, height: 300), 150) }
}, jpeg: true, [], nothing: true)

let data = try! JSONEncoder().encode(manifest)
try! data.write(to: URL(fileURLWithPath: "\(outDir)/manifest.json"))
print("casos generados: \(manifest.count)")
