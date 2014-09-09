# Variables
BIN = ./node_modules/.bin
COFFEE = ${BIN}/coffee
BROWSERIFY = ${BIN}/browserify
UGLIFY = ${BIN}/uglifyjs
DAEMON = ./watch.sh
PROJECT = kaliedoscope

# Targets
default: web

deps: 
	if test -d "node_modules"; then echo "dependencies installed"; else npm install; fi
  
clean:
	if [ -e "build/${PROJECT}.js" ]; then rm build/${PROJECT}.js; fi
	rm -rf build

# compile the NPM library version to JavaScript
build: clean
	${COFFEE} -o build -c src/

# Watch a directory then hit web build
watch: clean
	${DAEMON} src make
  
# compiles the NPM version files into a combined minified web .js library
web: build
	${BROWSERIFY} build/${PROJECT}.js > build/${PROJECT}_full.js
	${UGLIFY} build/${PROJECT}_full.js > build/${PROJECT}.min.js
	cp build/${PROJECT}_full.js html/js/${PROJECT}.js
	cp build/${PROJECT}.min.js html/js/${PROJECT}.min.js

docs:
	docco src/*.coffee

test: build
	mocha --compilers coffee:coffee-script

dist: deps web

publish: dist
	npm publish
