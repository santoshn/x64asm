##### CONSTANT DEFINITIONS

GCC=ccache g++

INC=-I./

#OBJ=build/cfg/control_flow_graph.o \
		\
		build/att/att_reader.o \
		build/att/att_writer.o \
		\

OBJ=build/assembler/assembler.o \
		\
		build/code/cr.o \
		build/code/dr.o \
		build/code/imm.o \
		build/code/modifier.o \
		build/code/mm.o \
		build/code/r.o \
		build/code/sreg.o \
		build/code/st.o \
		build/code/xmm.o \
		build/code/ymm.o #\
		build/code/reg_set.o \
		\
		build/sandboxer/sandboxer.o \
		\
		build/stream/stream.o \
		\
		build/tracer/tracer.o

BIN=#bin/att_exec \
		bin/att_sandbox \
		bin/att_trace \
		bin/att2dot \
		bin/att2hex \
		bin/att2bin

DOC=doc/html

LIB=lib/libx64.a

##### TOP LEVEL TARGETS (release is default)

all: release

debug:
	make -C . erthing FLEXOPS="-d" BISONOPS="-t" OPT="-std=c++0x -Wall -fPIC -g"
release:
	make -C . erthing OPT="-std=c++0x -Wall -fPIC -DNDEBUG -O3 -funroll-all-loops"
profile:
	make -C . erthing OPT="-std=c++0x -Wall -fPIC -DNDEBUG -O3 -funroll-all-loops -pg"

erthing: $(LIB) $(BIN) $(DOC)

##### TEST TARGETS

test: erthing
	cd test/stokeasm_py; python setup.py build; rm *.so; find -name "*.so" -print0 | xargs -0 /bin/cp -f -t .
	cd test; ./run_tests.sh

##### CLEAN TARGETS

clean:
	rm -rf $(BIN) $(DOC) $(LIB) build/* 
	rm -f src/assembler/assembler.defn src/assembler/assembler.decl
	rm -f src/code/opcode.enum
	rm -rf test/enumerate_all.hi test/enumerate_all.o test/tmp/* test/enumerate_all
	rm -f test/stokeasm_py/*.so
	rm -rf test/stokeasm_py/build

##### CODEGEN TARGETS

codegen: src/assembler/assembler.defn

src/assembler/assembler.defn: src/codegen/Codegen.hs src/codegen/x86.csv 
	mkdir -p build/codegen
	cd src/codegen && \
		ghc Codegen.hs && \
		./Codegen x86.csv && \
		mv assembler.defn ../assembler && \
		mv assembler.decl ../assembler && \
		mv opcode.enum ../code && \
		rm -f *.hi *.o Codegen

#	cd build/codegen && \
		./cfg ../../src/codegen/x64.csv ../../src/codegen/latencies.csv && \
		./assembler ../../src/codegen/x64.csv && \
		mv assembler.* ../../src/gen/ && \
		mv opcode.* ../../src/gen/
#	flex $(FLEXOPS) -Patt src/codegen/att.l && \
		mv lex.att.c src/gen
#	bison $(BISONOPS) -batt -patt --defines src/codegen/att.y && \
		mv att.tab.h src/gen && \
		mv att.tab.c src/gen
		
##### DOCUMENTATION TARGETS

doc/html: doxyfile src/cfg/*.cc src/cfg/*.h \
          src/assembler/*.cc src/assembler/*.h \
					src/code/*.h src/code/*.cc
	doxygen doxyfile

##### BUILD TARGETS

build/att/%.o: src/att/%.cc src/att/%.h codegen
	mkdir -p build/att && $(GCC) $(OPT) $(INC) -c $< -o $@
build/assembler/%.o: src/assembler/%.cc src/assembler/%.h codegen
	mkdir -p build/assembler && $(GCC) $(OPT) $(INC) -c $< -o $@
build/cfg/%.o: src/cfg/%.cc src/cfg/%.h codegen
	mkdir -p build/cfg && $(GCC) $(OPT) $(INC) -c $< -o $@
build/code/%.o: src/code/%.cc src/code/%.h codegen
	mkdir -p build/code && $(GCC) $(OPT) $(INC) -c $< -o $@
build/sandboxer/%.o: src/sandboxer/%.cc src/sandboxer/%.h codegen
	mkdir -p build/sandboxer && $(GCC) $(OPT) $(INC) -c $< -o $@
build/stream/%.o: src/stream/%.cc src/stream/%.h codegen
	mkdir -p build/stream && $(GCC) $(OPT) $(INC) -c $< -o $@
build/tracer/%.o: src/tracer/%.cc src/tracer/%.h codegen
	mkdir -p build/tracer && $(GCC) $(OPT) $(INC) -c $< -o $@

##### LIBRARY TARGET

$(LIB): $(OBJ)
	ar rcs $@ $(OBJ)

##### BINARY TARGET

bin/att_exec: tools/att_exec.cc $(LIB)
	$(GCC) $(OPT) $< -o $@ $(INC) $(LIB)
bin/att_sandbox: tools/att_sandbox.cc $(LIB)
	$(GCC) $(OPT) $< -o $@ $(INC) $(LIB)
bin/att_trace: tools/att_trace.cc $(LIB)
	$(GCC) $(OPT) $< -o $@ $(INC) $(LIB)
bin/att2dot: tools/att2dot.cc $(LIB)
	$(GCC) $(OPT) $< -o $@ $(INC) $(LIB)
bin/att2hex: tools/att2hex.cc $(LIB)
	$(GCC) $(OPT) $< -o $@ $(INC) $(LIB)
bin/att2bin: tools/att2bin.cc $(LIB)
	$(GCC) $(OPT) $< -o $@ $(INC) $(LIB)
