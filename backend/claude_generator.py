"""
Claude Haiku integration for generating word definitions and Feynman examples
"""

import os
import json
from anthropic import Anthropic
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Anthropic client
client = Anthropic(api_key=os.getenv('ANTHROPIC_API_KEY'))

def enrich_word(word, context_text):
    """
    Use Claude Haiku to generate definition and Feynman example for a word

    Args:
        word: The complex word to explain
        context_text: The original text where this word appeared (for context)

    Returns:
        tuple: (definition, feynman_example)
    """
    # Truncate context if too long (keep it under 1000 chars for efficiency)
    context_snippet = context_text[:1000] + "..." if len(context_text) > 1000 else context_text

    prompt = f"""You are helping a reader understand a complex word they encountered while reading.

Word: "{word}"

Context from their book:
{context_snippet}

Please provide:
1. A clear, concise definition (1-2 sentences max)
2. A Feynman-style explanation - a simple, relatable analogy or example that makes the word instantly understandable (1-3 sentences max)

Return your response as JSON with this exact structure:
{{
    "definition": "your definition here",
    "example": "your Feynman-style example here"
}}

Important:
- Keep the definition simple and clear
- The Feynman example should use everyday situations or objects
- Make it memorable and easy to understand"""

    try:
        response = client.messages.create(
            model="claude-3-5-haiku-20241022",
            max_tokens=300,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )

        # Parse the JSON response
        content = response.content[0].text

        # Try to extract JSON from the response
        # Sometimes Claude wraps JSON in markdown code blocks
        if "```json" in content:
            # Extract JSON from code block
            json_start = content.find("```json") + 7
            json_end = content.find("```", json_start)
            content = content[json_start:json_end].strip()
        elif "```" in content:
            # Extract from generic code block
            json_start = content.find("```") + 3
            json_end = content.find("```", json_start)
            content = content[json_start:json_end].strip()

        result = json.loads(content)

        return result['definition'], result['example']

    except Exception as e:
        print(f"Error enriching word '{word}': {e}")
        # Fallback if Claude fails
        return (
            "Definition could not be generated",
            "Example could not be generated"
        )

def enrich_words(words, context_text):
    """
    Have Claude pick the best 3 words from candidates and enrich them

    Args:
        words: List of candidate word dicts with 'word', 'definition', 'example', 'difficulty'
        context_text: The original text

    Returns:
        List of up to 3 best enriched word dicts
    """
    # Safeguard: Handle empty list
    if not words:
        print("No words to enrich!")
        return []

    # Extract just the word strings
    candidate_words = [w['word'] for w in words]

    print(f"Asking Claude to pick best from {len(candidate_words)} candidates...")
    print(f"Candidates: {', '.join(candidate_words)}")

    prompt = f"""You are helping a reader build their vocabulary.

CANDIDATE WORDS (you MUST pick ONLY from this list):
{', '.join(candidate_words)}

Your task:
1. Pick the BEST words to learn from the CANDIDATE WORDS list above (up to 3 maximum, or all of them if fewer than 3 are available)
   - Prioritize words that are truly sophisticated/challenging (like "ephemeral", "ubiquitous", "heuristic")
   - Avoid words that are just long but common (like "underrepresented", "personalities")
   - Consider educational value and semantic complexity, not just length
   - ONLY select from the candidate words listed above

2. For each word you pick, provide:
   - A clear, concise definition (1-2 sentences max)
   - A Feynman-style explanation using simple, everyday analogies that make the concept instantly relatable

Return JSON in this exact format:
{{
    "words": [
        {{
            "word": "word1",
            "definition": "clear definition here",
            "example": "Feynman-style analogy here"
        }},
        {{
            "word": "word2",
            "definition": "clear definition here",
            "example": "Feynman-style analogy here"
        }},
        {{
            "word": "word3",
            "definition": "clear definition here",
            "example": "Feynman-style analogy here"
        }}
    ]
}}"""

    try:
        response = client.messages.create(
            model="claude-3-5-haiku-20241022",
            max_tokens=800,
            messages=[{
                "role": "user",
                "content": prompt
            }]
        )

        content = response.content[0].text

        # Extract JSON from response
        if "```json" in content:
            json_start = content.find("```json") + 7
            json_end = content.find("```", json_start)
            content = content[json_start:json_end].strip()
        elif "```" in content:
            json_start = content.find("```") + 3
            json_end = content.find("```", json_start)
            content = content[json_start:json_end].strip()

        result = json.loads(content)
        selected_words = result['words']

        print(f"Claude selected: {', '.join([w['word'] for w in selected_words])}")

        # Format for API response with difficulty scores
        enriched = []
        for word_data in selected_words:
            # Find the original difficulty score
            original = next((w for w in words if w['word'] == word_data['word']), None)
            difficulty = original['difficulty'] if original else 0.8

            enriched.append({
                'word': word_data['word'],
                'definition': word_data['definition'],
                'example': word_data['example'],
                'difficulty': difficulty
            })

        return enriched

    except Exception as e:
        print(f"Error in Claude selection: {e}")
        # Fallback: just take first 3 and generate definitions
        print("Falling back to first 3 words...")
        fallback = []
        for word_data in words[:3]:
            definition, example = enrich_word(word_data['word'], context_text)
            fallback.append({
                'word': word_data['word'],
                'definition': definition,
                'example': example,
                'difficulty': word_data['difficulty']
            })
        return fallback
