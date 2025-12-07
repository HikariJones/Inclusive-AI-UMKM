# Setup Guide: 90%+ Confidence OCR

## Quick Setup (5 minutes)

### Step 1: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 2: Configure API Keys

#### Option A: Google Cloud Vision (Recommended)
1. Go to https://console.cloud.google.com/
2. Create new project
3. Enable Vision API
4. Create service account credentials
5. Download JSON credentials
6. Set environment variable:
   ```
   GOOGLE_APPLICATION_CREDENTIALS=path/to/credentials.json
   ```

#### Option B: Gemini API (Free Tier)
1. Go to https://ai.google.dev
2. Click "Get API Key"
3. Create new API key
4. Add to `.env`:
   ```
   GEMINI_API_KEY=your_key_here
   ```

### Step 3: Start Backend
```bash
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

### Step 4: Test
```bash
curl -X POST http://localhost:8000/api/ocr/book-to-excel \
  -H "Authorization: Bearer <token>" \
  -F "file=@image.jpg"
```

## Enabling 90%+ Confidence

### Google Cloud Vision
- Highest accuracy (90%+)
- Requires billing enabled
- Best for clear, printed text and quality handwriting

### Gemini Vision
- Excellent for handwriting (90%+)
- Free tier available (60 requests/minute)
- More tolerant of poor image quality

### Optimization Tips
1. **Image Quality**: Clear, high-resolution images (2000x2000+ pixels)
2. **Lighting**: Well-lit, minimal shadows
3. **Paper**: White/light background, dark ink/pencil
4. **Angle**: Straight, non-rotated images
5. **Resolution**: Minimum 150 DPI

## Architecture

```
User Upload
    ↓
Google Cloud Vision API
    ↓ (if billing disabled or error)
Gemini Vision API
    ↓ (on success)
Extract Text + Positions
    ↓
Detect Table Structure
    ↓
Normalize Data
    ↓
Export to Excel
    ↓
Download Link
```

## Confidence Scoring

- **0.9-1.0**: Excellent (clear text, optimal conditions)
- **0.7-0.9**: Good (readable, minor issues)
- **0.5-0.7**: Fair (some recognition errors)
- **< 0.5**: Poor (image quality issues)

## Production Checklist

- [ ] API keys configured
- [ ] Billing enabled (if using GCV)
- [ ] Backend running
- [ ] Database initialized
- [ ] Uploads directory writable
- [ ] CORS configured
- [ ] Authentication enabled
- [ ] Rate limiting configured

## Support

For issues:
1. Check `.env` file has correct API keys
2. Verify API key has billing enabled (GCV)
3. Check image quality and format
4. Review logs for error messages
5. Refer to ADVANCED_OCR_COMPLETE.md for detailed documentation
