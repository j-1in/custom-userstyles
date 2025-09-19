#!/bin/bash

cd ../../styles || exit 1

for dir in */; do
    if [ -d "$dir" ]; then
        style=$(basename "$dir")
        file="$dir/catppuccin.user.less"
        if [ -f "$file" ]; then
            # if grep -q "https://raw.githubusercontent.com/AdityaAparadh/everforest-userstyles/refs/heads/main/lib/lib.less" "$file"; then
            #     continue
            # fi
            
            echo "Processing $file"
            
            sed -i '/^@name/ s/Catppuccin/Everforest/' "$file"
            
            sed -i 's|github.com/catppuccin/userstyles/styles/|github.com/adityaaparadh/everforest-userstyles/styles/|g' "$file"
            
            sed -i 's|github.com/catppuccin/userstyles/tree/main/styles/|github.com/adityaaparadh/everforest-userstyles/tree/main/styles/|g' "$file"
            
            sed -i 's|github.com/catppuccin/userstyles/raw/main/styles/|github.com/adityaaparadh/everforest-userstyles/raw/main/styles/|g' "$file"
            
            sed -i 's|github.com/catppuccin/userstyles/issues?q=is%3Aopen+is%3Aissue+label%3A|github.com/adityaaparadh/everforest-userstyles/issues?q=is%3Aopen+is%3Aissue+label%3A|g' "$file"
            
            sed -i 's/Soothing pastel theme/Warm forest theme/g' "$file"
            
            sed -i 's|https://userstyles.catppuccin.com/lib/lib.less|https://cdn.jsdelivr.net/gh/AdityaAparadh/everforest-userstyles@main/lib/lib.less|g' "$file"
        else
            echo "File $file not found"
        fi
    fi
done