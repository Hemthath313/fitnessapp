#!/usr/bin/env python3
"""
Image Optimization Script for Fitness App
Optimizes images to reduce file size while maintaining quality.
Requires: Pillow (PIL) - install with: pip3 install Pillow
"""

import os
import subprocess
import sys
import shutil
from pathlib import Path

def check_pillow():
    """Check if Pillow is installed"""
    try:
        from PIL import Image
        return True
    except ImportError:
        return False

def install_pillow():
    """Try to install Pillow"""
    print("📦 Pillow not found. Attempting to install...")
    try:
        subprocess.run([sys.executable, '-m', 'pip', 'install', 'Pillow'], 
                      check=True, capture_output=True)
        print("✅ Pillow installed successfully!")
        return True
    except subprocess.CalledProcessError:
        print("❌ Failed to install Pillow automatically.")
        print("💡 Please install manually: pip3 install Pillow")
        return False

def get_file_size(filepath):
    """Get file size in KB"""
    return os.path.getsize(filepath) / 1024

def optimize_webp(input_path, output_path, quality=85):
    """Optimize WebP image"""
    try:
        from PIL import Image
        
        img = Image.open(input_path)
        
        # Convert RGBA to RGB if needed (WebP supports both)
        if img.mode == 'RGBA':
            # Keep alpha channel for WebP
            img.save(output_path, 'WEBP', quality=quality, method=6)
        else:
            img.save(output_path, 'WEBP', quality=quality, method=6)
        
        return True
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
        return False

def optimize_jpeg(input_path, output_path, quality=85):
    """Optimize JPEG image"""
    try:
        from PIL import Image
        
        img = Image.open(input_path)
        
        # Convert RGBA to RGB for JPEG
        if img.mode == 'RGBA':
            rgb_img = Image.new('RGB', img.size, (255, 255, 255))
            rgb_img.paste(img, mask=img.split()[3] if len(img.split()) == 4 else None)
            img = rgb_img
        
        # Optimize JPEG
        img.save(output_path, 'JPEG', quality=quality, optimize=True, progressive=True)
        
        return True
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
        return False

def optimize_png(input_path, output_path):
    """Optimize PNG image"""
    try:
        from PIL import Image
        
        img = Image.open(input_path)
        
        # For PNG with transparency, keep it
        # For PNG without transparency, convert to RGB
        if img.mode == 'RGBA':
            img.save(output_path, 'PNG', optimize=True, compress_level=9)
        else:
            img = img.convert('RGB')
            # Convert to JPEG for better compression if no transparency
            output_path = output_path.with_suffix('.jpg')
            img.save(output_path, 'JPEG', quality=85, optimize=True)
            print(f"   ℹ️  Converted PNG to JPEG (no transparency)")
        
        return True
    except Exception as e:
        print(f"   ⚠️  Error: {e}")
        return False

def optimize_image(input_path):
    """Optimize a single image file"""
    input_path = Path(input_path)
    
    if not input_path.exists():
        return False
    
    original_size = get_file_size(input_path)
    
    # Create temporary file
    temp_file = input_path.with_suffix('.tmp' + input_path.suffix)
    
    success = False
    if input_path.suffix.lower() == '.webp':
        success = optimize_webp(input_path, temp_file, quality=85)
    elif input_path.suffix.lower() in ['.jpg', '.jpeg']:
        success = optimize_jpeg(input_path, temp_file, quality=85)
    elif input_path.suffix.lower() == '.png':
        success = optimize_png(input_path, temp_file)
    else:
        print(f"   ⚠️  Unsupported format: {input_path.suffix}")
        return False
    
    if success and temp_file.exists():
        new_size = get_file_size(temp_file)
        
        # Only replace if we saved space
        if new_size < original_size:
            shutil.move(str(temp_file), str(input_path))
            reduction = ((original_size - new_size) / original_size) * 100
            print(f"   ✅ Optimized: {original_size:.1f} KB → {new_size:.1f} KB ({reduction:.1f}% reduction)")
            return True
        else:
            # Remove temp file if no improvement
            temp_file.unlink()
            print(f"   ℹ️  No improvement: {original_size:.1f} KB")
            return False
    
    return False

def find_all_images(images_dir):
    """Find all image files in images directory"""
    image_files = []
    extensions = ['.webp', '.jpg', '.jpeg', '.png']
    
    for root, dirs, files in os.walk(images_dir):
        for file in files:
            if any(file.lower().endswith(ext) for ext in extensions):
                image_files.append(Path(root) / file)
    
    return image_files

def main():
    print("🖼️  Starting image optimization...\n")
    
    # Check Pillow
    if not check_pillow():
        if not install_pillow():
            sys.exit(1)
    
    from PIL import Image
    
    # Setup paths
    images_dir = Path("assets/images")
    
    if not images_dir.exists():
        print(f"❌ Images directory not found: {images_dir}")
        sys.exit(1)
    
    # Find all image files
    image_files = find_all_images(images_dir)
    
    if not image_files:
        print("❌ No image files found in assets/images/")
        sys.exit(1)
    
    print(f"🖼️  Found {len(image_files)} image(s) to optimize\n")
    
    total_original = 0
    total_optimized = 0
    processed = 0
    failed = 0
    no_improvement = 0
    
    # Process each image
    for image_file in image_files:
        print(f"📷 Processing: {image_file.name}")
        
        original_size = get_file_size(image_file)
        total_original += original_size
        
        if optimize_image(image_file):
            new_size = get_file_size(image_file)
            total_optimized += new_size
            processed += 1
        else:
            # Check if it failed or just no improvement
            if image_file.exists():
                current_size = get_file_size(image_file)
                if current_size == original_size:
                    total_optimized += original_size
                    no_improvement += 1
                else:
                    failed += 1
            else:
                failed += 1
        print()
    
    # Summary
    print("=" * 50)
    print("✨ Optimization complete!")
    print(f"📊 Processed: {processed} images optimized")
    if no_improvement > 0:
        print(f"ℹ️  No improvement: {no_improvement} images")
    if failed > 0:
        print(f"⚠️  Failed: {failed} images")
    print(f"📦 Total size: {total_original:.1f} KB → {total_optimized:.1f} KB")
    if total_original > 0:
        space_saved = total_original - total_optimized
        percent_saved = (space_saved / total_original) * 100
        if space_saved > 0:
            print(f"💾 Space saved: {space_saved:.1f} KB ({percent_saved:.1f}%)")
        else:
            print("ℹ️  No space saved (images may already be optimized)")
    print("\n✅ All images have been optimized!")

if __name__ == "__main__":
    main()

