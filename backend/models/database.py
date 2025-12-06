from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import datetime
import os
from dotenv import load_dotenv

load_dotenv()

# Supabase PostgreSQL connection
# Format: postgresql://postgres:[YOUR-PASSWORD]@[PROJECT-REF].supabase.co:5432/postgres
# For connection pooling: postgresql://postgres:[YOUR-PASSWORD]@[PROJECT-REF].supabase.co:6543/postgres
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./umkm_db.sqlite")

# Configure engine based on database type
if DATABASE_URL.startswith("postgresql"):
    # PostgreSQL/Supabase configuration with connection pooling
    engine = create_engine(
        DATABASE_URL,
        pool_size=15,
        max_overflow=10,
        pool_pre_ping=True,  # Verify connections before using
        echo=False  # Set to True for SQL query logging
    )
else:
    # SQLite configuration (for local development/fallback)
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False}
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Models
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    full_name = Column(String(200))
    hashed_password = Column(String(200), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

class Payment(Base):
    __tablename__ = "payments"
    
    id = Column(Integer, primary_key=True, index=True)
    amount = Column(Float, nullable=False)
    reference_number = Column(String(100), unique=True, index=True)
    payment_date = Column(DateTime, nullable=False)
    screenshot_path = Column(String(500))
    
    # OCR extracted data
    ocr_amount = Column(Float)
    ocr_date = Column(DateTime)
    ocr_reference = Column(String(100))
    ocr_confidence = Column(Float)
    
    # Verification status
    is_verified = Column(Boolean, default=False)
    verified_at = Column(DateTime)
    notification_id = Column(Integer, ForeignKey("notifications.id"))
    
    # Additional info
    customer_name = Column(String(200))
    bank_name = Column(String(100))  # BCA, Mandiri, GoPay, Dana, etc.
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    notification = relationship("BankNotification", back_populates="payment")
    items = relationship("PaymentItem", back_populates="payment")

class BankNotification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    source = Column(String(100))  # BCA, Mandiri, GoPay, Dana, etc.
    raw_text = Column(Text, nullable=False)
    
    # Parsed data
    amount = Column(Float)
    transaction_date = Column(DateTime)
    reference_number = Column(String(100))
    sender_name = Column(String(200))
    
    # Status
    is_matched = Column(Boolean, default=False)
    matched_at = Column(DateTime)
    received_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    payment = relationship("Payment", back_populates="notification", uselist=False)

class Product(Base):
    __tablename__ = "products"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), nullable=False, unique=True, index=True)
    category = Column(String(100))
    unit = Column(String(50))  # pcs, kg, liter, etc.
    price = Column(Float, nullable=False)
    
    # Stock
    current_stock = Column(Float, default=0)
    min_stock = Column(Float, default=10)  # Low stock threshold
    
    # Stats
    total_sold = Column(Float, default=0)
    last_restocked_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    stock_movements = relationship("StockMovement", back_populates="product")
    payment_items = relationship("PaymentItem", back_populates="product")

class StockMovement(Base):
    __tablename__ = "stock_movements"
    
    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    
    # Movement details
    movement_type = Column(String(50))  # sale, restock, adjustment
    quantity = Column(Float, nullable=False)  # Positive for restock, negative for sale
    previous_stock = Column(Float, nullable=False)
    new_stock = Column(Float, nullable=False)
    
    # Reference
    reference_type = Column(String(50))  # payment, invoice, manual
    reference_id = Column(Integer)
    notes = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    product = relationship("Product", back_populates="stock_movements")

class PaymentItem(Base):
    __tablename__ = "payment_items"
    
    id = Column(Integer, primary_key=True, index=True)
    payment_id = Column(Integer, ForeignKey("payments.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    
    quantity = Column(Float, nullable=False)
    unit_price = Column(Float, nullable=False)
    subtotal = Column(Float, nullable=False)
    
    # Relationships
    payment = relationship("Payment", back_populates="items")
    product = relationship("Product", back_populates="payment_items")

class Invoice(Base):
    __tablename__ = "invoices"
    
    id = Column(Integer, primary_key=True, index=True)
    supplier_name = Column(String(200))
    invoice_number = Column(String(100))
    invoice_date = Column(DateTime)
    total_amount = Column(Float)
    
    # OCR data
    image_path = Column(String(500))
    ocr_text = Column(Text)
    parsed_items = Column(Text)  # JSON string of items
    
    is_processed = Column(Boolean, default=False)
    processed_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)
