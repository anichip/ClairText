//
//  APIService.swift
//  ClairText
//
//  Handles communication with Flask backend
//

import Foundation

struct WordResult: Codable, Identifiable {
    let id = UUID()
    let word: String
    let definition: String
    let example: String
    let difficulty: Double

    enum CodingKeys: String, CodingKey {
        case word, definition, example, difficulty
    }
}

struct AnalyzeResponse: Codable {
    let words: [WordResult]
}

struct StoredWord: Codable, Identifiable {
    let id = UUID()
    let word: String
    let difficulty: Double

    enum CodingKeys: String, CodingKey {
        case word, difficulty
    }
}

struct StoredWordsResponse: Codable {
    let words: [StoredWord]
}

class APIService {
    // Change this to your Mac's local IP address when testing on device
    // Find it with: System Preferences → Network → your WiFi → IP address
    private let baseURL = "http://10.0.0.116:5000"

    func analyzeText(_ text: String) async throws -> [WordResult] {
        guard let url = URL(string: "\(baseURL)/analyze_text") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["text": text]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let analyzeResponse = try JSONDecoder().decode(AnalyzeResponse.self, from: data)
        return analyzeResponse.words
    }

    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func masterWord(_ word: String, difficulty: Double) async throws {
        guard let url = URL(string: "\(baseURL)/master_word") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["word": word, "difficulty": difficulty]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    func getMasteredWords() async throws -> [StoredWord] {
        guard let url = URL(string: "\(baseURL)/get_mastered_words") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(StoredWordsResponse.self, from: data)
        return decoded.words
    }

    func getSavedWords() async throws -> [StoredWord] {
        guard let url = URL(string: "\(baseURL)/get_saved_words") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(StoredWordsResponse.self, from: data)
        return decoded.words
    }

    func saveWord(_ word: String, difficulty: Double) async throws {
        guard let url = URL(string: "\(baseURL)/save_word") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["word": word, "difficulty": difficulty]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}
