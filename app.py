from flask import Flask, request, jsonify
import word_analyzer
import claude_generator

app = Flask(__name__)

@app.route('/analyze_text', methods=['POST'])
def analyze_text():
    """
    Receives combined text from book pages
    Returns top 3 complex words with definitions (dummy data for now)
    """
    data = request.get_json()

    if not data or 'text' not in data:
        return jsonify({'error': 'No text provided'}), 400

    text = data['text']
    print(f"Received {len(text)} characters of text")

    # Step 1: Analyze text and get top 3 complex words
    words = word_analyzer.analyze_text(text)

    # Debug: print the words found
    print(f"Found {len(words)} complex words:")
    for w in words:
        print(f"  - {w['word']} (difficulty: {w['difficulty']})")

    # Step 2: Enrich words with Claude-generated definitions and examples
    print("Enriching words with Claude Haiku...")
    enriched_words = claude_generator.enrich_words(words, text)

    print("Done! Sending enriched words to app.")
    return jsonify({'words': enriched_words})

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    # Run on all interfaces so iPhone can connect via local network
    app.run(host='0.0.0.0', port=5000, debug=True)
