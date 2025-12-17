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

struct Headers {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

/************************************************************************
* Extern
*************************************************************************/

extern void set_tc_priority(bit<32> major, bit<32> minor);

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
        transition accept;
    }
}

/************************************************************************
* Filtr
*************************************************************************/

control pipe(inout Headers headers, out bool pass ) {

    /* Ustawianie klasy dla TC */
    action set_class(bit<32> major, bit<32> minor) {
        set_tc_priority(major, minor);
    }

    /* Tabela 1: Filtrowanie po Protokole (L4) */
    table tbl_protocol {
        key = { headers.ipv4.protocol : exact; }
        actions = { set_class; NoAction; }
        implementation = hash_table(256);
        default_action = NoAction;
    }

    /* Tabela 2: Filtrowanie po IP Źródłowym */
    table tbl_src_ip {
        key = { headers.ipv4.srcAddr : exact; }
        actions = { set_class; NoAction; }
        implementation = hash_table(256);
        default_action = NoAction;
    }

    /* Tabela 3: Filtrowanie po IP Docelowym */
    table tbl_dst_ip {
        key = { headers.ipv4.dstAddr : exact; }
        actions = { set_class; NoAction; }
        implementation = hash_table(256);
        default_action = NoAction;
    }

    apply {
        pass = true;
        set_tc_priority(1, 30);

        if (headers.ipv4.isValid()) {
            tbl_protocol.apply();
            tbl_src_ip.apply();
            tbl_dst_ip.apply();
        }
    }
}

ebpfFilter(prs(), pipe()) main;