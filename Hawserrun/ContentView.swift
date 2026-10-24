import SpriteKit
import SwiftUI

/// The scene is created once on the host, then handed to the view. It is not built inside `body`.
@MainActor
final class PlayHost: ObservableObject {
    let chrome = DeckChrome()
    let store = RunRecordStore()
    let scene: FerryScene

    init() {
        store.prepareColdLaunch()
        let scene = FerryScene(size: CGSize(width: 844, height: 390))
        scene.bind(chrome: chrome, store: store)
        self.scene = scene
    }
}

struct FerryHost: UIViewRepresentable {
    let scene: FerryScene

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true
        view.preferredFramesPerSecond = 60
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== scene {
            uiView.presentScene(scene)
        }
    }
}

struct ContentView: View {
    @StateObject private var host = PlayHost()

    var body: some View {
        PlayView(scene: host.scene, chrome: host.chrome, store: host.store)
    }
}

struct PlayView: View {
    let scene: FerryScene
    @ObservedObject var chrome: DeckChrome
    @ObservedObject var store: RunRecordStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showRecords = false
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .top) {
            FerryHost(scene: scene)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: DeckMetrics.space8) {
                HStack(spacing: DeckMetrics.space8) {
                    HeelGauge(
                        burdenFraction: chrome.burdenFraction,
                        heel: chrome.heel,
                        score: chrome.score,
                        reduceMotion: reduceMotion
                    )
                    ChapterBuoy(chapter: chrome.chapter, reduceMotion: reduceMotion)
                    Button {
                        scene.togglePause()
                    } label: {
                        Image(systemName: chrome.paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(DesignTokens.ink)
                            .symbolEffect(.bounce, value: chrome.paused)
                            .symbolEffectsRemoved(reduceMotion)
                            .frame(width: 44, height: 44)
                            .background(DesignTokens.surface)
                            .contentShape(Rectangle())
                            .clipShape(RoundedRectangle(cornerRadius: DeckMetrics.hud))
                            .overlay(
                                RoundedRectangle(cornerRadius: DeckMetrics.hud)
                                    .stroke(DesignTokens.ink, lineWidth: DeckMetrics.hairline)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(chrome.paused ? "Resume" : "Pause")
                }
                if chrome.showChapter {
                    ChapterOverlayView(
                        chapter: chrome.chapter,
                        score: chrome.score,
                        reduceMotion: reduceMotion
                    ) {
                        scene.dismissChapter()
                    }
                } else if chrome.paused {
                    PauseOverlayView(
                        onResume: { scene.setPaused(false) },
                        onRecords: { showRecords = true },
                        onSettings: { showSettings = true }
                    )
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, DeckMetrics.space16)
            .padding(.top, DeckMetrics.space8)
        }
        .background(DesignTokens.bg)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.success, trigger: chrome.cargoCommit)
        .sensoryFeedback(.impact(weight: .heavy), trigger: chrome.chapter)
        .sheet(isPresented: $showRecords) {
            RecordsSheetView(store: store)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetView(store: store) {
                scene.reloadFerryScene(saving: false)
            }
        }
    }
}

#Preview {
    ContentView()
}
