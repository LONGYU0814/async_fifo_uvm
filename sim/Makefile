# ============================================================
# Async FIFO UVM Project Makefile
# ============================================================


# ------------------------------------------------------------
# Tools
# ------------------------------------------------------------

VCS  := vcs
URG  := urg

UVM_HOME ?= /home/longyu/vcs/vcs2018/vcs/O-2018.09-SP2/etc/uvm-1.2/src

VERDI_HOME ?= /home/longyu/vcs/verdi/verdi/Verdi_O-2018.09-SP2
VERDI      := $(VERDI_HOME)/bin/verdi


# ------------------------------------------------------------
# Project
# ------------------------------------------------------------

FILELIST := filelist.f
SIMV     := simv

ASSERT_HIER := assert_hier.cfg

WAVE_FILE := ../waves/async_fifo_uvm.fsdb


# ------------------------------------------------------------
# UVM
# ------------------------------------------------------------

TEST      ?= fifo_test
VERBOSITY ?= UVM_LOW


# ------------------------------------------------------------
# Regression Tests
# ------------------------------------------------------------

TESTS := \
	fifo_test \
	fifo_full_test \
	fifo_illegal_test \
	fifo_wrap_test \
	fifo_reset_test


# ------------------------------------------------------------
# Coverage
# ------------------------------------------------------------

CM := line+cond+branch+tgl+assert

COMPILE_COV_DB := compile_cov.vdb

MERGED_REPORT := merged_cov_text


# ------------------------------------------------------------
# VCS Compile Options
# ------------------------------------------------------------

VCS_OPTS := \
	-full64 \
	-sverilog \
	+define+UVM_NO_DPI \
	+incdir+$(UVM_HOME) \
	-timescale=1ns/1ps \
	-debug_access+all \
	-cm $(CM) \
	-cm_assert_hier $(ASSERT_HIER) \
	-cm_dir $(COMPILE_COV_DB) \
	-P $(VERDI_HOME)/share/PLI/VCS/linux64/novas.tab \
	   $(VERDI_HOME)/share/PLI/VCS/linux64/pli.a


# ============================================================
# Default
# ============================================================

.PHONY: all
all: compile


# ============================================================
# Compile
# ============================================================

.PHONY: compile
compile:
	@echo "=========================================="
	@echo " Compiling Async FIFO UVM Environment"
	@echo "=========================================="

	rm -rf $(SIMV) $(SIMV).daidir csrc
	rm -rf $(COMPILE_COV_DB)

	$(VCS) $(VCS_OPTS) \
		$(UVM_HOME)/uvm_pkg.sv \
		-f $(FILELIST) \
		-o $(SIMV) \
		-l compile_cov.log

	@echo ""
	@echo "COMPILE PASS"


# ============================================================
# Run One Test
#
# Usage:
#
# make test TEST=fifo_test
# make test TEST=fifo_full_test
# make test TEST=fifo_illegal_test
# ============================================================

.PHONY: test
test:
	@echo "=========================================="
	@echo " Running TEST=$(TEST)"
	@echo "=========================================="

	rm -rf $(TEST).vdb
	rm -f  $(TEST)_cov.log

	./$(SIMV) \
		+UVM_TESTNAME=$(TEST) \
		+UVM_VERBOSITY=$(VERBOSITY) \
		-cm $(CM) \
		-cm_dir $(TEST).vdb \
		-l $(TEST)_cov.log

	@echo ""
	@echo "---------- UVM RESULT ----------"
	@grep -E "UVM_ERROR :|UVM_FATAL :" $(TEST)_cov.log | tail -2


# ============================================================
# Compile + One Test
#
# Usage:
#
# make run TEST=fifo_full_test
# ============================================================

.PHONY: run
run: compile test


# ============================================================
# Regression
#
# Runs:
#
# fifo_test
# fifo_full_test
# fifo_illegal_test
# fifo_wrap_test
# fifo_reset_test
# ============================================================

.PHONY: regression
regression: compile
	@echo ""
	@echo "=========================================="
	@echo " Starting Regression"
	@echo "=========================================="

	@set -e; \
	for t in $(TESTS); do \
		echo ""; \
		echo "------------------------------------------"; \
		echo " RUNNING $$t"; \
		echo "------------------------------------------"; \
		rm -rf $$t.vdb; \
		rm -f $$t"_cov.log"; \
		./$(SIMV) \
			+UVM_TESTNAME=$$t \
			+UVM_VERBOSITY=$(VERBOSITY) \
			-cm $(CM) \
			-cm_dir $$t.vdb \
			-l $$t"_cov.log"; \
		\
		if grep -Eq "UVM_ERROR[[:space:]]*:[[:space:]]*0" $$t"_cov.log" && \
		   grep -Eq "UVM_FATAL[[:space:]]*:[[:space:]]*0" $$t"_cov.log"; then \
			echo " PASS: $$t"; \
		else \
			echo " FAIL: $$t"; \
			exit 1; \
		fi; \
	done

	@echo ""
	@echo "=========================================="
	@echo " ALL REGRESSION TESTS PASS"
	@echo "=========================================="


# ============================================================
# Coverage Merge
# ============================================================

.PHONY: coverage
coverage: regression
	@echo ""
	@echo "=========================================="
	@echo " Merging Coverage"
	@echo "=========================================="

	rm -rf $(MERGED_REPORT)

	$(URG) \
		-dir $(COMPILE_COV_DB) \
		-dir fifo_test.vdb \
		-dir fifo_full_test.vdb \
		-dir fifo_illegal_test.vdb \
		-dir fifo_wrap_test.vdb \
		-dir fifo_reset_test.vdb \
		-metric $(CM) \
		-format text \
		-report $(MERGED_REPORT)

	@echo ""
	@echo "=========================================="
	@echo " Coverage Summary"
	@echo "=========================================="

	@cat $(MERGED_REPORT)/dashboard.txt


# ============================================================
# Coverage Summary Only
# ============================================================

.PHONY: summary
summary:
	@echo "=========================================="
	@echo " Coverage Summary"
	@echo "=========================================="
	@cat $(MERGED_REPORT)/dashboard.txt

	@echo ""
	@echo "=========================================="
	@echo " FIFO Assertion Coverage"
	@echo "=========================================="

	@grep -n -A 8 \
		"Assert Coverage for Module : fifo_assertions" \
		$(MERGED_REPORT)/modinfo.txt


# ============================================================
# Open Verdi
# ============================================================

.PHONY: verdi
verdi:
	@echo "Opening Verdi..."

	$(VERDI) \
		-sv \
		-f $(FILELIST) \
		-ssf $(WAVE_FILE) &


# ============================================================
# Clean
# ============================================================

.PHONY: clean
clean:
	rm -rf simv
	rm -rf simv.daidir
	rm -rf csrc

	rm -rf *.vdb
	rm -rf merged_cov_text
	rm -rf merged_cov_report

	rm -f *.log
	rm -f ucli.key
	rm -f vc_hdrs.h

	@echo "CLEAN DONE"


# ============================================================
# Help
# ============================================================

.PHONY: help
help:
	@echo ""
	@echo "Async FIFO UVM Makefile"
	@echo ""
	@echo "make compile"
	@echo "    Compile UVM testbench"
	@echo ""
	@echo "make test TEST=fifo_test"
	@echo "    Run one test using existing simv"
	@echo ""
	@echo "make run TEST=fifo_full_test"
	@echo "    Compile then run one test"
	@echo ""
	@echo "make regression"
	@echo "    Compile and run all tests"
	@echo ""
	@echo "make coverage"
	@echo "    Run regression and merge coverage"
	@echo ""
	@echo "make summary"
	@echo "    Show merged coverage summary"
	@echo ""
	@echo "make verdi"
	@echo "    Open FSDB waveform in Verdi"
	@echo ""
	@echo "make clean"
	@echo "    Delete generated files"
	@echo ""
