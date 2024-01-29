#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <poll.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

struct input_context {
  char devname[16];
  int keycode;
  void (*callback_fn)(void);
  struct pollfd *poll;
};

static void callback_SecTouchpad(void) {
  pid_t pid;
  int status;

  pid = fork();

  if (pid < 0) {
    perror("fork");
    return;
  } else if (pid == 0) {
    // TODO Hardcoded
    char *argv[] = {"am", "start-activity",
                    "com.google.android.apps.nexuslauncher/"
                    "com.android.quickstep.RecentsActivity",
                    NULL};
    execvp(argv[0], argv);
    _exit(127);
  } else {
    wait(&status);
  }
  printf("Exited with exit code %d\n", WEXITSTATUS(status));
}

static int init_GpioKeys(void) {
  int ret;
  static int fd = -1;
  static bool done = false;

#ifdef USE_NEW_UINPUT
  struct uinput_setup us;
#else
  struct uinput_user_dev us;
#endif

  if (!done) {
    fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (fd < 0) {
      perror("open");
      return -errno;
    }
    memset(&us, 0, sizeof(us));
    us.id.bustype = BUS_VIRTUAL;
    strncpy(us.name, "Home button wakeup", sizeof(us.name));
    ret = !ioctl(fd, UI_SET_EVBIT, EV_KEY) &&
          !ioctl(fd, UI_SET_KEYBIT, KEY_WAKEUP) &&
#ifdef USE_NEW_UINPUT
          !ioctl(fd, UI_DEV_SETUP, &us)
#else
          (write(fd, &us, sizeof(us)) > 0)
#endif
          && !ioctl(fd, UI_DEV_CREATE);
    if (!ret) {
      perror("ioctl");
      close(fd);
      return -errno;
    }
    done = true;
    printf("%s: ok\n", __func__);
  }
  return fd;
}

static void emit(int fd, int type, int code, int val) {
  struct input_event ie;
  ie.type = type;
  ie.code = code;
  ie.value = val;
  /* timestamp values below are ignored */
  ie.time.tv_sec = 0;
  ie.time.tv_usec = 0;
  write(fd, &ie, sizeof(ie));
}

static void callback_GpioKeys(void) {
  int fd = init_GpioKeys();
  if (fd > 0) {
    emit(fd, EV_KEY, KEY_WAKEUP, 1);
    emit(fd, EV_SYN, SYN_REPORT, 0);
    emit(fd, EV_KEY, KEY_WAKEUP, 0);
    emit(fd, EV_SYN, SYN_REPORT, 0);
  }
}

static void close_GpioKeys(const int fd) {
  if (fd > 0) {
    ioctl(fd, UI_DEV_DESTROY);
    close(fd);
  }
}

static bool getInputContexts(struct input_context **ctxp, int *size) {
  struct input_context *ctxs = malloc(sizeof(struct input_context) * 2);
  if (ctxs) {
    strcpy(ctxs[0].devname, "sec_touchkey");
    ctxs[0].keycode = 0xfe;
    ctxs[0].callback_fn = callback_SecTouchpad;
    strcpy(ctxs[1].devname, "gpio_keys");
    ctxs[1].keycode = 0xac;
    ctxs[1].callback_fn = callback_GpioKeys;

    *ctxp = ctxs;
    *size = 2;
    return true;
  }
  return false;
}

#define INPUT_DIR "/dev/input/"

static int findInputEvent(const struct input_context *ctx) {
  struct dirent *dr;
  char buf[PATH_MAX], device_name[16];
  DIR *dp;
  int fd, ret;

  dp = opendir(INPUT_DIR);
  if (!dp) {
    perror("opendir");
    return -errno;
  }
  while ((dr = readdir(dp))) {
    if (dr->d_name[0] == '.')
      continue;
    snprintf(buf, sizeof(buf), INPUT_DIR "%s", dr->d_name);
    fd = open(buf, O_RDONLY);
    if (fd < 0) {
      perror("open");
      continue;
    }
    ret = ioctl(fd, EVIOCGNAME(sizeof(device_name)), device_name);
    if (ret < 0) {
      perror("ioctl");
      continue;
    }
    if (!strncmp(ctx->devname, device_name, sizeof(device_name))) {
      printf("%s => %s == %s\n", buf, device_name, ctx->devname);
      return fd;
    }
    close(fd);
  }
  closedir(dp);
  return -ENOENT;
}

#define for_each_context(ptr, idx)                                             \
  for (idx = 0, ptr = data; idx < datasize; ++idx, ++ptr)

int main() {
  int i, j = 0, count = 0, datasize;
  struct input_context *ptr, *data;

  if (!getInputContexts(&data, &datasize))
    return ENOMEM;

  for_each_context(ptr, i) {
    int fd = findInputEvent(ptr);
    if (fd > 0) {
      ++count;
      close(fd);
    }
  }
  if (count == 0) {
    printf("Failed to open a single device. Abort.\n");
    free(data);
    return EINVAL;
  }
  printf("%d devices ready for poll\n", count);

  struct pollfd *polls = malloc(sizeof(struct pollfd) * count);
  if (!polls) {
    free(data);
    return ENOMEM;
  }

  for_each_context(ptr, i) {
    int fd = findInputEvent(ptr);
    if (fd > 0) {
      polls[j].fd = fd;
      polls[j].revents = 0;
      polls[j].events = POLLIN;
      ptr->poll = &polls[j];
      ++j;
    } else {
      ptr->poll = NULL;
    }
  }

  init_GpioKeys();
  while (true) {
    if (poll(polls, count, -1) < 0) {
      perror("poll");
      break;
    }
    for_each_context(ptr, i) {
      if (ptr->poll && ptr->poll->revents & POLLIN) {
        struct input_event ev;

        read(ptr->poll->fd, &ev, sizeof(ev));
        printf("event: keycode %d, value %d\n", ev.code, ev.value);
        if (ev.type == EV_KEY && ev.code == ptr->keycode && ev.value == 1) {
          printf("Callback for dev %s\n", ptr->devname);
          ptr->callback_fn();
          ptr->poll->revents = 0;
        }
      }
    }
  }
  close_GpioKeys(init_GpioKeys());
  free(data);
  free(polls);
}
