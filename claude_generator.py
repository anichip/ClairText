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
2. A Feynman-style explanation - a simple, relatable analogy or example that makes the word instantly understandable

Return your response as JSON with this exact structure:
{{
    "definition": "your definition here",
    "example": "your Feynman-style example here"
}}

Important:
- Keep the definition simple and clear
- The Feynman example should use everyday situations or objects
- Make it memorable and easy to understand
- Don't use the word itself in the explanation"""

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
    Enrich multiple words with Claude-generated content

    Args:
        words: List of word dicts with 'word', 'definition', 'example', 'difficulty'
        context_text: The original text

    Returns:
        List of enriched word dicts
    """
    enriched = []

    for word_data in words:
        word = word_data['word']
        print(f"Generating definition for '{word}'...")

        definition, example = enrich_word(word, context_text)

        enriched.append({
            'word': word,
            'definition': definition,
            'example': example,
            'difficulty': word_data['difficulty']
        })

    return enriched
