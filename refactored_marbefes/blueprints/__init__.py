"""
Blueprint module for organizing routes
"""
from .main import main_bp
from .api import api_bp

__all__ = ['main_bp', 'api_bp']
