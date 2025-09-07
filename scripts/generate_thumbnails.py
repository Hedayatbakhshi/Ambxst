#!/usr/bin/env python3
"""
Thumbnail Generator for Ambyst Wallpaper System
Generates thumbnails for video files, images, and GIFs using FFmpeg and ImageMagick with multithreading.
"""

import os
import sys
import json
import threading
import subprocess
import time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import List, Tuple, Optional

# Supported extensions
VIDEO_EXTENSIONS = {'.mp4', '.webm', '.mov', '.avi', '.mkv'}
IMAGE_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp', '.tif', '.tiff', '.bmp'}
GIF_EXTENSIONS = {'.gif'}

# Default thumbnail size
THUMBNAIL_SIZE = "320x240"

class ThumbnailGenerator:
    def __init__(self, config_path: str):
        self.config_path = Path(config_path)
        self.wall_path: Optional[Path] = None
        self.video_cache_dir: Optional[Path] = None
        self.image_cache_dir: Optional[Path] = None
        self.gif_cache_dir: Optional[Path] = None
        self.files_to_process = {'videos': [], 'images': [], 'gifs': []}
        self.total_files = 0
        self.processed_count = 0
        self.lock = threading.Lock()
        
    def load_config(self) -> bool:
        """Load wallpaper configuration."""
        try:
            if not self.config_path.exists():
                print(f"ERROR: Config file not found: {self.config_path}")
                return False
                
            with open(self.config_path, 'r') as f:
                config = json.load(f)
                
            wall_path = config.get('wallPath', '')
            if not wall_path:
                print("ERROR: wallPath not found in config")
                return False
                
            self.wall_path = Path(wall_path).expanduser()
            if not self.wall_path.exists():
                print(f"ERROR: Wallpaper directory not found: {self.wall_path}")
                return False
                
            # Setup cache directories
            home = Path.home()
            cache_base = home / '.cache' / 'quickshell'
            
            self.video_cache_dir = cache_base / 'video_thumbnails'
            self.image_cache_dir = cache_base / 'image_thumbnails'
            self.gif_cache_dir = cache_base / 'gif_thumbnails'
            
            # Create all cache directories
            for cache_dir in [self.video_cache_dir, self.image_cache_dir, self.gif_cache_dir]:
                cache_dir.mkdir(parents=True, exist_ok=True)
            
            print(f"✓ Config loaded: {self.wall_path}")
            print(f"✓ Video cache: {self.video_cache_dir}")
            print(f"✓ Image cache: {self.image_cache_dir}")
            print(f"✓ GIF cache: {self.gif_cache_dir}")
            return True
            
        except Exception as e:
            print(f"ERROR loading config: {e}")
            return False
    
    def find_files(self) -> Tuple[List[Path], List[Path], List[Path]]:
        """Find all media files in wallpaper directory."""
        videos = []
        images = []
        gifs = []
        
        if self.wall_path is None:
            print("ERROR: wall_path not initialized")
            return [], [], []
        
        try:
            for file_path in self.wall_path.iterdir():
                if file_path.is_file():
                    ext = file_path.suffix.lower()
                    if ext in VIDEO_EXTENSIONS:
                        videos.append(file_path)
                    elif ext in IMAGE_EXTENSIONS:
                        images.append(file_path)
                    elif ext in GIF_EXTENSIONS:
                        gifs.append(file_path)
                        
            # Sort all lists for consistent ordering
            videos.sort()
            images.sort()
            gifs.sort()
            
            print(f"✓ Found {len(videos)} videos, {len(images)} images, {len(gifs)} GIFs")
            return videos, images, gifs
            
        except Exception as e:
            print(f"ERROR scanning directory: {e}")
            return [], [], []
    
    def get_thumbnail_path(self, file_path: Path, file_type: str) -> Path:
        """Get thumbnail path for a media file."""
        thumbnail_name = file_path.stem + '.jpg'
        
        if file_type == 'video':
            if self.video_cache_dir is None:
                raise RuntimeError("video_cache_dir not initialized")
            return self.video_cache_dir / thumbnail_name
        elif file_type == 'image':
            if self.image_cache_dir is None:
                raise RuntimeError("image_cache_dir not initialized")
            return self.image_cache_dir / thumbnail_name
        elif file_type == 'gif':
            if self.gif_cache_dir is None:
                raise RuntimeError("gif_cache_dir not initialized")
            return self.gif_cache_dir / thumbnail_name
        else:
            raise ValueError(f"Unknown file type: {file_type}")
    
    def needs_thumbnail(self, file_path: Path, file_type: str) -> bool:
        """Check if file needs thumbnail generation."""
        thumbnail_path = self.get_thumbnail_path(file_path, file_type)
        
        # If thumbnail doesn't exist, needs generation
        if not thumbnail_path.exists():
            return True
            
        # If file is newer than thumbnail, needs regeneration
        try:
            file_mtime = file_path.stat().st_mtime
            thumbnail_mtime = thumbnail_path.stat().st_mtime
            return file_mtime > thumbnail_mtime
        except:
            return True
    
    def generate_video_thumbnail(self, video_path: Path) -> Tuple[bool, str]:
        """Generate thumbnail for a video file using FFmpeg."""
        thumbnail_path = self.get_thumbnail_path(video_path, 'video')
        
        try:
            # FFmpeg command for high-quality thumbnail
            cmd = [
                'ffmpeg', '-y',
                '-i', str(video_path),
                '-ss', '00:00:01',  # Skip first second to avoid black frames
                '-vframes', '1',    # Extract only 1 frame
                '-vf', f'scale=320:240:force_original_aspect_ratio=increase,crop=320:240',
                '-q:v', '2',        # High quality
                '-f', 'image2',     # Force image format
                str(thumbnail_path)
            ]
            
            # Run FFmpeg with error suppression
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30  # 30 second timeout per video
            )
            
            if result.returncode == 0 and thumbnail_path.exists():
                return True, "Success"
            else:
                error_msg = result.stderr.strip() if result.stderr else "Unknown error"
                return False, error_msg
                
        except subprocess.TimeoutExpired:
            return False, "Timeout"
        except Exception as e:
            return False, str(e)
    
    def generate_image_thumbnail(self, image_path: Path) -> Tuple[bool, str]:
        """Generate thumbnail for an image file using ImageMagick."""
        thumbnail_path = self.get_thumbnail_path(image_path, 'image')
        
        try:
            # ImageMagick command for high-quality thumbnail
            cmd = [
                'convert',
                str(image_path),
                '-resize', '320x240^',  # Force resize to exact dimensions
                '-gravity', 'center',   # Center the crop
                '-extent', '320x240',   # Crop to exact size
                '-quality', '85',       # High quality JPEG
                str(thumbnail_path)
            ]
            
            # Run ImageMagick
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=15  # 15 second timeout per image
            )
            
            if result.returncode == 0 and thumbnail_path.exists():
                return True, "Success"
            else:
                error_msg = result.stderr.strip() if result.stderr else "Unknown error"
                return False, error_msg
                
        except subprocess.TimeoutExpired:
            return False, "Timeout"
        except Exception as e:
            return False, str(e)
    
    def generate_gif_thumbnail(self, gif_path: Path) -> Tuple[bool, str]:
        """Generate thumbnail for a GIF file using FFmpeg (extract first frame)."""
        thumbnail_path = self.get_thumbnail_path(gif_path, 'gif')
        
        try:
            # FFmpeg command to extract first frame from GIF
            cmd = [
                'ffmpeg', '-y',
                '-i', str(gif_path),
                '-vframes', '1',    # Extract only the first frame
                '-vf', f'scale=320:240:force_original_aspect_ratio=increase,crop=320:240',
                '-q:v', '2',        # High quality
                '-f', 'image2',     # Force image format
                str(thumbnail_path)
            ]
            
            # Run FFmpeg
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=15  # 15 second timeout per GIF
            )
            
            if result.returncode == 0 and thumbnail_path.exists():
                return True, "Success"
            else:
                error_msg = result.stderr.strip() if result.stderr else "Unknown error"
                return False, error_msg
                
        except subprocess.TimeoutExpired:
            return False, "Timeout"
        except Exception as e:
            return False, str(e)
    
    def generate_single_thumbnail(self, file_path: Path, file_type: str) -> Tuple[bool, str]:
        """Generate thumbnail for a single file based on its type."""
        try:
            if file_type == 'video':
                success, message = self.generate_video_thumbnail(file_path)
            elif file_type == 'image':
                success, message = self.generate_image_thumbnail(file_path)
            elif file_type == 'gif':
                success, message = self.generate_gif_thumbnail(file_path)
            else:
                return False, f"Unknown file type: {file_type}"
            
            # Update progress
            with self.lock:
                self.processed_count += 1
                progress = (self.processed_count / self.total_files) * 100
                status = "✓" if success else "✗"
                print(f"[{self.processed_count}/{self.total_files}] {status} {file_path.name} ({progress:.1f}%)")
            
            return success, message
            
        except Exception as e:
            return False, str(e)
    
    def process_files(self, max_workers: int = 4) -> None:
        """Process files with multithreading."""
        all_files = []
        
        # Prepare list of (file_path, file_type) tuples
        for file_path in self.files_to_process['videos']:
            all_files.append((file_path, 'video'))
        for file_path in self.files_to_process['images']:
            all_files.append((file_path, 'image'))
        for file_path in self.files_to_process['gifs']:
            all_files.append((file_path, 'gif'))
        
        if not all_files:
            print("✓ All thumbnails are up to date")
            return
            
        print(f"⚡ Processing {len(all_files)} files with {max_workers} workers...")
        start_time = time.time()
        
        failed_files = []
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Submit all jobs
            future_to_file = {
                executor.submit(self.generate_single_thumbnail, file_path, file_type): (file_path, file_type)
                for file_path, file_type in all_files
            }
            
            # Process completed jobs
            for future in as_completed(future_to_file):
                file_path, file_type = future_to_file[future]
                try:
                    success, message = future.result()
                    if not success:
                        failed_files.append((file_path, message))
                        
                except Exception as e:
                    failed_files.append((file_path, str(e)))
        
        elapsed = time.time() - start_time
        success_count = self.total_files - len(failed_files)
        
        print(f"\n🏁 Processing complete in {elapsed:.1f}s")
        print(f"✅ Success: {success_count}/{self.total_files}")
        
        if failed_files:
            print(f"❌ Failed: {len(failed_files)}")
            for file_path, error in failed_files[:3]:  # Show first 3 errors
                print(f"   • {file_path.name}: {error}")
            if len(failed_files) > 3:
                print(f"   ... and {len(failed_files) - 3} more")
    
    def run(self) -> int:
        """Main execution function."""
        print("🖼️  Ambyst Thumbnail Generator")
        print("=" * 40)
        
        # Load configuration
        if not self.load_config():
            return 1
        
        # Find all files
        videos, images, gifs = self.find_files()
        if not any([videos, images, gifs]):
            print("ℹ️  No media files found")
            return 0
        
        # Filter files that need thumbnails
        for video in videos:
            if self.needs_thumbnail(video, 'video'):
                self.files_to_process['videos'].append(video)
                
        for image in images:
            if self.needs_thumbnail(image, 'image'):
                self.files_to_process['images'].append(image)
                
        for gif in gifs:
            if self.needs_thumbnail(gif, 'gif'):
                self.files_to_process['gifs'].append(gif)
        
        self.total_files = (
            len(self.files_to_process['videos']) + 
            len(self.files_to_process['images']) + 
            len(self.files_to_process['gifs'])
        )
        
        if self.total_files == 0:
            print("✓ All thumbnails are up to date")
            return 0
        
        print(f"📋 {self.total_files} files need thumbnail generation")
        print(f"   • Videos: {len(self.files_to_process['videos'])}")
        print(f"   • Images: {len(self.files_to_process['images'])}")
        print(f"   • GIFs: {len(self.files_to_process['gifs'])}")
        
        # Determine optimal worker count
        max_workers = min(4, os.cpu_count() or 1, self.total_files)
        
        # Process files
        try:
            self.process_files(max_workers)
            print("🎉 Thumbnail generation complete!")
            return 0
        except KeyboardInterrupt:
            print("\n⚠️  Interrupted by user")
            return 130
        except Exception as e:
            print(f"❌ Unexpected error: {e}")
            return 1

def main():
    """Entry point."""
    if len(sys.argv) != 2:
        print("Usage: python3 generate_thumbnails.py <config_path>")
        print("Example: python3 generate_thumbnails.py modules/widgets/wallpapers/wallpaper_config.json")
        return 1
    
    config_path = sys.argv[1]
    generator = ThumbnailGenerator(config_path)
    return generator.run()

if __name__ == '__main__':
    sys.exit(main())