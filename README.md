Pro`{ffesional,ductive,totype}` development
===========================================

## What's Pro?

Pro is a runtime for developing prototypes with web
technologies. At its core it's a static file server 
that supports conversions from the most popular
web-development languages into plain html, js and css.

Supported file types:

- *.styl files are compiled by [Stylus](http://learnboost.github.com/stylus/)
  into *.css files.
- *.less files are compiled by [LESS](http://lesscss.org/) into *.css files.
Stylus
- *.jade files are compiled by [jade](http://jade-lang.com/) into *.html files.
- *.coffee files are compiled by [CoffeeScript](http://jashkenas.github.com/coffee-script/)
  into *.js files.
- All other files are served as they are.

To give an example, the following folder structure:

```
index.jade
settings.html
styles/layout.less
styles/theme.styl
styles/libs/jquery-ui.css
scripts/main.coffee
scripts/jquery.js
```

is accessible by the browser in a compiled form at these paths:

```
index.html
settings.html
styles/layout.css
styles/theme.css
styles/libs/jquery-ui.css
scripts/main.js
scripts/jquery.js
```

Prototyper doesn't care what language you prefer, or what folder
structure you want. It only cares that you get your prototypes
up as quickly as possible.

## Install

The easiest way to get started is to install prototyper globally
with npm.

```bash
npm install -g pro
```

This gives you access to the executable `pro`.

## Usage

You can navigate to any folder and run `pro` to start the prototyping
server on port 8080.

```bash
pro
```

From there you can navigate to `http://localhost:8080/` and browse
the contents of the folder where `pro` is running.

Whenever the browser requests a file, prototyper checks if the source
of the file can be found in another file and if it requires compilation.
