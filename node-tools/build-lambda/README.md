# Build Lambda - Node.js Action

This GitHub Action builds a Node.js project, preparing it for deployment, typically to a Lambda-like environment. It sets up a specified Node.js version, installs dependencies, runs a build script, and then copies the build artifacts to a `build-output` directory.

## Inputs

| Name              | Description                                                                 | Required | Default         |
|-------------------|-----------------------------------------------------------------------------|----------|-----------------|
| `project-path`    | Path to the Node.js project directory.                                      | `true`   |                 |
| `node-version`    | Node.js version to use for building (e.g., '16', '18', '20').                 | `true`   | `'18'`          |
| `install-command` | Command to install dependencies.                                            | `false`  | `'npm install'` |
| `build-command`   | Command to build the project.                                               | `false`  | `'npm run build'`|

## Outputs

| Name                | Description                                         |
|---------------------|-----------------------------------------------------|
| `build-output-path` | Path to the directory containing the build artifacts. This will be `${GITHUB_WORKSPACE}/build-output`. |

## Example Usage

```yaml
name: Build Node.js Lambda

on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Build Lambda function
        uses: ./node-tools/build-lambda # Assumes action is in this repo
        # Or use: your-org/your-repo/node-tools/build-lambda@main if in another repo
        with:
          project-path: 'src/my-lambda-function' # Path to your lambda source code
          node-version: '18'
          # Optional: specify custom install or build commands
          # install-command: 'yarn install --frozen-lockfile'
          # build-command: 'yarn build:prod'

      - name: Upload artifacts (example)
        uses: actions/upload-artifact@v3
        with:
          name: lambda-build-artifacts
          path: ${{ steps.build.outputs.build-output-path }} # Use the output from the build step
          # Note: The actual output path will be something like /home/runner/work/your-repo/your-repo/build-output
          # You might need to adjust paths based on your runner environment and GITHUB_WORKSPACE

      # Example: Deploy to AWS Lambda (conceptual)
      # - name: Deploy to AWS Lambda
      #   uses: aws-actions/aws-lambda-deploy@v1 # This is a hypothetical action
      #   with:
      #     function-name: 'my-lambda-function'
      #     zip-file: ${{ steps.build.outputs.build-output-path }}/artifact.zip # Assuming your build creates a zip
```

## How it Works

1.  **Setup Node.js**: Uses `actions/setup-node` to install and configure the specified `node-version`.
2.  **Install Dependencies**: Navigates to the `project-path` and runs the `install-command`.
3.  **Build Project**: Runs the `build-command` in the `project-path`.
4.  **Prepare Output**:
    *   Creates a directory named `build-output` inside the `GITHUB_WORKSPACE`.
    *   The `entrypoint.sh` script then attempts to copy common build artifact directories (`dist/`, `build/`, `public/`) from the `project-path` into this `build-output` directory.
    *   If these standard directories are not found, it falls back to copying `package.json`, `package-lock.json` (if available), and `node_modules/` (if available).
    *   It's recommended that your build process outputs artifacts to a standard location like `dist` or `build` within your `project-path`.

## Customizing Artifact Copying

The `entrypoint.sh` script included in this action has a basic logic for finding and copying build artifacts. If your project has a different structure or you need more specific control over what gets copied, you can:

1.  **Fork this action**: Modify the `entrypoint.sh` script to match your project's needs.
2.  **Standardize your build output**: Ensure your project's build script outputs all necessary files into a `dist` or `build` directory within your `project-path`.

This action provides a general-purpose way to build Node.js projects. For complex scenarios, further customization of the `entrypoint.sh` script might be necessary.
