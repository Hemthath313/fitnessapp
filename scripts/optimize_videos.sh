#!/bin/bash

# Video Optimization Script for Fitness App
# This script compresses videos to reduce file size while maintaining good quality
# Usage: ./scripts/optimize_videos.sh

echo "🎬 Starting video optimization..."

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "❌ Error: ffmpeg is not installed."
    echo "📦 Install it using:"
    echo "   macOS: brew install ffmpeg"
    echo "   Linux: sudo apt-get install ffmpeg"
    echo "   Windows: Download from https://ffmpeg.org/download.html"
    exit 1
fi

# Create optimized directory
OPTIMIZED_DIR="assets/videos/optimized"
mkdir -p "$OPTIMIZED_DIR"

# Video optimization settings
# - Resolution: 720p max (good for mobile)
# - Bitrate: 500k (good balance)
# - Frame rate: 24fps (smooth enough for exercise videos)
# - Codec: H.264 (best compatibility)
# - Preset: fast (good balance between speed and compression)

OPTIMIZE_SETTINGS="-vf scale=720:-2 -c:v libx264 -preset fast -crf 28 -c:a aac -b:a 64k -movflags +faststart -r 24"

# Process each video
for video in assets/videos/*.mp4; do
    if [ -f "$video" ]; then
        filename=$(basename "$video")
        output="$OPTIMIZED_DIR/$filename"
        
        echo "📹 Optimizing: $filename"
        
        # Get original size
        original_size=$(du -h "$video" | cut -f1)
        
        # Optimize video
        ffmpeg -i "$video" $OPTIMIZE_SETTINGS -y "$output" 2>/dev/null
        
        if [ -f "$output" ]; then
            new_size=$(du -h "$output" | cut -f1)
            reduction=$(echo "scale=2; (1 - $(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null) / $(stat -f%z "$video" 2>/dev/null || stat -c%s "$video" 2>/dev/null)) * 100" | bc)
            
            echo "✅ Optimized: $filename"
            echo "   Original: $original_size → Optimized: $new_size"
            echo "   Size reduction: ~${reduction}%"
            echo ""
        else
            echo "❌ Failed to optimize: $filename"
        fi
    fi
done

echo "✨ Optimization complete!"
echo "📁 Optimized videos are in: $OPTIMIZED_DIR"
echo ""
echo "💡 Next steps:"
echo "   1. Review the optimized videos"
echo "   2. If quality is good, replace originals:"
echo "      mv $OPTIMIZED_DIR/*.mp4 assets/videos/"
echo "   3. Delete the optimized directory:"
echo "      rm -rf $OPTIMIZED_DIR"

