#include <logging.h>
#include <stdlib.h>  
#include <stdio.h>  
#include <unistd.h>
#include <string.h>  
#include <fcntl.h>
#include <time.h>

#define SYSFS_SOUND     "/sys/devices/ocp.3/helper.12/AIN0"
#define SYSFS_PRESSURE  "/sys/devices/ocp.3/helper.12/AIN1"
#define HZ		100
#define DELAY_US	(1000000 / HZ)

/*
 * Local function
 */

int difftime_us(struct timespec *tb, struct timespec *te)
{
	int us;

	/* Sanity checks */
	if (tb->tv_sec > te->tv_sec)
		return -1;

	us = (te->tv_sec - tb->tv_sec) * 1000000;
	us += ((te->tv_nsec - tb->tv_nsec) / 1000);

	return us;
}

/*
 * Main
 */
 
int main()  
{  
	int fd;  
	char ch[5];  
	int val;
	int delay_us;  
	struct timespec t0, t;
	int ret;

	/* Start sampling the ADC */
	while (1) {  
		ret = clock_gettime(CLOCK_MONOTONIC_RAW, &t0);
		EXIT_ON(ret < 0);

		/* Read the ADC */
		fd = open(SYSFS_PRESSURE, O_RDONLY);  
		EXIT_ON(fd < 0);
		ret = read(fd, ch, 5);  
		EXIT_ON(ret < 1);
        	close(fd);  
		ret = sscanf(ch, "%d", &val);  
		EXIT_ON(ret != 1);

		printf("%ld.%06ld %d\n", t0.tv_sec, t0.tv_nsec / 1000, val);

		/* Calculate the delay to sleep to the next period */
		ret = clock_gettime(CLOCK_MONOTONIC_RAW, &t);
		EXIT_ON(ret < 0);
		delay_us = DELAY_US - difftime_us(&t0, &t);
		EXIT_ON(delay_us < 0);
        	usleep(delay_us);
	}  

	return 0;
}
