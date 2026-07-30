// ============================================================
// ALU Agent / Environment / Test
// ============================================================

class alu_agent extends uvm_agent;
    `uvm_component_utils(alu_agent)

    alu_driver    drv;
    alu_monitor   mon;
    uvm_sequencer #(alu_txn) sqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = alu_driver::type_id::create("drv", this);
        mon = alu_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(alu_txn)::type_id::create("sqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass


class alu_env extends uvm_env;
    `uvm_component_utils(alu_env)

    alu_agent      agt;
    alu_scoreboard sb;
    alu_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = alu_agent::type_id::create("agt", this);
        sb  = alu_scoreboard::type_id::create("sb", this);
        cov = alu_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agt.mon.ap.connect(sb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass


class alu_test extends uvm_test;
    `uvm_component_utils(alu_test)

    alu_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = alu_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        alu_directed_seq dseq;
        alu_random_seq   rseq;

        phase.raise_objection(this);

        dseq = alu_directed_seq::type_id::create("dseq");
        dseq.start(env.agt.sqr);

        rseq = alu_random_seq::type_id::create("rseq");
        rseq.num_txns = 200;
        rseq.start(env.agt.sqr);

        phase.drop_objection(this);
    endtask
endclass
