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
#define WINDOW_SIZE_S   5

/*
 * Local function
 */

void extract(int arr[], size_t n, int *avg, int *min, int *max)
{
        int i;
        float sum = 0;

        if (min)
                *min = 4096;
        if (max)
                *max = 0;
        for (i = 0; i < n; i++) {
                sum += ((float) arr[i]) / ((float) n);
                if (min)
                        *min = min(*min, arr[i]);
                if (max)
                        *max = max(*max, arr[i]);
        }

        *avg = (int) sum;
}

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
        int val[WINDOW_SIZE_S * HZ];
        int idx;
	int delay_us;  
	struct timespec t0, t;
	int val_avg, val_min, val_max;
	int ret;

        /* Init the data buffers */
        for (idx = 0; idx < ARRAY_SIZE(val); idx++)
                val[idx] = 0;

	/* Start sampling the ADC */
	idx = 0;
	while (1) {  
		ret = clock_gettime(CLOCK_MONOTONIC_RAW, &t0);
		EXIT_ON(ret < 0);

		/* Read the ADC */
		fd = open(SYSFS_PRESSURE, O_RDONLY);  
		EXIT_ON(fd < 0);
		ret = read(fd, ch, 5);  
		EXIT_ON(ret < 1);
        	close(fd);  
		ret = sscanf(ch, "%d", &val[idx]);  
		EXIT_ON(ret != 1);

                /* Extract informations from buffered data */
                extract(val, ARRAY_SIZE(val), &val_avg, &val_min, &val_max);

		printf("%ld.%06ld %d %d %d %d\n",
			t0.tv_sec, t0.tv_nsec / 1000, val[idx],
			val_avg, val_min, val_max);

		/* Calculate the delay to sleep to the next period */
		ret = clock_gettime(CLOCK_MONOTONIC_RAW, &t);
		EXIT_ON(ret < 0);
		delay_us = DELAY_US - difftime_us(&t0, &t);
		EXIT_ON(delay_us < 0);
        	usleep(delay_us);

                /* Move the index */
                idx++;
                idx %= ARRAY_SIZE(val);
	}  

	return 0;
}
