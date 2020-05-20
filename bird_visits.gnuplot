set terminal pngcairo size 700,700 enhanced font 'Verdana,10'
set datafile separator '_'
#set ydata time
set xdata time
set timefmt "%H:%M:%S"
set xrange ['01:00:00':'23:00:00']
set yrange [0:8]
#set style fill  transparent solid 0.15 noborder
#set style fill  transparent solid
set output 'bird_visits.png'
clamp254(x) = x > 254 ? 254 : x
#myColor(x) = (clamp254((int((x+100)*1.5)))<<24) + ((0x00)<<16) + (0x44<<8) + 0x66
myColor(x) = 0xd0004466
mySize(x) = x*10

plot 'motions.txt' u 4:3:(mySize($5)):(myColor($5)) lc rgb variable w circles
#plot 'motions.txt' u 3:4:(mySize($5)):(0):(myColor($5)) w vectors nohead ls 1 lc rgb variable
#plot 'motions.txt' u 2:5:(mySize($5)):(myColor($5)) w points lt 1 pt 7 ps var lc rgb var

