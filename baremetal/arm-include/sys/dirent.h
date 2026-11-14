/* baremetal/arm-include/sys/dirent.h -- arm-none-eabi newlib's sys/dirent.h
 * is an #error; ESP's newlib carries this shape. No file system on the
 * board: opendir fails (ENOSYS stubs in baremetal/tinystdio.c). */
#ifndef SP_BM_SYS_DIRENT_H
#define SP_BM_SYS_DIRENT_H
#include <sys/types.h>
typedef struct { int dd_fd; } DIR;
struct dirent { ino_t d_ino; unsigned char d_type; char d_name[256]; };
#define DT_UNKNOWN 0
#define DT_DIR 4
#define DT_REG 8
#define DT_LNK 10
#endif
