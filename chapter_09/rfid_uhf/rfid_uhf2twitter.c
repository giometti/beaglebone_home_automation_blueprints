#include "../../lib/logging.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

#include <caenrfid.h>

int debug = 0;

char *t_cmd = "t";
char *t_arg = "update";

/* The known IDs */
struct associative_array_s {
        char *id;
        char *name;
} ID2NAME[] = {
        { "111111111111111111111111", "user1" },
        { "222222222222222222222222", "user2" },
        { "e280113020002021dda500ab", "Rodolfo Giometti" },
};

static char nibble2hex(char c)
{
        switch (c) {
        case 0 ... 9:
                return '0' + c;

        case 0xa ... 0xf:
                return 'a' + (c - 10);
        }

        printf("got invalid data!");
        return '\0';
}

/*
 * Local functions
 */

char *bin2hex(uint8_t *data, size_t len)
{
        char *str;
        int i;

        str = malloc(len * 2 + 1);
        if (!str)
                return NULL;

        for (i = 0; i < len; i++) {
                str[i * 2] = nibble2hex(data[i] >> 4);
                str[i * 2 + 1] = nibble2hex(data[i] & 0x0f);
        }
        str[i * 2] = '\0';

        return str;
}

/*
 * Usage function
 */

void usage(void)
{
        fprintf(stderr, "usage: %s <port>\n", NAME);

        exit(-1);
}

/*
 * Main
 */

int main(int argc, char *argv[])
{
	int i, j;
	struct caenrfid_handle handle;
        char string[] = "Source_0";
	struct caenrfid_tag *tag;
        size_t size;
        char *str, *cmd;
        int ret;

	if (argc < 2)
		usage();

        /* Start a new connection with the CAENRFIDD server */
        ret = caenrfid_open(CAENRFID_PORT_RS232, argv[1], &handle);
        if (ret < 0)
		usage();

        /* Set session "S2" for logical source 0 */
        ret = caenrfid_set_srcconf(&handle, "Source_0",
                                CAENRFID_SRC_CFG_G2_SESSION, 2);
        if (ret < 0) {
                err("cannot set session 2 (err=%d)", ret);
                exit(EXIT_FAILURE);
        }

	while (1) {
		/* Do the inventory */
	        ret = caenrfid_inventory(&handle, string, &tag, &size);
	        if (ret < 0) {
	                err("cannot get data (err=%d)", ret);
	                exit(EXIT_FAILURE);
	        }
	
		/* Report results */
	        for (i = 0; i < size; i++) {
	                str = bin2hex(tag[i].id, tag[i].len);
			EXIT_ON(!str);
	                info("got tag ID %.*s", tag[i].len * 2, str);
	
	                for (j = 0; j < ARRAY_SIZE(ID2NAME); j++)
	                        if (strncmp(str, ID2NAME[j].id,
						tag[i].len * 2) == 0)
	                                break;
	                if (j < ARRAY_SIZE(ID2NAME)) {
	                        info("Twitting that %s was arrived!",
						ID2NAME[j].name);
	                        ret = asprintf(&cmd, "%s %s \"%s was arrived!\"",
						t_cmd, t_arg, ID2NAME[j].name);
				EXIT_ON(ret < 1);
				ret = system(cmd);
				EXIT_ON(ret < 0);
	                        free(cmd);
	                } else
	                        info("unknow tag ID! Ignored");
	
	                free(str);
	        }
	
		/* Free inventory data */
		free(tag);
	}

	caenrfid_close(&handle);

	return 0;
}
