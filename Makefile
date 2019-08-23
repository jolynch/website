web:
	git submodule update --init
	hugo server

draft:
	git submodule update --init
	hugo -D server

publish:
	git submodule update --init
	./build.sh
