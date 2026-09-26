import SwiftUI

/// Owns the engine, feeds it every hardware input, and routes to the closed or open experience.
/// Dev A owns `ClosedGameView`, Dev B owns `OpenGameView`.
struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var engine = KaijuEngine()

    var body: some View {
        content
            .environment(engine)
            .sheet(item: neglectReport, content: neglectSheet)
            .task { await engine.run() }
            .onHingeChange { _, newContext in
                hingeDidChange(newContext)
            }
            .onChange(of: horizontalSizeClass, initial: true) { _, newClass in
                sizeClassDidChange(newClass)
            }
            .onChange(of: scenePhase, initial: true) { _, newPhase in
                scenePhaseDidChange(newPhase)
            }
    }

    private func neglectSheet(_ report: NeglectReport) -> some View {
        NeglectReportView(report: report)
            .environment(engine)
    }

    private func sizeClassDidChange(_ sizeClass: UserInterfaceSizeClass?) {
        engine.sizeClassDidChange(isCompact: sizeClass == UserInterfaceSizeClass.compact)
    }

    private func scenePhaseDidChange(_ phase: ScenePhase) {
        engine.scenePhaseDidChange(isBackground: phase == ScenePhase.background, isActive: phase == ScenePhase.active)
    }

    private var content: some View {
        ZStack(alignment: .top) {
            if engine.showsClosedExperience {
                ClosedGameView()
                    .transition(.opacity)
            } else {
                OpenGameView()
                    .transition(.opacity)
            }
        }
        .animation(.smooth, value: engine.showsClosedExperience)
    }

    private func hingeDidChange(_ context: DeviceHingeContext) {
        engine.hingeDidChange(HingeReading(context))
    }

    private var neglectReport: Binding<NeglectReport?> {
        Binding {
            engine.neglectReport
        } set: { newValue in
            if newValue == nil { engine.dismissNeglectReport() }
        }
    }
}
