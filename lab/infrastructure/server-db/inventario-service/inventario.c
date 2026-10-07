#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>

#define PORT 80
#define PRODUCT_DIR "/opt/inventario_service/products"
#define FILE_UTENTI "/opt/inventario_service/utenti.txt"
#define LISTA_PRODOTTI "/opt/inventario_service/products/lista.txt"

void trim(char *str) {
    int len = strlen(str);

    while (len > 0 &&
           (str[len - 1] == '\n' ||
            str[len - 1] == '\r' ||
            str[len - 1] == ' ')) {
        str[len - 1] = '\0';
        len--;
    }
}

int verifica_login(const char *username, const char *password) {
    FILE *f = fopen(FILE_UTENTI, "r");

    if (!f)
        return 0;

    char line[256];
    char file_user[128];
    char file_pass[128];
    int autenticato = 0;

    while (fgets(line, sizeof(line), f)) {
        trim(line);

        if (line[0] == '\0' || line[0] == '#')
            continue;

        char *colon = strchr(line, ':');

        if (colon) {
            *colon = '\0';

            strcpy(file_user, line);
            strcpy(file_pass, colon + 1);

            if (strcmp(username, file_user) == 0 &&
                strcmp(password, file_pass) == 0) {
                autenticato = 1;
                break;
            }
        }
    }

    fclose(f);
    return autenticato;
}

void handle_client(int client_socket) {
    char buffer[4096];

    while (1) {
        const char *menu =
            "\n=== GESTIONE INVENTARIO PRODOTTI ===\n"
            "1) Visualizza Prodotti\n"
            "2) Seleziona Prodotto/Lista da Modificare\n"
            "3) Esci\n"
            "Scegli un'opzione: ";

        if (send(client_socket, menu, strlen(menu), MSG_NOSIGNAL) < 0)
            break;

        memset(buffer, 0, sizeof(buffer));

        ssize_t received = recv(
            client_socket,
            buffer,
            sizeof(buffer) - 1,
            0
        );

        /*
         * 0 = il client ha chiuso normalmente.
         * <0 = errore.
         *
         * In entrambi i casi NON proviamo a scrivere nuovamente
         * sul socket.
         */
        if (received <= 0)
            break;

        buffer[received] = '\0';
        trim(buffer);

        if (strcmp(buffer, "1") == 0) {
            FILE *fp = fopen(LISTA_PRODOTTI, "r");

            if (fp) {
                const char *header =
                    "\n--- LISTA PRODOTTI ATTUALE ---\n";

                send(
                    client_socket,
                    header,
                    strlen(header),
                    MSG_NOSIGNAL
                );

                while (fgets(buffer, sizeof(buffer), fp)) {
                    if (send(
                            client_socket,
                            buffer,
                            strlen(buffer),
                            MSG_NOSIGNAL
                        ) < 0) {
                        break;
                    }
                }

                fclose(fp);

                send(
                    client_socket,
                    "\n",
                    1,
                    MSG_NOSIGNAL
                );
            } else {
                const char *msg =
                    "Errore nella lettura della lista prodotti.\n";

                send(
                    client_socket,
                    msg,
                    strlen(msg),
                    MSG_NOSIGNAL
                );
            }
        }

        else if (strcmp(buffer, "2") == 0) {
            char input_utente[256];
            char comando_sistema[512];

            const char *prompt =
                "Inserisci il nome del file di inventario "
                "o prodotto da modificare (es: lista.txt): ";

            if (send(
                    client_socket,
                    prompt,
                    strlen(prompt),
                    MSG_NOSIGNAL
                ) < 0) {
                break;
            }

            memset(buffer, 0, sizeof(buffer));

            received = recv(
                client_socket,
                buffer,
                sizeof(buffer) - 1,
                0
            );

            if (received <= 0)
                break;

            buffer[received] = '\0';

            trim(buffer);

            snprintf(
                input_utente,
                sizeof(input_utente),
                "%s",
                buffer
            );

            if (strlen(input_utente) == 0)
                continue;

            /*
             * INTENZIONALMENTE VULNERABILE:
             * mantenuto per il laboratorio AppArmor.
             */
            snprintf(
                comando_sistema,
                sizeof(comando_sistema),
                "ls -la %s/%s",
                PRODUCT_DIR,
                input_utente
            );

            const char *msg =
                "\n[*] Controllo del file di inventario in corso...\n";

            send(
                client_socket,
                msg,
                strlen(msg),
                MSG_NOSIGNAL
            );

            /*
             * Questo codice ora gira nel processo FIGLIO,
             * quindi dup2() non modifica stdin/stdout/stderr
             * del processo server principale.
             */
            dup2(client_socket, STDIN_FILENO);
            dup2(client_socket, STDOUT_FILENO);
            dup2(client_socket, STDERR_FILENO);

            int system_rc = system(comando_sistema);

	    if (system_rc == -1) {
    		perror("system");
		}

	    break;
        }

        else if (strcmp(buffer, "3") == 0) {
            const char *msg =
                "Disconnessione effettuata. Arrivederci!\n";

            send(
                client_socket,
                msg,
                strlen(msg),
                MSG_NOSIGNAL
            );

            break;
        }

        else {
            const char *msg =
                "Opzione non valida.\n";

            if (send(
                    client_socket,
                    msg,
                    strlen(msg),
                    MSG_NOSIGNAL
                ) < 0) {
                break;
            }
        }
    }

    shutdown(client_socket, SHUT_RDWR);
    close(client_socket);
}

int main(void) {
    int server_fd;
    struct sockaddr_in address;
    int opt = 1;

    /*
     * Evita che una write/send verso un client disconnesso
     * termini il demone.
     */
    signal(SIGPIPE, SIG_IGN);

    /*
     * Evita processi zombie per i client già terminati.
     */
    signal(SIGCHLD, SIG_IGN);

    mkdir(PRODUCT_DIR, 0755);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);

    if (server_fd < 0) {
        perror("Socket fallito");
        exit(EXIT_FAILURE);
    }

    if (setsockopt(
            server_fd,
            SOL_SOCKET,
            SO_REUSEADDR,
            &opt,
            sizeof(opt)
        ) < 0) {
        perror("setsockopt");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    memset(&address, 0, sizeof(address));

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(
            server_fd,
            (struct sockaddr *)&address,
            sizeof(address)
        ) < 0) {
        perror("Bind fallito");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    if (listen(server_fd, 5) < 0) {
        perror("Listen fallito");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    printf(
        "[*] Servizio Inventario Nativo (C) attivo sulla porta %d...\n",
        PORT
    );

    fflush(stdout);

    while (1) {
        struct sockaddr_in client_address;
        socklen_t client_len = sizeof(client_address);

        int client_socket = accept(
            server_fd,
            (struct sockaddr *)&client_address,
            &client_len
        );

        if (client_socket < 0) {
            perror("Accept fallito");
            continue;
        }

        pid_t pid = fork();

        if (pid < 0) {
            perror("Fork fallito");
            close(client_socket);
            continue;
        }

        if (pid == 0) {
            /*
             * Processo figlio.
             *
             * Non deve tenere aperto il socket di ascolto.
             */
            close(server_fd);

            handle_client(client_socket);

            _exit(EXIT_SUCCESS);
        }

        /*
         * Processo principale.
         *
         * La connessione viene gestita dal figlio.
         */
        close(client_socket);
    }

    close(server_fd);

    return 0;
}
