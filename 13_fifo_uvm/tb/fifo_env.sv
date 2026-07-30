// ============================================================
// FIFO Agent / Environment / Test
// ============================================================

class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)

    fifo_driver    drv;
    fifo_monitor   mon;
    uvm_sequencer #(fifo_txn) sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = fifo_driver::type_id::create("drv", this);
        mon = fifo_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(fifo_txn)::type_id::create("sqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass


class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)

    fifo_agent      agt;
    fifo_scoreboard sb;
    fifo_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = fifo_agent::type_id::create("agt", this);
        sb  = fifo_scoreboard::type_id::create("sb", this);
        cov = fifo_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agt.mon.ap.connect(sb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass


class fifo_test extends uvm_test;
    `uvm_component_utils(fifo_test)

    fifo_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_fill_seq   fseq;
        fifo_drain_seq  drseq;
        fifo_random_seq rseq;

        phase.raise_objection(this);

        fseq = fifo_fill_seq::type_id::create("fseq");
        fseq.start(env.agt.sqr);

        drseq = fifo_drain_seq::type_id::create("drseq");
        drseq.start(env.agt.sqr);

        rseq = fifo_random_seq::type_id::create("rseq");
        rseq.num_txns = 300;
        rseq.start(env.agt.sqr);

        phase.drop_objection(this);
    endtask
endclass
