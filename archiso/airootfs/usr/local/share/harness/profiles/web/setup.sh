#!/usr/bin/env bash
# HarnessOS — Web Dev profile setup
set -euo pipefail

echo "Installing npm globals: pnpm, typescript, ts-node, vercel, create-next-app..."
npm install -g pnpm typescript ts-node tsx vercel create-next-app 2>/dev/null || true

echo "Installing Tailwind CSS CLI..."
npm install -g tailwindcss 2>/dev/null || true

echo "Web Dev profile ready."
echo "  pnpm create next-app   — start a Next.js project"
echo "  bun run dev            — run with Bun (faster)"
