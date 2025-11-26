import cv2
import numpy as np
from PIL import Image
from pillow_heif import register_heif_opener, read_heif
import pytesseract
import easyocr

register_heif_opener()

#PART A : OPENCV PREPROCESSING
def preprocess_img(img_path):

    #1. get a BGR np.ndarray from the image_path
    bgr = cv2.imread(img_path)

    # If OpenCV can't read it, try with PIL (for HEIC files)
    if bgr is None:
        try:
            # Check if it's a HEIC file and handle explicitly
            if img_path.lower().endswith(('.heic', '.heif')):
                heif_file = read_heif(img_path)
                pil_image = Image.frombytes(
                    heif_file.mode,
                    heif_file.size,
                    heif_file.data,
                    "raw",
                )
            else:
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

    #1b. auto-cropping with OpenCV
    # bgr = auto_crop_to_text_simple(bgr)
    # cv2.imwrite("cropped_bgr_debug.png", bgr)

    #2. convert to grayscale
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)

    #3. gaussian blur
    blur = cv2.GaussianBlur(gray, (5,5), 1.0)

    #4. CLAHE + enhancement
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    enh = clahe.apply(blur)

    return enh

#part of part a. auto-cropping with OpenCV
# def auto_crop_to_text_simple(img):
#     """
#     Aggressively crop to just text content, removing fingers/shadows/margins
#     """
#     if len(img.shape) == 3:
#         gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
#     else:
#         gray = img.copy()
    
#     # Threshold to get text (invert so text is white)
#     _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV)
    
#     # Remove small noise speckles
#     kernel_small = np.ones((3,3), np.uint8)
#     binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel_small)
    
#     # Project text density onto axes
#     row_density = np.sum(binary, axis=1) / 255
#     col_density = np.sum(binary, axis=0) / 255
    
#     # Use a higher threshold to ignore sparse noise at edges
#     row_threshold = np.max(row_density) * 0.15
#     col_threshold = np.max(col_density) * 0.15
    
#     # Find rows and columns with substantial text
#     text_rows = np.where(row_density > row_threshold)[0]
#     text_cols = np.where(col_density > col_threshold)[0]
    
#     if len(text_rows) == 0 or len(text_cols) == 0:
#         print("No text detected! Returning original image.")
#         return img
    
#     top = text_rows[0]
#     bottom = text_rows[-1]
#     left = text_cols[0]
#     right = text_cols[-1]
    
#     # Apply aggressive inset to remove edge artifacts
#     height = bottom - top
#     width = right - left
    
#     vertical_inset = int(height * 0.05)
#     horizontal_inset = int(width * 0.08)
    
#     top = top + vertical_inset
#     bottom = bottom - vertical_inset
#     left = left + horizontal_inset
#     right = right - horizontal_inset
    
#     # Ensure we don't go out of bounds
#     top = max(0, top)
#     bottom = min(img.shape[0], bottom)
#     left = max(0, left)
#     right = min(img.shape[1], right)
    
#     cropped = img[top:bottom, left:right]
#     return cropped

######              #####               ####

#PART B : OCR Orientation detection + Fixing
def detect_orientation(img):
    try:
        osd = pytesseract.image_to_osd(img)
        angle = int(osd.split('\n')[2].split(":")[1].strip())
        return angle
    except:
        return 0
    
def auto_rotate(img):
    angle = detect_orientation(img)

    #fix only big big angle changes
    if angle != 0:
        if angle == 90:
            return cv2.rotate(img, cv2.ROTATE_90_COUNTERCLOCKWISE)
        elif angle == 180:
            return cv2.rotate(img, cv2.ROTATE_180)
        elif angle == 270:
            return cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)
        
    return img

######              #####               ####

#PART C : TEXT EXTRACTION 

def extract_text_tesseract(img):
    try: 
        binary = cv2.adaptiveThreshold(img, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 35, 15)

        #custom config. 
        custom_config = r'--oem 3 --psm 6'
        text = pytesseract.image_to_string(binary, config=custom_config)

        return text.strip()
    
    except Exception as e:
        raise RuntimeError(f"OCR extraction failed: {e}")
    
def extract_text_easyocr(img):
    """
    Fallback: Extract text using EasyOCR
    """
    try:
        import easyocr
        reader = easyocr.Reader(['en'], gpu=False)
        
        # EasyOCR expects numpy array
        results = reader.readtext(img)
        
        # Combine all detected text
        text = ' '.join([result[1] for result in results])
        return text.strip()
    
    except ImportError:
        raise ImportError("EasyOCR not installed. Run: pip install easyocr")
    except Exception as e:
        raise RuntimeError(f"EasyOCR extraction failed: {e}")

######              #####               ####

# PART D : FULL PIPELINE FOR PREPROCESSING

def preprocess_image_to_text(img_path):
    #Step 1. Preprocess with OpenCV
    preprocessed = preprocess_img(img_path)

    # Step 2. rotation
    rotated = auto_rotate(preprocessed)

    # Step 3. extract text. EasyOCR is the move
    raw_text = extract_text_easyocr(rotated)

    return raw_text


if __name__ == "__main__":
    enh = preprocess_img("/Users/r3alistic/Programming/VibeCoding/ClairText/IMG_4227.HEIC")
    cv2.imwrite("out_enh.png", enh)

    #Test the full pipeline 
    print("=" * 50)
    print("EXTRACTED TEXT (EasyOCR):")
    print("=" * 50)
    text = preprocess_image_to_text("/Users/r3alistic/Programming/VibeCoding/ClairText/IMG_4227.HEIC")
    
    print(text)
    print("=" * 50)