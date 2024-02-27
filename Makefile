VERSION = 0.0.8

all: build install dev

dev: main.rb
	ruby main.rb
install:
	gem install pickles-$(VERSION).gem
uninstall:
	gem uninstall pickles
build:
	gem build