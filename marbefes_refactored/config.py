"""
Configuration management for MARBEFES BBT Database
"""
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    """Application configuration"""
    
    # Flask settings
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    JSON_AS_ASCII = False
    
    # WMS Service Configuration
    WMS_BASE_URL = os.getenv(
        'WMS_BASE_URL', 
        'https://ows.emodnet-seabedhabitats.eu/geoserver/emodnet_view/wms'
    )
    WMS_VERSION = os.getenv('WMS_VERSION', '1.3.0')
    
    # HELCOM WMS Configuration
    HELCOM_WMS_BASE_URL = os.getenv(
        'HELCOM_WMS_BASE_URL',
        'https://maps.helcom.fi/arcgis/services/MADS/Pressures/MapServer/WMSServer'
    )
    HELCOM_WMS_VERSION = os.getenv('HELCOM_WMS_VERSION', '1.3.0')
    
    # Cache settings
    CACHE_TTL = int(os.getenv('CACHE_TTL', 3600))  # 1 hour default
    CACHE_MAX_SIZE = int(os.getenv('CACHE_MAX_SIZE', 32))
    
    # API limits
    MAX_FEATURES = int(os.getenv('MAX_FEATURES', 10000))
    MAX_GEOJSON_SIZE_MB = int(os.getenv('MAX_GEOJSON_SIZE_MB', 50))
    
    # Rate limiting
    RATELIMIT_ENABLED = os.getenv('RATELIMIT_ENABLED', 'True').lower() == 'true'
    RATELIMIT_DEFAULT = os.getenv('RATELIMIT_DEFAULT', '200 per day, 50 per hour')
    
    # Database (optional)
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        'sqlite:///data/marbefes.db'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FILE = os.getenv('LOG_FILE', 'logs/marbefes.log')
    LOG_MAX_BYTES = int(os.getenv('LOG_MAX_BYTES', 10485760))  # 10MB
    LOG_BACKUP_COUNT = int(os.getenv('LOG_BACKUP_COUNT', 10))
    
    # CORS settings
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*')
    
    # Compression
    COMPRESS_MIMETYPES = [
        'text/html', 'text/css', 'text/xml', 'application/json',
        'application/javascript', 'application/geo+json'
    ]
    COMPRESS_LEVEL = 6
    COMPRESS_MIN_SIZE = 1024

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    TESTING = False

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    TESTING = False
    
class TestingConfig(Config):
    """Testing configuration"""
    DEBUG = True
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'

# Configuration dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
