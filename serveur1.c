/* serveur1.c
   Compile : gcc -o serveur1 serveur1.c
   Usage   : ./serveur1 PORT BONNE_REPONSE QUESTION_LIGNE
   
   Logique :
     1. Accepte 2 connexions : A et B par ordre d'arrivée
     2. Envoie la question formatée aux deux joueurs
     3. Attend les réponses des deux joueurs
     4. Calcule le vainqueur (bonne réponse + rapidité)
     5. Envoie le résultat aux deux joueurs
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <time.h>

#define MAX_BUF 1024

typedef struct {
    char reponse[8];
    long long timestamp;
    int a_repondu;
    int fd;
} ReponseJoueur;

long long get_timestamp() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (long long)tv.tv_sec * 1000000 + tv.tv_usec;
}

/* Parse la ligne CSV et construit le message question à envoyer */
void formater_question(const char *ligne, char *out, int out_size) {
    char tmp[MAX_BUF];
    strncpy(tmp, ligne, sizeof(tmp)-1);
    tmp[sizeof(tmp)-1] = '\0';
    
    /* Supprimer le \n final */
    tmp[strcspn(tmp, "\n")] = 0;
    
    char *question = strtok(tmp, "|");
    char *c1       = strtok(NULL, "|");
    char *c2       = strtok(NULL, "|");
    char *c3       = strtok(NULL, "|");
    char *c4       = strtok(NULL, "|");

    if (!question || !c1 || !c2 || !c3 || !c4) {
        snprintf(out, out_size, "QUESTION_ERREUR\n");
        return;
    }

    snprintf(out, out_size,
        "QUESTION_DEBUT\n"
        " %s\n"
        "  [1] %s\n"
        "  [2] %s\n"
        "  [3] %s\n"
        "  [4] %s\n"
        "QUESTION_FIN\n",
        question, c1, c2, c3, c4);
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s PORT BONNE_REPONSE [QUESTION_LIGNE]\n", argv[0]);
        return 1;
    }

    int port          = atoi(argv[1]);
    char *bonne_rep   = argv[2];
    char *question_ligne = (argc >= 4) ? argv[3] : "";

    /* Créer le socket serveur */
    int serveur_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (serveur_fd < 0) { perror("socket"); return 1; }

    int opt = 1;
    setsockopt(serveur_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port        = htons(port);

    if (bind(serveur_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind"); return 1;
    }

    /* On attend 2 connexions : A et B */
    listen(serveur_fd, 2);

    /* Signaler au bash que le serveur est prêt */
    printf("SERVEUR_PRET\n");
    fflush(stdout);

    ReponseJoueur rep_A = {"", 0, 0, -1};
    ReponseJoueur rep_B = {"", 0, 0, -1};

    struct sockaddr_in addr_client;
    socklen_t addr_len = sizeof(addr_client);

    /* ---- Attendre les 2 connexions (A et B) ---- */
    printf("Attente des joueurs A et B...\n");
    fflush(stdout);

    /* Timeout global de 120 secondes pour que les 2 se connectent */
    time_t deadline = time(NULL) + 120;

    while (rep_A.fd < 0 || rep_B.fd < 0) {
        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(serveur_fd, &fds);

        struct timeval tv;
        tv.tv_sec  = (long)(deadline - time(NULL));
        tv.tv_usec = 0;
        if (tv.tv_sec <= 0) {
            printf("TIMEOUT_CONNEXION\n");
            fflush(stdout);
            return 1;
        }

        int act = select(serveur_fd + 1, &fds, NULL, NULL, &tv);
        if (act <= 0) {
            printf("TIMEOUT_CONNEXION\n");
            fflush(stdout);
            return 1;
        }

        int new_fd = accept(serveur_fd, (struct sockaddr*)&addr_client, &addr_len);
        if (new_fd < 0) continue;

        char *ip = inet_ntoa(addr_client.sin_addr);

        /* CORRECTION ICI : Rempli par ordre d'arrivée stricte (le premier connecté prend toujours rep_A, le second rep_B) */
        if (rep_A.fd < 0) {
            rep_A.fd = new_fd;
            printf("Joueur A connecte : %s\n", ip);
            fflush(stdout);
        } else if (rep_B.fd < 0) {
            rep_B.fd = new_fd;
            printf("Joueur B connecte : %s\n", ip);
            fflush(stdout);
        } else {
            close(new_fd);
        }
    }

    printf("Les deux joueurs sont connectes. Envoi de la question...\n");
    fflush(stdout);

    /* ---- Formater et envoyer la question aux deux joueurs ---- */
    char question_formatee[MAX_BUF];
    formater_question(question_ligne, question_formatee, sizeof(question_formatee));

    send(rep_A.fd, question_formatee, strlen(question_formatee), 0);
    send(rep_B.fd, question_formatee, strlen(question_formatee), 0);

    /* ---- Attendre les réponses des deux joueurs (timeout 60s) ---- */
    struct timeval timeout;
    timeout.tv_sec  = 60;
    timeout.tv_usec = 0;

    while (!rep_A.a_repondu || !rep_B.a_repondu) {
        fd_set fds;
        FD_ZERO(&fds);
        if (!rep_A.a_repondu) FD_SET(rep_A.fd, &fds);
        if (!rep_B.a_repondu) FD_SET(rep_B.fd, &fds);

        int max_fd = (rep_A.fd > rep_B.fd ? rep_A.fd : rep_B.fd) + 1;

        struct timeval tv = timeout;
        int activite = select(max_fd, &fds, NULL, NULL, &tv);

        if (activite <= 0) {
            printf("TIMEOUT_REPONSE\n");
            fflush(stdout);
            break;
        }

        char buf[MAX_BUF];

        /* Réception de A */
        if (!rep_A.a_repondu && FD_ISSET(rep_A.fd, &fds)) {
            memset(buf, 0, sizeof(buf));
            int n = recv(rep_A.fd, buf, sizeof(buf)-1, 0);
            if (n > 0) {
                rep_A.timestamp = get_timestamp();
                buf[strcspn(buf, "\n")] = 0;
                strncpy(rep_A.reponse, buf, sizeof(rep_A.reponse)-1);
                rep_A.a_repondu = 1;
                printf("A_REPONDU:%s\n", rep_A.reponse);
                fflush(stdout);
            }
        }

        /* Réception de B */
        if (!rep_B.a_repondu && FD_ISSET(rep_B.fd, &fds)) {
            memset(buf, 0, sizeof(buf));
            int n = recv(rep_B.fd, buf, sizeof(buf)-1, 0);
            if (n > 0) {
                rep_B.timestamp = get_timestamp();
                buf[strcspn(buf, "\n")] = 0;
                strncpy(rep_B.reponse, buf, sizeof(rep_B.reponse)-1);
                rep_B.a_repondu = 1;
                printf("B_REPONDU:%s\n", rep_B.reponse);
                fflush(stdout);
            }
        }
    }

    /* ---- Calculer le résultat ---- */
    int a_bon = rep_A.a_repondu && (strcmp(rep_A.reponse, bonne_rep) == 0);
    int b_bon = rep_B.a_repondu && (strcmp(rep_B.reponse, bonne_rep) == 0);
    char resultat[MAX_BUF];

    if (a_bon && b_bon) {
        if (rep_A.timestamp <= rep_B.timestamp) {
            long long diff = rep_B.timestamp - rep_A.timestamp;
            snprintf(resultat, sizeof(resultat), "VAINQUEUR:A|DIFF:%lld\n", diff);
        } else {
            long long diff = rep_A.timestamp - rep_B.timestamp;
            snprintf(resultat, sizeof(resultat), "VAINQUEUR:B|DIFF:%lld\n", diff);
        }
    } else if (a_bon) {
        snprintf(resultat, sizeof(resultat), "VAINQUEUR:A|DIFF:0\n");
    } else if (b_bon) {
        snprintf(resultat, sizeof(resultat), "VAINQUEUR:B|DIFF:0\n");
    } else {
        snprintf(resultat, sizeof(resultat), "VAINQUEUR:AUCUN|DIFF:0\n");
    }

    /* ---- Envoyer le résultat aux deux joueurs ---- */
    send(rep_A.fd, resultat, strlen(resultat), 0);
    send(rep_B.fd, resultat, strlen(resultat), 0);

    printf("RESULTAT:%s", resultat);
    fflush(stdout);

    /* Sauvegarder pour le bash */
    FILE *f = fopen("duel/resultat_question.txt", "w");
    if (f) { fprintf(f, "%s", resultat); fclose(f); }

    close(rep_A.fd);
    close(rep_B.fd);
    close(serveur_fd);
    return 0;
}
