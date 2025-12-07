"""
Advanced OCR Service - Google Cloud Vision + Gemini Vision
Priority: Google Cloud Vision (90%+) → Gemini Vision (90%+)
"""

import os
import cv2
import numpy as np
import pandas as pd
from typing import Dict, List, Tuple, Optional
import time
from pathlib import Path
from PIL import Image

# Google Cloud Vision (primary)
try:
    from google.cloud import vision
    GOOGLE_VISION_AVAILABLE = True
except ImportError:
    GOOGLE_VISION_AVAILABLE = False

# Google Gemini Vision (fallback)
try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False


class AdvancedOCR:
    """
    Premium OCR service with 90%+ accuracy for handwritten documents.
    Primary: Google Cloud Vision (requires credentials but excellent accuracy)
    Fallback: Google Gemini Vision (requires API key, great for handwriting)
    """
    
    def __init__(self):
        """Initialize OCR with backend selection priority"""
        self.backend = None
        self.client = None
        self.model = None
        
        # Priority 1: Google Cloud Vision (90%+)
        if GOOGLE_VISION_AVAILABLE and os.getenv('GOOGLE_APPLICATION_CREDENTIALS'):
            try:
                self.client = vision.ImageAnnotatorClient()
                self.backend = "GOOGLE_VISION"
                print("[OCR] Using Google Cloud Vision (90%+ accuracy)")
            except Exception as e:
                print(f"[OCR] Google Cloud Vision error: {e}")
                self.client = None
        
        # Priority 2: Gemini Vision (90%+ for handwriting)
        if self.backend is None:
            gemini_key = os.getenv('GEMINI_API_KEY')
            if GEMINI_AVAILABLE and gemini_key and gemini_key != 'your_gemini_api_key':
                try:
                    genai.configure(api_key=gemini_key)
                    self.model = genai.GenerativeModel('gemini-2.0-flash')
                    self.backend = "GEMINI_VISION"
                    print("[OCR] Using Google Gemini Vision (90%+ accuracy for handwriting)")
                except Exception as e:
                    print(f"[OCR] Gemini Vision error: {e}")
                    self.model = None
        
        if self.backend is None:
            raise RuntimeError("No OCR backend available. Set GOOGLE_APPLICATION_CREDENTIALS or GEMINI_API_KEY")
        
        # Minimum confidence threshold
        self.min_confidence = 0.3
    
    def _deskew(self, gray: np.ndarray) -> np.ndarray:
        """Deskew image using Hough line detection"""
        edges = cv2.Canny(gray, 50, 150, apertureSize=3)
        lines = cv2.HoughLines(edges, 1, np.pi / 180, 200)
        
        if lines is None:
            return gray
        
        angles = []
        for rho, theta in lines[:, 0]:
            angle = (theta * 180 / np.pi) - 90
            if -45 < angle < 45:
                angles.append(angle)
        
        if not angles:
            return gray
        
        median_angle = np.median(angles)
        (h, w) = gray.shape[:2]
        M = cv2.getRotationMatrix2D((w // 2, h // 2), median_angle, 1.0)
        return cv2.warpAffine(gray, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
    
    def preprocess_image(self, image: np.ndarray) -> np.ndarray:
        """Minimal preprocessing - let Tesseract LSTM do the heavy lifting"""
        # Convert to grayscale
        if len(image.shape) == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        else:
            gray = image
        
        # Only basic contrast normalization
        normalized = cv2.normalize(gray, None, 0, 255, cv2.NORM_MINMAX)
        
        return normalized
    
    def extract_with_google_vision(self, image_path: str) -> List[Tuple[str, Tuple[int, int], float]]:
        """Extract text using Google Cloud Vision API (90%+ accuracy)"""
        with open(image_path, 'rb') as image_file:
            content = image_file.read()
        
        image = vision.Image(content=content)
        response = self.client.document_text_detection(image=image)
        
        text_positions = []
        
        # Process document text with layout
        if response.full_text_annotation:
            for page in response.full_text_annotation.pages:
                for block in page.blocks:
                    for paragraph in block.paragraphs:
                        for word in paragraph.words:
                            text = ''.join([symbol.text for symbol in word.symbols])
                            confidence = np.mean([symbol.confidence for symbol in word.symbols]) if word.symbols else 0.0
                            
                            # Filter low confidence
                            if confidence < 0.2 or not text.strip():
                                continue
                            
                            # Get bounding box center
                            vertices = word.bounding_box.vertices
                            if vertices:
                                center_y = int(np.mean([v.y for v in vertices]))
                                center_x = int(np.mean([v.x for v in vertices]))
                                text_positions.append((text, (center_y, center_x), confidence))
        
        return text_positions
    
    def extract_with_gemini(self, image_path: str) -> List[Tuple[str, Tuple[int, int], float]]:
        """Extract text using Google Gemini Vision (excellent for handwriting)"""
        try:
            # Read and encode image
            with open(image_path, 'rb') as f:
                image_data = f.read()
            
            # Open with PIL for Gemini
            pil_image = Image.open(image_path)
            
            # Prompt optimized for handwritten text extraction with positioning
            prompt = """Analyze this handwritten document image and extract ALL visible text.
For each word or number you find:
1. Extract the exact text content
2. Estimate its Y position (row number, starting from 1 at top)
3. Estimate its X position (column number, starting from 1 at left)
4. Rate your confidence (0-100%)

Format each entry as: TEXT|Y|X|CONFIDENCE
Example: "Book|5|10|85" means "Book" at row 5, column 10, 85% confident

Extract EVERYTHING you can read, even if confidence is low. Be thorough."""

            # Generate content with Gemini
            response = self.model.generate_content([prompt, pil_image])
            
            text_positions = []
            
            # Parse response
            if response.text:
                lines = response.text.strip().split('\n')
                for line in lines:
                    line = line.strip()
                    if '|' in line:
                        try:
                            parts = line.split('|')
                            if len(parts) >= 4:
                                text = parts[0].strip()
                                y = int(parts[1].strip())
                                x = int(parts[2].strip())
                                conf = float(parts[3].strip().replace('%', '')) / 100.0
                                
                                if text and conf >= 0.2:  # Lenient threshold for handwriting
                                    text_positions.append((text, (y * 20, x * 20), conf))
                        except (ValueError, IndexError):
                            continue
            
            return text_positions
            
        except Exception as e:
            print(f"[ERROR] Gemini extraction failed: {e}")
            return []
    
    def extract_with_tesseract(self, image_path: str) -> List[Tuple[str, Tuple[int, int], float]]:
        """Removed - Tesseract no longer supported"""
        raise NotImplementedError("Tesseract backend has been removed")
    
    def extract_text_with_positions(self, image_path: str) -> List[Tuple[str, Tuple[int, int], float]]:
        """Main extraction method - uses best available backend with fallback"""
        if self.backend == "GOOGLE_VISION":
            try:
                result = self.extract_with_google_vision(image_path)
                if result:  # If Google Vision succeeded
                    return result
                # If empty result, try fallback
                print("[OCR] Google Vision returned no results, trying Gemini fallback...")
                if GEMINI_AVAILABLE and os.getenv('GEMINI_API_KEY') and os.getenv('GEMINI_API_KEY') != 'your_gemini_api_key':
                    try:
                        genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
                        self.model = genai.GenerativeModel('gemini-2.0-flash')
                        return self.extract_with_gemini(image_path)
                    except Exception as e:
                        print(f"[ERROR] Gemini fallback failed: {e}")
                return []
            except Exception as e:
                print(f"[ERROR] Google Cloud Vision extraction error: {e}")
                # Try fallback on error
                if GEMINI_AVAILABLE and os.getenv('GEMINI_API_KEY') and os.getenv('GEMINI_API_KEY') != 'your_gemini_api_key':
                    try:
                        print("[OCR] Falling back to Gemini Vision...")
                        genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
                        self.model = genai.GenerativeModel('gemini-2.0-flash')
                        return self.extract_with_gemini(image_path)
                    except Exception as e2:
                        print(f"[ERROR] Gemini fallback also failed: {e2}")
                return []
        elif self.backend == "GEMINI_VISION":
            return self.extract_with_gemini(image_path)
        else:
            raise RuntimeError(f"Unknown backend: {self.backend}")
    
    def detect_table_structure(self, text_positions: List[Tuple[str, Tuple[int, int], float]]) -> List[List[str]]:
        """Detect table structure from positioned text"""
        if not text_positions:
            return []
        
        # Group by Y position (rows)
        ys = [y for _, (y, _), _ in text_positions]
        ys_sorted = sorted(ys)
        gaps = [ys_sorted[i + 1] - ys_sorted[i] for i in range(len(ys_sorted) - 1)]
        median_gap = np.median(gaps) if gaps else 30
        y_threshold = max(15, min(50, median_gap * 1.3))
        
        rows = []
        current_row = []
        previous_y = None
        
        for text, (y, x), confidence in text_positions:
            if previous_y is None or abs(y - previous_y) < y_threshold:
                current_row.append((text, x, confidence))
            else:
                if current_row:
                    current_row.sort(key=lambda item: item[1])
                    rows.append([item[0] for item in current_row])
                current_row = [(text, x, confidence)]
            previous_y = y
        
        if current_row:
            current_row.sort(key=lambda item: item[1])
            rows.append([item[0] for item in current_row])
        
        # Adaptive column detection
        if rows and text_positions:
            xs = [x for _, _, (_, x), _ in [(None, None, (0, x), None) for _, (_, x), _ in text_positions]]
            
            if xs and len(xs) > 1:
                xs_sorted = sorted(xs)
                x_gaps = [xs_sorted[i + 1] - xs_sorted[i] for i in range(len(xs_sorted) - 1)]
                
                if x_gaps:
                    median_x_gap = np.median(x_gaps)
                    col_gap_threshold = max(20, median_x_gap * 2)
                    
                    column_clusters = []
                    current_cluster = [xs_sorted[0]]
                    
                    for i in range(1, len(xs_sorted)):
                        if xs_sorted[i] - current_cluster[-1] < col_gap_threshold:
                            current_cluster.append(xs_sorted[i])
                        else:
                            col_center = np.median(current_cluster)
                            column_clusters.append(col_center)
                            current_cluster = [xs_sorted[i]]
                    
                    if current_cluster:
                        col_center = np.median(current_cluster)
                        column_clusters.append(col_center)
                    
                    # Realign rows if we found reasonable columns
                    if 1 < len(column_clusters) < len(rows[0]) if rows else False:
                        max_len = len(column_clusters)
                        aligned_rows = []
                        
                        for row in rows:
                            aligned_row = ["" for _ in range(max_len)]
                            for cell_text in row:
                                for text, (_, cell_x), _ in text_positions:
                                    if text == cell_text:
                                        nearest_col = min(range(len(column_clusters)), 
                                                         key=lambda i: abs(cell_x - column_clusters[i]))
                                        if aligned_row[nearest_col] == "":
                                            aligned_row[nearest_col] = cell_text
                                        else:
                                            aligned_row[nearest_col] += " " + cell_text
                                        break
                            aligned_rows.append(aligned_row)
                        
                        rows = aligned_rows
        
        return rows
    
    def clean_and_normalize_data(self, rows: List[List[str]]) -> pd.DataFrame:
        """Clean and normalize table data"""
        if not rows:
            return pd.DataFrame()
        
        row_lengths = [len(row) for row in rows]
        num_columns = max(set(row_lengths), key=row_lengths.count) if row_lengths else 0
        
        if num_columns == 0:
            return pd.DataFrame()
        
        normalized_rows = []
        for row in rows:
            row = [str(item) if item else '' for item in row]
            
            if len(row) < num_columns:
                row.extend([''] * (num_columns - len(row)))
            elif len(row) > num_columns:
                row = row[:num_columns]
            
            normalized_rows.append(row)
        
        header_row = normalized_rows[0] if normalized_rows else []
        data_rows = normalized_rows[1:] if len(normalized_rows) > 1 else []
        
        if data_rows:
            df = pd.DataFrame(data_rows, columns=header_row if header_row else None)
        else:
            df = pd.DataFrame(columns=header_row if header_row else None)
        
        df = df.replace('', np.nan)
        
        for col in df.columns:
            try:
                df[col] = pd.to_numeric(df[col], errors='ignore')
            except Exception:
                pass
        
        return df
    
    def extract_table_from_image(self, image_path: str) -> Dict:
        """Main extraction pipeline"""
        start_time = time.time()
        try:
            text_positions = self.extract_text_with_positions(image_path)
            
            if not text_positions:
                return {
                    "success": False,
                    "error": "No text detected",
                    "rows_extracted": 0,
                    "columns_detected": 0,
                    "data": None,
                    "confidence": 0,
                    "processing_time_seconds": round(time.time() - start_time, 2),
                    "backend": self.backend
                }
            
            rows = self.detect_table_structure(text_positions)
            
            if not rows:
                return {
                    "success": False,
                    "error": "Could not detect table structure",
                    "rows_extracted": 0,
                    "columns_detected": 0,
                    "data": None,
                    "confidence": 0,
                    "processing_time_seconds": round(time.time() - start_time, 2),
                    "backend": self.backend
                }
            
            df = self.clean_and_normalize_data(rows)
            
            rows_extracted = len(df)
            columns_detected = len(df.columns)
            preview = df.head(5).to_string() if not df.empty else "No data"
            avg_conf = sum([conf for _, _, conf in text_positions]) / len(text_positions)
            
            return {
                "success": True,
                "rows_extracted": rows_extracted,
                "columns_detected": columns_detected,
                "data": df,
                "preview": preview,
                "confidence": round(float(avg_conf), 4),
                "processing_time_seconds": round(time.time() - start_time, 2),
                "backend": self.backend
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "rows_extracted": 0,
                "columns_detected": 0,
                "data": None,
                "confidence": 0,
                "processing_time_seconds": round(time.time() - start_time, 2),
                "backend": self.backend
            }
    
    def save_to_excel(self, df: pd.DataFrame, output_path: str):
        """Save DataFrame to Excel"""
        with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
            df.to_excel(writer, index=False, sheet_name='Laporan')
            
            worksheet = writer.sheets['Laporan']
            for idx, col in enumerate(df.columns):
                max_length = max(
                    df[col].astype(str).apply(len).max(),
                    len(str(col))
                )
                worksheet.column_dimensions[chr(65 + idx)].width = min(max_length + 2, 50)
