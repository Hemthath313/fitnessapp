#!/usr/bin/env python3
"""
Video Optimization Script for Fitness App
Optimizes videos in place to reduce file size while maintaining quality.
Requires: ffmpeg
"""

import os
import subprocess
import sys
import tempfile
import shutil
from pathlib import Path

def check_ffmpeg():
    """Check if ffmpeg is installed"""
    try:
        subprocess.run(['ffmpeg', '-version'], 
                     capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def get_file_size(filepath):
    """Get file size in MB"""
    return os.path.getsize(filepath) / (1024 * 1024)

def optimize_video(input_path, output_path):
    """Optimize a single video file"""
    # Optimization settings:
    # - Scale to max 720p (good for mobile)
    # - CRF 28 (good quality/size balance)
    # - 24fps (smooth enough)
    # - H.264 codec (best compatibility)
    # - Fast preset (good balance)
    
    cmd = [
        'ffmpeg',
        '-i', str(input_path),
        '-vf', 'scale=720:-2',  # Scale to 720p max height
        '-c:v', 'libx264',      # H.264 codec
        '-preset', 'fast',      # Encoding preset
        '-crf', '28',           # Quality (lower = better, 23-28 is good)
        '-c:a', 'aac',          # Audio codec
        '-b:a', '64k',          # Audio bitrate
        '-movflags', '+faststart',  # Fast start for web/mobile
        '-r', '24',             # Frame rate
        '-y',                   # Overwrite output
        str(output_path)
    ]
    
    try:
        subprocess.run(cmd, check=True, 
                      stdout=subprocess.DEVNULL,
                      stderr=subprocess.DEVNULL)
        return True
    except subprocess.CalledProcessError:
        return False

def find_all_videos(videos_dir):
    """Find all MP4 files recursively in videos directory and subdirectories"""
    video_files = []
    for root, dirs, files in os.walk(videos_dir):
        # Skip optimized directory if it exists
        if 'optimized' in root:
            continue
        for file in files:
            if file.endswith('.mp4'):
                video_files.append(Path(root) / file)
    return video_files

def main():
    print("🎬 Starting video optimization (in-place)...\n")
    
    # Check ffmpeg
    if not check_ffmpeg():
        print("❌ Error: ffmpeg is not installed.")
        print("📦 Install it using:")
        print("   macOS: brew install ffmpeg")
        print("   Linux: sudo apt-get install ffmpeg")
        print("   Windows: Download from https://ffmpeg.org/download.html")
        sys.exit(1)
    
    # Setup paths
    videos_dir = Path("assets/videos")
    
    # Find all MP4 files recursively
    video_files = find_all_videos(videos_dir)
    
    if not video_files:
        print("❌ No video files found in assets/videos/")
        sys.exit(1)
    
    print(f"📹 Found {len(video_files)} video(s) to optimize\n")
    
    total_original = 0
    total_optimized = 0
    processed = 0
    failed = 0
    
    # Process each video
    for video_file in video_files:
        print(f"📹 Optimizing: {video_file.relative_to(videos_dir)}")
        
        original_size = get_file_size(video_file)
        total_original += original_size
        
        # Create temporary file for optimized video
        temp_file = video_file.with_suffix('.tmp.mp4')
        
        if optimize_video(video_file, temp_file):
            new_size = get_file_size(temp_file)
            total_optimized += new_size
            reduction = ((original_size - new_size) / original_size) * 100
            
            # Replace original with optimized version
            shutil.move(str(temp_file), str(video_file))
            
            print(f"✅ Optimized: {video_file.name}")
            print(f"   Original: {original_size:.2f} MB → Optimized: {new_size:.2f} MB")
            print(f"   Size reduction: {reduction:.1f}%\n")
            processed += 1
        else:
            # Clean up temp file if optimization failed
            if temp_file.exists():
                temp_file.unlink()
            print(f"❌ Failed to optimize: {video_file.name}\n")
            failed += 1
    
    # Summary
    print("=" * 50)
    print("✨ Optimization complete!")
    print(f"📊 Processed: {processed} videos")
    if failed > 0:
        print(f"⚠️  Failed: {failed} videos")
    print(f"📦 Total size: {total_original:.2f} MB → {total_optimized:.2f} MB")
    if total_original > 0:
        space_saved = total_original - total_optimized
        percent_saved = (space_saved / total_original) * 100
        print(f"💾 Space saved: {space_saved:.2f} MB ({percent_saved:.1f}%)")
    print("\n✅ All videos have been optimized in place!")

if __name__ == "__main__":
    main()
