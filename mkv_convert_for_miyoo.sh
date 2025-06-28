#!/bin/bash

# Miyoo Mini Plus Video Converter - MKV Optimized
# Usage: ./mkv_convert_for_miyoo.sh input_video.mkv [output_name]

INPUT_FILE="$1"
OUTPUT_NAME="${2:-converted_$(basename "$INPUT_FILE" .mkv).mp4}"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 input_video.mkv [output_name]"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file does not exist"
    exit 1
fi

echo "Converting $INPUT_FILE for Miyoo Mini Plus..."
echo "Analyzing input file..."

# Get video info
ffprobe -v quiet -print_format json -show_format -show_streams "$INPUT_FILE" > /tmp/video_info.json

echo "Starting conversion (this may take a while for 720p files)..."

ffmpeg -i "$INPUT_FILE" \
    -map 0:v:0 \
    -map 0:a:0 \
    -vf "scale=480:320:force_original_aspect_ratio=decrease,pad=480:320:(ow-iw)/2:(oh-ih)/2:black" \
    -c:v libx264 \
    -preset medium \
    -profile:v baseline \
    -level 3.0 \
    -b:v 800k \
    -maxrate 1000k \
    -bufsize 1000k \
    -c:a aac \
    -b:a 64k \
    -ar 22050 \
    -ac 2 \
    -f mp4 \
    -movflags +faststart \
    -y \
    "$OUTPUT_NAME"

if [ $? -eq 0 ]; then
    echo "Conversion completed: $OUTPUT_NAME"
    echo "Original size: $(du -h "$INPUT_FILE" | cut -f1)"
    echo "Converted size: $(du -h "$OUTPUT_NAME" | cut -f1)"
    echo "Ready for Miyoo Mini Plus!"
else
    echo "Conversion failed"
    exit 1
fi

# Cleanup
rm -f /tmp/video_info.json