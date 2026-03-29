import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animationProgress: CGFloat = 0
    let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = animationProgress
                for particle in particles {
                    let x = particle.startX * size.width + particle.horizontalDrift * 40 * sin(time * 3 + particle.phase)
                    let y = particle.startY + time * particle.speed * size.height
                    let opacity = max(0, 1 - time * 0.8)
                    let rotation = Angle.degrees(Double(time * particle.rotationSpeed * 360))
                    guard opacity > 0, y < size.height else { continue }
                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)
                    let rect = CGRect(x: -particle.size / 2, y: -particle.size / 2, width: particle.size, height: particle.isCircle ? particle.size : particle.size * 0.6)
                    if particle.isCircle {
                        context.fill(Circle().path(in: rect), with: .color(particle.color))
                    } else {
                        context.fill(Rectangle().path(in: rect), with: .color(particle.color))
                    }
                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                    context.opacity = 1
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            particles = (0..<60).map { _ in
                ConfettiParticle(startX: .random(in: 0...1), startY: .random(in: -100...(-20)), speed: .random(in: 0.3...0.8), horizontalDrift: .random(in: -1...1), phase: .random(in: 0...(.pi * 2)), rotationSpeed: .random(in: 0.5...2), size: .random(in: 4...10), isCircle: .random(), color: colors.randomElement()!)
            }
            withAnimation(.linear(duration: 2.5)) { animationProgress = 1 }
        }
        .accessibilityHidden(true)
    }
}

private struct ConfettiParticle {
    let startX, startY, speed, horizontalDrift, phase, rotationSpeed, size: CGFloat
    let isCircle: Bool
    let color: Color
}
