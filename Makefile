.PHONY: help install lint pre-commit

help:
	@echo "Available targets:"
	@echo "  install     Install pre-commit hooks"
	@echo "  lint        Run pre-commit hooks"
	@echo "  pre-commit  Run all pre-commit checks"

install:
	pre-commit install

lint:
	pre-commit run --all-files

pre-commit:
	pre-commit run --all-files
