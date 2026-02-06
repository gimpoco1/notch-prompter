import Cocoa
import SwiftUI
import Combine

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
    running: true
  )

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
  let cwd = FileManager.default.currentDirectoryPath
  let configPath = URL(fileURLWithPath: cwd).appendingPathComponent("native/config.json").path
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
  }

  func autoFitNotch() {
    guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
    var computedWidth: CGFloat = 220
    var computedHeight: CGFloat = 28
    let widthOverscan: CGFloat = 8
    let heightOverscan: CGFloat = 2

    if #available(macOS 12.0, *) {
      if let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
        let totalWidth = screen.frame.width
        let notch = totalWidth - left.width - right.width
        if notch > 0 {
          computedWidth = notch + widthOverscan
        }
      }
      let safeTop = screen.safeAreaInsets.top
      if safeTop > 0 {
        computedHeight = safeTop + heightOverscan
      }
    }

    notchWidth = Double(computedWidth)
    notchHeight = Double(computedHeight)
    notchRadius = max(8, Double(computedHeight * 0.5))
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

        Text(state.text.isEmpty ? "Paste your script in the control window." : state.text)
          .font(.system(size: state.fontSize, weight: .regular, design: .monospaced))
          .foregroundColor(.white)
          .lineSpacing(4)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
          .background(
            GeometryReader { textGeo in
              Color.clear.preference(key: TextHeightKey.self, value: textGeo.size.height)
            }
          )
          .offset(y: offset)
          .padding(.horizontal, state.paddingX)
          .padding(.vertical, state.paddingY)
          .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
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
          VStack(alignment: .leading, spacing: 6) {
            Text("Notch Prompter")
              .font(.title3.weight(.semibold))
            Text("Paste your script and tune the overlay.")
              .foregroundColor(.secondary)
          }
          Spacer()
          Button(state.running ? "Pause" : "Resume") {
            state.running.toggle()
          }
          .buttonStyle(.borderedProminent)
        }

        GroupBox("Script") {
          VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
              TextEditor(text: $state.text)
                .font(.system(size: 15, design: .monospaced))
                .frame(minHeight: 180, maxHeight: 520)
                .frame(height: scriptHeight)
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                )
              if state.text.isEmpty {
                Text("Paste or type your script here...")
                  .foregroundColor(.secondary)
                  .padding(.top, 8)
                  .padding(.leading, 6)
              }
            }

            Rectangle()
              .fill(Color.gray.opacity(0.2))
              .frame(height: 4)
              .cornerRadius(2)
              .overlay(
                Rectangle()
                  .fill(Color.gray.opacity(0.4))
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
                .foregroundColor(.secondary)
            }
          }
          .padding(.top, 4)
        }

        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, spacing: 16) {
          GroupBox("Playback") {
            VStack(alignment: .leading, spacing: 12) {
              VStack(alignment: .leading) {
                Text("Speed")
                Slider(value: $state.speed, in: 8...120, step: 1)
                Text("\(Int(state.speed)) px/s")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              VStack(alignment: .leading) {
                Text("Scroll Mode")
                Picker("Mode", selection: $state.mode) {
                  ForEach(ScrollMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                  }
                }
                .pickerStyle(.segmented)
              }
            }
          }

          GroupBox("Typography") {
            VStack(alignment: .leading, spacing: 12) {
              Text("Font Size")
              Slider(value: $state.fontSize, in: 14...42, step: 1)
              Text("\(Int(state.fontSize)) px")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          GroupBox("Overlay") {
            VStack(alignment: .leading, spacing: 12) {
              Text("Width")
              Slider(value: $state.width, in: 260...980, step: 1)
              Text("\(Int(state.width)) px")
                .font(.caption)
                .foregroundColor(.secondary)

              Text("Height")
              Slider(value: $state.height, in: 56...160, step: 1)
              Text("\(Int(state.height)) px")
                .font(.caption)
                .foregroundColor(.secondary)

              Text("Opacity")
              Slider(value: $state.opacity, in: 0.4...1, step: 0.02)
              Text(String(format: "%.2f", state.opacity))
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          GroupBox("Notch") {
            VStack(alignment: .leading, spacing: 12) {
              Text("Notch Width")
              Slider(value: $state.notchWidth, in: 180...360, step: 1)
              Text("\(Int(state.notchWidth)) px")
                .font(.caption)
                .foregroundColor(.secondary)

              Text("Notch Height")
              Slider(value: $state.notchHeight, in: 12...48, step: 1)
              Text("\(Int(state.notchHeight)) px")
                .font(.caption)
                .foregroundColor(.secondary)

              Text("Dock Offset")
              Slider(value: $state.dockOffset, in: -12...16, step: 1)
              Text("\(Int(state.dockOffset)) px")
                .font(.caption)
                .foregroundColor(.secondary)

              Button("Auto-fit Notch") {
                state.autoFitNotch()
              }
            }
          }
        }
      }
      .padding(20)
    }
    .frame(minWidth: 720, minHeight: 520)
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let state = PrompterState(config: loadConfig())
  private var controlWindow: NSWindow?
  private var overlayPanel: NSPanel?
  private var cancellables = Set<AnyCancellable>()
  private var hoverTimer: Timer?

  func applicationDidFinishLaunching(_ notification: Notification) {
    setupMainMenu()
    createOverlayPanel()
    createControlWindow()
    bindPanelToState()
    startHoverMonitor()
  }

  func applicationWillTerminate(_ notification: Notification) {
    hoverTimer?.invalidate()
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

  private func startHoverMonitor() {
    hoverTimer?.invalidate()
    hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
      guard let self else { return }
      guard let panel = self.overlayPanel else { return }
      let mouse = NSEvent.mouseLocation

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

  private func panelFrame(for screen: NSScreen, width: Double, height: Double, dockOffset: Double) -> NSRect {
    let frame = screen.frame
    let x = frame.origin.x + (frame.size.width - width) / 2
    let y = frame.origin.y + frame.size.height - height + dockOffset
    return NSRect(x: x, y: y, width: width, height: height)
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.regular)
app.delegate = delegate
app.run()
