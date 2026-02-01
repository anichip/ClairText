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
                    Image(systemName: "chart.bar.fill")
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

                HStack(spacing: 12) {
                    Image(systemName: "book.fill")
                        .font(.largeTitle)
                        .foregroundColor(.blue)

                    Text("ClairText")
                        .font(.largeTitle)
                        .bold()
                }

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

// MARK: - Cookie Jar View

struct CookieJarView: View {
    @State private var masteredCount: Int = 0
    @State private var savedCount: Int = 0
    @State private var masteredWords: [StoredWord] = []
    @State private var savedWords: [StoredWord] = []

    private let apiService = APIService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Cookie Jar graphic
                NavigationLink(destination: MasteredWordsView(words: masteredWords)) {
                    ZStack {
                        // Jar body
                        VStack(spacing: 0) {
                            // Lid
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.brown.opacity(0.7))
                                .frame(width: 100, height: 20)

                            // Jar
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.brown.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.brown.opacity(0.4), lineWidth: 2)
                                )
                                .frame(width: 120, height: 150)
                                .overlay(
                                    // Cookies inside jar
                                    VStack(spacing: 4) {
                                        if masteredCount >= 3 {
                                            Text("🍪🍪🍪")
                                                .font(.title2)
                                        }
                                        if masteredCount >= 2 {
                                            Text("🍪🍪")
                                                .font(.title2)
                                        }
                                        if masteredCount >= 1 {
                                            Text("🍪")
                                                .font(.title2)
                                        }
                                    }
                                    .padding(.top, 20)
                                )
                        }

                        // Post-it note
                        Text("🍪\(masteredCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(10)
                            .background(Color.yellow)
                            .cornerRadius(4)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                            .rotationEffect(.degrees(-8))
                            .offset(x: 65, y: -70)
                    }
                }
                .buttonStyle(.plain)

                Text("Tap the jar to see your words")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Saved for Later bar
                NavigationLink(destination: SavedWordsView(words: savedWords)) {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("Saved for Later")
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(savedCount)")
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(12)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Cookie Jar")
            .onAppear {
                fetchWords()
            }
        }
    }

    func fetchWords() {
        Task {
            do {
                let mastered = try await apiService.getMasteredWords()
                let saved = try await apiService.getSavedWords()
                await MainActor.run {
                    masteredWords = mastered
                    masteredCount = mastered.count
                    savedWords = saved
                    savedCount = saved.count
                }
            } catch {
                print("Failed to fetch words: \(error)")
            }
        }
    }
}

// MARK: - Mastered Words View

struct MasteredWordsView: View {
    let words: [StoredWord]

    var body: some View {
        Group {
            if words.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No words mastered yet.")
                        .font(.headline)
                    Text("Scan some pages and start building your Cookie Jar!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                List(words) { word in
                    HStack {
                        Text(word.word)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(word.difficulty * 100))%")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Mastered Words")
    }
}

// MARK: - Saved Words View

struct SavedWordsView: View {
    @State var words: [StoredWord]
    private let apiService = APIService()

    var body: some View {
        Group {
            if words.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No saved words yet.")
                        .font(.headline)
                    Text("Save words you want to revisit later.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                List {
                    ForEach(words) { word in
                        HStack {
                            Text(word.word)
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(Int(word.difficulty * 100))%")
                                .foregroundColor(.secondary)
                            Button(action: {
                                masterSavedWord(word)
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved for Later")
    }

    func masterSavedWord(_ word: StoredWord) {
        Task {
            do {
                try await apiService.masterWord(word.word, difficulty: word.difficulty)
                await MainActor.run {
                    words.removeAll { $0.id == word.id }
                }
            } catch {
                print("Failed to master saved word: \(error)")
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon and Title
                    VStack(spacing: 12) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)

                        Text("ClairText")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Version 1.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Developer Info
                    InfoSection(title: "Developer") {
                        Text("Built with enthusiasm for computer vision, AI, and reading.")
                            .font(.body)
                            .multilineTextAlignment(.leading)
                    }

                    // How It Works
                    InfoSection(title: "How It Works") {
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(
                                icon: "camera.fill",
                                title: "Scan your book pages",
                                description: "Capture left and right pages with your camera"
                            )

                            FeatureRow(
                                icon: "text.magnifyingglass",
                                title: "AI finds complex words",
                                description: "OCR extracts text and identifies vocabulary"
                            )

                            FeatureRow(
                                icon: "lightbulb.fill",
                                title: "Learn with Feynman examples",
                                description: "Simple explanations that make words stick"
                            )

                            FeatureRow(
                                icon: "checkmark.circle.fill",
                                title: "Master words to your Cookie Jar",
                                description: "Track your vocabulary growth over time"
                            )
                        }
                    }

                    // Technical Details
                    InfoSection(title: "Technology") {
                        VStack(alignment: .leading, spacing: 8) {
                            TechRow(label: "Frontend", value: "Swift")
                            TechRow(label: "Backend", value: "FlaskAPI")
                            TechRow(label: "Database", value: "PostgreSQL")
                            TechRow(label: "AI", value: "Claude Haiku 3.5")
                            TechRow(label: "OCR", value: "Vision Framework")
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("About")
        }
    }
}

// MARK: - Supporting Views

struct InfoSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TechRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
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
                    checkAllDone()
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
                    checkAllDone()
                }
            } catch {
                print("Failed to save word: \(error)")
            }
        }
    }

    func checkAllDone() {
        let allHidden = wordResults.allSatisfy { hiddenWordIds.contains($0.id) }
        if allHidden && !wordResults.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
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
