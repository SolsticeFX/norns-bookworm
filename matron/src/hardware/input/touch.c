#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "events.h"
#include "hardware/input.h"
#include "hardware/io.h"


typedef struct _input_touch_priv {
    int fd;
    char* dev;
} input_touch_priv_t;

typedef struct _touch_dsi_priv {
    int fd;
    char* dev;
} touch_dsi_priv_t;


struct touch_input {
    uint8_t slot;
    uint8_t press;
    int32_t x;
    int32_t y;
    int32_t start_x;
    int32_t start_y;
    int32_t last_x;
    int32_t last_y;
}; 

struct touch_input tinput = {0, 0, 0, 0, 0, 0, 0, 0};


static int input_touch_config(matron_io_t* io, lua_State *l);
static int input_touch_setup(matron_io_t* io);
static void input_touch_destroy(matron_io_t* io);
static void* touch_dsi_poll(void* data);
static int open_and_grab(const char *pathname, int flags);


input_ops_t touch_dsi_ops = {
    .io_ops.name      = "touch:dsi",
    .io_ops.type      = IO_INPUT,
    .io_ops.data_size = sizeof(touch_dsi_priv_t),
    .io_ops.config    = input_touch_config,
    .io_ops.setup     = input_touch_setup,
    .io_ops.destroy   = input_touch_destroy,
    .poll = touch_dsi_poll,
};

int input_touch_config(matron_io_t* io, lua_State *l) {
    input_touch_priv_t* priv = io->data;

    lua_pushstring(l, "dev");
    lua_gettable(l, -2);
    if (lua_isstring(l, -1)) {
        const char *dev = lua_tostring(l, -1);
        if (!(priv->dev = malloc(strlen(dev) + 1))) {
            fprintf(stderr, "ERROR (%s) no memory\n", io->ops->name);
            lua_settop(l, 0);
            return -1;
        }
        strcpy(priv->dev, dev);
    } else {
        fprintf(stderr, "ERROR (%s) config option 'dev' should be a string\n", io->ops->name);
        lua_settop(l, 0);
        return -1;
    }
    lua_pop(l, 1);
    return 0;
}



int input_touch_setup(matron_io_t* io) {
    input_touch_priv_t *priv = io->data;
    priv->fd = open_and_grab(priv->dev, O_RDONLY);
    if (priv->fd <= 0) {
        fprintf(stderr, "ERROR (%s) device not available: %s\n", io->ops->name, priv->dev);
        return priv->fd;
    }
   

    return input_setup(io);
}

void input_touch_destroy(matron_io_t *io) {
    input_touch_priv_t *priv = io->data;
    free(priv->dev);
    input_destroy(io);
}



void* touch_dsi_poll(void* data) {
    matron_input_t* input = data;
    input_touch_priv_t* priv = input->io.data;

    int rd;
    unsigned int i;
    struct input_event event[64];

    while (1) {
        rd = read(priv->fd, event, sizeof(struct input_event) * 64);
        if (rd < (int)sizeof(struct input_event)) {
            fprintf(stderr, "ERROR (touchscreen) read error\n");
        }

        for (i = 0; i < rd / sizeof(struct input_event); i++) {
            if (event[i].type!=0) { // make sure it's not EV_SYN == 0
                
                if (event[i].code==330 && event[i].value==1) {
                //fprintf(stderr, "PRESS\n");
                tinput.press = event[i].value;
                }
                else if (event[i].code==330 && event[i].value==0) {
                tinput.press = event[i].value;
                }
                else if (event[i].code==0) { 
                //fprintf(stderr, "ABS X = %d\n", event[i].value);
               // tinput.x = event[i].value;
                }
                else if (event[i].code==1){
                //fprintf(stderr, "ABS Y = %d\n", event[i].value);
                //tinput.y = event[i].value;
                }
                else if (event[i].code==47) {
                //fprintf(stderr, "slot = %d\n", event[i].value);
                tinput.slot = event[i].value;
                }
                else if (event[i].code==53) {
                //fprintf(stderr, "ABS MT POS X = %d\n", event[i].value);
        
                tinput.x = event[i].value;

                }
                else if (event[i].code==54) {
                //fprintf(stderr, "ABS MT POS Y = %d\n", event[i].value);

                tinput.y = event[i].value;
                
                }
                
                else {
                   //  fprintf(stderr, "Unrecognised code and value \n");
                   // fprintf(stderr, "----\n");

                   // fprintf(stderr, "Code = %d, Value = %d", event[i].code, event[i].value);

                }
            }


            else {
               // fprintf(stderr, "x: %d", tinput.x);
 //               fprintf(stderr, "-------------- SYN_REPORT ------------\n");

                if(tinput.press==1){
                    if(tinput.last_x&&tinput.last_y){
                    //DRAG
                    union event_data *evdrag = event_data_new(EVENT_DRAG);
                        evdrag->drag.start_x = tinput.start_x;
                        evdrag->drag.start_y = tinput.start_y;
                        evdrag->drag.last_x = tinput.last_x;
                        evdrag->drag.last_y = tinput.last_y;
                        evdrag->drag.x = tinput.x;
                        evdrag->drag.y = tinput.y;
                        event_post(evdrag);
                    }
                    else {
                    //PRESS
                    tinput.start_x = tinput.x;
                    tinput.start_y = tinput.y;
                        union event_data *evpress = event_data_new(EVENT_PRESS);
                        evpress->press.x = tinput.x;
                        evpress->press.y = tinput.y;
                        event_post(evpress);

                        tinput.start_x = tinput.x;
                        tinput.last_x = tinput.x;
                        tinput.start_y = tinput.y;
                        tinput.last_y = tinput.y;
                    }


                }



                else{
                    //TAP
                    if(abs(tinput.start_x-tinput.x)<50 && abs(tinput.start_y-tinput.y)<50) {
                        union event_data *evtap = event_data_new(EVENT_TAP);

                        evtap->tap.x = tinput.last_x;
                        evtap->tap.y = tinput.last_y;
        
                        event_post(evtap);

                    }
                    else {
                    //RELEASE
                        union event_data *evrelease = event_data_new(EVENT_RELEASE);
                        evrelease->release.x = tinput.last_x;
                        evrelease->release.y = tinput.last_y;
                        event_post(evrelease);



                    }
                    
                tinput.start_x = 0;
                tinput.start_y = 0;
                tinput.press = 0;
                tinput.x = 0;
                tinput.y = 0;
                }

                /*union event_data *ev = event_data_new(EVENT_TOUCH);
                ev->touch.slot = tinput.slot;
                ev->touch.press = tinput.press;
                ev->touch.x = tinput.x;
                ev->touch.y = tinput.y;
                event_post(ev);*/
                tinput.last_x = tinput.x;
                tinput.last_y = tinput.y;    
            }
        }
    }

    return NULL;
}
int open_and_grab(const char *pathname, int flags) {
    int fd;
    int open_attempts = 0, ioctl_attempts = 0;
    while (open_attempts < 200) {
        fd = open(pathname, flags);
        if (fd > 0) {
            if (ioctl(fd, EVIOCGRAB, 1) == 0) {
                ioctl(fd, EVIOCGRAB, (void *)0);
                goto done;
            }
            ioctl_attempts++;
            close(fd);
        }
        open_attempts++;
        usleep(50000); // 50ms sleep * 200 = 10s fail after 10s
    };
done:
    if (open_attempts > 0) {
        fprintf(stderr, "WARN open_and_grab GPIO '%s' required %d open attempts & %d ioctl attempts\n", pathname,
                open_attempts, ioctl_attempts);
    }
    return fd;
}
