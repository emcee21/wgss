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
        terminalColor.withAlphaComponent(0.85).setStroke()

        let side = min(rect.width, rect.height) * 0.80
        let board = NSRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side)
        let cell = side / 3

        let linePath = NSBezierPath()
        linePath.lineWidth = isPreview ? 1.5 : 2.5
        for i in 1...2 {
            let offset = CGFloat(i) * cell
            linePath.move(to: NSPoint(x: board.minX + offset, y: board.minY))
            linePath.line(to: NSPoint(x: board.minX + offset, y: board.maxY))
            linePath.move(to: NSPoint(x: board.minX, y: board.minY + offset))
            linePath.line(to: NSPoint(x: board.maxX, y: board.minY + offset))
        }
        linePath.stroke()

        let moves: [(Int, Character)] = [
            (0, "X"), (4, "O"), (8, "X"), (2, "O"),
            (6, "X"), (3, "O"), (5, "X"), (7, "O"), (1, "X")
        ]

        let visibleMoves = min(moves.count, max(0, phaseTick / 20 + 1))
        for index in 0..<visibleMoves {
            let (cellIndex, marker) = moves[index]
            drawMarker(marker, inCell: cellIndex, board: board, cellSize: cell)
        }
    }

    private func drawMarker(_ marker: Character, inCell cellIndex: Int, board: NSRect, cellSize: CGFloat) {
        let row = 2 - (cellIndex / 3)
        let col = cellIndex % 3

        let center = NSPoint(
            x: board.minX + (CGFloat(col) + 0.5) * cellSize,
            y: board.minY + (CGFloat(row) + 0.5) * cellSize
        )
        let radius = cellSize * 0.28

        let path = NSBezierPath()
        path.lineWidth = isPreview ? 1.5 : 2.2
        terminalColor.setStroke()

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
        let frame = NSBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), xRadius: 8, yRadius: 8)
        terminalColor.withAlphaComponent(0.6).setStroke()
        frame.lineWidth = isPreview ? 1.2 : 2
        frame.stroke()

        let scanAlpha = 0.08 + (sin(CGFloat(phaseTick) * 0.08) + 1) * 0.10
        terminalColor.withAlphaComponent(scanAlpha).setFill()
        let scanY = rect.minY + (rect.height * CGFloat((phaseTick % 180)) / 180.0)
        NSRect(x: rect.minX + 10, y: scanY, width: rect.width - 20, height: isPreview ? 5 : 9).fill()

        let continent1 = NSBezierPath(roundedRect: NSRect(x: rect.minX + rect.width * 0.16,
                                                          y: rect.minY + rect.height * 0.46,
                                                          width: rect.width * 0.22,
                                                          height: rect.height * 0.24), xRadius: 14, yRadius: 14)
        let continent2 = NSBezierPath(roundedRect: NSRect(x: rect.minX + rect.width * 0.54,
                                                          y: rect.minY + rect.height * 0.40,
                                                          width: rect.width * 0.30,
                                                          height: rect.height * 0.28), xRadius: 16, yRadius: 16)
        terminalColor.withAlphaComponent(0.18).setFill()
        continent1.fill()
        continent2.fill()

        let targets: [(String, CGFloat, CGFloat)] = [
            ("LAS VEGAS", 0.23, 0.54),
            ("SEATTLE", 0.19, 0.62),
            ("CHICAGO", 0.31, 0.58),
            ("NEW YORK", 0.35, 0.56),
            ("MOSCOW", 0.62, 0.59),
            ("LENINGRAD", 0.60, 0.62),
            ("KYIV", 0.58, 0.55),
            ("LONDON", 0.52, 0.58)
        ]

        let visibleTargets = min(targets.count, max(0, phaseTick / 18 + 1))
        let pulse = 0.6 + (sin(CGFloat(phaseTick) * 0.2) + 1) * 0.2

        for index in 0..<visibleTargets {
            let (_, xFactor, yFactor) = targets[index]
            let point = NSPoint(x: rect.minX + rect.width * xFactor, y: rect.minY + rect.height * yFactor)

            terminalColor.withAlphaComponent(pulse).setStroke()
            let ring = NSBezierPath()
            ring.lineWidth = isPreview ? 1.2 : 1.8
            ring.appendArc(withCenter: point, radius: isPreview ? 4 : 7, startAngle: 0, endAngle: 360)
            ring.stroke()

            let cross = NSBezierPath()
            cross.lineWidth = 1
            cross.move(to: NSPoint(x: point.x - 6, y: point.y))
            cross.line(to: NSPoint(x: point.x + 6, y: point.y))
            cross.move(to: NSPoint(x: point.x, y: point.y - 6))
            cross.line(to: NSPoint(x: point.x, y: point.y + 6))
            cross.stroke()
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
