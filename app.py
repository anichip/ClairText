from flask import Flask, request, jsonify
import word_analyzer
import claude_generator
import database

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

@app.route('/master_word', methods=['POST'])
def master_word_endpoint():
    """
    Mark a word as mastered (add to Cookie Jar)
    """
    data = request.get_json()

    if not data or 'word' not in data:
        return jsonify({'error': 'No word provided'}), 400

    word = data['word']
    difficulty = data.get('difficulty', 0.0)

    success = database.master_word(word, difficulty)

    if success:
        return jsonify({'status': 'success', 'message': f'Word "{word}" mastered!'})
    else:
        return jsonify({'error': 'Failed to master word'}), 500

@app.route('/save_word', methods=['POST'])
def save_word_endpoint():
    """
    Save a word for later practice
    """
    data = request.get_json()

    if not data or 'word' not in data:
        return jsonify({'error': 'No word provided'}), 400

    word = data['word']
    difficulty = data.get('difficulty', 0.0)

    success = database.save_word(word, difficulty)

    if success:
        return jsonify({'status': 'success', 'message': f'Word "{word}" saved for later!'})
    else:
        return jsonify({'error': 'Failed to save word'}), 500

@app.route('/get_mastered_words', methods=['GET'])
def get_mastered_words():
    """
    Get all mastered words (Cookie Jar contents)
    """
    words = database.get_mastered_words()
    return jsonify({'words': words})

@app.route('/get_saved_words', methods=['GET'])
def get_saved_words():
    """
    Get all saved words (Save for Later contents)
    """
    words = database.get_saved_words()
    return jsonify({'words': words})

if __name__ == '__main__':
    # Run on all interfaces so iPhone can connect via local network
    app.run(host='0.0.0.0', port=5000, debug=True)
