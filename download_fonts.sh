#!/bin/bash

# Directory to save fonts to
FONTS_DIR="ios/ptchampion/Resources/Fonts"
mkdir -p "$FONTS_DIR"

# Bebas Neue - Direct link
echo "Downloading Bebas Neue..."
curl -L "https://github.com/dharmatype/Bebas-Neue/raw/master/fonts/ttfs/BebasNeue-Bold.ttf" -o "$FONTS_DIR/BebasNeue-Bold.ttf"

# Montserrat - Direct links
echo "Downloading Montserrat variants..."
curl -L "https://github.com/JulietaUla/Montserrat/raw/master/fonts/ttf/Montserrat-Regular.ttf" -o "$FONTS_DIR/Montserrat-Regular.ttf"
curl -L "https://github.com/JulietaUla/Montserrat/raw/master/fonts/ttf/Montserrat-Bold.ttf" -o "$FONTS_DIR/Montserrat-Bold.ttf"
curl -L "https://github.com/JulietaUla/Montserrat/raw/master/fonts/ttf/Montserrat-SemiBold.ttf" -o "$FONTS_DIR/Montserrat-SemiBold.ttf"

# Roboto Mono - Direct links
echo "Downloading Roboto Mono variants..."
curl -L "https://github.com/googlefonts/RobotoMono/raw/main/fonts/ttf/RobotoMono-Bold.ttf" -o "$FONTS_DIR/RobotoMono-Bold.ttf"
curl -L "https://github.com/googlefonts/RobotoMono/raw/main/fonts/ttf/RobotoMono-Medium.ttf" -o "$FONTS_DIR/RobotoMono-Medium.ttf"

# Check results
echo "Downloaded fonts:"
ls -la "$FONTS_DIR" 