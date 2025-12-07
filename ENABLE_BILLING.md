# Enable Billing for Google Cloud Vision

## Why Enable Billing?

- **Free tier**: 1,000 requests/month (usually exhausted quickly during testing)
- **With billing**: Unlimited requests at $1.50 per 1,000
- **Performance**: No rate limiting with billing
- **Cost**: Negligible for small businesses (< $2/month typical usage)

## Quick Setup

### 1. Go to Billing
https://console.cloud.google.com/billing

### 2. Add Payment Method
- Click "Billing accounts"
- Click "Create Account"
- Enter business/personal name
- Add credit or debit card

### 3. Link to Project
- Go to "My Projects"
- Select your OCR project
- Click "..." menu
- Select "Edit Project Settings"
- Change billing account to your new one

### 4. Verify
Wait 5 minutes, then test:

```bash
python -c "
from google.cloud import vision
from google.cloud.vision_v1 import types

client = vision.ImageAnnotatorClient()
# Make a test request
print('✓ Billing enabled - API ready')
"
```

## Pricing

| Requests | Cost |
|----------|------|
| 1-1,000 | Free |
| 1,001-10,000 | $1.50/1,000 |
| 10,001+ | $0.75/1,000 |
| 100,000+ | $0.60/1,000 |

## Typical Usage Costs

- 100 documents/month: **Free** (under 1,000)
- 500 documents/month: **Free** (under 1,000)
- 2,000 documents/month: **$1.50**
- 10,000 documents/month: **$15**

## Troubleshooting

### Issue: Billing not reflecting
- Wait 5 minutes
- Refresh page
- Check all projects are linked to correct account

### Issue: Payment method rejected
- Verify card details
- Try different payment method
- Contact Google Cloud Support

### Issue: Still getting rate limited
- Verify billing is active (not just added)
- Check if you selected right project
- May need to restart application

## Support

- Billing FAQ: https://cloud.google.com/billing/docs/concepts
- Support: https://cloud.google.com/support
