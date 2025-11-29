//
//  ContentView.swift
//  ClairText
//
//  Created by Aniruddha Chiplunkar on 11/27/25.
//

import SwiftUI

enum CaptureStep {
    case capturingLeft
    case capturingRight
    case showingResults
}

struct ContentView: View {
    @State private var currentStep: CaptureStep = .capturingLeft
    @State private var leftPageImage: UIImage?
    @State private var rightPageImage: UIImage?
    @State private var leftPageText: String = ""
    @State private var rightPageText: String = ""
    @State private var showCamera: Bool = false
    @State private var isProcessing: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            switch currentStep {
            case .capturingLeft:
                leftPageView
            case .capturingRight:
                rightPageView
            case .showingResults:
                resultsView
            }
        }
        .padding()
        .sheet(isPresented: $showCamera) {
            if currentStep == .capturingLeft {
                CameraView(image: $leftPageImage)
            } else if currentStep == .capturingRight {
                CameraView(image: $rightPageImage)
            }
        }
        .onChange(of: leftPageImage) { _, newImage in
            if let image = newImage {
                processLeftPage(image)
            }
        }
        .onChange(of: rightPageImage) { _, newImage in
            if let image = newImage {
                processRightPage(image)
            }
        }
    }

    var leftPageView: some View {
        VStack(spacing: 20) {
            Text("ClairText")
                .font(.largeTitle)
                .bold()

            if isProcessing {
                ProgressView("Processing left page...")
            } else {
                Button(action: {
                    showCamera = true
                }) {
                    Label("Capture Left Page", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
    }

    var rightPageView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)

            Text("Left page captured!")
                .font(.headline)

            if isProcessing {
                ProgressView("Processing right page...")
            } else {
                Button(action: {
                    showCamera = true
                }) {
                    Label("Capture Right Page", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
    }

    var resultsView: some View {
        VStack(spacing: 20) {
            Text("Extracted Text")
                .font(.title)
                .bold()

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Left Page:")
                        .font(.headline)
                    Text(leftPageText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)

                    Text("Right Page:")
                        .font(.headline)
                    Text(rightPageText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            Button(action: {
                startOver()
            }) {
                Label("Start Over", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(10)
            }
        }
    }

    func processLeftPage(_ image: UIImage) {
        isProcessing = true
        OCRProcessor.recognizeText(from: image) { text in
            leftPageText = text
            isProcessing = false
            currentStep = .capturingRight
        }
    }

    func processRightPage(_ image: UIImage) {
        isProcessing = true
        OCRProcessor.recognizeText(from: image) { text in
            rightPageText = text
            isProcessing = false
            currentStep = .showingResults
        }
    }

    func startOver() {
        currentStep = .capturingLeft
        leftPageImage = nil
        rightPageImage = nil
        leftPageText = ""
        rightPageText = ""
    }
}

#Preview {
    ContentView()
}
