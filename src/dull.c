#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include <stdlib.h>
#include <pwd.h>
#include <grp.h>

#define LINESIZE 131072
#define SIX_MONTHS (60 * 60 * 24 * 365 / 2)

int ls(char*);
char* format_mode(mode_t);

int main(int argc, char** argv) {
    char line[LINESIZE];
    char* tab;
    char* filename;
    while (NULL != fgets(line, LINESIZE, stdin)) {
        size_t len = strlen(line);
        if (line[len - 1] != '\n') {
            while (1) {
                if (NULL == fgets(line, LINESIZE, stdin)) {
                    exit(0);
                }
                len = strlen(line);
                if (line[len - 1] == '\n') {
                    continue;
                }
            }
            continue;
        }
        line[len - 1] = '\0';   /* chop the newline */
        tab = strchr(line, '\t');
        if (tab == NULL) {
            filename = line;
        } else {
            filename = tab + 1;
            *tab = '\0';
            fputs(line, stdout);
            putchar('\t');
        }
        ls(filename);
    }
}

char months[12][4] = {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};

int ls(char* filename) {
    /* based on and stolen from Perl Power Tools */
    char linkname[LINESIZE];
    struct stat statbuf;
    if (-1 == lstat(filename, &statbuf)) {
        perror(filename);
        return -1;
    }
    int is_symlink = ((statbuf.st_mode & 0170000) >> 12) == 10;
    if (is_symlink) {
        ssize_t len;
        if (-1 == (len = readlink(filename, linkname, LINESIZE - 1))) {
            perror(filename);
            strcpy(linkname, "<readlink failed>");
        } else {
            linkname[len] = '\0';
        }
    }
    printf("%10ld ", statbuf.st_ino);               /* [0] */
    printf("%4ld ", statbuf.st_blocks);             /* [1] */
    printf("%10s ", format_mode(statbuf.st_mode));  /* [2] */
    printf("%3ld ", statbuf.st_nlink);              /* [3] */
    struct passwd* pw = getpwuid(statbuf.st_uid);
    if (NULL == pw) {
        printf("%-8d ", statbuf.st_uid); /* [4] */
    } else {
        printf("%-8s ", pw->pw_name); /* [4] */
    }
    struct group* gr = getgrgid(statbuf.st_gid);
    if (NULL == gr) {
        printf("%-8d ", statbuf.st_gid); /* [5] */
    } else {
        printf("%-8s ", gr->gr_name); /* [5] */
    }
    if (statbuf.st_mode & 0140000) {
        printf("%9ld ", statbuf.st_size); /* [6] */
    } else {
        printf("%4lx,%4lx ",
               (statbuf.st_dev & 0xffff0000 >> 16),
               (statbuf.st_dev & 0xffff)); /* [6] */
    }
    struct tm *tmptr;
    time_t t = (time_t)statbuf.st_mtime;
    tmptr = localtime(&t);
    if (((long)time(NULL) - (long)statbuf.st_mtime) < SIX_MONTHS) {
        printf("%s %2d %02d:%02d ",
               months[tmptr->tm_mon],
               tmptr->tm_mday,
               tmptr->tm_hour,
               tmptr->tm_min);
    } else {
        printf("%s %2d %5d ",
               months[tmptr->tm_mon],
               tmptr->tm_mday,
               tmptr->tm_year + 1900);
    }
    fputs(filename, stdout);
    if (is_symlink) {
        printf(" -> %s", linkname);
    }
    putchar('\n');
    return 1;
}

char perms[8][4] = {
    "---", "--x", "-w-", "-wx", "r--", "r-x", "rw-", "rwx"
};
char ftypes[] = {
    '.', 'p', 'c', '?', 'd', '?', 'b', '?', '-', '?', 'l', '?', 's', '?', '?', '?'
};

char modestr[11];
char* format_mode(mode_t mode) {
    /* based on and stolen from Perl Power Tools */
    modestr[10] = '\0';
    int setids = (mode & 07000) >> 9;
    modestr[0] = ftypes[(mode & 0170000) >> 12]; /* ftype */
    memcpy(modestr + 1, perms[(mode & 0700) >> 6], 3);
    memcpy(modestr + 4, perms[(mode & 0070) >> 3], 3);
    memcpy(modestr + 7, perms[(mode & 0007)     ], 3);
    if (setids) {
        if (setids & 1) {       /* sticky */
            modestr[3] = modestr[3] == 'x' ? 't' : 'T';
        }
        if (setids & 4) {       /* setuid */
            modestr[9] = modestr[9] == 'x' ? 's' : 'S';
        }
        if (setids & 2) {       /* setgid */
            modestr[6] = modestr[6] == 'x' ? 's' : 'S';
        }
    }
    return modestr;
}
