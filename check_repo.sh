#!/bin/bash
cd ~/Documents/MACRON

echo "=== ARCHIVOS PYTHON ==="
find . -name "*.py" -not -path "./venv/*" -not -path "./.git/*" | sort

echo ""
echo "=== ARCHIVOS MD/TXT ==="
find . -name "*.md" -o -name "*.txt" | grep -v venv | grep -v .git | sort

echo ""
echo "=== CARPETAS ==="
ls -la | grep "^d"

echo ""
echo "=== COMMITS ==="
git log --oneline -5

echo ""
echo "=== ESTADO ==="
git status --short
