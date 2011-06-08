#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* The count_down variable. */
#ifdef USE_ITHREADS
SV *count_down;
#define COUNT_DOWN()      SvIV    (count_down                     )
#define COUNT_DOWN_dec()  SvIV_set(count_down, SvIV(count_down) - 1)
#define COUNT_DOWN_set(i) SvIV_set(count_down, i                   )
#else
IV count_down;
#define COUNT_DOWN()         count_down
#define COUNT_DOWN_dec()  (--count_down    )
#define COUNT_DOWN_set(i) (  count_down = i)
#endif

/* The inside_logger variable */
#ifdef USE_ITHREADS
SV *inside_logger;
#define INSIDE_LOGGER()     SvTRUE  (inside_logger  )
#define INSIDE_LOGGER_on()  SvIV_set(inside_logger, 1)
#define INSIDE_LOGGER_off() SvIV_set(inside_logger, 0)
#else
IV inside_logger;
#define INSIDE_LOGGER()     inside_logger
#define INSIDE_LOGGER_on()  (inside_logger = 1)
#define INSIDE_LOGGER_off() (inside_logger = 0)
#endif

/* The log_size variable */
#ifdef USE_ITHREADS
SV *log_size;
#define LOG_SIZE_inc()   SvIV_set(log_size, SvIV(log_size) + 1)
#define LOG_SIZE_reset() SvIV_set(log_size, 0                 )
#define LOG_SIZE()       SvIV    (log_size)
#else
IV log_size;
#define LOG_SIZE_inc()   (++log_size    )
#define LOG_SIZE_reset() (  log_size = 0)
#define LOG_SIZE()       (  log_size    )
#endif

void
take_snapshot(pTHX)
{
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    call_pv("Devel::ContinuousProfiler::take_snapshot",G_DISCARD|G_NOARGS);

    FREETMPS;
    LEAVE;
}

int
sp_runops(pTHX)
{
    dVAR;
    register OP *op = PL_op;
    while ((PL_op = op = CALL_FPTR(op->op_ppaddr)(aTHX))) {
        if ( COUNT_DOWN() ) {
            COUNT_DOWN_dec();
        }
        else {
            if ( INSIDE_LOGGER() ) {
                LOG_SIZE_inc();
            }
            else {
                INSIDE_LOGGER_on();
                LOG_SIZE_reset();
                take_snapshot(aTHX);
                COUNT_DOWN_set( LOG_SIZE() << 10 );
                INSIDE_LOGGER_off();
            }
        }
    }

    TAINT_NOT;
    return 0;
}

void
_initialize()
{
#ifdef USE_ITHREADS
    count_down = get_sv("Devel::ContinuousProfiler::count_down",GV_ADD);
#endif
    COUNT_DOWN_set(0);

#ifdef USE_ITHREADS
    inside_logger = get_sv("Devel::ContinuousProfiler::is_inside_logger",GV_ADD);
#endif
    INSIDE_LOGGER_off();

#ifdef USE_ITHREADS
    log_size = get_sv("Devel::ContinuousProfiler::log_size",GV_ADD);
#endif
    LOG_SIZE_reset();

    PL_runops = sp_runops;
}

MODULE = Devel::ContinuousProfiler PACKAGE = Devel::ContinuousProfiler

void
_initialize()

IV
count_down()
    CODE:
        RETVAL = COUNT_DOWN();
    OUTPUT:
        RETVAL

IV
is_inside_logger()
    CODE:
        RETVAL = INSIDE_LOGGER();
    OUTPUT:
        RETVAL

IV
log_size()
    CODE:
        RETVAL = LOG_SIZE();
    OUTPUT:
        RETVAL

BOOT:
    _initialize();
