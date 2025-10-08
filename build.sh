#!/usr/bin/env bash
set -euo pipefail

# Configuration
REGISTRY="teknofile"
IMAGE_PREFIX="compreface"
IMAGE_TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"
BUILD_OPTS="--no-cache --push"

# Component definitions
declare -A COMPONENTS=(
    ["admin"]="frs_crud:../dev/Dockerfile:."
    ["api"]="frs_core:../dev/Dockerfile:."
    ["db"]=".:db/Dockerfile:db/"
    ["fe"]=".:ui/docker-prod/Dockerfile:ui/"
    ["core"]=".:embedding-calculator/Dockerfile:embedding-calculator/"
)

# Function to build a single component
build_component() {
    local name=$1
    local config=${COMPONENTS[$name]}
    local target
    local dockerfile
    local context
    local target_opt
    
    target=$(echo "$config" | cut -d: -f1)
    dockerfile=$(echo "$config" | cut -d: -f2)
    context=$(echo "$config" | cut -d: -f3)
    target_opt=""
    if [ "$target" != "." ]; then
        target_opt="--target $target"
    fi

    echo "Building $name component..."
    docker buildx build \
        $BUILD_OPTS \
        --file "$dockerfile" \
        --platform "$PLATFORMS" \
        $target_opt \
        --tag "$REGISTRY/$IMAGE_PREFIX-$name:$IMAGE_TAG" \
        "$context"
}

# Function to build all components
build_all() {
    for component in "${!COMPONENTS[@]}"; do
        build_component "$component"
    done
}

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] [COMPONENT...]"
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -l, --list             List available components"
    echo "  -v, --version VERSION  Set the image tag version (default: latest)"
    echo "Components:"
    for component in "${!COMPONENTS[@]}"; do
        echo "  $component"
    done
}

# List available components
list_components() {
    echo "Available components:"
    for component in "${!COMPONENTS[@]}"; do
        echo "  $component"
    done
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -l|--list)
            list_components
            exit 0
            ;;
        -v|--version)
            if [[ -z "${2:-}" ]]; then
                echo "Error: Version argument is required"
                echo
                usage
                exit 1
            fi
            IMAGE_TAG="$2"
            shift 2
            ;;
        -*)
            echo "Error: Unknown option $1"
            echo
            usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -eq 0 ]]; then
    # No components specified - build all
    build_all
else
    # Build specified components
    for component in "$@"; do
        if [[ -n "${COMPONENTS[$component]:-}" ]]; then
            build_component "$component"
        else
            echo "Error: Unknown component '$component'"
            echo
            usage
            exit 1
        fi
    done
fi
