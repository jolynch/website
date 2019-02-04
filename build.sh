#!/bin/bash

echo "Building site"

hugo

cd public
git add .

git commit

git push origin master
