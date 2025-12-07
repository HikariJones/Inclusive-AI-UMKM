# Google Cloud Setup

## Prerequisites
- Google account
- Credit/debit card (for billing)
- Google Cloud SDK installed (optional)

## Step 1: Create Google Cloud Project

1. Go to https://console.cloud.google.com/
2. Click "Select a Project" → "New Project"
3. Enter project name: "Inclusive-AI-UMKM"
4. Click "Create"
5. Wait for project to be created (1-2 minutes)

## Step 2: Enable Vision API

1. In project dashboard, click "Enable APIs and Services"
2. Search for "Cloud Vision API"
3. Click on it and select "Enable"
4. Wait for enablement (30-60 seconds)

## Step 3: Create Service Account

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "Service Account"
3. Fill in:
   - Service account name: "ocr-processor"
   - Service account ID: Auto-filled
   - Description: "OCR processing for handwritten documents"
4. Click "Create and Continue"
5. Grant "Editor" role
6. Click "Continue"
7. Click "Done"

## Step 4: Create and Download Key

1. In Credentials page, find your service account
2. Click on it
3. Go to "Keys" tab
4. Click "Add Key" → "Create new key"
5. Choose "JSON"
6. Click "Create"
7. Save the JSON file to project root
8. Rename to `google-credentials.json`

## Step 5: Enable Billing

1. Go to "Billing" in left menu
2. Click "Link billing account"
3. Select or create billing account
4. Add payment method
5. Link to project

## Step 6: Configure Environment

Add to `.env`:
```
GOOGLE_APPLICATION_CREDENTIALS=google-credentials.json
```

## Step 7: Verify Setup

```bash
python -c "
from google.cloud import vision
import os

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'google-credentials.json'
client = vision.ImageAnnotatorClient()
print('✓ Google Cloud Vision configured successfully')
"
```

## Expected Costs

- First 1,000 requests/month: **Free**
- After 1,000: $1.50 per 1,000 requests
- For typical UMKM usage: **< $1/month**

## Troubleshooting

### Error: Billing disabled
- Go to Billing settings
- Verify account has payment method
- Wait 5 minutes for settings to propagate

### Error: Credentials not found
- Verify `google-credentials.json` exists
- Check `GOOGLE_APPLICATION_CREDENTIALS` in `.env`
- Verify file path is correct

### Error: Permission denied
- Go to "IAM & Admin"
- Verify service account has "Editor" role
- Wait 2 minutes for permissions to sync

## Support

- Google Cloud Documentation: https://cloud.google.com/vision/docs
- Pricing Calculator: https://cloud.google.com/products/calculator
- Support: https://cloud.google.com/support
