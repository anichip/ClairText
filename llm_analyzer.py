import base64
import json
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from datetime import datetime
import cv2
import numpy as np

try:
    import openai
    OPENAI_AVAILABLE = True
except:
    OPENAI_AVAILABLE = False

@dataclass
class LLMVisionResult:
    output_info : Dict[str,Any]

@dataclass
class Word: 
    word: str
    definition: str 
    difficulty: str
    #why data class? Easier validation

class LLMAnalyzer:
    
    def __init__(self,api_key,model):

        self.model = model 
        self.client = openai.OpenAI(api_key=api_key)

        #JSON output schema 
        self.output_json_schema = {
            "type": "object",
            "properties": {
                "big_words": {
                    "type": "array",
                    "maxItems": 10,
                    "items": {
                        "type": "object",
                        "properties": {
                            "word": {"type": "string"},
                            "definition": {"type": "string"},
                            "difficulty": {"type": "number", "minimum": 0.0, "maximum": 1.0}
                        },
                        "required": ["word", "definition", "difficulty"],
                        "additionalProperties": False
                    }
                }
            },
            "required": ["big_words"],
            "additionalProperties": False
}


    


