bash#!/bin/bash

# Batch convert all MKV files in current directory
echo "Converting all MKV files in current directory..."

for file in *.mkv; do
    if [ -f "$file" ]; then
        echo "Processing: $file"
        ./mkv_convert_for_miyoo.sh "$file"
        echo "---"
    fi
done

echo "Batch conversion complete!"