.PHONY: test compile

# 指定 V11 版本的工具
SV2V_PATH = /home/lao/tools/sv2v/bin/sv2v

export LIBPYTHON_LOC=$(shell cocotb-config --libpython)
# 模式规则的写法
test_%:
	make compile
	iverilog -o build/sim.vvp -s gpu -g2012 build/gpu.v
	MODULE=test.test_$* vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus build/sim.vvp

compile:
	make compile_alu
	$(SV2V_PATH) -I src/* -w build/gpu.v
	echo "" >> build/gpu.v
	cat build/alu.v >> build/gpu.v
	echo '`timescale 1ns/1ns' > build/temp.v
	cat build/gpu.v >> build/temp.v
	mv build/temp.v build/gpu.v

compile_%:
	$(SV2V_PATH) -w build/$*.v src/$*.sv

# TODO: Get gtkwave visualizaiton

show_%: %.vcd %.gtkw
	gtkwave $^

# lao test
sv2v:
	$(SV2V_PATH) -w lao/gpu.v src/*.sv
sv2v_%:
	$(SV2V_PATH) -w lao/$*.v src/$*.sv