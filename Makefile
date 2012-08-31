test:
	PRO_LOG_LEVEL=none ./node_modules/.bin/mocha --compilers coffee:./node_modules/coffee-script

build:
	./node_modules/.bin/coffee -co lib src

.PHONY: test