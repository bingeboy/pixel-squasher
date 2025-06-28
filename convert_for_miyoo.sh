#!/bin/bash

# Miyoo Mini Plus Video Converter
# Usage: ./convert_for_miyoo.sh input_video.mp4 [output_name]

INPUT_FILE="$1"
OUTPUT_NAME="${2:-converted_$(basename "$INPUT_FILE")}"

if [ -z "$INPUT_FILE" ]; then
    echo "Usage: $0 input_video.mp4 [output_name]"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file does not exist"
    exit 1
fi

echo "Converting $INPUT_FILE for Miyoo Mini Plus..."

ffmpeg -i "$INPUT_FILE" \
    -vf "scale=480:320:force_original_aspect_ratio=decrease,pad=480:320:(ow-iw)/2:(oh-ih)/2:black" \
    -c:v libx264 \
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
    "$OUTPUT_NAME"

if [ $? -eq 0 ]; then
    echo "Conversion completed: $OUTPUT_NAME"
    echo "File size: $(du -h "$OUTPUT_NAME" | cut -f1)"
else
    echo "Conversion failed"
    exit 1
fi
