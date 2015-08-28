#!/usr/bin/env python

import time

sess_name = "exp_sess"
trace_dest = "/tmp/%s" % (sess_name)

if __name__=="__main__":
    import lttng

    dom = lttng.Domain()
    dom.type = lttng.DOMAIN_KERNEL

    channel = lttng.Channel()
    channel.name = "exp_chan"
    channel.attr.overwrite = 0
    channel.attr.subbuf_size = 4096
    channel.attr.num_subbuf = 8
    channel.attr.switch_timer_interval = 0
    channel.attr.read_timer_interval = 200
    channel.attr.output = lttng.EVENT_SPLICE

    event = lttng.Event()
    event.name = "sched_switch"
    event.type = lttng.EVENT_TRACEPOINT
    event.loglevel_type = lttng.EVENT_LOGLEVEL_ALL


    ret = lttng.create(sess_name, trace_dest)
    assert(ret == 0)

    han = None
    han = lttng.Handle(sess_name, dom)
    assert(han != None)

    lttng.enable_channel(han, channel)
    lttng.enable_event(han, event, channel.name)

    print(lttng.list_channels(han))

    lttng.start(sess_name)
    time.sleep(0.1)
    lttng.stop(sess_name)

    ret = lttng.destroy(sess_name)
    assert(ret == 0)
