//
//  ContentView.swift
//  HeartExplosionParticles
//

import SwiftUI
import QuartzCore

struct ContentView: View {
    @State private var trigger = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // 🔻 Частицы (находятся под кнопкой)
            if trigger {
                HeartExplosionView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(0) // ниже кнопки
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            trigger = false
                        }
                    }
            }

            // 🔺 Кнопка (всегда сверху)
            VStack {
                Spacer()
                Button("💥 Взрыв сердечек!") {
                    trigger.toggle()
                }
                .font(.title2)
                .padding()
                .foregroundColor(.white)
                .background(.pink)
                .clipShape(Capsule())
                .padding(.bottom, 60)
            }
            .zIndex(1)
        }
    }
}

// MARK: - Вьюшка с взрывом

struct HeartExplosionView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let emitter = CAEmitterLayer()
        emitter.emitterShape = .point
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)

        let cell = CAEmitterCell()
        cell.contents = emojiImage(emoji: "❤️", size: 40)?.cgImage
        cell.birthRate = 40
        cell.lifetime = 10.0
        cell.velocity = 840
        cell.velocityRange = 120
        cell.yAcceleration = UIScreen.main.bounds.height - 300 // Гравитация вниз
        cell.emissionLongitude = -CGFloat.pi / 2 // вверх
        cell.emissionRange = CGFloat.pi / 8     // узкий "конус" вверх
        cell.scale = 0.3
        cell.scaleRange = 0.2
        cell.alphaSpeed = 0
        cell.spin = 4
        cell.spinRange = 2

        emitter.emitterCells = [cell]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            emitter.birthRate = 0
        }

        view.layer.addSublayer(emitter)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Emoji → UIImage

func emojiImage(emoji: String, size: CGFloat = 40) -> UIImage? {
    let label = UILabel()
    label.text = emoji
    label.font = UIFont.systemFont(ofSize: size)
    label.textAlignment = .center
    label.frame = CGRect(origin: .zero, size: CGSize(width: size, height: size))

    let renderer = UIGraphicsImageRenderer(size: label.frame.size)
    return renderer.image { ctx in
        label.layer.render(in: ctx.cgContext)
    }
}
