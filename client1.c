/* client1.c — version fichiers temporaires
   Usage Joueur A : echo "3" | ./client1 127.0.0.1 PORT
   Usage Joueur B : ./client1 IP PORT fichier_question fichier_reponse
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define MAX_BUF 2048

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s IP PORT [fich_question fich_reponse]\n", argv[0]);
        return 1;
    }

    char *ip_serveur   = argv[1];
    int   port         = atoi(argv[2]);
    char *fich_qst     = (argc >= 5) ? argv[3] : NULL;
    char *fich_rep     = (argc >= 5) ? argv[4] : NULL;

    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) { perror("socket"); return 1; }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(port);
    inet_pton(AF_INET, ip_serveur, &addr.sin_addr);

    if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("connect"); close(sock); return 1;
    }

    /* Recevoir la question */
    char buf[MAX_BUF];
    memset(buf, 0, sizeof(buf));
    int total = 0;
    while (total < (int)(sizeof(buf)-1)) {
        int n = recv(sock, buf+total, sizeof(buf)-1-total, 0);
        if (n <= 0) break;
        total += n; buf[total] = '\0';
        if (strstr(buf, "QUESTION_FIN\n")) break;
    }

    /* Extraire le contenu */
    char contenu[MAX_BUF];
    memset(contenu, 0, sizeof(contenu));
    char *debut = strstr(buf, "QUESTION_DEBUT\n");
    char *fin   = strstr(buf, "QUESTION_FIN\n");
    if (debut && fin) {
        debut += strlen("QUESTION_DEBUT\n");
        int len = (int)(fin - debut);
        if (len > 0) strncpy(contenu, debut, len < (int)sizeof(contenu)-1 ? len : (int)sizeof(contenu)-1);
    } else {
        strncpy(contenu, buf, sizeof(contenu)-1);
    }

    /* Écrire/afficher la question */
    if (fich_qst) {
        FILE *f = fopen(fich_qst, "w");
        if (f) { fprintf(f, "QUESTION_PRETE\n%s", contenu); fflush(f); fclose(f); }
    } else {
        printf("QUESTION_PRETE\n%s", contenu); fflush(stdout);
    }

    /* Lire la réponse */
    char reponse[8];
    memset(reponse, 0, sizeof(reponse));

    if (fich_rep) {
        /* Attendre que le bash écrive la réponse dans le fichier (polling) */
        FILE *f = NULL;
        int attente = 0;
        while (attente < 600) {  /* 60 secondes max */
            f = fopen(fich_rep, "r");
            if (f) {
                if (fgets(reponse, sizeof(reponse), f)) { fclose(f); break; }
                fclose(f);
            }
            usleep(100000); /* 0.1s */
            attente++;
        }
        reponse[strcspn(reponse, "\n")] = 0;
    } else {
        if (fgets(reponse, sizeof(reponse), stdin) == NULL) strcpy(reponse, "0");
        reponse[strcspn(reponse, "\n")] = 0;
    }

    /* Envoyer la réponse */
    char msg[32];
    snprintf(msg, sizeof(msg), "%s\n", reponse);
    send(sock, msg, strlen(msg), 0);

    /* Recevoir le résultat */
    memset(buf, 0, sizeof(buf));
    int n = recv(sock, buf, sizeof(buf)-1, 0);
    if (n > 0) {
        buf[n] = '\0';
        if (fich_qst) {
            FILE *f = fopen(fich_qst, "a");
            if (f) { fprintf(f, "%s", buf); fflush(f); fclose(f); }
        } else {
            printf("%s", buf); fflush(stdout);
        }
    }

    close(sock);
    return 0;
}
