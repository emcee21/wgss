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
        }

        needsDisplay = true
    }

    override func draw(_ rect: NSRect) {
        backgroundColor.setFill()
        rect.fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = .left

        let font = NSFont.monospacedSystemFont(ofSize: isPreview ? 9 : 18, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: terminalColor,
            .paragraphStyle: paragraph
        ]

        let visibleHistory = renderedLines.suffix(isPreview ? 16 : 34)
        var output = visibleHistory.joined(separator: "\n")
        if !currentLine.isEmpty {
            if !output.isEmpty { output += "\n" }
            output += currentLine + "▌"
        }

        let inset: CGFloat = isPreview ? 8 : 24
        let drawRect = rect.insetBy(dx: inset, dy: inset)
        output.draw(in: drawRect, withAttributes: attributes)
    }

    private func resetScenario() {
        renderedLines.removeAll(keepingCapacity: true)
        lineIndex = 0
        characterIndex = 0
        currentLine = ""
        holdTicks = 0

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
