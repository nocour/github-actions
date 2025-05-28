#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

PROJECT_PATH="$1"
# NODE_VERSION="$2" # Already handled by actions/setup-node in action.yml
# INSTALL_COMMAND="$3" # Already executed in action.yml
# BUILD_COMMAND="$4" # Already executed in action.yml

echo "--- Entrypoint Script Started ---"
echo "Project Path: ${PROJECT_PATH}"
echo "GitHub Workspace: ${GITHUB_WORKSPACE}"

# Define the output directory within the GitHub Workspace
OUTPUT_DIR="${GITHUB_WORKSPACE}/build-output"

echo "Creating output directory: ${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

echo "Changing to project path: ${PROJECT_PATH}"
cd "${PROJECT_PATH}"

echo "Copying build artifacts to ${OUTPUT_DIR}"

# Common Node.js build output directories and files
# Add or remove based on common patterns or if a specific artifact_path input is added later
if [ -d "dist" ]; then
  echo "Copying dist/ folder..."
  cp -r dist/* "${OUTPUT_DIR}/"
elif [ -d "build" ]; then
  echo "Copying build/ folder..."
  cp -r build/* "${OUTPUT_DIR}/"
elif [ -d "public" ]; then # Common for static sites
  echo "Copying public/ folder..."
  cp -r public/* "${OUTPUT_DIR}/"
elif [ -f "package.json" ]; then
  # Fallback: if specific build folders aren't found,
  # copy essential files for a lambda function:
  # package.json, node_modules (if they exist after npm install), and common entry files.
  # This part might need to be more sophisticated or configurable.
  echo "Copying package.json, package-lock.json (if exists), and other relevant files..."
  cp package.json "${OUTPUT_DIR}/"
  if [ -f "package-lock.json" ]; then
    cp package-lock.json "${OUTPUT_DIR}/"
  fi
  if [ -d "node_modules" ]; then
    echo "Copying node_modules/ folder..."
    # Note: Copying node_modules can be large and slow.
    # Ideally, the lambda deployment package handles dependencies separately.
    # For a generic build action, providing the modules might be expected.
    cp -R node_modules "${OUTPUT_DIR}/"
  fi
  # Add common main files, e.g., index.js, app.js. User might need to configure this.
  if [ -f "index.js" ]; then cp index.js "${OUTPUT_DIR}/"; fi
  if [ -f "app.js" ]; then cp app.js "${OUTPUT_DIR}/"; fi
  # Add other potential compiled outputs if not in dist/build
  if [ -d "lib" ]; then cp -r lib/* "${OUTPUT_DIR}/lib/" || true; fi # if lib is output
  if [ -d "src" ] && [ ! -d "dist" ] && [ ! -d "build" ]; then # if src is used directly (e.g. with ts-node in dev)
     # Potentially copy src if no other build output is found, though this is less common for 'build'
     echo "Warning: No standard 'dist' or 'build' folder found, consider copying 'src' if applicable for your runtime."
  fi
else
  echo "Warning: No standard build output (dist, build, public) or package.json found in ${PROJECT_PATH}."
  echo "Please ensure your build command ('${BUILD_COMMAND}') generates artifacts in a recognized location, or customize this script."
  # Create a dummy file to ensure the output directory is not empty, preventing potential errors in downstream steps
  touch "${OUTPUT_DIR}/.empty_placeholder"
fi

echo "Listing contents of ${OUTPUT_DIR}:"
ls -la "${OUTPUT_DIR}"

echo "--- Entrypoint Script Finished ---"
