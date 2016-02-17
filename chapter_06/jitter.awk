BEGIN {
	sum = 0
	n = 0
	min = 1
	max = 0
	prev = 0
}
{
	# Compute the jitter
	d = $1 - prev - T
	prev = $1

	# Skip the first value
	if (n++ == 0) {
		next
	}

	# Do some statistics
	sum += d
	min = min < d ? min : d
	max = max > d ? max : d

	# Do we finished?
	if (n == N)
		exit(0)
}

END {
	printf("avg=%0.6f min=%0.6f max=%0.6f\n",
		sum / n, min, max)
}
