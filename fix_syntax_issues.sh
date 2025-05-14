#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔍 Scanning for and fixing common Swift syntax issues..."

# Function to process a file
fix_file() {
    local file=$1
    local fixed=false
    local temp_file=$(mktemp)

    echo "Processing $file..."

    # 1. Fix caption() applied to container views
    if sed -E '/^[[:space:]]*(HStack|VStack|ZStack|Group|ScrollView).*\.caption\(\)/ {
        h
        s/\.caption\(\)//g
        s/$/ {/
        p
        g
        s/^[[:space:]]*(HStack|VStack|ZStack|Group|ScrollView).*\.caption\(\)/    Text("").font(.caption)/
        p
        d
    }' "$file" > "$temp_file"; then
        fixed=true
        echo "${GREEN}✓${NC} Fixed caption() on container views"
    fi

    # 2. Fix missing parentheses in tuple expressions
    if sed -E 's/([a-zA-Z]+):[[:space:]]*([a-zA-Z]+),[[:space:]]*([a-zA-Z]+):[[:space:]]*([a-zA-Z]+)/(\1: \2, \3: \4)/g' "$temp_file" > "$temp_file.2"; then
        mv "$temp_file.2" "$temp_file"
        fixed=true
        echo "${GREEN}✓${NC} Fixed tuple expressions"
    fi

    # 3. Fix incorrect closure syntax
    if sed -E 's/\{[[:space:]]*([a-zA-Z]+,[[:space:]]*[a-zA-Z]+)[[:space:]]*in/{ (\1) in/g' "$temp_file" > "$temp_file.2"; then
        mv "$temp_file.2" "$temp_file"
        fixed=true
        echo "${GREEN}✓${NC} Fixed closure syntax"
    fi

    # 4. Fix comparison expressions
    if sed -E 's/([^=!<>])(==|!=|>=|<=|>|<)([^=])/\1 \2 \3/g' "$temp_file" > "$temp_file.2"; then
        mv "$temp_file.2" "$temp_file"
        fixed=true
        echo "${GREEN}✓${NC} Fixed comparison expressions"
    fi

    # If any fixes were made, update the original file
    if [ "$fixed" = true ]; then
        mv "$temp_file" "$file"
        echo "${GREEN}✓${NC} Updated $file with fixes"
    else
        rm "$temp_file"
        echo "${RED}No issues found in $file${NC}"
    fi
}

# Find all Swift files and process them
find . -name "*.swift" -type f | while read -r file; do
    fix_file "$file"
done

echo "✨ Finished processing all Swift files" 