test:
	PRO_LOG_LEVEL=none ./node_modules/.bin/mocha --compilers coffee:./node_modules/coffee-script

build:
	./node_modules/.bin/coffee -co lib src

watch:
	./node_modules/.bin/coffee -cwo lib src

.PHONY: test