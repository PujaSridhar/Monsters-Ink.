import SpriteKit
import SwiftUI

/// SpriteKit particle overlay: acid rain (neglect) and dust/debris (destruction).
/// Drop `EffectsLayer` on top of any view; it's transparent and ignores touches.
final class EffectsScene: SKScene {
    private let rain = SKEmitterNode()
    private let dust = SKEmitterNode()

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .clear
        scaleMode = .resizeFill

        rain.particleTexture = Self.texture(size: CGSize(width: 2, height: 10), color: .green)
        rain.particleBirthRate = 0
        rain.particleLifetime = 2.5
        rain.particleSpeed = 500
        rain.particleSpeedRange = 120
        rain.emissionAngle = -.pi / 2 - 0.15
        rain.particleAlpha = 0.7
        rain.particleColorBlendFactor = 1
        rain.particleColor = UIColor(red: 0.5, green: 1, blue: 0.2, alpha: 1)
        addChild(rain)

        dust.particleTexture = Self.texture(size: CGSize(width: 6, height: 6), color: .white)
        dust.particleBirthRate = 0
        dust.particleLifetime = 1.6
        dust.particleSpeed = 180
        dust.particleSpeedRange = 120
        dust.emissionAngle = .pi / 2
        dust.emissionAngleRange = .pi / 1.5
        dust.yAcceleration = -300
        dust.particleAlphaSpeed = -0.6
        dust.particleScaleRange = 1.5
        dust.particleColorBlendFactor = 1
        dust.particleColor = UIColor(red: 0.55, green: 0.5, blue: 0.45, alpha: 1)
        addChild(dust)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        rain.position = CGPoint(x: size.width / 2, y: size.height + 20)
        rain.particlePositionRange = CGVector(dx: size.width * 1.3, dy: 0)
        dust.position = CGPoint(x: size.width / 2, y: size.height * 0.1)
        dust.particlePositionRange = CGVector(dx: size.width, dy: 10)
    }

    /// 0 = off, 1 = downpour.
    func setAcidRain(_ intensity: Double) {
        rain.particleBirthRate = 400 * intensity
    }

    /// 0 = off, 1 = the city is being turned to dust.
    func setDust(_ intensity: Double) {
        dust.particleBirthRate = 300 * intensity
    }

    /// A one-off burst, e.g. when a tower loses a floor.
    func burst(at point: CGPoint? = nil) {
        let spark = dust.copy() as! SKEmitterNode
        spark.position = point ?? CGPoint(x: .random(in: 0...size.width), y: size.height * 0.2)
        spark.particleBirthRate = 800
        spark.numParticlesToEmit = 60
        spark.particlePositionRange = CGVector(dx: 40, dy: 10)
        addChild(spark)
        spark.run(.sequence([.wait(forDuration: 2), .removeFromParent()]))
    }

    private static func texture(size: CGSize, color: UIColor) -> SKTexture {
        let image = UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }
}

/// SwiftUI wrapper for `EffectsScene`.
struct EffectsLayer: View {
    var acidRain: Double = 0
    var dust: Double = 0
    /// Change this value to trigger a debris burst (e.g. pass `engine.floorsDestroyedCount`).
    var burstTrigger: Int = 0

    @State private var scene = EffectsScene(size: CGSize(width: 400, height: 800))

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onAppear { apply() }
            .onChange(of: acidRain) { apply() }
            .onChange(of: dust) { apply() }
            .onChange(of: burstTrigger) { scene.burst() }
    }

    private func apply() {
        scene.setAcidRain(acidRain)
        scene.setDust(dust)
    }
}
