#include <core.p4>
#include <ebpf_model.p4>

/************************************************************************
* Nagłówki
*************************************************************************/

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header l4_generic_t {
    bit<16> srcPort;
    bit<16> dstPort;
}

struct Headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
    l4_generic_t l4;
}

/************************************************************************
* Extern
*************************************************************************/

extern void set_tc_classid(bit<32> classid);

/************************************************************************
* Parser
*************************************************************************/

parser prs(packet_in p, out Headers headers)
{
    state start
    {
        p.extract(headers.ethernet);
        transition select(headers.ethernet.etherType)
        {
            16w0x800 : ip;
            default : accept;
        }
    }

    state ip
    {
        p.extract(headers.ipv4);
        transition select(headers.ipv4.protocol) {
            8w0x6: l4; // TCP
            8w0x11: l4; // UDP
            default: accept;
        }
    }

    state l4
    {
        p.extract(headers.l4);
        transition accept;
    }
}

/************************************************************************
* Filtr
*************************************************************************/

control pipe(inout Headers headers, out bool pass ) {

    /* Akcje */
    action set_class(bit<32> classid) {
        set_tc_classid(classid);
    }

    action drop() {
        pass = false;;
    }

    /* Tabela */
    table flow {
        key = {
            headers.ipv4.srcAddr : exact;
            headers.ipv4.dstAddr : exact;   // jak zadziała to będę eksperymentował z lpm

            headers.ipv4.protocol : exact;

            headers.l4.srcPort : exact;
            headers.l4.dstPort : exact;
        }
        actions = { set_class; NoAction; drop;}
        implementation = hash_table(256);
        default_action = NoAction;
    }

    apply {
        pass = true;

        if (headers.l4.isValid()) {
            flow.apply();
        }
    }
}

ebpfFilter(prs(), pipe()) main;