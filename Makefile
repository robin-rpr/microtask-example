V8_HOME ?= /YOUR_PATH/v8/v8 # absolute path to V8
GTEST_HOME ?= /YOUR_PATH/googletest/googletest # absolute path to Googletest

v8_out_dir := YOUR_V8_BUILD_NAME # V8 out/<output> folder name
v8_build_dir := $(V8_HOME)/out/$(v8_out_dir)
v8_include_dir := $(V8_HOME)/include
v8_dylibs := -lv8 -lv8_libplatform -lv8_libbase

gtest_include_dir := $(GTEST_HOME)/include
objs := $(filter-out test/main,$(patsubst %.cc, %, $(wildcard test/*.cc)))

# Expecting V8 to be already compiled.
# Missing something? Here are the minimal build steps: 
# https://v8.dev/docs/build

CXXFLAGS = -Wall -g -O0 -std=c++14 -stdlib=libc++ -Wcast-function-type \
	-fno-exceptions -fno-rtti \
	-DV8_COMPRESS_POINTERS \
	-I$(v8_include_dir) \
	-I$(V8_HOME) \
	-I$(v8_build_dir)/gen \
	-L$(v8_build_dir) \
	$(v8_dylibs) \
	-Wl,-L$(v8_build_dir) -Wl,-rpath,$(v8_build_dir) -Wl,-lpthread

.PHONY: gtest-compile
gtest-compile: CXXFLAGS = --verbose -Wall -O0 -g -c $(GTEST_HOME)/src/gtest-all.cc \
	-o $(GTEST_HOME)/gtest-all.o	-std=c++14 \
	-fno-exceptions -fno-rtti \
	-I$(GTEST_HOME) \
	-I$(GTEST_HOME)/include

gtest-compile: 
	${info Building gtest library}
	$(CXX) ${CXXFLAGS} # $@.cc -o $@
	@mkdir -p $(CURDIR)/lib/gtest
	${AR} -rv $(CURDIR)/lib/gtest/libgtest.a $(GTEST_HOME)/gtest-all.o

test/%: CXXFLAGS += test/main.cc $@.cc -o $@ ./lib/gtest/libgtest.a \
	-Wcast-function-type -Wno-unused-variable \
	-Wno-class-memaccess -Wno-comment -Wno-unused-but-set-variable \
	-DV8_INTL_SUPPORT \
	-DDEBUG \
	-I$(V8_HOME)/third_party/icu/source/common/ \
	-I$(gtest_include_dir) \
	-Wl

test/%: test/%.cc test/v8_test_fixture.h
	$(CXX) ${CXXFLAGS}

.PHONY: clean
clean:
	@${RM} $(objs)