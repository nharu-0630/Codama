# Codama Project Makefile

.PHONY: help backend-openapi frontend-generate-client clean

# Default target
help:
	@echo "Available commands:"
	@echo "  backend-openapi         Generate OpenAPI YAML from FastAPI backend"
	@echo "  frontend-generate-client Generate Dart client from OpenAPI YAML"
	@echo "  clean                   Clean generated files"

# Generate OpenAPI YAML from FastAPI backend
backend-openapi:
	@echo "Generating OpenAPI YAML from FastAPI backend..."
	cd backend && uv run python -c "from main import app; import yaml; import json; spec = app.openapi(); print(yaml.dump(spec, default_flow_style=False))" > ../openapi.yaml
	@echo "OpenAPI YAML generated at ./openapi.yaml"

# Generate Dart client from OpenAPI YAML
frontend-generate-client:
	@echo "Generating Dart client from OpenAPI YAML..."
	@if [ ! -f openapi.yaml ]; then echo "Error: openapi.yaml not found. Run 'make backend-openapi' first."; exit 1; fi
	mkdir -p frontend/openapi/generated/client
	openapi-generator generate -i openapi.yaml -g dart-dio -o frontend/openapi/generated/client/
	@echo "Dart client generated at frontend/openapi/generated/client/"

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -f openapi.yaml
	rm -rf frontend/openapi/generated/
	@echo "Clean completed"