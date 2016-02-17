#ifndef _LOGGING_H
#define _LOGGING_H

#define _GNU_SOURCE
#include <errno.h>
#ifdef USE_SYSLOG
#  include <syslog.h>
#  define __log_func	syslog
#  define __log_debug	LOG_DEBUG
#  define __log_info	LOG_INFO
#  define __log_err	LOG_ERR
#else /* !USE_SYSLOG */
#  include <stdio.h>
#  define __log_func	fprintf
#  define __log_debug	stderr
#  define __log_info	stderr
#  define __log_err	stderr
#endif /* USE_SYSLOG */

#define NAME			program_invocation_short_name

extern int debug;

#ifndef DISABLE_DEBUG
#define __message(par1, fmt, args...)					\
		__log_func(par1, "%s[%4d]: " fmt "\n" ,			\
			__FILE__, __LINE__ , ## args)

#define __dbg(fmt, args...)						\
	do {								\
		if (unlikely(debug))					\
			__message(__log_debug, fmt , ## args);		\
	} while (0)

#define DUMP(code)							\
	do {								\
		if (unlikely(debug)) do {				\
			code						\
		} while (0);						\
	} while (0)

#else  /* !DISABLE_DEBUG */

#define __message(par1, fmt, args...)					\
		__log_func(par1, fmt "\n" , ## args)

#define __dbg(fmt, args...)						\
				/* do nothing! */

#define DUMP(code)							\
				/* do nothing! */
#endif /* DISABLE_DEBUG */

#define __info(fmt, args...)						\
		__message(__log_info, fmt , ## args)

#define __err(fmt, args...)						\
		__message(__log_err, fmt , ## args)

/*
 * Exported defines
 *
 * The following defines should be preferred to the above one into
 * normal code.
 */

#ifndef DISABLE_DEBUG
#define info(fmt, args...)						\
		__info("%s: " fmt , __func__ , ## args)
#define err(fmt, args...)						\
		__err("%s: " fmt , __func__ , ## args)
#define dbg(fmt, args...)						\
		__dbg("%s: " fmt , __func__ , ## args)

#else  /* DISABLE_DEBUG */

#define info(args...)		__info(args)
#define err(args...)		__err(args)
#define dbg(args...)		__dbg(args)

#endif /* !DISABLE_DEBUG */

#define min(x, y) ({                                    \
                typeof(x) _min1 = (x);                  \
                typeof(y) _min2 = (y);                  \
                (void) (&_min1 == &_min2);              \
                _min1 < _min2 ? _min1 : _min2; })

#define max(x, y) ({                                    \
                typeof(x) _max1 = (x);                  \
                typeof(y) _max2 = (y);                  \
                (void) (&_max1 == &_max2);              \
                _max1 > _max2 ? _max1 : _max2; })

#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)
#define container_of(ptr, type, member)                                 \
        ({                                                              \
                const typeof( ((type *)0)->member ) *__mptr = (ptr);    \
                (type *)( (char *)__mptr - offsetof(type,member) );     \
        })

#define BUILD_BUG_ON_ZERO(e)                                            \
                (sizeof(char[1 - 2 * !!(e)]) - 1)
#define __must_be_array(a)                                              \
                BUILD_BUG_ON_ZERO(__builtin_types_compatible_p(typeof(a), \
                                                        typeof(&a[0])))
#define ARRAY_SIZE(arr)							\
		(sizeof(arr) / sizeof((arr)[0]) + __must_be_array(arr))

#define unlikely(x)	     __builtin_expect(!!(x), 0)
#define BUG()								\
	do {								\
		err("fatal error in %s() at line %d",			\
			__func__, __LINE__);				\
		exit(EXIT_FAILURE);					\
	} while (0)
#define EXIT_ON(condition)						\
	do {								\
		if (unlikely(condition))				\
			BUG();						\
	} while(0)
#define BUG_ON(condition)       EXIT_ON(condition)

#endif /* _LOGGING_H */
