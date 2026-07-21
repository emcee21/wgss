import AppKit
import ScreenSaver

final class WarGamesScreenSaverView: ScreenSaverView {
    private enum Phase {
        case tictactoe
        case thermonuclear
        case conclusion
    }

    private let terminalColor = NSColor(calibratedRed: 0.39, green: 1.0, blue: 0.39, alpha: 1.0)
    private let backgroundColor = NSColor.black
    private let terminalGlowColor = NSColor(calibratedRed: 0.62, green: 1.0, blue: 0.62, alpha: 1.0)
    private let hostileColor = NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.40, alpha: 1.0)
    private let brightTrailColor = NSColor(calibratedRed: 0.82, green: 0.90, blue: 1.0, alpha: 1.0)

    private var phase: Phase = .tictactoe
    private var phaseTick = 0

    private var script: [String] = []
    private var renderedLines: [String] = []
    private var currentLine = ""
    private var lineIndex = 0
    private var characterIndex = 0
    private var holdTicks = 0

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
        resetScenario()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 30.0
        resetScenario()
    }

    override func animateOneFrame() {
        phaseTick += 1

        if holdTicks > 0 {
            holdTicks -= 1
            needsDisplay = true
            return
        }

        guard lineIndex < script.count else {
            holdTicks = 120
            resetScenario()
            needsDisplay = true
            return
        }

        let targetLine = script[lineIndex]
        if characterIndex < targetLine.count {
            characterIndex += 1
            let end = targetLine.index(targetLine.startIndex, offsetBy: characterIndex)
            currentLine = String(targetLine[..<end])
        } else {
            renderedLines.append(targetLine)
            currentLine = ""
            lineIndex += 1
            characterIndex = 0
            holdTicks = 18
            updatePhase(forCompletedLine: targetLine)
        }

        needsDisplay = true
    }

    override func draw(_ rect: NSRect) {
        backgroundColor.setFill()
        rect.fill()

        let inset: CGFloat = isPreview ? 8 : 24
        let content = rect.insetBy(dx: inset, dy: inset)
        let visualHeight = content.height * (isPreview ? 0.40 : 0.46)
        let visualRect = NSRect(x: content.minX, y: content.maxY - visualHeight, width: content.width, height: visualHeight)
        let textRect = NSRect(x: content.minX, y: content.minY, width: content.width, height: content.height - visualHeight - (isPreview ? 6 : 10))

        drawVisuals(in: visualRect)
        drawTerminalText(in: textRect)
    }

    private func drawTerminalText(in rect: NSRect) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .left

        let font = NSFont.monospacedSystemFont(ofSize: isPreview ? 9 : 18, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: terminalColor,
            .paragraphStyle: paragraph
        ]

        let visibleHistory = renderedLines.suffix(isPreview ? 12 : 24)
        var output = visibleHistory.joined(separator: "\n")
        if !currentLine.isEmpty {
            if !output.isEmpty { output += "\n" }
            output += currentLine + "▌"
        }

        output.draw(in: rect, withAttributes: attributes)
    }

    private func drawVisuals(in rect: NSRect) {
        NSColor(calibratedWhite: 0.05, alpha: 1.0).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 6, yRadius: 6).fill()

        switch phase {
        case .tictactoe:
            drawTicTacToe(in: rect)
        case .thermonuclear:
            drawThermonuclearMap(in: rect)
        case .conclusion:
            drawConclusion(in: rect)
        }
    }

    private func drawTicTacToe(in rect: NSRect) {
        let side = min(rect.width, rect.height) * 0.76
        let board = NSRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
        let cell = side / 3
        let glow = 0.60 + (sin(CGFloat(phaseTick) * 0.15) + 1) * 0.20

        let linePath = NSBezierPath()
        linePath.lineWidth = isPreview ? 1.8 : 2.8
        terminalGlowColor.withAlphaComponent(glow).setStroke()
        for i in 1...2 {
            let offset = CGFloat(i) * cell
            linePath.move(to: NSPoint(x: board.minX + offset, y: board.minY))
            linePath.line(to: NSPoint(x: board.minX + offset, y: board.maxY))
            linePath.move(to: NSPoint(x: board.minX, y: board.minY + offset))
            linePath.line(to: NSPoint(x: board.maxX, y: board.minY + offset))
        }
        linePath.stroke()

        let moveSets: [[Int]] = [
            [0, 4, 8, 2, 6, 3, 5, 7, 1],
            [0, 4, 2, 1, 7, 6, 3, 5, 8],
            [4, 0, 8, 2, 6, 3, 1, 7, 5]
        ]
        let ticksPerGame = 198
        let gameIndex = (phaseTick / ticksPerGame) % moveSets.count
        let tickInGame = phaseTick % ticksPerGame
        let moves = moveSets[gameIndex]
        let visibleMoves = min(moves.count, max(0, tickInGame / 18 + 1))

        for index in 0..<visibleMoves {
            let marker: Character = index.isMultiple(of: 2) ? "X" : "O"
            let reveal = CGFloat(max(0, min(18, tickInGame - index * 18))) / 18.0
            let alpha = 0.30 + max(0.0, reveal) * 0.70
            drawMarker(marker, inCell: moves[index], board: board, cellSize: cell, alpha: alpha)
        }

        let sweepY = board.minY + board.height * CGFloat((phaseTick % 120)) / 120.0
        terminalGlowColor.withAlphaComponent(0.18).setFill()
        NSRect(x: board.minX, y: sweepY, width: board.width, height: isPreview ? 4 : 8).fill()
    }

    private func drawMarker(
        _ marker: Character,
        inCell cellIndex: Int,
        board: NSRect,
        cellSize: CGFloat,
        alpha: CGFloat = 1.0
    ) {
        let row = 2 - (cellIndex / 3)
        let col = cellIndex % 3

        let center = NSPoint(
            x: board.minX + (CGFloat(col) + 0.5) * cellSize,
            y: board.minY + (CGFloat(row) + 0.5) * cellSize
        )
        let radius = cellSize * 0.28

        let path = NSBezierPath()
        path.lineWidth = isPreview ? 1.5 : 2.2
        terminalGlowColor.withAlphaComponent(alpha).setStroke()

        if marker == "X" {
            path.move(to: NSPoint(x: center.x - radius, y: center.y - radius))
            path.line(to: NSPoint(x: center.x + radius, y: center.y + radius))
            path.move(to: NSPoint(x: center.x - radius, y: center.y + radius))
            path.line(to: NSPoint(x: center.x + radius, y: center.y - radius))
        } else {
            path.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
        }

        path.stroke()
    }

    private func drawThermonuclearMap(in rect: NSRect) {
        let frameRect = rect.insetBy(dx: 8, dy: 8)
        let frame = NSBezierPath(roundedRect: frameRect, xRadius: 8, yRadius: 8)
        terminalGlowColor.withAlphaComponent(0.45).setStroke()
        frame.lineWidth = isPreview ? 1.1 : 2
        frame.stroke()

        let outlines: [[NSPoint]] = [
            [NSPoint(x: 0.05, y: 0.60), NSPoint(x: 0.10, y: 0.68), NSPoint(x: 0.18, y: 0.73), NSPoint(x: 0.24, y: 0.71), NSPoint(x: 0.30, y: 0.61), NSPoint(x: 0.29, y: 0.52), NSPoint(x: 0.22, y: 0.48), NSPoint(x: 0.16, y: 0.50), NSPoint(x: 0.10, y: 0.54), NSPoint(x: 0.05, y: 0.60)],
            [NSPoint(x: 0.30, y: 0.45), NSPoint(x: 0.34, y: 0.41), NSPoint(x: 0.36, y: 0.31), NSPoint(x: 0.33, y: 0.20), NSPoint(x: 0.29, y: 0.25), NSPoint(x: 0.27, y: 0.35), NSPoint(x: 0.30, y: 0.45)],
            [NSPoint(x: 0.46, y: 0.62), NSPoint(x: 0.53, y: 0.69), NSPoint(x: 0.60, y: 0.71), NSPoint(x: 0.69, y: 0.70), NSPoint(x: 0.76, y: 0.67), NSPoint(x: 0.83, y: 0.63), NSPoint(x: 0.87, y: 0.58), NSPoint(x: 0.84, y: 0.53), NSPoint(x: 0.78, y: 0.50), NSPoint(x: 0.70, y: 0.53), NSPoint(x: 0.62, y: 0.56), NSPoint(x: 0.55, y: 0.57), NSPoint(x: 0.50, y: 0.55), NSPoint(x: 0.46, y: 0.62)],
            [NSPoint(x: 0.55, y: 0.52), NSPoint(x: 0.59, y: 0.48), NSPoint(x: 0.60, y: 0.40), NSPoint(x: 0.57, y: 0.29), NSPoint(x: 0.52, y: 0.22), NSPoint(x: 0.49, y: 0.30), NSPoint(x: 0.50, y: 0.42), NSPoint(x: 0.55, y: 0.52)],
            [NSPoint(x: 0.83, y: 0.28), NSPoint(x: 0.88, y: 0.30), NSPoint(x: 0.90, y: 0.26), NSPoint(x: 0.87, y: 0.22), NSPoint(x: 0.82, y: 0.24), NSPoint(x: 0.83, y: 0.28)],
            [NSPoint(x: 0.32, y: 0.74), NSPoint(x: 0.36, y: 0.81), NSPoint(x: 0.40, y: 0.78), NSPoint(x: 0.38, y: 0.72), NSPoint(x: 0.32, y: 0.74)]
        ]

        for shape in outlines {
            let path = NSBezierPath()
            path.lineWidth = isPreview ? 1.1 : 1.8
            for (index, point) in shape.enumerated() {
                let mapped = mapPoint(point, in: frameRect)
                if index == 0 { path.move(to: mapped) } else { path.line(to: mapped) }
            }
            terminalGlowColor.withAlphaComponent(0.42).setStroke()
            path.stroke()
        }

        let strategicNodes: [(CGFloat, CGFloat, NSColor)] = [
            (0.21, 0.57, terminalGlowColor),
            (0.17, 0.64, terminalGlowColor),
            (0.30, 0.60, terminalGlowColor),
            (0.34, 0.58, terminalGlowColor),
            (0.64, 0.62, hostileColor),
            (0.62, 0.66, hostileColor),
            (0.58, 0.58, hostileColor),
            (0.52, 0.60, terminalGlowColor)
        ]

        for node in strategicNodes {
            let point = mapPoint(NSPoint(x: node.0, y: node.1), in: frameRect)
            let dot = NSBezierPath(ovalIn: NSRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4))
            node.2.withAlphaComponent(0.85).setFill()
            dot.fill()
        }

        let routes: [(Int, Int, NSColor, CGFloat)] = [
            (0, 4, brightTrailColor, 0.23), (1, 5, brightTrailColor, 0.28), (2, 4, brightTrailColor, 0.18), (3, 6, brightTrailColor, 0.16),
            (4, 0, brightTrailColor, 0.22), (5, 1, brightTrailColor, 0.25), (6, 2, brightTrailColor, 0.18), (4, 3, brightTrailColor, 0.14),
            (4, 7, hostileColor, 0.11), (6, 7, hostileColor, 0.10), (7, 4, brightTrailColor, 0.10)
        ]

        for (index, route) in routes.enumerated() {
            let startTick = index * 8
            let progress = clamp(CGFloat(phaseTick - startTick) / 42.0)
            guard progress > 0 else { continue }

            let from = mapPoint(NSPoint(x: strategicNodes[route.0].0, y: strategicNodes[route.0].1), in: frameRect)
            let to = mapPoint(NSPoint(x: strategicNodes[route.1].0, y: strategicNodes[route.1].1), in: frameRect)
            drawRoute(from: from, to: to, progress: progress, color: route.2, arcHeight: route.3 * rect.height)

            if progress >= 0.95 {
                let impact = NSBezierPath(ovalIn: NSRect(x: to.x - 5, y: to.y - 5, width: 10, height: 10))
                let pulse = 0.45 + (sin(CGFloat(phaseTick) * 0.22) + 1) * 0.20
                route.2.withAlphaComponent(pulse).setStroke()
                impact.lineWidth = 1.4
                impact.stroke()
            }
        }

        let streaks: [(CGFloat, Int, NSColor)] = [
            (0.56, 4, brightTrailColor), (0.60, 5, brightTrailColor), (0.63, 6, brightTrailColor),
            (0.70, 5, brightTrailColor), (0.76, 4, brightTrailColor), (0.84, 3, brightTrailColor)
        ]
        for streak in streaks {
            let travel = CGFloat((phaseTick * streak.1) % Int(rect.height + 120))
            let top = frameRect.maxY - travel
            guard top > frameRect.minY - 35 else { continue }

            let x = frameRect.minX + frameRect.width * streak.0
            let path = NSBezierPath()
            path.lineWidth = isPreview ? 1.6 : 2.5
            path.move(to: NSPoint(x: x, y: top))
            path.line(to: NSPoint(x: x - 8, y: top - (isPreview ? 18 : 34)))
            streak.2.withAlphaComponent(0.78).setStroke()
            path.stroke()
        }
    }

    private func drawConclusion(in rect: NSRect) {
        terminalColor.withAlphaComponent(0.22).setFill()
        let globeRect = NSRect(x: rect.midX - rect.height * 0.24, y: rect.midY - rect.height * 0.24,
                               width: rect.height * 0.48, height: rect.height * 0.48)
        NSBezierPath(ovalIn: globeRect).fill()

        terminalColor.withAlphaComponent(0.9).setStroke()
        let slash = NSBezierPath()
        slash.lineWidth = isPreview ? 2 : 4
        slash.move(to: NSPoint(x: globeRect.minX + 4, y: globeRect.maxY - 4))
        slash.line(to: NSPoint(x: globeRect.maxX - 4, y: globeRect.minY + 4))
        slash.stroke()

        let text = "NO WINNING MOVE"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: isPreview ? 10 : 18, weight: .bold),
            .foregroundColor: terminalColor
        ]
        let size = text.size(withAttributes: attrs)
        let origin = NSPoint(x: rect.midX - size.width / 2, y: rect.minY + rect.height * 0.12)
        text.draw(at: origin, withAttributes: attrs)
    }

    private func mapPoint(_ point: NSPoint, in rect: NSRect) -> NSPoint {
        NSPoint(x: rect.minX + rect.width * point.x, y: rect.minY + rect.height * point.y)
    }

    private func drawRoute(from: NSPoint, to: NSPoint, progress: CGFloat, color: NSColor, arcHeight: CGFloat) {
        let steps = max(2, Int(50 * progress))
        let path = NSBezierPath()
        path.lineWidth = isPreview ? 1.5 : 2.2

        for step in 0...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let point = pointOnArc(from: from, to: to, t: t, arcHeight: arcHeight)
            if step == 0 { path.move(to: point) } else { path.line(to: point) }
        }

        color.withAlphaComponent(0.80).setStroke()
        path.stroke()
    }

    private func pointOnArc(from: NSPoint, to: NSPoint, t: CGFloat, arcHeight: CGFloat) -> NSPoint {
        let midX = (from.x + to.x) * 0.5
        let midY = (from.y + to.y) * 0.5 + arcHeight
        let oneMinusT = 1 - t

        let x = oneMinusT * oneMinusT * from.x + 2 * oneMinusT * t * midX + t * t * to.x
        let y = oneMinusT * oneMinusT * from.y + 2 * oneMinusT * t * midY + t * t * to.y
        return NSPoint(x: x, y: y)
    }

    private func clamp(_ value: CGFloat) -> CGFloat {
        min(1, max(0, value))
    }

    private func updatePhase(forCompletedLine line: String) {
        if line == "SIMULATION: GLOBAL THERMONUCLEAR WAR" {
            phase = .thermonuclear
            phaseTick = 0
        } else if line == "STRANGE GAME." {
            phase = .conclusion
            phaseTick = 0
        }
    }

    private func resetScenario() {
        renderedLines.removeAll(keepingCapacity: true)
        lineIndex = 0
        characterIndex = 0
        currentLine = ""
        holdTicks = 0
        phase = .tictactoe
        phaseTick = 0

        script = buildScript()
    }

    private func buildScript() -> [String] {
        var lines: [String] = [
            "FALKEN STRATEGIC PROGRAM INITIALIZING...",
            "CONNECTED: NORAD COMMAND SYSTEM",
            "",
            "SIMULATION: TIC-TAC-TOE"
        ]

        lines.append(contentsOf: ticTacToeExchange())

        lines.append(contentsOf: [
            "",
            "UNSUCCESSFUL OUTCOMES DETECTED.",
            "",
            "SIMULATION: GLOBAL THERMONUCLEAR WAR"
        ])

        lines.append(contentsOf: thermonuclearExchange())

        lines.append(contentsOf: [
            "",
            "STRANGE GAME.",
            "THE ONLY WINNING MOVE IS NOT TO PLAY.",
            "CONCLUSION: GIVING UP.",
            "",
            "RESTARTING STRATEGIC EVALUATION..."
        ])

        return lines
    }

    private func ticTacToeExchange() -> [String] {
        let games = [
            ["XOX", "OXO", "OXX"],
            ["XOX", "OOX", "XXO"],
            ["OXO", "XXO", "XOX"]
        ]

        var lines: [String] = []
        for (index, board) in games.enumerated() {
            lines.append("GAME \(index + 1):")
            lines.append(contentsOf: board)
            lines.append("RESULT: DRAW")
            lines.append("")
        }

        return lines
    }

    private func thermonuclearExchange() -> [String] {
        let cities = [
            "LAS VEGAS", "SEATTLE", "CHICAGO", "NEW YORK",
            "MOSCOW", "LENINGRAD", "KYIV", "LONDON"
        ]

        var lines: [String] = [
            "ESTIMATING FIRST STRIKE OPTIONS...",
            "RUNNING ITERATION MATRIX..."
        ]

        for city in cities {
            lines.append("TARGET: \(city) -> COUNTERSTRIKE DETECTED")
        }

        lines.append("FINAL STATE: MUTUAL ASSURED DESTRUCTION")
        lines.append("SURVIVAL PROBABILITY: 0.0%")
        return lines
    }
}
