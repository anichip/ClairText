import cv2
import numpy as np
from PIL import Image
from pillow_heif import register_heif_opener, read_heif
import pytesseract

register_heif_opener()

#PART A : OPENCV PREPROCESSING
def preprocess_img(img_path):

    #1. get a BGR np.ndarray from the image_path
    bgr = cv2.imread(img_path)

    # If OpenCV can't read it, try with PIL (for HEIC files)
    if bgr is None:
        try:
            pil_image = Image.open(img_path)
            # Convert PIL image to OpenCV format (BGR)
            rgb_array = np.array(pil_image)
            if len(rgb_array.shape) == 3:
                bgr = cv2.cvtColor(rgb_array, cv2.COLOR_RGB2BGR)
            else:
                bgr = rgb_array
        except Exception as e:
            raise FileNotFoundError(f"Cannot read image: {img_path}. Error: {e}")

    if bgr is None:
        raise FileNotFoundError(f"Cannot read image: {img_path}")

    #2. convert to grayscale
    gray = cv2.cvtColor(bgr,cv2.COLOR_BGR2GRAY)

    #3. gaussian blur
    blur = cv2.GaussianBlur(gray,(5,5),1.0)

    #4. CLAHE + enhancement
    #   each image gets split into tiles to boost contrast
    clahe = cv2.createCLAHE(clipLimit=2.0,tileGridSize=(8,8))
    enh = clahe.apply(blur)

    return enh 

    # #5. Adaptive Threshold
    # binary = cv2.adaptiveThreshold(enh, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 35, 15)

######              #####               ####

#PART B : OCR Orientation detection + Fixing
def detect_orientation(img):

    #return the orientation info from tesseract 
    #also return a dictionaly with angle and confidence 

    try:
        osd = pytesseract.image_to_osd(img)
        angle = int(osd.split('\n')[2].split(":")[1].strip())
        return angle
    except:
        return 0 #The default is "no rotation needed"
    
def auto_rotate(img):

    angle = detect_orientation(img)

    if angle != 0 :
        #Rotate counter-clockwise based on the detected angle 
        if angle == 90:
            return cv2.rotate(img,cv2.ROTATE_90_COUNTERCLOCKWISE)
        elif angle == 180:
            return cv2.rotate(img,cv2.ROTATE_180)
        elif angle == 270:
            return cv2.rotate(img,cv2.ROTATE_90_CLOCKWISE)
    
    return img #will return if it's not any of those


######              #####               ####

#PART C : TEXT EXTRACTION 

def extract_text_tesseract(img):

    try: 
        #Apply threshold that is adaptive to make it easier for OCR 
        binary = cv2.adaptiveThreshold(img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 35, 15)

        #Tesseract config.
        # --psm 3 = The default , it will not assume a single uniform block of text
        # --oem 3 = Use both legacy and LSTM OCR engines
        custom_config = r'--oem 3 --psm 6'
        text = pytesseract.image_to_string(binary, config=custom_config)

        return text.strip()
    
    except Exception as e:
        raise RuntimeError(f"OCR extraction failed: {e}")
    
# def extract_text_easyocr(img):
#     """
#     Fallback: Extract text using EasyOCR
#     Returns: string of extracted text
#     """
#     try:
#         import easyocr
#         reader = easyocr.Reader(['en'], gpu=False)  # Set gpu=True if available
        
#         # EasyOCR expects numpy array
#         results = reader.readtext(img)
        
#         # Combine all detected text
#         text = ' '.join([result[1] for result in results])
#         return text.strip()
#     except ImportError:
#         raise ImportError("EasyOCR not installed. Run: pip install easyocr")
#     except Exception as e:
#         raise RuntimeError(f"EasyOCR extraction failed: {e}")

######              #####               ####

# PART D : FULL PIPELINE FOR PREPROCESSING

def preprocess_image_to_text(img_path, use_easyocr=False):

    #RETURN string of extracted text after doing OpenCV --> rotation --> extraction 

    #Step 1. Preprocess with OpenCV
    preprocessed = preprocess_img(img_path)

    # Step 2. rotation
    rotated = auto_rotate(preprocessed)

    # Step 3. extract text (rn I commented out easy ocr because I am putting my trust in Tesseract)
    # if not use_easyocr:
    raw_text = extract_text_tesseract(rotated)
    # else:
    #     raw_text = extract_text_easyocr(rotated)

    return raw_text



if __name__ == "__main__":
    enh = preprocess_img("/Users/r3alistic/Programming/VibeCoding/ClairText/IMG_4228.HEIC")
    cv2.imwrite("out_enh.png", enh)

    #Test the full pipeline 
    print("=" * 50)
    print("EXTRACTED TEXT (Tesseract):")
    print("=" * 50)
    text = preprocess_image_to_text("/Users/r3alistic/Programming/VibeCoding/ClairText/IMG_4228.HEIC")
    
    print(text)
    print("=" * 50)