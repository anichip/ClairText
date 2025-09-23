import cv2
import numpy as np
from PIL import Image
from pillow_heif import register_heif_opener

register_heif_opener()

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
    blur = cv2.GaussianBlur(gray,(3,3),0.5)

    #4. CLAHE + enhancement
    #   each image gets split into tiles to boost contrast
    clahe = cv2.createCLAHE(clipLimit=2.0,tileGridSize=(8,8))
    enh = clahe.apply(blur)

    return enh 

    # #5. Adaptive Threshold
    # binary = cv2.adaptiveThreshold(enh, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 35, 15)

if __name__ == "__main__":
    enh = preprocess_img("/Users/r3alistic/Programming/VibeCoding/ClairText/IMG_3521.jpg")
    cv2.imwrite("out_enh.png", enh)