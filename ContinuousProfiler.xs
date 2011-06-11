#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef USE_ITHREADS
int count_down;
int inside_logger;
int log_size;
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
#ifdef USE_ITHREADS
    SV * count_down_sv, *inside_logger_sv, *log_size_sv;
    IV count_down;

    register OP *op = PL_op;
    while ((PL_op = op = CALL_FPTR(op->op_ppaddr)(aTHX))) {
        count_down_sv = get_sv("Devel::ContinuousProfiler::count_down", GV_ADD);
        count_down = SvIV(count_down);
        if ( count_down > 0 ) {
            sv_dec(count_down_sv);
        }
        else {
            inside_logger_sv = get_sv("Devel::ContinuousProfiler::inside_logger", GV_ADD);
            log_size_sv = get_sv("Devel::ContinuousProfiler::log_size", GV_ADD);
            if ( SvIV(inside_logger_sv) ) {
                sv_inc(log_size_sv);
            }
            else {
                SvIV_set(inside_logger_sv, 1);
                SvIV_set(log_size_sv, 0);
                take_snapshot(aTHX);
                SvIV_set(count_down_sv, SvIV(log_size_sv) << 10);
                SvIV_set(inside_logger_sv, 0);
            }
        }
    }
#else
    register OP *op = PL_op;
    while ((PL_op = op = CALL_FPTR(op->op_ppaddr)(aTHX))) {
        if ( count_down > 0 ) {
            -- count_down;
        }
        else {
            if ( inside_logger ) {
                ++ log_size;
            }
            else {
                inside_logger = 1;
                log_size = 0;
                take_snapshot(aTHX);
                count_down = log_size << 10;
                inside_logger = 0;
            }
        }
    }
#endif

    TAINT_NOT;
    return 0;
}

void
_initialize()
{
    get_sv("Devel::ContinuousProfiler::count_down", GV_ADD);
    get_sv("Devel::ContinuousProfiler::inside_logger", GV_ADD);
    get_sv("Devel::ContinuousProfiler::log_size", GV_ADD);
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
