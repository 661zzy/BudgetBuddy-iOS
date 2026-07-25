import SwiftUI

// MARK: - Tiny pixel-art engine
// A low-res color grid you draw into with shape primitives, rendered as crisp
// squares. True "Mario-style" pixel output, but composed by coordinate so each
// scene comes out clean. One draw-function per story scene (see PIXEL_SCENES).

struct PixelGrid {
    let w: Int
    let h: Int
    var cells: [Color?]

    init(_ w: Int, _ h: Int) { self.w = w; self.h = h; cells = Array(repeating: nil, count: w * h) }

    mutating func px(_ x: Int, _ y: Int, _ c: Color) {
        if x >= 0 && x < w && y >= 0 && y < h { cells[y * w + x] = c }
    }
    mutating func rect(_ x: Int, _ y: Int, _ rw: Int, _ rh: Int, _ c: Color) {
        for yy in y..<(y + rh) { for xx in x..<(x + rw) { px(xx, yy, c) } }
    }
    mutating func hline(_ x0: Int, _ x1: Int, _ y: Int, _ c: Color) {
        for x in min(x0, x1)...max(x0, x1) { px(x, y, c) }
    }
    mutating func vline(_ x: Int, _ y0: Int, _ y1: Int, _ c: Color) {
        for y in min(y0, y1)...max(y0, y1) { px(x, y, c) }
    }
    mutating func line(_ ax: Int, _ ay: Int, _ bx: Int, _ by: Int, _ c: Color) {
        var x0 = ax, y0 = ay
        let dx = abs(bx - x0), dy = -abs(by - y0)
        let sx = x0 < bx ? 1 : -1, sy = y0 < by ? 1 : -1
        var err = dx + dy
        while true {
            px(x0, y0, c)
            if x0 == bx && y0 == by { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x0 += sx }
            if e2 <= dx { err += dx; y0 += sy }
        }
    }
    mutating func disc(_ cx: Int, _ cy: Int, _ r: Int, _ c: Color) {
        for yy in (cy - r)...(cy + r) {
            for xx in (cx - r)...(cx + r) {
                let dx = xx - cx, dy = yy - cy
                if dx * dx + dy * dy <= r * r { px(xx, yy, c) }
            }
        }
    }
    mutating func star(_ cx: Int, _ cy: Int, _ r: Int, _ c: Color) {
        line(cx, cy - r, cx, cy + r, c)
        line(cx - r, cy, cx + r, cy, c)
        line(cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1, c)
        line(cx - r + 1, cy + r - 1, cx + r - 1, cy - r + 1, c)
    }
}

struct PixelArtView: View {
    let grid: PixelGrid
    var body: some View {
        Canvas { ctx, size in
            let cw = size.width / CGFloat(grid.w)
            let ch = size.height / CGFloat(grid.h)
            for y in 0..<grid.h {
                for x in 0..<grid.w {
                    guard let c = grid.cells[y * grid.w + x] else { continue }
                    let r = CGRect(x: CGFloat(x) * cw, y: CGFloat(y) * ch,
                                   width: cw + 0.6, height: ch + 0.6)
                    ctx.fill(Path(r), with: .color(c))
                }
            }
        }
        .aspectRatio(CGFloat(grid.w) / CGFloat(grid.h), contentMode: .fit)
    }
}

// MARK: - Scene registry  (key = "storyId/sceneId")

func pixelScene(_ storyId: String, _ sceneId: String) -> PixelGrid? {
    switch "\(storyId)/\(sceneId)" {
    case "flat-tire/s1": return drawFlatTire()
    case "flat-tire/s2": return drawRepairShop()
    case "flat-tire/s3": return drawClock()
    case "flat-tire/s4": return drawBus()
    case "flat-tire/s5": return drawDormNight()
    case "flat-tire/s6": return drawSunriseGate()
    case "anti-scam/s3": return drawPhonePopup()
    default: return nil
    }
}

// MARK: - Scenes

// 爆胎的自行车 · 车胎爆了 — a bike with a deflated front wheel + a pop burst.
private func drawFlatTire() -> PixelGrid {
    var g = PixelGrid(44, 26)
    let sky = Color(hex: 0xCDE8F4), road = Color(hex: 0x8A9096), frame = Color(hex: 0x273039)
    let tire = Color(hex: 0x1E2329), spoke = Color(hex: 0xB6BEC5)
    let burst = Color(hex: 0xF6C734), core = Color(hex: 0xEE8B3A), seat = Color(hex: 0x3C2E28)
    g.rect(0, 0, 44, 26, sky)
    g.rect(0, 20, 44, 6, road)

    let by = 16, bx = 30, fy = 16, fx = 13, r = 6
    // back wheel (round)
    g.disc(bx, by, r, tire); g.disc(bx, by, r - 2, sky)
    g.line(bx - 4, by, bx + 4, by, spoke); g.line(bx, by - 4, bx, by + 4, spoke)
    g.line(bx - 3, by - 3, bx + 3, by + 3, spoke); g.line(bx - 3, by + 3, bx + 3, by - 3, spoke)
    g.disc(bx, by, 1, frame)
    // front wheel (will be flattened)
    g.disc(fx, fy, r, tire); g.disc(fx, fy, r - 2, sky)
    g.line(fx - 4, fy, fx + 4, fy, spoke); g.line(fx, fy - 4, fx, fy + 4, spoke)
    g.line(fx - 3, fy - 3, fx + 3, fy + 3, spoke); g.line(fx - 3, fy + 3, fx + 3, fy - 3, spoke)
    g.disc(fx, fy, 1, frame)
    // flatten: mash the bottom onto the road as a spread-out tire
    g.rect(fx - 7, 19, 15, 7, road)
    g.rect(fx - 7, 19, 15, 2, tire)
    g.px(fx - 8, 20, tire); g.px(fx + 7, 20, tire)
    // frame
    g.line(fx, fy, bx, by, frame)
    g.line(fx, fy, 24, 7, frame); g.line(bx, by, 26, 7, frame); g.line(24, 7, 28, 7, frame)
    g.rect(27, 5, 5, 2, seat)
    g.line(fx, fy, 10, 6, frame); g.rect(7, 5, 5, 2, frame)
    // pop burst
    g.star(9, 10, 3, burst); g.disc(9, 10, 1, core)
    return g
}

// 手机弹窗 — a phone showing a popup card (used for 0 利息借钱 / 弹窗诈骗 scenes).
private func drawPhonePopup() -> PixelGrid {
    var g = PixelGrid(30, 38)
    let bg = Color(hex: 0xE7EEF5), body = Color(hex: 0x2B3138), screen = Color(hex: 0xBFD0D9)
    let pop = Color(hex: 0xFFFFFF), red = Color(hex: 0xD9534F), ink = Color(hex: 0x2B3138)
    g.rect(0, 0, 30, 38, bg)
    g.rect(7, 3, 16, 32, body)          // phone body
    g.rect(9, 6, 12, 26, screen)        // screen
    g.rect(13, 33, 4, 1, Color(hex: 0x55606A))  // home indicator
    // popup card
    g.rect(9, 12, 12, 10, pop)
    g.disc(12, 16, 1, red)              // alert dot
    g.hline(15, 19, 15, ink); g.hline(15, 18, 17, ink); g.hline(11, 19, 19, ink)
    return g
}

// 修车铺报价 — a leaning tire, a big wrench, and a ¥ price tag.
private func drawRepairShop() -> PixelGrid {
    var g = PixelGrid(40, 26)
    let wall = Color(hex: 0xEDE3D0), floor = Color(hex: 0x6E6258), metal = Color(hex: 0x9AA1A8)
    let dark = Color(hex: 0x3A4148), tire = Color(hex: 0x232830), tag = Color(hex: 0xE7C04B), ink = Color(hex: 0x2A2F36)
    g.rect(0, 0, 40, 26, wall)
    g.rect(0, 21, 40, 5, floor)
    g.disc(10, 15, 6, tire); g.disc(10, 15, 3, wall); g.disc(10, 15, 1, dark)   // leaning tire
    g.line(22, 20, 30, 9, metal)                       // wrench handle
    g.rect(28, 6, 6, 5, metal); g.rect(30, 7, 3, 3, wall)   // open-end head
    g.rect(19, 3, 10, 8, tag)                           // price tag
    g.line(22, 5, 23, 6, ink); g.line(25, 5, 24, 6, ink)
    g.vline(23, 6, 9, ink); g.hline(21, 25, 7, ink); g.hline(21, 25, 8, ink)   // ¥
    return g
}

// 快迟到了 — a clock under time pressure.
private func drawClock() -> PixelGrid {
    var g = PixelGrid(34, 34)
    let bg = Color(hex: 0xDDE8F0), face = Color(hex: 0xF7F3E8), edge = Color(hex: 0x2E3A44)
    let hand = Color(hex: 0xCF5B4E), ink = Color(hex: 0x2E3A44)
    g.rect(0, 0, 34, 34, bg)
    g.disc(17, 17, 13, edge); g.disc(17, 17, 11, face)
    g.rect(16, 5, 2, 2, ink); g.rect(27, 16, 2, 2, ink); g.rect(16, 27, 2, 2, ink); g.rect(5, 16, 2, 2, ink)
    g.line(17, 17, 17, 9, ink)        // minute hand
    g.line(17, 17, 23, 20, hand)      // hour hand
    g.disc(17, 17, 1, ink)
    return g
}

// 公交选择 — a bus at a stop.
private func drawBus() -> PixelGrid {
    var g = PixelGrid(44, 26)
    let sky = Color(hex: 0xCDE8F4), road = Color(hex: 0x8A9096), body = Color(hex: 0x4F86C6)
    let win = Color(hex: 0xBFE0F2), dark = Color(hex: 0x2A2F36), tire = Color(hex: 0x1E2329)
    let sign = Color(hex: 0xE7C04B), pole = Color(hex: 0x9AA1A8)
    g.rect(0, 0, 44, 26, sky)
    g.rect(0, 21, 44, 5, road)
    g.rect(6, 7, 30, 12, body)
    for i in 0..<4 { g.rect(9 + i * 6, 9, 4, 4, win) }
    g.rect(31, 11, 3, 7, win)          // door
    g.hline(6, 35, 16, dark)           // stripe
    g.disc(13, 20, 3, tire); g.disc(13, 20, 1, pole)
    g.disc(29, 20, 3, tire); g.disc(29, 20, 1, pole)
    g.vline(40, 7, 21, pole); g.rect(38, 5, 5, 4, sign)   // bus-stop sign
    return g
}

// 当天结束 — a dorm at night with a crescent moon in the window.
private func drawDormNight() -> PixelGrid {
    var g = PixelGrid(40, 26)
    let night = Color(hex: 0x2C3A55), floor = Color(hex: 0x26324A), bed = Color(hex: 0x7E8AA6)
    let blanket = Color(hex: 0x9AA7C2), pillow = Color(hex: 0xE8ECF4), moon = Color(hex: 0xF3EAC2)
    let frame = Color(hex: 0x1E2738), inner = Color(hex: 0x1B2740)
    g.rect(0, 0, 40, 26, night)
    g.rect(0, 21, 40, 5, floor)
    g.rect(4, 4, 12, 11, frame); g.rect(5, 5, 10, 9, inner)     // window
    g.disc(11, 9, 3, moon); g.disc(13, 8, 2, inner)             // crescent
    g.px(7, 6, moon); g.px(9, 11, moon); g.px(13, 12, moon)     // stars
    g.rect(20, 12, 16, 7, bed)
    g.rect(20, 10, 6, 4, pillow)
    g.rect(26, 11, 11, 5, blanket)
    g.rect(19, 15, 2, 5, frame); g.rect(35, 15, 2, 5, frame)
    return g
}

// 第二天选择 — sunrise over the school gate.
private func drawSunriseGate() -> PixelGrid {
    var g = PixelGrid(40, 26)
    let sky = Color(hex: 0xFCE3B8), sun = Color(hex: 0xF6A93B), ground = Color(hex: 0x8FA06A)
    let pillar = Color(hex: 0xB85C46), arch = Color(hex: 0x9A4A38), sign = Color(hex: 0xF7F3E8), ink = Color(hex: 0x3A2A24)
    g.rect(0, 0, 40, 26, sky)
    g.rect(0, 21, 40, 5, ground)
    g.disc(20, 16, 5, sun)
    g.vline(20, 4, 7, sun); g.hline(8, 11, 16, sun); g.hline(29, 32, 16, sun)   // rays
    g.rect(6, 8, 3, 13, pillar); g.rect(31, 8, 3, 13, pillar)
    g.rect(6, 6, 28, 3, arch)
    g.rect(15, 2, 10, 4, sign)
    g.hline(17, 22, 4, ink)
    return g
}
