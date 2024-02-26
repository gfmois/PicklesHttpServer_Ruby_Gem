VERSION = 0.0.7

all: build install dev

dev:
	ruby main.rb
install:
	gem install pickles-$(VERSION).gem
uninstall:
	gem uninstall pickles
build:
	gem build