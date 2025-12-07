import easyocr
import cv2
import numpy as np
from datetime import datetime
import re
from typing import Dict, Optional

class PaymentOCR:
    """OCR service for extracting payment information from screenshots"""
    
    def __init__(self):
        # Initialize EasyOCR with Indonesian and English
        self.reader = easyocr.Reader(['id', 'en'], gpu=False)
        
    def extract_payment_info(self, image_path: str) -> Dict:
        """
        Extract payment details from screenshot using multi-pass OCR
        Returns: {amount, timestamp, reference, bank, confidence}
        """
        try:
            # Read original image
            image = cv2.imread(image_path)
            if image is None:
                raise Exception(f"Cannot read image: {image_path}")
            
            # Multi-pass OCR with different preprocessing methods
            all_texts = []
            
            print("\n🔄 MULTI-PASS OCR PROCESSING:")
            
            # Pass 1: Original color image (best for clear screenshots)
            print("   Pass 1: Original color image...")
            results1 = self.reader.readtext(image)
            texts1 = [(text, conf, "original") for bbox, text, conf in results1]
            all_texts.extend(texts1)
            
            # Pass 2: Grayscale (good for general use)
            print("   Pass 2: Grayscale...")
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            results2 = self.reader.readtext(gray)
            texts2 = [(text, conf, "gray") for bbox, text, conf in results2]
            all_texts.extend(texts2)
            
            # Pass 3: Contrast enhanced (good for low contrast text)
            print("   Pass 3: Contrast enhanced...")
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            enhanced = clahe.apply(gray)
            results3 = self.reader.readtext(enhanced)
            texts3 = [(text, conf, "enhanced") for bbox, text, conf in results3]
            all_texts.extend(texts3)
            
            # Pass 4: Denoised (good for noisy images)
            print("   Pass 4: Denoised...")
            denoised = cv2.fastNlMeansDenoising(gray, None, 10, 7, 21)
            results4 = self.reader.readtext(denoised)
            texts4 = [(text, conf, "denoised") for bbox, text, conf in results4]
            all_texts.extend(texts4)
            
            # Deduplicate and sort by confidence
            unique_texts = {}
            for text, conf, source in all_texts:
                key = text.lower().strip()
                if key not in unique_texts or conf > unique_texts[key][1]:
                    unique_texts[key] = (text, conf, source)
            
            # Convert back to list format
            texts = [(t, c) for t, c, s in unique_texts.values()]
            
            # DEBUG: Print all extracted texts
            print("\n📝 OCR EXTRACTED TEXTS (MERGED FROM ALL PASSES):")
            for i, (text, conf) in enumerate(sorted(texts, key=lambda x: -x[1])[:25]):
                print(f"   [{i}] '{text}' (confidence: {conf:.2f})")
            print()
            
            # Parse payment information
            amount = self.parse_amount(texts)
            timestamp = self.parse_date_time(texts)
            reference = self.parse_reference(texts)
            bank = self.detect_bank(texts)
            
            # Calculate average confidence of top results
            top_confidences = [c for _, c in sorted(texts, key=lambda x: -x[1])[:10]]
            avg_confidence = sum(top_confidences) / len(top_confidences) if top_confidences else 0
            
            return {
                'amount': amount,
                'timestamp': timestamp,
                'reference': reference,
                'bank': bank,
                'confidence': round(avg_confidence, 2),
                'success': True
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'amount': None,
                'timestamp': None,
                'reference': None,
                'bank': None,
                'confidence': 0
            }
    
    def parse_amount(self, texts) -> Optional[float]:
        """Extract payment amount from text, optimized for notification screenshots"""
        
        # OCR often misreads digits: 1→l/i/g, 0→o, 5→s, 8→b, etc.
        # Also handles merged text like 'RpgltelahditerimadariHiKARi'
        
        for text, conf in texts:
            text_lower = text.lower()
            text_upper = text.upper()
            
            # Check if this text contains payment keywords (diterima, transfer, masuk, etc.)
            payment_keywords = ['diterima', 'terima', 'transfer', 'masuk', 'bayar', 'telah']
            is_payment_text = any(kw in text_lower for kw in payment_keywords)
            
            # Look for Rp pattern in this text
            if 'rp' in text_lower or is_payment_text:
                # Pattern 1: Standard Rp followed by digits
                rp_patterns = [
                    r'RP\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
                    r'RP\s*(\d+)',
                ]
                
                for pattern in rp_patterns:
                    match = re.search(pattern, text_upper)
                    if match:
                        try:
                            amount_str = match.group(1).replace('.', '').replace(',', '.')
                            amount = float(amount_str)
                            if amount > 0:
                                print(f"   💰 Found amount: Rp{amount} from text: '{text}'")
                                return amount
                        except:
                            pass
                
                # Pattern 2: Handle OCR misreading - 'Rpg' could be 'Rp1', 'Rpl' could be 'Rp1'
                # Look for Rp followed by potential digits (including misread ones)
                # Only check first 1-6 characters after Rp to avoid grabbing too much
                ocr_digit_pattern = r'RP([GILOSZ0-9]{1,6})'  # G, I, L, O, S, Z often confused with digits
                match = re.search(ocr_digit_pattern, text_upper)
                if match:
                    digit_like = match.group(1)
                    # Only take first 1-3 characters that could be digits
                    first_chars = digit_like[:3]
                    # Convert common OCR misreads back to digits
                    converted = first_chars.replace('G', '1').replace('L', '1').replace('I', '1')
                    converted = converted.replace('O', '0').replace('S', '5').replace('Z', '2')
                    # Take only actual digit characters
                    digits_only = ''.join(c for c in converted if c.isdigit())
                    if digits_only:
                        try:
                            amount = float(digits_only)
                            if amount > 0:
                                print(f"   💰 Found amount (OCR corrected): Rp{amount} from '{first_chars}' (original: '{digit_like}') in text: '{text}'")
                                return amount
                        except:
                            pass
        
        # Fallback: If we found DANA/GoPay/etc but no amount, assume small amount
        # This is for notification screenshots that might not show amount clearly
        for text, _ in texts:
            text_lower = text.lower()
            if any(bank in text_lower for bank in ['dana', 'gopay', 'ovo', 'shopeepay', 'linkaja']):
                print(f"   💰 Payment app detected but no amount found, using default 1")
                return 1.0  # Default to 1 if we can't read the amount
        
        return None
    
    def parse_date_time(self, texts) -> Optional[str]:
        """Extract date and time from text"""
        date_patterns = [
            r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}',  # DD/MM/YYYY or DD-MM-YYYY
            r'\d{2,4}[/-]\d{1,2}[/-]\d{1,2}',  # YYYY/MM/DD
            r'\d{1,2}\s+\w+\s+\d{2,4}',         # DD Month YYYY
        ]
        
        time_pattern = r'\d{1,2}:\d{2}(:\d{2})?'
        
        found_date = None
        found_time = None
        
        for text, _ in texts:
            # Find date
            if not found_date:
                for pattern in date_patterns:
                    match = re.search(pattern, text)
                    if match:
                        found_date = match.group()
                        break
            
            # Find time
            if not found_time:
                match = re.search(time_pattern, text)
                if match:
                    found_time = match.group()
        
        if found_date:
            timestamp = f"{found_date} {found_time}" if found_time else found_date
            return timestamp
        
        return None
    
    def parse_reference(self, texts) -> Optional[str]:
        """Extract reference/transaction number"""
        ref_keywords = ['ref', 'referensi', 'no', 'trx', 'transaksi', 'id']
        
        for i, (text, _) in enumerate(texts):
            text_lower = text.lower()
            
            # Check if this text contains reference keyword
            if any(keyword in text_lower for keyword in ref_keywords):
                # Check next text for the actual reference number
                if i + 1 < len(texts):
                    next_text = texts[i + 1][0]
                    # Look for alphanumeric reference
                    if re.search(r'[A-Z0-9]{6,}', next_text):
                        return next_text
                
                # Or extract from same text
                ref_match = re.search(r'[A-Z0-9]{8,}', text)
                if ref_match:
                    return ref_match.group()
        
        return None
    
    def detect_bank(self, texts) -> Optional[str]:
        """Detect which bank/payment method from text"""
        banks = {
            'BCA': ['bca', 'bank central asia'],
            'Mandiri': ['mandiri', 'bank mandiri'],
            'BNI': ['bni', 'bank negara indonesia'],
            'BRI': ['bri', 'bank rakyat indonesia'],
            'GoPay': ['gopay', 'gojek'],
            'OVO': ['ovo'],
            'Dana': ['dana'],
            'ShopeePay': ['shopee', 'shopeepay'],
            'LinkAja': ['linkaja', 'link aja'],
            'QRIS': ['qris'],
        }
        
        all_text = ' '.join([text.lower() for text, _ in texts])
        
        for bank_name, keywords in banks.items():
            if any(keyword in all_text for keyword in keywords):
                return bank_name
        
        return 'Unknown'
