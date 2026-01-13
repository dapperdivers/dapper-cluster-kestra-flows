#!/bin/bash
# Validate all Kestra flows locally

set -e

echo "🔍 Validating YAML syntax..."
yamllint .

echo ""
echo "✅ YAML validation passed!"
echo ""
echo "📋 Flow files found:"
find _flows -name "*.yaml" -o -name "*.yml"

echo ""
echo "✨ All validations complete!"
