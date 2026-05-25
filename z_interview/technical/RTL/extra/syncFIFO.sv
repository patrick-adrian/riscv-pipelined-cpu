//==============================================================================
// Synchronous FIFO  —  single-clock-domain First-In-First-Out queue
//------------------------------------------------------------------------------
// A FIFO buffers data between a producer and a consumer that operate at
// different RATES (but the SAME clock — that's what makes this "sync";
// async FIFOs cross clock domains and use Gray pointers + synchronizers).
//
// INTERFACE
//   write side:  wr_en  asserted by producer; if !full, data is enqueued
//   read  side:  rd_en  asserted by consumer; if !empty, data appears next cycle
//
// THE FUNDAMENTAL TRICK: pointer widths
//
//   The internal RAM has DEPTH = 2^ADDR_W entries. The read and write
//   POINTERS are each (ADDR_W + 1) bits — ONE EXTRA bit. Why?
//
//     - The low ADDR_W bits index the RAM (`mem[wr_ptr[ADDR_W-1:0]]`).
//     - The TOP bit acts as a "wrap" or "epoch" marker.
//
//   This lets us distinguish full from empty without separate flags:
//       empty  : wr_ptr  ==  rd_ptr              (same epoch, same index)
//       full   : wr_ptr  ==  {~rd_ptr[MSB], rd_ptr[MSB-1:0]}
//                                                (same index, DIFFERENT epoch)
//
//   Without the extra bit, `wr_ptr == rd_ptr` would be ambiguous: it could
//   mean either "all caught up" (empty) or "wrote 2^ADDR_W times more"
//   (full). The extra bit resolves the ambiguity for free. This is the
//   most-asked FIFO interview question.
//
// INTERVIEW TALKING POINTS
//  - "Why power-of-2 depth?" — natural wraparound of the pointer width with
//    no compare-and-reset logic. You CAN build non-power-of-2 FIFOs, but
//    you pay an extra comparator. Most designs use powers of two.
//  - "First-Word-Fall-Through (FWFT) vs standard FIFO?" — FWFT shows the
//    head of queue on `rd_data` IMMEDIATELY (no read-enable needed to
//    pre-fetch); a standard FIFO requires `rd_en` and presents the data
//    next cycle. This implementation is FWFT-style: `rd_data` is always
//    the entry at `rd_ptr`, no extra latency.
//  - "What if both wr_en and rd_en fire on the same cycle when full?" —
//    most designs allow the simultaneous read+write to succeed (a "pass-
//    through" cycle: write data goes in, oldest data goes out). We allow
//    that here by checking the gated wr_en/rd_en independently.
//  - "almost_full / almost_empty"? — programmable thresholds for back-
//    pressure. Easy to add: `assign almost_full = (occupancy >= AF_THR);`
//==============================================================================

module sync_fifo #(
    parameter int DATA_W = 8,
    parameter int DEPTH  = 16,                              // must be power of 2
    parameter int ADDR_W = $clog2(DEPTH)
)(
    input  logic                clk,
    input  logic                rst_n,

    // Write port
    input  logic                wr_en,
    input  logic [DATA_W-1:0]   wr_data,
    output logic                full,

    // Read port (First-Word-Fall-Through)
    input  logic                rd_en,
    output logic [DATA_W-1:0]   rd_data,
    output logic                empty,

    // Status
    output logic [ADDR_W:0]     occupancy                   // 0 .. DEPTH
);

    // -----------------------------------------------------------------------
    // STORAGE
    // -----------------------------------------------------------------------
    // An unpacked array: `mem[i]` is a DATA_W-bit word. Synthesizes to a
    // small distributed register array; for large FIFOs the tool can
    // map this to block RAM if you also register the read address.
    logic [DATA_W-1:0] mem [DEPTH];

    // Pointers are ADDR_W+1 bits wide (the "extra bit" trick).
    logic [ADDR_W:0] wr_ptr, rd_ptr;

    // Convenience aliases for the low ADDR_W bits — used as RAM indices.
    wire [ADDR_W-1:0] wr_idx = wr_ptr[ADDR_W-1:0];
    wire [ADDR_W-1:0] rd_idx = rd_ptr[ADDR_W-1:0];

    // -----------------------------------------------------------------------
    // STATUS FLAGS (combinational from pointer comparison)
    // -----------------------------------------------------------------------
    assign empty = (wr_ptr == rd_ptr);

    // Full: same RAM index, DIFFERENT top (epoch) bit. Equivalent to
    // saying "writer has wrapped exactly once more than reader".
    assign full  = (wr_ptr[ADDR_W]      != rd_ptr[ADDR_W]) &&
                   (wr_ptr[ADDR_W-1:0]  == rd_ptr[ADDR_W-1:0]);

    // Occupancy: signed subtraction of the (ADDR_W+1)-bit pointers, which
    // naturally yields 0..DEPTH thanks to the extra bit. (Casts kept
    // explicit so the math is obvious to a reader.)
    assign occupancy = wr_ptr - rd_ptr;

    // -----------------------------------------------------------------------
    // WRITE LOGIC
    // -----------------------------------------------------------------------
    // Single always_ff so the producer's behavior is in one place.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            mem[wr_idx] <= wr_data;
            wr_ptr      <= wr_ptr + 1'b1;
        end
    end

    // -----------------------------------------------------------------------
    // READ LOGIC (FWFT)
    // -----------------------------------------------------------------------
    // `rd_data` always reflects the entry at `rd_ptr`. When the consumer
    // asserts `rd_en`, we just advance the pointer — the NEW head appears
    // on `rd_data` next cycle automatically.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= '0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    assign rd_data = mem[rd_idx];

    // -----------------------------------------------------------------------
    // SAFETY ASSERTIONS (sim only; the synthesizer ignores these)
    // -----------------------------------------------------------------------
    // synthesis translate_off
    no_overflow:  assert property (@(posedge clk) disable iff (!rst_n)
                                    !(wr_en && full && !rd_en))
                  else $error("FIFO overflow: wr_en while full");

    no_underflow: assert property (@(posedge clk) disable iff (!rst_n)
                                    !(rd_en && empty))
                  else $error("FIFO underflow: rd_en while empty");
    // synthesis translate_on

endmodule
