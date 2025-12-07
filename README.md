# Inclusive AI UMKM - Payment Validation & Inventory System

**🎉 Now with Flutter Mobile App + Book OCR to Excel Feature!**

## Problem Statement
Mid-to-low businesses in Indonesia waste significant time manually verifying QRIS payments and managing inventory. This system automates:
1. **Payment Verification**: Automated validation of payment screenshots against bank notifications
2. **Inventory Management**: OCR-based stock tracking with predictive analysis
3. **Book Digitization**: Convert handwritten reports to Excel files (NEW!)

## Architecture Overview

```
Mobile App (Flutter) → Camera/Gallery → Upload Payment/Report
                              ↓
                    OCR Module (EasyOCR)
                    - Payment: Extract amount, date, reference
                    - Book: Extract table structure → Excel
                              ↓
                    FastAPI Backend (JWT Auth)
                              ↓
                    Database (Supabase PostgreSQL) + AI Forecasting
```

## Tech Stack

- **Frontend**: Flutter 3.0+ (Cross-platform mobile app)
- **Backend**: Python FastAPI with JWT authentication
- **Database**: Supabase PostgreSQL (production-ready) / SQLite (local fallback)
- **OCR**: EasyOCR (Indonesian + English support)
- **Authentication**: JWT with bcrypt password hashing
- **AI/ML**: Prophet for forecasting, pandas for data processing
- **Excel Export**: openpyxl for Excel file generation

## Project Structure

```
inclusive-ai-umkm/
├── mobile_app/          # Flutter mobile application (NEW!)
│   ├── lib/
│   │   ├── providers/   # State management
│   │   ├── screens/     # UI screens
│   │   └── services/    # API client
│   └── pubspec.yaml
├── backend/             # FastAPI backend
│   ├── api/             # API endpoints (includes auth & OCR)
│   ├── models/          # Database models (includes User)
│   └── services/        # Business logic (includes JWT & Book OCR)
├── ocr_module/          # Payment OCR & invoice parsing
├── uploads/             # File storage
│   ├── screenshots/
│   ├── book_reports/    # Handwritten book images (NEW!)
│   └── excel_files/     # Generated Excel files (NEW!)
├── bot/                 # Telegram bot (optional, can coexist with app)
└── tests/               # Unit tests
```

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)
```powershell
# Run the setup script (installs everything)
.\setup.ps1

# Start backend (in terminal 1)
.\run_backend.ps1

# Run Flutter app (in terminal 2)
.\run_flutter.ps1
```

### Option 2: Manual Setup

**Step 1: Install Python dependencies**
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

**Step 1.5: Configure Supabase Database (Optional but Recommended)**
```powershell
# Create .env file in project root
# Add your Supabase connection string:
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@[PROJECT-REF].supabase.co:6543/postgres

# Get connection string from: Supabase Dashboard → Settings → Database → Connection string
# Use port 6543 for connection pooling (recommended) or 5432 for direct connection
```

**Step 2: Install Flutter dependencies**
```powershell
cd mobile_app
flutter pub get
cd ..
```

**Step 3: Start backend**
```powershell
cd backend
python main.py
# Backend runs at http://localhost:8000
```

**Step 4: Run Flutter app**
```powershell
cd mobile_app
flutter run
```

**Step 5: Login**
- Username: `demo`
- Password: `demo123`

## 📱 Features

### 1. Payment Validation
- Upload payment screenshots via camera or gallery
- Automatic OCR extraction (amount, date, reference)
- Real-time matching with bank notifications
- Confidence scoring

### 2. Inventory Management
- Real-time stock tracking
- Low stock alerts
- Product search and filtering
- Sales forecasting with Prophet AI

### 3. Book OCR to Excel (NEW!)
- Capture handwritten book reports
- AI-powered table detection
- Convert to structured Excel format
- Download and share Excel files

### 4. Dashboard & Analytics
- Today's revenue and transaction count
- Pending payments overview
- Low stock warnings
- Quick action buttons

## 🔐 Authentication

The app uses JWT token-based authentication:
- Register new users via API
- Login to get access token
- Token auto-saved in SharedPreferences
- Auto-login on app restart

## 🗄️ Supabase Database Setup

### Initial Setup

1. **Create Supabase Project**
   - Go to [supabase.com](https://supabase.com) and create a new project
   - Wait for the project to be fully provisioned (2-3 minutes)

2. **Get Connection String**
   - Go to: **Settings → Database → Connection string**
   - Select **Connection pooling** mode (port 6543) for better performance
   - Copy the connection string
   - Replace `[YOUR-PASSWORD]` with your database password

3. **Configure Environment**
   ```powershell
   # Create .env file in project root
   DATABASE_URL=postgresql://postgres:your_password@your-project.supabase.co:6543/postgres
   ```

4. **Test Connection**
   ```powershell
   python backend/scripts/test_supabase_connection.py
   ```

### Migrating from SQLite to Supabase

If you have existing data in SQLite and want to migrate to Supabase:

1. **Backup SQLite Database** (optional but recommended)
   ```powershell
   copy backend\umkm_db.sqlite backend\umkm_db.sqlite.backup
   ```

2. **Run Migration Script**
   ```powershell
   python backend/scripts/migrate_to_supabase.py
   ```

3. **Verify Migration**
   - The script will show record counts for each table
   - Check that all data was migrated successfully

4. **Update .env File**
   - Ensure `DATABASE_URL` points to Supabase
   - Restart the backend server

5. **Test Application**
   ```powershell
   python test_system.py
   ```

### Supabase Features

- **Connection Pooling**: Use port 6543 for better performance with multiple connections
- **Direct Connection**: Use port 5432 for direct database access
- **Dashboard**: Access your database via Supabase dashboard for visual management
- **Backups**: Automatic daily backups (on paid plans)

## 📖 Documentation

- **[Mobile App Guide](mobile_app/README.md)** - Complete Flutter setup and usage
- **[Quick Start](mobile_app/QUICKSTART.md)** - Get started in 3 steps
- **[Migration Guide](MIGRATION_GUIDE.md)** - Telegram bot → Flutter app
- **[Update Summary](UPDATE_SUMMARY.md)** - Latest changes and features
- **[API Docs](http://localhost:8000/docs)** - Interactive API documentation

## 🎯 API Endpoints

### Authentication
```
POST /api/auth/register        # Create new user
POST /api/auth/token           # Login (get JWT token)
GET  /api/auth/me              # Get current user
```

### Payments
```
POST /api/payments/validate-screenshot
GET  /api/payments/pending
GET  /api/payments/stats/today
```

### Inventory
```
GET  /api/inventory/products
GET  /api/inventory/low-stock
GET  /api/inventory/forecast/{product_id}
POST /api/inventory/process-invoice
```

### OCR (NEW!)
```
POST /api/ocr/book-to-excel           # Convert handwritten book to Excel
GET  /api/ocr/download-excel/{id}     # Download Excel file
GET  /api/ocr/files                   # List user's files
```

## 🛠️ Tech Details

### Backend
- FastAPI for REST API
- SQLAlchemy ORM with Supabase PostgreSQL
- EasyOCR for text extraction
- Prophet for time-series forecasting
- JWT with python-jose
- Bcrypt for password hashing

### Mobile App
- Flutter with Material Design 3
- Provider for state management
- Dio for HTTP requests
- Image picker for camera/gallery
- Excel package for file handling
- Shared preferences for storage

## 🎬 Demo Flow

1. **Login** - Professional auth screen
2. **Dashboard** - View statistics and alerts
3. **Upload Payment** - Capture screenshot, auto-validate
4. **Check Inventory** - View stock, get predictions
5. **Book OCR** ⭐ - Convert handwritten report to Excel

## 🐛 Troubleshooting

### Backend won't start
```powershell
# Reinstall dependencies
pip install -r requirements.txt

# Check Python version
python --version  # Should be 3.8+

# Check database connection
python backend/scripts/test_supabase_connection.py
```

### Database Connection Issues
- **Connection refused**: Check your Supabase project is active and connection string is correct
- **Authentication failed**: Verify your database password in the connection string
- **Table not found**: Run migration script or ensure tables are created: `Base.metadata.create_all(bind=engine)`
- **Connection timeout**: Use connection pooling (port 6543) instead of direct connection (port 5432)

### Flutter app can't connect
- Backend must be running first
- Check API URL in `mobile_app/lib/services/api_service.dart`
- For Android emulator: Use `http://10.0.2.2:8000`
- For physical device: Use your computer's IP

### OCR not working
- Ensure good lighting when capturing images
- Keep camera steady
- Use clear, readable handwriting
- Check backend logs for errors

## 📊 Project Status

✅ Backend API (FastAPI)  
✅ Database models (SQLAlchemy)  
✅ Payment OCR (EasyOCR)  
✅ Authentication (JWT)  
✅ Flutter mobile app  
✅ Book OCR to Excel  
✅ Inventory forecasting  
⏳ Push notifications  
⏳ Offline mode  
⏳ Multi-language support  


```bash
cd bot
python telegram_bot.py
```

## MVP Features (Hackathon Scope)

### Phase 1: Payment Validation ✓
- [x] OCR from payment screenshots
- [x] Manual notification input (merchant forwards bank SMS)
- [x] Amount & timestamp matching
- [x] Auto-confirmation via bot

### Phase 2: Inventory Tracking
- [x] Deduct stock on validated payment
- [x] OCR for supplier invoices
- [x] Stock level queries via chat

### Phase 3: Predictive Analysis
- [x] Historical sales data collection
- [x] Simple time-series forecasting
- [x] Low stock alerts

## Demo Flow

1. Customer sends QRIS payment screenshot to business WhatsApp
2. Bot extracts: "Rp 50.000 | 14:35 | Ref: 123456"
3. Merchant's phone receives bank notification: "Dana masuk Rp 50.000"
4. Bot matches both → "✅ Payment verified! Kopi Susu x2 recorded."
5. Inventory updated: Kopi Susu stock -2
6. Bot alerts: "⚠️ Gula will run out in 3 days. Order 5kg now."

## Hackathon Winning Factors

1. **Inclusive UX**: No new app to learn - uses existing WhatsApp/Telegram
2. **Real Pain Point**: Solves actual UMKM problems in Indonesia
3. **Scalable**: Works for 1 merchant or 1000
4. **AI-Powered**: OCR + LLM + Predictive ML
5. **Market Fit**: QRIS adoption is exploding in Indonesia

## Next Steps After Hackathon

- Android app for automatic notification capture
- Official banking API integrations
- Multi-merchant dashboard
- Advanced fraud detection
- Marketplace integration (Tokopedia, Shopee)
