# -*- coding: utf-8 -*-
# SOURCE: https://github.com/autopilotpattern/jenkins/blob/master/makefile
MAKEFLAGS += --warn-undefined-variables
# .SHELLFLAGS := -eu -o pipefail

# SOURCE: https://github.com/luismayta/zsh-servers-functions/blob/b68f34e486d6c4a465703472e499b1c39fe4a26c/Makefile
# Configuration.
SHELL = /bin/bash
ROOT_DIR = $(shell pwd)
PROJECT_BIN_DIR = $(ROOT_DIR)/bin
DATA_DIR = $(ROOT_DIR)/var
SCRIPT_DIR = $(ROOT_DIR)/script

WGET = wget
# SOURCE: https://github.com/wk8838299/bullcoin/blob/8182e2f19c1f93c9578a2b66de6a9cce0506d1a7/LMN/src/makefile.osx
HAVE_BREW=$(shell brew --prefix >/dev/null 2>&1; echo $$? )


.PHONY: list help default all check fail-when-git-dirty
.PHONY: pre-commit-install check-connection-postgres monkeytype-stub monkeytype-apply monkeytype-ci

.PHONY: FORCE_MAKE

PR_SHA                := $(shell git rev-parse HEAD)

define ASCILOGO
autosub
=======================================
endef

export ASCILOGO

# http://misc.flogisoft.com/bash/tip_colors_and_formatting

RED=\033[0;31m
GREEN=\033[0;32m
ORNG=\033[38;5;214m
BLUE=\033[38;5;81m
NC=\033[0m

export RED
export GREEN
export NC
export ORNG
export BLUE

# verify that certain variables have been defined off the bat
check_defined = \
		$(foreach 1,$1,$(__check_defined))
__check_defined = \
		$(if $(value $1),, \
			$(error Undefined $1$(if $(value 2), ($(strip $2)))))

export PATH := ./script:./bin:./bash:./venv/bin:$(PATH)

MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_FOLDER := $(notdir $(patsubst %/,%,$(dir $(MKFILE_PATH))))
CURRENT_DIR := $(shell pwd)
MAKE := make
PY_MODULE_NAME := autosub

list_allowed_args := product ip command role tier cluster non_root_user host

default: all

all: info


#--- User Defined Variable ---
PACKAGE_NAME="autosub"

# Python version Used for Development
PY_VER_MAJOR="3"
PY_VER_MINOR="9"
PY_VER_MICRO="0"

#  Other Python Version You Want to Test With
# (Only useful when you use tox locally)
TEST_PY_VER3="3.9.0"

# If you use pyenv-virtualenv, set to "Y"
USE_PYENV="Y"

# S3 Bucket Name
DOC_HOST_BUCKET_NAME="NoBucket"


#--- Derive Other Variable ---

# Virtualenv Name
VENV_NAME="${PACKAGE_NAME}${PY_VER_MAJOR}"

# Project Root Directory
GIT_ROOT_DIR=${shell git rev-parse --show-toplevel}
PROJECT_ROOT_DIR=${shell pwd}

OS=${shell uname -s}

ifeq (${OS}, Windows_NT)
		DETECTED_OS := Windows
else
		DETECTED_OS := $(shell uname -s)
endif

.PHONY: pip-tools
pip-tools:
ifeq (${DETECTED_OS}, Darwin)
	ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install pip-tools pipdeptree
else
	pip install pip-tools pipdeptree
endif

.PHONY: pip-tools-osx
pip-tools-osx: pip-tools

.PHONY: pip-tools-upgrade
pip-tools-upgrade:
ifeq (${DETECTED_OS}, Darwin)
	ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install pip-tools pipdeptree --upgrade
else
	pip install pip-tools pipdeptree --upgrade
endif

.PHONY: pip-compile-upgrade-all
pip-compile-upgrade-all: pip-tools
	pip-compile --output-file requirements.txt requirements.in --upgrade
	

.PHONY: pip-compile
pip-compile: pip-tools
	pip-compile --output-file requirements.txt requirements.in
	

.PHONY: pip-compile-rebuild
pip-compile-rebuild: pip-tools
	pip-compile --rebuild --output-file requirements.txt requirements.in
	

.PHONY: install-deps-all
install-deps-all:
ifeq (${DETECTED_OS}, Darwin)
	PKG_CONFIG_PATH=/usr/local/opt/libffi/lib/pkgconfig ARCHFLAGS="-arch x86_64" LDFLAGS="-L/usr/local/opt/openssl/lib" CFLAGS="-I/usr/local/opt/openssl/include" pip install -r requirements.txt
	
else
	pip install -r requirements.txt
	
endif

.PHONY: pip-compile-and-install
pip-compile-and-install: pip-compile install-deps-all ## generate requirement.txt files, then install all of those dependencies

.PHONY: install-all
install-all: install-deps-all

deepspeech-0.8.2-models.pbmm:
# Model file (~190 MB) 
	aria2c https://github.com/mozilla/DeepSpeech/releases/download/v0.8.2/deepspeech-0.8.2-models.pbmm

deepspeech-0.8.2-models.scorer:
# Scorer file (~900 MB)
	aria2c https://github.com/mozilla/DeepSpeech/releases/download/v0.8.2/deepspeech-0.8.2-models.scorer

.PHONY: models
models: deepspeech-0.8.2-models.pbmm deepspeech-0.8.2-models.scorer
	mkdir audio || true
	mkdir output || true


.PHONY: autosub
autosub:
	python3 autosub/main.py --file $(FILE)