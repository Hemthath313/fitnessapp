#!/usr/bin/env python3
"""
Video Optimization Script for Fitness App
Optimizes videos to reduce file size while maintaining quality.
Requires: ffmpeg
"""

import os
import subprocess
import sys
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

def main():
    print("🎬 Starting video optimization...\n")
    
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
    optimized_dir = videos_dir / "optimized"
    optimized_dir.mkdir(exist_ok=True)
    
    # Find all MP4 files
    video_files = list(videos_dir.glob("*.mp4"))
    
    if not video_files:
        print("❌ No video files found in assets/videos/")
        sys.exit(1)
    
    total_original = 0
    total_optimized = 0
    
    # Process each video
    for video_file in video_files:
        if video_file.name == "README.md":
            continue
            
        print(f"📹 Optimizing: {video_file.name}")
        
        original_size = get_file_size(video_file)
        total_original += original_size
        
        output_file = optimized_dir / video_file.name
        
        if optimize_video(video_file, output_file):
            new_size = get_file_size(output_file)
            total_optimized += new_size
            reduction = ((original_size - new_size) / original_size) * 100
            
            print(f"✅ Optimized: {video_file.name}")
            print(f"   Original: {original_size:.2f} MB → Optimized: {new_size:.2f} MB")
            print(f"   Size reduction: {reduction:.1f}%\n")
        else:
            print(f"❌ Failed to optimize: {video_file.name}\n")
    
    # Summary
    print("✨ Optimization complete!")
    print(f"📊 Total size: {total_original:.2f} MB → {total_optimized:.2f} MB")
    print(f"💾 Space saved: {total_original - total_optimized:.2f} MB ({(total_original - total_optimized)/total_original*100:.1f}%)")
    print(f"\n📁 Optimized videos are in: {optimized_dir}")
    print("\n💡 Next steps:")
    print("   1. Review the optimized videos")
    print("   2. If quality is good, replace originals:")
    print(f"      mv {optimized_dir}/*.mp4 {videos_dir}/")
    print("   3. Delete the optimized directory:")
    print(f"      rm -rf {optimized_dir}")

if __name__ == "__main__":
    main()

