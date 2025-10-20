"""
Vector data management for MARBEFES BBT Database
"""
import json
import logging
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime

logger = logging.getLogger(__name__)

@dataclass
class VectorLayer:
    """Vector layer metadata"""
    name: str
    display_name: str
    geometry_type: str
    feature_count: int
    bounds: List[float]
    crs: str
    file_path: str
    loaded_at: datetime = None
    data: Any = None

class VectorDataManager:
    """Manages vector data loading and caching"""
    
    def __init__(self, data_dir='data/vector', cache_enabled=True):
        self.data_dir = Path(data_dir)
        self.cache_enabled = cache_enabled
        self.loaded_layers: Dict[str, VectorLayer] = {}
        self.layer_metadata: Dict[str, dict] = {}
        
        # Try to import geopandas
        try:
            import geopandas as gpd
            self.gpd = gpd
            self.vector_support = True
        except ImportError:
            logger.warning("Geopandas not installed - vector support disabled")
            self.vector_support = False
    
    def scan_vector_files(self) -> List[str]:
        """Scan data directory for vector files"""
        if not self.data_dir.exists():
            logger.warning(f"Vector data directory not found: {self.data_dir}")
            return []
        
        supported_formats = ['.gpkg', '.shp', '.geojson', '.json']
        vector_files = []
        
        for ext in supported_formats:
            vector_files.extend(self.data_dir.glob(f'*{ext}'))
        
        return vector_files
    
    def get_layer(self, layer_name: str) -> Optional[VectorLayer]:
        """Load layer on demand with caching"""
        if not self.vector_support:
            return None
        
        # Check cache first
        if self.cache_enabled and layer_name in self.loaded_layers:
            return self.loaded_layers[layer_name]
        
        # Load layer
        layer = self._load_layer(layer_name)
        
        # Cache if enabled
        if layer and self.cache_enabled:
            self.loaded_layers[layer_name] = layer
        
        return layer
    
    def _load_layer(self, layer_name: str) -> Optional[VectorLayer]:
        """Load a vector layer from file"""
        if not self.vector_support:
            return None
        
        try:
            # Find the file
            vector_files = self.scan_vector_files()
            layer_file = None
            
            for file_path in vector_files:
                if layer_name in str(file_path):
                    layer_file = file_path
                    break
            
            if not layer_file:
                logger.error(f"Layer file not found: {layer_name}")
                return None
            
            # Load with geopandas
            gdf = self.gpd.read_file(layer_file)
            
            # Create layer metadata
            layer = VectorLayer(
                name=layer_name,
                display_name=layer_name.replace('_', ' ').title(),
                geometry_type=self._get_geometry_type(gdf),
                feature_count=len(gdf),
                bounds=list(gdf.total_bounds),
                crs=str(gdf.crs),
                file_path=str(layer_file),
                loaded_at=datetime.now(),
                data=gdf
            )
            
            logger.info(f"Loaded vector layer: {layer_name} ({layer.feature_count} features)")
            return layer
            
        except Exception as e:
            logger.error(f"Error loading vector layer {layer_name}: {e}")
            return None
    
    def _get_geometry_type(self, gdf) -> str:
        """Get the primary geometry type of a GeoDataFrame"""
        if gdf.empty:
            return "Unknown"
        
        geom_types = gdf.geometry.geom_type.unique()
        if len(geom_types) == 1:
            return geom_types[0]
        else:
            return "Mixed"
    
    def get_layer_geojson(self, layer_name: str, simplify: float = None,
                         bbox: List[float] = None, limit: int = None) -> Optional[dict]:
        """Get layer as GeoJSON with optional filters"""
        layer = self.get_layer(layer_name)
        if not layer or not layer.data:
            return None
        
        gdf = layer.data.copy()
        
        # Apply bbox filter if provided
        if bbox and len(bbox) == 4:
            west, south, east, north = bbox
            gdf = gdf.cx[west:east, south:north]
        
        # Apply simplification if requested
        if simplify and simplify > 0:
            gdf['geometry'] = gdf['geometry'].simplify(simplify)
        
        # Apply limit if specified
        if limit and limit > 0:
            gdf = gdf.head(limit)
        
        # Convert to GeoJSON
        geojson = json.loads(gdf.to_json())
        
        # Add metadata
        geojson['metadata'] = {
            'layer_name': layer_name,
            'feature_count': len(gdf),
            'bounds': list(gdf.total_bounds) if not gdf.empty else None,
            'crs': str(gdf.crs),
            'geometry_type': layer.geometry_type
        }
        
        return geojson
    
    def get_layers_summary(self) -> List[dict]:
        """Get summary of all available layers"""
        summaries = []
        
        for file_path in self.scan_vector_files():
            layer_name = file_path.stem
            
            # Try to get basic info without fully loading
            try:
                if self.vector_support:
                    # Quick load just for metadata
                    gdf = self.gpd.read_file(file_path, rows=1)
                    
                    summary = {
                        'name': layer_name,
                        'display_name': layer_name.replace('_', ' ').title(),
                        'file_type': file_path.suffix[1:],
                        'geometry_type': self._get_geometry_type(gdf),
                        'crs': str(gdf.crs)
                    }
                else:
                    summary = {
                        'name': layer_name,
                        'display_name': layer_name.replace('_', ' ').title(),
                        'file_type': file_path.suffix[1:],
                        'error': 'Vector support not available'
                    }
                
                summaries.append(summary)
                
            except Exception as e:
                logger.error(f"Error getting summary for {layer_name}: {e}")
                summaries.append({
                    'name': layer_name,
                    'display_name': layer_name.replace('_', ' ').title(),
                    'error': str(e)
                })
        
        return summaries
    
    def create_bounds_summary(self) -> dict:
        """Create summary of bounds for all layers"""
        bounds_list = []
        overall_bounds = None
        
        for layer_name in self.loaded_layers:
            layer = self.loaded_layers[layer_name]
            if layer and layer.bounds:
                bounds_list.append({
                    'layer': layer_name,
                    'bounds': layer.bounds
                })
                
                # Update overall bounds
                if overall_bounds is None:
                    overall_bounds = list(layer.bounds)
                else:
                    overall_bounds[0] = min(overall_bounds[0], layer.bounds[0])  # min x
                    overall_bounds[1] = min(overall_bounds[1], layer.bounds[1])  # min y
                    overall_bounds[2] = max(overall_bounds[2], layer.bounds[2])  # max x
                    overall_bounds[3] = max(overall_bounds[3], layer.bounds[3])  # max y
        
        return {
            'layers': bounds_list,
            'overall_bounds': overall_bounds
        }
    
    def clear_cache(self):
        """Clear all cached layers"""
        self.loaded_layers.clear()
        self.layer_metadata.clear()
        logger.info("Vector cache cleared")
    
    def get_memory_usage(self) -> dict:
        """Get memory usage statistics"""
        import sys
        
        stats = {
            'loaded_layers': len(self.loaded_layers),
            'total_features': 0,
            'estimated_memory_mb': 0
        }
        
        for layer_name, layer in self.loaded_layers.items():
            if layer and layer.data is not None:
                stats['total_features'] += layer.feature_count
                # Rough estimate of memory usage
                stats['estimated_memory_mb'] += sys.getsizeof(layer.data) / (1024 * 1024)
        
        return stats

# Singleton instance
vector_manager = VectorDataManager()
