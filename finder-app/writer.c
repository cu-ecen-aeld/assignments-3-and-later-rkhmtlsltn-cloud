#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char *argv[])
{
    if (argc != 3) {
        fprintf(stderr, "Error: expected 2 arguments\n");
        syslog(LOG_ERR, "Invalid arguments");
        return 1;
    }

    const char *writefile = argv[1];
    const char *writestr = argv[2];

    openlog(NULL, 0, LOG_USER);

    FILE *file = fopen(writefile, "w");
    if (file == NULL) {
        fprintf(stderr, "Error: could not create file %s\n", writefile);
        syslog(LOG_ERR, "Could not create file %s", writefile);
        closelog();
        return 1;
    }

    if (fprintf(file, "%s", writestr) < 0) {
        fprintf(stderr, "Error: could not write to file %s\n", writefile);
        syslog(LOG_ERR, "Could not write to file %s", writefile);
        fclose(file);
        closelog();
        return 1;
    }

    if (fclose(file) != 0) {
        fprintf(stderr, "Error: could not close file %s\n", writefile);
        syslog(LOG_ERR, "Could not close file %s", writefile);
        closelog();
        return 1;
    }

    syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);

    closelog();

    return 0;
}
