"""
The setup script is the centre of all activity in building, distributing,
and installing modules using the Distutils. It is required for ``pip install``.
See more: https://docs.python.org/2/distutils/setupscript.html
"""
from __future__ import print_function

import os
import pprint
import sys
from datetime import date
from shutil import rmtree

from setuptools import Command
from setuptools import find_packages
from setuptools import setup

from urllib.parse import urlparse, urlunparse
from pathlib import PosixPath


import os
from setuptools import setup
from setuptools import setup, find_packages

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

def read_requirements_file(path, removes_links=True):
    """
    Read requirements.txt, ignore comments
    """
    requires = list()
    f = open(path, "rb")
    for line in f.read().decode("utf-8").split("\n"):
        line = line.strip()
        if "#" in line:
            line = line[: line.find("#")].strip()
        # skip if we are installing via scm repository
        if "-e git+https" in line:
            print("BAD LINE: {}".format(line))
            continue
        if "https:" in line and "tarball" in line:

            uri = urlparse(line)

            if "egg=" in uri.fragment:
                fragment_split = uri.fragment.split('=')
                dependency_name = fragment_split[1]
            else:
                fragment_split = uri.fragment.split('=')
                dependency_name = fragment_split[2]

            path_split = uri.path.split('/')
            line = f"{dependency_name} @ git+{uri.scheme}://{uri.netloc}/{path_split[1]}/{path_split[2]}@{path_split[4]}#egg={dependency_name}"
            print(line)

        if line:
            requires.append(line)
    return requires


DIR = os.path.dirname(os.path.abspath(__file__))

REQUIREMENTS_PATH = f"{DIR}/requirements.txt"

try:
    INSTALL_PACKAGES = read_requirements_file(REQUIREMENTS_PATH)
except:  # noqa: E722
    print("'requirements.txt' not found!")
    INSTALL_PACKAGES = list()

# INSTALL_PACKAGES = open(os.path.join(DIR, 'requirements.txt')).read().splitlines()

with open("README.md", "r") as fh:
    README = fh.read()

setup(
    name="AutoSub",
    packages="autosub",
    version="0.0.2",
    author="Abhiroop Talasila",
    author_email="abhiroop.talasila@gmail.com",
    description="CLI application to generate subtitle file (.srt) for any video file using using STT",
    long_description=README,
    install_requires=INSTALL_PACKAGES,
    long_description_content_type="text/markdown",
    url="https://github.com/universityofprofessorex/AutoSub",
    keywords=['speech-to-text','deepspeech','machine-learning'],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires='>=3.5',
)
