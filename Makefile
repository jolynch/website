web:
	git submodule update --init
	hugo server

publish:
	git submodule update --init
	./build.sh
