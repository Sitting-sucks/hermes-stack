#!/bin/bash
# Open Multi-Agent Setup — TypeScript-Native Multi-Agent Orchestration
# Part of the Hermes Stack Installer
# Installs @open-multi-agent/core (https://github.com/open-multi-agent/open-multi-agent) — 6K+ stars
# Goal-driven coordinator: give it a goal, it decomposes into tasks, parallelizes, and delivers

set -e

echo "  🔗 Installing Open Multi-Agent (multi-agent orchestration)..."

# Install globally for CLI access
npm install -g @open-multi-agent/core 2>/dev/null

echo "  ✅ Open Multi-Agent installed. Use 'oma' CLI or import '@open-multi-agent/core' in Node.js."
echo "     One runTeam() call from goal to result."
