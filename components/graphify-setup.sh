#!/bin/bash
# Graphify Setup — Multimodal Knowledge Graph for Hermes Agent
# Part of the Hermes Stack Installer
# Installs graphify (https://github.com/safishamsi/graphify) — 57K+ stars
# Turns any folder of code, docs, PDFs, images into a queryable knowledge graph

set -e

echo "  🔗 Installing Graphify (multimodal knowledge graphs)..."

# Install via pip — PyPI package is graphifyy, CLI command is graphify
pip install graphifyy 2>/dev/null || pip3 install graphifyy 2>/dev/null

# Install the Hermes Agent skill
graphify install --platform hermes 2>/dev/null

echo "  ✅ Graphify installed. Type /graphify in Hermes to build a knowledge graph."
