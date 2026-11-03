#!/usr/bin/env python3
"""Compile and run the self-checking integration and upstream unit tests."""
import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path
from assemble import assemble, write_image

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / ".build"
TESTS = {
    "integration": ("tb_lab6", ROOT / "tests/tb_lab6.sv"),
    "individual": ("tb_individual", ROOT / "tests/tb_individual.sv"),
    "memory": ("lab_06_tb_data_mem", ROOT / "tests/upstream/lab_06.tb_data_mem.sv"),
    "lsu": ("lab_08_tb_lsu", ROOT / "tests/upstream/lab_08.tb_lsu.sv"),
    "csr": ("lab_10_tb_csr", ROOT / "tests/upstream/lab_10.tb_csr.sv"),
    "irq": ("lab_10_tb_irq", ROOT / "tests/upstream/lab_10.tb_irq.sv"),
    "lab07": ("lab_07_tb_processor_system", ROOT / "tests/upstream/lab_07.tb_processor_system.sv"),
    "lab11": ("lab_11_tb_processor_system", ROOT / "tests/upstream/lab_11.tb_processor_system.sv"),
}


def prepare_images():
    official = ROOT / "programs/lab11.mem"
    if assemble((ROOT / "programs/lab11.S").read_text()) != [int(w, 16) for w in official.read_text().split()]:
        raise RuntimeError("Assembler does not reproduce the official lab 11 image")
    for folder in (ROOT / "programs", ROOT / "tests/programs"):
        for source in sorted(folder.glob("*.S")):
            write_image(source, source.with_suffix(".mem"))


def bench_for_verilator(name, path):
    # Keep the original benches intact for Vivado. Constrained random size
    # selection is replaced with equivalent legal choices to avoid an SMT
    # solver dependency when running the upstream LSU test in Verilator.
    text = path.read_text()
    if name == "memory":
        # Verilator is two-state: out-of-range reads cannot be tested with X.
        # Check the same array dimensions with SystemVerilog introspection.
        text = text.replace("    DUT.ram[DATA_MEM_SIZE_WORDS] = '0;", "")
        text = text.replace("DUT.ram[DATA_MEM_SIZE_WORDS] === 'x", "$size(DUT.ram) == DATA_MEM_SIZE_WORDS")
        text = text.replace("DUT.ram[0][32] === 'x", "$bits(DUT.ram[0]) == 32")
    elif name == "csr":
        # The original starts with an interactive pause at time zero.
        text = text.replace("  $stop();", "  // Initial interactive pause omitted for batch testing.", 1)
        # Use the enclosing property's identical clock instead of an explicit
        # clock argument, which Verilator does not parse here.
        text = text.replace("$changed(addr_i, @(posedge clk_i))", "$changed(addr_i)")
    elif name == "irq":
        # Drive inputs after the active edge rather than racing the DUT.
        text = re.sub(r"@\(posedge clk_i\);?", "@(posedge clk_i); #1;", text)
    elif name == "lsu":
        text = text.replace(
            "assert(std::randomize(core_size_i) with {core_size_i inside {LDST_B,LDST_H,LDST_W};});",
            "case ($urandom_range(0, 2)) 0: core_size_i=LDST_B; 1: core_size_i=LDST_H; 2: core_size_i=LDST_W; endcase")
        text = text.replace(
            "assert(std::randomize(core_size_i) with {core_size_i inside {LDST_B,LDST_H,LDST_W,LDST_BU,LDST_HU};});",
            "case ($urandom_range(0, 4)) 0: core_size_i=LDST_B; 1: core_size_i=LDST_H; 2: core_size_i=LDST_W; 3: core_size_i=LDST_BU; 4: core_size_i=LDST_HU; endcase")
        if "std::randomize" in text:
            raise RuntimeError("LSU testbench adaptation did not match")
    elif name == "lab07":
        text = text.replace("module lab_07_tb_processor_system();",
                            "module lab_07_tb_processor_system();\n  defparam DUT.ENABLE_TRAPS = 1'b0;")
    else:
        return path
    adapted = BUILD / (name + "_verilator.sv")
    adapted.write_text(text)
    return adapted


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--test", choices=TESTS, action="append")
    parser.add_argument("--waves", action="store_true")
    args = parser.parse_args()
    verilator = shutil.which("verilator")
    if not verilator and Path("/opt/homebrew/bin/verilator").is_file():
        verilator = "/opt/homebrew/bin/verilator"
    if not verilator:
        parser.error("Verilator is required. For Vivado use scripts/run_vivado.tcl.")
    BUILD.mkdir(exist_ok=True)
    prepare_images()
    sources = [str(ROOT / line.strip()) for line in (ROOT / "sources.f").read_text().splitlines() if line.strip()]
    results = []
    for name in args.test or TESTS:
        top, path = TESTS[name]
        path = bench_for_verilator(name, path)
        model = BUILD / name
        log = BUILD / (name + ".log")
        command = [verilator, "--binary", "--timing", "--assert", "--trace", "-j", "2",
                   "-Wno-fatal", "-Wno-TIMESCALEMOD", "--top-module", top,
                   "--Mdir", str(model), *sources, str(path)]
        with log.open("w") as output:
            result = subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT)
            if result.returncode == 0:
                cwd = BUILD / (name + "_run")
                cwd.mkdir(exist_ok=True)
                for folder in (ROOT / "programs", ROOT / "tests/programs"):
                    for image in folder.glob("*.mem"):
                        shutil.copy2(image, cwd / image.name)
                selected = name if name in ("lab07", "lab11", "individual") else "lab11"
                shutil.copy2(ROOT / "programs" / (selected + ".mem"), cwd / "program.mem")
                command = [str(model / ("V" + top))]
                if args.waves and name == "integration":
                    command.append("+waves")
                result = subprocess.run(command, cwd=cwd, stdout=output, stderr=subprocess.STDOUT)
        text = log.read_text()
        counts = [int(n) for n in re.findall(r"Number of errors:\s*(\d+)", text)]
        failed = result.returncode != 0 or any(counts) or bool(re.search(r"%Error|\$fatal|Assertion failed", text))
        if name == "integration" and "PASS tb_lab6:" not in text:
            failed = True
        if failed:
            print("FAIL " + name + "\n" + "\n".join(text.splitlines()[-60:]), flush=True)
            return 1
        detail = re.search(r"PASS tb_lab6: \d+ checks", text)
        summary = "PASS " + name + ((": " + detail.group()) if detail else "")
        print(summary, flush=True)
        results.append(summary)
    (BUILD / "test_results.txt").write_text("\n".join(results) + "\n")
    print(f"All {len(results)} testbenches passed. Logs: {BUILD}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
