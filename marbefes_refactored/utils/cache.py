"""
Caching utilities for MARBEFES BBT Database
"""
from functools import lru_cache, wraps
from datetime import datetime, timedelta
import hashlib
import json
import pickle
import os
from pathlib import Path

class CacheManager:
    """Manages application caching"""
    
    def __init__(self, cache_dir='cache', ttl=3600):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True)
        self.ttl = ttl
        
    def get_cache_key(self, *args, **kwargs):
        """Generate cache key from function arguments"""
        key_data = str(args) + str(sorted(kwargs.items()))
        return hashlib.md5(key_data.encode()).hexdigest()
    
    def get(self, key):
        """Get cached value"""
        cache_file = self.cache_dir / f"{key}.cache"
        if cache_file.exists():
            try:
                with open(cache_file, 'rb') as f:
                    data = pickle.load(f)
                    if datetime.now() - data['timestamp'] < timedelta(seconds=self.ttl):
                        return data['value']
            except:
                pass
        return None
    
    def set(self, key, value):
        """Set cached value"""
        cache_file = self.cache_dir / f"{key}.cache"
        with open(cache_file, 'wb') as f:
            pickle.dump({
                'timestamp': datetime.now(),
                'value': value
            }, f)
    
    def clear(self):
        """Clear all cache"""
        for cache_file in self.cache_dir.glob('*.cache'):
            cache_file.unlink()

def get_ttl_hash(seconds=3600):
    """Return hash for cache invalidation after TTL"""
    return round(datetime.now().timestamp() / seconds)

def cached_request(ttl=3600):
    """Decorator for caching HTTP requests"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Add TTL hash to kwargs for cache invalidation
            kwargs['_ttl_hash'] = get_ttl_hash(ttl)
            return func(*args, **kwargs)
        return wrapper
    return decorator

# Create LRU cache for WMS capabilities
@lru_cache(maxsize=32)
def get_capabilities_cached(url, ttl_hash=None):
    """Cache WMS GetCapabilities request"""
    import requests
    params = {
        'service': 'WMS',
        'version': '1.3.0',
        'request': 'GetCapabilities'
    }
    response = requests.get(url, params=params, timeout=10)
    return response.text

def cache_geojson(layer_name, geojson_data, cache_dir='cache/geojson'):
    """Cache GeoJSON data to file"""
    cache_path = Path(cache_dir)
    cache_path.mkdir(parents=True, exist_ok=True)
    
    cache_file = cache_path / f"{layer_name.replace('/', '_')}.json"
    with open(cache_file, 'w', encoding='utf-8') as f:
        json.dump(geojson_data, f)
    
    return cache_file

def load_cached_geojson(layer_name, cache_dir='cache/geojson', max_age_hours=24):
    """Load cached GeoJSON if available and fresh"""
    cache_path = Path(cache_dir)
    cache_file = cache_path / f"{layer_name.replace('/', '_')}.json"
    
    if cache_file.exists():
        # Check file age
        file_age = datetime.now() - datetime.fromtimestamp(cache_file.stat().st_mtime)
        if file_age < timedelta(hours=max_age_hours):
            try:
                with open(cache_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except:
                pass
    
    return None

class ResponseCache:
    """In-memory response cache with TTL"""
    
    def __init__(self, ttl=300):
        self._cache = {}
        self.ttl = ttl
    
    def get(self, key):
        """Get cached response"""
        if key in self._cache:
            entry = self._cache[key]
            if datetime.now() - entry['timestamp'] < timedelta(seconds=self.ttl):
                return entry['data']
            else:
                del self._cache[key]
        return None
    
    def set(self, key, data):
        """Cache response"""
        self._cache[key] = {
            'timestamp': datetime.now(),
            'data': data
        }
    
    def clear_expired(self):
        """Remove expired entries"""
        now = datetime.now()
        expired_keys = [
            key for key, entry in self._cache.items()
            if now - entry['timestamp'] >= timedelta(seconds=self.ttl)
        ]
        for key in expired_keys:
            del self._cache[key]
