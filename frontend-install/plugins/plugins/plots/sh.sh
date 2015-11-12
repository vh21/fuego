#!/bin/bash

jo=(Benchmark.bandwidth Benchmark.blobsallad Benchmark.bonnie Benchmark.CustomerScreens Benchmark.Dhrystone Benchmark.fio Benchmark.ftest-gdi Benchmark.GLMark Benchmark.gtkperf Benchmark.himeno Benchmark.Interbench Benchmark.IOzone Benchmark.iperf Benchmark.Java Benchmark.linpack Benchmark.lmbench2 Benchmark.LTP.Filesystem Benchmark.netperf Benchmark.nve Benchmark.OpenSSL Benchmark.Stream Benchmark.tiobench Benchmark.unixbench Benchmark.Whetstone Benchmark.xscreensavers)               


for i in ${jo[*]}
do
	mkdir -p ${i}
	mkdir -p ${i}/586-atom
	mkdir -p ${i}/arm-omap3
	
	touch ${i}/586-atom/plot.png
	touch ${i}/arm-omap3/plot.png
	
done
