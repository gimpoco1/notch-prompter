import Cocoa
import SwiftUI
import Combine
import AVFoundation

struct PrompterConfig: Codable {
  var text: String
  var speed: Double
  var fontSize: Double
  var width: Double
  var height: Double
  var opacity: Double
  var paddingX: Double
  var paddingY: Double
  var mode: String
  var notchWidth: Double
  var notchHeight: Double
  var notchRadius: Double
  var panelRadius: Double
  var dockOffset: Double
  var running: Bool
  var voiceControlEnabled: Bool
  var voiceSensitivity: Double

  init(
    text: String,
    speed: Double,
    fontSize: Double,
    width: Double,
    height: Double,
    opacity: Double,
    paddingX: Double,
    paddingY: Double,
    mode: String,
    notchWidth: Double,
    notchHeight: Double,
    notchRadius: Double,
    panelRadius: Double,
    dockOffset: Double,
    running: Bool,
    voiceControlEnabled: Bool,
    voiceSensitivity: Double
  ) {
    self.text = text
    self.speed = speed
    self.fontSize = fontSize
    self.width = width
    self.height = height
    self.opacity = opacity
    self.paddingX = paddingX
    self.paddingY = paddingY
    self.mode = mode
    self.notchWidth = notchWidth
    self.notchHeight = notchHeight
    self.notchRadius = notchRadius
    self.panelRadius = panelRadius
    self.dockOffset = dockOffset
    self.running = running
    self.voiceControlEnabled = voiceControlEnabled
    self.voiceSensitivity = voiceSensitivity
  }

  static let `default` = PrompterConfig(
    text: "",
    speed: 28,
    fontSize: 22,
    width: 520,
    height: 72,
    opacity: 1,
    paddingX: 18,
    paddingY: 12,
    mode: "loop",
    notchWidth: 220,
    notchHeight: 28,
    notchRadius: 14,
    panelRadius: 26,
    dockOffset: 0,
    running: true,
    voiceControlEnabled: false,
    voiceSensitivity: 0.6
  )

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let fallback = PrompterConfig.default

    text = try container.decodeIfPresent(String.self, forKey: .text) ?? fallback.text
    speed = try container.decodeIfPresent(Double.self, forKey: .speed) ?? fallback.speed
    fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? fallback.fontSize
    width = try container.decodeIfPresent(Double.self, forKey: .width) ?? fallback.width
    height = try container.decodeIfPresent(Double.self, forKey: .height) ?? fallback.height
    opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? fallback.opacity
    paddingX = try container.decodeIfPresent(Double.self, forKey: .paddingX) ?? fallback.paddingX
    paddingY = try container.decodeIfPresent(Double.self, forKey: .paddingY) ?? fallback.paddingY
    mode = try container.decodeIfPresent(String.self, forKey: .mode) ?? fallback.mode
    notchWidth = try container.decodeIfPresent(Double.self, forKey: .notchWidth) ?? fallback.notchWidth
    notchHeight = try container.decodeIfPresent(Double.self, forKey: .notchHeight) ?? fallback.notchHeight
    notchRadius = try container.decodeIfPresent(Double.self, forKey: .notchRadius) ?? fallback.notchRadius
    panelRadius = try container.decodeIfPresent(Double.self, forKey: .panelRadius) ?? fallback.panelRadius
    dockOffset = try container.decodeIfPresent(Double.self, forKey: .dockOffset) ?? fallback.dockOffset
    running = try container.decodeIfPresent(Bool.self, forKey: .running) ?? fallback.running
    voiceControlEnabled = try container.decodeIfPresent(Bool.self, forKey: .voiceControlEnabled) ?? fallback.voiceControlEnabled
    voiceSensitivity = try container.decodeIfPresent(Double.self, forKey: .voiceSensitivity) ?? fallback.voiceSensitivity
  }

  static func load(from path: String) -> PrompterConfig {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
      return .default
    }
    let decoder = JSONDecoder()
    if let config = try? decoder.decode(PrompterConfig.self, from: data) {
      return config
    }
    return .default
  }
}

func loadConfig() -> PrompterConfig {
  if let bundled = Bundle.main.url(forResource: "config", withExtension: "json")?.path {
    let config = PrompterConfig.load(from: bundled)
    return config
  }

  let cwd = FileManager.default.currentDirectoryPath
  let configPath = URL(fileURLWithPath: cwd).appendingPathComponent("config.json").path
  return PrompterConfig.load(from: configPath)
}

enum ScrollMode: String, CaseIterable, Identifiable {
  case start
  case loop
  case stop

  var id: String { rawValue }

  var label: String {
    switch self {
    case .start:
      return "Start at Top"
    case .loop:
      return "Loop"
    case .stop:
      return "Stop at End"
    }
  }
}

final class PrompterState: ObservableObject {
  @Published var text: String
  @Published var speed: Double
  @Published var fontSize: Double
  @Published var width: Double
  @Published var height: Double
  @Published var opacity: Double
  @Published var paddingX: Double
  @Published var paddingY: Double
  @Published var mode: ScrollMode
  @Published var notchWidth: Double
  @Published var notchHeight: Double
  @Published var notchRadius: Double
  @Published var panelRadius: Double
  @Published var dockOffset: Double
  @Published var running: Bool
  @Published var showOverlayControls: Bool = false
  @Published var voiceControlEnabled: Bool
  @Published var voiceSensitivity: Double
  @Published var voiceLevel: Double = 0
  @Published var voiceActive: Bool = false

  init(config: PrompterConfig) {
    self._text = Published(initialValue: config.text)
    self._speed = Published(initialValue: config.speed)
    self._fontSize = Published(initialValue: config.fontSize)
    self._width = Published(initialValue: config.width)
    self._height = Published(initialValue: config.height)
    self._opacity = Published(initialValue: config.opacity)
    self._paddingX = Published(initialValue: config.paddingX)
    self._paddingY = Published(initialValue: config.paddingY)
    self._mode = Published(initialValue: ScrollMode(rawValue: config.mode) ?? .loop)
    self._notchWidth = Published(initialValue: config.notchWidth)
    self._notchHeight = Published(initialValue: config.notchHeight)
    self._notchRadius = Published(initialValue: config.notchRadius)
    self._panelRadius = Published(initialValue: config.panelRadius)
    self._dockOffset = Published(initialValue: config.dockOffset)
    self._running = Published(initialValue: config.running)
    self._voiceControlEnabled = Published(initialValue: config.voiceControlEnabled)
    self._voiceSensitivity = Published(initialValue: config.voiceSensitivity)
  }

  func autoFitNotch() {
    guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
    var computedWidth: CGFloat = 220
    var computedHeight: CGFloat = 28
    let widthInset: CGFloat = 4
    let heightInset: CGFloat = 1

    if #available(macOS 12.0, *) {
      if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
        let totalWidth = screen.frame.width
        let notch = totalWidth - left.width - right.width
        if notch > 0 {
          computedWidth = notch
        }
      }
      let safeTop = screen.safeAreaInsets.top
      let menuBarHeight = max(0, screen.frame.maxY - screen.visibleFrame.maxY)
      let heightCandidates = [safeTop, menuBarHeight].filter { $0 > 0 }
      if let best = heightCandidates.min() {
        computedHeight = best
      }
    } else {
      let menuBarHeight = max(0, screen.frame.maxY - screen.visibleFrame.maxY)
      if menuBarHeight > 0 {
        computedHeight = menuBarHeight
      }
    }

    let scale = screen.backingScaleFactor
    func roundToPixel(_ value: CGFloat) -> CGFloat {
      guard scale > 0 else { return value }
      return (value * scale).rounded(.toNearestOrAwayFromZero) / scale
    }

    let fittedWidth = roundToPixel(max(140, computedWidth - widthInset))
    let fittedHeight = roundToPixel(max(10, computedHeight - heightInset))

    notchWidth = Double(fittedWidth)
    notchHeight = Double(fittedHeight)
    notchRadius = max(8, Double(fittedHeight * 0.5))
  }
}

final class VoiceActivityMonitor: ObservableObject {
  @Published var level: Double = 0
  @Published var isActive: Bool = false

  var sensitivity: Double = 0.6

  private var engine: AVAudioEngine?
  private var lastActiveTime = Date.distantPast
  private let holdDuration: TimeInterval = 0.35
  private var running = false

  func start() {
    guard !running else { return }
    running = true
    AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
      DispatchQueue.main.async {
        guard let self else { return }
        if granted {
          self.startEngine()
        } else {
          self.level = 0
          self.isActive = false
        }
      }
    }
  }

  func stop() {
    running = false
    if let engine {
      engine.inputNode.removeTap(onBus: 0)
      engine.stop()
    }
    engine = nil
    level = 0
    isActive = false
  }

  private func startEngine() {
    let engine = AVAudioEngine()
    let input = engine.inputNode
    let format = input.inputFormat(forBus: 0)
    let bufferSize: AVAudioFrameCount = 1024

    input.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
      self?.process(buffer: buffer)
    }

    do {
      try engine.start()
      self.engine = engine
    } catch {
      level = 0
      isActive = false
    }
  }

  private func process(buffer: AVAudioPCMBuffer) {
    guard let channelData = buffer.floatChannelData?[0] else { return }
    let frameLength = Int(buffer.frameLength)
    if frameLength == 0 { return }

    var sum: Float = 0
    for i in 0..<frameLength {
      let sample = channelData[i]
      sum += sample * sample
    }
    let mean = sum / Float(frameLength)
    let rms = sqrt(mean)
    let db = rms > 0 ? 20 * log10(rms) : -100

    let clampedDb = max(-60, min(-20, Double(db)))
    let normalized = (clampedDb + 60) / 40
    let nextLevel = max(0, min(1, normalized))

    let (activeThreshold, inactiveThreshold) = thresholds(for: sensitivity)
    let now = Date()
    var active = isActive

    if Double(db) >= activeThreshold {
      active = true
      lastActiveTime = now
    } else if Double(db) <= inactiveThreshold && now.timeIntervalSince(lastActiveTime) > holdDuration {
      active = false
    }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.level = (self.level * 0.6) + (nextLevel * 0.4)
      self.isActive = active
    }
  }

  private func thresholds(for sensitivity: Double) -> (Double, Double) {
    let clamped = max(0.2, min(1, sensitivity))
    let active = -46 + (clamped * 18)
    let inactive = active - 8
    return (active, inactive)
  }
}

struct NotchShape: Shape {
  var notchWidth: CGFloat
  var notchHeight: CGFloat
  var notchRadius: CGFloat
  var topCornerRadius: CGFloat
  var bottomCornerRadius: CGFloat

  func path(in rect: CGRect) -> Path {
    let width = rect.width
    let height = rect.height

    let topCorner = min(topCornerRadius, min(width, height) / 2)
    let bottomCorner = min(bottomCornerRadius, min(width, height) / 2)
    let notchW = min(max(140, notchWidth), width - bottomCorner * 2 - 24)
    let notchH = min(max(10, notchHeight), height - bottomCorner - 4)
    let notchR = min(max(6, notchRadius), min(notchH, notchW / 3))

    let leftNotch = (width - notchW) / 2
    let rightNotch = leftNotch + notchW

    var path = Path()
    path.move(to: CGPoint(x: topCorner, y: 0))
    path.addLine(to: CGPoint(x: leftNotch, y: 0))
    path.addLine(to: CGPoint(x: leftNotch, y: notchH - notchR))
    path.addArc(center: CGPoint(x: leftNotch + notchR, y: notchH - notchR), radius: notchR, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
    path.addLine(to: CGPoint(x: rightNotch - notchR, y: notchH))
    path.addArc(center: CGPoint(x: rightNotch - notchR, y: notchH - notchR), radius: notchR, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
    path.addLine(to: CGPoint(x: rightNotch, y: 0))
    path.addLine(to: CGPoint(x: width - topCorner, y: 0))
    if topCorner > 0 {
      path.addArc(center: CGPoint(x: width - topCorner, y: topCorner), radius: topCorner, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
    } else {
      path.addLine(to: CGPoint(x: width, y: 0))
    }
    path.addLine(to: CGPoint(x: width, y: height - bottomCorner))
    if bottomCorner > 0 {
      path.addArc(center: CGPoint(x: width - bottomCorner, y: height - bottomCorner), radius: bottomCorner, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
    }
    path.addLine(to: CGPoint(x: bottomCorner, y: height))
    if bottomCorner > 0 {
      path.addArc(center: CGPoint(x: bottomCorner, y: height - bottomCorner), radius: bottomCorner, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
    }
    path.addLine(to: CGPoint(x: 0, y: topCorner))
    if topCorner > 0 {
      path.addArc(center: CGPoint(x: topCorner, y: topCorner), radius: topCorner, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
    }
    path.closeSubpath()
    return path
  }
}

struct TextHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

struct ContainerHeightKey: PreferenceKey {
  static var defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

struct NotchOverlayView: View {
  @ObservedObject var state: PrompterState
  @State private var offset: CGFloat = 0
  @State private var textHeight: CGFloat = 0
  @State private var containerHeight: CGFloat = 0
  @State private var lastTick = Date()
  @State private var reachedEnd = false

  private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

  private func startOffset() -> CGFloat {
    if state.mode == .start {
      return 0
    }
    return containerHeight
  }

  private func endOffset() -> CGFloat {
    if state.mode == .start {
      return min(0, containerHeight - textHeight)
    }
    return -textHeight
  }

  private func resetScroll() {
    reachedEnd = false
    offset = startOffset()
    lastTick = Date()
  }

  var body: some View {
    GeometryReader { geo in
      let shape = NotchShape(
        notchWidth: CGFloat(state.notchWidth),
        notchHeight: CGFloat(state.notchHeight),
        notchRadius: CGFloat(state.notchRadius),
        topCornerRadius: 0,
        bottomCornerRadius: CGFloat(state.panelRadius)
      )

      let fadeHeight = max(8.0, min(26.0, geo.size.height * 0.25))
      let fadeStop = min(0.35, fadeHeight / max(1, geo.size.height))
      let fadeMask = LinearGradient(
        stops: [
          .init(color: Color.black.opacity(0), location: 0),
          .init(color: Color.black.opacity(1), location: fadeStop),
          .init(color: Color.black.opacity(1), location: 1)
        ],
        startPoint: .top,
        endPoint: .bottom
      )

      ZStack(alignment: .topTrailing) {
        shape
          .fill(Color.black.opacity(state.opacity))
          .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
          .shadow(color: Color.blue.opacity(0.18), radius: 26, x: 0, y: 0)

        VoiceGlowView(level: state.voiceLevel, isActive: state.voiceControlEnabled && state.voiceActive)
          .opacity(state.voiceControlEnabled ? 1 : 0)

        Text(state.text.isEmpty ? "Paste your script in the control window." : state.text)
          .font(.system(size: state.fontSize, weight: .regular, design: .monospaced))
          .foregroundColor(.white)
          .lineSpacing(4)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .background(
            GeometryReader { textGeo in
              Color.clear.preference(key: TextHeightKey.self, value: textGeo.size.height)
            }
          )
          .offset(y: offset)
          .padding(.horizontal, state.paddingX)
          .padding(.vertical, state.paddingY)
          .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
          .mask(fadeMask)

        Button(action: { state.running.toggle() }) {
          Image(systemName: state.running ? "pause.fill" : "play.fill")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 26, height: 26)
            .background(Color.black.opacity(0.55))
            .clipShape(Circle())
            .overlay(
              Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
        .padding(.trailing, 8)
        .opacity(state.showOverlayControls ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: state.showOverlayControls)
        .allowsHitTesting(state.showOverlayControls)
      }
      .clipShape(shape)
      .background(
        GeometryReader { sizeGeo in
          Color.clear.preference(key: ContainerHeightKey.self, value: sizeGeo.size.height - CGFloat(state.paddingY * 2))
        }
      )
    }
    .onPreferenceChange(TextHeightKey.self) { value in
      textHeight = value
      resetScroll()
    }
    .onPreferenceChange(ContainerHeightKey.self) { value in
      containerHeight = max(0, value)
      resetScroll()
    }
    .onReceive(state.$text) { _ in resetScroll() }
    .onReceive(state.$mode) { _ in resetScroll() }
    .onReceive(state.$fontSize) { _ in resetScroll() }
    .onReceive(state.$paddingY) { _ in resetScroll() }
    .onReceive(timer) { now in
      if !state.running {
        lastTick = now
        return
      }
      let dt = now.timeIntervalSince(lastTick)
      lastTick = now

      if reachedEnd { return }

      offset -= CGFloat(state.speed) * CGFloat(dt)
      let endY = endOffset()
      if offset <= endY {
        if state.mode == .loop {
          offset = startOffset()
        } else {
          offset = endY
          reachedEnd = true
        }
      }
    }
  }
}

struct VoiceGlowView: View {
  var level: Double
  var isActive: Bool
  @State private var pulse = false

  var body: some View {
    GeometryReader { geo in
      let intensity = max(0, min(1, level))
      let baseWidth = geo.size.width * (0.55 + 0.25 * CGFloat(intensity))
      let baseHeight = geo.size.height * (0.6 + 0.4 * CGFloat(intensity))
      let yPos = geo.size.height * 0.6
      let opacity = isActive ? (0.15 + 0.65 * intensity) : 0

      Ellipse()
        .fill(
          RadialGradient(
            colors: [
              Color.blue.opacity(0.55),
              Color.blue.opacity(0.15),
              Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: max(40, baseWidth * 0.6)
          )
        )
        .frame(width: baseWidth, height: baseHeight)
        .position(x: geo.size.width / 2, y: yPos)
        .blur(radius: 16)
        .opacity(opacity)
        .scaleEffect(pulse ? 1.05 : 0.96)
        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
        .onAppear { pulse = isActive }
        .onChange(of: isActive) { active in
          pulse = active
        }
    }
    .allowsHitTesting(false)
  }
}

struct ControlTheme {
  static let background = Color.black.opacity(0.92)
  static let card = Color.white.opacity(0.06)
  static let border = Color.white.opacity(0.12)
  static let textSecondary = Color.white.opacity(0.55)
  static let accent = Color.cyan.opacity(0.85)
}

struct SectionCard<Content: View>: View {
  let title: String
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundColor(ControlTheme.textSecondary)
        .textCase(.uppercase)
      content()
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(ControlTheme.card)
        .overlay(
          RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(ControlTheme.border, lineWidth: 1)
        )
    )
  }
}

struct SliderRow: View {
  let title: String
  let valueText: String
  let range: ClosedRange<Double>
  let step: Double
  @Binding var value: Double

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title)
        Spacer()
        Text(valueText)
          .foregroundColor(ControlTheme.textSecondary)
      }
      .font(.subheadline)
      Slider(value: $value, in: range, step: step)
        .tint(ControlTheme.accent)
    }
  }
}

struct ControlView: View {
  @ObservedObject var state: PrompterState
  @State private var scriptHeight: CGFloat = 260
  @State private var scriptHeightStart: CGFloat = 260

  private func pasteFromClipboard() {
    if let text = NSPasteboard.general.string(forType: .string) {
      state.text = text
    }
  }

  private func clearScript() {
    state.text = ""
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Notch Prompter")
              .font(.title3.weight(.semibold))
            Text("Minimal prompter controls.")
              .foregroundColor(ControlTheme.textSecondary)
          }
          Spacer()
          Button(state.running ? "Pause" : "Resume") {
            state.running.toggle()
          }
          .buttonStyle(.bordered)
          .tint(ControlTheme.accent)
        }

        HStack(alignment: .top, spacing: 18) {
          VStack(alignment: .leading, spacing: 12) {
            SectionCard(title: "Script") {
              ZStack(alignment: .topLeading) {
                TextEditor(text: $state.text)
                  .font(.system(size: 15, design: .monospaced))
                  .frame(minHeight: 180, maxHeight: 520)
                  .frame(height: scriptHeight)
                  .scrollContentBackground(.hidden)
                  .background(Color.white.opacity(0.04))
                  .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                  .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                      .stroke(ControlTheme.border, lineWidth: 1)
                  )
                if state.text.isEmpty {
                  Text("Paste or type your script here...")
                    .foregroundColor(ControlTheme.textSecondary)
                    .padding(.top, 10)
                    .padding(.leading, 8)
                }
              }

              Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 4)
                .cornerRadius(2)
                .overlay(
                  Rectangle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 36, height: 4)
                    .cornerRadius(2)
                )
                .gesture(
                  DragGesture()
                    .onChanged { value in
                      let next = scriptHeightStart + value.translation.height
                      scriptHeight = min(max(180, next), 520)
                    }
                    .onEnded { _ in
                      scriptHeightStart = scriptHeight
                    }
                )
                .padding(.top, 2)

              HStack {
                Button("Paste") { pasteFromClipboard() }
                Button("Clear") { clearScript() }
                Spacer()
                Text("\(state.text.count) chars")
                  .font(.caption)
                  .foregroundColor(ControlTheme.textSecondary)
              }
            }
          }

          VStack(alignment: .leading, spacing: 12) {
            SectionCard(title: "Playback") {
              SliderRow(
                title: "Speed",
                valueText: "\(Int(state.speed)) px/s",
                range: 8...120,
                step: 1,
                value: $state.speed
              )
              VStack(alignment: .leading, spacing: 8) {
                Text("Scroll Mode")
                  .font(.subheadline)
                Picker("Mode", selection: $state.mode) {
                  ForEach(ScrollMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                  }
                }
                .pickerStyle(.segmented)
              }
            }

            SectionCard(title: "Voice") {
              Toggle("Voice Control", isOn: $state.voiceControlEnabled)
                .toggleStyle(SwitchToggleStyle(tint: ControlTheme.accent))
              SliderRow(
                title: "Sensitivity",
                valueText: String(format: "%.2f", state.voiceSensitivity),
                range: 0.2...1.0,
                step: 0.02,
                value: $state.voiceSensitivity
              )
              Text("Auto-play while speaking, pause when silent.")
                .font(.caption)
                .foregroundColor(ControlTheme.textSecondary)
            }

            SectionCard(title: "Typography") {
              SliderRow(
                title: "Font Size",
                valueText: "\(Int(state.fontSize)) px",
                range: 14...42,
                step: 1,
                value: $state.fontSize
              )
            }

            SectionCard(title: "Overlay") {
              SliderRow(
                title: "Width",
                valueText: "\(Int(state.width)) px",
                range: 260...980,
                step: 1,
                value: $state.width
              )
              SliderRow(
                title: "Height",
                valueText: "\(Int(state.height)) px",
                range: 56...160,
                step: 1,
                value: $state.height
              )
              SliderRow(
                title: "Opacity",
                valueText: String(format: "%.2f", state.opacity),
                range: 0.4...1,
                step: 0.02,
                value: $state.opacity
              )
            }

            SectionCard(title: "Notch") {
              SliderRow(
                title: "Notch Width",
                valueText: "\(Int(state.notchWidth)) px",
                range: 180...360,
                step: 1,
                value: $state.notchWidth
              )
              SliderRow(
                title: "Notch Height",
                valueText: "\(Int(state.notchHeight)) px",
                range: 12...48,
                step: 1,
                value: $state.notchHeight
              )
              SliderRow(
                title: "Dock Offset",
                valueText: "\(Int(state.dockOffset)) px",
                range: -12...16,
                step: 1,
                value: $state.dockOffset
              )
              Button("Auto-fit Notch") {
                state.autoFitNotch()
              }
              .buttonStyle(.bordered)
              .tint(ControlTheme.accent)
            }
          }
          .frame(width: 320)
        }
      }
      .padding(20)
    }
    .background(ControlTheme.background)
    .preferredColorScheme(.dark)
    .tint(ControlTheme.accent)
    .frame(minWidth: 860, minHeight: 580)
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let state = PrompterState(config: loadConfig())
  private let voiceMonitor = VoiceActivityMonitor()
  private var controlWindow: NSWindow?
  private var overlayPanel: NSPanel?
  private var cancellables = Set<AnyCancellable>()
  private var hoverTimer: Timer?
  private var overlayVisible = true
  private var notchHoverInside = false
  private var lastToggle = Date.distantPast

  func applicationDidFinishLaunching(_ notification: Notification) {
    applyAppIcon()
    setupMainMenu()
    state.autoFitNotch()
    createOverlayPanel()
    createControlWindow()
    bindPanelToState()
    bindVoiceControl()
    startHoverMonitor()
  }

  func applicationWillTerminate(_ notification: Notification) {
    hoverTimer?.invalidate()
  }

  private func applyAppIcon() {
    let bundleIcon = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
      ?? Bundle.main.url(forResource: "AppIcon", withExtension: "png")
      ?? Bundle.main.url(forResource: "icon", withExtension: "png")

    let iconPath = bundleIcon?.path ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent("icon.png").path

    if let image = NSImage(contentsOfFile: iconPath) {
      NSApplication.shared.applicationIconImage = image
    }
  }

  private func createOverlayPanel() {
    guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
    let frame = panelFrame(for: screen, width: state.width, height: state.height, dockOffset: state.dockOffset)

    let panel = NSPanel(
      contentRect: frame,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )

    panel.level = .statusBar
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.hasShadow = false
    panel.hidesOnDeactivate = false
    panel.ignoresMouseEvents = true

    let hosting = NSHostingView(rootView: NotchOverlayView(state: state))
    hosting.frame = panel.contentView?.bounds ?? frame
    hosting.autoresizingMask = [.width, .height]
    panel.contentView = hosting

    panel.orderFrontRegardless()
    overlayPanel = panel
    overlayVisible = true
  }

  private func setupMainMenu() {
    let mainMenu = NSMenu()

    let appMenuItem = NSMenuItem()
    let appMenu = NSMenu()
    appMenu.addItem(withTitle: "Quit Notch Prompter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    appMenuItem.submenu = appMenu
    mainMenu.addItem(appMenuItem)

    let editMenuItem = NSMenuItem()
    let editMenu = NSMenu(title: "Edit")
    editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
    editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
    editMenu.addItem(.separator())
    editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
    editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
    editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
    editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
    editMenuItem.submenu = editMenu
    mainMenu.addItem(editMenuItem)

    NSApp.mainMenu = mainMenu
  }

  private func createControlWindow() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 860, height: 640),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "Notch Prompter"
    window.appearance = NSAppearance(named: .darkAqua)
    window.center()
    window.contentView = NSHostingView(rootView: ControlView(state: state))
    window.makeKeyAndOrderFront(nil)
    controlWindow = window
    NSApp.activate(ignoringOtherApps: true)
  }

  private func bindPanelToState() {
    Publishers.CombineLatest3(state.$width, state.$height, state.$dockOffset)
      .receive(on: RunLoop.main)
      .sink { [weak self] width, height, dockOffset in
        guard let self else { return }
        guard let panel = self.overlayPanel else { return }
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = self.panelFrame(for: screen, width: width, height: height, dockOffset: dockOffset)
        panel.setFrame(frame, display: true)
      }
      .store(in: &cancellables)
  }

  private func bindVoiceControl() {
    state.$voiceControlEnabled
      .receive(on: RunLoop.main)
      .sink { [weak self] enabled in
        guard let self else { return }
        if enabled {
          self.voiceMonitor.start()
        } else {
          self.voiceMonitor.stop()
          self.state.voiceActive = false
          self.state.voiceLevel = 0
        }
      }
      .store(in: &cancellables)

    state.$voiceSensitivity
      .receive(on: RunLoop.main)
      .sink { [weak self] value in
        self?.voiceMonitor.sensitivity = value
      }
      .store(in: &cancellables)

    voiceMonitor.$level
      .receive(on: RunLoop.main)
      .sink { [weak self] level in
        self?.state.voiceLevel = level
      }
      .store(in: &cancellables)

    voiceMonitor.$isActive
      .receive(on: RunLoop.main)
      .sink { [weak self] active in
        guard let self else { return }
        self.state.voiceActive = active
        if self.state.voiceControlEnabled {
          self.state.running = active
        }
      }
      .store(in: &cancellables)
  }

  private func startHoverMonitor() {
    hoverTimer?.invalidate()
    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
      guard let self else { return }
      guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
      let mouse = NSEvent.mouseLocation

      let notchRect = self.notchTriggerRect(on: screen)
      let hoveringNotch = notchRect.contains(mouse)
      if hoveringNotch && !self.notchHoverInside {
        self.toggleOverlayVisibility()
      }
      self.notchHoverInside = hoveringNotch

      guard self.overlayVisible, let panel = self.overlayPanel else {
        if self.state.showOverlayControls {
          self.state.showOverlayControls = false
        }
        return
      }

      let buttonSize: CGFloat = 26
      let paddingX: CGFloat = 8
      let paddingY: CGFloat = 6
      let buttonRect = NSRect(
        x: panel.frame.maxX - paddingX - buttonSize,
        y: panel.frame.maxY - paddingY - buttonSize,
        width: buttonSize,
        height: buttonSize
      )

      let isHovering = buttonRect.contains(mouse)
      if self.state.showOverlayControls != isHovering {
        self.state.showOverlayControls = isHovering
      }
      panel.ignoresMouseEvents = !isHovering
    }
  }

  private func notchTriggerRect(on screen: NSScreen) -> NSRect {
    let notchRect = actualNotchRect(for: screen)
    let triggerHeight = max(8, min(18, notchRect.height * 0.65))
    let triggerPadding: CGFloat = 10
    let x = notchRect.origin.x - triggerPadding
    let y = notchRect.minY - triggerHeight
    let width = notchRect.width + triggerPadding * 2
    return NSRect(x: x, y: y, width: width, height: triggerHeight)
  }

  private func actualNotchRect(for screen: NSScreen) -> NSRect {
    let frame = screen.frame
    var notchWidth: CGFloat = CGFloat(state.notchWidth)
    var notchHeight: CGFloat = CGFloat(state.notchHeight)

    if #available(macOS 12.0, *) {
      if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
        let totalWidth = frame.width
        let computed = totalWidth - left.width - right.width
        if computed > 0 {
          notchWidth = computed
        }
      }
      let safeTop = screen.safeAreaInsets.top
      let menuBarHeight = max(0, frame.maxY - screen.visibleFrame.maxY)
      let heightCandidates = [safeTop, menuBarHeight].filter { $0 > 0 }
      if let best = heightCandidates.min() {
        notchHeight = best
      }
    } else {
      let menuBarHeight = max(0, frame.maxY - screen.visibleFrame.maxY)
      if menuBarHeight > 0 {
        notchHeight = menuBarHeight
      }
    }

    let x = frame.midX - notchWidth / 2
    let y = frame.maxY - notchHeight
    return NSRect(x: x, y: y, width: notchWidth, height: notchHeight)
  }

  private func toggleOverlayVisibility() {
    let now = Date()
    if now.timeIntervalSince(lastToggle) < 0.3 { return }
    lastToggle = now
    setOverlayVisible(!overlayVisible)
    performHapticFeedback()
  }

  private func setOverlayVisible(_ visible: Bool) {
    guard let panel = overlayPanel else { return }
    overlayVisible = visible
    if visible {
      panel.orderFrontRegardless()
    } else {
      panel.orderOut(nil)
      panel.ignoresMouseEvents = true
    }
  }

  private func performHapticFeedback() {
    if #available(macOS 10.11, *) {
      let performer = NSHapticFeedbackManager.defaultPerformer
      performer.perform(.levelChange, performanceTime: .now)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
        performer.perform(.levelChange, performanceTime: .now)
      }
    }
  }

  private func panelFrame(for screen: NSScreen, width: Double, height: Double, dockOffset: Double) -> NSRect {
    let frame = screen.frame
    let scale = screen.backingScaleFactor
    func roundToPixel(_ value: CGFloat) -> CGFloat {
      guard scale > 0 else { return value }
      return (value * scale).rounded(.toNearestOrAwayFromZero) / scale
    }

    let panelWidth = roundToPixel(CGFloat(width))
    let panelHeight = roundToPixel(CGFloat(height))
    let x = roundToPixel(frame.origin.x + (frame.size.width - panelWidth) / 2)
    let y = roundToPixel(frame.origin.y + frame.size.height - panelHeight + CGFloat(dockOffset))
    return NSRect(x: x, y: y, width: panelWidth, height: panelHeight)
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
