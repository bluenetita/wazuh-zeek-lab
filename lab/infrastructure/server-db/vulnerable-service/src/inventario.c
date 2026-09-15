#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/stat.h>

#define PORT 80
#define PRODUCT_DIR "/opt/inventario_service/products"
#define FILE_UTENTI "/opt/inventario_service/utenti.txt"
#define LISTA_PRODOTTI "/opt/inventario_service/products/lista.txt"

void trim(char *str) {
    int len = strlen(str);
    while (len > 0 && (str[len - 1] == '\n' || str[len - 1] == '\r' || str[len - 1] == ' ')) {
        str[len - 1] = '\0';
        len--;
    }
}

int verifica_login(const char *username, const char *password) {
    FILE *f = fopen(FILE_UTENTI, "r");
    if (!f) return 0;

    char line[256];
    char file_user[128], file_pass[128];
    int autenticato = 0;

    while (fgets(line, sizeof(line), f)) {
        trim(line);
        if (line[0] == '\0' || line[0] == '#') continue;

        char *colon = strchr(line, ':');
        if (colon) {
            *colon = '\0';
            strcpy(file_user, line);
            strcpy(file_pass, colon + 1);

            if (strcmp(username, file_user) == 0 && strcmp(password, file_pass) == 0) {
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
        char *menu =
            "\n=== GESTIONE INVENTARIO PRODOTTI ===\n"
            "1) Visualizza Prodotti\n"
            "2) Seleziona Prodotto/Lista da Modificare\n"
            "3) Esci\n"
            "Scegli un'opzione: ";

        send(client_socket, menu, strlen(menu), 0);

        memset(buffer, 0, sizeof(buffer));
        recv(client_socket, buffer, sizeof(buffer) - 1, 0);
        trim(buffer);

        if (strcmp(buffer, "1") == 0) {
            FILE *fp = fopen(LISTA_PRODOTTI, "r");

            if (fp) {
                send(client_socket, "\n--- LISTA PRODOTTI ATTUALE ---\n", 32, 0);

                while (fgets(buffer, sizeof(buffer), fp)) {
                    send(client_socket, buffer, strlen(buffer), 0);
                }

                fclose(fp);
                send(client_socket, "\n", 1, 0);
            } else {
                send(client_socket,
                     "Errore nella lettura della lista prodotti.\n",
                     43,
                     0);
            }
        }

        else if (strcmp(buffer, "2") == 0) {
            char input_utente[256];
            char comando_sistema[512];

            send(client_socket,
                 "Inserisci il nome del file di inventario o prodotto da modificare (es: lista.txt): ",
                 84,
                 0);

            memset(buffer, 0, sizeof(buffer));
            recv(client_socket, buffer, sizeof(buffer) - 1, 0);
            trim(buffer);

            strcpy(input_utente, buffer);

            if (strlen(input_utente) == 0)
                continue;

            snprintf(
                comando_sistema,
                sizeof(comando_sistema),
                "ls -la %s/%s",
                PRODUCT_DIR,
                input_utente
            );

            send(client_socket,
                 "\n[*] Controllo del file di inventario in corso...\n",
                 50,
                 0);

            dup2(client_socket, 0);
            dup2(client_socket, 1);
            dup2(client_socket, 2);

            system(comando_sistema);
            break;
        }

        else if (strcmp(buffer, "3") == 0) {
            send(client_socket,
                 "Disconnessione effettuata. Arrivederci!\n",
                 40,
                 0);
            break;
        }

        else {
            send(client_socket, "Opzione non valida.\n", 20, 0);
        }
    }

    close(client_socket);
}

int main() {
    int server_fd, client_socket;
    struct sockaddr_in address;
    int opt = 1;
    int addrlen = sizeof(address);

    mkdir(PRODUCT_DIR, 0755);

    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("Socket fallito");
        exit(EXIT_FAILURE);
    }

    setsockopt(
        server_fd,
        SOL_SOCKET,
        SO_REUSEADDR,
        &opt,
        sizeof(opt)
    );

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(
        server_fd,
        (struct sockaddr *)&address,
        sizeof(address)
    ) < 0) {
        perror("Bind fallito");
        exit(EXIT_FAILURE);
    }

    if (listen(server_fd, 5) < 0) {
        perror("Listen fallito");
        exit(EXIT_FAILURE);
    }

    printf(
        "[*] Servizio Inventario Nativo (C) attivo sulla porta %d...\n",
        PORT
    );

    while (1) {
        if ((client_socket = accept(
            server_fd,
            (struct sockaddr *)&address,
            (socklen_t *)&addrlen
        )) < 0) {
            perror("Accept fallito");
            continue;
        }

        handle_client(client_socket);
    }

    return 0;
}
