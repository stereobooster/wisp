# create data with r7rs-benchmark: cp ~/eigenes/Programme/r7rs-benchmarks/all.csv r7rs-benchmark-all.csv; for i in 1.8.8 2.0.14 2.2 2.9; do ./evaluate-r7rs-benchmark.w r7rs-benchmark-all.csv guile-$i --csv > /tmp/r7rs-bench-slowdown-guile-$i.csv; done; gnuplot -c evaluate-r7rs-benchmark.gnuplot
set title "Slowdown vs. fastest, progression in Guile, using https://ecraven.github.io/r7rs-benchmarks/"
set xtics rotate 45
set log y
set yrange [0.9:50]
set ylabel "Slowdown vs. fastest / dimensionless"
set xlabel "specific test"
set terminal png size 1024,768 linewidth 2
set output "evaluate-r7rs-benchmark.png"
plot "/tmp/r7rs-bench-slowdown-guile-1.8.8.csv" u 0:($2):xtic(1) w linespoints title "1.8", "/tmp/r7rs-bench-slowdown-guile-2.0.14.csv" u 0:($2):xtic(1) w linespoints title "2.0", "/tmp/r7rs-bench-slowdown-guile-2.2.csv" u 0:($2):xtic(1) w linespoints title "2.2", "/tmp/r7rs-bench-slowdown-guile-2.9.csv" u 0:($2):xtic(1) w linespoints  title "2.9"
