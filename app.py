"""
ClairText Flask Backend
Receives text from Swift app and returns word analysis
"""

from flask import Flask, request, jsonify

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

    # Dummy response - will be replaced with real analysis later
    dummy_words = [
        {
            "word": "ambivalent",
            "definition": "Having mixed feelings or contradictory ideas about something",
            "example": "Like being hungry but not knowing what to eat - you want food but can't decide",
            "difficulty": 0.8
        },
        {
            "word": "ephemeral",
            "definition": "Lasting for a very short time",
            "example": "Like a Snapchat message that disappears - it's there briefly then gone",
            "difficulty": 0.9
        },
        {
            "word": "pragmatic",
            "definition": "Dealing with things sensibly and realistically",
            "example": "Like choosing sneakers over heels for a day of walking - practical choice",
            "difficulty": 0.7
        }
    ]

    return jsonify({'words': dummy_words})

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    # Run on all interfaces so iPhone can connect via local network
    app.run(host='0.0.0.0', port=5000, debug=True)
