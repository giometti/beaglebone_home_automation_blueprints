#include <logging.h>
#include <getopt.h>
#include <stdlib.h>  
#include <stdio.h>  
#include <unistd.h>
#include <string.h>  
#include <fcntl.h>
#include <sched.h>
#include <time.h>

#define NAME            program_invocation_short_name
#define HZ		100
#define DELAY_US	(1000000 / HZ)
#define WINDOW_SIZE_S	5

#define SYSFS_SOUND	"/sys/devices/ocp.3/helper.12/AIN0"  
#define SYSFS_PRESSURE	"/sys/devices/ocp.3/helper.12/AIN1"  

int debug = 0;

/*
 * Local function
 */

int read_adc(char *file)
{
	int fd;
	char ch[5];  
	int val;
	int retries = 3;
	int ret;

retry:
	fd = open(file, O_RDONLY);  
	EXIT_ON(fd < 0);

	ret = read(fd, ch, 5);  
       	close(fd);  
	if (ret < 1) {
		EXIT_ON(retries-- == 0);
		goto retry;
	}

	ret = sscanf(ch, "%d", &val);  
	EXIT_ON(ret != 1);

	return val;
}

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
 * Usage function
 */

void usage(void)
{
        fprintf(stderr, "usage: %s [-h] [-d] [-l]\n", NAME);
        fprintf(stderr, "    -h    - show this message\n");
        fprintf(stderr, "    -d    - enable debugging messages\n");
        fprintf(stderr, "    -l    - log on stderr\n");

        exit(-1);
}

/*
 * Main
 */
  
int main(int argc, char *argv[])  
{  
        int c, option_index;
	int prs[WINDOW_SIZE_S * HZ];
	int prs_idx;
	int snd[WINDOW_SIZE_S * HZ];
	int snd_idx;
	struct sched_param param;
	int delay_us;  
	struct timespec t0, t;
	int prs_avg, prs_min, prs_max;
	int snd_avg;
	int ticks = 0;
	int ret;

        opterr = 0;       /* disbale default error message */
        while (1) {
                /* getopt_long stores the option index here */
                option_index = 0;

		c = getopt_long(argc, argv, "hd", NULL, &option_index);

                /* Detect the end of the options */
                if (c == -1)
                        break;

                switch (c) {
                case 0:
                        break;

                case 'h':
                        usage();

                case 'd':
                        debug = 1;
                        break;

                case '?':
                        fprintf(stderr, "unhandled option");
                        exit(-1);

                default:
                        exit(-1);
                }
        }

	/* Set stdout line buffered */
	setlinebuf(stdout);

	/* Do a dummy read to init the data buffers */
	c = read_adc(SYSFS_SOUND);
	for (snd_idx = 0; snd_idx < ARRAY_SIZE(snd); snd_idx++)
		snd[snd_idx] = c;
	c = read_adc(SYSFS_PRESSURE);
	for (prs_idx = 0; prs_idx < ARRAY_SIZE(prs); prs_idx++)
		prs[prs_idx] = c;

	/* Set FIFO scheduling */
	param.sched_priority = 99;
	ret = sched_setscheduler(getpid(), SCHED_FIFO, &param);
	EXIT_ON(ret < 0);

	/* Start sampling the ADC */
	snd_idx = prs_idx = 0;
	ret = clock_gettime(CLOCK_MONOTONIC_RAW, &t);
	EXIT_ON(ret < 0);
	while (1) {  
                ret = clock_gettime(CLOCK_MONOTONIC_RAW, &t0);
                EXIT_ON(ret < 0);

		/* Read the data from the ADCs */
		snd[snd_idx] = read_adc(SYSFS_SOUND);
		prs[prs_idx] = read_adc(SYSFS_PRESSURE);

		/* Extract informations from buffered data */
		extract(snd, ARRAY_SIZE(snd),
			&snd_avg, NULL, NULL);
		extract(prs, ARRAY_SIZE(prs),
			&prs_avg, &prs_min, &prs_max);
		dbg("%ld.%06ld prs:%d min=%d max=%d snd:%d",
			t0.tv_sec, t0.tv_nsec / 1000,
			prs[prs_idx], prs_min, prs_max, snd[snd_idx]);

		/* We have to output the pressure data each second,
		 * that is every HZ ticks.
		 * Also we have to read the sound level...
		 */
		if (ticks++ == 0)
			printf("%d %d %d\n",
				prs_avg, prs_max - prs_min, snd_avg);
		ticks %= HZ;

		/* Calculate the delay to sleep to the next period */
		ret = clock_gettime(CLOCK_MONOTONIC_RAW, &t);
		EXIT_ON(ret < 0);
		delay_us = DELAY_US - difftime_us(&t0, &t);
		EXIT_ON(delay_us < 0);
        	usleep(delay_us);

		/* Move the index */
		prs_idx++;
		prs_idx %= ARRAY_SIZE(prs);
		snd_idx++;
		snd_idx %= ARRAY_SIZE(snd);
	}  

	return 0;
}
