all:
	cd scripts; sh checkdep.sh
	mkdir flann-1.6.11-src/build
	cd flann-1.6.11-src/build; cmake ..; make -j
	cd graclus1.2; make -j
	cd lmfit-3.2; ./configure; make
	cd bundler-v0.4-source; make -j
	cd cmvs/program/main; make -j
	cd RunCmdParallel; make
	cd SiftMatcher; make
	@echo ''
	@echo ''
	@echo '--------------------------------------------------------------------'
	@echo '                            IMPORTANT !!!'
	@echo '--------------------------------------------------------------------'
	@echo 'Copy bundler-v0.4-source/lib/libANN_char.so to '
	@echo '/usr/local/lib and run ldconfig before running RunSFM.'
	@echo ''

clean:
	cd flann-1.6.11-src/build; rm -rf *
	cd graclus1.2; make clean
	cd lmfit-3.2; make clean
	cd bundler-v0.4-source; make clean
	cd cmvs/program/main; make clean
	cd RunCmdParallel; make clean
	cd SiftMatcher; make clean
