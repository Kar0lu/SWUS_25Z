#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <sys/socket.h>

/* Ok, w sumie tej długości to używam tylko do raw_dec i raczej i tak się za bardzo nie przyda... a i może być max 4B, bo inaczej wyjdzie poza zakres */
#define USAGE "usage: simplifier <key_format (ip|class|raw_dec)> <length> <value>"

int main(int argc, char **argv) {
    uint32_t bytes;
    /* Tak, nie za każdym razem użyję tych wskaźników */
    char* separator;
    unsigned char *p;

    if (argc < 4) {
        printf(USAGE);
        return 1;
    }

    /* Tak, wiem, że jest nie ładnie, ale to do użycia w skryptach raczej lub przez kogoś, kto wie co robi */
    switch(argv[1][0]){
        case 'i':
            inet_pton(AF_INET, argv[3], &bytes);
            /* Tak, tutaj powinienem sprawdzić co zostało zwrócone... */
            for(int i = 3; i >= 0; i--)
                printf("%02X ", *(((uint8_t*)&bytes)+i));
            break;

        case 'c':
            bytes = strtoul(argv[3], &separator, 16) << 16 | strtoul(separator + 1, 0, 16);
            p = (void*)&bytes;
            printf("%02X %02X %02X %02X", p[0], p[1], p[2], p[3]);
            break;

        case 'r':
            bytes = strtoul(argv[3], 0, 10);
            /* Ok, bardziej ryzykownie chyba się nie da, ale trzeba uważać na argumenty */
            argv[2][0] = (uint8_t)atoi(argv[2]);
            p = (void*)&bytes;
            while(argv[2][0]--) printf("%02X%c", *p++, argv[2][0]?' ':'\0');
            break;

        default: printf("Unknown action: %s", argv[1]);
    }

    return 0;
}