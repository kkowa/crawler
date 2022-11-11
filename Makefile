#!/usr/bin/env make -f

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --silent

SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.DEFAULT_GOAL := help
help: Makefile
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

LOCBIN := ${PWD}/.bin
PATH := ${PATH}:${LOCBIN}


# =============================================================================
# Common
# =============================================================================
PROTOC_VERSION := $(shell sed -nE 's/ARG PROTOC_VERSION=\"(.+)\"/\1/p' Dockerfile)
GOLANGCI_LINT_VERSION := $(shell sed -nE 's/ARG GOLANGCI_LINT_VERSION=\"(.+)\"/\1/p' Dockerfile)

install:  ## Install the app and required tools locally
	command -v goenv > /dev/null && goenv install --skip-existing "$$(goenv local)"

	if ! command -v protoc > /dev/null; then
		zipfile="protoc-${PROTOC_VERSION}-$$(uname -s)-$$(uname -m).zip"
		curl -fsSL -O "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/$${zipfile}" \
			&& unzip -nj "$${zipfile}" bin/protoc -d "${LOCBIN}" \
			&& rm $${zipfile}
	fi

	! command -v golangci-lint > /dev/null && \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "${LOCBIN}" "${GOLANGCI_LINT_VERSION}"

	! command -v air > /dev/null && \
		curl -fsSL https://raw.githubusercontent.com/cosmtrek/air/master/install.sh | sh -s -- -b "${LOCBIN}"

	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	go mod download
.PHONY: install

init:  ## Initialize project repository
	git submodule update --init
	pre-commit autoupdate
	pre-commit install --install-hooks --hook-type pre-commit --hook-type commit-msg
.PHONY: init

run:  ## Run development server
	air
.PHONY: run


# =============================================================================
# CI
# =============================================================================
ci: lint test scan  ## Run CI tasks
.PHONY: ci

generate:  ## Generate codes from schemas
	mkdir -p _generated/grpc
	protoc \
		--proto_path=idl/grpc/protos \
		--go-grpc_opt=paths=source_relative \
		--go-grpc_out=_generated/grpc \
		--go_opt=paths=source_relative \
		--go_out=_generated/grpc \
		idl/grpc/protos/helloworld/*.proto
.PHONY: generate

format:  ## Run autoformatters
	golangci-lint run --fix --verbose
.PHONY: format

lint:  ## Run all linters
	golangci-lint run --verbose
.PHONY: lint

test:  ## Run tests
	go test -race -coverprofile=coverage.txt -covermode=atomic
	go tool cover -html=coverage.txt -o ./coverage.html
	rm coverage.txt
.PHONY: test

scan:  ## Run all scans

.PHONY: scan


# =============================================================================
# Handy Scripts
# =============================================================================
clean:  ## Remove temporary files
	rm -rf .tmp/ coverage.{txt,xml,html} report.xml
	find . -path "*.log*" -delete
.PHONY: clean
