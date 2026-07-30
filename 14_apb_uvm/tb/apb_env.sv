// ============================================================
// APB Agent / Environment / Test
// ============================================================

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_driver    drv;
    apb_monitor   mon;
    uvm_sequencer #(apb_txn) sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = apb_driver::type_id::create("drv", this);
        mon = apb_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(apb_txn)::type_id::create("sqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass


class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)

    apb_agent      agt;
    apb_scoreboard sb;
    apb_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = apb_agent::type_id::create("agt", this);
        sb  = apb_scoreboard::type_id::create("sb", this);
        cov = apb_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agt.mon.ap.connect(sb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass


class apb_test extends uvm_test;
    `uvm_component_utils(apb_test)

    apb_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        apb_directed_seq dseq;
        apb_random_seq   rseq;

        phase.raise_objection(this);

        dseq = apb_directed_seq::type_id::create("dseq");
        dseq.start(env.agt.sqr);

        rseq = apb_random_seq::type_id::create("rseq");
        rseq.num_txns = 150;
        rseq.start(env.agt.sqr);

        phase.drop_objection(this);
    endtask
endclass
