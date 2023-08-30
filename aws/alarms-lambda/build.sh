#!/bin/bash

rm -rf dist/
pip install --platform manylinux2014_x86_64 --target=dist --implementation cp --python-version 3.11 --only-binary=:all: --upgrade  -r requirements.txt
ls -lart
cp main.py dist/
ls -lart dist/
cd dist
zip -qr ../python-package.zip .