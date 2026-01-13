#!/bin/bash
# Create a new namespace directory structure

if [ -z "$1" ]; then
  echo "Usage: ./scripts/create-namespace.sh <namespace-name>"
  echo "Example: ./scripts/create-namespace.sh production"
  exit 1
fi

NAMESPACE=$1
NAMESPACE_DIR="_flows/${NAMESPACE}"

if [ -d "$NAMESPACE_DIR" ]; then
  echo "❌ Namespace '${NAMESPACE}' already exists at ${NAMESPACE_DIR}"
  exit 1
fi

echo "📁 Creating namespace: ${NAMESPACE}"
mkdir -p "$NAMESPACE_DIR"

# Create a sample flow file
cat > "${NAMESPACE_DIR}/example.yaml" <<EOF
id: example_flow
namespace: ${NAMESPACE}

description: |
  Example flow for ${NAMESPACE} namespace

tasks:
  - id: hello
    type: io.kestra.plugin.core.log.Log
    message: "Hello from ${NAMESPACE}!"
EOF

echo "✅ Namespace '${NAMESPACE}' created successfully!"
echo "📄 Example flow created at: ${NAMESPACE_DIR}/example.yaml"
echo ""
echo "Next steps:"
echo "  1. Edit ${NAMESPACE_DIR}/example.yaml or create new flows"
echo "  2. Run: yamllint ${NAMESPACE_DIR}"
echo "  3. Commit your changes"
