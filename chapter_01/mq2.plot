set terminal png size 800,600 enhanced font "Helvetica,20"
set output 'mq2.png'
set xdata time
set timefmt "%H:%M:%S"
set autoscale
set nokey
set grid lw 1
show grid
set xlabel "\nTime"
set ylabel 'ppm'
set format x "%H:%M:%S"
set xtics rotate
plot "mq2.log" using 1:2 with lines
