#!/usr/bin/env bash

python3 -m venv sub || true
source sub/bin/activate
python3 -c "import sys;print(sys.executable)"

pip install --upgrade pip wheel better_exceptions bpython
pip install pip-tools pipdeptree
pip3 install -r requirements.txt