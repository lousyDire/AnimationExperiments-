//
//  ContentView.swift
//  CustomToolbarBlur
//
//  Created by Игорь Чикичев on 27.03.2025.
//

import SwiftUI
import UIKit
import QuartzCore

// MARK: - Контент

struct ContentView: View {
    @State private var blurIntensity: CGFloat = 0.05

    var body: some View {
        ZStack(alignment: .top) {
            NavigationView {
                List(0..<30) { i in
                    Text("Элемент \(i)")
                }
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        ZStack {
                            BlurEffectViewRepresentable(style: .systemMaterialDark, intensity: $blurIntensity)
                                .frame(height: 50)
                                .edgesIgnoringSafeArea(.bottom)
                            
                            Text("Тулбар")
                                .foregroundColor(.white)
                                .bold()
                        }
                    }
                }
            }

            // Живой блюр под навбар (примерно 100 по высоте)
            BlurEffectViewRepresentable(style: .systemMaterialDark, intensity: $blurIntensity)
                .frame(height: 100)
                .edgesIgnoringSafeArea(.top)
        }
    }
}

// MARK: - SwiftUI Обёртка

struct BlurEffectViewRepresentable: UIViewRepresentable {
    var style: UIBlurEffect.Style
    @Binding var intensity: CGFloat

    func makeUIView(context: Context) -> BlurEffectView {
        let view = BlurEffectView()
        view.effect = UIBlurEffect(style: style)
        view.intensity = intensity
        return view
    }

    func updateUIView(_ uiView: BlurEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.intensity = intensity
    }
}

// MARK: - UIView + CALayer (анимируемый блюр)

class BlurIntensityLayer: CALayer {
    @NSManaged var intensity: CGFloat

    override init(layer: Any) {
        super.init(layer: layer)
        if let layer = layer as? BlurIntensityLayer {
            self.intensity = layer.intensity
        }
    }

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override class func needsDisplay(forKey key: String) -> Bool {
        return key == #keyPath(intensity) || super.needsDisplay(forKey: key)
    }

    override func action(forKey event: String) -> CAAction? {
        guard event == #keyPath(intensity) else {
            return super.action(forKey: event)
        }

        let animation = CABasicAnimation(keyPath: event)
        animation.fromValue = (self.presentation() ?? self).intensity
        return animation
    }
}

class BlurEffectView: UIView {
    override class var layerClass: AnyClass {
        return BlurIntensityLayer.self
    }

    @objc
    @IBInspectable
    public dynamic var intensity: CGFloat {
        set { self.blurIntensityLayer.intensity = newValue }
        get { return self.blurIntensityLayer.intensity }
    }

    @IBInspectable
    public var effect = UIBlurEffect(style: .dark) {
        didSet {
            self.setupPropertyAnimator()
        }
    }

    private let visualEffectView = UIVisualEffectView(effect: nil)
    private var propertyAnimator: UIViewPropertyAnimator!
    private var blurIntensityLayer: BlurIntensityLayer {
        return self.layer as! BlurIntensityLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }

    deinit {
        self.propertyAnimator.stopAnimation(true)
    }

    private func setupPropertyAnimator() {
        self.propertyAnimator?.stopAnimation(true)
        self.propertyAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear)
        self.propertyAnimator.addAnimations { [weak self] in
            self?.visualEffectView.effect = self?.effect
        }
        self.propertyAnimator.pausesOnCompletion = true
    }

    private func setupView() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = false

        self.addSubview(self.visualEffectView)
        self.visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        self.setupPropertyAnimator()
    }

    override func display(_ layer: CALayer) {
        guard let presentationLayer = layer.presentation() as? BlurIntensityLayer else {
            return
        }
        let clampedIntensity = max(0.0, min(1.0, presentationLayer.intensity))
        self.propertyAnimator.fractionComplete = clampedIntensity
    }
}
