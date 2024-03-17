VERSION = 0.0.1

all: build install

dev: main.rb
	ruby main.rb
install:
	gem install pickles_http-$(VERSION).gem
uninstall:
	gem uninstall pickles
build:
	gem build