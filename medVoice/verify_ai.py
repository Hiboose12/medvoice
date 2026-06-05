import os
import django
import sys

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'medVoice.settings')
django.setup()

from ai_verification.services import TextValidationService, ImageValidationService

def test_text_validation():
    print("\nXXX Testing Text Validation XXX")
    
    # Test cases
    samples = [
        ("The doctor was very helpful.", True),
        ("I need an appointment for surgery.", True),
        ("The food at the restaurant was bad.", False),
        ("My car broke down on the highway.", False),
        ("Emergency ward was crowded.", True),
        ("I love playing video games.", False),
    ]

    for text, expected in samples:
        is_valid, score = TextValidationService.validate(text)
        status = "PASS" if is_valid == expected else "FAIL"
        print(f"[{status}] Text: '{text}' -> Valid: {is_valid} (Score: {score:.2f}) | Expected: {expected}")

def test_image_validation():
    print("\nXXX Testing Image Validation XXX")
    print("Skipping actual image file test as no sample image is guaranteed to exist.")
    print("Mocking successful load to check logic flow...")
    
    # We can't easily query image without a file. 
    # But we can check if the class loads without error.
    try:
        service = ImageValidationService()
        print("ImageValidationService class loaded successfully.")
    except Exception as e:
        print(f"Error loading ImageValidationService: {e}")

    # Test Secure Default (Fail Closed)
    print("Testing Secure Default on missing/invalid file...")
    is_valid, score = ImageValidationService.validate("non_existent_file.jpg")
    if is_valid is False and score == 0.0:
        print("[PASS] Secure Default Verified: Returns False, 0.0 on error.")
    else:
        print(f"[FAIL] Secure Default Failed: Returned {is_valid}, {score}")

if __name__ == "__main__":
    test_text_validation()
    test_image_validation()
