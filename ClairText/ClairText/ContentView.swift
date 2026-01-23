//
//  ContentView.swift
//  ClairText
//
//  Created by Aniruddha Chiplunkar on 11/27/25.
//

import SwiftUI

// MARK: - Main Tab View

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            CookieJarView()
                .tabItem {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("Cookie Jar")
                }

            AboutView()
                .tabItem {
                    Image(systemName: "info.circle.fill")
                    Text("About")
                }
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @State private var showScan = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                Text("ClairText")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                Text("Ready to learn?")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Button(action: {
                    showScan = true
                }) {
                    Label("Scan Pages", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                Spacer()
                Spacer()
            }
            .navigationDestination(isPresented: $showScan) {
                ScanView()
            }
        }
    }
}

// MARK: - Cookie Jar View (Placeholder)

struct CookieJarView: View {
    var body: some View {
        VStack {
            Text("Cookie Jar")
                .font(.largeTitle)
                .bold()
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - About View (Placeholder)

struct AboutView: View {
    var body: some View {
        VStack {
            Text("About")
                .font(.largeTitle)
                .bold()
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Scan View (Capture Flow)

enum CaptureStep {
    case capturingLeft
    case capturingRight
    case showingResults
}

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: CaptureStep = .capturingLeft
    @State private var leftPageImage: UIImage?
    @State private var rightPageImage: UIImage?
    @State private var leftPageText: String = ""
    @State private var rightPageText: String = ""
    @State private var showCamera: Bool = false
    @State private var isProcessing: Bool = false
    @State private var wordResults: [WordResult] = []
    @State private var errorMessage: String?
    @State private var hiddenWordIds: Set<UUID> = []

    private let apiService = APIService()

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
            Text("Capture Left Page")
                .font(.title2)
                .bold()

            if isProcessing {
                ProgressView("Processing left page...")
            } else {
                Button(action: {
                    showCamera = true
                }) {
                    Label("Open Camera", systemImage: "camera.fill")
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
            Text("Your Big Words")
                .font(.title)
                .bold()

            if let error = errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(wordResults) { wordResult in
                            if !hiddenWordIds.contains(wordResult.id) {
                                WordCardView(
                                    wordResult: wordResult,
                                    onMaster: { masterWord(wordResult) },
                                    onSave: { saveWord(wordResult) }
                                )
                                .transition(.opacity)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeOut(duration: 0.3), value: hiddenWordIds)
                }
            }

            HStack(spacing: 16) {
                Button(action: {
                    startOver()
                }) {
                    Label("Start Over", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .cornerRadius(10)
                }

                Button(action: {
                    dismiss()
                }) {
                    Label("Proceed", systemImage: "arrow.right")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.darkGray))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
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
            // Call API with combined text
            Task {
                await analyzeText()
            }
        }
    }

    func analyzeText() async {
        let combinedText = leftPageText + " " + rightPageText

        do {
            let words = try await apiService.analyzeText(combinedText)
            await MainActor.run {
                wordResults = words
                isProcessing = false
                currentStep = .showingResults
                errorMessage = nil
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                errorMessage = "Failed to connect to backend: \(error.localizedDescription)"
                // Still show results view, but with error
                currentStep = .showingResults
            }
        }
    }

    func startOver() {
        currentStep = .capturingLeft
        leftPageImage = nil
        rightPageImage = nil
        leftPageText = ""
        rightPageText = ""
        wordResults = []
        errorMessage = nil
        hiddenWordIds = []
    }

    func masterWord(_ wordResult: WordResult) {
        Task {
            do {
                try await apiService.masterWord(wordResult.word, difficulty: wordResult.difficulty)
                await MainActor.run {
                    hiddenWordIds.insert(wordResult.id)
                }
            } catch {
                print("Failed to master word: \(error)")
            }
        }
    }

    func saveWord(_ wordResult: WordResult) {
        Task {
            do {
                try await apiService.saveWord(wordResult.word, difficulty: wordResult.difficulty)
                await MainActor.run {
                    hiddenWordIds.insert(wordResult.id)
                }
            } catch {
                print("Failed to save word: \(error)")
            }
        }
    }
}

struct WordCardView: View {
    let wordResult: WordResult
    let onMaster: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(wordResult.word)
                    .font(.title2)
                    .bold()
                Spacer()
                Text("\(Int(wordResult.difficulty * 100))%")
                    .font(.caption)
                    .padding(6)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundColor(difficultyColor)
                    .cornerRadius(6)
            }

            Text(wordResult.definition)
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Feynman Example:")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.blue)
                Text(wordResult.example)
                    .font(.subheadline)
                    .italic()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onMaster) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Master")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(8)
                }

                Button(action: onSave) {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("Save for Later")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
    }

    var difficultyColor: Color {
        if wordResult.difficulty > 0.75 {
            return .red
        } else if wordResult.difficulty > 0.5 {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview {
    ContentView()
}
